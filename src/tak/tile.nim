type
    Color* = enum
        white, black

    Piece* = enum
        flat, wall, cap

    Tile* = object 
        piece*: Piece
        stack*: seq[Color]

proc isTileEmpty*(self: Tile): bool =
    self.stack == @[]

proc topTile*(self: Tile): tuple[piece: Piece, color: Color] =
    if not self.isTileEmpty:
        return (self.piece, self.stack[^1])

proc add*(tile: Tile, to_add: seq[Color], piece: Piece): Tile =
  var out_stack = tile.stack
  out_stack.add(to_add)
  result = Tile(piece: piece, stack: out_stack)

proc `not`*(clr: Color): Color =
    case clr
    of white: return black
    of black: return white