proc setStack*(m: var Metadata, tile: Tile, square: Square) =
    if (m.flatstones.bitand(m.p1Pieces)).get(square.row, square.column):
        m.p1FlatCount -= 1
    elif (m.flatstones.bitand(m.p2Pieces)).get(square.row, square.column):
        m.p2FlatCount -= 1

    if tile.isEmpty:
        m.p1Pieces.clear(square.row, square.column)
        m.p2Pieces.clear(square.row, square.column)
        m.flatstones.clear(square.row, square.column)
        m.standingStones.clear(square.row, square.column)
        m.capstones.clear(square.row, square.column)
        return

    let (piece, color) = tile.topPiece

    case color:
    of white:
        m.p1Pieces.set(square.row, square.column)
        m.p2Pieces.clear(square.row, square.column)
    of black:
        m.p1Pieces.clear(square.row, square.column)
        m.p2Pieces.set(square.row, square.column)

    case piece:
    of flat:
        m.flatstones.set(square.row, square.column)
        m.standingStones.clear(square.row, square.column)
        m.capstones.clear(square.row, square.column)
        case color:
        of white:
            m.p1FlatCount += 1
        of black:
            m.p2FlatCount += 1
    of wall:
        m.flatstones.clear(square.row, square.column)
        m.standingStones.set(square.row, square.column)
        m.capstones.clear(square.row, square.column)
    of cap:
        m.flatstones.clear(square.row, square.column)
        m.standingStones.clear(square.row, square.column)
        m.capstones.set(square.row, square.column)
    
proc placePiece*(m: var Metadata, piece: Piece, color: Color, square: Square) =
    case color:
    of white:
        m.p1Pieces.set(square.row, square.column)
        m.p2Pieces.clear(square.row, square.column)
    of black:
        m.p1Pieces.clear(square.row, square.column)
        m.p2Pieces.set(square.row, square.column)
    
    case piece:
    of flat:
        m.flatstones.set(square.row, square.column)
        m.standingStones.clear(square.row, square.column)
        m.capstones.clear(square.row, square.column)
        case color:
        of white:
            m.p1FlatCount += 1
        of black:
            m.p2FlatCount += 1
    of wall:
        m.standingStones.set(square.row, square.column)
    of cap:
        m.capstones.set(square.row, square.column)
    # m.hash = m.hash xor zobristHashes[x][y][tile]
