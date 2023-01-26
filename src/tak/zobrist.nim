import random
import game
from tile import Piece, Color

type
    
    ZobristHash* = uint64

    ZobristKeys[N: static uint] = object
        blackToMove: ZobristHash
        topPieces: array[N, array[N, array[6, ZobristHash]]]
        stackPieces: array[N, array[N, array[256, ZobristHash]]]
        stackHeights: array[N, array[N, array[101, ZobristHash]]]

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
    of 3: ZobristKeys3S.blackToMove
    of 4: ZobristKeys4S.blackToMove
    of 5: ZobristKeys5S.blackToMove
    of 6: ZobristKeys6S.blackToMove
    of 7: ZobristKeys7S.blackToMove
    of 8: ZobristKeys8S.blackToMove
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

proc zobristHashStack(game: Game, i, j: uint, keys: ZobristKeys): ZobristHash =
    var hash = 0'u64
    
    let tile = game.board[i][j]

    if not tile.isTileEmpty:
        let piece, color = tile.topTile
        hash = hash.bitxor(keys.topPieces[i][j][pieceIndex(piece, color)])
        hash = hash.bitxor(keys.stackHeights[i][j][tile.height])
        hash = hash.bitxor(keys.stackPieces[i][j][game.metadata.p2Stacks[i][j]])

    return hash

proc zobristHashStateSized(game: Game, keys: ZobristKeys): ZobristHash =
    var hash = 0'u64
    for i in 0 ..< game.size:
        for j in 0 ..< game.size:
            hash = hash.bitxor(zobristHashStack(game, i, j, keys))
    if game.blackToMove:
        hash = hash.bitxor(keys.blackToMove)
    hash

proc zobristHashState*[N: static uint](game: Game[N]): ZobristHash =
    case N:
    of 3: zobristHashStateSized(game, ZobristKeys3S)
    of 4: zobristHashStateSized(game, ZobristKeys4S)
    of 5: zobristHashStateSized(game, ZobristKeys5S)
    of 6: zobristHashStateSized(game, ZobristKeys6S)
    of 7: zobristHashStateSized(game, ZobristKeys7S)
    of 8: zobristHashStateSized(game, ZobristKeys8S)
    else: discard
