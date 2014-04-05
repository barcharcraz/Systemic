import components
import ecs

proc makeStaticMesh*(model, texture: string, pos: TVec3f): EntityId =
  result = genEntity()
  
