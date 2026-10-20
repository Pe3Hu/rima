class_name Stratum
extends Node2D

## Пустой контейнер stratum'а. Подсветку клеток включает Mold.

signal fulcrum_pressed(stratum_: StratumData)

@export var fulcrum_scene: PackedScene

var data: StratumData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_fulcrum()


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	pass


func init_fulcrum() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(self)
	if data == null or data.fulcrum == null or fulcrum_scene == null:
		return
	var fulcrum := fulcrum_scene.instantiate() as Fulcrum
	add_child(fulcrum)
	fulcrum.pressed.connect(_on_fulcrum_pressed)
	fulcrum.data = data.fulcrum


func _ready() -> void:
	init_fulcrum()


func get_fulcrum() -> Fulcrum:
	if get_child_count() == 0:
		return null
	return get_child(0) as Fulcrum


func _on_fulcrum_pressed() -> void:
	if data == null:
		return
	fulcrum_pressed.emit(data)
