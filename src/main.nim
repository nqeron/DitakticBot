import tak/game as gm
import tak/move as mv
import tak/tps
import tak/game as gm
import play/play as playMove, play/player

import std/strformat

import util/error


# let (play, move, err) = parseMove("3a3>1211", 5)
# if ?err:
#     echo $err
# echo play, move

mainLoop()

# let move = newMove(newSquare(1,1,), Place.flat)

# var (game, err) = parseGame("x6/x6/x6/x6/x6/x6 2 1", true)

# #var game = newGame(6'u8, 2'i8, true)


# if ?err:
#     echo $err
# else:
#     echo $game
    
#     let move = newMove(newSquare(1,1), Place.flat)
#     echo move
#     err = game.play(move)
#     if ?err:
#         echo $err
#     else:
#         echo game.toTps