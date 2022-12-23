from game import Game, stones_for_size
from board import Board
from tile import Tile, Piece, Color
import std/strutils, std/sequtils

proc parseColor(val: char): (Color, bool) =
    case val:
    of '1': result = (Color.white, false)
    of '2': result = (Color.black, false)
    else: result = (default(Color), true)

proc parsePiece(val: char): (Piece, Color, bool) =
    case val:
    of 'S': result = (Piece.wall, default(Color), false)
    of 'C': result = (Piece.cap, default(Color), false)
    else:
        let (clr, err) = val.parseColor
        result = (Piece.flat, clr, err)

proc parseTile(val: string): (Tile, bool) =
    if val == "X":
        return (default(Tile), false)
    if val.len <= 0:
        return (default(Tile), true)

    if val.len == 1:
        let (piece, clr, err) = val[0].parsePiece
        if err: return (default(Tile), true)

        return (Tile(piece: piece, stack: @[clr]), false)

    var out_seq: seq[Color]
    for c in val[0 ..< ^1]:
        let (clr, err) = parseColor(c)
        if err: return (default(Tile), true)

        out_seq.add(clr)

    let (piece, clr, err) = val[^1].parsePiece

    if err: return (default(Tile), true)
    if piece == Piece.flat:
        out_seq.add(clr)

    return (Tile(piece: piece, stack: out_seq), false)

proc getPlyFromMove(color: Color, moveNum: int, swap: bool): uint16 =
    if moveNum == 1:
        if swap:
            case color:
            of Color.white:
                1
            of Color.black:
                0
        else:
            case color:
            of Color. white:
                0
            of Color.black:
                1
    else:
        case color:
        of Color.white:
            moveNum * 2
        of Color.black:
            moveNum * 2 + 1

proc parseGame*(val: string, swap: bool, komi: int8): (Game, bool) =
    
    let segments = val.split(' ')

    if segments.len <= 0 or segments.len > 3: return (default(Game), false)
    let boardStr = segments[0]
    let color = segments[1]
    let movNumStr = segments[2]

    if color.len > 1: return (default(Game), false)

    let (to_play_clr, err) = parseColor(color[0])

    if err: return (default(Game), false)

    let movInt = movNumStr.parseInt()
    let cur_ply = to_play_clr.getPlyFromMove(movInt, swap)

    if boardStr.len <= 0: return (default(Game), false)

    let rows = boardStr.split('/')
    let size = rows.len

    var boardB: Board = default(Board)
    
    #if board.len <= 0: return false

    let boardStringSeq = rows.mapIt(it.split(','))

    var colIdx = 0
    var rowIdx = 0

    let (stones, caps) = stones_for_size( uint8 size )

    var wStones = stones
    var wCaps = caps

    var bStones = stones
    var bCaps = caps

    while colIdx < boardStringSeq.len:

        rowIdx = 0

        while rowIdx < boardStringSeq[colIdx].len:

            let tileStr = boardStringSeq[colIdx][rowIdx]

            let (tileParsed, tileErr) = tileStr.parseTile

            echo tileParsed, "; ", tileErr
            
            if tileErr: return (default(Game), false)

            boardB[colIdx][rowIdx] = tileParsed

            for clr in tileParsed.stack[0..^1]:
                case clr:
                of black:
                    bStones -= 1
                of white:
                    wStones -= 1
            
            case tileParsed.piece:
            of cap:
                case tileParsed.stack[^1]:
                of white:
                    wCaps -= 1
                of black:
                    bCaps -= 1
            else:
                case tileParsed.stack[^1]:
                of white:
                    wStones -= 1
                of black:
                    bStones -= 1

            if wStones < 0 or bStones < 0 or wCaps < 0 or bCaps < 0: return (default(Game), false)
            
            rowIdx += 1

        colIdx += 1

    var game = Game( board: boardB, to_play: to_play_clr, ply: cur_ply, white_stones: wStones, white_caps: wCaps, black_stones: bStones, black_caps: bCaps, half_komi: komi, reversible_plies: 0'u8, swap: swap)

    return (game, true)
            


    
