
# from ../tak/bitmap import Bitmap
# from ../tak/move import Direction
import ../tak/game
import std/times
import ../tak/tile

type
    EvalType* = int32
    EvalFunc*[N: static uint] = proc (game: Game[N], clr: Color): EvalType

    Evaluation = distinct EvalType
    Config* = tuple[level: uint8, depth: uint, maxDuration: Duration]

const Win: EvalType = 100_000
const WinThreshold: EvalType = 99_000

proc Zero*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(0)

proc Max*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.high - 1)

proc Min*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.low + 1)

proc easyEval(game: Game, clr: Color): EvalType =
    return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 + 
        game.meta.pieceCount(clr, wall) * 10)

proc midEval(game: Game, clr: Color): EvalType =


    #evaluate group sizes
    var eval: EvalType
    var cntGroups = 0
    for groupSize in game.meta.groupCount(clr):
        eval += EvalType (groupSize * 20)
        cntGroups += 1
    eval += EvalType (cntGroups * 30)

    cntGroups = 0
    for groupSize in game.meta.groupCount(not clr):
        eval -= EvalType (groupSize * 20)
        cntGroups += 1
    eval -= EvalType (cntGroups * 30)

    eval += game.easyEval(clr)

    return eval

proc hardEval(game: Game, clr: Color): EvalType =
    #todo
    return midEval(game, clr)



proc evalByConfig(game: Game, cfg: Config, clr: Color): EvalType =
    case cfg.level:
    of 1'u8: return easyEval(game, clr)
    of 2'u8: return midEval(game, clr)
    of 3'u8: return hardEval(game, clr)
    else: return midEval(game, clr)

proc evaluate*(game: Game, cfg: Config, maxPlayer: bool, isOver: bool = false, resColor: Color = Color.white): EvalType =

    if isOver:
        if maxPlayer:
            if resColor == Color.white:
                return Win
            else:
                return -Win
        else:
            if resColor == Color.black:
                return Win
            else:
                return -Win

    let clr = if maxPlayer: white else: black
    
    return game.evalByConfig(cfg, clr)
    # return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 +
    #      game.meta.pieceCount(clr, wall) * 10)

template newConfig*(lvl: uint8, dpth, dur): Config =
     (level: lvl, depth: dpth, maxDuration: dur)


