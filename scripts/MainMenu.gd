extends Control

## Title screen: the name in brick letters and one big card with a live
## preview of the road (ModeCard RACE, in a CardRow). Enter (or Space) goes
## on to the player count; the mouse does nothing here.
##
## This used to be a mode picker with a second card for Pile Up, the tower
## mode; that game now lives in its own repository (docs/PROJECT_STATE.md §0).
##
## The rest of the look (the pixel font, the brick rain and the brick title)
## is shared by every menu screen — see PixelUI.

const PixelUI := preload("res://scripts/PixelUI.gd")
const ModeCard := preload("res://scripts/ModeCard.gd")

@onready var row: Control = $Cards

func _ready() -> void:
	PixelUI.apply(self)
	var c: Control = ModeCard.new()
	c.kind = ModeCard.Kind.RACE
	c.title = "PLAY"
	row.add_card(c)
	row.chosen.connect(func(_i: int): get_tree().change_scene_to_file("res://scenes/PlayerSelect.tscn"))
	row.select(0)
