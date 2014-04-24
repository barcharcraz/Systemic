import vecmath
import colors
import cairo
type 
  TWidget* = object of TObject
  TLabel* = object of TWidget
    pos*: TVec2f
    text*: string
  TButton* = object of TWidget
    pos*: TVec2f
    size*: TVec2f
    label*: ref TLabel
    color*: TColor
    ucolor*: TColor
    acolor*: TColor

  TListBox* = object of TWidget
    pos*: TVec2f
    size*: TVec2f
    color*: TColor
    items*: seq[TMovable]


#{{{ forward declearations
#{{{ initialization functions
proc initButton*(pos: TVec2f): TButton
proc initButton*(pos: TVec2f, name: string): TButton
proc initListBox*(pos,size: TVec2f, color: TColor): TListBox
#}}}
#{{{ list layout
proc layoutList(elms: var seq[ref TWidget], anchor: CMovable)
#}}}


#}}}

proc initButton*(pos: TVec2f): TButton =
  result.pos = pos
  result.size = vec2f(100, 50)
  new(result.label)
  result.label.text = ""
  result.label.pos = vec2f(0,0)
  # snazzy!
  result.ucolor = colAqua ##un-active color
  result.acolor = colDarkMagenta ##active-color
  result.color = result.ucolor
proc initButton*(pos: TVec2f, name: string): TButton =
  result = initButton(pos)
  new(result.label)
  result.label.pos = vec2f(0,0)
  result.label.text = ""

#-------- LIST BOX NONVIRTUAL
proc initListBox*(pos: TVec2f = vec2f(0,0),
                  size: TVec2f = vec2f(100,100),
                  color: TColor = colDarkRed): TListBox =
  result.pos = pos
  result.size = size
  result.color = color
  result.items = @[]
proc add*(self: ref TListBox, elm: TMovable) = 
  self.items.add(elm)
  layoutList(self.items, self)

#-------- END LIST BOX NONVIRTUAL
method draw*(ctx: PContext, elm: ref TWidget) =
  quit("need to override draw")
method draw*(ctx: PContext, btn: ref TButton) =
  using ctx
  var (r,g,b) = extractRGB(btn.color)
  set_source_rgb(r.float / 255.0, g.float / 255.0, b.float / 255.0)
  rectangle(btn.pos.x, btn.pos.y, btn.size.x, btn.size.y)
  draw(ctx, btn.label)
  fill()

method draw*(ctx: PContext, lbl: ref TLabel) =
  using ctx
  save()
  move_to(lbl.pos.x, lbl.pos.y)
  select_font_face("monospace", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
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
  translate(lb.pos.x, lb.pos.y)
  for elm in lb.items: draw(ctx, elm)
  restore()


#{{{ layout functions for lists


proc layoutList(elms: var seq[ref TWidget], anchor: CMovable) =
  var ystep = anchor.size.y / elms.len
  for i,elm in elms.pairs():
    elm.size.x = anchor.size.x
    elm.size.y = ystep
    elm.pos.x = anchor.pos.x
    elm.pos.y = anchor.pos.y + (i * ystep)

#}}}