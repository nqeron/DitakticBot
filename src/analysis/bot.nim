
import evaluation
import ../tak/game
import ../tak/move
import ../tak/movegen
import ../util/error
from ../tak/tile import Color
import std/times, std/sequtils, std/strutils, std/random

proc alphaBeta(game: var Game, cfg: AnalysisConfig, pv: var seq[Move], alpha: var EvalType, beta: var EvalType, depth: uint, maximizingPlayer: bool): EvalType =
    
    var clr: Color
    let isOver = game.isOver(clr)
    if (depth == 0) or isOver:
        return game.evaluate(cfg, maximizingPlayer, isOver, clr)
    
    var movesToTry = game.possibleMoves()
    shuffle(movesToTry)
    let movesToTryStr = movesToTry.mapIt(it.ptnVal(game.N)).join(" ")
    # echo &"depth: {depth}. possibleMoves: {movesToTryStr}"
    var moveOpts: seq[Move]
    for move in movesToTry:
        # echo &"Trying move {move.ptnVal(game.N)} at depth {depth}"
        var toMove = game
        let err = toMove.play(move)
        # var pv = pvO
        pv.add(move)
        if ?err:
            continue
        if maximizingPlayer:
            alpha = max(alpha, alphaBeta(toMove, cfg, pv, alpha, beta, depth - 1, false))
            # echo &"Alpha: {alpha}, Beta: {beta}"
            if beta <= alpha:
                break
        else:
            beta = min(beta, alphaBeta(toMove, cfg, pv, alpha, beta, depth - 1, true))
            # echo &"Alpha: {alpha}, Beta: {beta}"
            if beta <= alpha:
                break
        # pv.delete(pv.len - 1, 1)
        
    let pvStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
    # echo &"pvAB: {pvStr}, depth: {depth}"

    return if maximizingPlayer: alpha else: beta

proc iterDeep(gameO: Game, cfg: AnalysisConfig): (EvalType, Move) =
    var alpha = EvalType.low
    var beta = EvalType.high
    # echo &"alpha: {alpha}, beta: {beta}"
    let timeStart = now()
    var game = gameO

    let initDepth = if cfg.initDepth == 0'u: 1'u else: cfg.initDepth  

    # var bestMove: Move
    var pvSeq: seq[Move]
    for i in initDepth .. cfg.depth + initDepth:
        # echo &"Starting depth {i}"
        var pv: seq[Move]
        alpha = EvalType.low
        beta = EvalType.high
        alpha = alphaBeta(game, cfg, pv, alpha, beta, i, true)

        # let pvTmpStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
        # echo &"pvTmpStr: {pvTmpStr}"

        let pvCStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
        echo &"pvCount: {pv.len}, pv: {pvCStr}"
        let bestMove = pv[0]
        
        pvSeq.add(bestMove)
        let err = game.play(bestMove)
        if ?err:
            echo &"Error: {err}"
            break

        let timeNow = now()

        # echo &"timeNow: {timeNow}, timeStart:{timeStart}"
        let elapsed = (now() - timeStart).inMilliseconds
        let pvStr = pvSeq.mapIt(it.ptnVal(game.N)).join(" ")

        echo &"depth: {i}, time: {elapsed}, alpha: {alpha}, pv: {pvStr}"

        var clr: Color
        if game.isOver(clr):
            # echo &"Game over"
            break

        if elapsed >  cfg.maxDuration.inMilliseconds:
            echo &"Time limit exceeded"
            break

        
    return (alpha, pvSeq[0])

proc getAIMove*(game: Game, cfg: AnalysisConfig): (PlayType, Move, Error) =
    #let (evalFun, _, _) = 15'u8.getDifficultyPresets(game.N)
    let (eval, bestMove) = iterDeep(game, cfg)
    return (PlayType.move, bestMove, default(Error))

proc analyze*(game: Game, cfg: AnalysisConfig): (EvalType, string) =

    let (eval, bestMove) = iterDeep(game, cfg)
    return (eval, bestMove.ptnVal(game.N))