
import evaluation
import ../tak/game
import ../tak/move
import ../tak/movegen
import ../util/error
from ../tak/tile import Color
import std/times, std/sequtils, std/strutils, std/random, std/algorithm


proc alphaBeta(game: var Game, cfg: AnalysisConfig, pv: var seq[Move], alpha: var EvalType, beta: var EvalType, depth: uint, maximizingPlayer: bool): EvalType =
    
    var clr: Color
    let isOver = game.isOver(clr) 
    if (depth == 0) or isOver:
        let eval = game.evaluate(cfg, maximizingPlayer, isOver, clr)
        # echo &"depth: {depth}, isOver: {isOver}, color: {clr}, to_play: {game.to_play}, maxPlayer: {maximizingPlayer}, eval: {eval}"
        # if maximizingPlayer:
        #     beta = eval
        # else:
        #     alpha = eval
        return eval
    
    # if depth > 1:
    #     echo &"pv for depth:{depth}, pv: {pv[^1]}" 
    #     discard game.play(pv[^1])

    var possMoves = game.possibleMoves()
    shuffle(possMoves)
    let movesToTry = if depth > 1 and (pv.len >= int depth - 2): pv[depth - 2] & possMoves & pv[depth - 2] else: possMoves
    let movesToTryStr = movesToTry.mapIt(it.ptnVal(game.N)).join(" ")
    # teecho &"depth: {depth}. possibleMoves: {movesToTryStr}"
    # var moveOpts: seq[Move]
    # var curAlpha = EvalType.low
    # var curBeta = EvalType.high
    var found = default(Move)
    var bestMove: Move = movesToTry[0]
    if maximizingPlayer:
        var value = EvalType.low
        for move in movesToTry:
            found = move
            # echo &"Trying move {move.ptnVal(game.N)} at depth {depth}"
            var toMove = game
            let err = toMove.play(move)

        # pv.add(move)
        # var pv = pvO
            if ?err:
                continue
        # if maximizingPlayer:
            # echo &"pre alpha: {alpha}, beta: {beta}"
            value = max(value, alphaBeta(toMove, cfg, pv, alpha, beta, depth - 1, false))
            # echo &"value: {value}, beta: {beta}"
            
            if value > beta:
                bestMove = found
                break
            alpha = max(alpha, value)

        if pv.len < int depth:
            pv.add(bestMove)
        else:
            pv[^1] = bestMove
        
        return value
    else:
        var value = EvalType.high
        for move in movesToTry:
            found = move
            # echo &"Trying move {move.ptnVal(game.N)} at depth {depth}"
            var toMove = game
            let err = toMove.play(move)

            if ?err:
                continue

            value = min(value, alphaBeta(toMove, cfg, pv, alpha, beta, depth - 1, true))
            # echo &"value: {value}, alpha: {alpha}"
              
            if value < alpha:
                bestMove = found
                break
            beta = min(beta, value)

        if pv.len < int depth:
            pv.add(bestMove)
        else:
            pv[^1] = bestMove

        return value
        # pv.delete(pv.len - 1, 1)
    # echo &"depth: {depth}, found: {found}"
    
    
    # let pvStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
    # echo &"pvAB: {pvStr}, depth: {depth}"

proc iterDeep(gameO: Game, cfg: AnalysisConfig): (EvalType, Move, Error) =
    var alpha = EvalType.low
    var beta = EvalType.high
    # echo &"alpha: {alpha}, beta: {beta}"
    let timeStart = now()
    var game = gameO

    

    let initDepth = if cfg.initDepth == 0'u: 1'u else: cfg.initDepth  

    # var bestMove: Move
    # var pvSeq: seq[Move]
    var pv: seq[Move]
    for i in initDepth .. cfg.depth + initDepth:
        # echo &"Starting depth {i}"
        alpha = EvalType.low
        beta = EvalType.high
        alpha = alphaBeta(game, cfg, pv, alpha, beta, i, true)

        # let pvTmpStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
        # echo &"pvTmpStr: {pvTmpStr}"

        # let pvCStr = pv.mapIt(it.ptnVal(game.N)).join(" ")
        # let bestMove = pv[0]
        
        # pvSeq.add(bestMove)

        # let timeNow = now()

        # echo &"timeNow: {timeNow}, timeStart:{timeStart}"
        let elapsed = (now() - timeStart).inMilliseconds
        let pvInOrder = pv.reversed()
        # pvInOrder.reverse()
        # pvInOrder.reversed()
        let pvStr = pvInOrder.mapIt(it.ptnVal(game.N)).join(" ")

        echo &"depth: {i}, time: {elapsed}, alpha: {alpha}, pv: {pvStr}"

        var clr: Color
        var gameT = gameO
        let pErr = gameT.playMoves(pvInOrder)
        if ?pErr:
            return (default(EvalType), default(Move), pErr)
        if gameT.isOver(clr):
            echo &"Game over"
            break

        if elapsed >  cfg.maxDuration.inMilliseconds:
            echo &"Time limit exceeded"
            break

    if pv.len <= 0:
        return (alpha, default(Move), newError("no move found"))
        
    return (alpha, pv[^1], default(Error))

proc getAIMove*(game: Game, cfg: AnalysisConfig): (PlayType, Move, Error) =
    #let (evalFun, _, _) = 15'u8.getDifficultyPresets(game.N)
    let (_, bestMove, err) = iterDeep(game, cfg)
    if ?err:
        return (default(PlayType), default(Move), err)

    return (PlayType.move, bestMove, default(Error))

proc analyze*(game: Game, cfg: AnalysisConfig): (EvalType, string) =

    let (eval, bestMove, err) = iterDeep(game, cfg)
    if ?err:
        return (eval, "")

    return (eval, bestMove.ptnVal(game.N))