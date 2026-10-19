extends Control

## Mode picker. GameSettings.mode is set here and then read by PlayerSelect
## (which hides the race-only single-player option) and by SkinSelect (which
## decides which scene to hand off to). Nothing downstream re-derives it.
## Pile Up goes through one more screen first — TowerVariantSelect, which
## picks the solo or the team cup.
##
## Two big cards side by side, one per mode, each with a live preview of its
## mode that runs while it is the selected one (ModeCard). Driven by the
## keyboard alone: left/right choose, Enter (or Space) plays; the mouse does
## nothing here. Coming back from a mode's screens, that mode is the one
## selected.
##
## The rest of the look (the pixel font, the brick rain and the brick title)
## is shared by every menu screen — see PixelUI.

const PixelUI := preload("res://scripts/PixelUI.gd")

@onready var cards: Array[Control] = [$RaceCard, $TowerCard]
var choice := 0
var _leaving := false

func _ready() -> void:
	PixelUI.apply(self)
	_select(1 if GameSettings.mode == GameSettings.MODE_TOWER else 0)

func _select(i: int) -> void:
	choice = clampi(i, 0, cards.size() - 1)
	for k in range(cards.size()):
		cards[k].selected = k == choice

func _unhandled_input(event: InputEvent) -> void:
	if _leaving:
		return
	if event.is_action_pressed("ui_left"):
		_select(choice - 1)
	elif event.is_action_pressed("ui_right"):
		_select(choice + 1)
	elif event.is_action_pressed("ui_accept"):
		_leaving = true
		_play(GameSettings.MODE_TOWER if choice == 1 else GameSettings.MODE_RACE)
	else:
		return
	get_viewport().set_input_as_handled()

func _play(mode: int) -> void:
	GameSettings.mode = mode
	if mode == GameSettings.MODE_TOWER:
		get_tree().change_scene_to_file("res://scenes/TowerVariantSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/PlayerSelect.tscn")
