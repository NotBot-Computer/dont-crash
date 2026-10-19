extends Control

## Pile Up's bricks raining down behind a menu and piling up along the
## bottom of the screen; when the pile gets tall it sinks out of sight and a
## new one starts. Pure decoration: no physics, nothing to do with the game,
## and it never takes a click.
##
## Bricks fall straight down on a grid of columns and stop on the column
## heights below them, Tetris style, so a pile is built without anything
## ever overlapping — and two bricks never fall through the same columns at
## once, which is what lets a landing be decided from the heights alone.
##
## Each screen starts with a pile already part built and bricks already in
## the air, so changing screens does not look like the rain starting over.

const PixelUI := preload("res://scripts/PixelUI.gd")

const CELL_ART := 10 # art pixels per brick cell; a cell is CELL_ART * PIX on screen
# Tunable per instance: the main menu's Pile Up card runs one of these at
# full strength inside its preview.
@export var max_rows := 5 # the pile sinks once a column reaches this
@export var prewarm_rows := 3
@export var fall_alpha := 0.34
@export var pile_alpha := 0.75
const SPAWN_MIN := 0.5
const SPAWN_MAX := 1.1
const MAX_FALLING := 9
const FALL_MIN := 55.0
const FALL_MAX := 100.0
const CLASSIC_SHARE := 0.85 # the odd bricks are rarer in the game too
const SINK_TIME := 1.1

var cell: float = float(CELL_ART * PixelUI.PIX)
var _textures := {} # "brick:quarter" -> ImageTexture
var _colors: Array[Color] = []
var _classic: Array[int] = []
var _odd: Array[int] = []

var cols := 0
var x0 := 0.0
var heights: Array[int] = []
var falling: Array[Dictionary] = [] # key, gx, w, h, low (per column), top (per column), y (bottom edge, px), speed
var pile: Array[Dictionary] = [] # key, gx, w, h, base (rows above the floor)
var sinking: Array[Dictionary] = []
var sink_t := 0.0
var spawn_in := 0.0
var _started := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Start as soon as there is a size, even with processing off — a paused
	# rain (the unselected mode card) still shows its pile and its sky.
	resized.connect(_try_start)
	_try_start.call_deferred()
	for i in range(GameSettings.BRICKS.size()):
		var b: Dictionary = GameSettings.BRICKS[i]
		_colors.append(PixelUI.brick_color(b))
		(_classic if b["classic"] else _odd).append(i)

func _try_start() -> void:
	if not _started and size.x > 0.0:
		_start()
		queue_redraw()

func _process(delta: float) -> void:
	if not _started:
		if size.x <= 0.0:
			return
		_start()
	spawn_in -= delta
	if spawn_in <= 0.0:
		spawn_in = randf_range(SPAWN_MIN, SPAWN_MAX)
		if falling.size() < MAX_FALLING:
			_spawn(randf_range(-cell * 2.0, 0.0))

	var still: Array[Dictionary] = []
	for p in falling:
		p["y"] += p["speed"] * delta
		var land_y: float = size.y - float(_base_for(p)) * cell
		if p["y"] >= land_y:
			p["y"] = land_y
			_land(p, _base_for(p))
		else:
			still.append(p)
	falling = still

	if not sinking.is_empty():
		sink_t += delta
		if sink_t >= SINK_TIME:
			sinking.clear()
	queue_redraw()

func _start() -> void:
	_started = true
	cols = int(size.x / cell)
	x0 = floorf((size.x - float(cols) * cell) * 0.5)
	heights.resize(cols)
	heights.fill(0)
	# A pile part built, then a sky already full of bricks.
	for _n in range(60):
		var p: Dictionary = _make_piece()
		var base: int = _base_for(p)
		if base + int(p["h"]) > prewarm_rows:
			continue
		_land(p, base)
	for _n in range(6):
		_spawn(randf_range(0.0, maxf(0.0, size.y - float(max_rows + 2) * cell)))
	spawn_in = randf_range(SPAWN_MIN, SPAWN_MAX)

func _pick_brick() -> int:
	if _odd.is_empty() or randf() < CLASSIC_SHARE:
		return _classic[randi() % _classic.size()]
	return _odd[randi() % _odd.size()]

# A random brick at a random turn and column. `low[i]` is how far the
# brick's lowest cell in column i sits above its bottom edge, `top[i]` how
# tall it stands in that column — both in cells — which is all a landing
# needs to know.
func _make_piece() -> Dictionary:
	var idx: int = _pick_brick()
	var quarter: int = randi() % 4
	var occ: Array = PixelUI.brick_cells(GameSettings.BRICKS[idx], quarter)
	var h: int = occ.size()
	var w: int = (occ[0] as Array).size()
	var low: Array[int] = []
	var top: Array[int] = []
	for c in range(w):
		var lo := -1
		var hi := -1
		for r in range(h):
			if occ[r][c]:
				if hi < 0:
					hi = r
				lo = r
		low.append(h - 1 - lo)
		top.append(h - hi)
	var key := "%d:%d" % [idx, quarter]
	if not _textures.has(key):
		_textures[key] = PixelUI.cells_texture(occ, _colors[idx], CELL_ART)
	return {"key": key, "gx": randi() % maxi(1, cols - w + 1), "w": w, "h": h, "low": low, "top": top}

# A new falling brick whose columns no other falling brick is using.
func _spawn(bottom_y: float) -> void:
	for _try in range(8):
		var p: Dictionary = _make_piece()
		var clear := true
		for q in falling:
			if p["gx"] < q["gx"] + q["w"] and q["gx"] < p["gx"] + p["w"]:
				clear = false
				break
		if clear:
			p["y"] = bottom_y
			p["speed"] = randf_range(FALL_MIN, FALL_MAX)
			falling.append(p)
			return

# Rows above the floor at which the brick's bottom edge comes to rest.
func _base_for(p: Dictionary) -> int:
	var base := 0
	for i in range(int(p["w"])):
		base = maxi(base, heights[int(p["gx"]) + i] - int(p["low"][i]))
	return base

func _land(p: Dictionary, base: int) -> void:
	var tallest := 0
	for i in range(int(p["w"])):
		var c: int = int(p["gx"]) + i
		heights[c] = maxi(heights[c], base + int(p["top"][i]))
		tallest = maxi(tallest, heights[c])
	pile.append({"key": p["key"], "gx": p["gx"], "w": p["w"], "h": p["h"], "base": base})
	# Full: the pile sinks away and the next one starts on an empty floor
	# straight away, so the rain never stops.
	if tallest >= max_rows:
		sinking = pile
		pile = []
		sink_t = 0.0
		heights.fill(0)

func _snap(v: float) -> float:
	var px: float = float(PixelUI.PIX)
	return floorf(v / px) * px

func _draw_piece(p: Dictionary, bottom: float, alpha: float) -> void:
	var tex: Texture2D = _textures[p["key"]]
	var w: float = float(p["w"]) * cell
	var h: float = float(p["h"]) * cell
	draw_texture_rect(tex, Rect2(x0 + float(p["gx"]) * cell, _snap(bottom - h), w, h), false, Color(1, 1, 1, alpha))

func _draw() -> void:
	if not _started:
		return
	var k: float = clampf(sink_t / SINK_TIME, 0.0, 1.0)
	var drop: float = k * k * float(max_rows + 1) * cell
	for p in sinking:
		_draw_piece(p, size.y - float(p["base"]) * cell + drop, pile_alpha * (1.0 - k * 0.5))
	for p in pile:
		_draw_piece(p, size.y - float(p["base"]) * cell, pile_alpha)
	for p in falling:
		_draw_piece(p, p["y"], fall_alpha)
