import tile
import std/sequtils, std/sugar, std/strutils, std/strformat

from move import Square, Move, Direction, Spread, Place

type
    Board* = seq[seq[Tile]]

proc newBoard*(size: int): Board =
     result = newSeqWith(size, newSeq[Tile](size))

proc isSquareOutOfBounds*(board: Board, square: Square): bool =
    let N = board.len
    return (square.row < 0 or square.row >= N or square.column < 0 or square.column >= N)

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

            let tile = board[colIdx][rowIdx]

            if tile.isTileEmpty:
                blankCount += 1
                rowIdx += 1
                continue

            rowSeq.condenseBlanks(blankCount)
            blankCount = 0
            
            var stackStr = tile.stack.map( c => $c.numVal).join("")
            
            case tile.piece
            of cap:
                stackStr.add("C")
            of wall:
                stackStr.add("S")
            of flat: discard

            rowSeq.add(stackStr)
            rowIdx += 1
            
        rowSeq.condenseBlanks(blankCount)
        
        let colStr = rowSeq.join(",")

        colSeq.add(colStr)

        colIdx += 1

    let tpsStr = colSeq.join("/")
    return tpsStr