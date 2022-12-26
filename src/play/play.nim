import ../tak/game as gm
import ../tak/move as mv
import ../tak/tps as tpsParse
from ../tak/tile import Color
import player
import ../util/error
import std/parseopt, std/parseutils, std/strformat

type
    Play = enum
        move, undo

proc initGame(): (Game, Actor, Actor, Error) =

    var p = initOptParser(shortNoVal = {'h'}, longNoVal = @["help", "white", "black", "size", "komi", "noSwap", "tps"])

    var wPlayer = human
    var bPlayer = human
    var komi = 2
    var size = 6
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
                    return (default(Game), default(Actor), default(Actor), err)
            of "black": 
                (bPlayer, err) = val.parseActor()
                if ?err:
                    err.add("Error parsing black actor")
                    return (default(Game), default(Actor), default(Actor), err)
            of "size": 
                if val.parseInt(size) != 1:
                    return (default(Game), default(Actor), default(Actor), newError("size too long"))
            of "komi": 
                if val.parseInt(komi) != 1: 
                    return (default(Game), default(Actor), default(Actor), newError("komi is too long"))
            of "noSwap": swap = false
            of "tps": tps = val
            else: return (default(Game), default(Actor), default(Actor), newError(&"Option key {key} is invalid"))

    if tps != "":
        let (game, err) = parseGame(tps, swap, int8 komi)
        return (game, wPlayer, bPlayer, err)

    let (game, crErr) = newGame(uint8 size, int8 komi, swap)
    return (game, wPlayer, bPlayer, crErr)


proc getMoveFromPlayer*(game: Game, wPlayer: Actor, bPlayer: Actor): (PlayType, Move, Error) =
    case game.to_play
    of white:
        return wPlayer.getMove(game)
    of black:
        return bPlayer.getMove(game)


proc mainLoop*() = 

    var (game, wPlayer, bPlayer, err) = initGame()
    if ?err:
        echo $err
        return
    
    echo &"Playing game {game} with players: {wPlayer}, {bPlayer}"

    var positionHistory = @[game]

    while true: #isNotFinished?
        #get move
        var (playType, pMove, err) = game.getMoveFromPlayer(wPlayer, bPlayer)

        if ?err:
            echo $err
            break

        case playType
        of PlayType.undo:
            game = positionHistory.pop()
        of PlayType.move:
            var nextPos = game
            err = nextPos.play(pMove)
            if ?err:
                echo $err
            else:
                game = nextPos
                positionHistory.add(game)

        echo game.toTps
        
        if game.ply == 20: #put in break temporarily
            break

        #play/undo move