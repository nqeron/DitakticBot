import tak/game as gm
from tak/tps import parseGame

import util/error

let (game, err) = parseGame("2,x2,1,x2/x4,1,x/x2,2,12,1,x/x2,12C,1,21C,x/x2,2,1S,12,x/1,x,2,x,1,x 2 12")

if not ?err:
    echo $game