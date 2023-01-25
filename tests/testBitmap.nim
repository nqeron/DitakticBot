import std/unittest
import ../src/tak/bitmap

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