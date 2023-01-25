import std/unittest, std/bitops
import ../src/tak/bitmap
from ../src/tak/move import Direction

suite "bit map tests":

    test "test set":
        var b = Bitmap[5](0'u8)
        b.set(uint 0, uint 0)
        check(b == 0x10'u64)

        b = Bitmap[5](0'u8)
        b.set(1, 0);
        check(b == 0x08'u64)

        b = Bitmap[5](0'u8)
        b.set(1, 1);
        check(b == 0x0100'u64)

        b = Bitmap[5](0'u8)
        b.set(4, 4)
        check(b == 0x100000'u64)

    test "test clear":
        var b = Bitmap[5](0xFFFFFFFFFFFFFFFF'u64)
        b.clear(0, 0);
        check(b == 0xFFFFFFFFFFFFFFEF'u64);

        b = Bitmap[5](0xFFFFFFFFFFFFFFFF'u64)
        b.clear(1, 0);
        check(b == 0xFFFFFFFFFFFFFFF7'u64);

        b = Bitmap[5](0xFFFFFFFFFFFFFFFF'u64)
        b.clear(1, 1);
        check(b == 0xFFFFFFFFFFFFFEFF'u64);

        b = Bitmap[5](0xFFFFFFFFFFFFFFFF'u64)
        b.clear(4, 4);
        check(b == 0xFFFFFFFFFFEFFFFF'u64);

    test "test get":
        let b = Bitmap[5](0b0000000110001001010101000)
        check(not b.get(0, 0))
        check(b.get(1, 0))
        check(b.get(0, 1))
        check(b.get(2, 1))
        check(b.get(2, 2))
        check(not b.get(3, 2))

    test "test coordinates":
        check(Bitmap[3](0b000000001).coordinates() == (uint 2, uint 0))
        check(Bitmap[3](0b000000010).coordinates() == (uint 1, uint 0))
        check(Bitmap[3](0b000000100).coordinates() == (uint 0, uint 0))
        check(Bitmap[3](0b000001000).coordinates() == (uint 2, uint 1))
        check(Bitmap[3](0b000010000).coordinates() == (uint 1, uint 1))
        check(Bitmap[3](0b000100000).coordinates() == (uint 0, uint 1))
        check(Bitmap[3](0b001000000).coordinates() == (uint 2, uint 2))

    test "test dilate":
        let b = Bitmap[5](0b0000000000001000000000000)
        check(b.dilate() == Bitmap[5](0b0000000100011100010000000))

        let bit = Bitmap[5](0b1000100000000000000010001)
        check(bit.dilate() == Bitmap[5](0b11011_10001_00000_10001_11011))

        let bitOne = Bitmap[5](0b00000_00100_01110_00100_00000)
        #0001 1011 1000 1000 0010 0011 0011
        check(bitOne.dilate() == Bitmap[5](0b00100_01110_11111_01110_00100))

    test "test flood":
        var b = Bitmap[5'u](0b0000000000001000000000000)
        check(b.floodFill(boardMask(5'u)) == Bitmap[5](0b11111_11111_11111_11111_11111))
        b = Bitmap[5'u](0b0000000000000000001000000)
        check(b.floodFill(0b111_111_111_111) == Bitmap[5](0b111_111_111_111))

    test "test groups":
        let b = Bitmap[5'u](0b1110011010001100011111000)
        var g: GroupIter[5'u] = b.groups
        let gIter = nextGroup(g)

        check(gIter() == Bitmap[5](0b00000_00000_00000_00000_11000))
        check(gIter() == Bitmap[5](0b00000_00010_00110_00111_00000))
        check(gIter() == Bitmap[5](0b11100_11000_00000_00000_00000))
        let _ = gIter()
        check(finished(gIter))

    test "test width":
        let b = Bitmap[5'u](0b0000001100011100100001000)
        check(b.width == 3)

    test "test height":
        let b = Bitmap[5'u](0b0000001100011100100001000)
        check(b.height == 4)

    test "test bitIter":
        let b: BitIter[3'u] = (Bitmap[3'u](0b010110001)).bits()
        let bIter = nextBit(b)

        check(bIter() == Bitmap[3](0b000000001))
        check(bIter() == Bitmap[3](0b000010000))
        check(bIter() == Bitmap[3](0b000100000))
        check(bIter() == Bitmap[3](0b010000000))
        let _ = bIter()
        check(finished(bIter))

    test "test edgeMasks":
        proc allEdges(size: static uint): Bitmap[size] =
            let edges = edgeMask(size)
            return edges[ord(up)].bitor(edges[ord(left)]).bitor(edges[ord(down)]).bitor(edges[ord(right)])

        check(allEdges(3) == Bitmap[3](0b111_101_111))
        check(allEdges(4) == Bitmap[4](0b1111_1001_1001_1111))
        check(allEdges(5) == Bitmap[5](0b11111_10001_10001_10001_11111))
        check(allEdges(6) == Bitmap[6](0b111111_100001_100001_100001_100001_111111))
        check(allEdges(7) == Bitmap[7](0b1111111_1000001_1000001_1000001_1000001_1000001_1111111))
        check(allEdges(8) == Bitmap[8](0b11111111_10000001_10000001_10000001_10000001_10000001_10000001_11111111'u64))

   