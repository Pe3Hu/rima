extends MarginContainer


@onready var bg = $BG
@onready var role = $Role
@onready var index = $Index

var proprietor = null
var field = null


func set_attributes(input_: Dictionary) -> void:
	proprietor = input_.proprietor
	field = input_.field


func set_proprietor(proprietor_: MarginContainer) -> void:
	proprietor = proprietor_
	
	if field != null:
		var style = field.get("theme_override_styles/panel")
		style.bg_color = Global.color.role[proprietor.role]
	
	update_icons()


func update_icons() -> void:
	var input = {}
	input.type = "role"
	input.subtype = proprietor.role
	role.set_attributes(input)
	role.custom_minimum_size = Vector2(Global.vec.size.role)
	
	input.type = "number"
	input.subtype = proprietor.index
	index.set_attributes(input)
	index.custom_minimum_size = Vector2(Global.vec.size.sixteen)

	role.set("theme_override_constants/margin_left", 4)
	role.set("theme_override_constants/margin_top", 4)
	custom_minimum_size = role.custom_minimum_size + index.custom_minimum_size * 0.75

