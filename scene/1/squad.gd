extends MarginContainer


@onready var defenders = $Defenders

var sketch = null
var battlefield = null
var selected = {}
var actives = []


func set_attributes(input_: Dictionary) -> void:
	sketch = input_.sketch
	
	selected.defender = null
	selected.spell = null
	init_defenders()


func init_defenders() -> void:
	for _i in 5:
		var input = {}
		input.squad = self
	
		var defender = Global.scene.defender.instantiate()
		defenders.add_child(defender)
		defender.set_attributes(input)


func shift_selected_defender(shift_: int) -> void:
	if selected.defender == null and !actives.is_empty():
		selected.defender = actives.back()
	
	if selected.defender != null:
		selected.defender.set_status("active")
		var index = (actives.find(selected.defender) + shift_ + actives.size()) % actives.size()
		selected.defender = actives[index]
		selected.defender.set_status("selected")
		shift_selected_spell(0)


func shift_selected_spell(shift_: int) -> void:
	if selected.defender != null:
		if selected.spell == null and !selected.defender.actives.is_empty():
			selected.spell = selected.defender.actives.back()
		
		if selected.spell != null:
			sketch.arena.battlefield.prepare_spell_coverage()
			selected.spell.set_status("active")
			var index = (selected.defender.actives.find(selected.spell) + shift_ + selected.defender.actives.size()) % selected.defender.actives.size()
			selected.spell = selected.defender.actives[index]
			sketch.arena.battlefield.prepare_spell_coverage()
			selected.spell.set_status("selected")


func reset() -> void:
	actives = []
	actives.append_array(defenders.get_children())
	
	for defender in defenders.get_children():
		defender.reset()
	
	shift_selected_defender(0)
