# main package

version = "0.0.1"
author = "Noah Fields (nqeron)"
description = "DitakticBot"
license = "MIT"

srcDir = "src"
binDir = when defined(windows): "bin/windows" else: when defined(macosx): "bin/osx" else: "bin/other"
bin = @["main"]

skipExt = @["nim"]

requires "nim >= 1.6.10"

task debug, "Build debug":
    exec "nimble build"

task release, "Build release":
    exec "nimble build -d:release"
