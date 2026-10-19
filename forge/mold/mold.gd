class_name Mold
extends Node2D

## Рисует Mold от локального (0, 0). Центр экрана задаёт родитель.

@export var is_interactive: bool = false
@export var ingot_scene: PackedScene
@export var piece_scene: PackedScene
@export var piece_side: Bozo.PieceSide = Bozo.PieceSide.NONE

var _layout_key: String = ""

var data: MoldData:
	set(value_):
		if data == value_:
			_on_changed()
			return
		if data != null and data.changed.is_connected(_on_changed):
			data.changed.disconnect(_on_changed)
		data = value_
		connect_datas()
		connect_signals()


func connect_datas() -> void:
	if data == null or not is_node_ready():
		return
	%Background.data = data


func connect_signals() -> void:
	if data == null:
		return
	if not data.changed.is_connected(_on_changed):
		data.changed.connect(_on_changed)
	_on_changed()


func _ready() -> void:
	_on_changed()


func _on_changed() -> void:
	if not is_node_ready():
		return
	var layout := _layout_key_of(data)
	if _layout_key != "" and layout == _layout_key and _refresh_figures():
		return
	init_layers()
	_layout_key = _layout_key_of(data)


func init_layers() -> void:
	init_ingots()
	init_pieces()


func init_ingots() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(%Ingots)
	if data == null or ingot_scene == null:
		return
	for item in data.ingots:
		var ingot_data := item as IngotData
		if ingot_data == null:
			continue
		var ingot := ingot_scene.instantiate() as Ingot
		%Ingots.add_child(ingot)
		ingot.data = ingot_data


func init_pieces() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(%Pieces)
	if data == null:
		return
	var ingot_map := {}
	var thickness_map := {}
	data.fill_cell_maps(ingot_map, thickness_map)
	for cell in data.coords:
		if not ingot_map.has(cell):
			continue
		var piece_data := PieceData.new()
		piece_data.init_cell(cell, int(thickness_map[cell]), ingot_map[cell], piece_side)
		add_piece(piece_data)


func add_piece(piece_data_: PieceData) -> void:
	if piece_scene == null:
		return
	var piece := piece_scene.instantiate() as Piece
	%Pieces.add_child(piece)
	piece.data = piece_data_


func _refresh_figures() -> bool:
	if data == null:
		return false
	var ingot_nodes := %Ingots.get_children()
	if ingot_nodes.size() != data.ingots.size():
		return false
	for index in data.ingots.size():
		var ingot_node := ingot_nodes[index] as Ingot
		var ingot_data := data.ingots[index] as IngotData
		if ingot_node == null or ingot_data == null:
			return false
		ingot_node.data = ingot_data
	var pieces := %Pieces.get_children()
	var ingot_map := {}
	var thickness_map := {}
	data.fill_cell_maps(ingot_map, thickness_map)
	var piece_index := 0
	for cell in data.coords:
		if not ingot_map.has(cell):
			continue
		if piece_index >= pieces.size():
			return false
		var piece := pieces[piece_index] as Piece
		piece_index += 1
		if piece == null or piece.data == null or piece.data.coord != cell:
			return false
		piece.data.ingot_data = ingot_map[cell]
		piece.data.thickness = int(thickness_map[cell])
	return piece_index == pieces.size()


func _layout_key_of(mold_data_: MoldData) -> String:
	if mold_data_ == null or mold_data_.template == null:
		return ""
	var parts: Array[String] = [str(mold_data_.template.get_instance_id())]
	for item in mold_data_.ingots:
		var ingot := item as IngotData
		if ingot == null:
			parts.append("-")
			continue
		var flipped := 0
		if ingot.is_flipped:
			flipped = 1
		parts.append("%d|%d|%d|%d|%d" % [ingot.shape, ingot.origin.x, ingot.origin.y, ingot.rotation_steps, flipped])
	return "\n".join(parts)


func get_piece_at_global(global_position_: Vector2) -> PieceData:
	if data == null:
		return null
	var local := to_local(global_position_)
	var span := float(Catalog.MOLD_CELL_SIZE)
	if span == 0.0:
		return null
	var cell := Vector2i(floori(local.x / span), floori(local.y / span))
	for child in %Pieces.get_children():
		var piece := child as Piece
		if piece == null or piece.data == null:
			continue
		if piece.data.coord == cell:
			return piece.data
	return null
