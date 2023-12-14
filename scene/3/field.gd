extends MarginContainer


@onready var bg = $BG
@onready var marker = $Marker

var battlefield = null
var grid = null
var type = null
var status = null


func set_attributes(input_: Dictionary) -> void:
	battlefield = input_.battlefield
	grid = input_.grid
	type = input_.type
	
	var style = StyleBoxFlat.new()
	bg.set("theme_override_styles/panel", style)
	marker.set_field(self)
	custom_minimum_size = Global.vec.size.field
	reset()


func set_status(status_: String) -> void:
	status = status_
	
	var style = marker.bg.get("theme_override_styles/panel")
	style.bg_color = Global.color.field[status]


func reset() -> void:
	set_status("unselected")
