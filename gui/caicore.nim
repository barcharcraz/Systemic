import opengl
import cairo
import exceptions
import components/image
type TCairoUI = object
  surf: PSurface
  ctx: PContext

proc initCairoUI*(w,h: int): TCairoUI = 
  result.surf = image_surface_create(FORMAT_ARGB32, w, h)
  result.ctx = create(result.surf)
proc destroyCairoUI*(self: var TCairoUI) {.destructor.} =
  surface_destroy(self.surf)
  destroy(self.ctx)

proc createCairoImageComp(c: PSurface): TImage =
  result.width = get_width(c)
  result.height = get_height(c)
  var fmt = get_format(c)
  case fmt
  of FORMAT_ARGB32: result.bpp = 32
  of FORMAT_RGB24: result.bpp = 24
  else: raise newException(EUnsupportedFormat, "")
  result.data = cast[pointer](get_data(c))


