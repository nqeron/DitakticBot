import ../tak/game
import ../tak/move as mv
import ../tak/tps as tpsParse
from ../tak/tile import Color
import player
import ../util/error
import std/parseopt, std/parseutils, std/strformat

type
    Play = enum
        move, undo
    # BoardSize = enum
    #     size3 = 3'u, size4 = 4'u, size5 = 5'u, size6 = 6'u, size7 = 7'u, size8 = 8'u


const size3: uint = 3'u
const size4: uint = 4'u
const size5: uint = 5'u
const size6: uint = 6'u
const size7: uint = 7'u
const size8: uint = 8'u


proc getMoveFromPlayer*(game: Game, wPlayer: Actor, bPlayer: Actor): (PlayType, Move, Error) =
    case game.to_play
    of white:
        return wPlayer.getMove(game)
    of black:
        return bPlayer.getMove(game)

proc gameLoop[N: static uint](game: Game[N], wPlayer: Actor, bPlayer: Actor, err: Error): Error =
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

proc initGame(): Error =

    var p = initOptParser(shortNoVal = {'h'}, longNoVal = @["help", "white", "black", "size", "komi", "noSwap", "tps"])

    var wPlayer = human
    var bPlayer = human
    var komi = 2
    var size: uint = 6
    var swap = true
    var tps: string

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
                if val.parseInt(komi) != 1: 
                    return newError("komi is too long")
            of "noSwap": swap = false
            of "tps": tps = val
            else: return newError(&"Option key {key} is invalid")

    if tps != "":
        case size:
        of 3'u: 
            let (game, crErr) = parseGame(tps, size3, swap, int8 komi)
            return gameLoop(game, wPlayer, bPlayer, crErr)
        of 4'u:
            let (game, crErr) = parseGame(tps, size4, swap, int8 komi)
            return gameLoop[size4](game, wPlayer, bPlayer, crErr)
        of 5'u:
            let (game, crErr) = parseGame(tps, size5, swap, int8 komi)
            return gameLoop(game, wPlayer, bPlayer, crErr)
        of 6'u:
            let (game, crErr) = parseGame(tps, size6, swap, int8 komi)
            return gameLoop(game, wPlayer, bPlayer, crErr)
        of 7'u:
            let (game, crErr) = parseGame(tps, size7, swap, int8 komi)
            return gameLoop(game, wPlayer, bPlayer, crErr)
        of 8'u:
            let (game, crErr) = parseGame(tps, size8, swap, int8 komi)
            return gameLoop(game, wPlayer, bPlayer, crErr)
        else:
            return newError("Invalid board size")
    else:
        case size:
        of size3: 
            let (game, crErr) = newGame(size3, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)        
        of size4:
            let (game, crErr) = newGame(size4, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)
        of size5:
            let (game, crErr) = newGame(size5, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)
        of size6:
            let (game, crErr) = newGame(size6, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)
        of size7:
            let (game, crErr) = newGame(size7, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)
        of size8:
            let (game, crErr) = newGame(size8, int8 komi, swap)
            gameLoop(game, wPlayer, bPlayer, crErr)
        else:
            return newError("Invalid board size")

proc mainLoop*() = 

    let err = initGame()
    if ?err:
        echo $err
        quit(1)