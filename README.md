# DitakticBot #

![](https://img.shields.io/github/license/nqeron/DitakticBot) ![](https://img.shields.io/github/workflow/status/nqeron/DitakticBot/Actions)


## THIS IS A WORK IN PROGRESSS ##

The aim of this work is to create an AI play tak with the following features:
 
 - Can be customized to allow friendly undos, similar to friendlyBot.
 - tei
 - can analyze tps or PTN
 - handles variable komi (NOTE: this is experimental)
 - supports no-swap (experimental)
 - multiple levels of difficulty
    - probably from a) time, b) depth, c) heuristic specifics
 - can respond to and set specific game settings in playtak, such as color, size, komi, no-swap, difficulty

 ### TO USE ###

 ### Install ###

 I recommend installing Nim using choosenim here: https://github.com/dom96/choosenim

 Note that nim is flagged by many antivirus softwares, so you may have to override that

Eventually I would like to distribute exe and sh files so that installing nim is not needed.

### Running ####

`nimble run`
runs the main program
This will probably do better handling of user input soon

If you want to customize your game, run `nimble debug` followed by running the exe/sh with parameters for size, komi, swap, starting tps

### Progress ##

tei is working

playtak connection is mostly there

2 eval functions and a levelling system has been implemented.

## On Tap ##

- basic ai support:
    - movegen implementation
- github workflows
- symmetries?
- testing?
