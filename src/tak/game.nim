import board
import tile
import move
import bitmap
import std/sequtils, std/strformat, std/math, std/bitops
import ../util/error

type 
    StoneCounts* = tuple[wStones: uint8, wCaps: uint8, bStones: uint8, bCaps: uint8]

    ZobristHash* = uint64

    ZobristKeys*[N: static uint] = object
        blackToMove: ZobristHash
        topPieces: array[N, array[N, array[6, ZobristHash]]]
        stackPieces: array[N, array[N, array[256, ZobristHash]]]
        stackHeights: array[N, array[N, array[101, ZobristHash]]]

    Metadata*[Z: static uint] = object
        p1Pieces: Bitmap[Z]
        p2Pieces: Bitmap[Z]
        flatstones: Bitmap[Z]
        standingStones: Bitmap[Z]
        capstones: Bitmap[Z]
        p1FlatCount: uint8
        p2FlatCount: uint8
        p1Stacks: array[Z, array[Z, uint8]]
        p2Stacks: array[Z, array[Z, uint8]]
        hash*: ZobristHash

    Game*[N: static uint] = object 
        board*: Board[N]
        to_play*: Color
        ply*: uint16
        stoneCounts*: StoneCounts
        half_komi*: int8
        swap*: bool
        meta*: Metadata[N]


proc `[]`*(game: var Game, square: Square): var Tile =
    result = game.board[square.row][square.column]

proc `[]`*(game: Game, square: Square): Tile =
    result = game.board[square.row][square.column]

proc `[]=`*(game: var Game, square: Square, tile: Tile) {. inline .} =
    game.board[square.row][square.column] = tile

include zobrist
include metadata

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

proc `default`*(t: typedesc[StoneCounts], size: uint): StoneCounts =
    let (stones, caps) = (uint8 size).stones_for_size
    result = (wStones: stones, wCaps: caps, bStones: stones, bCaps: caps)

proc newGame*(size: static uint, komi: int8 = 2'i8, swap: bool = true): (Game[size], Error) =
    if size < 3 or size > 8: return (default(Game[size]), newError("Game size not supported"))

    var stnCounts: StoneCounts = default(StoneCounts, size)
    var brd = newBoard(size)
    (
        Game[size](
            board: brd,
            to_play: white,
            ply: 0,
            stoneCounts: stnCounts,
            half_komi: komi,
            swap: swap,
            meta: default(Metadata[size])
        ) 
    , default(Error))


proc executePlace(game: var Game, square: Square, piece: Piece): Error =
    let color = game.getColorToPlay()
    
    var err = game.stoneCounts.dec(color, piece)
    if ?err:
        err.add("not enough stones in reserve") 
        return err
    
    if  game.board.isSquareOutOfBounds(square): return newError("square is out of bounds")

    if not game[square].isEmpty: return newError("Cannot place piece in on square with existing pieces") #check if tile is empty
        
    game[square].addPiece(piece, color)
    game.meta.placePiece(piece, color, square)

    return default(Error)

proc executeSpread(game: var Game, square: Square, direction: Direction, pattern: seq[uint]): Error =  
    let color = game.to_play
    
    if game.board.isSquareOutOfBounds(square):
        return newError("Square is out of bounds")
    var tile = game[square]
    if tile.isEmpty:
        return newError("No pieces on tile to move")
    
    let (topPc, chkColor) = tile.topPiece

    if not (chkColor == color):
        return newError("Top tile does not belong to player")

    let count = pattern.len
    case direction:
    of up:
        if (int square.row) - count < 0:
            return newError("Spread moves past bound of board")
    of down:
        if (int square.row) + count >= game.board.len:
            return newError("Spread moves past bound of board")
    of left:
        if (int square.column) - count < 0:
            return newError("Spread moves past bound of board")
    of right:
        if (int square.column) + count >= game.board.len:
            return newError("Spread moves past bound of board")

    let numPieces = uint foldl(pattern, a + b)
    if  numPieces > tile.length:
        return newError("number of pieces in move exceeds number of pieces in stack")

    let origBoardState = game
    game.meta.hash = game.meta.hash.bitxor(zobristHashStack(game, square))

    var carry = game[square].take(numPieces)

    game.meta.setStack(game[square], square)

    game.meta.hash = game.meta.hash.bitxor(zobristHashStack(game, square))

    var nextSquare = square
    var validCrush = false
    for i in 0 ..< count:
        nextSquare = nextSquare.nextInDir(direction)

        if game[nextSquare].len + pattern[i] > MaxStackHeight:
            game = origBoardState
            return newError("Spread causes stack to exceed max height")

        if game.board.isSquareOutOfBounds(nextSquare):
            game = origBoardState
            return newError("Spread moves past bound of board")

        game.meta.hash = game.meta.hash.bitxor(zobristHashStack(game, nextSquare))
        let (piece, _) = if game[nextSquare].isEmpty: (flat, default(Color)) else: game[nextSquare].topPiece
        case piece:
        of flat: discard
        of cap: return newError("Cannot spread into capstone")
        of wall:
            validCrush = i == (count - 1) and topPc == cap and pattern[i] == 1
            if not validCrush:
                return newError("Cannot spread into wall")

        game[nextSquare].add(carry.drop(pattern[i]))
        game.meta.setStack(game[nextSquare], nextSquare)
        game.meta.hash = game.meta.hash.bitxor(zobristHashStack(game, nextSquare))
        

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
        game.executeMove(move.square, move.movedetail.spreadVal)

proc play*(game: var Game, move: Move): Error =  
    var err = game.executeMove(move)
    if ?err: 
        err.add( &"Error executing move: {move}")
        return err

    game.meta.hash = game.meta.hash.bitxor(zobristAdvanceMove(game.N))

    game.to_play = not game.to_play
    game.ply += 1

proc getMove(game: Game): int =
    floorDiv(int game.ply, 2) + 1

proc toTps*(game: Game): string =
    
    let boardTPS = game.board.getTPSBoard()
    let colorNum = game.to_play.numVal
    let move = game.getMove()

    result = &"{boardTPS} {colorNum} {move}"

proc fromPTNMoves*(moves: openArray[string], size: static uint, komi: int8 = 0'i8, swap: bool = true): (Game[size], Error) =
    var (game, error) = newGame(size, komi, swap)
    
    if ?error:
        error.add("Unable to create new game")
        return (default(Game[size]), error)

    for moveStr in moves:
        var (playtype, move, err) = parseMove(moveStr, size)

        if ?err:
            err.add("Unable to parse move")
            return (default(Game[size]), err)

        if playtype != PlayType.move: return (default(Game[size]), newError("Playtype is not a move"))

        err = game.play(move)
        if ?err:
            err.add("Invalid move!")
            return (default(Game[size]), err)
    return (game, default(Error))

proc checkTak*(game: Game): (bool, Color) =
    let m: Metadata[game.N] = game.meta
    let p1RoadBMP: Bitmap[game.N] = m.p1Pieces.bitand(m.flatstones.bitor(m.capstones))
    let p2RoadBMP: Bitmap[game.N] = m.p2Pieces.bitand(m.flatstones.bitor(m.capstones))
    
    let p1Road: bool = p1RoadBMP.spansBoard()
    let p2Road: bool = p2RoadBMP.spansBoard()

    if  p1Road and p2Road:
        return (true, game.getColorToPlay)

    if p1Road:
        return (true, white)

    if p2Road:
        return (true, black)

    return (false, default(Color))




# in a Game, check if a player has more flats than the other player - returns win, winner, tie
proc checkFlatWin*(game: Game): (bool, Color, bool) =
    let reserves = game.stoneCounts
    
    let m = game.meta
    
    if not ((m.p1Pieces.bitor(m.p2Pieces).fillsBoard()) or (reserves.getTotalStones(white) == 0 and reserves.getTotalStones(black) == 0)):
        return (false, default(Color), false)

    let p1Score  = (2 * (int8 m.p1FlatCount))
    let p2Score = (2 * (int8 m.p2FlatCount)) + game.half_komi

    if p1Score > p2Score:
        return (true, white, false)
    elif p2Score > p1Score:
        return (true, black, false)
    else:
        return (true, default(Color), true)

proc isOver*(game: Game): bool =
    let (flatWin, winner, tie) = game.checkFlatWin()
    if flatWin:
        return true
    return game.checkTak()[0]

proc recalculateMetadata*(game: var Game) =
    game.meta = default(Metadata[game.N])

    var x, y: uint
    while x < game.N:
        while y < game.N:
            let square: Square = (row: x, column: y)
            let stack = game[square]
            if not stack.isEmpty:
                game.meta.setStack(stack, square)
            inc(y)
        inc(x)

    game.meta.hash = zobristHashState(game)
