extends Control

## One of the main menu's two mode cards: a framed panel, taller than it is
## wide, with a live preview of the mode filling it and the mode's name
## underneath — nothing else, at the user's request. MainMenu owns
## the selection and sets `selected`; this only draws.
##
## The selected card is ringed in yellow and its preview runs. The other one
## holds still and dims, so which mode Enter will start is never in doubt.
##
## The previews are made of the game's own art. RACE: the road scrolling
## down and cars driving up it, in lanes, each lane at its own pace so
## nothing ever overlaps. TOWER: a BrickRain at full strength, bricks falling
## and piling up.
##
## Keyboard only — it never takes the mouse (the menu is driven with the
## arrow keys and Enter).

const PixelUI := preload("res://scripts/PixelUI.gd")
const BrickRain := preload("res://scripts/BrickRain.gd")
const ROAD_TEXTURE := preload("res://sprites/road/road_tile.png")

enum Kind { RACE, TOWER }

const INSET := 18.0 # frame to preview
const NAME_BAND := 66.0 # under the preview, for the mode's name
const TITLE_SIZE := 24
const DIM := Color(0.5, 0.52, 0.6, 1.0)

# The race preview, in the Road's own terms (Road.SHOULDER_RATIO, 5 lanes).
const SHOULDER_RATIO := 0.1287
const LANES := 5
const ROAD_SPEED := 70.0 # px/s down — the camera climbing
const LANE_SPEED_MIN := 45.0 # px/s up the screen, on top of that
const LANE_SPEED_MAX := 150.0
const CAR_GAP := 26.0 # bumper to bumper, at least, within a lane
const PLAYER_SHARE := 0.35 # how many of the cars are the six player sedans

@export var kind: Kind = Kind.RACE
@export var title := ""

var selected := false:
	set(v):
		selected = v
		_apply_selected()

var _font: Font
var _frame: StyleBox
var _frame_hot: StyleBox
var _preview: Control
var _rain: Control

var _road_y := 0.0
var _lane_speed: Array[float] = []
var _lane_next: Array[float] = [] # seconds until a lane may take another car
var _cars: Array[Dictionary] = [] # tex, lane, y (top, px), w, h

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

	if kind == Kind.TOWER:
		_rain = BrickRain.new()
		_rain.max_rows = 6
		_rain.prewarm_rows = 3
		_rain.fall_alpha = 1.0
		_rain.pile_alpha = 1.0
		_rain.set_anchors_preset(Control.PRESET_FULL_RECT)
		_preview.add_child(_rain)
	else:
		_preview.draw.connect(_draw_race)
		_start_race()
	_apply_selected()

func _apply_selected() -> void:
	if _preview == null:
		return
	_preview.modulate = Color.WHITE if selected else DIM
	if _rain != null:
		_rain.set_process(selected)
	queue_redraw()

func _process(delta: float) -> void:
	if kind == Kind.RACE and selected:
		_step_race(delta)
		_preview.queue_redraw()

func _draw() -> void:
	draw_style_box(_frame_hot if selected else _frame, Rect2(Vector2.ZERO, size))
	# The name centred in the band under the preview (a 24px cap is ~24px tall).
	var y: float = size.y - NAME_BAND * 0.5 + 6.0
	var tc: Color = PixelUI.HOT if selected else PixelUI.TEXT
	draw_string(_font, Vector2(3.0, y + 3.0), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, TITLE_SIZE, PixelUI.SHADOW)
	draw_string(_font, Vector2(0.0, y), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, TITLE_SIZE, tc)

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
	var w: float = _preview.size.x
	var h: float = _preview.size.y
	var tile_h: float = ROAD_TEXTURE.get_height() * w / ROAD_TEXTURE.get_width()
	var y: float = fmod(_road_y, tile_h) - tile_h
	while y < h:
		_preview.draw_texture_rect(ROAD_TEXTURE, Rect2(0.0, floorf(y), w, tile_h), false)
		y += tile_h
	for c in _cars:
		var cw: float = c["w"]
		var ch: float = c["h"]
		_preview.draw_texture_rect(c["tex"], Rect2(floorf(_lane_x(c["lane"]) - cw * 0.5), floorf(c["y"]), cw, ch), false)
