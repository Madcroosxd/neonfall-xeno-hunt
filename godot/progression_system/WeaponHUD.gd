class_name WeaponHUD
extends CanvasLayer

const RARITY_COLORS: Dictionary = {
	"common": Color("d9e0eb"), "rare": Color("43c8ff"), "epic": Color("c66cff"),
}
const SLOT_LABELS: Dictionary = {
	1: "ANA", 2: "ALAN", 3: "TAKTİK", 4: "AĞIR",
}

@export_node_path("Node") var player_path: NodePath

@onready var player: ModularRobotPlayer = get_node(player_path) as ModularRobotPlayer

var slot_panels: Dictionary = {}
var slot_name_labels: Dictionary = {}
var slot_icon_labels: Dictionary = {}


func _ready() -> void:
	layer = 9
	_build_ui()
	if player != null:
		player.loadout_ready.connect(_on_loadout_ready)
		call_deferred("_refresh_from_player")


func _refresh_from_player() -> void:
	if player != null:
		_on_loadout_ready(player.get_weapon_inventory())


func _build_ui() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var row: HBoxContainer = HBoxContainer.new()
	row.name = "WeaponRow"
	row.position = Vector2(22, 186)
	row.add_theme_constant_override("separation", 8)
	root.add_child(row)

	for slot: int in range(1, 5):
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(78, 92)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.02, 0.035, 0.08, 0.92)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = RARITY_COLORS["common"]
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		panel.add_theme_stylebox_override("panel", style)
		row.add_child(panel)

		var margin: MarginContainer = MarginContainer.new()
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 4)
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
		panel.add_child(margin)

		var inner: VBoxContainer = VBoxContainer.new()
		inner.add_theme_constant_override("separation", 2)
		margin.add_child(inner)

		var tag_label: Label = Label.new()
		tag_label.text = String(SLOT_LABELS.get(slot, "?"))
		tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag_label.add_theme_font_size_override("font_size", 10)
		tag_label.add_theme_color_override("font_color", Color(0.55, 0.68, 0.82, 0.85))
		inner.add_child(tag_label)

		var icon_label: Label = Label.new()
		icon_label.text = "--"
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 20)
		icon_label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1.0))
		inner.add_child(icon_label)

		var name_label: Label = Label.new()
		name_label.text = "Boş"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.custom_minimum_size = Vector2(70, 26)
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Color(0.78, 0.88, 0.98, 0.95))
		inner.add_child(name_label)

		slot_panels[slot] = style
		slot_icon_labels[slot] = icon_label
		slot_name_labels[slot] = name_label


func _on_loadout_ready(loadout: Dictionary) -> void:
	for slot: int in range(1, 5):
		var weapon_id: String = String(loadout.get(slot, ""))
		var style: StyleBoxFlat = slot_panels.get(slot) as StyleBoxFlat
		var icon_label: Label = slot_icon_labels.get(slot) as Label
		var name_label: Label = slot_name_labels.get(slot) as Label
		if weapon_id.is_empty() or not WeaponManager.WEAPON_DATABASE.has(weapon_id):
			if style != null: style.border_color = RARITY_COLORS["common"]
			if icon_label != null: icon_label.text = "--"
			if name_label != null: name_label.text = "Boş"
			continue
		var definition: Dictionary = WeaponManager.WEAPON_DATABASE[weapon_id]
		var rarity: String = String(definition.get("rarity", "common"))
		var color: Color = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
		if style != null:
			style.border_color = color
			style.shadow_color = Color(color, 0.22)
			style.shadow_size = 6
		if icon_label != null:
			icon_label.text = String(definition.get("icon", "W"))
			icon_label.add_theme_color_override("font_color", color)
		if name_label != null:
			name_label.text = String(definition.get("display_name", weapon_id))
