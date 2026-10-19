extends RefCounted

## The menus' pixel-art look, in one place: the font, the chunky framed
## buttons and panels, and Pile Up's bricks redrawn as pixel art. Every menu
## screen calls apply() on its root at the end of _ready(), and TowerCup
## borrows font() and frame() for the rows it draws itself.
##
## Static functions and no static vars: a script's statics outlive the
## headless leak check in 4.7 (docs/PROJECT_STATE.md §12), so nothing here is
## cached. Building the theme is a handful of 21px images per scene change.
##
## Everything is on one grid: an art pixel is PIX screen pixels. Press Start
## 2P is drawn on an 8-pixel em, so its 24px size is exactly that grid too,
## and 16px (two screen pixels per font pixel) is the body size. Sizes that
## are not multiples of 8 render with uneven pixels; keep to 8/16/24/32/48.
##
## The font is Press Start 2P (fonts/PressStart2P-Regular.ttf), by CodeMan38,
## under the SIL Open Font License 1.1 — its licence is committed beside it.

const FONT_PATH := "res://fonts/PressStart2P-Regular.ttf"
const PIX := 3

const BG := Color(0.078, 0.086, 0.165, 1.0) # the menus' navy, unchanged
const INK := Color(0.02, 0.02, 0.05, 1.0) # every outline
const TEXT := Color(1.0, 1.0, 1.0, 0.96)
const DIM := Color(0.78, 0.82, 1.0, 0.72)
const SHADOW := Color(0.0, 0.0, 0.0, 0.8)
# A resting button: a slab of night with a lit top edge.
const FACE := Color(0.17, 0.19, 0.36, 1.0)
const FACE_LIGHT := Color(0.33, 0.37, 0.62, 1.0)
const FACE_SHADE := Color(0.09, 0.10, 0.21, 1.0)
# The focused one is the O brick's yellow, with dark text on it — the one
# thing on a screen that has to be found at a glance.
const HOT := Color(1.0, 0.86, 0.16, 1.0)
const HOT_LIGHT := Color(1.0, 0.96, 0.62, 1.0)
const HOT_SHADE := Color(0.82, 0.52, 0.04, 1.0)
const HOT_TEXT := Color(0.10, 0.07, 0.12, 1.0)
const PANEL := Color(0.11, 0.12, 0.24, 0.92)

static func font() -> Font:
	return load(FONT_PATH)

# A framed box as a nine-slice: a 7x7 art-pixel tile with notched corners —
# outline, a one-pixel bevel lit from the top left, then the face.
static func frame(face: Color, light: Color, shade: Color, ink: Color = INK) -> StyleBoxTexture:
	var n := 7
	var img := Image.create(n * PIX, n * PIX, false, Image.FORMAT_RGBA8)
	for y in range(n):
		for x in range(n):
			var ex: bool = x == 0 or x == n - 1
			var ey: bool = y == 0 or y == n - 1
			var ix: bool = x == 1 or x == n - 2
			var iy: bool = y == 1 or y == n - 2
			var c: Color = face
			if ex and ey:
				c = Color(0, 0, 0, 0)
			elif ex or ey or (ix and iy):
				c = ink
			elif x == 1 or y == 1:
				c = light
			elif x == n - 2 or y == n - 2:
				c = shade
			img.fill_rect(Rect2i(x * PIX, y * PIX, PIX, PIX), c)
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(img)
	box.set_texture_margin_all(3 * PIX)
	box.content_margin_left = 5 * PIX
	box.content_margin_right = 5 * PIX
	box.content_margin_top = 3 * PIX
	box.content_margin_bottom = 3 * PIX
	return box

static func button_frame() -> StyleBoxTexture:
	return frame(FACE, FACE_LIGHT, FACE_SHADE)

static func hot_frame() -> StyleBoxTexture:
	return frame(HOT, HOT_LIGHT, HOT_SHADE)

# A panel, optionally ringed in a colour (a ready player's own).
static func panel_frame(accent: Color = Color(0, 0, 0, 0)) -> StyleBoxTexture:
	if accent.a <= 0.0:
		return frame(PANEL, FACE_LIGHT, FACE_SHADE)
	return frame(PANEL, accent.lightened(0.25), accent.darkened(0.35), accent.darkened(0.7))

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 16

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", SHADOW)
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)

	t.set_font_size("font_size", "Button", 24)
	t.set_stylebox("normal", "Button", button_frame())
	t.set_stylebox("disabled", "Button", button_frame())
	# Hover looks like focus, and apply() makes hovering take focus, so the
	# mouse and the keyboard never disagree about which button is lit. (The
	# font colour of a hovered button is font_hover_color even when it has
	# focus, so the two have to match anyway.)
	t.set_stylebox("hover", "Button", hot_frame())
	t.set_stylebox("focus", "Button", hot_frame())
	t.set_stylebox("pressed", "Button", frame(HOT_SHADE, HOT_SHADE.darkened(0.2), HOT))
	t.set_stylebox("hover_pressed", "Button", frame(HOT_SHADE, HOT_SHADE.darkened(0.2), HOT))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", HOT_TEXT)
	t.set_color("font_focus_color", "Button", HOT_TEXT)
	t.set_color("font_pressed_color", "Button", HOT_TEXT)
	t.set_color("font_hover_pressed_color", "Button", HOT_TEXT)

	t.set_stylebox("panel", "PanelContainer", panel_frame())
	return t

# Give a menu screen the look. Call after its buttons exist.
static func apply(root: Control) -> void:
	root.theme = make_theme()
	# Inherited by every child: the nine-slice seams and the brick textures
	# must not be smoothed, or the pixels go soft at every edge.
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for b: Button in root.find_children("*", "Button", true, false):
		b.mouse_entered.connect(b.grab_focus)

# --- Bricks as pixel art ----------------------------------------------------------

# The colour of one of GameSettings.BRICKS, read off its own sprite at the
# centre of its first cell, so the menus' bricks are the bricks' colours.
static func brick_color(brick: Dictionary) -> Color:
	var img: Image = (brick["texture"] as Texture2D).get_image()
	var box: Rect2 = brick["boxes"][0]
	var cw: float = float(img.get_width()) / float(brick["cols"])
	var ch: float = float(img.get_height()) / float(brick["rows"])
	return img.get_pixel(int((box.position.x + 0.5) * cw), int((box.position.y + 0.5) * ch))

# A brick's cells as rows of bools, from its BRICKS boxes, turned `quarter`
# quarter-turns clockwise.
static func brick_cells(brick: Dictionary, quarter: int = 0) -> Array:
	var rows: int = brick["rows"]
	var cols: int = brick["cols"]
	var occ: Array = []
	for r in range(rows):
		var line: Array = []
		line.resize(cols)
		line.fill(false)
		occ.append(line)
	for box: Rect2 in brick["boxes"]:
		for r in range(int(box.position.y), int(box.end.y)):
			for c in range(int(box.position.x), int(box.end.x)):
				occ[r][c] = true
	for _q in range(posmod(quarter, 4)):
		occ = _turn(occ)
	return occ

static func _turn(occ: Array) -> Array:
	var rows: int = occ.size()
	var cols: int = (occ[0] as Array).size()
	var out: Array = []
	for r in range(cols):
		var line: Array = []
		for c in range(rows):
			line.append(occ[rows - 1 - c][r])
		out.append(line)
	return out

# Cells from strings, '#' for a filled one — the title's letters.
static func cells_from_rows(rows: PackedStringArray) -> Array:
	var occ: Array = []
	for s in rows:
		var line: Array = []
		for ch in s:
			line.append(ch == "#")
		occ.append(line)
	return occ

# Any set of cells drawn the way the Pile Up sprites are: one merged shape,
# no lines between its cells, a dark outline round the outside — plus the
# pixel-art bevel, lit from the top left. `cell` art pixels per cell; the
# texture is at art resolution, so draw it PIX times bigger with nearest
# filtering.
static func cells_texture(occ: Array, color: Color, cell: int) -> ImageTexture:
	var rows: int = occ.size()
	var cols: int = (occ[0] as Array).size()
	var img := Image.create(cols * cell, rows * cell, false, Image.FORMAT_RGBA8)
	var light: Color = color.lightened(0.4)
	var shade: Color = color.darkened(0.32)
	var on := func(r: int, c: int) -> bool:
		return r >= 0 and c >= 0 and r < rows and c < cols and occ[r][c]
	for r in range(rows):
		for c in range(cols):
			if not occ[r][c]:
				continue
			var top: bool = not on.call(r - 1, c)
			var bottom: bool = not on.call(r + 1, c)
			var left: bool = not on.call(r, c - 1)
			var right: bool = not on.call(r, c + 1)
			for ly in range(cell):
				for lx in range(cell):
					var px: Color = color
					var x0: bool = lx == 0
					var x1: bool = lx == cell - 1
					var y0: bool = ly == 0
					var y1: bool = ly == cell - 1
					if (y0 and top) or (y1 and bottom) or (x0 and left) or (x1 and right):
						px = INK
					# The inside corner of an L, where both neighbours are
					# there but the diagonal is not: the outline turns it.
					elif (x0 and y0 and not on.call(r - 1, c - 1)) or (x1 and y0 and not on.call(r - 1, c + 1)) \
							or (x0 and y1 and not on.call(r + 1, c - 1)) or (x1 and y1 and not on.call(r + 1, c + 1)):
						px = INK
					elif (ly == 1 and top) or (lx == 1 and left):
						px = light
					elif (ly == cell - 2 and bottom) or (lx == cell - 2 and right):
						px = shade
					img.set_pixel(c * cell + lx, r * cell + ly, px)
	return ImageTexture.create_from_image(img)
