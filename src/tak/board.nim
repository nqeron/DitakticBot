import tile
import std/strutils, std/strformat

from move import Square, Move, Direction, Spread, Place

type
    Board*[N: static uint] = array[N, array[N, Tile]]

proc newBoard*(size: static uint): Board[size] =
    var b: array[size, array[size, Tile]]
    for x in b.mitems:
        for y in x.mitems:
            y = default(Tile)
    Board[size](b)

proc isSquareOutOfBounds*(board: Board, square: Square): bool =
    return (square.row < 0 or square.row >= board.N or square.column < 0 or square.column >= board.N)

proc condenseBlanks(rowSeq: var seq[string], blanks: int) =
    if blanks < 1:
        return

    if blanks == 1:
        rowSeq.add("x")
    else:
        rowSeq.add(&"x{blanks}")

proc getTPSBoard*(board: Board): string =

    var colIdx = 0
    var colSeq: seq[string]

    while colIdx < board.len:
        var rowIdx = 0

        var rowSeq: seq[string]
        var blankCount = 0

        while rowIdx < board[colIdx].len:

            let tile: Tile = board[colIdx][rowIdx]

            if tile.isEmpty:
                blankCount += 1
                rowIdx += 1
                continue

            rowSeq.condenseBlanks(blankCount)
            blankCount = 0
            
            var stackStr = $tile

            rowSeq.add(stackStr)
            rowIdx += 1
            
        rowSeq.condenseBlanks(blankCount)
        
        let colStr = rowSeq.join(",")

        colSeq.add(colStr)

        colIdx += 1

    let tpsStr = colSeq.join("/")
    return tpsStr