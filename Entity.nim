import tables
import Component
type TEntity = object
    data: TTable[int,ref TComponent]
proc get[A](e: TEntity): A
proc initEntity(): TEntity =
    result.data = initTable[int, ref TComponent](64)
proc `[]`(e:TEntity, T: typedesc): ref T =
    result = get[T](e)
proc addComponent[A](e:var TEntity, comp:A) =
    let typeidx = GetType(A)
    echo typeidx
    e[typeidx] = comp
proc getOptional[A](e: TEntity) : A =
    result = nil
    let typeid = GetType(A)
    if e.data.hasKey(typeid):
        result = cast[A](e[typeid])

proc get[A](e: TEntity) : A =
    result = getOptional[A](e)
    if result != nil:
        return
    raise newException(EInvalidIndex, "component is not valid")

proc hasComponent[A](e: TEntity) : bool =
    var elm = get[A](e)
    if elm == nil:
        return false
    else:
        return true

when isMainModule:
    type TTestComp = object of TComponent
        name:string
        count:int
    var TestComp : ref TTestComp
    new(TestComp)
    TestComp.name = "test"
    TestComp.count = 4
    var TestEnt : TEntity
    let tidx = GenComponent(ref TTestComp)
    TestEnt.addComponent(TestComp)
    echo("Test type is: ", tidx)
    if get[ref TTestComp](TestEnt).name == "test":
        echo("SUCCESS: name is test")


