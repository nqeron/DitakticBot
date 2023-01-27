import random

randomize()

proc newZobrist(size: static uint): ZobristKeys[size] =
    #initRand(0xdeadbeef'u64)
    var keys: ZobristKeys[size]
    for i in 0 ..< size:
        for j in 0 ..< size:
            for k in 0 ..< 6:
                keys.topPieces[i][j][k] = rand(uint64)
            for k in 0 ..< 256:
                keys.stackPieces[i][j][k] = rand(uint64)
            for k in 0 ..< 101:
                keys.stackHeights[i][j][k] = rand(uint64)
    keys.blackToMove = rand(uint64)


let ZobristKeys3S = newZobrist(3'u)
let ZobristKeys4S = newZobrist(4'u)
let ZobristKeys5S = newZobrist(5'u)
let ZobristKeys6S = newZobrist(6'u)
let ZobristKeys7S = newZobrist(7'u)
let ZobristKeys8S = newZobrist(8'u)

proc zobristAdvanceMove*(size: static uint): ZobristHash =
    case size
    of 3: return ZobristKeys3S.blackToMove
    of 4: return ZobristKeys4S.blackToMove
    of 5: return ZobristKeys5S.blackToMove
    of 6: return ZobristKeys6S.blackToMove
    of 7: return ZobristKeys7S.blackToMove
    of 8: return ZobristKeys8S.blackToMove
    else: discard

# proc downcastSize[N: static uint](game: Game[N]): static uint =
#     case N:
#     of 3: 3'u
#     of 4: 4'u
#     of 5: 5'u
#     of 6: 6'u
#     of 7: 7'u
#     of 8: 8'u
#     else: discard

proc pieceIndex*(piece: Piece, color: Color): uint =
    uint ((ord(piece) shr 5) shl 1) + ord(color) - 1

proc zobristHashStackSized(game: Game, square: Square, keys: ZobristKeys): ZobristHash =
    var hash = 0'u64
    let tile: Tile = game[square]

    if not tile.isEmpty:
        var (piece, color) = tile.topPiece
        hash = hash.bitxor(keys.topPieces[square.row][square.column][pieceIndex(piece, color)])
        hash = hash.bitxor(keys.stackHeights[square.row][square.column][tile.len])
        hash = hash.bitxor(keys.stackPieces[square.row][square.column][game.meta.p2Stacks[square.row][square.column]])

    return hash


proc zobristHashStack(game: Game, square: Square): ZobristHash =
    case game.N:
    of 3: return zobristHashStackSized(game, square, ZobristKeys3S)
    of 4: return zobristHashStackSized(game, square, ZobristKeys4S)
    of 5: return zobristHashStackSized(game, square, ZobristKeys5S)
    of 6: return zobristHashStackSized(game, square, ZobristKeys6S)
    of 7: return zobristHashStackSized(game, square, ZobristKeys7S)
    of 8: return zobristHashStackSized(game, square, ZobristKeys8S)
    else: discard

proc zobristHashStateSized(game: Game, keys: ZobristKeys): ZobristHash =
    var hash = 0'u64
    var i, j: uint
    while i < game.N:
        while j < game.N:
            let sq: Square = (row: i, column: j)
            hash = hash.bitxor(zobristHashStack(game, sq))
            inc(j)
        inc(i)
    if game.to_play == black:
        hash = hash.bitxor(keys.blackToMove)
    hash

proc zobristHashState*(game: Game): ZobristHash =
    case game.N:
    of 3: return zobristHashStateSized(game, ZobristKeys3S)
    of 4: return zobristHashStateSized(game, ZobristKeys4S)
    of 5: return zobristHashStateSized(game, ZobristKeys5S)
    of 6: return zobristHashStateSized(game, ZobristKeys6S)
    of 7: return zobristHashStateSized(game, ZobristKeys7S)
    of 8: return zobristHashStateSized(game, ZobristKeys8S)
    else: discard
