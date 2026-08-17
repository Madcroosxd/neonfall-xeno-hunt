class_name LevelUpUI
extends CanvasLayer

signal choice_selected(choice: Dictionary)
signal choice_skipped

@onready var overlay: Control = $Overlay
@onready var level_label: Label = $Overlay/Center/Layout/Level
@onready var skip_button: Button = $Overlay/Center/Layout/SkipButton
@onready var cards: Array[LevelUpCard] = [
	$Overlay/Center/Layout/Cards/Card1,
	$Overlay/Center/Layout/Cards/Card2,
	$Overlay/Center/Layout/Cards/Card3,
	$Overlay/Center/Layout/Cards/Card4,
]

var active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for card: LevelUpCard in cards:
		card.card_chosen.connect(_on_card_chosen)
	skip_button.pressed.connect(_on_skip_pressed)
	overlay.visible = false


func show_choices(level: int, choices: Array[Dictionary]) -> void:
	if choices.size() != cards.size():
		push_error("LevelUpUI tam olarak dört kart bekler.")
		return
	level_label.text = "LEVEL %02d  //  DEVRE YÜKSELTME" % level
	for index: int in range(cards.size()):
		cards[index].setup(choices[index])
	active = true
	overlay.visible = true
	get_tree().paused = true
	cards[0].grab_focus()


func force_close() -> void:
	active = false
	overlay.visible = false
	if get_tree() != null:
		get_tree().paused = false


func _on_card_chosen(choice: Dictionary) -> void:
	if not active:
		return
	active = false
	overlay.visible = false
	get_tree().paused = false
	choice_selected.emit(choice)


func _on_skip_pressed() -> void:
	if not active:
		return
	active = false
	overlay.visible = false
	get_tree().paused = false
	choice_skipped.emit()
