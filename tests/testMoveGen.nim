import ../src/tak/game as gm
import ../src/tak/movegen
import ../src/util/error
import std/unittest, std/strformat
import genUtil


proc perfCount(game: Game, depth: int, trace: var Error): (int, Error) =
    if depth == 0 or game.isOver:
        return (1, trace)
    elif depth == 1:
        let pM = game.possibleMoves
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

        let (game, parseErr) = fromPTNMoves(["d3", "c3", "c4", "1d3<", "1c4-", "Sc4"],5'u, 0, true)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 87)
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 6_155)
        err = default(Error)
        checkWithErr(perfCount(game, 3, err), 461_800)

    test "respect carry limit perft":
        let (game, parseErr) = fromPTNMoves(["c2", "c3", "d3", "b3", "c4", "1c2+", "1d3<", "1b3>", "1c4-", "Cc2", "a1", "1c2+", "a2"]
        , 5'u)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 104)
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 7_743)
        err = default(Error)
        checkWithErr(perfCount(game, 3, err), 592_645)

    test "suicide perft":
        let (game, parseErr) = fromPTNMoves(["c4", "c2", "d2", "c3", "b2", "d3", "1d2+", "b3", "d2", "b4", "1c2+", "1b3>", "2d3<", "1c4-", "d4", 
        "5c3<23", "c2", "c4", "1d4<", "d3", "1d2+", "1c3+", "Cc3", "2c4>", "1c3<", "d2", 
        "c3", "1d2+", "1c3+", "1b4>", "2b3>11", "3c4-12", "d2", "c4", "b4", "c5", "1b3>",
         "1c4<", "3c3-", "e5", "e2"]
        , 5'u)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 85);
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 11_206);
        err = default(Error)
        checkWithErr(perfCount(game, 3,err), 957_000);

    test "endgame perft":
        let (game, parseErr) = fromPTNMoves(["a5", "b4", "c3", "d2", "e1", "d1", "c2", "d3", "c1", "d4", "d5", "c4", "c5", "b3", "b2", "a2",
        "Sb1", "a3", "Ce4", "Cb5", "a4", "a1", "e5", "e3", "c3<", "Sc3", "c1>", "c1", "2d1+", "c3-", "c3",
        "a3>", "a3", "d1", "e4<", "2c2>", "c2", "e2", "b2+", "b2"]
        , 5'u)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 65);
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 4_072);
        err = default(Error)
        checkWithErr(perfCount(game, 3,err), 272_031);

    test "reserves perft":
        let (game, parseErr) = fromPTNMoves(["a1", "b1", "c1", "d1", "e1", "e2", "d2", "c2", "b2", "a2", "a3", "b3", "c3", "d3", "e3", "a4", "b4",
        "c4", "d4", "e4", "a5", "a4-", "b4-", "c4-", "d4-", "e4-", "a4", "b4", "c4", "d4", "e4", "2a3>",
        "c4>", "2e3<", "a3", "4b3-", "b3", "c4", "e3", "d5", "d2<", "d2", "2d4-", "d4", "c5", "b5", "2c2>",
        "d1+", "c2", "e2+", "d1", "e2", "c5<", "c5", "e4<", "Se4", "2b5-", "e4-", "a3-"]
        , 5'u)
        check(not ?parseErr)
        var err = default(Error)
        checkWithErr(perfCount(game, 1, err), 152);
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 15_356);

    test "perft 5s Open":
        let (game, createErr) = newGame(5'u)
        
        check(not ?createErr)

        var err = default(Error)
        checkWithErr(perfCount(game, 0, err), 1);
        err = default(Error)
        checkWithErr(perfCount(game, 1, err), 25);
        err = default(Error)
        checkWithErr(perfCount(game, 2, err), 600);
        err = default(Error)
        checkWithErr(perfCount(game, 3, err), 43_320);
