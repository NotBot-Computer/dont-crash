extends Control

## A row of ModeCards picked with the keyboard alone: left/right move the
## selection, Enter (ui_accept — also keypad Enter and Space) chooses, Esc
## (ui_cancel) goes back. The mouse does nothing. Used by every menu screen
## that offers a choice: the main menu and the player count.
##
## Cards are laid out centred across the row's width, `card_size` each,
## `gap` apart, top-aligned. Build a card with ModeCard.new(), set its
## exports, then add_card() it — the card builds its preview from its size,
## so the size is set before it enters the tree.
##
## Once Enter or Esc has been acted on the row stops listening, so a second
## press in the same frame cannot change scene twice.

signal chosen(index: int)
signal selection_changed(index: int)
signal back

const ModeCard := preload("res://scripts/ModeCard.gd")

@export var card_size := Vector2(408, 522)
@export var gap := 72.0
@export var allow_back := true

var cards: Array[Control] = []
var choice := 0
var _done := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)

func add_card(card: Control) -> void:
	card.size = card_size
	add_child(card)
	cards.append(card)
	_layout()

func _layout() -> void:
	var n: int = cards.size()
	var total: float = card_size.x * float(n) + gap * float(maxi(0, n - 1))
	var x: float = floorf((size.x - total) * 0.5)
	for c in cards:
		c.position = Vector2(x, 0.0)
		x += card_size.x + gap

func select(i: int) -> void:
	if cards.is_empty():
		return
	choice = clampi(i, 0, cards.size() - 1)
	for k in range(cards.size()):
		cards[k].selected = k == choice
	selection_changed.emit(choice)

func _unhandled_input(event: InputEvent) -> void:
	if _done or cards.is_empty() or not is_inside_tree():
		return
	if event.is_action_pressed("ui_left"):
		select(choice - 1)
	elif event.is_action_pressed("ui_right"):
		select(choice + 1)
	elif event.is_action_pressed("ui_accept"):
		_done = true
		chosen.emit(choice)
	elif allow_back and event.is_action_pressed("ui_cancel"):
		_done = true
		back.emit()
	else:
		return
	# Choosing can take the row out of the tree (a scene change, or a
	# screen freed mid-event), so the viewport may already be gone.
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.set_input_as_handled()
