import game, move, tile, board

type
    SpreadGen = tuple[square: Square, hand: int, drops: seq[int]]

template newSpreadGen(sq: Square, pickup: int, drps: seq[int] = @[]): SpreadGen =
    (square: sq, hand: pickup, drops: drps)
    

proc addPlaces(moves: var seq[Move], game: Game, square: Square) =
    if game.ply < 2:
        moves.add(newMove(square, newPlace(flat)))
        return
    let stoneCounts = game.stoneCounts
    #TODO - check stone counts for flat/cap
    if stoneCounts.getFlats(game.getColorToPlay()) > 0:
        moves.add(newMove(square, newPlace(flat)))
        moves.add(newMove(square, newPlace(wall)))
    
    if stoneCounts.getCaps(game.getColorToPlay()) > 0:
        moves.add(newMove(square, newPlace(cap)))

proc addSpreads(moves: var seq[Move], game: Game, square: Square) =
    let tile = game[square]
    let size = len(game.board)
    let maxCarry = min(tile.len, game.board.len)
    for direction in [up, down, left, right]:
        for pickup in 1..maxCarry:
            var spreads = @[newSpreadGen(square, pickup)]
            while spreads != @[]:
                var spread = spreads.pop()
                if spread.hand == 0:
                    moves.add(newMove(square, newSpread(direction, spread.drops)))
                    continue
                let nextSquare = spread.square.nextInDir(direction)
                if game.board.isSquareOutOfBounds(nextSquare):
                    continue
                let nextTile = game[nextSquare]
                let (nextPiece, _) = nextTile.topTile()
                
                let canDrop = case nextPiece
                of flat: true
                of cap: false
                of wall: spread.hand == 1 and tile.piece == cap

                if not canDrop: continue

                for drop in 1..spread.hand:
                    var drops = spread.drops
                    drops.add(drop)
                    spreads.add(newSpreadGen(nextSquare, spread.hand - drop, drops))
                    



proc possibleMoves*(game: Game): seq[Move] =
    result = @[]

    # if game.ply < 2:
    #     return result #addOpeningMoves()

    let size = len(game.board)

    for col in 0..<size:
        for row in 0..<size:
            let square = newSquare(row, col)
            let tile: Tile = game[square]
            
            if tile.isTileEmpty():
                result.addPlaces(game, square)
                continue

            let (_, color) = tile.topTile()
            if color == game.getColorToPlay():
                result.addSpreads(game, square)