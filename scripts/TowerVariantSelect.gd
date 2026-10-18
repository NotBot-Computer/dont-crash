extends Control

## Pile Up's first screen after the main menu: alone or in teams. Both are a
## cup (GameSettings.TOWER_CUPS) — a run of rounds, a different variant every
## round, trophies by place — and nothing else is offered: every variant is
## played as one of a cup's rounds, asked for so that Pile Up is always a cup
## whichever way you play it. PlayerSelect then offers only the counts the
## chosen cup allows, and the first round's variant is set here so the count
## and colour screens seat people the way that round will.
##
## The rows are built from the table rather than laid out in the scene, so
## the list of cups and the screen that offers them cannot disagree.
##
## It used to list the variants themselves, with the team ones on a page of
## their own under TEAM MODES and each page's cup last; see
## docs/PROJECT_STATE.md §5 sessions AE, AG and AH.

const ROW_TOP := 220.0
const ROW_STEP := 130.0
const BUTTON_W := 340.0
const BUTTON_H := 56.0

var _rows: Array[Control] = []

func _ready() -> void:
	$BackButton.pressed.connect(_on_back)
	$Title.text = "PILE UP"
	$Subtitle.text = "a different mode every round — first to %d trophies wins" % GameSettings.CUP_TARGET

	var focus: Button = null
	for c: Dictionary in GameSettings.TOWER_CUPS:
		var id: int = c["id"]
		var row: Button = _add_row(c["title"], c["hint"], func(): _pick_cup(id))
		if id == GameSettings.tower_cup:
			focus = row
	if focus == null and not _rows.is_empty():
		focus = _rows[0] as Button
	if focus != null:
		focus.grab_focus()

# A button and its hint line, at the next free row.
func _add_row(title: String, hint_text: String, on_press: Callable) -> Button:
	var y: float = ROW_TOP + float(_rows.size()) * 0.5 * ROW_STEP

	var button := Button.new()
	button.text = title
	button.add_theme_font_size_override("font_size", 24)
	button.anchor_left = 0.5
	button.anchor_right = 0.5
	button.offset_left = -BUTTON_W * 0.5
	button.offset_right = BUTTON_W * 0.5
	button.offset_top = y
	button.offset_bottom = y + BUTTON_H
	button.pressed.connect(on_press)
	add_child(button)

	var hint := Label.new()
	hint.text = hint_text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.anchor_right = 1.0
	hint.offset_top = y + BUTTON_H + 6.0
	hint.offset_bottom = y + BUTTON_H + 32.0
	add_child(hint)

	_rows.append(button)
	_rows.append(hint)
	return button

# The scores themselves start when the colours are locked (SkinSelect), once
# the number of players is known.
func _pick_cup(cup: int) -> void:
	GameSettings.tower_cup = cup
	GameSettings.tower_variant = GameSettings.tower_cup_info(cup)["rounds"][0]
	get_tree().change_scene_to_file("res://scenes/PlayerSelect.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
