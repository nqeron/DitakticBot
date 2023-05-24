import ../tak/game
import ../tak/move as mv
import ../tak/tps as tpsParse
from ../tak/tile import Color
import player
import ../util/error, ../util/makeStatic
import ../analysis/evaluation
import std/parseopt, std/parseutils, std/strformat



type
    Play = enum
        move, undo
    # BoardSize = enum
    #     size3 = 3'u, size4 = 4'u, size5 = 5'u, size6 = 6'u, size7 = 7'u, size8 = 8'u


proc getMoveFromPlayer*(game: Game, wPlayer: Actor, bPlayer: Actor): (PlayType, Move, Error) =
    case game.to_play
    of white:
        return wPlayer.getMove(game)
    of black:
        return bPlayer.getMove(game)

proc gameLoop[N: static uint](game: Game[N], wPlayer: Actor, bPlayer: Actor, err: Error, cfg: AnalysisConfig): Error =
    if ?err:
        echo $err
        return err
    
    echo &"Playing game {game} with players: {wPlayer}, {bPlayer}"

    var positionHistory = @[game]

    var curState = game
    var clr: Color

    while not curState.isOver(clr): #isNotFinished?
        #get move
        var (playType, pMove, err) = curState.getMoveFromPlayer(wPlayer, bPlayer)

        if ?err:
            echo $err
            return err

        case playType
        of PlayType.undo:
            curState = positionHistory.pop()
        of PlayType.move:
            var nextPos = curState
            err = nextPos.play(pMove)
            if ?err:
                echo $err
                return err
            else:
                curState = nextPos
                positionHistory.add(game)

proc chooseGameLoopBySize(size: static uint, tps: string, level: int, wPlayer: Actor, bPlayer: Actor, komi: int8, swap: bool = true): Error =
    
    let (game, crErr) =
        if not tps == "":
            parseGame(tps, size, swap, komi)
        else:
            newGame(size, komi, swap)
    
    if ?crErr:
            return crErr

    let cfg: AnalysisConfig = newConfig(level)
    return gameLoop(game, wPlayer, bPlayer, crErr, cfg)


proc initGame(): Error =

    var p = initOptParser(shortNoVal = {'h'}, longNoVal = @["help", "noSwap" ])

    var wPlayer = human
    var bPlayer = human
    var komi = 2
    var size: uint = 6
    var swap = true
    var tps: string
    var level: int

    var err: Error

    for kind, key, val in getopt(p):
        case kind
        of cmdArgument:
            discard
        of cmdEnd:
            assert(false)
        of cmdShortOption, cmdLongOption:
            case key
            of "help", "h" : echo "TODO"
            of "white": 
                (wPlayer, err) = val.parseActor()
                if ?err:
                    err.add("Error parsing white actor")
                    return err
            of "black": 
                (bPlayer, err) = val.parseActor()
                if ?err:
                    err.add("Error parsing black actor")
                    return err
            of "size": 
                if val.parseUInt(size) != 1:
                    return newError("size too long")
            of "komi": 
                komi = int8 parseInt(val)
            of "noSwap": swap = false
            of "tps": tps = val
            of "level": level = parseInt(val)
            else: return newError(&"Option key {key} is invalid")

    chooseSize(size, chooseGameLoopBySize, tps, level, wPlayer, bPlayer, komi, swap)

proc mainLoop*() = 

    let err = initGame()
    if ?err:
        echo $err
        quit(1)