import vecmath
type TVelocity* = object
  lin*: TVec3f
  rot*: TQuatf
type TTransform* = object
  position*: TVec3f
  rotation*: TQuatf

proc initVelocity*(): TVelocity =
  result.rot = identityQuatf()
  result.lin = [0.0'f32, 0.0'f32, 0.0'f32]
proc initVelocity*(rot: TQuatf): TVelocity =
  result.rot = rot
  result.lin = [0.0'f32, 0.0'f32, 0.0'f32]

proc initTransform*(): TTransform =
  result.position = [0.0'f32, 0.0'f32, 0.0'f32]
  result.rotation = [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32]
proc initTransform*(pos: TVec3f): TTransform =
  result.position = pos
  result.rotation = [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32]
proc GenMatrix*(trans: TTransform): TMat4f =
  var rotMtx = toAffine(trans.rotation.toRotMatrix())
  var transMtx = trans.position.toTranslationMatrix()
  result = mul(transMtx, rotMtx)
proc GenRotTransMatrix*(trans: TTransform): TMat4f =
  var rotMtx = toAffine(trans.rotation.toRotMatrix())
  var transMtx = trans.position.toTranslationMatrix()
  result = mul(rotMtx, transMtx)
