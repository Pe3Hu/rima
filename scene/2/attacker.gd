extends MarginContainer


@onready var marker = $HBox/Marker

var swarm = null
var field = null
var role = null
var index = null


func set_attributes(input_: Dictionary) -> void:
	swarm = input_.swarm
	role = "attack"
	index = Global.num.index.attacker
	Global.num.index.attacker += 1
	
	marker.set_proprietor(self)
