import ../tak/game
import error
import std/macros


template chooseSize*(size: uint, toApply: proc, args: varargs[untyped]): Error =
    const size3 = 3'u
    const size4 = 4'u
    const size5 = 5'u
    const size6 = 6'u
    const size7 = 7'u
    const size8 = 8'u

    case size:
    of size3:
       toApply(size3, args)
    of size4:
        toApply(size4, args)
    of size5:
        toApply(size5, args)
    of size6:
        toApply(size6, args)
    of size7:
        toApply(size7, args)
    of size8:
        toApply(size8, args)
    else:
        newError("Invalid size")

template chooseSizeWithRes*[T](size: uint, toApply: proc, args: varargs[untyped]): (T, Error) =
    const size3 = 3'u
    const size4 = 4'u
    const size5 = 5'u
    const size6 = 6'u
    const size7 = 7'u
    const size8 = 8'u

    case size:
    of size3:
       toApply(size3, args)
    of size4:
        toApply(size4, args)
    of size5:
        toApply(size5, args)
    of size6:
        toApply(size6, args)
    of size7:
        toApply(size7, args)
    of size8:
        toApply(size8, args)
    else:
        (default(typeof(T)), newError("Invalid size"))