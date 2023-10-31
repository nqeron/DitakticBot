import connection
import ../analysis/evaluation
import ../util/error
import regex
import std/strformat, std/strutils, std/times
import parseopt

proc processAnalysisSettings*(con: var PlayTakConnection, cfg: var AnalysisConfig): Error =

    let cmd = con.getMessage()

    match cmd, rex"^(Tell|Shout) <(\w+)> ditakticBot: (.*)$":
        let tell = matches[0]
        let player = matches[2]
        let optString = matches[3]

        var pOpts = initOptParser(optString)
        var level: AnalysisLevel
        var initDepth: uint
        var cfgErr: Error

        for kind, key, val in pOpts.getopt():
            case kind:
            of cmdEnd: discard #does this happen?
            of cmdShortOption, cmdLongOption:
                case key:
                of "level":
                    let (lvl, err) = parseAnalysisLevel(val)
                    if ?err:
                        cfgErr.add($err, true)
                    level = lvl
                of "initDepth", "lookAhead":
                    try:
                        initDepth = parseUInt(val)
                    except ValueError:
                        cfgErr.add(&"{key} is not a valid uint", true)
                else: discard #gen errors for not recognized options
            of cmdArgument: discard #also gen errors
    
    match cmd, rex"^(Tell|Shout) <(\w+)> ditakticBot: (\w+)( \w+)?$":
        let tell = matches[0]
        let player = matches[1]
        let option = matches[2]
        let valueStr: string = matches[3].strip()
        
        if option == "level":
            try:
                let level: int = parseInt(valueStr)
                con.tell(tell, player, &"setting ditakticBot analysis level to {level}")
                cfg = newConfig(level)
                return default(Error)
            except ValueError:
                con.tell(tell, player, &"level command must have a valid integer value")
                return newError("Invalid level setting")
        
        if option == "evalLevel":
            let (level, err) = parseAnalysisLevel(valueStr)
            if not ?err:
                con.tell(tell, player, &"setting evvalLevel to {level}")
                cfg.level = level
                return default(Error)
            return err

        if option == "initDepth":
            try:
                let initDepth = parseUInt(valueStr)
                con.tell(tell, player, &"setting ditakticBot analysis initDepth to {initDepth}")
                cfg.initDepth = initDepth
                return default(Error)
            except ValueError:
                con.tell(tell, player, &"initDepth command must have a valid integer value")
                return newError("Invalid initDepth setting")

        if option == "depth":
            try:
                let depth = parseUInt(valueStr)
                con.tell(tell, player, &"setting ditakticBot analysis depth to {depth}")
                cfg.depth = depth
                return default(Error)
            except ValueError:
                con.tell(tell, player, &"depth command must have a valid integer value")
                return newError("Invalid depth setting")

        if option == "duration":
            try:
                let duration =  initDuration(seconds = parseInt(valueStr))
                let ms = duration.inMilliseconds
                con.tell(tell, player, &"setting ditakticBot analysis depth to {ms} milliseconds")
                cfg.maxDuration = duration
                return default(Error)
            except ValueError:
                con.tell(tell, player, &"duration command must have a valid integer value in seconds")
                return newError("Invalid duration setting")

        if option == "options":
            con.tell(tell, player, "Can set options for level, initDepth, depth, and duration")
            return default(Error)

        if option == "current" or option == "settings":
            con.tell(tell, player, &"Playing with settings: {cfg}")
            return default(Error)

        # await ws.tell(tell, player, "Not a valid option to set")
        return newError("Not a valid option")
    
    return newError("Didn't match anything")

proc processForceShutDown*(con: var PlayTakConnection): Error =

    let cmd = con.getMessage()

    match cmd, rex"^Tell <nqeron> ditakticBot: quit$":
        con.tell("Tell", "nqeron", "Shutting down")
        con.logOut()
        return default(Error)

    return newError("Not a shutdown command")

proc processNOK*(con: var PlayTakConnection, processingCmd: string): Error =

    let cmd = con.getMessage()

    match cmd, rex"^NOK$":
        con.tell("Shout", "", &"Got an error while processing command: {processingCmd}")
        return default(Error)

    return newError("Not an NOK signal")