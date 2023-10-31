
# from ../tak/bitmap import Bitmap
# from ../tak/move import Direction
import ../tak/game
import std/times, std/math
import ../tak/tile
import ../util/error

type
    EvalType* = int32
    EvalFunc*[N: static uint] = proc (game: Game[N], clr: Color): EvalType

    AnalysisLevel* = enum
        easy, medium, hard

    Evaluation = distinct EvalType
    AnalysisConfig* = object
        level*: AnalysisLevel
        initDepth*: uint
        depth*: uint
        maxDuration*: Duration

const Win: EvalType = 100_000
# const WinThreshold: EvalType = 99_000

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



proc evalByConfig(game: Game, cfg: AnalysisConfig, clr: Color): EvalType =
    case cfg.level:
    of easy: return easyEval(game, clr)
    of medium: return midEval(game, clr)
    of hard: return hardEval(game, clr)

proc evaluate*(game: Game, cfg: AnalysisConfig, maxPlayer: bool, isOver: bool = false, resColor: Color = Color.white): EvalType =

    if isOver:
        if maxPlayer:
            if game.to_play == resColor:
                # return Win
                return EvalType.high - 1
            else:
                return EvalType.low + 1
                # return -Win
        else:
            if game.to_play != resColor:
                return EvalType.high - 1
                # return Win
            else:
                return EvalType.low + 1
                #  return -Win

    let clr = if maxPlayer: white else: black
    
    return game.evalByConfig(cfg, clr)
    # return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 +
    #      game.meta.pieceCount(clr, wall) * 10)

proc newConfig*(level: int): AnalysisConfig =

    var lvl: AnalysisLevel =
        case (level mod 12):
        of 1,2,3,4: easy
        of 5,6,7,8: medium
        of 9,10,11,0: hard
        else: medium

    let initDepth: uint =
        case (level mod 48):
        of 1,2,3,4,5,6,7,8,9,10,11,12: 1'u
        of 13,14,15,16,17,18,19,20,21,22,23,24: 2'u
        of 25,26,27,28,29,30,31,32,33,34,35,36: 4'u
        of 37,38,39,40,41,42,43,44,45,46,47,0: 8'u
        else: 6'u 

    let depth: uint =
        case (level mod 4):
        of 1: 1'u
        of 2: 2'u
        of 3: 4'u
        of 0: 8'u
        else: 6'u

    let dur = initDuration(seconds = int ((int initDepth) * (8 ^ depth)  ))

    return AnalysisConfig(level: lvl, initDepth: initDepth , depth: depth, maxDuration: dur)

proc `default`*(t:typedesc[AnalysisConfig]): AnalysisConfig =
    return newConfig(6)

proc parseAnalysisLevel*(lvl: string): (AnalysisLevel, Error) =
    case lvl:
    of "1", "e", "easy": (easy, default(Error))
    of "2","m", "med", "medium": (medium, default(Error))
    of "3", "h", "hard": (hard, default(Error))
    else: (default(AnalysisLevel), newError("Invalid analysis level"))
