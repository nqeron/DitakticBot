import ../util/error
import std/bitops

type
    Color* = enum
        white = 0x01, black = 0x02

    Piece* = enum
        flat = 0x10, wall = 0x20, cap = 0x40

    Tile* = distinct uint32

    StackIter* = object
        tile: Tile
        iTop: uint
        iBottom: uint
    

proc `default`*(t: typedesc[Tile]): Tile = Tile(0b1000)

const MaxStackHeight*: uint = 32'u - 4'u

proc fromPiece*(piece: Piece, color: Color): Tile =
    Tile(0b10000'u32.bitor((uint32 piece) shr 3).bitor((uint32 color) - 1))

func `len`*(tile: Tile): uint =
    MaxStackHeight - (uint countLeadingZeroBits(tile.uint32))

proc length*(tile: Tile): uint =
    MaxStackHeight - (uint countLeadingZeroBits(tile.uint32))

# proc `len`*(tile: var Tile): uint =
#     MaxStackHeight - (uint countLeadingZeroBits(tile.uint32))

proc isEmpty*(tile: Tile): bool =
    tile.length == 0

proc get*(tile: Tile, idx: uint): (Piece, Color) =
    assert(idx < tile.len)

    let piece = case ((uint32 (tile.uint shr tile.length)).bitand(0x07'u32) shl 4)
    of 0x10: Piece.flat
    of 0x20: Piece.wall
    of 0x40: Piece.cap
    else: Piece.flat

    let color = if (tile.uint32 shr idx).bitand(0x01'u32) == 0: white else: black
    (piece, color)

proc topPiece*(tile: Tile): (Piece, Color) =
    tile.get(tile.len - 1)

proc add*(tile: var Tile, toAdd: Tile) = 
    assert((tile.length + toAdd.length) <= MaxStackHeight, "Tile stack overflow")

    if not toAdd.isEmpty:
        let mask = uint32.high shl tile.length
        var ed = tile.uint32.bitand(bitnot mask)
        ed = ed.bitor(toAdd.uint32 shl tile.length)
        tile = Tile(ed)

proc addPiece*(tile: var Tile, piece: Piece, color: Color) =
    tile.add(fromPiece(piece, color))

proc take*(tile: var Tile, count: uint): Tile =
    assert(count <= tile.length, "Tile stack underflow")

    let remaining = tile.length - count
    let carryStack = Tile(tile.uint32 shr remaining)
    
    if remaining > 0:
        let mask = uint32.high shl remaining
        tile = Tile(tile.uint32.bitand(bitnot mask).bitor((0b1001'u32 shl remaining)))
    else:
        tile = default(Tile)

    carryStack

proc drop*(tile: var Tile, count: uint): Tile =
    assert(count <= tile.length, "Tile stack underflow")

    if count < tile.length:
        let mask = uint32.high shl count
        let dropStack = Tile(tile.uint32.bitand(bitnot mask).bitor(0b1001'u32 shl count))
        tile = Tile(tile.uint32 shr count)
        dropStack
    else:
        let dropStack = tile
        tile = default(Tile)
        dropStack

proc getStackIter*(stack: Tile): StackIter =
    StackIter(tile: stack, iTop: stack.length, iBottom: 0)

proc getHashRepr*(tile: Tile): (uint8, uint8) =
    if tile.isEmpty:
        return (0'u8, 0'u8)

    let mask = 0xFF'u8 shr (8 - min(tile.length, 8))
    let stackSegment = (tile.uint32 shr (max(tile.length, 8) - 8)).bitand(mask)
    let p1 = uint8 stackSegment.bitnot.bitand(mask)
    let p2 = uint8 stackSegment
    (p1, p2)

iterator nextPiece*(startIter: StackIter): (Piece, Color) =
    var iter = startIter
    while iter.iTop > iter.iBottom:
        iter.iTop -= 1
        yield iter.tile.get(iter.iTop) 

iterator nextPieceBack*(startIter: StackIter): (Piece, Color) =
    var iter = startIter
    while iter.iTop > iter.iBottom:
        iter.iBottom += 1
        yield iter.tile.get(iter.iBottom - 1)
            
proc `$`*(piece: Piece): string =
    case piece
    of flat: ""
    of cap: return "C"
    of wall: return "S"

proc `$`*(clr: Color): string =
    case clr
    of white: return "1"
    of black: return "2"

proc `$`*(tile: Tile): string =
    if tile.isEmpty:
        return "x"

    var builder = ""
    let stackIter = tile.getStackIter()
    var idx: uint = 0
    for pcFull in stackIter.nextPieceBack:
        let (piece, color) = pcFull
        builder.add($color)
        if idx == tile.len - 1:
            builder.add($piece)
        idx += 1
    return builder

proc parseColor*(val: string): (Color, Error) =
    case val:
    of "1": result = (Color.white, default(Error))
    of "2": result = (Color.black, default(Error))
    else: result = (default(Color), newError("Color must be 1 or 2") )

proc parsePiece*(val: string): (Piece, Color, Error) =
    case val:
    of "S": result = (Piece.wall, default(Color), default(Error))
    of "C": result = (Piece.cap, default(Color), default(Error))
    else:
        var (clr, err) = val.parseColor
        if ?err:
            err.add("Piece is not valid")
            return(default(Piece), default(Color), err)
        result = (Piece.flat, clr, err)

proc parseTile*(val: string): (Tile, Error) =
    if val == "x":
        return (default(Tile), default(Error))
    if val.len <= 0:
        return (default(Tile), newError("Tile is missing"))

    if val.len == 1:
        var (piece, clr, err) = ("" & val[0]).parsePiece
        if ?err: 
            err.add("Tile could not parse single piece")
            return (default(Tile), err)

        return (fromPiece(piece, clr), default(Error))

    var outTile: Tile = default(Tile)
    
    var valIdx = 0
    while valIdx < val.len:
        if valIdx == val.len - 2:
            var (piece, _, err) = ("" & val[valIdx+1]).parsePiece
            if ?err: 
                err.add("Error parsing piece in stack")
                return (default(Tile), err)
            case piece:
            of Piece.cap, Piece.wall:
                var (clr, colorErr) = ("" & val[valIdx]).parseColor
                if ?colorErr: 
                    colorErr.add("Error parsing piece in stack")
                    return (default(Tile), colorErr)
                outTile.addPiece(piece, clr)
                valIdx += 2
                continue
            else: discard

        var (clr, err) = ("" & val[valIdx]).parseColor
        if ?err: 
            err.add("Error parsing piece in stack")
            return (default(Tile), err)
        outTile.addPiece(flat, clr)
        valIdx += 1

    return (outTile, default(Error))

proc numVal*(clr: Color): int = 
    case clr
    of white: 1
    of black: 2

proc `not`*(clr: Color): Color =
    case clr
    of white: return black
    of black: return white

# proc getHashRepr(tile: Tile): (uint8, uint8) =
#     if !tile.isTileEmpty:
#         let mask = 0xFF'u8 shr (8 - min(8,len(tile.stack)))
#         let stackSegment = 