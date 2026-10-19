extends TowerSkill

## NIGHTFALL (pack B, id "nightfall") — an opponent skill that attacks the
## victim's *eyes*, and nothing else.
##
## Night falls on their next TURNS (two of them). The screen goes dark — the
## tower, the platform and their own falling brick all with it — and the only
## light is lightning. Every second or two a bolt cracks down the sky, and for
## a third of a second the whole scene is lit: the stack, and the brick where
## it really is. Then the dark comes back and they steer from memory. Their
## brick steers exactly as it did, falls exactly as fast, weighs exactly as
## much; the only thing taken is what they can see, which is the same
## restraint Don't Crash's Smoke Screen makes and for the same reason — a hex
## that both blinds you and changes your controls is two skills with one icon.
##
## It was a lantern first (session AD): the dark had a hole of light around
## the held brick, so the brick was always seen and the landing too. The user
## asked for the stronger version instead (session AJ) — the tower AND the
## falling brick unseen, lightning the only look — and for it to last a while,
## which became two of the victim's turns.
##
## What keeps it a skill and not a coin flip:
##   * The dark ARRIVES. It fades in over FADE_IN from the start of each turn
##     under it, so the victim sees the tower with the new brick already above
##     it and gets one honest look. Movement is on the half-cell lattice, so
##     from there a careful player can count their presses.
##   * The first strike comes EARLY (STRIKE_FIRST_*), well before a brick at
##     the ordinary descent speed can reach the stack, and then every
##     STRIKE_GAP_* — drawn per turn, so a player cannot count on the beat.
##   * The landing is SEEN. The dark lifts over FADE_OUT the instant the brick
##     is out of the victim's hands, so the table watches the tower settle (or
##     not) in daylight. The fault rule needs that: what falls on this turn is
##     the victim's, and they should watch it.
##
## The dark is SCREEN-space (draw_screen): it sits above the world and below
## the HUD panels, so the cards, the next brick and the toast stay readable,
## and the world underneath is not moved, tinted or hidden by anything but
## alpha. It is strictly the victim's — only drawn while their slot is on the
## clock — and in a race it is drawn into the victim's own tower's viewport,
## so the other halves stay in daylight. Between activate() and the first
## tick the envelope is 0, so a queued hex never darkens anybody else's turn.
##
## Nothing is written on the mode and no node or resource is made, so
## deactivate() has nothing to free and nothing to undo: once its two turns
## are over the next frame is ordinary daylight.

# --- Timing -----------------------------------------------------------------

# The lights going down, at the start of each turn under the hex. Long enough
# for the look described above, short enough that a soft-dropping victim is
# in the dark before the stack.
const FADE_IN := 0.6
# And back up, from the moment the brick is out of the victim's hands.
const FADE_OUT := 0.3

# Strikes, timed from the start of each turn: the first after
# STRIKE_FIRST_MIN..MAX of it, then every STRIKE_GAP_MIN..MAX.
const STRIKE_FIRST_MIN := 1.0
const STRIKE_FIRST_MAX := 1.5
const STRIKE_GAP_MIN := 1.5
const STRIKE_GAP_MAX := 2.6
const STRIKE_HORIZON := 14.0 # seconds of strikes drawn per turn; a wedged brick lasts 6s at most past an ordinary descent

# One strike, as a shape over its own clock. The scene is fully lit for
# REVEAL, then the dark closes back over CLOSE — a third of a second of
# daylight, enough to see the stack and where the brick is, not enough to
# line a shot up without already having a plan. Real lightning stutters, so
# there is one dip in the middle of the reveal (DIP_*), down to DIP_LIGHT.
const REVEAL := 0.30
const CLOSE := 0.18
const DIP_START := 0.10
const DIP_END := 0.14
const DIP_LIGHT := 0.35
# The flash itself: the screen washed white for FLASH, from FLASH_ALPHA.
const FLASH := 0.10
const FLASH_ALPHA := 0.55
const FLASH_COLOR := Color(0.92, 0.95, 1.0)

# --- The bolt -----------------------------------------------------------------

# Drawn for BOLT_TIME from the top of the screen down to BOLT_REACH_* of the
# way down, starting at a random x in BOLT_X_* of the view, in BOLT_SEGMENTS
# steps that each wander up to BOLT_JAG of the view's width sideways, with one
# short fork. All in fractions of the view, so a 375px race tower's bolt is as
# crooked as a full-width one. A wide faint stroke under a thin white one, so
# it glows rather than reading as a line.
const BOLT_TIME := 0.24
const BOLT_X_MIN := 0.30
const BOLT_X_MAX := 0.70
const BOLT_REACH_MIN := 0.45
const BOLT_REACH_MAX := 0.75
const BOLT_SEGMENTS := 9
const BOLT_JAG := 0.022
const BOLT_CORE := 3.0
const BOLT_GLOW := 12.0
const BOLT_GLOW_ALPHA := 0.35
const BOLT_COLOR := Color(0.85, 0.92, 1.0)

# --- The dark -----------------------------------------------------------------

# Night blue, not black: black over a pixel-art sky reads as a rendering
# fault, a deep blue reads as night — a storm sky, a touch lighter at the top
# (DARK_TOP) than at the ground (DARK), so it is a sky and not a flat panel.
# Fully opaque: the lantern version used 0.94 because it had the lantern,
# and 0.97 was tried here first, but a brick's black outline still showed
# through it as a silhouette (screenshot), which would make the strikes
# pointless.
const DARK := Color(0.02, 0.03, 0.08)
const DARK_TOP := Color(0.07, 0.08, 0.17)

# --- State ------------------------------------------------------------------

var _retired: bool = false
var _age: float = 0.0 # seconds into the current turn under the hex; the strike clock
var _dark: float = 0.0 # envelope, 0..1, advanced in tick()
var _strikes: Array[float] = [] # this turn's strike times, in order
var _bolts: Array[Dictionary] = [] # per strike: {"main", "fork"} PackedVector2Arrays, in fractions of the view

# --- Hooks ------------------------------------------------------------------

func hud_tag() -> String:
	return "DARK"

func duration_turns() -> int:
	return 2

# --- Lifecycle --------------------------------------------------------------

func activate() -> void:
	_retired = false
	_new_turn()

# The second turn opens like the first: daylight, then the dark arriving,
# with a fresh set of strikes.
func on_turn_start() -> void:
	if not _retired:
		_new_turn()

func _new_turn() -> void:
	_age = 0.0
	_dark = 0.0
	_strikes = []
	_bolts = []
	var t: float = randf_range(STRIKE_FIRST_MIN, STRIKE_FIRST_MAX)
	while t < STRIKE_HORIZON:
		_strikes.append(t)
		_bolts.append(_make_bolt())
		t += randf_range(STRIKE_GAP_MIN, STRIKE_GAP_MAX)

func tick(delta: float) -> void:
	if _retired or mode == null:
		return
	_age += delta
	var piece = mode.active_piece
	var piloting: bool = mode.state == "piloting" and piece != null and is_instance_valid(piece)
	_dark = move_toward(_dark, 1.0 if piloting else 0.0, delta / (FADE_IN if piloting else FADE_OUT))

# Nothing on the mode to undo. The envelope is zeroed so a draw call that
# somehow lands between retirement and the canvas's next redraw paints
# nothing (TowerMode redraws both skill canvases every frame regardless).
# Idempotent by construction.
func deactivate() -> void:
	_retired = true
	_dark = 0.0
	_strikes = []
	_bolts = []

# --- Lightning ------------------------------------------------------------------

# The strike in progress as (index, seconds into it), or index -1 for none.
func _current_strike() -> Vector2:
	for i in range(_strikes.size()):
		var u: float = _age - _strikes[i]
		if u < 0.0:
			break # in order; nothing later has started either
		if u < REVEAL + CLOSE:
			return Vector2(float(i), u)
	return Vector2(-1.0, 0.0)

# How much of the dark a strike lifts, 0..1, at `u` seconds into it.
func _light(u: float) -> float:
	if u < 0.0:
		return 0.0
	if u < REVEAL:
		return DIP_LIGHT if (u > DIP_START and u < DIP_END) else 1.0
	if u < REVEAL + CLOSE:
		return 1.0 - (u - REVEAL) / CLOSE
	return 0.0

# A jagged path from the top edge down, plus one short fork off a point in its
# upper half. Drawn once per strike at the start of the turn, so it holds
# still while it is on screen.
func _make_bolt() -> Dictionary:
	var main := PackedVector2Array()
	var x: float = randf_range(BOLT_X_MIN, BOLT_X_MAX)
	var reach: float = randf_range(BOLT_REACH_MIN, BOLT_REACH_MAX)
	var step: float = reach / float(BOLT_SEGMENTS)
	for k in range(BOLT_SEGMENTS + 1):
		main.append(Vector2(x, float(k) * step))
		x += randf_range(-BOLT_JAG, BOLT_JAG)
	var fork := PackedVector2Array()
	var p: Vector2 = main[randi_range(2, BOLT_SEGMENTS / 2)]
	var side: float = -1.0 if randf() < 0.5 else 1.0
	fork.append(p)
	for _k in range(3):
		p += Vector2(side * randf_range(BOLT_JAG * 0.7, BOLT_JAG * 1.6), step * 0.8)
		fork.append(p)
	return {"main": main, "fork": fork}

# --- Drawing ----------------------------------------------------------------

# Screen space (TowerSkillScreen): above the world, below the HUD panels.
func draw_screen(canvas: CanvasItem) -> void:
	if _retired or mode == null or _dark <= 0.001:
		return
	if mode.active_slot != target:
		return
	var size: Vector2 = canvas.get_viewport_rect().size
	var strike: Vector2 = _current_strike()
	var lit: float = _light(strike.y) if strike.x >= 0.0 else 0.0

	var alpha: float = _dark * (1.0 - lit)
	if alpha > 0.001:
		var top := Color(DARK_TOP.r, DARK_TOP.g, DARK_TOP.b, alpha)
		var bottom := Color(DARK.r, DARK.g, DARK.b, alpha)
		canvas.draw_polygon(
			PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0.0), size, Vector2(0.0, size.y)]),
			PackedColorArray([top, top, bottom, bottom]))
	if strike.x < 0.0:
		return

	# Both scaled by the envelope, so a strike that lands while the dark is
	# still arriving, or already lifting, is no brighter than the night it
	# is in.
	var u: float = strike.y
	if u < FLASH:
		var f: float = FLASH_ALPHA * (1.0 - u / FLASH) * _dark
		canvas.draw_rect(Rect2(Vector2.ZERO, size), Color(FLASH_COLOR.r, FLASH_COLOR.g, FLASH_COLOR.b, f), true)
	if u < BOLT_TIME:
		var a: float = (1.0 - u / BOLT_TIME) * _dark
		var bolt: Dictionary = _bolts[int(strike.x)]
		for path: PackedVector2Array in [bolt["main"], bolt["fork"]]:
			var pts := PackedVector2Array()
			for q: Vector2 in path:
				pts.append(q * size)
			canvas.draw_polyline(pts, Color(BOLT_COLOR.r, BOLT_COLOR.g, BOLT_COLOR.b, BOLT_GLOW_ALPHA * a), BOLT_GLOW, true)
			canvas.draw_polyline(pts, Color(1.0, 1.0, 1.0, a), BOLT_CORE, true)
