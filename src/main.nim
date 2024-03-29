import play/play
import tei/tei
import playtak/client

import std/strformat

import std/parseopt

const NimblePkgVersion {.strdefine.} = ""

var p = initOptParser()

var idx = 0
var launchTei = false
var launchAnalyze = false
var launchPlaytak = false


proc writeHelp() =
    echo "p tei [--debug 0/1]"
    echo "p analyze [--file ptn]"
    echo "p playtak"

proc writeVersion() =
    echo &"{NimblePkgVersion}"

for kind, key, val in p.getopt():
  case kind
  of cmdArgument:
    if idx == 0 and key == "tei":
        launchTei = true
    elif idx == 0 and key == "analyze":
        launchAnalyze = true
    elif idx == 0 and key == "playtak":
        launchPlaytak = true
    else:
        writeHelp()    
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
  of cmdEnd: assert(false) # cannot happen
  idx += 1

if launchTei:
    teiLoop()
elif launchPlaytak:
    echo "Starting Playtak"
    connectionLoop()