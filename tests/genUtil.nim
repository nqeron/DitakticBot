import std/unittest, std/sugar
import ../src/util/error

template checkEqAll*[F,T]( toCheck: openArray[(F, T)], transform: (frm: F) -> T) =
    check( foldl( mapIt(toCheck, transform(it[0]) == it[1]), a and b, true) )

template checkRoundTripAll*(toCheck: openArray[string], rTrip: (frm: string) -> bool) =
    check ( foldl( mapIt(toCheck, rTrip(it)), a and b, true) )

template checkFuncAll*[F](toCheck: openArray[F], transform: (frm: F) -> bool) =
    check( foldl( mapIt(toCheck, transform(it), a and b, true)))

template checkWithErr*[T](toCheck: tuple[frm: T, err: Error], val: T) =
    if ?toCheck[1]:
        check(false)
    else:
        check(toCheck[0] == val)