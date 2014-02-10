type Zero = object
type Succ[T] = object
proc getVal[Z: Zero | Succ](): int = 
  when Z is Zero:
    result = 0
  elif Z is Succ:
    result = getVal[Z.T]() + 1
when isMainModule:
  echo getVal[Succ[Zero]]
discard """
type
  Matrix[M: static[int],N: static[int], T] = array[0..(M*N - 1), T]
    # Note how `Number` is just a type constraint here, while
    # `static[int]` requires us to supply a compile-time int value
  
"""
discard """
this is the AST for the type section
StmtList
  TypeSection
    TypeDef
      Ident !"Matrix"
      GenericParams
        IdentDefs
          Ident !"M"
          StaticTy
            Ident !"int"
          Empty
        IdentDefs
          Ident !"N"
          StaticTy
            Ident !"int"
          Empty
        IdentDefs
          Ident !"T"
          Empty
          Empty
      BracketExpr
        Ident !"array"
        Infix
          Ident !".."
          IntLit 0
          Par
            Infix
              Ident !"-"
              Infix
                Ident !"*"
                Ident !"M"
                Ident !"N"
              IntLit 1
        Ident !"T"

"""