import typetraits
import tables
export typetraits
var numComponents : int = 0
var componentDecls* : TTable[string, int] = initTable[string,int](64)
type TComponent* = object of TObject

proc GenComponent*(T: typedesc): int =
    if componentDecls.hasKey(name(T)):
        result = componentDecls[name(T)]
    else:
        componentDecls.add(name(T), numComponents)
        result = numComponents
        inc numcomponents
proc GetType*(T: typedesc): int = 
    result = GenComponent(T)
when isMainModule:
    type TTest = tuple[name:string, count:int]
    var test = GenComponent(TTest)
    var test2 = GenComponent(TTest)
    var test3 = GenComponent(int)
    echo("Component  ID is: ", test)
    echo("Component2 ID is: ", test2)
    echo("Component3 ID is: ", test3)
