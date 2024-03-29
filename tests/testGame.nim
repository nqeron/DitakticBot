import ../src/tak/game, ../src/tak/tps, ../src/tak/move
import ../src/util/error
import genUtil
import std/unittest, std/sequtils, std/strutils


proc roundTrip[N: static uint] (typ: Game[N], val: string): bool =
    var (game, err) = parseGame(val, N)
    if ?err:
        return false
    return game.toTps == val

proc checkPtnMoves(moves: openArray[string]): (string, Error) =
    var (game, err) = fromPTNMoves(moves, 6'u)
    if ?err: return ("", err)
    return (game.toTps(), default(Error))

suite "game tps test":

    test "roundtrip one":
        let (g, err) = "2,x5/x6/x2,2,1,1C,x/x,2C,1,1,2,x/x2,2,2,1,x/1,x3,1,x 2 7".parseGame(6'u)
        
        check(not ?err)
        check(g.toTps == "2,x5/x6/x2,2,1,1C,x/x,2C,1,1,2,x/x2,2,2,1,x/1,x3,1,x 2 7")

    test "roundtrip two":
        let (g, err) = "2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34".parseGame(6'u)
        assert(not ?err, $err)
        check(not ?err)
        check(g.toTps == "2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34")


    test "roundtrip full tps":
        checkRoundTripAll(["2,x5/x6/x2,2,1,1C,x/x,2C,1,1,2,x/x2,2,2,1,x/1,x3,1,x 2 7", 
        "x6/x6/x6/x6/x6/x6 1 1", 
        "2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34",
        "2,2,1,1,1211112S,1/1,2,221C,2S,12,21/1,21S,2112C,2,1,1/2,2,2,1,2,2S/1,2,21S,2,1212S,1/1,1S,2,1,1,1 1 39"],
        proc(c: string): bool = (default(Game[6'u])).roundTrip(c))

suite "game play test":

    test "valid places on default game":
        var (game,err) = newGame(6'u)
        check(not ?err)
        check(not ?game.play(newMove(newSquare(0'u,0'u), newPlace(Place.flat))))
        check(not ?game.play(newMove(newSquare(0'u,5'u), newPlace(Place.flat))))

    test "invalid places on default game":
        let (gameI,nErr) = newGame(6'u)
        check(not ?nErr)

        var (pt, move, mErr) = parseMove("Ca1", 6'u)
        check(not ?mErr)

        var game = gameI
        var err = game.play(move)
        echo ?err
        check(?err)

        (pt, move, mErr) = parseMove("Sf6", 6'u)
        check(not ?mErr)

        game = gameI
        err = game.play(move)
        echo err
        check(?err)

    test "invalid game creation":
        var (game, err) = newGame(9'u8)
        check(?err)

suite "complicated state":

    test "check outbound edge moves":
        let initTps = "1,x2,1,x,2/x6/1,x4,2/x6/x6/2,x2,2,x,1 1 5"
        let (gameI, pErr) = parseGame(initTps, 6'u)
        check(not ?pErr)

        var game = gameI
        var (pt, move, mErr) = parseMove("f1-", 6'u)
        check(not ?mErr)
        
        var err = game.play(move)
        echo err
        check(?err)
        check(($err).contains("Spread moves past bound of board"))

        game = gameI
        (pt, move, mErr) = parseMove("f1>", 6'u)
        check(not ?mErr)
        
        err = game.play(move)
        echo err
        check(?err)
        check(($err).contains("Spread moves past bound of board"))

        game = gameI
        (pt, move, mErr) = parseMove("a6<", 6'u)
        check(not ?mErr)
        
        err = game.play(move)
        echo err
        check(?err)
        check(($err).contains("Spread moves past bound of board"))

        game = gameI
        (pt, move, mErr) = parseMove("a6+", 6'u)
        check(not ?mErr)
        
        err = game.play(move)
        echo err
        check(?err)
        check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "a1", "a1<"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "a6", "a6<"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "a6", "a6+"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "f6", "f6+"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "f6", "f6>"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "f1", "f1>"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    #     moves = ["c3", "f1", "f1-"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(?err)
    #     check(($err).contains("Spread moves past bound of board"))

    # test "check inbound edge moves":
    #     var moves = ["c3", "a1", "a1+"]
    #     var (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "a1", "a1>"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "a6", "a6>"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "a6", "a6-"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "f6", "f6-"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "f6", "f6<"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "f1", "f1<"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    #     moves = ["c3", "f1", "f1+"]
    #     (tps, err) = checkPtnMoves(moves)
    #     check(not ?err)
    #     check(tps != "")

    test "complicated rabbit v x":
        let moves = ["a1", "b1", "b4", "Cc3", "a2", "b3", "a3", "a4", "b2", "d3", "b4<", "Sb4", "Ca5", "a1+", 
        "a1", "e3", "a1+", "b4<", "a5-", "Sa1", "4a4-22", "Sa4", "4a2+", "c4", "c1", "e1",
        "e2", "d2", "d1", "c5", "f1", "e1<", "c1>"]
        let tps = "x6/x2,2,x3/2S,x,2,x3/1212121C,2,2C,2,2,x/1,1,x,2,1,x/2S,1,x,121,x,1 2 17"

        let (toTps, err) = checkPtnMoves(moves)
        check( not ?err )
        check(toTps == tps)

suite "Check Tak":

    test "check taks":
        let tps = "212S,x2,1,121,1/2,1,x,2,2,112/2,22,2,12C,11121C,x/221S,x,2,x2,2S/2,x4,1/2,x4,1 2 31"

        let (game, err) = parseGame(tps, 6'u)
        check( not ?err )
        let (tak, clr) = game.checkTak
        check(tak)

    test "check move to tak":
        let tps = "212S,x2,1,121,1/2,1,2212,x2,1/2,22,2,12C,11121C,x/221S,x,2,x2,2S/2,x4,1/2,x4,1 2 30"

        var (game, err) = parseGame(tps, 6'u)
        check(not ?err)

        let (_, move, mErr) = parseMove("4c5>112", 6'u)
        check(not ?mErr)
        

    
    # test "valid moves from parsed game":
    #     var (game, err) = parseGame("2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34")
    #     check(not ?err)
    #     #echo $game.play(newMove(newSquare(2,1), newSpread(left, @[1,2])))
    #     #check(not ?game.play(newMove(newSquare(2,1), newSpread(left, @[1,2]))))