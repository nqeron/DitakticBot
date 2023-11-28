import asyncdispatch, os, std/strformat
import ../tak/game, ../tak/tile, ../tak/move, ../tak/tps
import std/strutils
import ../util/error, ../util/makeStatic
import std/sequtils, std/times, std/threadpool
import ../analysis/bot, ../analysis/evaluation
import connection, gameHandles, gameConfig, customHandles

# var curGames: array[5, Game]

proc makeSizedMove(sSize: static uint, gameConfig: var GameConfig, move: Move): Error =
    let stoneCounts: StoneCounts = (wStones: gameConfig.flats, wCaps: gameConfig.caps, bStones: gameConfig.flats, bCaps: gameConfig.caps)
    var (game, err) = parseGame(gameConfig.tpsHistory[^1], sSize, true, gameConfig.komi, stoneCounts)
    # echo "before Move: ", gameConfig.tpsHistory[^1]
    if ?err:
        return err
    let moveErr = game.play(move)
    if ?moveErr:
        return moveErr
    gameConfig.tpsHistory.add(game.toTps)
    # echo "Adding: ", game.toTps
    return default(Error)


proc makeMove(gameConfig: var GameConfig, move: Move) =
    let _ = chooseSize(gameConfig.gameSize, makeSizedMove, gameConfig, move)

proc analyzeBySize(sSize: static uint, gameConfig: var GameConfig, analysisConfig: AnalysisConfig): Error =
    let stoneCounts: StoneCounts = (wStones: gameConfig.flats, wCaps: gameConfig.caps, bStones: gameConfig.flats, bCaps: gameConfig.caps)
    # echo "tps: ", gameConfig.tpsHistory[^1]
    
    var (game, err) = parseGame(gameConfig.tpsHistory[^1], sSize, true, gameConfig.komi, stoneCounts)
    
    if ?err:
        return err

    let (eval, pv) =  game.analyze(analysisConfig)

    let (_, move, _) = parseMove(pv, sSize)
    
    
    let pErr =  game.play(move)

    if ?pErr:
        return pErr

    gameConfig.lastMove = move
    gameConfig.lastEval = eval
    gameConfig.tpsHistory.add(game.toTps)

    return default(Error)

proc respondWithMove(con: var PlayTakConnection, gConfig: var GameConfig, analysisConfig: AnalysisConfig): Error =
    # con.tell(TELL, gConfig.opponent, &"Using config: {analysisConfig}")
    let gConfErr = chooseSize(gConfig.gameSize, analyzeBySize, gConfig, analysisConfig)
    if ?gConfErr:
        return gConfErr

    let move: Move = gConfig.lastMove
    # con.tell("Tell", gConfig.opponent, &"Trying to play: {move}")

    case move.movedetail.kind:
    of place:
        let sq = move.square.ptnVal(gConfig.gameSize).toUpper
        let pieceType: Piece = move.movedetail.placeVal
        let pieceDataStr = if pieceType == cap: "C" elif pieceType == wall: "W" else: ""
        waitfor con.send(&"Game#{gConfig.gameNumber} P {sq} {pieceDataStr}")
    of spread:
        let sqFrom = move.square
        let spread = move.movedetail.spreadVal
        let sqToStr = sqFrom.nextInDir(spread.direction, uint spread.pattern.len).ptnVal(gConfig.gameSize).toUpper
        let sqFromStr = sqFrom.ptnVal(gConfig.gameSize).toUpper
        let drops = spread.pattern.join(" ")
        waitfor con.send(&"Game#{gConfig.gameNumber} M {sqFromStr} {sqToStr} {drops}")

    return default(Error)


proc processCommands(con: ref PlayTakConnection) {. thread .} =
    var prevCmd: string
    var cmd: string
    var gameConfig: GameConfig
    var analysisConfig: AnalysisConfig
    
    while con.isLoggedIn:

        prevCmd =  cmd
        cmd = con.getMessage()
        # echo &"Trying to process cmd: {cmd}"

        # echo "Checking for Analysis"
        let anConfigErr = con.processAnalysisSettings(analysisConfig) 
        
        if not ?anConfigErr:
            con.flushMessage()
            continue
        
        # echo "Checking for join game"
        var botMove = false
        let (newGameConfig, toPlay, err) = con.processStartGameCommand(analysisConfig)

        if not ?err:
            gameConfig = newGameConfig
            botMove = toPlay
            con.flushMessage()
        else:
            echo $err

        # echo "Checking for "
        let (move, pMoveErr) = con.processMove(gameConfig.gameSize)
        if not ?pMoveErr:
            gameConfig.makeMove(move)
            botMove = true
            con.flushMessage()

        if botMove:
            let err = con.respondWithMove(gameConfig, analysisConfig)
            if not ?err:
                con.flushMessage()
                continue

        let pUndoRequest = con.processUndo(gameConfig, analysisConfig)
        if not ?pUndoRequest:
            con.flushMessage()
            continue

        let pDrawRequest = con.processDrawRequest()
        if not ?pDrawRequest:
            con.flushMessage()
            continue

        let pGameOver = con.processGameOver()
        if not ?pGameOver:
            con.flushMessage()
            gameConfig = default(GameConfig)
            continue

        let pShutDown = con.processForceShutDown()
        if not ?pShutDown:
            break

        let pNok = con.processNOK(prevCmd)
        if not ?pNok:
            con.flushMessage()
            continue

        let pIgnoredCommands = con.processIgnoredHandles()
        if not ?pIgnoredCommands:
            con.flushMessage()
        else:
            echo $pIgnoredCommands
    
        if not con.isListingGames and not con.hasSeek and not con.isInGame:
            con.createSeek()
            continue

proc connectionLoop*(dbg: bool = false) =
    # var ws = await newWebSocket("ws://playtak.com:9999/ws")

    let username = "ditakticBot"
    let password = getEnv("ditakticBotPassword")
    var debug = dbg

    let con: ref PlayTakConnection = new PlayTakConnection

    con.setupConnection()

    echo "connected"

    let lError = con.loginAndSetup(username, password)

    con.setListingGames(true)
    if ?lError:
        echo "Login Error:", $lError
        return

    echo "login"
    
    con.genPings()
    con.processCommands()      

    # echo "quitting"
    waitfor con.send("quit")
    con.close()