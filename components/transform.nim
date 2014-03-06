import vecmath

type TTransform = object
  position: TVec3f
  rotation: TQuatf

proc GenMatrix(trans: TTransform): TMat4f =
  var rotMtx = trans.rotation.toRotMatrix().toAffine()
  var transMtx = trans.position.toTranslationMatrix().toAffine()
  result = mul(transMtx * rotMtx)
proc GenRotTransMatrix(trans: TTransform): TMat4f =
  var rotMtx = trans.rotation.toRotMatrix().toAffine()
  var transMtx = trans.position.toTranslationMatrix().toAffine()
  result = mul(rotMtx * transMtx)
