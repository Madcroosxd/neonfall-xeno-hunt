class_name LevelUpCard
extends Button

signal card_chosen(choice: Dictionary)

const RARITY_COLORS: Dictionary = {
	"common": Color("d9e0eb"),
	"rare": Color("43c8ff"),
	"epic": Color("c66cff"),
}
const SPACE_WEAPON_ATLAS: Texture2D = preload("res://assets/generated/space_weapon_atlas_v1.png")
const ATLAS_COLUMNS: int = 4
const ATLAS_ROWS: int = 3

@onready var icon_view: BuffIcon = $Margin/Content/Icon
@onready var weapon_preview: TextureRect = $Margin/Content/WeaponPreview
@onready var rarity_label: Label = $Margin/Content/Rarity
@onready var name_label: Label = $Margin/Content/Name
@onready var description_label: Label = $Margin/Content/Description
@onready var stack_label: Label = $Margin/Content/Stack

var choice: Dictionary = {}


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(new_choice: Dictionary) -> void:
	choice = new_choice.duplicate(true)
	var is_weapon_choice: bool = String(choice.get("choice_kind", "buff")) == "weapon"
	var rarity: String = String(choice.get("rarity", "common"))
	var color: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	rarity_label.text = String(choice.get("rarity_label", rarity.to_upper()))
	rarity_label.modulate = color
	name_label.text = String(choice.get("name", "BUFF"))
	description_label.text = String(choice.get("description", ""))
	icon_view.visible = not is_weapon_choice
	weapon_preview.visible = is_weapon_choice
	if is_weapon_choice:
		weapon_preview.texture = _build_weapon_texture(int(choice.get("atlas_index", 0)))
		stack_label.text = "%s YUVASI  •  YUVAYI AÇ" % String(choice.get("slot_label", "SİLAH"))
	else:
		stack_label.text = "DEVRE %d / %d" % [int(choice.get("next_stack", 1)), int(choice.get("max_stacks", 1))]
		icon_view.set_icon(String(choice.get("icon", "damage")), color)
	_apply_style(color)
	disabled = false


func _build_weapon_texture(index: int) -> AtlasTexture:
	var cell_width: float = float(SPACE_WEAPON_ATLAS.get_width()) / float(ATLAS_COLUMNS)
	var base_cell_height: int = SPACE_WEAPON_ATLAS.get_height() / ATLAS_ROWS
	var column: int = index % ATLAS_COLUMNS
	var row: int = floori(float(index) / float(ATLAS_COLUMNS))
	var region_height: int = base_cell_height if row < ATLAS_ROWS - 1 else SPACE_WEAPON_ATLAS.get_height() - base_cell_height * row
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = SPACE_WEAPON_ATLAS
	atlas_texture.region = Rect2(float(column) * cell_width, float(row * base_cell_height), cell_width, float(region_height))
	return atlas_texture


func _apply_style(color: Color) -> void:
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color(0.025, 0.038, 0.085, 0.98)
	normal.border_color = color
	normal.set_border_width_all(3)
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_left = 14
	normal.corner_radius_bottom_right = 14
	normal.shadow_color = Color(color, 0.25)
	normal.shadow_size = 10
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.055, 0.075, 0.15, 1.0)
	hover.border_color = color.lightened(0.2)
	hover.shadow_color = Color(color, 0.5)
	hover.shadow_size = 16
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	add_theme_stylebox_override("focus", hover)


func _on_pressed() -> void:
	if not choice.is_empty():
		disabled = true
		card_chosen.emit(choice.duplicate(true))
