type EntityId* = distinct int
proc `==`*(a, b: EntityId): bool {.borrow.}
type TComponent*[T] = object
  id*: EntityId
  data*: T
proc initComponent*[T](id: EntityId; data: T): TComponent[T] =
  result.id = id
  result.data = data
proc genEntity*(): EntityId = 
  var id {.global.}: int = 0
  result = cast[EntityId](id)
  inc(id)