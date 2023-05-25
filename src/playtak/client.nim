import asyncdispatch, ws, os, std/strformat
import ../tak/game, ../tak/tile, ../tak/move, ../tak/tps
import regex
import std/strutils, std/strformat
import ../util/error, ../util/makeStatic
import std/sequtils, std/times
import ../analysis/bot, ../analysis/evaluation

type 
    GameConfig = object 
        gameNumber: string
        gameSize: uint
        myColor: Color
        komi: int8 
        flats: uint8
        caps: uint8
        tpsHistory: seq[string]
        lastMove: Move
        lastEval: EvalType

# var curGames: array[5, Game]


proc toString(bytes: openarray[byte]): string =
  result = newString(bytes.len)
  copyMem(result[0].addr, bytes[0].unsafeAddr, bytes.len)

proc tell(ws: WebSocket, tellCmd: string, player: string, message: string): Future[void] {. async .} =
    if tellCmd == "Tell":
        await ws.send(&"{tellCmd} {player} {message}")
    else:
        await ws.send(&"{tellCmd} @{player}: {message}")
proc processMove(gameConfig: GameConfig, cmd: string): (Move, Error)  =

    echo "processMove: ", cmd
    var move: Move

    match cmd, rex"^Game#(\d+) P ([a-hA-H][1-8])( C| W)?$":
        
        echo matches[1]

        var piece: Piece = 
            if matches[2].strip() == "C": cap 
            elif matches[2].strip() == "W": wall 
            else: flat

        var (sq, _) = parseSquare(matches[1], gameConfig.gameSize) 

        move = newMove(sq, newPlace(piece))
        echo &"parsed move: {move.ptnVal(gameConfig.gameSize)}"
        return (move, default(Error))

    match cmd, rex"^Game#(\d+) M ([a-hA-H][1-8]) ([a-hA-H][1-8]) (\d)+^":

        let (sqFrom, _) = parseSquare(matches[1], gameConfig.gameSize)
        let (sqTo, _) = parseSquare(matches[2], gameConfig.gameSize)
        let (direction, _) = sqFrom.dirTo(sqTo)
        let drops = mapIt(matches[3 .. ^1], it.parseUInt())
        
        move = newMove(sqFrom, newSpread(direction, drops))
        echo &"parsed move: {move.ptnVal(gameConfig.gameSize)}"
        return (move, default(Error))

    echo "no move match"
    return (default(Move), newError("Not a valid move command"))
    

proc loginAndSetup(command: string, ws: WebSocket): Future[bool] {. async .} =
    let cmd = command.strip()
    if cmd == "Welcome!":
        #don't send a message
        return false
    if cmd == "Login or Register":
        var p: string = getEnv("ditakticBotPassword")
        await ws.send(&"Login ditakticBot {p}")
        return false
    if cmd == "Welcome ditakticBot!":
        await ws.send("Seek 6 1200 30 A 4 30 1 0 0 0 0 nqeron")
        return false

    match cmd, rex"^Tell <(\w+)> ditakticBot: quit$":
        if matches[0] == "nqeron":
            await ws.send(&"Tell <nqeron> terminating ditakticBot")
            return true
        else:
            return false

    match cmd, rex"^Game#(\d+) OfferDraw$":
        await ws.send(&"Game#{matches[0]} OfferDraw")
        return false

    return false
        

proc newGameConfigBySize(size: static uint, gameNumber: string, myColor: Color, komi: int8, flats: uint8, caps: uint8, swap: bool = true): (GameConfig, Error) =
    let (game, err) = newGame(size, komi, swap)
    if ?err:
        return (default(GameConfig), newError("Could not instantiate game"))

    var emptyTps = @[game.toTps]

    return (GameConfig(gameNumber: gameNumber, gameSize: size, myColor: myColor, komi: komi, flats: flats, caps: caps, tpsHistory: emptyTps), default(Error))

    

proc processStartGameCommand(cmd: string): (GameConfig, bool, Error) =

    #matches game number, size, player_white vs player_black your_color time komi pieces cap  triggermove timeamount
    match cmd, rex"^Game Start (\d+) (\d) (\w+) vs (\w+) (\w+) (\d+) (\d) (\d+) (\d) (\d+) (\d+)$":
        let gameNumber = matches[0]
        let gameSize = parseUint(matches[1])
        # let playerWhite = matches[2]
        # let playerBlack = matches[3]
        let myColor: Color = parseColorString(matches[4])
        # let time = parseInt(matches[5])
        let komi = int8 parseInt(matches[6])
        let flats = uint8 parseUInt(matches[7])
        let caps = uint8 parseUInt(matches[8])
        # let triggerMove = parseInt(matches[9])
        # let timeamount = parseInt(matches[10])

        let toPlay: bool = myColor == white

        var emptyTps: seq[string]
        echo "Starting game ..."

        let (gConfig, err) = chooseSizeWithRes[GameConfig](gameSize, newGameConfigBySize, gameNumber, myColor, komi, flats, caps)

        return (gConfig, toPlay, err)

    return (default(GameConfig), false, newError("Not a game create command"))


proc makeSizedMove(sSize: static uint, gameConfig: var GameConfig, move: Move): Error =
    let stoneCounts: StoneCounts = (wStones: gameConfig.flats, wCaps: gameConfig.caps, bStones: gameConfig.flats, bCaps: gameConfig.caps)
    var (game, err) = parseGame(gameConfig.tpsHistory[^1], sSize, true, gameConfig.komi, stoneCounts)
    if ?err:
        return err
    let moveErr = game.play(move)
    if ?moveErr:
        return moveErr
    gameConfig.tpsHistory.add(game.toTps)
    return default(Error)


proc makeMove(gameConfig: var GameConfig, move: Move) =
    let _ = chooseSize(gameConfig.gameSize, makeSizedMove, gameConfig, move)

proc analyzeBySize(sSize: static uint, oldGameConfig: GameConfig, analysisConfig: AnalysisConfig): (GameConfig, Error) =
    var gameConfig = oldGameConfig
    let stoneCounts: StoneCounts = (wStones: gameConfig.flats, wCaps: gameConfig.caps, bStones: gameConfig.flats, bCaps: gameConfig.caps)
    var (game, err) = parseGame(gameConfig.tpsHistory[^1], sSize, true, gameConfig.komi, stoneCounts)
    
    if ?err:
        return (default(GameConfig), err)

    let (eval, pv) =  game.analyze(analysisConfig)

    let (_, move, _) = parseMove(pv, sSize)
    
    
    let pErr =  game.play(move)

    if ?pErr:
        return (default(GameConfig), pErr)

    gameConfig.lastMove = move
    gameConfig.lastEval = eval
    gameConfig.tpsHistory.add(game.toTps)

    return (gameConfig, default(Error))

proc respondWithMove(ws: WebSocket, gConfig: GameConfig, analysisConfig: AnalysisConfig): Future[(GameConfig, Error)] {. async .} =
    let (gameConfig, gConfErr) = chooseSizeWithRes[GameConfig](gConfig.gameSize, analyzeBySize, gConfig, analysisConfig)
    if ?gConfErr:
        return (gameConfig, gConfErr)

    let move: Move = gameConfig.lastMove

    case move.movedetail.kind:
    of place:
        let sq = move.square.ptnVal(gameConfig.gameSize).toUpper
        await ws.send(&"Game#{gameConfig.gameNumber} P {sq}")
    of spread:
        let sqFrom = move.square
        let spread = move.movedetail.spreadVal
        let sqToStr = sqFrom.nextInDir(spread.direction, uint spread.pattern.len).ptnVal(gameConfig.gameSize).toUpper
        let sqFromStr = sqFrom.ptnVal(gameConfig.gameSize).toUpper
        let drops = spread.pattern.join(" ")
        await ws.send(&"Game#{gameConfig.gameNumber} M {sqFromStr} {sqToStr} {drops}")

    return (gameConfig, default(Error))

proc processAnalysisSettings(ws: WebSocket, cmd: string, cfg: AnalysisConfig): Future[(AnalysisConfig, Error)] {. async .} =
    echo "settings: ^", cmd,"$"
    match cmd, rex"^(Tell|Shout) <(\w+)> ditakticBot: (\w+)( \w+)?$":
        let tell = matches[0]
        let player = matches[1]
        let option = matches[2]
        let valueStr = matches[3]
        
        if option == "level":
            try:
                let level: int = parseInt(valueStr)
                await ws.tell(tell, player, &"setting ditakticBot analysis level to {level}")
                return (newConfig(level), default(Error))
            except ValueError:
                await ws.tell(tell, player, &"level command must have a valid integer value")
                return (default(AnalysisConfig), newError("Invalid level setting"))
        
        if option == "evalLevel":
            let (level, err) = parseAnalysisLevel(valueStr)
            if not ?err:
                await ws.tell(tell, player, &"setting evvalLevel to {level}")
                return (AnalysisConfig(level: level, initDepth: cfg.initDepth, depth: cfg.depth, maxDuration: cfg.maxDuration), default(Error))
            return (default(AnalysisConfig), err)

        if option == "initDepth":
            try:
                let initDepth = parseUInt(valueStr)
                await ws.tell(tell, player, &"setting ditakticBot analysis initDepth to {initDepth}")
                return (AnalysisConfig(level: cfg.level, initDepth: initDepth, depth: cfg.depth, maxDuration: cfg.maxDuration), default(Error))
            except ValueError:
                await ws.tell(tell, player, &"initDepth command must have a valid integer value")
                return (default(AnalysisConfig), newError("Invalid initDepth setting"))

        if option == "depth":
            try:
                let depth = parseUInt(valueStr)
                await ws.tell(tell, player, &"setting ditakticBot analysis depth to {depth}")
                return (AnalysisConfig(level: cfg.level, initDepth: cfg.initDepth, depth: depth, maxDuration: cfg.maxDuration), default(Error))
            except ValueError:
                await ws.tell(tell, player, &"depth command must have a valid integer value")
                return (default(AnalysisConfig), newError("Invalid depth setting"))

        if option == "duration":
            try:
                let duration =  initDuration(seconds = parseInt(valueStr))
                let ms = duration.inMilliseconds
                await ws.tell(tell, player, &"setting ditakticBot analysis depth to {ms} milliseconds")
                return (AnalysisConfig(level: cfg.level, initDepth: cfg.initDepth, depth: cfg.depth, maxDuration: duration), default(Error))
            except ValueError:
                await ws.tell(tell, player, &"duration command must have a valid integer value in seconds")
                return (default(AnalysisConfig), newError("Invalid duration setting"))

        if option == "options":
            await ws.tell(tell, player, "Can set options for level, initDepth, depth, and duration")
            return (cfg, default(Error))

        if option == "current" or option == "settings":
            await ws.tell(tell, player, &"Playing with settings: {cfg}")
            return (cfg, default(Error))

        # await ws.tell(tell, player, "Not a valid option to set")
        return (default(AnalysisConfig), newError("Not a valid option"))


proc testconnection*() {. async .} =
    var ws = await newWebSocket("ws://playtak.com:9999/ws")

    var gameConfig: GameConfig
    var analysisConfig: AnalysisConfig

    while true:
        var cmdBytes: seq[byte] = await ws.receiveBinaryPacket()
        let cmd = cmdBytes.toString.strip()
        let shouldExit = await loginAndSetup(cmd, ws)
        
        let (modAnalysisConfig, anConfigErr) = await ws.processAnalysisSettings(cmd, analysisConfig)
        if not ?anConfigErr:
            analysisConfig = modAnalysisConfig
            continue

        var botMove = false
        let (newGameConfig, toPlay, err) = processStartGameCommand(cmd)

        if not ?err:
            gameConfig = newGameConfig
            botMove = toPlay

        let (move, pMoveErr) = gameConfig.processMove(cmd)
        if not ?pMoveErr:
            gameConfig.makeMove(move)
            botMove = true

        if botMove:
            let (modGConfig, err) = await ws.respondWithMove(gameConfig, analysisConfig)
            if not ?err:
                gameConfig = modGConfig
                continue

        if shouldExit:
            break
    
    await ws.send("quit")
    ws.close()



