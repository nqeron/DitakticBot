# main package

import std/strformat

version = "0.0.1"
author = "Noah Fields (nqeron)"
description = "DitakticBot"
license = "MIT"

srcDir = "src"
binDir = "bin"
bin = @["tei", "playtak"]

skipExt = @["nim"]

requires "nim >= 1.6.10"
requires "regex"
requires "ws >= 0.5.0"


task debug, "Build debug":
    
    binDir = 
        when defined(windows): "bin/debug/windows" 
        else: 
            when defined(macosx): "bin/debug/osx"
            else: "bin/debug/other"
    for b in bin:
        exec &"nim c -o:{binDir}/{b} {srcDir}/{b}.nim"

task release, "Build release":
    binDir =
        when defined(windows): "bin/release/windows" 
        else: 
            when defined(macosx): "bin/release/osx" 
            else: "bin/release/other"
    for b in bin:
        exec &"nim c -o:{binDir}/{b} -d:release {srcDir}/{b}.nim"


