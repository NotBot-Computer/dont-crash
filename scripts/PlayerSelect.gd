extends Control

## Player count, plus the race-only single-player entry point. Which mode we
## are heading into was decided on the main menu (GameSettings.mode), and for
## Pile Up which variant on TowerVariantSelect (GameSettings.tower_variant).

const PixelUI := preload("res://scripts/PixelUI.gd")
const ModeCard := preload("res://scripts/ModeCard.gd")

# One card per count on offer, picked like the main menu's (CardRow:
# left/right, Enter, Esc back). Each card's preview shows that many players:
# in Don't Crash that many split-screen roads with a car each (the bot one
# tagged), in Pile Up that many strips with one brick falling in each.
@onready var row: Control = $Cards
var _options: Array[Dictionary] = [] # count, solo

func _ready() -> void:
	PixelUI.apply(self)
	add_child(PixelUI.key_badge("ESC  BACK"))
	add_child(PixelUI.key_badge("← →  CHOOSE   ENTER  OK", true))

	# Pile Up has no AI: BotDriver plays a PlayerBoard — it senses traffic in
	# an obstacle_container and steers between lane centres, none of which
	# exists in the tower mode. So the bot hints and the vs-BOT card are
	# race-only until a tower bot exists (docs/PROJECT_STATE.md §9). Co-op is
	# the only variant with no opponent, so in the tower a count of one is a
	# lone builder, offered only where the variant allows it.
	if not _tower():
		$Title.text = "HOW MANY PLAYERS?"
		$Hint.visible = true
		_add_option("1 PLAYER vs BOT", 2, true)
		for n in [2, 3, 4]:
			_add_option("%d PLAYERS" % n, n, false)
	else:
		var info: Dictionary = GameSettings.tower_pick_info()
		$Title.text = "%s — HOW MANY BUILDERS?" % info["title"]
		$Hint.visible = true
		$Hint.text = _cup_hint() if GameSettings.tower_cup != GameSettings.TOWER_CUP_NONE else _seating_hint(GameSettings.tower_variant)
		for n in [1, 2, 3, 4]:
			if (info["counts"] as Array).has(n):
				_add_option("1 BUILDER" if n == 1 else "%d PLAYERS" % n, n, false)
	row.chosen.connect(func(i: int): _select(_options[i]["count"], _options[i]["solo"]))
	row.back.connect(_on_back)
	row.select(0)

func _add_option(title: String, count: int, solo: bool) -> void:
	var card: Control = ModeCard.new()
	card.title = title
	card.count = count
	if _tower():
		card.kind = ModeCard.Kind.TOWERS
		card.one_at_a_time = true
	else:
		card.kind = ModeCard.Kind.ROADS
		card.bot_last = solo
	_options.append({"count": count, "solo": solo})
	row.add_card(card)

func _tower() -> bool:
	return GameSettings.mode == GameSettings.MODE_TOWER

# Teams are seats (GameSettings.tower_team_of), so the count screen is where a
# group finds out who they are playing with — before they pick colours.
func _seating_hint(variant: int) -> String:
	match variant:
		GameSettings.TOWER_TEAMS:
			return "Left team: P1 + P3      Right team: P2 + P4  (with three, P2 holds the right alone)"
		GameSettings.TOWER_COPILOT:
			return "Left crew: P1 + P3      Right crew: P2 + P4 — you swap steering and turning every brick"
		GameSettings.TOWER_COOP:
			return "Everyone builds one tower together, sharing one pool of lives"
		GameSettings.TOWER_RACE:
			return "Left tower: P1 (+ P3)      Right tower: P2 (+ P4)"
		GameSettings.TOWER_RACE_SOLO:
			return "A tower each, side by side, in seat order — and a hex always lands on whoever is highest"
	return "Every builder for themselves"

# A cup is several variants, so the line says what it is made of instead of
# how one of them is seated — and, in the team cup, the seats, which do not
# change between its rounds.
func _cup_hint() -> String:
	if GameSettings.tower_cup == GameSettings.TOWER_CUP_TEAM:
		return "Left team: P1 + P3      Right team: P2 + P4 — winning a round is 3 trophies, losing it none, first to %d" % GameSettings.CUP_TARGET
	return "Free for all, a race, then co-op, and round again — 1st 3 trophies, 2nd 2, 3rd 1, first to %d" % GameSettings.CUP_TARGET

# `solo` is the race's single-player entry point: that mode is a race between
# boards, so there has to be something to race — it is really "two boards, one
# of them driven by BotDriver", which is why its card shows two roads. Any other slot can still be turned over to a
# bot from SkinSelect (the 1-4 keys), including all of them at once if you
# just want to watch.
func _select(count: int, solo: bool = false) -> void:
	GameSettings.player_count = count
	GameSettings.clear_bots()
	if solo and GameSettings.mode == GameSettings.MODE_RACE:
		GameSettings.set_bot(1, true)
	get_tree().change_scene_to_file("res://scenes/SkinSelect.tscn")

func _on_back() -> void:
	if _tower():
		get_tree().change_scene_to_file("res://scenes/TowerVariantSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
