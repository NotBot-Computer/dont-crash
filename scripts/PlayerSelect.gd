extends Control

## Player count, plus the single-player entry point.

const PixelUI := preload("res://scripts/PixelUI.gd")
const ModeCard := preload("res://scripts/ModeCard.gd")

# One card per count on offer, picked like the main menu's (CardRow:
# left/right, Enter, Esc back). Each card's preview shows that many
# split-screen roads with a car each (the bot one tagged).
@onready var row: Control = $Cards
var _options: Array[Dictionary] = [] # count, solo

func _ready() -> void:
	PixelUI.apply(self)
	add_child(PixelUI.key_badge("ESC  BACK"))
	add_child(PixelUI.key_badge("← →  CHOOSE   ENTER  OK", true))

	_add_option("1 PLAYER vs BOT", 2, true)
	for n in [2, 3, 4]:
		_add_option("%d PLAYERS" % n, n, false)
	row.chosen.connect(func(i: int): _select(_options[i]["count"], _options[i]["solo"]))
	row.back.connect(_on_back)
	row.select(0)

func _add_option(title: String, count: int, solo: bool) -> void:
	var card: Control = ModeCard.new()
	card.title = title
	card.count = count
	card.kind = ModeCard.Kind.ROADS
	card.bot_last = solo
	_options.append({"count": count, "solo": solo})
	row.add_card(card)

# `solo` is the single-player entry point: the game is a race between
# boards, so there has to be something to race — it is really "two boards, one
# of them driven by BotDriver", which is why its card shows two roads. Any other slot can still be turned over to a
# bot from SkinSelect (the 1-4 keys), including all of them at once if you
# just want to watch.
func _select(count: int, solo: bool = false) -> void:
	GameSettings.player_count = count
	GameSettings.clear_bots()
	if solo:
		GameSettings.set_bot(1, true)
	get_tree().change_scene_to_file("res://scenes/SkinSelect.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
