import game, move, tile, board

type
    SpreadGen = tuple[square: Square, hand: uint, drops: seq[uint]]

template newSpreadGen(sq: Square, pickup: uint, drps: seq[uint] = @[]): SpreadGen =
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
    let tile: Tile = game[square]

    let (tileTopPiece, _) = tile.topPiece
    let size = game.N
    let maxCarry: uint = uint min(tile.len, size)
    for direction in [up, down, left, right]:
        for pickup in 1'u .. maxCarry:
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
                let (nextPiece, _) = if nextTile.isEmpty: (flat, default(Color)) else: nextTile.topPiece
                
                let canDrop = case nextPiece
                of flat: true
                of cap: false
                of wall: spread.hand == 1 and tileTopPiece == cap

                if not canDrop: continue

                for drop in 1'u .. spread.hand:
                    var drops = spread.drops
                    drops.add(drop)
                    spreads.add(newSpreadGen(nextSquare, spread.hand - drop, drops))
                    



proc possibleMoves*(game: Game): seq[Move] =
    result = @[]

    # if game.ply < 2:
    #     return result #addOpeningMoves()

    let size = game.N

    var col, r: uint
    while col < size:
        r = 0
        while r < size:

            let square: Square = (row: r, column: col)
            let tile: Tile = game[square]
            
            if tile.isEmpty():
                result.addPlaces(game, square)
                r += 1
                continue

            let (_, color) = tile.topPiece
            if color == game.getColorToPlay():
                result.addSpreads(game, square)
            r += 1
        col += 1