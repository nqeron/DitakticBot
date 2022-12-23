from tak/game as gm import Game, newGame
from tak/tps import parseGame


var game = parseGame("2,2,1,1,1211112S,1/1,2,221C,2S,12,21/1,21S,2112C,2,1,1/2,2,2,1,2,2S/1,2,21S,2,1212S,1/1,1S,2,1,1,1 1 39", true, 2'i8)

echo $game