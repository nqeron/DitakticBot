import ../src/tak/game, ../src/tak/tps, ../src/tak/move
import ../src/util/error
import genUtil
import std/unittest, std/sequtils


func roundTrip[R] (typ: R, val: string): bool =
    if R is Game:
        var (game, err) = parseGame(val)
        if ?err:
            return false
        return game.toTps == val

suite "game tps test":

    test "roundtrip full tps":
        checkRoundTripAll(["2,x5/x6/x2,2,1,1C,x/x,2C,1,1,2,x/x2,2,2,1,x/1,x3,1,x 2 7", 
        "x6/x6/x6/x6/x6/x6 1 1", 
        "2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34",
        "2,2,1,1,1211112S,1/1,2,221C,2S,12,21/1,21S,2112C,2,1,1/2,2,2,1,2,2S/1,2,21S,2,1212S,1/1,1S,2,1,1,1 1 39"],
        func(c: string): bool = (default(Game)).roundTrip(c))

suite "game play test":

    test "valid places on default game":
        var (game,err) = newGame()
        check(not ?err)
        check(not ?game.play(newMove(newSquare(0,0), newPlace(Place.flat))))
        check(not ?game.play(newMove(newSquare(0,5), newPlace(Place.flat))))

    test "invalid places on default game":
        var (game,err) = newGame()
        check(not ?err)
        check(?game.play(newMove(newSquare(0,0), newPlace(Place.wall))))
        check(?game.play(newMove(newSquare(0,5), newPlace(Place.cap))))

    test "invalid game creation":
        var (game, err) = newGame(9'u8)
        check(?err)
    
    # test "valid moves from parsed game":
    #     var (game, err) = parseGame("2,2,x,1,1112S,1/1,2,221C,211,12,2/x,21S,2112C,2,1,1/x,2,2,1,2,2S/x,2,21S,x,1212S,1/1,1S,2,x,1,1 1 34")
    #     check(not ?err)
    #     #echo $game.play(newMove(newSquare(2,1), newSpread(left, @[1,2])))
    #     #check(not ?game.play(newMove(newSquare(2,1), newSpread(left, @[1,2]))))