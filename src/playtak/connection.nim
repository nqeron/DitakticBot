import ws
import asyncdispatch
import std/strformat, std/strutils, os
from ../util/byteString import toString
import ../util/error
import std/atomics

type
    ConnectionFlag = enum
        connected = 0, loggedIn, inGame, hasSeek, listingGames

    #bit set -- connected, loggedIn, inGame
    ConnectionState* = array[5, Atomic[bool]]

    PlayTakConnection* = object
        ws: WebSocket
        state: ConnectionState
        lastMessage: string
        messageProcessed: bool

const TELL* = "Tell"
const SHOUT* = "Shout"


proc `[]=`*(state: var ConnectionState, flag: ConnectionFlag, value: bool) =
    state[ord flag].store(value)

proc `[]`*(state: ConnectionState, flag: ConnectionFlag): bool =
    var z: Atomic[bool] = state[ord flag]
    return z.load

proc setupConnection*(con: var PlayTakConnection) =
    con.ws = waitfor newWebSocket("ws://playtak.com:9999/ws")
    con.state[connected] = true

proc logOut*(con: var PlayTakConnection) =
    con.state[loggedIn] = false

proc logIn*(con: var PlayTakConnection) =
    con.state[loggedIn] = true    

proc isLoggedIn*(con: PlayTakConnection): bool =
    return con.state[loggedIn]

proc getMessage*(con: var PlayTakConnection): string =
    if con.messageProcessed or con.lastMessage == "":
        let cmdBytes: seq[byte] = waitfor con.ws.receiveBinaryPacket()
        let cmd = cmdBytes.toString.strip()
        con.lastMessage = cmd
        con.messageProcessed = false

    return con.lastMessage

proc flushMessage*(con: var PlayTakConnection) =
    con.messageProcessed = true

proc send*(con: PlayTakConnection, message: string): Future[void] {. async .} =
    # echo &"Sending message:{message}"
    # var l = con.lock
    await con.ws.send(message)

proc tell*(con: var PlayTakConnection, tellCmd: string, player: string, message: string) =
    if tellCmd == "Tell":
        waitfor con.send(&"{tellCmd} {player} {message}")
    else:
        if player != "":
            waitfor con.send(&"{tellCmd} @{player}: {message}")
        else:
            waitfor con.send(&"{tellCmd} {message}")

proc ping*(con: ref PlayTakConnection)=
    waitfor con.send("PING")

proc genPings*(con: ref PlayTakConnection) =

    proc pingLoop() {. async .} =
        while con.isLoggedIn:
            await con.send("PING")
            await sleepAsync(30000)
    asyncCheck pingLoop()

proc loginAndSetup*(con: var PlayTakConnection, username: string, password: string): Error =
    var cmd = con.getMessage()
    if cmd != "Welcome!":
        return newError("Expected token 'Welcome!'")
    con.flushMessage()

    cmd = con.getMessage()
    if cmd != "Login or Register":
        return newError("Expected token 'Login or Register'")

    waitfor con.send(&"Login {username} {password}")

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
     con.ws.close()

# proc customHandle*[R](con: var PlayTakConnection, handle: proc, args: varargs[untyped]): R =
#     let cmd = con.getMessage()
#     con.handle(cmd, args)