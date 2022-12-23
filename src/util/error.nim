import std/strutils

type
    Error* = tuple[fail: bool, trace: seq[string]]

template `?`*(err: Error): bool =
    err.fail

template `$`*(err: Error): string =
    err.trace.join("; ")
    
proc `add`*(err: var Error, msg: string) =
    err.trace.add(msg)
    
template newError*(msg: string, res: bool = true): Error =
    (fail: res, trace: @[msg])
    