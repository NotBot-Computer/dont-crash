extends Control

## Mode picker. GameSettings.mode is set here and then read by PlayerSelect
## (which hides the race-only single-player option) and by SkinSelect (which
## decides which scene to hand off to). Nothing downstream re-derives it.
## Pile Up goes through one more screen first — TowerVariantSelect, which
## picks the solo or the team cup.
##
## Two big cards side by side, one per mode, each with a live preview of its
## mode that runs while it is the selected one (ModeCard, in a CardRow).
## Driven by the keyboard alone: left/right choose, Enter (or Space) plays;
## the mouse does nothing here. Coming back from a mode's screens, that mode
## is the one selected.
##
## The rest of the look (the pixel font, the brick rain and the brick title)
## is shared by every menu screen — see PixelUI.

const PixelUI := preload("res://scripts/PixelUI.gd")
const ModeCard := preload("res://scripts/ModeCard.gd")

@onready var row: Control = $Cards

func _ready() -> void:
	PixelUI.apply(self)
	row.add_card(_card(ModeCard.Kind.RACE, "DON'T CRASH"))
	row.add_card(_card(ModeCard.Kind.TOWER, "PILE UP"))
	row.chosen.connect(func(i: int): _play(GameSettings.MODE_TOWER if i == 1 else GameSettings.MODE_RACE))
	row.select(1 if GameSettings.mode == GameSettings.MODE_TOWER else 0)

func _card(kind: int, title: String) -> Control:
	var c: Control = ModeCard.new()
	c.kind = kind
	c.title = title
	return c

func _play(mode: int) -> void:
	GameSettings.mode = mode
	if mode == GameSettings.MODE_TOWER:
		get_tree().change_scene_to_file("res://scenes/TowerVariantSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/PlayerSelect.tscn")
