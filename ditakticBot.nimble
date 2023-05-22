# main package

version = "0.0.5"
author = "Noah Fields (nqeron)"
description = "DitakticBot"
license = "MIT"

srcDir = "src"
binDir = "bin"
 
bin = @["main"]

skipExt = @["nim"]

requires "nim >= 1.6.10"
requires "regex"

task debug, "Build debug":
    binDir = 
        when defined(windows): "bin/debug/windows" 
        else: 
            when defined(macosx): "bin/debug/osx"
            else: "bin/debug/other"
        
    exec "nimble build"

task release, "Build release":
   binDir = 
       when defined(windows): "bin/release/windows" 
       else: 
           when defined(macosx): "bin/release/osx" 
           else: "bin/release/other"