extends MarginContainer


@onready var fields = $Fields

var arena = null
var grids = {}


func set_attributes(input_: Dictionary) -> void:
	arena = input_.arena
	arena.squad.battlefield = self
	
	init_fields()
	unleash_defenders()
	unleash_attackers()
	arena.squad.reset()


func init_fields() -> void:
	var n = 5
	fields.columns = n
	grids.all = []
	grids.corner = []
	grids.edge = []
	grids.center = []
	grids.free = []
	var corners = [0, n - 1]
	
	for _i in n:
		for _j in n:
			var input = {}
			input.battlefield = self
			input.grid = Vector2(_j, _i)
			
			if corners.has(_i) or corners.has(_j):
				if corners.has(_i) and corners.has(_j):
					input.type = "corner"
				else:
					input.type = "edge"
			else:
				input.type = "center"
			
			var field = Global.scene.field.instantiate()
			fields.add_child(field)
			field.set_attributes(input)
			grids[input.type].append(input.grid)
			grids.all.append(input.grid)


func unleash_defenders() -> void:
	grids.free = []
	grids.free.append_array(grids.all)
	var _grids = get_grids_for_defenders()
	
	for _i in _grids.size():
		var grid = _grids[_i]
		var field = get_field(grid)
		var defender = arena.squad.defenders.get_child(_i)
		field.marker.set_proprietor(defender)


func get_grids_for_defenders() -> Array:
	var result = []
	var options = []
	options.append_array(grids.all)
	
	while !options.is_empty():
		var grid = options.pick_random()
		result.append(grid)
		grids.free.erase(grid)
		
		for _i in range(options.size()-1, -1, -1):
			var option = options[_i]
			
			if option.x == grid.x or option.y == grid.y:
				options.erase(option)
	
	return result


func get_field(grid_: Vector2) -> MarginContainer:
	var index = grid_.y * fields.columns + grid_.x
	return fields.get_child(index)


func unleash_attackers() -> void:
	arena.swarm.replenish()
	var _grids = get_grids_for_attackers()
	
	for _i in _grids.size():
		var grid = _grids[_i]
		var field = get_field(grid)
		var attacker = arena.swarm.attackers.get_child(_i)
		field.marker.set_proprietor(attacker)


func get_grids_for_attackers() -> Array:
	var result = []
	var n = min(arena.swarm.attackers.get_child_count(), grids.free.size())
	
	for _i in n:
		var grid = grids.free.pick_random()
		result.append(grid)
		grids.free.erase(grid)
	
	return result


func prepare_spell_coverage() -> void:
	var spell = arena.squad.selected.spell
	var defender = arena.squad.selected.defender
	
	if Global.dict.pattern.types[spell.letter.subtype].has(defender.field.type):
		if spell.coverage.is_empty():
			for icon in spell.directions.get_children():
				for direction in Global.dict.directions[icon.subtype]:
					var grid = defender.field.grid
					
					while boundary_check(grid):
						if grid != defender.field.grid:
							spell.coverage.append(grid)
						
						grid += direction


func boundary_check(grid_: Vector2) -> bool:
	return grid_.x >= 0 and grid_.y >= 0 and grid_.x < fields.columns and grid_.y < fields.columns
