import vecmath

type TTransform* = object
  position*: TVec3f
  rotation*: TQuatf

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
