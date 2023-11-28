from ../tak/move import Move
from ../tak/tile import Color
import ../analysis/evaluation

type 

    UndoType* = enum
        none, all, partial

    GameConfig* = object 
        gameNumber*: string
        gameSize*: uint
        myColor*: Color
        opponent*: string
        swap*: bool
        komi*: int8 
        flats*: uint8
        caps*: uint8
        tpsHistory*: seq[string]
        lastMove*: Move
        lastEval*: EvalType
        undoType*: UndoType
        # hasUndo*: bool

# proc `GameConfig`*(gameNumber: string, gameSize: uint, myColor: Color, komi: int8, flats: uint8, caps: uint8
#             , tpsHistory: seq[string]): GameConfig =
#             GameConfig(gameNumber: gameNumber, gameSize: gameSize, myColor: myColor, komi: komi, flats: flats, caps: caps, tpsHistory: tpsHistory)