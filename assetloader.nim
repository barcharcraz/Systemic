import assimp
import freeimage
import components.mesh as cmesh
import components.image
import exceptions
import vecmath
import os
import strutils
import tables
import logging
proc loadMesh*(filename: string): cmesh.TMesh =
  var scene = aiImportFile(filename.cstring, 0)
  if scene.meshCount == 0:
    aiReleaseImport(scene)
    raise newException(ENoMesh, filename & " has no meshes")
  newSeq(result.verts, scene.meshes.vertexCount)
  #we assume triangles FIXME: stop doing this
  newSeq(result.indices, scene.meshes.faceCount * 3)
  var verts = cast[ptr array[0..50000, TVec3f]](scene[].meshes[][].vertices)
  var norms = cast[ptr array[0..50000, TVec3f]](scene[].meshes[][].normals)
  var tex = cast[ptr array[0..50000, TVec3f]](scene[].meshes[][].texCoords[0])
  for i in 0..scene[].meshes[][].vertexCount-1:
    result.verts[i].pos = verts[i]
    result.verts[i].norm = norms[i]
    result.verts[i].uv[0] = tex[i][0].float32
    result.verts[i].uv[1] = tex[i][1].float32
  var faces = cast[ptr array[0..50000, TFace]](scene[].meshes[][].faces)
  for i in 0..scene.meshes[].faceCount-1:
    var findex = cast[ptr array[0..50000, cint]](faces[i].indices)
    result.indices[i*3] = findex[0].uint32
    result.indices[i*3 + 1] = findex[1].uint32
    result.indices[i*3 + 2] = findex[2].uint32
  aiReleaseImport(scene)
    
FreeImage_Initialise(0)
addQuitProc do {.noconv.}:
  FreeImage_DeInitialise()
var textureCache = initTable[string, ptr FIBITMAP]()
proc loadTexture*(filename: string) =
  if textureCache.hasKey(filename):
    warn(filename & " is already in the texture cache")
  var imageType = FreeImage_GetFileType(filename, 0)
  if imageType == FIF_UNKNOWN:
    raise newException(EUnsupportedFormat, "format of " & filename & " is not supported")
  var image = FreeImage_Load(imageType, filename, 0)
  var image32 = FreeImage_ConvertTo32Bits(image)
  FreeImage_Unload(image)
  textureCache.add(filename, image32)
proc unloadTexture*(filename: string) =
  if not textureCache.hasKey(filename):
    warn("tried to unload " & filename & " which is not in the texture cache")
  var image = textureCache[filename]
  FreeImage_Unload(image)
  textureCache.del(filename)
proc getTexture*(filename: string): TImage =
  if not textureCache.hasKey(filename):
    info("loading " & filename)
    loadTexture(filename)
  var image = textureCache[filename]
  result.width = FreeImage_GetWidth(image).int
  result.height = FreeImage_GetHeight(image).int
  result.bpp = FreeImage_GetBPP(image).int
  result.data = FreeImage_GetBits(image)