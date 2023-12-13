extends MarginContainer


@onready var marker = $HBox/Marker

var swarm = null
var field = null
var role = null
var index = null
var atk = {}
var hp = {}
var cd = {}



func set_attributes(input_: Dictionary) -> void:
	swarm = input_.swarm
	role = "attack"
	index = Global.num.index.attacker
	Global.num.index.attacker += 1
	
	atk.max = 1
	atk.current = int(atk.max)
	hp.max = 100
	hp.current = int(hp.max)
	cd.max = 6
	cd.current = int(cd.max)
	marker.set_proprietor(self)
