import logging
import scene
import exceptions
type EntityId* = distinct int
proc `==`*(a, b: EntityId): bool {.borrow.}
var EntityMapping: seq[SceneId] = @[]
proc clearEntMapping*() =
  EntityMapping = @[]
proc getScene*(ent: EntityId): SceneId =
  if EntityMapping.high < ent.int:
    raise newException(ENoScene, $(ent.int))
  result = EntityMapping[ent.int]
  if result == SceneId(-1):
    raise newException(ENoScene, $(ent.int))

proc add*(scene: SceneId; ent: EntityId) =
  #make sure that we have enough space in the entity mapping
  #if we do not than add more space and set all the new elements
  #to -1
  if EntityMapping.high < ent.int:
    var oldLen = EntityMapping.len
    EntityMapping.setLen(ent.int + 1)
    for elm in oldLen..EntityMapping.high:
      EntityMapping[elm] = SceneId(-1)
  var entscene = EntityMapping[ent.int]
  if entscene != SceneId(-1):
    #this means that the entity is already in a scene
    #now there is nothing preventing us from letting
    #an entity be in more than one scene but it would mean
    #another dimension in the EntityMapping
    raise newException(ESceneNotUnique, "Entity: " & $ent.int & " is already in scene " & $entscene.int)
  EntityMapping[ent.int] = scene
  
type TComponent*[T] = object
  id*: EntityId
  data*: T
proc initComponent*[T](id: EntityId; data: T): TComponent[T] =
  result.id = id
  result.data = data
var id: int = 0
proc genEntity*(): EntityId = 
  result = cast[EntityId](id)
  inc(id)
proc resetEntityGen*() =
  id = 0
proc getNumIds*(): int =
  result = id
