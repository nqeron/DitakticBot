import ws
import asyncdispatch
import std/strformat, std/strutils, os
from ../util/byteString import toString
import ../util/error
import std/atomics
import locks

type
    ConnectionFlag = enum
        connected = 0, loggedIn, inGame, hasSeek, listingGames

    #bit set -- connected, loggedIn, inGame
    ConnectionState* = array[5, Atomic[bool]]

    PlayTakConnection* = object
        lock: Lock
        ws {.guard: lock.}: WebSocket
        state: ConnectionState
        lastMessage: string
        messageProcessed: bool

const TELL* = "Tell"
const SHOUT* = "Shout"


proc `[]=`*(state: var ConnectionState, flag: ConnectionFlag, value: bool) =
    state[ord flag].store(value)

proc `[]`*(state: var ConnectionState, flag: ConnectionFlag): bool =
    state[ord flag].load

proc setupConnection*(con: var PlayTakConnection) =
    con.lock.initLock()
    con.lock.acquire()
    {.locks: [con.lock]}:
        con.ws = waitfor newWebSocket("ws://playtak.com:9999/ws")
        con.state[connected] = true
        con.lock.release

proc logOut*(con: var PlayTakConnection) =
    con.state[loggedIn] = false

proc logIn*(con: var PlayTakConnection) =
    con.state[loggedIn] = true    

proc isLoggedIn*(con: var PlayTakConnection): bool =
    return con.state[loggedIn]

proc getMessage*(con: var PlayTakConnection): string =
    if con.messageProcessed or con.lastMessage == "":
        con.lock.acquire()
        {.locks: [con.lock].}:
            let cmdBytes: seq[byte] = waitfor con.ws.receiveBinaryPacket()
            let cmd = cmdBytes.toString.strip()
            con.lastMessage = cmd
            con.messageProcessed = false
            con.lock.release()

    return con.lastMessage

proc flushMessage*(con: var PlayTakConnection) =
    con.messageProcessed = true

proc send*(con: var PlayTakConnection, message: string) =
    con.lock.acquire()
    {.locks: [con.lock].}:
        waitfor con.ws.send(message)
        con.lock.release()

proc tell*(con: var PlayTakConnection, tellCmd: string, player: string, message: string) =
    if tellCmd == "Tell":
        con.send(&"{tellCmd} {player} {message}")
    else:
        if player != "":
            con.send(&"{tellCmd} @{player}: {message}")
        else:
            con.send(&"{tellCmd} {message}")

proc ping*(con: var PlayTakConnection)=
    con.send("PING")

proc genPings*(con: var PlayTakConnection) =
    while con.isLoggedIn:
        con.send("PING")
        sleep 10000

proc loginAndSetup*(con: var PlayTakConnection, username: string, password: string): Error =
    var cmd = con.getMessage()
    if cmd != "Welcome!":
        return newError("Expected token 'Welcome!'")
    con.flushMessage()

    cmd = con.getMessage()
    if cmd != "Login or Register":
        return newError("Expected token 'Login or Register'")

    con.send(&"Login {username} {password}")

    con.flushMessage()
    cmd = con.getMessage()
    if cmd != &"Welcome {username}!":
        return newError(&"Expected token 'Welcome {username}!'")
    
    con.flushMessage()
    con.logIn()
    return default(Error)

proc joinGame*(con: var PlayTakConnection) =
    con.state[inGame] = true

proc exitGame*(con: var PlayTakConnection) =
    con.state[inGame] = false

proc isInGame*(con: var PlayTakConnection): bool =
    return con.state[inGame]

proc setSeek*(con: var PlayTakConnection, val: bool) =
    con.state[hasSeek] = val

proc hasSeek*(con: var PlayTakConnection): bool =
    return con.state[hasSeek]

proc isListingGames*(con: var PlayTakConnection): bool =
    return con.state[listingGames]

proc setListingGames*(con: var PlayTakConnection, val: bool) =
    con.state[listingGames] = val

proc close*(con: var PlayTakConnection) =
    con.lock.acquire()
    {.locks: [con.lock].}:
        con.ws.close()
        con.lock.release()

# proc customHandle*[R](con: var PlayTakConnection, handle: proc, args: varargs[untyped]): R =
#     let cmd = con.getMessage()
#     con.handle(cmd, args)