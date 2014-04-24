import vecmath
import colors
import cairo
import input
type 
  TWidget* = object of TObject
    pos*: TVec2f
    size*: TVec2f
  TLabel* = object of TWidget
    text*: string
  TButton* = object of TWidget
    label*: ref TLabel
    color*: TColor
    ucolor*: TColor
    acolor*: TColor
    onClick*: proc(btn: ref TButton)

  TListBox* = object of TWidget
    color*: TColor
    items*: seq[ref TWidget]


#{{{ forward declearations
#{{{ initialization functions
proc initButton*(pos: TVec2f): TButton
proc initButton*(pos: TVec2f, name: string): TButton
proc initListBox*(pos: TVec2f = vec2f(0,0),
                  size: TVec2f = vec2f(100,100),
                  color: TColor = colDarkRed): TListBox
#}}}
#{{{ list layout
proc layoutList(elms: var seq[ref TWidget], anchor: ref TWidget)
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
proc initListBox*(pos,size: TVec2f, color: TColor): TListBox =
  result.pos = pos
  result.size = size
  result.color = color
  result.items = @[]
proc add*(self: ref TListBox, elm: ref TWidget) = 
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
  for elm in lb.items: draw(ctx, elm)
  restore()

#{{{ ------ update functions
method onMouseMove*(self: ref TWidget, mouse: TMouse) = discard
method onMouseEnter*(self: ref TWidget, mouse: TMouse) = discard
method onMouseLeave*(self: ref TWidget, mouse: TMouse) = discard
method onMouseButton*(self: ref TWidget, mouse: TMouse) = discard
proc checkOverlap(self: ref TWidget, point: TVec2f): bool =
  if point.x > self.pos.x and point.x < self.pos.x+self.size.x and
     point.y > self.pos.y and point.y < self.pos.y+self.size.y:
    result = true
  else:
    result = false
proc checkOverlap(self: ref TWidget, mouse: TMouse): bool =
  result = checkOverlap(self, vec2f(mouse.x, mouse.y))
method handleInput*(self: ref TWidget, inp: TInput, last: TInput) =
  if checkOverlap(self, inp.mouse):
    echo "overlap"
    if not checkOverlap(self, last.mouse):
      self.onMouseEnter(inp.mouse)
      echo "mouse enter"
    self.onMouseMove(inp.mouse)
    if mbNone notin inp.mouse.buttons:
      self.onMouseButton(inp.mouse)
  else:
    if checkOverlap(self, last.mouse):
      self.onMouseLeave(inp.mouse)
method handleInput(self: ref TListBox, inp: TInput, last: TInput) =
  for elm in self.items:
    elm.handleInput(inp, last)
proc handleAllInput*(group: seq[ref TWidget], inp: TInput) =
  var last {.global.}: TInput
  for elm in group:
    handleInput(elm, inp, last)
  last = inp

method onMouseEnter*(self: ref TButton, mouse: TMouse) =
  self.color = self.acolor
method onMouseLeave*(self: ref TButton, mouse: TMouse) =
  self.color = self.ucolor
method onMouseButton*(self: ref TButton, mouse: TMouse) =
  if self.onCLick != nil:
    self.onClick(self)
#}}}

#{{{ layout functions for lists


proc layoutList(elms: var seq[ref TWidget], anchor: ref TWidget) =
  var ystep = anchor.size.y / elms.len.float
  for i,elm in elms.pairs():
    elm.size.x = anchor.size.x
    elm.size.y = ystep
    elm.pos.x = anchor.pos.x
    elm.pos.y = anchor.pos.y + (i.float * ystep)

#}}}