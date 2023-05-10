import ../tak/move
from ../tak/game import ZobristHash

let MaxProbeDepth: int = 5

type

    Bound = enum
        UpperBound, LowerBound, ExactBound  

    TranspositionTableEntry = object
        bound*: Bound
        evaluation*: Evaluation
        nodeCount*: uint32
        depth*: uint8
        plyCount: uint8
        move*: Move

    Slot = object
        hash: ZobristHash
        entry: TranspositionTableEntry

    TranspositionTable[N: static uint] = seq[Slot]