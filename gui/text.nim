import layout
import vecmath
import cairo
proc drawLabel*(ctx: PContext, elm: CLayoutElm, text: string) =
  save(ctx)
  move_to(ctx, elm.pos.x, elm.pos.y)
  rel_move_to(ctx, elm.size.x / 4.0, elm.size.y / 4.0)
  select_font_face(ctx, "monospace", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
  set_font_size(ctx, 12)
  set_source_rgb(ctx,0,0,0)
  show_text(ctx, text)
  restore(ctx)
