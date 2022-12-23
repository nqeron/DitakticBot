import tak/game
from tak/tps import parseGame


#var game = parseGame("2,2,1,1,1211112S,1/1,2,221C,2S,12,21/1,21S,2112C,2,1,1/2,2,2,1,2,2S/1,2,21S,2,1212S,1/1,1S,2,1,1,1 1 39", true, 2'i8)

#echo $game

#var tpsTest = "2,x2,1,x2/x4,1,x/x2,2,12,1,x/x2,12C,1,21C,x/x2,2,1S,12,x/1,x,2,x,1,x 2 12"
var (gameTwo, err) = parseGame("2,x2,1,x2/x4,1,x/x2,2,12,1,x/x2,12C,1,21C,x/x2,2,1S,12,x/1,x,2,x,1,x 2 12", false, 0'i8)

echo $gameTwo[(row: 2, column: 3)]

#a1 = row: N-1, col: 0
#a6 = 0, 0
#f1 = N, N-1
#f6 = 0, N-1