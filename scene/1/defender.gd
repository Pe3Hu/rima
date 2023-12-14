extends MarginContainer


@onready var marker = $HBox/Marker
@onready var spells = $HBox/Spells

var squad = null
var field = null
var role = null
var index = null
var status = null
var actives = []


func set_attributes(input_: Dictionary) -> void:
	squad = input_.squad
	role = "defense"
	index = Global.num.index.defender
	Global.num.index.defender += 1
	
	status = "active"
	marker.set_proprietor(self)
	init_spells()


func init_spells() -> void:
	var damage = 10
	var cooldown = 4
	var letters = {}
	letters["i"] = ["d", "b"]
	letters["l"] = ["q", "p"]
	
	for letter in letters:
		for direction in letters[letter]:
			var input = {}
			input.defender = self
			input.letter = letter
			input.directions = [direction]
			input.damage = damage
			input.cooldown = cooldown
		
			var spell = Global.scene.spell.instantiate()
			spells.add_child(spell)
			spell.set_attributes(input)


func set_status(status_: String) -> void:
	status = status_
	
	if role == "defense":
		var style = marker.bg.get("theme_override_styles/panel")
		style.bg_color = Global.color.defender[status]
		style = field.marker.bg.get("theme_override_styles/panel")
		style.bg_color = Global.color.defender[status]
	
	if status == "inactive":
		squad.actives.erase(self)


func reset() -> void:
	actives = []
	actives.append_array(spells.get_children())
	
	for spell in spells.get_children():
		spell.set_status("active")
	
	set_status("active")
