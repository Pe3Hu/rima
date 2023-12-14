extends MarginContainer


@onready var bg = $BG
@onready var role = $Role
@onready var index = $Index
@onready var hp = $HP
@onready var atk = $ATK
@onready var cd = $CD

var proprietor = null
var field = null


func _ready() -> void:
	var style = StyleBoxFlat.new()
	bg.set("theme_override_styles/panel", style)
	custom_minimum_size = Vector2(Global.vec.size.field)


func set_field(field_: MarginContainer) -> void:
	field = field_


func set_proprietor(proprietor_: MarginContainer) -> void:
	proprietor = proprietor_
	
	if field != null:
		proprietor.field = field
		
		if proprietor.role == "defense":
			var style = bg.get("theme_override_styles/panel")
			style.bg_color = Global.color.defender[proprietor.status]
	
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

