import ../tak/game as gm
import ../tak/move as mv
import ../util/error
import std/strformat
import ../analysis/bot

type
    ActorKind* = enum
        human, ai, playtak 

    Actor* = object
        case kind*: ActorKind
        of human: humanVal: Human
        of ai: aiVal*: MinMax
        of playTak: playTakVal*: PlayTak

proc parseActorKind*(actStr: string): (ActorKind, Error) =
    if actStr == "": return (default(ActorKind), newError("Actor string is empty"))
    case actStr
    of "h", "human":
        (human, default(Error))
    of "a", "ai", "bot":
        (ai, default(Error))
    of "p", "pl", "pt", "playtak":
        (playtak, default(Error))
    else:
        (default(ActorKind), newError(&"Actor is invalid {actStr}"))

proc getMove*(actor: Actor, game: Game): (PlayType, Move, Error) =
    case actor.kind
    of human:
        let moveStr = readLine(stdin)
        return parseMove(moveStr, game.N)
    of ai:
        let minMax: MinMax = actor.aiVal
        let (playType, move, error) = getAIMove(game, minMax.analysisConfig)
        if not ?error:
            echo &"AI move: {move}"
        return (playType, move, error)
    of playtak:
        return (default(PlayType), default(Move), newError("Not Supported yet"))


