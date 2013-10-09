import sets
import tables
proc subsetof[A](lhs: TSet[A]; rhs: TSet[A]) : bool = 
    result = true
    for elm in lhs.items:
        if not rhs.contains(elm):
            result = false
            return


proc SubsetOfKeys[A,B](lhs: TSet[A]; rhs: TTable[A,B]) : bool = 
    result = true
    for elm in lhs.items:
        if not rhs.hasKey(elm):
            result = false
            return

when isMainModule:
    
    #do some tests
    var testS = toSet([1,2,3,4,5]);
    if toSet([1,2,3]).subsetof(testS):
        echo("SUCCESS: subset")
    if not toSet([9,8]).subsetof(testS):
        echo("SUCCESS: not subset")
    
    echo("======== MAP TESTS==========")

    var testM = toTable([(1,"foo"), (2,"bar"), (3,"baz")])
    if toSet([1,2]).subsetofkeys(testM):
        echo("SUCCESS: submap")
