extends MarginContainer


@onready var swarm = $HBox/Swarm
@onready var battlefield = $HBox/Battlefield

var sketch = null
var squad = null


func set_attributes(input_: Dictionary) -> void:
	sketch = input_.sketch
	squad = sketch.squad
	
	var input = {}
	input.arena = self
	swarm.set_attributes(input)
	battlefield.set_attributes(input)
