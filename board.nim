type

    Piece = enum
        flat, wall, capstone

    Color = enum
        white, black

    Tile = object 
        piece: Piece 
        stack: seq[Color]

    Board[N : uint8] = ref object
        data: array[N, array[N, Tile]]

proc newBoard*[N: uint8](data: array[N, array[N, Tile]]): Board[N] =
    new(result)
    result.data = data
    
var test = newBoard[1]([[Tile(piece: Piece.flat, stack: @[Color.white, Color.white])]])

echo test


#[var test: array[2, array[2, int]] = [[1,2],[3,4]]
echo test]#