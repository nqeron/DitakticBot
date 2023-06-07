import connection, gameConfig 
import ../tak/move, ../tak/tile, ../tak/game
import regex
import ../util/error, ../util/makeStatic
import std/strutils, std/sequtils, std/strformat
import asyncdispatch
from ../analysis/evaluation import AnalysisConfig, newConfig



proc newGameConfigBySize(size: static uint, gameNumber: string, myColor: Color, opponent: string, komi: int8, flats: uint8, caps: uint8, swap: bool = true): (GameConfig, Error) =
    let (game, err) = newGame(size, komi, swap)
    if ?err:
        return (default(GameConfig), newError("Could not instantiate game"))

    var emptyTps = @[game.toTps]

    return (GameConfig(gameNumber: gameNumber, gameSize: size, myColor: myColor, opponent: opponent, komi: komi, flats: flats, caps: caps, tpsHistory: emptyTps), default(Error))


proc processStartGameCommand*(con: var PlayTakConnection, analysisCfg: var AnalysisConfig): (GameConfig, bool, Error) =

    if not con.isLoggedIn:
        return (default(GameConfig), false, newError("Not Logged in. "))
    
    let cmd = con.getMessage()

    match cmd, rex"^Game Start (\d+) (\d) (\w+) vs (\w+) (\w+) (\d+) (\d) (\d+) (\d) (\d+) (\d+)$":
        let gameNumber = matches[0]
        let gameSize = parseUint(matches[1])
        let playerWhite = matches[2]
        let playerBlack = matches[3]
        let myColor: Color = parseColorString(matches[4])
        # let time = parseInt(matches[5])
        let komi = int8 parseInt(matches[6])
        let flats = uint8 parseUInt(matches[7])
        let caps = uint8 parseUInt(matches[8])
        # let triggerMove = parseInt(matches[9])
        # let timeamount = parseInt(matches[10])

        let toPlay: bool = myColor == white
        let opponent = if myColor == white: playerBlack else: playerWhite

        let (gConfig, err) = chooseSizeWithRes[GameConfig](gameSize, newGameConfigBySize, gameNumber, myColor, opponent, komi, flats, caps)

        analysisCfg = newConfig(7) #default a level - 7 for now, may change

        con.joinGame()

        return (gConfig, toPlay, err)

    return (default(GameConfig), false, newError("Not a game create command"))

proc processMove*(con: var PlayTakConnection, size: uint): (Move, Error)  =

    let cmd = con.getMessage()

    match cmd, rex"^Game#(\d+) P ([a-hA-H][1-8])( C| W)?$":
        
        echo matches[1]

        var piece: Piece = 
            if matches[2].strip() == "C": cap 
            elif matches[2].strip() == "W": wall 
            else: flat

        var (sq, _) = parseSquare(matches[1], size) 

        let move = newMove(sq, newPlace(piece))
        # echo &"parsed move: {move.ptnVal(gameConfig.gameSize)}"
        return (move, default(Error))


    match cmd, rex"^Game#(\d+) M ([a-hA-H][1-8]) ([a-hA-H][1-8])( \d)+$":

        let (sqFrom, _) = parseSquare(matches[1], size)
        let (sqTo, _) = parseSquare(matches[2], size)
        let (direction, _) = sqFrom.dirTo(sqTo)
        let drops = mapIt(matches[3 .. ^1], it.strip().parseUInt())
        
        let move = newMove(sqFrom, newSpread(direction, drops))
        echo &"parsed move: {move.ptnVal(size)}"
        return (move, default(Error))

    # echo "no move match"
    return (default(Move), newError("Not a valid move command"))



proc processUndo*(con: var PlayTakConnection, gameConfig: var GameConfig): Error =
    
    let cmd = con.getMessage()

    match cmd, rex"^Game#(\d+) RemoveUndo$":
        return default(Error)

    match cmd, rex"^Game#(\d+) RequestUndo$":
        let gameNumber = matches[0]

        # if not gameConfig.hasUndo:
        #     con.tell("Tell", gameConfig.opponent, "Undo was removed before able to process")
        #     return default(Error)

        case gameConfig.undoType:
        of none:
            con.tell("Tell", gameConfig.opponent, "Bot is currently set to not accept undos")
            return default(Error)
        of UndoType.all, partial:
            waitfor con.send(&"Game#{gameNumber} RequestUndo")
            return default(Error)
        #TODO separate logic for partial undos
        # of partial:

    return newError("No Undo requested")

proc processGameOver*(con: var PlayTakConnection): Error =
    
    let cmd = con.getMessage()

    match cmd, rex"^Game#(\d+) Over (.*)$":
        con.setSeek(false)
        con.exitGame()
        return default(Error)

    return newError("Not a Game over command")
            
proc processDrawRequest*(con: var PlayTakConnection): Error =
    
    let cmd = con.getMessage()

    match cmd, rex"^Game#(\d+) OfferDraw$":
        let gameNumber = matches[0]
        waitfor con.send(&"Game#{gameNumber} OfferDraw")
        return default(Error)

    return newError("No Draw Offered")

proc createSeek*(con: var PlayTakConnection, size: int = 6, time: int = 1200, increment: int = 30, color: string = "B", komi: int = 4, 
        flats: int = 30, caps: int = 1, player: string = "") =
    
    let unrated = 0
    let tournament = 0
    # let triggerMove = 0
    # let timeAmount = 0

    var seek = &"Seek {size} {time} {increment} {color} {komi} {flats} {caps} {unrated} {tournament}"
    if player != "":
        seek.add(&" {player}")
    echo &"Creating seek: {seek}"
    waitfor con.send(seek)
    # echo "sent seek"
    # echo con.lock
    con.setSeek(true)
    # con.flushMessage()
    # let resp = con.getMessage()
    # echo resp

proc processIgnoredHandles*(con: var PlayTakConnection): Error =

    let cmd = con.getMessage()

    match cmd, rex"^Seek (new|remove) (\d+) (\w+) (\d) (\d+) (\d+) (\w) (\d) (\d+) (\d) (\d) (\d) (\d) (\d)( \w+)?$":
        #Ignore seeks
        return default(Error)

    match cmd, rex"^GameList (Add|Remove|remove) (\d+) (\w+) (\w+) (\d) (\d+) (\d+) (\d) (\d+) (\d) (\d) (\d) (\d)( \w+)?$":
        #ignore game list commands
        echo cmd
        return default(Error)

    match cmd, rex"^Told (.*)$":
        return default(Error)

    match cmd, rex"^Game#(\d+) Time (\d+) (\d+)$":
        #ignore time printouts for now, maybe account later
        return default(Error)

    match cmd, rex"^Game#(\d+) RemoveDraw$":
        return default(Error)

    match cmd, rex"^OK$":
        #ignore time printouts for now, maybe account later
        return default(Error)

    match cmd, rex"^Message Your game is resumed$":
        return default(Error)

    match cmd, rex"^Error:Not your turn$":
        return default(Error)

    match cmd, rex"^Online (\d+)$":
        #ignore Online commands
        con.setListingGames(false)
        return default(Error)

    match cmd, rex"^Shout <(\w+)> (.*)$":
        #ignore other and own messages
        return default(Error)

    return newError(&"Command should be handled elsewhere: {cmd}")