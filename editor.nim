import os
import prefabs
import ecs
import vecmath
import widgets

type CAssetContainer = generic x
  add(x, string, proc())
static: echo((ref TListBox) is CAssetContainer)
proc populateAssets*(cont: ref TListBox, folder: string, pattern: string) =
  for file in walkFiles(folder / pattern):
    var filev = file
    echo file
    cont.add(file) do:
      activeScene().addStaticMesh(filev, folder / "diffuse.tga", vec3f(0,0,0))
      