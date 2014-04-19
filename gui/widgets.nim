import vecmath
import colors
import cairo
type TWidget = object of TObject
type TButton* = object of TWidget
  pos*: TVec2f
  size*: TVec2f
  label*: string
  color: TColor
  ucolor: TColor
  acolor: TColor
type TLabel* = object of TWidget
  pos*: TVec2f
  text*: string
type TListBox* = object of TWidget
  pos*: TVec2f
  size*: TVec2f
  color*: TColor
  items: seq[ref TWidget]

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

method draw*(ctx: PContext, btn: ref TButton) =
  using ctx
  var (r,g,b) = extractRGB(btn.color)
  set_source_rgb(r.float / 255.0, g.float / 255.0, b.float / 255.0)
  rectangle(btn.pos.x, btn.pos.y, elm.size.x, elm.size.y)
  fill()

method draw*(ctx: PContext, lbl: ref TLabel) =
  using ctx
  save()
  move_to(lbl.pos.x, lbl.pos.y)
  select_font_face("monospace", FONT_SLANG_NORMAL, FONT_WEIGHT_NORMAL)
  set_font_size(12)
  set_source_rgb(0,0,0)
  show_text(lbl.text)
  restore()

method draw*(ctx: PContext, lb: ref TListBox) =
  using ctx
  save()
  var (r,g,b) = extractRGB(lb.color)
  set_source_rgb(r.float/255.0, g.float/255.0, b.float/255.0)
  rectangle(lb.pos.x, lb.pos.y, lb.size.x, lb.size.y)
  fill()
  restore()
