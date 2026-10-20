class_name Piece
extends Node2D

## Показывает толщину по центру клетки. Подсветку включает Mold.
## Общий LabelSettings из сцены не мутируется: у каждой клетки своя копия.

var is_selected: bool = false:
	set(value_):
		if is_selected == value_:
			return
		is_selected = value_
		_show_thickness()

var is_highlighted: bool = false:
	set(value_):
		if is_highlighted == value_:
			return
		is_highlighted = value_
		_show_thickness()

var data: PieceData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		_show_thickness()

var _outline: LabelSettings
var _base_outline_size: int = 10
var _base_outline_color: Color = Color(0.102, 0.102, 0.102, 1)


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	if data != null and not data.thickness_changed.is_connected(_show_thickness):
		data.thickness_changed.connect(_show_thickness)
	_show_thickness()


func _show_thickness() -> void:
	if not is_node_ready() or data == null:
		return
	var span := float(Catalog.MOLD_CELL_SIZE)
	var center := Vector2(data.coord) * span + Vector2(span, span) * 0.5
	%ThicknessLabel.position = center - Vector2(span, span) * 0.5
	%ThicknessLabel.size = Vector2(span, span)
	%ThicknessLabel.text = str(data.thickness)
	var settings := _ensure_outline()
	var color := _base_outline_color
	if is_highlighted:
		color = Digest.stratum_highlight_color
	elif is_selected:
		color = Digest.selection_color
	settings.outline_color = color
	settings.outline_size = _base_outline_size


func _ensure_outline() -> LabelSettings:
	if _outline != null:
		return _outline
	var source: LabelSettings = %ThicknessLabel.label_settings
	if source == null:
		_outline = LabelSettings.new()
	else:
		_outline = source.duplicate()
		_base_outline_size = _outline.outline_size
		_base_outline_color = _outline.outline_color
	%ThicknessLabel.label_settings = _outline
	return _outline


func _ready() -> void:
	_show_thickness()
