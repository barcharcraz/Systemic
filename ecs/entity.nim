type EntityId* = distinct int
proc `==`*(a, b: EntityId): bool {.borrow.}
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
proc getNumIds*() int =
  result = id