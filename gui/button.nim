import cairo
import vecmath
import colors
type TButton = object
  pos: TVec2f
  size: TVec2f
  color: TColor
proc drawButtons*(ctx: PContext, btns: openarray[TButton]) {.procvar.} =
  using ctx
  for elm in btns:
    var (r,b,g) = extractRGB(elm.color)
    set_source_rgb(r.float / 255.0,b.float / 255.0,g.float / 255.0)
    rectangle(elm.pos.x, elm.pos.y, elm.size.x, elm.size.y)
    fill()