import opengl
import tables
import logging
## implements draw data objects which store all the state reuqired for
## issueing a draw call, these are designed to be simpler and less error prone than
## all the binding stuff usually required
type TDrawElementsIndirectCommand* = object
  count: uint32
  primCount: uint32
  firstIndex: uint32
  baseVertex: uint32
  baseInstance: uint32
type TDrawCommand* = object
  mode: GLenum
  idxType: GLenum
  command: TDrawElementsIndirectCommand
type TDrawObject* = object
  program: GLuint
  drawCommand: TDrawCommand
  VertexAttributes: GLuint
  uniforms: seq[GLuint] ## sequence of uniform blocks, index is uniform block binding
  textures: seq[tuple[typ: GLenum, id: GLuint]] ## sequence of textures index is texture unit
  opaqueTypes: seq[tuple[location: GLint, val: GLuint]] ## pairs of (location, value) for things to be bound to samplers

type TSamplerData = object
  location: GLuint
  typ: GLenum
type TProgramData = object
  uniformBlocks: TTable[string, GLuint]
  opaqueNames: TTable[string, TSamplerData]

type EIdentifierTooLong = object of ESynch
type EUnsupportedSamplerType = object of Esynch
proc initProgramData(): TProgramData =
  result.uniformBlocks = initTable()
  result.opaqueNames = initTable()

const SamplerTypes = {GL_SAMPLER_1D, GL_SAMPLER_2D, GL_SAMPLER_3D, GL_SAMPLER_CUBE, GL_SAMPLER_1D_SHADOW, GL_SAMPLER_2D_SHADOW}
proc findTexTypeOfSampler(program, sampler: GLuint): GLenum =
  var sampler = sampler
  var typ: GLint
  glGetActiveUniformsiv(program, 1, addr sampler, GL_UNIFORM_TYPE, addr typ)
  case typ
  of GL_SAMPLER_1D: return GL_TEXTURE_1D
  of GL_SAMPLER_2D: return GL_TEXTURE_2D
  of GL_SAMPLER_3D: return GL_TEXTURE_3D
  of GL_SAMPLER_CUBE: return GL_TEXTURE_CUBE_MAP
  of GL_SAMPLER_1D_SHADOW: return GL_TEXTURE_1D
  of GL_SAMPLER_2D_SHADOW: return GL_TEXTURE_2D
  else: raise newException(EUnsupportedSamplerType, "sampler type is not supported")
proc initProgramData(program: GLuint): TProgramData =
  var indices: GLuint
  var blockName: array[1..100, GLchar]
  var blockNameLength: GLsizei
  glGetProgramiv(program, GL_ACTIVE_UNIFORM_BLOCKS, addr indices)
  for i in 0..indices:
    glGetActiveUniformBlockName(program, i, len(blockName), addr blockNameLength, addr blockName[1])
    if blockNameLength >= len(blockName):
      raise newException(EIdentifierTooLong, "max GLSL uniform identifier length is 99 chars")
    result.uniformBlocks[$cast[cstring](blockName)] = i
    glUniformBlockBinding(program, i, i)
  glGetProgramiv(program, GL_ACTIVE_UNIFORMS, addr indices)
  for i in 0..indices:
    var blockIdx: GLint
    var uniformType: GLenum
    glGetActiveUniformsiv(program, 1, addr i, GL_UNIFORM_TYPE, addr uniformType)
    if uniformType in SamplerTypes:
      glActiveUniformBlockName(program, i, len(blockName), addr blockNameLength, addr blockName[1])
      if blockNameLength >= len(blockName):
        raise newException(EIdentifierTooLong, "max GLSL uniform name length is 99 chars")
      result.opaqueNames[$cast[cstring](blockName)].location = i
      result.opaqueNames[$cast[cstring](blockName)].typ = findTexTypeOfSampler(program, i)

proc initDrawElementsIndirectCommand*(): TDrawElementsIndirectCommand =
  result.count = 0
  result.primCount = 0
  result.firstIndex = 0
  result.baseVertex = 0
  result.baseIndex = 0
proc initDrawCommand*(): TDrawCommand =
  result.command = initDrawElementsIndirectCommand()
  result.idxType = cGL_UNSIGNED_INT
  result.mode = GL_TRIANGLES

var programinfo = initTable[GLuint, TProgramData]
proc initDrawObject*(program: GLuint): TDrawObject =
  if not programinfo.hasKey(program):
    programinfo[program] = initProgramData(program)
  result.program = program
  result.drawCommand = initDrawCommand()
  newSeq(result.uniforms, len(programinfo[program].uniformBlocks))
  newSeq(result.opaqueTypes, len(programinfo[program].opaqueNames))
  result.textures = @[]

proc SetUniformBuffer(self: var TDrawObject, name: string, val: GLuint) =
  var info = addr programinfo.mget(self.program)
  var binding = info.uniformBlocks.mget(name)
  self.uniforms[binding] = val
proc SetSamplerTexture(self: var TDrawObject, name: string, val: GLuint) =
  ## val is a texture handle, the assumption is that the texture has the correct type
  var info = addr programinfo.mget(self.program)
  var samplerInfo = info.OpaqueNames.mget(name)
  var newTex = (samplerInfo.typ, val)
  proc `==`(a,b: tuple[GLenum, GLuint]): bool = a[2] == b[2]
  var texIdx = find(self.textures, newTex)
  if texIdx == -1:
    self.textures.add(newTex)



proc BindDrawObject(obj: TDrawObject) =
  glUseProgram(obj.program)
  for i,elm in obj.uniforms:
    glBindBufferBase(GL_UNIFORM_BUFFER, i, elm)
  for i,elm in obj.textures:
    glActiveTexture(GL_TEXTURE0 + i)
    glBindTexture(elm.typ, elm.id)
  for elm in obj.opaqueTypes:
    glUniform1i(elm.location, elm.val)
proc DrawBundle*(bundle: TDrawObject) =
  BindDrawObject(bundle)
  glBindVertexArray(bundle.VertexAttributes)
  glDrawElementsIndirect(bundle.drawCommand.mode, 
                         bundle.drawCommand.idxType,
                         addr bundle.drawCommand.command)




