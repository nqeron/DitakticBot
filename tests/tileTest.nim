import std/unittest, std/sequtils

import ../src/tak/tile
import ../src/util/error

import genUtil

suite "color":

    test "correct color parse":
        checkEqAll([('1', (Color.white, default(Error)) ),('2', (Color.black, default(Error))) ], func(c: char): (Color, Error) = c.parseColor)

    test "incorrect color parse":
        checkEqAll([('0', true), ('5', true), ('z', true),('q', true), ('c', true), ('C', true)], func(c: char): bool = ?c.parseColor[1])

    test "correct color to value":
        checkEqAll([ (Color.white, 1), (Color.black, 2)], func(c: Color): int = c.numVal)

suite "piece":

    test "correct piece parse":
        checkEqAll( [ ('1', (Piece.flat, Color.white, default(Error))), ('2', (Piece.flat, Color.black, default(Error))), ('S', (Piece.wall, default(Color), default(Error))), ('C', (Piece.cap, default(Color), default(Error))) ], func(c: char): (Piece, Color, Error) = c.parsePiece )
        
    test  "incorrect piece parse":
        checkEqAll( [ ('Q', true), ('3', true), ('s', true), ('c', true) ], func(c: char): bool = ?c.parsePiece[2] )

    #color to val/string

suite "tile":

    # ["1", "2", "1S", "2C", "11211221", "22221C"

    test "correct tile parse":
        checkEqAll( [ ("12112", (Tile( piece: Piece.flat, stack: @[Color.white, Color.black, Color.white, Color.white, Color.black]), default(Error) )), 
        ( "1", (Tile(piece: Piece.flat, stack: @[Color.white]), default(Error))), ("2", (Tile(piece: Piece.flat, stack: @[Color.black]), default(Error))), 
        ("1S", (Tile(piece: Piece.wall, stack: @[Color.white]), default(Error))), ("2C", (Tile(piece: Piece.cap, stack: @[Color.black]), default(Error))),
        ("22221C", (Tile(piece: Piece.cap, stack: @[Color.black, Color.black, Color.black, Color.black, Color.white]), default(Error)))],
        func(c: string): (Tile, Error) = c.parseTile)
