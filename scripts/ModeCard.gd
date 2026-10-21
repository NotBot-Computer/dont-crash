extends Control

## One card of a keyboard-picked row (CardRow): a framed panel, taller than
## it is wide, with a live preview filling it and a name underneath —
## nothing else, at the user's request. The row owns the selection and sets
## `selected`; this only draws.
##
## The selected card is ringed in yellow and its preview runs. The others
## hold still and dim, so what Enter will start is never in doubt.
##
## Previews, all made of the game's own art:
##   RACE   the road scrolling down and cars driving up it, in lanes, each
##          lane at its own pace so nothing ever overlaps (main menu).
##   ROADS  `count` roads side by side, split-screen, a player's car on each
##          (the player count); `bot_last` tags the last one BOT.
##
## In ROADS every strip is its own well: a dark floor inside a
## thin pixel ring (PixelUI.well), with the card's face showing between
## strips. A thin black line between them did not read as separate boards.
## On the player count each ring is in its seat's colour.
##
## Set every export before adding the card: the preview is built in _ready()
## from the card's size. Never takes the mouse.

const PixelUI := preload("res://scripts/PixelUI.gd")
const ROAD_TEXTURE := preload("res://sprites/road/road_tile.png")

enum Kind { RACE, ROADS }

const INSET := 18.0 # frame to preview
const NAME_BAND := 66.0 # under the preview, for the name
const TITLE_SIZE := 24
const DIM := Color(0.5, 0.52, 0.6, 1.0)
const SPLIT := 9.0 # the card's face between two strips
const WELL_BG := Color(0.055, 0.06, 0.13, 1.0)

# The race preview, in the Road's own terms (Road.SHOULDER_RATIO, 5 lanes).
const SHOULDER_RATIO := 0.1287
const LANES := 5
const ROAD_SPEED := 70.0 # px/s down — the camera climbing
const LANE_SPEED_MIN := 45.0 # px/s up the screen, on top of that
const LANE_SPEED_MAX := 150.0
const CAR_GAP := 26.0 # bumper to bumper, at least, within a lane
const PLAYER_SHARE := 0.35 # how many of the cars are the six player sedans

# The split-screen roads: each board scrolls fast under its own car, which
# weaves. The car is drawn far bigger than its lane would make it — at four
# boards a true-scale car would be a few pixels wide.
const BOARD_SPEED := 260.0
const BOARD_CAR_W := 0.42 # of a strip's width
const BOARD_CAR_MAX_W := 46.0

@export var kind: Kind = Kind.RACE
@export var title := ""
@export var count := 1
@export var bot_last := false

var selected := false:
	set(v):
		selected = v
		_apply_selected()

var _font: Font
var _frame: StyleBox
var _frame_hot: StyleBox
var _preview: Control
var _wells: Array[StyleBox] = [] # one ring per strip
var t := 0.0

var _road_y := 0.0
var _lane_speed: Array[float] = []
var _lane_next: Array[float] = [] # seconds until a lane may take another car
var _cars: Array[Dictionary] = [] # tex, lane, y (top, px), w, h
var _phase: Array[float] = [] # per board, where its car is in its weave

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_font = PixelUI.font()
	_frame = PixelUI.panel_frame()
	_frame_hot = PixelUI.panel_frame(PixelUI.HOT)

	_preview = Control.new()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.clip_contents = true
	_preview.position = Vector2(INSET, INSET)
	_preview.size = Vector2(size.x - INSET * 2.0, size.y - INSET - NAME_BAND)
	add_child(_preview)

	if kind == Kind.ROADS:
		for i in range(count):
			_wells.append(PixelUI.well(_seat_color(i)))
			_phase.append(randf() * TAU)
		_preview.draw.connect(_draw_roads)
	else:
		_preview.draw.connect(_draw_race)
		_start_race()
	_apply_selected()

func _apply_selected() -> void:
	if _preview == null:
		return
	_preview.modulate = Color.WHITE if selected else DIM
	queue_redraw()

func _process(delta: float) -> void:
	if not selected:
		return
	t += delta
	if kind == Kind.RACE:
		_step_race(delta)
		_preview.queue_redraw()
	elif kind == Kind.ROADS:
		_road_y += BOARD_SPEED * delta
		_preview.queue_redraw()

func _draw() -> void:
	draw_style_box(_frame_hot if selected else _frame, Rect2(Vector2.ZERO, size))
	# The name centred in the band under the preview, at 24 if it fits and 16
	# if not ("1 PLAYER vs BOT" on a four-card row).
	var fs: int = TITLE_SIZE
	if _font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > size.x - INSET * 2.0:
		fs = 16
	var y: float = size.y - NAME_BAND * 0.5 + float(fs) * 0.25
	var tc: Color = PixelUI.HOT if selected else PixelUI.TEXT
	var off: float = 3.0 if fs > 16 else 2.0
	draw_string(_font, Vector2(off, y + off), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, PixelUI.SHADOW)
	draw_string(_font, Vector2(0.0, y), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, tc)

# --- Strips ---------------------------------------------------------------------

# Inside a strip's ring.
func _inner(s: Rect2) -> Rect2:
	return s.grow(-float(PixelUI.WELL))

func _draw_wells(on: CanvasItem) -> void:
	var strips: Array[Rect2] = _strips()
	for i in range(strips.size()):
		on.draw_style_box(_wells[i], strips[i])

# The strips, left to right, with SPLIT between them.
func _strips() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var w: float = (_preview.size.x - SPLIT * float(count - 1)) / float(count)
	for i in range(count):
		out.append(Rect2(floorf(float(i) * (w + SPLIT)), 0.0, floorf(w), _preview.size.y))
	return out

# Seat i's colour before anyone has picked one: the colour SkinSelect starts
# them on.
func _seat_color(i: int) -> Color:
	return GameSettings.PLAYER_SKINS[i % GameSettings.PLAYER_SKINS.size()]["color"]

# --- Split-screen roads ------------------------------------------------------------

func _draw_roads() -> void:
	var strips: Array[Rect2] = _strips()
	for i in range(strips.size()):
		var s: Rect2 = _inner(strips[i])
		_draw_road(s, _road_y)
		var tex: Texture2D = GameSettings.PLAYER_SKINS[i % GameSettings.PLAYER_SKINS.size()]["texture"]
		var cw: float = minf(s.size.x * BOARD_CAR_W, BOARD_CAR_MAX_W)
		var ch: float = cw * 1.69 # PlayerBoard.PLAYER_KIND's height_frac
		var road_w: float = s.size.x * (1.0 - SHOULDER_RATIO * 2.0)
		var sway: float = sin(t * 1.7 + _phase[i]) * (road_w - cw) * 0.42
		var cx: float = s.position.x + s.size.x * 0.5 + sway
		var cy: float = s.position.y + s.size.y * 0.62 + sin(t * 2.3 + _phase[i]) * 6.0
		_preview.draw_texture_rect(tex, Rect2(floorf(cx - cw * 0.5), floorf(cy - ch * 0.5), cw, ch), false)
		if bot_last and i == strips.size() - 1:
			var ty: float = floorf(cy - ch * 0.5 - 10.0)
			_preview.draw_string(_font, Vector2(s.position.x + 2.0, ty + 2.0), "BOT", HORIZONTAL_ALIGNMENT_CENTER, s.size.x, 16, PixelUI.SHADOW)
			_preview.draw_string(_font, Vector2(s.position.x, ty), "BOT", HORIZONTAL_ALIGNMENT_CENTER, s.size.x, 16, PixelUI.HOT)
	_draw_wells(_preview)

# The road tile scaled to a strip's width, scrolled down by `scroll`, and
# cut to the strip's own top and bottom (a strip can be inset from the
# preview's edges, and the ring's notched corners must not show road).
func _draw_road(s: Rect2, scroll: float) -> void:
	var tex_size: Vector2 = ROAD_TEXTURE.get_size()
	var tile_h: float = tex_size.y * s.size.x / tex_size.x
	var y: float = s.position.y + fmod(scroll, tile_h) - tile_h
	while y < s.end.y:
		var top: float = maxf(floorf(y), s.position.y)
		# A pixel taller than the step, so rounding never opens a seam.
		var bottom: float = minf(floorf(y) + ceilf(tile_h) + 1.0, s.end.y)
		if bottom > top:
			var k: float = tex_size.y / tile_h
			var src := Rect2(0.0, (top - floorf(y)) * k, tex_size.x, (bottom - top) * k)
			_preview.draw_texture_rect_region(ROAD_TEXTURE, Rect2(s.position.x, top, s.size.x, bottom - top), src)
		y += tile_h

# --- The race preview -----------------------------------------------------------

func _lane_w() -> float:
	var w: float = _preview.size.x
	return (w - w * SHOULDER_RATIO * 2.0) / float(LANES)

func _lane_x(lane: int) -> float:
	var w: float = _preview.size.x
	return w * SHOULDER_RATIO + _lane_w() * (float(lane) + 0.5)

func _start_race() -> void:
	_lane_speed.clear()
	_lane_next.clear()
	for _l in range(LANES):
		_lane_speed.append(randf_range(LANE_SPEED_MIN, LANE_SPEED_MAX))
		_lane_next.append(0.0)
	# A road already busy: step it a few seconds before anyone sees it.
	for _i in range(240):
		_step_race(1.0 / 30.0)

func _step_race(delta: float) -> void:
	var h: float = _preview.size.y
	_road_y += ROAD_SPEED * delta
	var still: Array[Dictionary] = []
	for c in _cars:
		c["y"] -= _lane_speed[c["lane"]] * delta
		if c["y"] + c["h"] > -4.0:
			still.append(c)
	_cars = still
	for l in range(LANES):
		_lane_next[l] -= delta
		if _lane_next[l] <= 0.0 and randf() < delta * 1.4:
			var car: Dictionary = _make_car(l)
			car["y"] = h + 2.0
			_cars.append(car)
			# The next car in this lane waits until this one has pulled a
			# whole car length plus a gap clear of the bottom edge.
			_lane_next[l] = (car["h"] + CAR_GAP) / _lane_speed[l]

func _make_car(lane: int) -> Dictionary:
	var tex: Texture2D
	var cfg: Dictionary
	if randf() < PLAYER_SHARE:
		var skin: Dictionary = GameSettings.PLAYER_SKINS[randi() % GameSettings.PLAYER_SKINS.size()]
		tex = skin["texture"]
		cfg = {"width_frac": 0.62, "height_frac": 1.69} # PlayerBoard.PLAYER_KIND
	else:
		cfg = _pick_traffic()
		var texs: Array = cfg["textures"]
		tex = texs[randi() % texs.size()]
	var w: float = _lane_w() * float(cfg["width_frac"])
	return {"tex": tex, "lane": lane, "y": 0.0, "w": w, "h": w * float(cfg["height_frac"])}

# Weighted like the real traffic (GameSettings.TRAFFIC_KINDS' weights).
func _pick_traffic() -> Dictionary:
	var total := 0
	for k: Dictionary in GameSettings.TRAFFIC_KINDS:
		total += int(k["weight"])
	var r: int = randi() % maxi(1, total)
	for k: Dictionary in GameSettings.TRAFFIC_KINDS:
		r -= int(k["weight"])
		if r < 0:
			return k
	return GameSettings.TRAFFIC_KINDS[0]

func _draw_race() -> void:
	_draw_road(Rect2(Vector2.ZERO, _preview.size), _road_y)
	for c in _cars:
		var cw: float = c["w"]
		var ch: float = c["h"]
		_preview.draw_texture_rect(c["tex"], Rect2(floorf(_lane_x(c["lane"]) - cw * 0.5), floorf(c["y"]), cw, ch), false)
