import ../src/tak/game as gm
import ../src/tak/movegen
import ../src/util/error
import std/unittest, std/strformat
import genUtil


proc perfCount(game: Game, depth: int, trace: var Error): (int, Error) =
    echo game.toTps, ";", depth
    if depth == 0 or game.isOver:
        return (1, trace)
    elif depth == 1:
        let pM = game.possibleMoves
        echo pM.len
        return (pM.len, trace)
    else:
        var count = 0
        for move in game.possibleMoves:
            var initialState = game
            var err = initialState.play(move)
            var (incr, tr) = perfCount(initialState, depth - 1, err)
            count += incr
            trace.add($tr)
        return (count, trace)

suite "test Move gen":

    test "move stack perft":

        let (game, parseErr) = fromPTNMoves(["d3", "c3", "c4", "1d3<", "1c4-", "Sc4"],5'u8, 0, true)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 87)
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 6_155)
        err = default(Error)
        checkWithErr(perfCount(game, 3, err), 461_800)

    test "respect carry limit perft":
        let (game, parseErr) = fromPTNMoves(["c2", "c3", "d3", "b3", "c4", "1c2+", "1d3<", "1b3>", "1c4-", "Cc2", "a1", "1c2+", "a2"]
        , 5'u8)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 104)
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 7_743)
        err = default(Error)
        checkWithErr(perfCount(game, 3, err), 592_645)