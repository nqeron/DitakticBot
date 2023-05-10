
# from ../tak/bitmap import Bitmap
# from ../tak/move import Direction
import ../tak/game
import std/times
from ../tak/tile import Piece, Color

type
    EvalType* = int32
    EvalFunc*[N: static uint] = proc (gm: Game[N], clr: Color): EvalType

    Evaluation = distinct EvalType

const Win: EvalType = 100_000
const WinThreshold: EvalType = 99_000

proc Zero*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(0)

proc Max*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.high - 1)

proc Min*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.low + 1)

proc evaluate*(game: Game, evalFun: EvalFunc, maxPlayer: bool, isOver: bool = false, resColor: Color = Color.white): EvalType =

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
    
    return evalFun(game, clr)
    # return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 +
    #     game.meta.pieceCount(clr, wall) * 10)

proc easyEval[N: static uint](game: Game[N], clr: Color): EvalType =
    return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 + 
        game.meta.pieceCount(clr, wall) * 10)

proc midEval[N: static uint](game: Game[N], clr: Color): EvalType =


    #evaluate group sizes
    var eval: EvalType
    var cntGroups = 0
    for groupSize in game.meta.groupCount(clr):
        eval += EvalType (groupSize * 20)
        cntGroups += 1
    eval += EvalType (cntGroups * 30)

    eval += game.easyEval(clr)

    return eval

proc hardEval[N: static uint](game: Game[N], clr: Color): EvalType =
    #todo
    return midEval(game, clr)

proc getDifficultyPresets*(level: uint8, size: static uint): (EvalFunc[size], uint, Duration) =
    case level:
    of 1'u8: (easyEval, 1'u, initDuration(seconds = 5))
    of 2'u8: (easyEval, 2'u, initDuration(seconds = 10))
    of 3'u8: (easyEval, 3'u, initDuration(seconds = 15))
    of 4'u8: (midEval, 1'u, initDuration(seconds = 5))
    of 5'u8: (midEval, 2'u, initDuration(seconds = 10))
    of 6'u8: (midEval, 4'u, initDuration(seconds = 15))
    of 7'u8: (hardEval, 2'u, initDuration(seconds = 10))
    of 8'u8: (hardEval, 4'u, initDuration(seconds = 15))
    of 9'u8: (hardEval, 6'u, initDuration(seconds = 20))
    of 10'u8: (hardEval, 8'u, initDuration(seconds = 30))
    else: (midEval, 3'u, initDuration(seconds = 12))

