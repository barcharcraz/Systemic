import cairo
import vecmath
import colors
import layout
type TListBox* = object of TObject
  pos: TVec2f
  size: TVec2f
  color: TColor
  items: seq[TLayoutElm]

proc initListBox*(pos: TVec2f, size: TVec2f, color: TColor = colDarkRed): TListBox =
  result = TListBox(pos: pos, size: size, color: color, items: @[])


proc updateListBox*(box: TListBox) =
  var curPos = box.pos
  curPos.x = curPos.x + 2.0'f32
  curPos.y = curPos.y + 2.0'f32
  for i,elm in box.items.pairs:
    box.items[i].pos() = curPos
    curPos[2] = curPos[2] + elm.size().y
proc drawListBox*(ctx: PContext, box: TListBox) =
  save(ctx)
  var (r,g,b) = extractRGB(box.color)
  ctx.set_source_rgb(r.float / 255.0, g.float / 255.0, b.float / 255.0)
  ctx.rectangle(box.pos.x, box.pos.y, box.size.x, box.size.y)
  ctx.fill
  restore(ctx)

proc UpdateListBoxes*(lists: openarray[TListBox]) {.procvar.} =
  for elm in lists: updateListBox(elm)
proc drawListBoxes*(ctx: PContext, lists: openarray[TListBox]) {.procvar.} =
  for elm in lists: drawListBox(ctx, elm)
