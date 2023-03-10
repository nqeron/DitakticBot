import game as gm
from board import Board, newBoard
import move
import tile
import std/strutils, std/sequtils, std/strformat
import ../util/error

proc getPlyFromMove(color: Color, moveNum: int): uint16 =
    case color
    of Color.white:
        (uint16 moveNum - 1) * 2'u16
    of Color.black:
        (uint16 moveNum - 1) * 2'u16 + 1'u16


proc parseGame*(val: string, size: static uint, swap: bool = true, komi: int8 = 0'i8, stoneCountConst: StoneCounts = default(StoneCounts, size)): (Game[size], Error) =
    
    let segments = val.split(' ')

    if segments.len <= 0 or segments.len > 3: return (default(Game[size]), newError("TPS string has too many segments"))
    let boardStr = segments[0]
    let color = segments[1]
    let movNumStr = segments[2]

    if color.len > 1: return (default(Game[size]), newError("Color flag in TPS string is more than 1 char"))

    var (to_play_clr, err) = parseColor(color)

    if ?err:
        err.add("Could not parse Color from TPS move section") 
        return (default(Game[size]), err)

    let movInt = movNumStr.parseInt()
    if movInt == 0: return (default(Game[size]), newError("ply/move index starts at 1"))
    let cur_ply = to_play_clr.getPlyFromMove(movInt)


    if boardStr.len <= 0: return (default(Game[size]), newError("Board segment is empty"))

    let rows = boardStr.split('/')
    if (uint rows.len) != size: return (default(Game[size]), newError("Board segment has incorrect number of rows"))

    var boardB: Board[size] = newBoard(size)

    let boardStringSeq = rows.mapIt(it.split(','))

    var colIdx = 0

    let (stones, caps) = stones_for_size( uint8 size )
 
    var  stoneCountsT: StoneCounts =
        if stoneCountConst == default(StoneCounts, size):
            (wStones: stones, wCaps: caps, bStones: stones, bCaps: caps)
        else:
            default(StoneCounts, size)
        
    while colIdx < boardStringSeq.len:

        var parseRowIdx = 0
        var rowIdx = 0
        while parseRowIdx < boardStringSeq[colIdx].len:

            let tileStr = boardStringSeq[colIdx][parseRowIdx]

            if tileStr.len == 2 and tileStr[0] == 'x':
                let blanks = parseInt( tileStr[1 .. ^1] )

                if blanks+rowIdx > boardStringSeq.len: return (default(Game[size]), 
                    newError( &"Parsing tps at col: {colIdx} row: {parseRowIdx} number of blanks exceeds board size"))

                
                # do nothing - these should be empty tiles?

                parseRowIdx += 1
                rowIdx += blanks
                continue

            var (tileParsed, tileErr) = tileStr.parseTile

            
            if ?tileErr:
                tileErr.add(&"Error parsing tps at col: {colIdx} row: {parseRowIdx}")
                return (default(Game[size]), tileErr)

            boardB[colIdx][rowIdx] = tileParsed

            if tileParsed.isEmpty:
                parseRowIdx += 1
                rowIdx += 1
                continue

            let stackIter = tileParsed.getStackIter
            var idx: uint = 0
            for pcFull in stackIter.nextPieceBack:
                var (pcPart, clr) = pcFull
                pcPart = if idx == (tileParsed.len - 1'u): pcPart else: flat
                err = stoneCountsT.dec(clr, pcPart)
                err.add(&"Error subtracting stones at col: {colIdx}, {rowIdx}")
                if ?err: return (default(Game[size]), err)
                idx += 1

            parseRowIdx += 1
            rowIdx += 1

        colIdx += 1

    var game = Game[size]( board: boardB, to_play: to_play_clr, ply: cur_ply, stoneCounts: stoneCountsT, half_komi: komi, swap: swap, meta: default(Metadata[size]))

    game.recalculateMetadata()

    return (game, default(Error))
            


    
