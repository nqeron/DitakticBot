import std/threadpool
import std/atomics
import os
import std/random
import locks

{.experimental: "parallel".}
type
    Test = object
        L: Lock
        shouldGen {.guard: L.}: bool


var shouldGen: Atomic[bool]
    

proc testGenMsg(t: var Test) =
    var i = 0
    while true:
        t.L.acquire()
        {.locks: [t.L].}:
            let cont = t.shouldGen
            t.L.release()
            if not cont:
                break

        let disp = i
        echo disp
        i += 1
        sleep 1000

proc makeCalc(t: var Test) =
    while shouldGen.load:
        echo "random 1-20 not to continue"
        let num = rand(20)
        if num == 15:
            shouldGen.store(false)
        sleep 1500
        

randomize()
shouldGen.store(true)
var test: Test
parallel:
    spawn test.testGenMsg()
    spawn test.makeCalc()
