import bitmap
from tile import Tile, Color, Piece

type
    Metadata*[N: static uint] = object
        p1Pieces: Bitmap[N]
        p2Pieces: Bitmap[N]
        flatstones: Bitmap[N]
        standingStones: Bitmap[N]
        capstones: Bitmap[N]
        p1FlatCount: uint8
        p2FlatCount: uint8
        p1Stacks: array[N, array[N, uint8]]
        p2Stacks: array[N, array[N, uint8]]
        #hash: ZobristHash

proc setStack*(m: var Metadata, tile: Tile, x: uint, y: uint) =
    if (m.flatstones.bitand(m.p1Pieces)).get(x, y):
        m.p1FlatCount -= 1
    elif (m.flatstones.bitand(m.p2Pieces)).get(x, y):
        m.p2FlatCount -= 1

    if tile.isTileEmpty:
        m.p1Pieces.clear(x, y)
        m.p2Pieces.clear(x, y)
        m.flatstones.clear(x, y)
        m.standingStones.clear(x, y)
        m.capstones.clear(x, y)
        return

    let (piece, color) = tile.topTile

    case color:
    of white:
        m.p1Pieces.set(x, y)
        m.p2Pieces.clear(x, y)
    of black:
        m.p1Pieces.clear(x, y)
        m.p2Pieces.set(x, y)

    case piece:
    of flat:
        m.flatstones.set(x, y)
        m.standingStones.clear(x, y)
        m.capstones.clear(x, y)
        case color:
        of white:
            m.p1FlatCount += 1
        of black:
            m.p2FlatCount += 1
    of wall:
        m.flatstones.clear(x, y)
        m.standingStones.set(x, y)
        m.capstones.clear(x, y)
    of cap:
        m.flatstones.clear(x, y)
        m.standingStones.clear(x, y)
        m.capstones.set(x, y)
    
    # m.hash = m.hash xor zobristHashes[x][y][tile]
