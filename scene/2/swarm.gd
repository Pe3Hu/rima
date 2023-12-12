extends MarginContainer


@onready var attackers = $Attackers

var arena = null


func set_attributes(input_: Dictionary) -> void:
	arena = input_.arena
	
	init_attackers()


func init_attackers() -> void:
	for _i in 15:
		var input = {}
		input.swarm = self
	
		var attacker = Global.scene.attacker.instantiate()
		attackers.add_child(attacker)
		attacker.set_attributes(input)
