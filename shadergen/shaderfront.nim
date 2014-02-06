import macros
dumpTree:
  proc testBasicOps(verts: openarray[int]): int =
    for i in verts.items:
      result = result + i
proc genVarDecleration(typename: string, name: string): string = 
  return typename & name
proc genArgList(typenames: seq[string], names: seq[string]): string =
  result = ""
  for t in typenames.pairs:
    result = result & t.val & " " & names[t.key] & " "
proc genGlProcDef(s: PNimrodNode): string {.compileTime.} =
  var params: seq[string]
  var paramNames: seq[string]
  expectKind(s, {nnkProcDef})
  for param in s.params.findChild((it.kind == nnkIdentDefs)).children:
    if param.kind != nnkEmpty:
      params.add($param)
      paramNames.add($param)
  var rv = $s.params
  var name = $s.name
  var paramNodes = "foo"
  #rv = $paramNodes
  result = (rv & " " & name & "()" & " {")

macro testGen(s: stmt): expr =
  var shader: string = ""
  for i in s.children:
    if(i.kind == nnkProcDef):
      shader = shader & genGlProcDef(i)
  result = newStrLitNode(shader)


dumpTree:
  const test = "foo"

proc testGenFunc(c: int):int {.testGen.} = 
  result = c + c
echo str
