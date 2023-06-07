import playtak/client
import parseopt

var p = initOptParser()
var debug: bool

for kind, key, val in p.getopt():
    case kind:
    of cmdEnd, cmdArgument: discard
    of cmdLongOption, cmdShortOption:
        case key:
        of "debug":
            debug = true
        else: discard

connectionLoop(debug)