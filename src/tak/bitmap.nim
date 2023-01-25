import std/bitops, strformat
from move import Direction

type
    Bitmap*[N: static uint] = uint64
    GroupIter*[F: static uint] = object
        seeds: Bitmap[F]
        bitmap: Bitmap[F]
    BitIter*[Z: static uint] = object
        bitmap: Bitmap[Z]

# proc newGroupIter*[N: static uint](seeds: Bitmap[N], bitmap: Bitmap[N]): GroupIter[N] =
#     GroupIter[N](seeds: seeds, bitmap: bitmap)

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
        Bitmap[size](edgeMasks[size][ord(right)]),
        Bitmap[size](edgeMasks[size][ord(down)]),
        Bitmap[size](edgeMasks[size][ord(left)]),
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

    dilation = dilation.bitor((bitmap shl 1).bitand(edgeMask(bitmap.N)[ord(right)].bitnot).bitand(boardMask(bitmap.N)))
    dilation = dilation.bitor((bitmap shr 1).bitand(edgeMask(bitmap.N)[ord(left)].bitnot))
    dilation = dilation.bitor((bitmap shl bitmap.N).bitand(boardMask(bitmap.N)))
    dilation = dilation.bitor((bitmap shr bitmap.N))

    return dilation

proc floodFill*(bitmap: Bitmap, mask: Bitmap): Bitmap =
    var seed = bitmap.bitand(mask)

    while true:
        let next: uint64 = (uint64 seed).dilate().bitand(uint64 mask)
        if next == seed:
            return seed
        seed = next

    return seed

proc groups*[N: static uint](btmap: Bitmap[N]): GroupIter[N]  =
    GroupIter[N](seeds: btmap, bitmap: btmap)

proc groupsFrom*[N](bitmap: Bitmap[N], seeds: Bitmap[N]): GroupIter[N] =
    assert(seeds.bitand(bitnot self) == 0'u64, "provided seeds are not a subset of the bitmap")
    
    (seeds, bitmap)

proc width*[N: static uint](bitmap: Bitmap[N]): uint =
    var rowMask = edgeMask(N)[ord(up)]
    var rowAggregate = default(Bitmap[N])
    for i in 0 ..< N:
        let row = bitmap.bitand(rowMask)
        rowAggregate = rowAggregate.bitor(row shl (i * N))
        rowMask = rowMask shr N
    
    return uint rowAggregate.countSetBits()

proc height*[N: static uint](bitmap: Bitmap[N]): uint =
    var colMask = edgeMask(N)[ord(left)]
    var colAggregate = default(Bitmap[N])
    for i in 0 ..< N:
        let col = bitmap.bitand(colMask)
        colAggregate = colAggregate.bitor(col shl i)
        colMask = colMask shr 1
    
    return uint colAggregate.countSetBits()

proc lowestBit*[N](bitmap: Bitmap[N]): Bitmap[N] =
    let remainder = bitmap.bitand(bitmap - 1)
    return bitmap.bitand(bitnot remainder)

# proc `$`*[N: static uint](bitmap: Bitmap[N]): string =
    
#     let rowMask = 0xFFFFFFFFFFFFFFFF shr (64 - N)
#     let columnMask = 1
#     var result = ""
#     for y in 0 ..< N:
#         if y > 1: result.add("/")
#         let row = (bitmap shr (N * N - y * N)).bitand(rowMask)
#         for x in 0 ..< N:
#             let column = (row shr (N - x)).bitand(columnMask)
#             echo "column: ", column
#             result.add(&"{column}")
#     return result

proc bits*[Z: static uint](btmap: Bitmap[Z]): BitIter[Z] =
    BitIter[Z](bitmap: btmap)

proc nextGroup*[F: static uint](iterStart: GroupIter[F]): iterator(): Bitmap[F] =
    return iterator(): Bitmap[F] =
        var iter = iterStart
        while iter.seeds != 0'u64:
            let seed = iter.seeds.lowestBit()
            echo fmt"seed: `{seed:#b}`"
            echo fmt"iter.bitmap: `{iter.bitmap:#b}`"
            let group = floodFill(seed, Bitmap[F](iter.bitmap))
            iter.seeds = iter.seeds.bitand( bitnot group )
            iter.bitmap = iter.bitmap.bitand( bitnot group )
            echo fmt"group: `{group:#b}`"
            yield Bitmap[iter.F](group)

proc nextBit*[Z: static uint](iterStart: BitIter[Z]): iterator(): Bitmap[Z] =
    return iterator(): Bitmap[Z] =
        var iter = iterStart
        while iter.bitmap != 0'u64:
            let remainder = iter.bitmap.bitand(iter.bitmap - 1)
            let bit = iter.bitmap.bitand(bitnot remainder)
            iter.bitmap = remainder
            yield bit