extends MarginContainer


@onready var marker = $HBox/Marker

var squad = null
var field = null
var role = null
var index = null


func set_attributes(input_: Dictionary) -> void:
	squad = input_.squad
	role = "defense"
	index = Global.num.index.attacker
	Global.num.index.attacker += 1
	
	marker.set_proprietor(self)
