from tile import Piece
import ../util/error
import regex
import std/strformat, std/parseutils, std/strutils

type
    PlayType* = enum
        move, undo

    Square* = tuple[row: int, column: int]

    Place* = Piece

    Direction* = enum 
        up, down, right, left

    Spread* = tuple[direction: Direction, pattern: seq[int]]

    MoveKind* = enum
        place, spread 

    MoveDetail* = object
        case kind*: MoveKind
        of place: placeVal*: Place
        of spread: spreadVal*: Spread

    Move* = tuple[square: Square, movedetail: MoveDetail]

proc `&`*[V: Move](x: string, mv: Move): string =
    x.add($mv)

template newSpread(dir: Direction, pattSeq: seq[int]): MoveDetail =
    MoveDetail(kind: spread, spreadVal: (direction: dir, pattern: pattSeq))

template newSpread(dir: Direction, pattStr: string): MoveDetail =
    var patSeq: seq[int]
    for c in pattStr:
        patSeq.add((""&c).parseInt())

    MoveDetail(kind: spread, spreadVal: (direction: dir, pattern: patSeq))

template newSquare*(r: int, col: int): Square =
    (row: r, column: col)

template newPlace(placeDet: Place): MoveDetail =
    MoveDetail(kind: place, placeVal: placeDet)

template newMove*(sq: Square, md: MoveDetail): Move =
     (square: sq, movedetail: md)

# proc defaultMove(): Move[Pl =
#     return (square: newSquare(0,0), movekind: default(Place))
    

proc toColNum(colStr: string): (int, Error) =
    if colStr == "" or colStr.len > 1: return (0, newError(&"invalid length {colStr.len}"))

    case colStr
    of "a": (0, default(Error))
    of "b": (1, default(Error))
    of "c": (2, default(Error))
    of "d": (3, default(Error))
    of "e": (4, default(Error))
    of "f": (5, default(Error))
    of "g": (6, default(Error))
    of "h": (7, default(Error))
    else: (0, newError( &"Invalid value for column {colStr}" ))

proc parseRow(rowStr: string, boardSize: int): (int, Error) =

    var rowStart: int
    if rowStr == "" or rowStr.parseInt(rowStart) != 1: return (0, newError("Incorrect number of row elements"))
    let row = boardSize - rowStart
    if row < 0: return (0, newError("given row number is too large"))
    return (row, default(Error))


proc parseDirection(directionStr: string): (Direction, Error) =
    if directionStr == "" or directionStr.len > 1: return (default(Direction), newError("direction string is invalid length"))
    case directionStr:
    of "+": (up, default(Error))
    of "-": (down, default(Error))
    of ">": (right, default(Error))
    of "<": (left, default(Error))
    else: (default(Direction), newError("Invalid direction"))

proc parseMove*(moveString: string, boardSize: int): (PlayType, Move, Error) =

    var defMove: Move
    
    if moveString == "undo": return (undo, defMove, default(Error))

    var capts: seq[string] = @[]
    
    match moveString, rex"^([1-9])?([CS])?([a-h])([1-8])(([+\-<>])(\d+)?)?$":
        capts = matches

    if capts == @[]: return (default(PlayType), defMove, newError("move does not fit expected pattern"))
    
    var captIdx = 0;
    var stackAmt: int
    if capts[captIdx].parseInt(stackAmt) <= 0:
        stackAmt = 0
    captIdx += 1

    var pieceType = flat

    case capts[captIdx]
    of "C": 
        pieceType = cap
    of "S": 
        pieceType = wall
    of "F": 
        pieceType = flat
    else: discard

    captIdx += 1

    var (col, err) = capts[captIdx].toColNum
    if ?err:
        err.add(&"Error Parsing move: {moveString}")
        return (default(PlayType), defMove, err)
    captIdx += 1

    var (row, rowErr) = capts[captIdx].parseRow(boardSize)
    if ?rowErr:
        rowErr.add(&"Error parsing row for move: {moveString}")
    captIdx += 1

    if stackAmt <= 0 and capts[captIdx] == "": return (move, newMove(newSquare(row, col), newPlace(pieceType)), default(Error))
    captIdx += 1

    var (direction, dirErr) = capts[captIdx].parseDirection()
    if ?dirErr:
        dirErr.add(&"Error parsing direction of throw: {capts[captIdx]}")
        return (default(PlayType), defMove, dirErr)
    captIdx += 1

    if capts[captIdx] == "": return (move, newMove(newSquare(row, col), newSpread(direction, @[stackAmt])), default(Error))

    return (move, newMove(newSquare(row, col), newSpread(direction, capts[captIdx])), default(Error))

    

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

