import std/bitops
from move import Direction

type
    Bitmap*[N: static uint] = uint64
    GroupIter*[N: static uint] = object
        seeds: Bitmap[N]
        bitmap: Bitmap[N]
    BitIter*[N: static uint] = object
        bitmap: Bitmap[N]

proc set*(bitmap: var Bitmap, x: uint, y: uint)  =
    assert(x < bitmap.N)
    assert(y < bitmap.N)
    bitmap = bitmap.bitor(1'u64 shl ((bitmap.N - 1 - x) + y * bitmap.N))

proc clear*(bitmap: var Bitmap, x: uint, y: uint)  =
    assert(x < bitmap.N)
    assert(y < bitmap.N)
    bitmap = bitmap.bitand( bitnot(1'u64 shl ((bitmap.N - 1 - x) + y * bitmap.N)))

proc get*(bitmap: Bitmap, x: uint, y: uint): bool =
    assert(x < bitmap.N)
    assert(y < bitmap.N)
    return (bitmap.bitand(1'u64 shl ((bitmap.N - 1 - x) + y * bitmap.N))) != 0

proc coordinates*(bitmap: Bitmap): (uint, uint) =
    assert(bitmap.countSetBits() == 1)

    let index = countTrailingZeroBits(bitmap)
    let yC = (uint index) div bitmap.N
    let xC = bitmap.N - 1 - (uint index) mod bitmap.N

    return (xC, yC)

proc edgeMask*(size: static uint): array[4, Bitmap[size]] =
    const edgeMasks: array[9, array[4, uint64]] = [
        [0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64],
        [0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64],
        [0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64, 0x0000000000000000'u64],
        [0x01C0'u64, 0x0049'u64, 0x0007'u64, 0x0124'u64],
        [0xF000'u64, 0x1111'u64, 0x000F'u64, 0x8888'u64],
        [0x01F00000'u64, 0x00108421'u64, 0x0000001F'u64, 0x01084210'u64],
        [0x0FC0000000'u64, 0x0041041041'u64, 0x000000003F'u64, 0x0820820820'u64],
        [0x01FC0000000000'u64, 0x00040810204081'u64, 0x0000000000007F'u64, 0x01020408102040'u64,],
        [0xFF00000000000000'u64, 0x0101010101010101'u64, 0x00000000000000FF'u64, 0x8080808080808080'u64,]
    ]

    return [
        Bitmap[size](edgeMasks[size][ord(up)]),
        Bitmap[size](edgeMasks[size][ord(left)]),
        Bitmap[size](edgeMasks[size][ord(down)]),
        Bitmap[size](edgeMasks[size][ord(right)]),
    ]

proc boardMask*(size: static uint): Bitmap[size] =
    const boardMasks: array[9, uint64] = [
        0'u64,
        0'u64,
        0'u64,
        0x01FF'u64,
        0xFFFF'u64,
        0x01FFFFFF'u64,
        0x0FFFFFFFFF'u64,
        0x01FFFFFFFFFFFF'u64,
        0xFFFFFFFFFFFFFFFF'u64,
    ]
    return Bitmap[size](boardMasks[size])

proc dilate*(bitmap: Bitmap): Bitmap =
    var dilation = bitmap
    dilation = dilation.bitor( (bitmap shl 1).bitand( (bitnot edgeMask(bitmap.N)[ord(left)]).bitand(boardMask(bitmap.N))))
    dilation = dilation.bitor( (bitmap shr 1).bitand( bitnot edgeMask(bitmap.N)[ord(right)]))
    dilation = dilation.bitor( (bitmap shl bitmap.N).bitand(boardMask(bitmap.N)))
    dilation = dilation.bitor(bitmap shr bitmap.N)

    return dilation

proc floodFill*(bitmap: Bitmap, mask: Bitmap): Bitmap =
    var seed = bitmap bitand mask

    while true:
        let next = seed.dilate() bitand mask
        if next == seed:
            return seed
        seed = next

    return seed

proc groups*[N](bitmap: Bitmap[N]): GroupIter[N] =
    (bitmap, bitmap)

proc groupsFrom*[N](bitmap: Bitmap[N], seeds: Bitmap[N]): GroupIter[N] =
    assert(seeds bitand bitnot self == 0.into(), "provided seeds are not a subset of the bitmap")
    
    (seeds, bitmap)

proc width*[N](bitmap: Bitmap[N]): uint =
    var rowMask = edgeMask[N]()[up]
    var rowAggregate = default(Bitmap[N])
    for i in 0 ..< N:
        let row = bitmap bitand rowMask
        rowAggregate = rowAggregate bitor (row shl (i * N))
        rowMask = rowMask shr N
    
    return uint rowAggregate.countSetBits()

proc height*[N](bitmap: Bitmap[N]): uint =
    var colMask = edgeMask[N]()[left]
    var colAggregate = default(Bitmap[N])
    for i in 0 ..< N:
        let col = bitmap bitand colMask
        colAggregate = colAggregate bitor (col shl i)
        colMask = colMask shr 1
    
    return uint colAggregate.countSetBits()

proc lowestBit*[N](bitmap: Bitmap[N]): Bitmap[N] =
    let remainder = bitmap bitand (bitmap - 1)
    return bitmap bitand bitnot remainder

proc `$`*[N](bitmap: Bitmap[N]): string =
    
    let rowMask = 0xFFFFFFFFFFFFFFFF shr (64 - N)
    let columnMask = 1
    var result = ""
    for y in 0 ..< N:
        if y > 1: result.add("/")
        let row = (bitmap shr (N * N - y * N)) bitand rowMask
        for x in 0 ..< N:
            let column = (row shr (N - x)) bitand columnMask
            result.add(&"{column}")
    return result

iterator nextGroup*[N](iter: var GroupIter[N]): Bitmap[N] =
    while iter.seeds != 0.into():
        let seed = iter.seeds.lowestBit()
        let group = floodFill(seed, iter.bitmap)
        iter.seeds = iter.seeds bitand bitnot group
        iter.bitmap = iter.bitmap bitand bitnot group
        yield group

iterator nextBit*[N](iter: var BitIter[N]): Bitmap[N] =
    while iter.bitmap != 0.into():
        let remainder = iter.bitmap bitand (iter.bitmap - 1)
        let bit = iter.bitmap bitand bitnot remainder
        iter.bitmap = remainder
        yield bit