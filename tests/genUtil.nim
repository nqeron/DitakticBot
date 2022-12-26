import std/unittest, std/sugar

template checkEqAll*[F,T]( toCheck: openArray[(F, T)], transform: (frm: F) -> T) =
    check( foldl( mapIt(toCheck, transform(it[0]) == it[1]), a and b, true) )

#[ template checkRoundTripAll*[F, T](toCheck: openArray[F]) =
    check ( foldl( mapIt(toCheck, it.parseToType(T).toDebugString == it), a and b, true) )
    ]#