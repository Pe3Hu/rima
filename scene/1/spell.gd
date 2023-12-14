extends MarginContainer


@onready var bg = $BG
@onready var letter = $HBox/Letter
@onready var damage = $HBox/Damage
@onready var cooldown = $HBox/Cooldown
@onready var directions = $HBox/Directions

var defender = null
var status = null
var coverage = []


func set_attributes(input_: Dictionary) -> void:
	defender = input_.defender
	
	var style = StyleBoxFlat.new()
	bg.set("theme_override_styles/panel", style)
	
	update_icons(input_)


func update_icons(input_: Dictionary) -> void:
	var input = {}
	input.proprietor = self
	input.type = "letter"
	input.subtype = input_.letter
	letter.set_attributes(input)
	
	for direction in input_.directions:
		input.subtype = direction
		
		var icon = Global.scene.icon.instantiate()
		directions.add_child(icon)
		icon.set_attributes(input)
	
	var keys = ["damage", "cooldown"]
	
	for key in keys:
		var couple = get(key)
		input.type = key
		input.subtype = "standard"
		input.value = input_[key]
		couple.set_attributes(input)


func set_status(status_: String) -> void:
	status = status_
	
	var style = bg.get("theme_override_styles/panel")
	style.bg_color = Global.color.spell[status]
	
	match status:
		"inactive":
			defender.actives.erase(self)
			coverage = []
		"selected":
			paint_coverage("selected")
		"active":
			paint_coverage("unselected")


func paint_coverage(status_: String) -> void:
	for grid in coverage:
		var field = defender.squad.battlefield.get_field(grid)
		field.set_status(status_)


func reset() -> void:
	coverage = []
	set_status("active")
