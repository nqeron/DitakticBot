import play/play
import tei/tei
# import playtak/client
import std/strutils
import std/parseopt


var p = initOptParser()
var debug: bool
for kind, key, val in p.getopt():
    case kind:
    of cmdArgument, cmdEnd: discard
    of cmdLongOption, cmdShortOption:
        case key:
        of "debug":
            debug = parseBool(val)
        else:
            discard

teiLoop(debug)