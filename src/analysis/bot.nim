
import evaluation
import ../tak/game
import ../tak/move
import ../tak/movegen
import ../util/error
import std/times, std/sequtils

proc alphaBeta(game: Game, pv: var seq[Move], alpha: var EvalType, beta: var EvalType, depth: uint, maximizingPlayer: bool): EvalType =
    if (depth == 0) or (game.isOver()):
        return game.evaluate(maximizingPlayer)
    for move in game.possibleMoves():
        var toMove = game
        let err = toMove.play(move)
        pv.add(move)
        if ?err:
            continue
        if maximizingPlayer:
            alpha = max(alpha, alphaBeta(toMove, pv, alpha, beta, depth - 1, false))
            if beta <= alpha:
                break
        else:
            beta = min(beta, alphaBeta(toMove, pv, alpha, beta, depth - 1, true))
            if beta <= alpha:
                break
    return if maximizingPlayer: alpha else: beta

proc iterDeep(game: Game, depth: uint, durationMax: Duration): (EvalType, seq[Move]) =
    var alpha = EvalType.high
    var beta = EvalType.low
    let timeStart = now()

    var pv: seq[Move]
    for i in 0'u ..< depth:
        alpha = alphaBeta(game, pv, alpha, beta, i, true)
        if (now() - timeStart).inMilliseconds > durationMax.inMilliseconds:
            break
    return (alpha, pv)

proc getAIMove*(game: Game, depth: uint = 5'u, durationMax: Duration = initDuration(seconds = 15)): (PlayType, Move, Error) =
    let (eval, pv) = iterDeep(game, depth, durationMax)
    if pv.len() == 0:
        return (default(PlayType), default(Move), newError("No moves found"))
    return (PlayType.move, pv[0], default(Error))

proc analyze*(game: Game, depth: uint = 5'u, durationMax: Duration = initDuration(seconds = 15)): (EvalType, seq[string]) =
    let (eval, pv) = iterDeep(game, depth, durationMax)
    let pvStr = mapit(pv, it.ptnVal(game.N))
    return (eval, pvStr)