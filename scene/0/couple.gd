extends MarginContainer


@onready var title = $Title
@onready var stack = $Stack

var proprietor = null


func set_attributes(input_: Dictionary) -> void:
	proprietor = input_.proprietor
	
	var input = {}
	input.type = input_.type
	input.subtype = input_.subtype
	title.set_attributes(input)
	stack.custom_minimum_size = Vector2(Global.vec.size.spell)
	
	input = {}
	input.type = "number"
	input.subtype = input_.value
	stack.set_attributes(input)
	stack.custom_minimum_size = Vector2(Global.vec.size.sixteen)

	#title.set("theme_override_constants/margin_left", 4)
	#title.set("theme_override_constants/margin_top", 4)
	custom_minimum_size = title.custom_minimum_size + stack.custom_minimum_size * 0.75
