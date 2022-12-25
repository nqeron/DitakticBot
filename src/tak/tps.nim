import game as gm
from board import Board, newBoard
from tile import Tile, Piece, Color, isTileEmpty
import std/strutils, std/sequtils, std/strformat
import ../util/error

proc parseColor(val: char): (Color, Error) =
    case val:
    of '1': result = (Color.white, default(Error))
    of '2': result = (Color.black, default(Error))
    else: result = (default(Color), newError("Color must be 1 or 2") )

proc parsePiece(val: char): (Piece, Color, Error) =
    case val:
    of 'S': result = (Piece.wall, default(Color), default(Error))
    of 'C': result = (Piece.cap, default(Color), default(Error))
    else:
        var (clr, err) = val.parseColor
        err.add("Piece is not valid")
        result = (Piece.flat, clr, err)

proc parseTile(val: string): (Tile, Error) =
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

proc getPlyFromMove(color: Color, moveNum: int): uint16 =
    case color
    of Color.white:
        (uint16 moveNum - 1) * 2'u16
    of Color.black:
        (uint16 moveNum - 1) * 2'u16 + 1'u16

proc parseGame*(val: string, swap: bool = true, komi: int8 = 0'i8, stoneCountConst: StoneCounts = default(StoneCounts)): (Game, Error) =
    
    let segments = val.split(' ')

    if segments.len <= 0 or segments.len > 3: return (default(Game), newError("TPS string has too many segments"))
    let boardStr = segments[0]
    let color = segments[1]
    let movNumStr = segments[2]

    if color.len > 1: return (default(Game), newError("Color flag in TPS string is more than 1 char"))

    var (to_play_clr, err) = parseColor(color[0])

    if ?err:
        err.add("Could not parse Color from TPS move section") 
        return (default(Game), err)

    let movInt = movNumStr.parseInt()
    if movInt == 0: return (default(Game), newError("ply/move index starts at 1"))
    let cur_ply = to_play_clr.getPlyFromMove(movInt)


    if boardStr.len <= 0: return (default(Game), newError("Board segment is empty"))

    let rows = boardStr.split('/')
    let size = rows.len

    var boardB: Board = newBoard(size)   
    #if board.len <= 0: return false

    let boardStringSeq = rows.mapIt(it.split(','))

    var colIdx = 0

    let (stones, caps) = stones_for_size( uint8 size )
 
    var  stoneCountsT: StoneCounts =
        if stoneCountConst == default(StoneCounts):
            (wStones: stones, wCaps: caps, bStones: stones, bCaps: caps)
        else:
            default(uint8 size)
        
    while colIdx < boardStringSeq.len:

        var parseRowIdx = 0
        var rowIdx = 0
        while parseRowIdx < boardStringSeq[colIdx].len:

            let tileStr = boardStringSeq[colIdx][parseRowIdx]

            if tileStr.len == 2 and tileStr[0] == 'x':
                let blanks = parseInt( tileStr[1 .. ^1] )

                if blanks+rowIdx > boardStringSeq.len: return (default(Game), 
                    newError( &"Parsing tps at col: {colIdx} row: {parseRowIdx} number of blanks exceeds board size"))

                
                boardB[colIdx][rowIdx ..< rowIdx + blanks] = newSeqWith(blanks, default(Tile))

                parseRowIdx += 1
                rowIdx += blanks
                continue

            var (tileParsed, tileErr) = tileStr.parseTile
            
            if ?tileErr:
                tileErr.add(&"Error parsing tps at col: {colIdx} row: {parseRowIdx}")
                return (default(Game), tileErr)

            boardB[colIdx][rowIdx] = tileParsed

            if tileParsed.isTileEmpty:
                parseRowIdx += 1
                rowIdx += 1
                continue

            for clr in tileParsed.stack[0 ..< ^1]:
                err = stoneCountsT.dec(clr, flat)
                err.add(&"Error subtracting stones at col: {colIdx}, {rowIdx}")
                if ?err: return (default(Game), err)
            
            err = stoneCountsT.dec(tileParsed.stack[^1], tileParsed.piece)

            err.add(&"Error subtracting top piece at col: {colIdx}, {rowIdx}")
            if ?err: return (default(Game), err)

            parseRowIdx += 1
            rowIdx += 1

        colIdx += 1

    var game = Game( board: boardB, to_play: to_play_clr, ply: cur_ply, stoneCounts: stoneCountsT, half_komi: komi, reversible_plies: 0'u8, swap: swap)

    return (game, default(Error))
            


    
