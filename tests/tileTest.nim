import std/unittest, std/sequtils, std/strutils, std/sugar, std/strformat

import ../src/tak/tile
import ../src/util/error

import genUtil

proc debug(clr: Color): string =
    $clr.numVal

proc debug(piece: Piece, clr: Color): string =
    case piece
    of flat:
        clr.debug
    of wall:
        "S"
    of cap:
        "C"

proc debug(tile: Tile): string =
    result = tile.stack[0 ..< ^1].map( (clr) => clr.debug).join("")
    case tile.piece:
        of flat:
            result.add(tile.stack[^1].debug)
        of wall:
            result.add(tile.stack[^1].debug & "S")
        of cap:
            result.add(tile.stack[^1].debug & "C")



func roundTrip[R] (typ: R, val: string): bool =
    if R is Tile:
        var (tile, err) = val.parseTile
        if ?err:
            return false
        return tile.debug == val
    elif R is Piece:
        var (piece, clr, err) = val.parsePiece
        if ?err:
            return false
        return debug(piece, clr) == val
    elif R is Color:
        var (clr, err) = val.parseColor
        if ?err:
            return false
        return clr.debug == val
    return false

suite "color":

    test "correct roundtrip":
        checkRoundTripAll(["1","2"], func(c: string): bool = white.roundTrip(c))

    test "incorrect color parse":
        checkRoundTripAll(["0", "5", "z", "q", "c", "C"], func(c: string): bool = not white.roundTrip(c))

    test "correct color to value":
        checkEqAll([ (Color.white, 1), (Color.black, 2)], func(c: Color): int = c.numVal)

suite "piece":

    test "correct roundtrip":
        checkRoundTripAll( [ "1", "2", "S", "C"], func(c: string): bool = flat.roundTrip(c) )
        
    test  "incorrect piece parse":
        checkRoundTripAll( [ "Q", "3", "s", "c"], func(c: string): bool = not flat.roundTrip(c) )

suite "tile":

    test "correct tile parse":

        checkRoundTripAll( ["1", "2", "1S", "2C", "11211221", "22221C"], func(c: string): bool = (default(Tile)).roundTrip(c))

    test "incorrect tile parse":
        checkRoundTripAll(["", "S", "C", "123", "12P", "hi", "a", "1SC"], func(c: string): bool = not (default(Tile)).roundTrip(c))