from tile import Piece

type
    Square* = tuple[row: int, column: int]

    Place* = Piece

    Direction* = enum 
        up, down, right, left

    Spread* = tuple[direction: Direction, pattern: seq[int]]

    MoveKind* = Place | Spread

    Move*[M: MoveKind] = tuple[square: Square, movekind: M]

proc `&`*[V: Move](x: string, mv: Move): string =
    x.add($mv)

template newSquare*(r: int, col: int): Square =
    (row: r, column: col)

template newMove*[M: MoveKind](sq: Square, mk: M): Move[M] =
    (square: sq, movekind: mk)
    

proc nextInDir*(square: Square, direction: Direction): Square =
    case direction:
    of up:
        (row: square.row, column: square.column + 1)
    of down:
        (row: square.row, column: square.column - 1)
    of left:
        (row: square.row - 1, column: square.column)
    of right:
        (row: square.row + 1, column: square.column)