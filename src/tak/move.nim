from tile import Piece
import ../util/error
import regex
import std/strformat, std/parseutils, std/strutils, std/sequtils, std/sugar

type
    PlayType* = enum
        move, undo

    Square* = tuple[row: uint, column: uint]

    Place* = Piece

    Direction* = enum 
        up, down, right, left

    Spread* = tuple[direction: Direction, pattern: seq[uint]]

    MoveKind* = enum
        place, spread 

    MoveDetail* = object
        case kind*: MoveKind
        of place: placeVal*: Place
        of spread: spreadVal*: Spread

    Move* = tuple[square: Square, movedetail: MoveDetail]

proc `&`*[V: Move](x: string, mv: Move): string =
    x.add($mv)

template newSpread*(dir: Direction, pattSeq: seq[uint]): MoveDetail =
    MoveDetail(kind: spread, spreadVal: (direction: dir, pattern: pattSeq))

template newSpread(dir: Direction, pattStr: string): MoveDetail =
    var patSeq: seq[uint]
    for c in pattStr:
        patSeq.add((""&c).parseUInt())

    MoveDetail(kind: spread, spreadVal: (direction: dir, pattern: patSeq))

template newSquare*(r: uint, col: uint): Square =
    (row: r, column: col)

template newPlace*(placeDet: Place): MoveDetail =
    MoveDetail(kind: place, placeVal: placeDet)

template newMove*(sq: Square, md: MoveDetail): Move =
     (square: sq, movedetail: md)

# proc defaultMove(): Move[Pl =
#     return (square: newSquare(0,0), movekind: default(Place))

proc `$`(direction: Direction): string =
    case direction:
    of up: "+"
    of down: "-"
    of left: "<"
    of right: ">"
    

proc toColNum(colStr: string): (uint, Error) =
    if colStr == "" or colStr.len > 1: return (0'u, newError(&"invalid length {colStr.len}"))

    case colStr
    of "a": (0'u, default(Error))
    of "b": (1'u, default(Error))
    of "c": (2'u, default(Error))
    of "d": (3'u, default(Error))
    of "e": (4'u, default(Error))
    of "f": (5'u, default(Error))
    of "g": (6'u, default(Error))
    of "h": (7'u, default(Error))
    else: (0'u, newError( &"Invalid value for column {colStr}" ))

proc parseRow(rowStr: string, boardSize: uint): (uint, Error) =

    var rowStart: uint
    if rowStr == "" or rowStr.parseUInt(rowStart) != 1: return (0'u, newError("Incorrect number of row elements"))
    let row = boardSize - rowStart
    if row < 0: return (0'u, newError("given row number is too large"))
    return (row, default(Error))


proc parseDirection(directionStr: string): (Direction, Error) =
    if directionStr == "" or directionStr.len > 1: return (default(Direction), newError("direction string is invalid length"))
    case directionStr:
    of "+": (up, default(Error))
    of "-": (down, default(Error))
    of ">": (right, default(Error))
    of "<": (left, default(Error))
    else: (default(Direction), newError("Invalid direction"))

proc parseMove*(moveString: string, boardSize: uint): (PlayType, Move, Error) =

    var defMove: Move
    
    if moveString == "undo": return (undo, defMove, default(Error))

    var capts: seq[string] = @[]
    
    match moveString, rex"^([1-9])?([CS])?([a-h])([1-8])(([+\-<>])(\d+)?)?$":
        capts = matches

    if capts == @[]: return (default(PlayType), defMove, newError("move does not fit expected pattern"))
    
    var captIdx = 0;
    var stackAmt: uint
    if capts[captIdx].parseUInt(stackAmt) <= 0:
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

    if stackAmt == 0: stackAmt = 1

    if capts[captIdx] == "": return (move, newMove(newSquare(row, col), newSpread(direction, @[stackAmt])), default(Error))

    return (move, newMove(newSquare(row, col), newSpread(direction, capts[captIdx])), default(Error))

    

proc nextInDir*(square: Square, direction: Direction, amt: uint = 1): Square =
    case direction:
    of up:
        (row: square.row - amt, column: square.column)
    of down:
        (row: square.row + amt, column: square.column)
    of left:
        (row: square.row, column: square.column - amt)
    of right:
        (row: square.row, column: square.column + amt)

proc ptnVal*(square: Square, size: uint): string =
    if square.row >= size or square.column >= size: return ""
    let colPTN = 
        case square.column
        of 0: "a"
        of 1: "b"
        of 2: "c"
        of 3: "d"
        of 4: "e"
        of 5: "f"
        of 6: "g"
        of 7: "h"
        else: ""
    
    if colPTN == "": return ""
    let rowPTN = $(size - square.row)

    return &"{colPTN}{rowPTN}"

proc ptnVal*(place: Place, expanded = false): string =
    case place
    of flat:
        if expanded: "F" 
        else: ""
    of wall: "S"
    of cap: "C"



proc ptnVal*(move: Move, size: uint, expanded: bool = false): string =
    case move.movedetail.kind
    of place:
        move.movedetail.placeVal.ptnVal(expanded) & move.square.ptnVal(size)
    of spread:
        let spread = move.movedetail.spreadVal
        var stackAmt: uint = 0
        var pattStr = ""
        
        if spread.pattern.len > 0:
            stackAmt = foldl(spread.pattern, a + b, 0'u)
            pattStr = if expanded and spread.pattern.len == 1: $spread.pattern[0] elif spread.pattern.len == 1: "" else: spread.pattern.map((it) => $it).join("")

        let stackAmtStr = if expanded or stackAmt > 1: $stackAmt else: ""

        return  &"{stackAmtStr}{move.square.ptnVal(size)}{$spread.direction}{pattStr}"

proc parseSquare*(squareStr: string, size: uint): (Square, Error) =

    match squareStr, rex"^([a-hA-H])([1-8])$":
        let (col, _) = matches[0].toLower.toColNum
        let row = size - parseUInt(matches[1]) 
        # - 1'u
        let sq = newSquare(row, col)

        return (sq, default(Error))

    return (default(Square), newError("Invalid square"))

proc dirTo*(sqFrom: Square, sqTo: Square): (Direction, Error) =
    if sqFrom.row < sqTo.row:
        (down, default(Error))
    elif sqFrom.row > sqTo.row:
        (up, default(Error))
    elif sqFrom.column < sqTo.column:
        (right, default(Error))
    elif sqFrom.column > sqTo.column:
        (left, default(Error))
    else:
        (default(Direction), newError("identical squares"))

# proc getToSquareFromMove*(move: Move): Square =
#     case move.direction:
#     of up: return newSquare(row + move.pattSeq.len, col)
#     of down: return newSquare(row + move.pattSeq.len, col)
#     of up: return newSquare(row + move.pattSeq.len, col)
#     of up: return newSquare(row + move.pattSeq.len, col)

