import std/unittest, std/sequtils
import ../src/tak/move as mv, ../src/tak/game, ../src/tak/tps
import ../src/util/error 

import genUtil
        

func roundtrip(typ: Game, val: string, expanded: bool = false): bool =
    var (playType, move, err) = parseMove(val, typ.N)
    if ?err:
            return false

    case playType
    of PlayType.undo: return "undo" == val
    of PlayType.move: return move.ptnVal(typ.N, expanded) == val

suite "check move ptn":

    test "roundtrip move - place - default board":
        var game: Game[6'u]
        var err: Error
        (game, err) = newGame(6'u)
        check(not ?err)
        checkRoundtripAll( ["a1", "a6", "f6", "f1", "b2", "c3", "Sd2", "Ce4"], proc(c: string): bool = (game).roundtrip(c))

    test "roundtrip move - spread - custom board":
        var (game, err) = parseGame("2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34", 6'u)
        
        check(not ?err)
        checkRoundtripAll( ["3c5<12", "c5<", "d3+", "3d5-111", "2b4-", "3c5>12"], proc(c: string): bool = (game).roundtrip(c))

    test "roundtrip move - expanded - spread - custom board":
        var (game, err) = parseGame("2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34", 6'u)
        
        check(not ?err)
        checkRoundtripAll( ["3c5<12", "1c5<1", "1d3+1", "3d5-111", "2b4-2", "3c5>12"], proc(c: string): bool = (game).roundtrip(c, true))

    test "incorrect places on default board":
        var (game, err) = newGame(6'u)
        check(not ?err)
        checkRoundTripAll(["1a", "3", "Q", "cC4", "b8", "h3"], proc(c: string): bool = not (game).roundtrip(c))

    test "incorrect spreads - custom board":
        var (game, err) = parseGame("2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34", 6'u)
        
        check(not ?err)
        checkRoundtripAll( ["3c7<12", "h5<", "d3++", "3d5-1111", "b4-4", "3C5>12"], proc(c: string): bool = not (game).roundtrip(c))
    