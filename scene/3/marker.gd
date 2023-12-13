extends MarginContainer


@onready var bg = $BG
@onready var role = $Role
@onready var index = $Index
@onready var hp = $HP
@onready var atk = $ATK
@onready var cd = $CD

var proprietor = null
var field = null


func set_field(field_: MarginContainer) -> void:
	field = field_
	var style = StyleBoxFlat.new()
	field.bg.set("theme_override_styles/panel", style)


func set_proprietor(proprietor_: MarginContainer) -> void:
	proprietor = proprietor_
	
	if field != null:
		var style = field.bg.get("theme_override_styles/panel")
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
	
	if proprietor.role == "attack":
		for type in Global.arr.parameter:
			input.subtype = proprietor[type].current
			var icon = get(type)
			icon.set_attributes(input)
			icon.custom_minimum_size = Vector2(Global.vec.size.sixteen)
			icon.visible = true
	
	#role.set("theme_override_constants/margin_left", 4)
	#role.set("theme_override_constants/margin_top", 4)
	custom_minimum_size = Vector2(Global.vec.size.field)

