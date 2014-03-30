import ecs/entity
import vecmath
type TVelocity* = object
  lin*: TVec3f
  rot*: TQuatf
type TPremulVelocity* = distinct TVelocity
type TTransform* = object
  position*: TVec3f
  rotation*: TQuatf
type TAcceleration* = object
  lin*: TVec3f
  rot*: TVec3f
type TOrbit* = object
  around*: EntityId
  vel*: float
proc initVelocity*(): TVelocity =
  result.rot = identityQuatf()
  result.lin.data = [0.0'f32, 0.0'f32, 0.0'f32]
proc initVelocity*(rot: TQuatf): TVelocity =
  result.rot = rot
  result.lin.data = [0.0'f32, 0.0'f32, 0.0'f32]
proc initAcceleration*(): TAcceleration =
  result.lin = initVec3f(0,0,0)
  result.rot = identityQuatf()
proc initTransform*(): TTransform =
  result.position.data = [0.0'f32, 0.0'f32, 0.0'f32]
  result.rotation = [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32].TQuatf
proc initTransform*(pos: TVec3f): TTransform =
  result.position = pos
  result.rotation = [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32].TQuatf
proc GenMatrix*(trans: TTransform): TMat4f =
  var rotMtx = toAffine(trans.rotation.toRotMatrix())
  var transMtx = trans.position.toTranslationMatrix()
  result = mul(transMtx, rotMtx)
proc GenRotTransMatrix*(trans: TTransform): TMat4f =
  var rotMtx = toAffine(trans.rotation.toRotMatrix())
  var transMtx = trans.position.toTranslationMatrix()
  result = mul(rotMtx, transMtx)
