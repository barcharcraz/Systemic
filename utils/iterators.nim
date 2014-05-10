template first*(iter: expr): expr {.immediate.} =
  proc impl(): auto =
    for elm in iter: return elm
  impl()
proc head*(item: tuple): auto =
  return item[0]

