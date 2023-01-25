import board
import tile
import move
import std/sequtils, std/strformat, std/math
import ../util/error

type 

    StoneCounts* = tuple[wStones: uint8, wCaps: uint8, bStones: uint8, bCaps: uint8]

    Game* = object 
        board*: Board
        to_play*: Color
        ply*: uint16
        stoneCounts*: StoneCounts
        half_komi*: int8
        reversible_plies*: uint8
        swap*: bool

proc getFlats*(stoneCounts: StoneCounts, color: Color): uint8 =
    case color
    of white:
        return stoneCounts.wStones
    of black:
        return stoneCounts.bStones

proc getCaps*(stoneCounts: StoneCounts, color: Color): uint8 =
    case color
    of white:
        return stoneCounts.wCaps
    of black:
        return stoneCounts.bCaps

proc getTotalStones*(stoneCounts: StoneCounts, color: Color): uint8 =
    return stoneCounts.getFlats(color) + stoneCounts.getCaps(color)

proc `dec`*(stoneCounts: var StoneCounts, color: Color, piece: Piece): Error =
    if  (color == white and piece == flat) or  (color == white and piece == wall):
        if stoneCounts.wStones == 0:
            return newError("Can not subtract from no stones")
        else:
            stoneCounts.wStones -= 1
    elif color == white and piece == cap:
        if stoneCounts.wCaps == 0:
            return newError("Can not subtract from no stones")
        else:
            stoneCounts.wCaps -= 1
    elif (color == black and piece == flat) or  (color == black and piece == wall):
        if stoneCounts.bStones == 0:
            return newError("Can not subtract from no stones")
        else:
            stoneCounts.bStones -= 1
    elif color == black and piece == cap:
        if stoneCounts.bCaps == 0:
            return newError("Can not subtract from no stones")
        else:
            stoneCounts.bCaps -= 1

    return default(Error)

    
proc stones_for_size*(sz: uint8): (uint8, uint8) = 
    case sz
    of 3:
        result = (stones: 10'u8, capstones: 0'u8)
    of 4:
        result = (stones: 15'u8, capstones: 0'u8)
    of 5:
        result = (stones: 21'u8, capstones: 1'u8)
    of 6:
        result = (stones: 30'u8, capstones: 1'u8)
    of 7:
        result = (stones: 40'u8, capstones: 2'u8)
    of 8:
        result = (stones: 50'u8, capstones: 2'u8)
    else: result = (stones: 0'u8, capstones: 0'u8)

proc getColorToPlay*(game: Game): Color =
    result = game.to_play
    if (game.swap and game.ply < 2):
        result = not result

proc `default`*(sz: uint8): StoneCounts =
    let (stones, caps) = sz.stones_for_size
    result = (wStones: stones, wCaps: caps, bStones: stones, bCaps: caps)

proc newGame*(size: uint8 = 6'u8, komi: int8 = 2'i8, swap: bool = true): (Game, Error) =
    if size < 3 or size > 8: return (default(Game), newError("Game size not supported"))

    var stnCounts: StoneCounts = default(size)
    var board = newBoard(int size)
    var addr_out = Game(
        board: board,
        to_play: white,
        ply: 0,
        stoneCounts: stnCounts,
        half_komi: komi,
        reversible_plies: 0'u8,
        swap: swap
    )
    return (addr_out, default(Error))

proc `[]`*(game: Game, square: Square): Tile =
    result = game.board[square.row][square.column]

proc `[]=`*(game: var Game, square: Square, tile: Tile) {. inline .} =
    game.board[square.row][square.column] = tile


proc executePlace(game: var Game, square: Square, piece: Piece): Error =
    let color = game.getColorToPlay()
    
    var err = game.stoneCounts.dec(color, piece)
    if ?err:
        err.add("not enough stones in reserve") 
        return err
    
    if  game.board.isSquareOutOfBounds(square): return newError("square is out of bounds")

    if not game[square].isTileEmpty: return newError("Cannot place piece in on square with existing pieces") #check if tile is empty
        
    game[square] = Tile(piece: piece, stack: @[color])

    return default(Error)

proc executeSpread(game: var Game, square: Square, direction: Direction, pattern: seq[int]): Error =
    #echo "executing spread: ", square, " ", direction, " ", pattern
    let color = game.to_play
    
    if game.board.isSquareOutOfBounds(square):
        return newError("Square is out of bounds")
    var tile = game[square]
    if tile.isTileEmpty:
        return newError("No pieces on tile to move")

    if not (tile.topTile.color == color):
        return newError("Top tile does not belong to player")

    let count = pattern.len
    #echo &"count: {count}"
    case direction:
    of up:
        if square.row - count < 0:
            return newError("Spread moves past bound of board")
    of down:
        if square.row + count >= game.board.len:
            return newError("Spread moves past bound of board")
    of left:
        if square.column - count < 0:
            return newError("Spread moves past bound of board")
    of right:
        if square.column + count >= game.board.len:
            return newError("Spread moves past bound of board")

    let numPieces = foldl(pattern, a + b)
    #echo &"numPieces: {numPieces}"
    if tile.stack.len < numPieces:
        return newError("number of pieces in move exceeds number of pieces in stack")

    let origBoardState = game
    
    var toDrop = tile.stack[^numPieces..^1]
    #echo &"toDrop: {toDrop}"
    game[square] = if numPieces == len(tile.stack): default(Tile) else: Tile(piece: flat, stack: tile.stack[0 ..< ^numPieces])

    var pattern_idx = 0

    var nextSquare: Square = square.nextInDir(direction)
    while pattern_idx < pattern.len:

        case game[nextSquare].topTile.piece
        of wall:
            if not( tile.piece == cap and (pattern_idx == (len(pattern) - 1)) and pattern[pattern_idx] == 1): 
                game = origBoardState
                return newError("can not move into square")
        of cap:
            game = origBoardState
            return newError("can not move into square")
        of flat: discard

        game[nextSquare] = game[nextSquare].add(toDrop[0..<pattern[pattern_idx]], 
                                if pattern_idx == (len(pattern) - 1): tile.piece else: flat)
        
        toDrop = toDrop[pattern[pattern_idx]..^1]
        
        nextSquare = nextSquare.nextInDir(direction)
        pattern_idx += 1
        

    #take top pieces - sum of pattern
    #drop one by one onto square in direction
    return default(Error)

proc executeMove(self: var Game, square: Square, place: Place): Error =

    if self.ply < 2 and place != flat: return newError("Must place a flat on the first turn!")

    var err = self.executePlace(square, place)
    
    return err

proc executeMove (self: var Game, square: Square, spread: Spread): Error =
    var err = self.executeSpread(square, spread.direction, spread.pattern)
    if ?err:
        err.add("Error executing spread")
        return err

proc executeMove(game: var Game, move: Move): Error =
    case move.movedetail.kind:
    of place:
        game.executeMove(move.square, move.movedetail.placeVal)
    of spread:
        #echo "executing spread"
        game.executeMove(move.square, move.movedetail.spreadVal)

proc play*(game: var Game, move: Move): Error =  
    var err = game.executeMove(move)
    if ?err: 
        err.add( &"Error executing move: {move}")
        return err
    game.to_play = not game.to_play
    game.ply += 1

proc getMove(game: Game): int =
    floorDiv(int game.ply, 2) + 1

proc toTps*(game: Game): string =
    
    let boardTPS = game.board.getTPSBoard()
    let colorNum = game.to_play.numVal
    let move = game.getMove()

    result = &"{boardTPS} {colorNum} {move}"

proc fromPTNMoves*(moves: openArray[string], size: uint8, komi: int8 = 0'i8, swap: bool = true): (Game, Error) =
    var (game, error) = newGame(size, komi, swap)
    
    if ?error:
        error.add("Unable to create new game")
        return (default(Game), error)

    for moveStr in moves:
        var (playtype, move, err) = parseMove(moveStr, int size)

        echo moveStr, move, ?err, $err
        if ?err:
            err.add("Unable to parse move")
            return (default(Game), err)

        if playtype != PlayType.move: return (default(Game), newError("Playtype is not a move"))

        err = game.play(move)
        echo game.toTps
        echo ?err, $err
        if ?err:
            err.add("Invalid move!")
            return (default(Game), err)
    return (game, default(Error))

# # in a 2d array of 1s and 0s check if there is a path from left to right or top to bottom, but not left or right to bottom and not left or right to top
# proc checkTak*( game: Game, color: Color): bool =
#     let board = game.board
#     var visited: seq[seq[(bool, bool)]] = newSeq[seq[(bool, bool)]](board.len)
#     for i in 0 ..< board.len:
#         visited[i] = newSeq[(bool, bool)](board.len)
    
#     var queue: seq[Square] = @[]
#     var leftEdge = false
#     var topEdge = false
#     for i in 0 ..< board.len:
#         if  game.board[i][0].topColorEq(color):
#             queue.add(newSquare(i, 0))
#             visited[i][0] = (true, false)
#         if  board[0][i].topColorEq(color):
#             queue.add(newSquare(0, i))
#             visited[0][i] = (false, true)

#     while queue.len > 0:
#         let square = queue.pop()
#         if board[square.row][square.column].topColorEq(color) and ((visited[square.row][square.column][1] and square.row == board.len - 1) or (visited[square.row][square.column][0] and square.column == board.len - 1)):
#             return true
#         for dir in [up, down, left, right]:
#             let nextSquare = square.nextInDir(dir)
#             if nextSquare.row >= 0 and nextSquare.row < board.len and nextSquare.column >= 0 and nextSquare.column < board.len:
#                 if board[nextSquare.row][nextSquare.column].topColorEq(color):
#                     if not (visited[nextSquare.row][nextSquare.column][0] and visited[nextSquare.row][nextSquare.column][1]):
#                         queue.add(nextSquare)
#                         visited[nextSquare.row][nextSquare.column] = (visited[square.row][square.column][0] or visited[nextSquare.row][nextSquare.collumn][0], visited[square.row][square.column][1] or )

#     return false

# in a Game, check if a player has more flats than the other player - returns win, winner, tie
proc checkFlatWin*(game: Game): (bool, Color, bool) =
    let reserves = game.stoneCounts
    
    let board = game.board
    var wCount, bCount = 0
    for i in 0 ..< board.len:
        for j in 0 ..< board.len:
            if not board[i][j].isTileEmpty and board[i][j].topTile.piece == flat:
                if board[i][j].topTile.color == white:
                    wCount += 1
                else:
                    bCount += 1

    if wCount + bCount > board.len * board.len:
        if wCount == bCount + game.half_komi:
            return (true, default(Color), true)
        return (true, if wCount > bCount + game.half_komi: white else: black, false)

    if reserves.getTotalStones(white) > 0 or reserves.getTotalStones(black) > 0:
        return (false, default(Color), false)

    if wCount > bCount + game.half_komi:
        return (true, white, false)
    elif bCount + game.half_komi > wCount:
        return (true, black, false)
    else:
        return (true, default(Color), true)

proc isOver*(game: Game): bool =
    let (flatWin, winner, tie) = game.checkFlatWin()
    if flatWin:
        return true
    # if game.checkTak(game.to_play):
    #     return true
    # if game.checkTak(not game.to_play):
    #     return true
    return false