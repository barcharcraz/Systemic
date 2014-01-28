import macros

macro test(s: stmt): stmt =
  result = quote do:
    discard

test:
  proc addNums(x: int, y:int): int = x + y
