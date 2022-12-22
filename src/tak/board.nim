from tile import Tile, Color, Piece

from move import Square, Move, Direction, Spread, Place

type
    
    Board*[N: static uint8] = array[N, array[N, Tile]]

proc newBoard*[N: static uint8] (data: array[N, array[N, Tile]]): Board[N] =
    result = data


proc isSquareOutOfBounds*(board: Board, square: Square): bool =
    let N = board.len
    return (square.row < 0 or square.row >= N or square.column < 0 or square.column >= N)
    