
# from ../tak/bitmap import Bitmap
# from ../tak/move import Direction
import ../tak/game
from ../tak/tile import Piece, Color

type
    EvalType* = int32

    Evaluation = distinct EvalType

const Win: EvalType = 100_000
const WinThreshold: EvalType = 99_000

proc Zero*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(0)

proc Max*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.high - 1)

proc Min*(t: typedesc[Evaluation]): Evaluation =
    Evaluation(EvalType.low + 1)

proc evaluate*(game: Game, maxPlayer: bool): EvalType =
    let clr = if maxPlayer: white else: black
    
    return EvalType (game.meta.pieceCount(clr, flat) * 100 + game.meta.pieceCount(clr, cap) * 200 +
        game.meta.pieceCount(clr, wall) * 10)

