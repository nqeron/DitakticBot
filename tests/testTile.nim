import std/unittest, std/sequtils, std/strutils, std/sugar

import ../src/tak/tile
import ../src/util/error

import genUtil

func roundTrip (val: string): bool =
    let (tile, err) = val.parseTile
    if ?err:
        return false
    $tile == val

suite "color":

    test "correct roundtrip":
        checkEqAll([("1", (white, default(Error))),("2", (black, default(Error)))], func(c: string): (Color, Error) = c.parseColor)

    test "incorrect color parse":
        checkRoundTripAll(["0", "5", "z", "q", "c", "C"], func(c: string): bool = ?c.parseColor[1])

    test "correct color to value":
        checkEqAll([ (Color.white, 1), (Color.black, 2)], func(c: Color): int = c.numVal)

suite "piece":

    test "correct roundtrip":
        checkEqAll( [ ("1", (flat, white, default(Error))), ("2", (flat, black, default(Error)))
        , ("S", (wall, default(Color), default(Error))), ("C", (cap, default(Color), default(Error)))], func(c: string): (Piece, Color, Error) = c.parsePiece)
        
    test  "incorrect piece parse":
        checkRoundTripAll( [ "Q", "3", "s", "c"], func(c: string): bool = ?c.parsePiece[2] )

suite "tile":

    test "correct tile parse":

        checkRoundTripAll( ["1", "2", "1S", "2C", "11211221", "22221C"], func(c: string): bool = roundTrip(c))

    test "incorrect tile parse":
        checkRoundTripAll(["", "S", "C", "123", "12P", "hi", "a", "1SC"], func(c: string): bool = not roundTrip(c))