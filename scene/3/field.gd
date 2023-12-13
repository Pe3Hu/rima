extends MarginContainer


@onready var bg = $BG
@onready var marker = $Marker

var battlefield = null
var grid = null


func set_attributes(input_: Dictionary) -> void:
	battlefield = input_.battlefield
	grid = input_.grid
	
	custom_minimum_size = Global.vec.size.field
	marker.set_field(self)
