extends MarginContainer


@onready var fields = $Fields

var arena = null
var grids = {}


func set_attributes(input_: Dictionary) -> void:
	arena = input_.arena
	
	init_fields()
	unleash_defenders()


func init_fields() -> void:
	var n = 5
	fields.columns = n
	grids.all = []
	grids.corner = []
	grids.edge = []
	grids.center = []
	var corners = [0, n - 1]
	
	for _i in n:
		for _j in n:
			var input = {}
			input.battlefield = self
			input.grid = Vector2(_j, _i)
		
			var field = Global.scene.field.instantiate()
			fields.add_child(field)
			field.set_attributes(input)
			grids.all.append(input.grid)
			
			if corners.has(_i) or corners.has(_j):
				if corners.has(_i) and corners.has(_j):
					grids.corner.append(input.grid)
				else:
					grids.edge.append(input.grid)
			else:
				grids.center.append(input.grid)


func unleash_defenders() -> void:
	categorize_fields()


func categorize_fields() -> Array:
	for key in grids:
		print([key, grids[key].size()])
	
	var categorizeds = []
	var options = []
	options.append_array(grids.all)
	
	while !options.is_empty():
		var grid = options.pick_random()
		
		for _i in range(options.size()-1, -1, -1):
			var option = options[_i]
			categorizeds.append(option)
			
			if option.x == grid.x or option.y == grid.y:
				options.erase(option)
	
	return categorizeds
