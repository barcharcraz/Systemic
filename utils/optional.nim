type EInvalidOptional = object of ESynch
type TOptional[T] = object
  data: T
  valid: bool