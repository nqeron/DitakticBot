import std/unittest, std/sugar

template checkEqAll*[F,T]( toCheck: openArray[(F, T)], transform: (frm: F) -> T) =
    check( foldl( mapIt(toCheck, transform(it[0]) == it[1]), a and b, true) )

template checkRoundTripAll*(toCheck: openArray[string], rTrip: (frm: string) -> bool) =
    check ( foldl( mapIt(toCheck, rTrip(it)), a and b, true) )

template checkFuncAll*[F](toCheck: openArray[F], transform: (frm: F) -> bool) =
    check( foldl( mapIt(toCheck, transform(it), a and b, true)))