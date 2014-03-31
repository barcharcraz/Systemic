import math
proc pow*(base: int, exp: int): int =
  result = pow(base.float, exp.float).int