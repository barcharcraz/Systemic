import macros
proc genGlProcDef(s: PNimrodNode): string =
  var rv = ""
  var params: seq[string]
  var paramNames: seq[string]
  expectKind(s, {nnkProcDef})
  var name = $s
  var paramNodes = "foo"
  rv = $paramNodes
  #result = rv & " " & name & "()" & "{"
  result = ""

macro testGen(s: stmt): expr =
  var shader: string = ""
  for i in s.children:
    if(i.kind == nnkProcDef):
      shader = shader & "foo"
  result = newStrLitNode(shader)

dumpTree:
  proc testBasicOps(verts: openarray[int]): int =
    for i in verts.items:
      result = result + i
dumpTree:
  const test = "foo"
const
  str = testGen do:
          proc testGenFunc(c: int):int =
            result = c + c
echo str
