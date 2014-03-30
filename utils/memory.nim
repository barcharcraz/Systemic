type TAutoPtr*[T] = object
  ## dumb version of c++'s unique_ptr,
  ## we do not have `=` overloading yet
  ## so I can not make a real unique_ptr
  p: ptr T

newAutoPtr*[T](elm: ptr T):
