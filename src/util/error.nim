import std/strutils

#Introduce ErrorKind?

type
    Error* = tuple[fail: bool, trace: seq[string]]

template `?`*(err: Error): bool =
    err.fail

template `$`*(err: Error): string =
    err.trace.join("; ")
    
proc `add`*(err: var Error, msg: string, withRaise: bool = false) =
    err.trace.add(msg)
    err.fail = withRaise
    
template newError*(msg: string, res: bool = true): Error =
    (fail: res, trace: @[msg])
    