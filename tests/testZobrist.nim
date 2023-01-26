import std/unittest
import ../src/tak/zobrist
from ../src/tak/tile import Piece, Color

suite "ZobristHashingTestSuite":

    test "check piece indices":
        check(pieceIndex(flat, white) == 0)
        check(pieceIndex(flat, black) == 1)
        check(pieceIndex(wall, white) == 2)
        check(pieceIndex(wall, black) == 3)
        check(pieceIndex(cap, white) == 4)
        check(pieceIndex(cap, black) == 5)