extends MarginContainer


@onready var reserves = $HBox/Reserves
@onready var attackers = $HBox/Attackers

var arena = null
var limit = 12


func set_attributes(input_: Dictionary) -> void:
	arena = input_.arena
	
	init_reserves()


func init_reserves() -> void:
	for _i in limit:
		var input = {}
		input.swarm = self
	
		var attacker = Global.scene.attacker.instantiate()
		reserves.add_child(attacker)
		attacker.set_attributes(input)
	
	update_columns()


func update_columns() -> void:
	attackers.columns = ceil(limit/5)


func replenish() -> void:
	var n = limit - attackers.get_child_count()
	
	for _i in n:
		var attacker = reserves.get_child(0)
		reserves.remove_child(attacker)
		attackers.add_child(attacker)
