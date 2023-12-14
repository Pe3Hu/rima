extends Node


var rng = RandomNumberGenerator.new()
var arr = {}
var num = {}
var vec = {}
var color = {}
var dict = {}
var flag = {}
var node = {}
var scene = {}


func _ready() -> void:
	init_arr()
	init_num()
	init_vec()
	init_color()
	init_dict()
	init_node()
	init_scene()


func init_arr() -> void:
	arr.edge = [1, 2, 3, 4, 5, 6]
	arr.parameter = ["hp", "atk", "cd"]
	arr.spell = ["letter", "damage", "cooldown"]


func init_num() -> void:
	num.index = {}
	num.index.attacker = 0
	num.index.defender = 0


func init_dict() -> void:
	init_neighbor()
	init_pattern()
	


func init_neighbor() -> void:
	dict.neighbor = {}
	dict.neighbor.linear3 = [
		Vector3( 0, 0, -1),
		Vector3( 1, 0,  0),
		Vector3( 0, 0,  1),
		Vector3(-1, 0,  0)
	]
	dict.neighbor.linear2 = [
		Vector2( 0,-1),
		Vector2( 1, 0),
		Vector2( 0, 1),
		Vector2(-1, 0)
	]
	dict.neighbor.diagonal = [
		Vector2( 1,-1),
		Vector2( 1, 1),
		Vector2(-1, 1),
		Vector2(-1,-1)
	]
	dict.neighbor.zero = [
		Vector2( 0, 0),
		Vector2( 1, 0),
		Vector2( 1, 1),
		Vector2( 0, 1)
	]
	dict.neighbor.hex = [
		[
			Vector2( 1,-1), 
			Vector2( 1, 0), 
			Vector2( 0, 1), 
			Vector2(-1, 0), 
			Vector2(-1,-1),
			Vector2( 0,-1)
		],
		[
			Vector2( 1, 0),
			Vector2( 1, 1),
			Vector2( 0, 1),
			Vector2(-1, 1),
			Vector2(-1, 0),
			Vector2( 0,-1)
		]
	]


func init_pattern() -> void:
	dict.directions = {}
	dict.directions["d"] = [Vector2(1, 0), Vector2(-1, 0)]
	dict.directions["q"] = [Vector2(1, 1), Vector2(-1, -1)]
	dict.directions["b"] = [Vector2(0, 1), Vector2(0, -1)]
	dict.directions["p"] = [Vector2(-1, 1), Vector2(1, -1)]
	
	dict.pattern = {}
	dict.pattern.index = {}
	dict.pattern.types = {}
	dict.pattern.mirrors = [0, 1, 2, 3, 4, 5, 9]
	
	var path = "res://asset/json/rima_pattern.json"
	var array = load_data(path)
	
	for pattern in array:
		var data = {}
		
		for key in pattern:
			if key != "index":
				data[key] = pattern[key]
		
		dict.pattern.index[pattern.index] = data
		
		if !dict.pattern.types.has(pattern.title):
			dict.pattern.types[pattern.title] = []
		
		dict.pattern.types[pattern.title].append(pattern.type)


func init_node() -> void:
	node.game = get_node("/root/Game")


func init_scene() -> void:
	scene.icon = load("res://scene/0/icon.tscn")
	scene.defender = load("res://scene/1/defender.tscn")
	scene.spell = load("res://scene/1/spell.tscn")
	scene.attacker = load("res://scene/2/attacker.tscn")
	scene.field = load("res://scene/3/field.tscn")


func init_vec():
	vec.size = {}
	vec.size.letter = Vector2(20, 20)
	vec.size.icon = Vector2(48, 48)
	vec.size.number = Vector2(5, 32)
	vec.size.sixteen = Vector2(16, 16)
	
	vec.size.aspect = Vector2(32, 32)
	vec.size.box = Vector2(100, 100)
	vec.size.bar = Vector2(120, 12)
	
	vec.size.field = Vector2(64, 64)
	vec.size.role = Vector2(32, 32)
	vec.size.spell = Vector2(48, 48)
	
	init_window_size()


func init_window_size():
	vec.size.window = {}
	vec.size.window.width = ProjectSettings.get_setting("display/window/size/viewport_width")
	vec.size.window.height = ProjectSettings.get_setting("display/window/size/viewport_height")
	vec.size.window.center = Vector2(vec.size.window.width/2, vec.size.window.height/2)


func init_color():
	var h = 360.0
	
	color.role = {}
	color.role.attack = Color.from_hsv(0 / h, 0.39, 0.7)
	color.role.defense = Color.from_hsv(210 / h, 0.39, 0.7)
	
	color.defender = {}
	color.defender.active = Color.from_hsv(120 / h, 0.6, 0.7)
	color.defender.selected = Color.from_hsv(270 / h, 0.6, 0.7)
	color.defender.inactive = Color.from_hsv(30 / h, 0.6, 0.7)
	
	color.spell = {}
	color.spell.active = Color.from_hsv(210 / h, 0.6, 0.7)
	color.spell.selected = Color.from_hsv(270 / h, 0.6, 0.7)
	color.spell.inactive = Color.from_hsv(60 / h, 0.6, 0.7)
	
	color.field = {}
	color.field.selected = Color.from_hsv(0 / h, 0.4, 0.7)
	color.field.unselected = Color.from_hsv(60 / h, 0.2, 0.7)


func save(path_: String, data_: String):
	var path = path_ + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(data_)


func load_data(path_: String):
	var file = FileAccess.open(path_, FileAccess.READ)
	var text = file.get_as_text()
	var json_object = JSON.new()
	var parse_err = json_object.parse(text)
	return json_object.get_data()


func get_random_key(dict_: Dictionary):
	if dict_.keys().size() == 0:
		print("!bug! empty array in get_random_key func")
		return null
	
	var total = 0
	
	for key in dict_.keys():
		total += dict_[key]
	
	rng.randomize()
	var index_r = rng.randf_range(0, 1)
	var index = 0
	
	for key in dict_.keys():
		var weight = float(dict_[key])
		index += weight/total
		
		if index > index_r:
			return key
	
	print("!bug! index_r error in get_random_key func")
	return null
