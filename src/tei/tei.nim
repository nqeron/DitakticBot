import ../tak/game
import ../tak/move as mv
import ../tak/tps as tpsParse
from ../tak/tile import Color
import ../analysis/bot
import ../analysis/evaluation
import ../play/player
import ../util/error
import std/parseopt, std/parseutils, std/strformat, std/strutils, std/times
import ../util/makeStatic



const size3 = 3'u
const size4 = 4'u
const size5 = 5'u
const size6 = 6'u
const size7 = 7'u
const size8 = 8'u

proc analyzeNewGameBySize(sSize: static uint, cfg: Config): Error =
    # let cfg = vargs[0]
    let (game, err) = newGame(sSize)
    if ?err:
        return err
    let (eval, pv) = analyze(game, cfg)
    echo &"info score cp {eval} pv {pv}"

proc analyzeTPSbySize(sSize: static uint, tps: string, swap: bool, halfKomi: int8, cfg: Config): Error =
    let (game, err) = parseGame(tps, sSize, swap, halfKomi)
    if ?err:
        return err
    let (eval, pv) = analyze(game, cfg)
    echo &"info score cp {eval} pv {pv}"


proc chooseAnalysis(tps: string, size: uint, swap: bool, halfKomi: int8, cfg: Config): Error =
        
        if tps == "":
            chooseSize(size, analyzeNewGameBySize, cfg)
        else:
            chooseSize(size, analyzeTPSbySize, tps, swap, halfKomi, cfg)

const NimblePkgVersion {.strdefine.} = ""
const NimblePkgAuthor {.strdefine.} = ""

proc teiLoop*() = 

    var halfKomi: int8 = 2'i8
    var size = 6'u
    var swap = true
    var tps = ""
    var level: uint8 = 5'u8
    
    while true:
        let message = readLine(stdin)
        if message == "":
            break

        var parts = message.split(" ")
        
        case parts[0]:
        of "tei":
            echo &"id name DitakticBot {NimblePkgVersion}"
            echo &"id author {NimblePkgAuthor}"
            echo "option name HalfKomi type spin default 2 min -10 max 10"
            echo "option name Swap type check default true"
            echo "option name Level type spin default 2 min 1 max 3"
            echo "teiok"
        of "isready":
            echo "readyok"
        of "setoption":
            let name = parts[1].split("=")[1]
            let value = parts[2].split("=")[1]
            case name:
            of "HalfKomi":
                halfKomi = int8 parseInt(value)
                assert halfKomi >= -10 and halfKomi <= 10, "Invalid komi"
            of "Swap":
                swap = value == "true"
            of "Level":
                level = uint8 parseUInt(value)
                assert level >= 1 and level <= 3, "Invalid level"
        of "teinewgame":
            if parts.len < 2:
                size = 6'u
                continue
            size = parseUInt(parts[1])

            if size < 3'u or size > 8'u:
                echo "error: invalid size"
                size = 6'u
                continue
        of "position":
            if parts.len < 2:
                echo "error: position requires a type"
                continue

            case parts[1]:
            of "startpos":
                tps = ""
            of "tps":

                if parts.len < 3:
                    echo "error: tps requires a tps string"
                    continue

                tps = parts[2..^1].join(" ")
            else:
                echo "error: unknown position type"
                continue
        of "go":
            #ignore depth and duration for now
            let cfg = newConfig(level, 8'u, initDuration(minutes = 1))
            let err = chooseAnalysis(tps, size, swap, halfKomi, cfg)
            if ?err:
                echo &"error: {$err}"

        of "quit":
            break
        else:
            echo "error: unknown command"
            continue




        