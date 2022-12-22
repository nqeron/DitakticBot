import std/strformat,  std/strutils, std/sequtils

type
    Color = enum
        white, black

    Piece = enum
        flat, wall, cap

    Tile = object 
        piece: Piece
        stack: seq[Color]

    Board[N: uint8] = array[N, array[N, Tile]]

    Square = tuple[row: int, column: int]

    Place = Piece

    Direction = enum 
        up, down, right, left

    Spread = tuple[direction: Direction, pattern: seq[int]]

    MoveKind = Place | Spread

    Move[M: MoveKind] = tuple[square: Square, movekind: M]


proc newBoard[N: uint8] (data: array[N, array[N, Tile]]): Board[N] =
    result = data

proc isTileEmpty(self: Tile): bool =
    self.stack == @[]

proc topTile(self: Tile): tuple[piece: Piece, color: Color] =
    if not self.isTileEmpty:
        return (self.piece, self.stack[^1])

proc isOutOfBounds(square: Square, board: Board): bool =
    let N = board.len
    return (square.row < 0 or square.row >= N or square.column < 0 or square.column >= N)

proc `[]`(board: Board, square: Square): Tile =
    result = board[square.column][square.row]

proc `[]=`(board: var Board, square: Square, tile: Tile) {. inline .} =
    board[square.column][square.row] = tile
    

#proc `=` (tile:)
  

proc add(tile: Tile, to_add: seq[Color], piece: Piece): Tile =
  var out_stack = tile.stack
  out_stack.add(to_add)
  result = Tile(piece: piece, stack: out_stack)


proc nextInDir(square: Square, direction: Direction): Square =
    case direction:
    of up:
        (row: square.row, column: square.column + 1)
    of down:
        (row: square.row, column: square.column - 1)
    of left:
        (row: square.row - 1, column: square.column)
    of right:
        (row: square.row + 1, column: square.column)


proc executePlace(board: var Board, square: Square, piece: Piece, color: Color): bool =
    # TODO - check that piece is still available
    if  not square.isOutOfBounds(board):
        if board[square].isTileEmpty: #check if tile is empty
            board[square] = Tile(piece: piece, stack: @[color])
            return true
    return false

proc executeSpread(board: var Board, square: Square, direction: Direction, pattern: seq[int], color: Color): bool =
    if square.isOutOfBounds(board):
        return false
    var tile = board[square]
    if tile.isTileEmpty:
        return false

    let count = pattern.len
    case direction:
    of up:
        if square.column + count >= board.len:
            return false
    of down:
        if square.column - count < 0:
            return false
    of left:
        if square.row - count < 0:
            return false
    of right:
        if square.row + count > board.len:
            return false
    if not (tile.topTile.color == color):
        return false

    let numPieces = foldl(pattern, a + b)
    
    if tile.stack.len < numPieces:
        return false 

    let origBoardState = board
    
    var toDrop = tile.stack[^numPieces..^1]

    board[square] = if numPieces == len(tile.stack): default(Tile) else: Tile(piece: tile.piece, stack: tile.stack[0 ..< ^numPieces])

    var pattern_idx = 0

    var nextSquare: Square = square.nextInDir(direction)
    while pattern_idx < pattern.len:

        case board[nextSquare].topTile.piece
        of wall:
            if not( tile.piece == cap and (pattern_idx == (len(pattern) - 1)) and pattern[pattern_idx] == 1): 
                board = origBoardState
                return false 
        of cap:
            board = origBoardState
            return false
        of flat: discard

        board[nextSquare] = board[nextSquare].add(toDrop[0..<pattern[pattern_idx]], 
                                if pattern_idx == (len(pattern) - 1): tile.piece else: flat)
        
        toDrop = toDrop[pattern[pattern_idx]..^1]
        nextSquare = nextSquare.nextInDir(direction)
        pattern_idx += 1

    #take top pieces - sum of pattern
    #drop one by one onto square in direction
    return true

proc executeMove (self: var Board, move: Move[Place], color: Color): bool = 
    self.executePlace(move.square, move.movekind, color)

proc executeMove (self: var Board, move: Move[Spread], color: Color): bool =
    let spread = move.movekind
    self.executeSpread(move.square, spread.direction, spread.pattern, color)
    
var temp: array[5, array[5, Tile]]

var myBoard = newBoard(temp) 

#[
echo $myBoard

echo myBoard[0][1].isTileEmpty

echo myBoard[0][1].topTile
]#

var success = executeMove(myBoard, (square: (0, 0), movekind: flat), black)
success = success and executeMove(myBoard, (square: (0, 4), movekind: cap), white)
success = success and executeMove(myBoard, (square: (1, 4), movekind: flat), white)
success = success and executeMove(myBoard, (square: (3, 4), movekind: wall), white)
success = success and executeMove(myBoard, (square: (0, 4), movekind: Spread((direction: right, pattern: @[1]))), white)

echo $myBoard, "", success

success = success and executeMove(myBoard, (square: (1, 4), movekind: Spread((direction: right, pattern: @[1,1]))), white)


echo $myBoard, "", success
#executeMove(myBoard, Move(square: (2, 4)), movekind: Place(flat))

#myBoard.executePlace(Square(row: 1,column: 1), black, cap)