from tile import Tile, Color, Piece
import std/sequtils

from move import Square, Move, Direction, Spread, Place

type
    Board* = seq[seq[Tile]]

proc newBoard*(size: int): Board =
     result = newSeqWith(size, newSeq[Tile](size))

proc isSquareOutOfBounds*(board: Board, square: Square): bool =
    let N = board.len
    return (square.row < 0 or square.row >= N or square.column < 0 or square.column >= N)
    