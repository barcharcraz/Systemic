from logging import nil

template loggingWrapper*(def: expr) =
  template debug(frmt: string, args: varargs[string, `$`]) =
    when defined def:
      logging.debug(frmt, args)

