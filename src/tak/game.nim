import board
import tile
from move import Square, Move, Direction, Spread, Place, nextInDir
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

proc `dec`*(StoneCounts: var StoneCounts, color: Color, piece: Piece): Error =
    if  (color == white and piece == flat) or  (color == white and piece == wall):
        if StoneCounts.wStones == 0:
            return newError("Can not subtract from no stones")
        else:
            StoneCounts.wStones -= 1
    elif color == white and piece == cap:
        if StoneCounts.wCaps == 0:
            return newError("Can not subtract from no stones")
        else:
            StoneCounts.wCaps -= 1
    elif (color == black and piece == flat) or  (color == black and piece == wall):
        if StoneCounts.bStones == 0:
            return newError("Can not subtract from no stones")
        else:
            StoneCounts.bStones -= 1
    elif color == black and piece == cap:
        if StoneCounts.bCaps == 0:
            return newError("Can not subtract from no stones")
        else:
            StoneCounts.bCaps -= 1

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

proc getColorToPlay*(game: var Game): Color =
    result = game.to_play
    if (game.swap and game.ply < 2):
        result = not result

proc `default`*(sz: uint8): StoneCounts =
    let (stones, caps) = sz.stones_for_size
    result = (wStones: stones, wCaps: caps, bStones: stones, bCaps: caps)

proc newGame*(size: uint8, komi: int8, swap: bool): Game =
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
    return addr_out

proc `[]`*(game: var Game, square: Square): Tile =
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
    let color = game.to_play
    
    if game.board.isSquareOutOfBounds(square):
        return newError("Square is out of bounds")
    var tile = game[square]
    if tile.isTileEmpty:
        return newError("No pieces on tile to move")

    if not (tile.topTile.color == color):
        return newError("Top tile does not belong to player")

    let count = pattern.len
    case direction:
    of up:
        if square.column + count >= game.board.len:
            return newError("Spread moves past bound of board")
    of down:
        if square.column - count < 0:
            return newError("Spread moves past bound of board")
    of left:
        if square.row - count < 0:
            return newError("Spread moves past bound of board")
    of right:
        if square.row + count > game.board.len:
            return newError("Spread moves past bound of board")

    let numPieces = foldl(pattern, a + b)
    
    if tile.stack.len < numPieces:
        return newError("number of pieces in move exceeds number of pieces in stack")

    let origBoardState = game
    
    var toDrop = tile.stack[^numPieces..^1]

    game[square] = if numPieces == len(tile.stack): default(Tile) else: Tile(piece: tile.piece, stack: tile.stack[0 ..< ^numPieces])

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

proc executeMove(self: var Game, move: Move[Place]): Error =

    if self.ply < 2 and move.movekind != flat: return newError("Must place a flat on the first turn!")

    var err = self.executePlace(move.square, move.movekind)
    
    return err

proc executeMove (self: var Game, move: Move[Spread]): Error =
    let spread = move.movekind
    var err = self.executeSpread(move.square, spread.direction, spread.pattern)
    if ?err:
        err.add("Error executing spread")
        return err

proc play*(game: var Game, move: Move): Error =  
    var err = game.executeMove(move)
    if ?err: 
        err.add( &"Error executing move: {move}")
        return err
    if game.swap:
        if game.ply != 1: game.to_play = not game.to_play
    else:
        game.to_play = not game.to_play
    game.ply += 1

proc getMove(game: Game): int =
    echo game.ply

    floorDiv(int game.ply, 2)

proc toTps*(game: Game): string =
    
    let boardTPS = game.board.getTPSBoard()
    let colorNum = game.to_play.numVal
    let move = game.getMove()

    result = &"{boardTPS} {colorNum} {move}"