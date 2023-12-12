extends MarginContainer


@onready var squad = $HBox/Squad
@onready var arena = $HBox/Arena


func _ready() -> void:
	var input = {}
	input.sketch = self
	squad.set_attributes(input)
	arena.set_attributes(input)
