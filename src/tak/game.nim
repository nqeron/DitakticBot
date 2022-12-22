from board import Board, newBoard
from tile import Color, Tile, Piece
from move import Square, Move, Direction, Spread, Place
import std/sequtils

type 
    Game*[N: static uint8, B: static bool] = object 
        board: Board[N]
        to_play: Color
        ply: uint16
        white_stones: uint8
        white_caps: uint8
        black_stones: uint8
        black_caps: uint8
        half_komi: int8
        reversible_plies: uint8

proc stones_for_size(sz: uint8): (uint8, uint8) = 
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

proc newGame*[N: static uint8, B: static bool] (komi: int8): Game[N, B] =
    let (stones, caps) = N.stones_for_size()
    var temp: array[N, array[N, Tile]]
    var addr_out = Game[N, B](
        board: newBoard[N](temp),
        to_play: when B: black else: white,
        ply: 0,
        white_stones: stones,
        white_caps: caps, 
        black_stones: stones,
        black_caps: caps,
        half_komi: komi,
        reversible_plies: 0'u8,
    )
    return addr_out

proc `[]`(game: var Game, square: Square): Tile =
    result = game.board[square.column][square.row]

proc `[]=`(game: var Game, square: Square, tile: Tile) {. inline .} =
    game.board[square.column][square.row] = tile

proc getCounts(game: var Game): (uint8, uint8) =
    case game.to_play
    of white:
        (game.white_stones, game.white_caps)
    of black:
        (game.black_stones, game.black_caps)

proc setCounts(game: var Game, counts: (uint8, uint8)) =
    case game.to_play:
    of white:
        game.white_stones = counts[0]
        game.white_caps = counts[1]
    of black:
        game.black_stones = counts[0]
        game.black_caps = counts[1]

proc executePlace(game: var Game, square: Square, piece: Piece): bool =
    # TODO - check that piece is still available
    let (stones, caps) = game.getCounts()
  
    let color = game.to_play
    
    if stones <= 0: return false
    
    if piece == cap and caps <= 0: return false

    if  not game.board.isSquareOutOfBounds(square):
        if game[square].isTileEmpty: #check if tile is empty
            game[square] = Tile(piece: piece, stack: @[color])
            return true
    return false

proc executeSpread(game: var Game, square: Square, direction: Direction, pattern: seq[int]): bool =
    let color = game.to_play
    
    if game.board.isSquareOutOfBounds(square):
        return false
    var tile = game[square]
    if tile.isTileEmpty:
        return false

    let count = pattern.len
    case direction:
    of up:
        if square.column + count >= game.len:
            return false
    of down:
        if square.column - count < 0:
            return false
    of left:
        if square.row - count < 0:
            return false
    of right:
        if square.row + count > game.len:
            return false
    if not (tile.topTile.color == color):
        return false

    let numPieces = foldl(pattern, a + b)
    
    if tile.stack.len < numPieces:
        return false 

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
                return false 
        of cap:
            game = origBoardState
            return false
        of flat: discard

        game[nextSquare] = game[nextSquare].add(toDrop[0..<pattern[pattern_idx]], 
                                if pattern_idx == (len(pattern) - 1): tile.piece else: flat)
        
        toDrop = toDrop[pattern[pattern_idx]..^1]
        nextSquare = nextSquare.nextInDir(direction)
        pattern_idx += 1

    #take top pieces - sum of pattern
    #drop one by one onto square in direction
    return true

proc executeMove[N, B] (self: var Game[N, B], move: Move[Place], color: Color): bool =
    when not B:
        if (self.ply == 0 and color == black) or (self.ply == 1 and color == white) or (self.ply > 0 and self.ply mod 2 == 0 and color == black) or (self.ply > 1 and self.ply mod 2 == 1 and color == white): return false
    else:
        if (self.ply == 0 and color == white) or (self.ply == 1 and color == black) or (self.ply > 0 and self.ply mod 2 == 0 and color == black) or (self.ply > 1 and self.ply mod 2 == 1 and color == white): return false 
    
    let success: bool = self.executePlace(move.square, move.movekind)
    if success:
        let (stones, caps) = self.getCounts()
        if (move.movekind == cap): self.setCounts((stones, caps - 1))
        else: self.setCounts((stones - 1, caps))
    return success

proc executeMove (self: var Game, move: Move[Spread], color: Color): bool =
    if self.ply <= 1: return false
    if (self.ply mod 2 == 0 and color == black) or (self.ply mod 2 == 1 and color == white): return false 
    let spread = move.movekind
    self.executeSpread(move.square, spread.direction, spread.pattern)

proc play*[N, B](game: var Game[N, B], move: Move) =  
    let success: bool = game.executeMove(move, game.to_play)
    if not success:
        echo: "Invalid Move!"
    when B:
        if game.ply != 1: game.to_play = not game.to_play
    else:
        game.to_play = not game.to_play
    game.ply += 1