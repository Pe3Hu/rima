extends MarginContainer


@onready var defenders = $Defenders

var sketch = null


func set_attributes(input_: Dictionary) -> void:
	sketch = input_.sketch
	
	init_defenders()


func init_defenders() -> void:
	for _i in 5:
		var input = {}
		input.squad = self
	
		var defender = Global.scene.defender.instantiate()
		defenders.add_child(defender)
		defender.set_attributes(input)

