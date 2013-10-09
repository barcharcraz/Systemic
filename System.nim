
type 
    TSystem {.inheritable.} = object
    TTestSystem = object of TSystem


method process(s: TSystem) = 
