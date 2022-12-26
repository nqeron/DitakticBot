import ../util/error

type
    Color* = enum
        white, black

    Piece* = enum
        flat, wall, cap

    Tile* = object 
        piece*: Piece
        stack*: seq[Color]

proc parseColor*(val: char): (Color, Error) =
    case val:
    of '1': result = (Color.white, default(Error))
    of '2': result = (Color.black, default(Error))
    else: result = (default(Color), newError("Color must be 1 or 2") )

proc parsePiece*(val: char): (Piece, Color, Error) =
    case val:
    of 'S': result = (Piece.wall, default(Color), default(Error))
    of 'C': result = (Piece.cap, default(Color), default(Error))
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
        var (piece, clr, err) = val[0].parsePiece
        if ?err: 
            err.add("Tile could not parse single piece")
            return (default(Tile), err)

        return (Tile(piece: piece, stack: @[clr]), default(Error))

    var out_seq: seq[Color]
    for c in val[0 ..< ^1]:
        var (clr, err) = parseColor(c)
        if ?err: 
            err.add("Error parsing piece in stack")
            return (default(Tile), err)

        out_seq.add(clr)

    var (piece, clr, err) = val[^1].parsePiece

    if ?err: 
        err.add("Error parsing top piece")
        return (default(Tile), err)

    if piece == Piece.flat:
        out_seq.add(clr)

    return (Tile(piece: piece, stack: out_seq), default(Error))

proc isTileEmpty*(self: Tile): bool =
    self.stack == @[]

proc topTile*(self: Tile): tuple[piece: Piece, color: Color] =
    if not self.isTileEmpty:
        return (self.piece, self.stack[^1])

proc add*(tile: Tile, to_add: seq[Color], piece: Piece): Tile =

    if tile.stack == @[]:
        return default(Tile)
  
    if to_add == @[]:
        return Tile(piece: tile.piece, stack: tile.stack)

    var out_stack = tile.stack
    out_stack.add(to_add)
    result = Tile(piece: piece, stack: out_stack)

proc `not`*(clr: Color): Color =
    case clr
    of white: return black
    of black: return white

proc numVal*(clr: Color): int = 
    case clr
    of white: 1
    of black: 2