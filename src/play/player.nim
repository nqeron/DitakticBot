import ../tak/game as gm
import ../tak/move as mv
import ../util/error
import std/strformat
import ../analysis/bot

type
    Actor* = enum
        human, ai, playtak

proc parseActor*(actStr: string): (Actor, Error) =
    if actStr == "": return (default(Actor), newError("Actor string is empty"))
    case actStr
    of "h", "human":
        (human, default(Error))
    of "a", "ai", "bot":
        (ai, default(Error))
    of "p", "pl", "pt", "playtak":
        (playtak, default(Error))
    else:
        (default(Actor), newError(&"Actor is invalid {actStr}"))

proc getMove*(actor: Actor, game: Game): (PlayType, Move, Error) =
    case actor
    of human:
        let moveStr = readLine(stdin)
        return parseMove(moveStr, game.N)
    of ai:
        let (playType, move, error) = getAIMove(game)
        if not ?error:
            echo &"AI move: {move}"
        return (playType, move, error)
    of playtak:
        return (default(PlayType), default(Move), newError("Not Supported yet"))


