import assimp
import components.mesh as cmesh
import exceptions
import vecmath
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
    
