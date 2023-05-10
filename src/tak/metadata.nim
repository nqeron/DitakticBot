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

proc pieceCount*(m: Metadata, color: Color, piece: Piece): int =
    if (color == white and piece == flat):
        return int m.p1FlatCount
    elif (color == black and piece == flat):
        return (int) m.p2FlatCount
    elif (color == white and piece == wall):
        return (int) m.p1Pieces.bitand(m.standingStones).popCount
    elif (color == black and piece == wall):
        return (int) m.p2Pieces.bitand(m.standingStones).popCount
    elif (color == white and piece == cap):
        return (int) m.p1Pieces.bitand(m.capstones).popCount
    elif (color == black and piece == cap):
        return (int) m.p2Pieces.bitand(m.capstones).popCount
    else:
        return 0

#returns size of each group
proc groupCount*(m: Metadata, color: Color): seq[int] =
    let edge = edgeMask(m.Z)
    let allEdges = edge[ord(up)].bitor(edge[ord(right)]).bitor(edge[ord(down)]).bitor(edge[ord(left)])

    let bmp: Bitmap[m.Z] = m.flatstones.bitor(m.capstones).bitand(if color == white: m.p1Pieces else: m.p2Pieces)
    var sizes: seq[int]
    for group in bmp.groupsFrom(bmp.bitand(allEdges)).groupIterator:
        sizes.add(int group.popCount())

    return sizes