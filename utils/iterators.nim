template first*(iter: expr): expr {.immediate.} =
  proc impl(): auto =
    for elm in iter: return elm
  impl()
