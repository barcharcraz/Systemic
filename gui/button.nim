import cairo
import vecmath
import colors
import input
import text
type TButton* = object of TObject
  pos*: TVec2f
  size*: TVec2f
  label*: string
  color: TColor
  ucolor: TColor
  acolor: TColor
proc initButton*(pos: TVec2f): TButton =
  result.pos = pos
  result.size = vec2f(100, 50)
  result.label = ""
  # snazzy!
  result.ucolor = colAqua ##un-active color
  result.acolor = colDarkMagenta ##active-color
  result.color = result.ucolor
proc initButton*(pos: TVec2f, name: string): TButton =
  result = initButton(pos)
  result.label = name
proc doButtonCollision*(mouse: TMouse; btns: var openarray[ref TButton]) {.procvar.} =
  for i,elm in btns.pairs:
    if mouse.x > elm.pos.x and mouse.x < elm.pos.x+elm.size.x and
       mouse.y > elm.pos.y and mouse.y < elm.pos.y+elm.size.y:

      btns[i].color = elm.acolor
    else:
      btns[i].color = elm.ucolor
proc drawButtons*(ctx: PContext, btns: openarray[ref TButton]) {.procvar.} =
  using ctx
  for elm in btns:
    var (r,g,b) = extractRGB(elm.color)
    set_source_rgb(r.float / 255.0,g.float / 255.0,b.float / 255.0)
    rectangle(elm.pos.x, elm.pos.y, elm.size.x, elm.size.y)
    fill()
    drawLabel(ctx, elm, elm.label)
