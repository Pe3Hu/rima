class_name Forge
extends Control

## Три Mold и кнопка Fusion. Состояние меняет только ForgeData.

var data: ForgeData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_labels()


#region init
func _ready() -> void:
	if not %FusionButton.pressed.is_connected(_on_fusion_pressed):
		%FusionButton.pressed.connect(_on_fusion_pressed)
	data = Mother.forge
#endregion


func connect_datas() -> void:
	if data == null:
		return
	%LeftMold.data = data.left
	%CenterMold.data = data.center
	%RightMold.data = data.right
	_place_molds()


func connect_signals() -> void:
	if data == null:
		return
	if not data.center_changed.is_connected(_on_center_changed):
		data.center_changed.connect(_on_center_changed)
	if not data.right_changed.is_connected(_on_right_changed):
		data.right_changed.connect(_on_right_changed)
	if not data.selection_changed.is_connected(_on_selection_changed):
		data.selection_changed.connect(_on_selection_changed)
	if not data.fusion_applied.is_connected(_on_fusion_applied):
		data.fusion_applied.connect(_on_fusion_applied)
	_on_center_changed()
	_on_right_changed()
	_on_selection_changed()


func init_labels() -> void:
	%LeftCaption.text = "Текущее"
	%CenterCaption.text = "Изменения"
	%RightCaption.text = "Результат"
	if data == null:
		return
	%WeaponNameLabel.text = "Текущее оружие: %s" % data.get_current_weapon_name()


func _unhandled_input(event_: InputEvent) -> void:
	if data == null or event_ == null:
		return
	if event_ is InputEventMouseButton and _apply_center_click(event_ as InputEventMouseButton):
		get_viewport().set_input_as_handled()
		return
	if event_.is_action_pressed("forge_prev_variant"):
		data.apply_variant_change(-1)
		get_viewport().set_input_as_handled()
	elif event_.is_action_pressed("forge_next_variant"):
		data.apply_variant_change(1)
		get_viewport().set_input_as_handled()


func _apply_center_click(button_: InputEventMouseButton) -> bool:
	if button_.button_index != MOUSE_BUTTON_LEFT or not button_.pressed:
		return false
	var mold := %CenterMold as Mold
	if not _is_on_mold(mold, button_.position):
		return false
	var piece := mold.get_piece_at_global(button_.position)
	if piece == null or piece.ingot_data == data.selected_ingot:
		data.apply_selection(null)
	else:
		data.apply_selection(piece.ingot_data)
	return true


func _is_on_mold(mold_: Mold, position_: Vector2) -> bool:
	if mold_.data == null or mold_.data.template == null:
		return false
	var span := float(Catalog.MOLD_CELL_SIZE)
	if span == 0.0:
		return false
	var local := mold_.to_local(position_)
	var cell := Vector2i(floori(local.x / span), floori(local.y / span))
	return mold_.data.template.is_cell_inside(cell)


func _on_fusion_pressed() -> void:
	if data == null:
		return
	if not data.apply_fusion():
		return
	%WeaponNameLabel.text = "Текущее оружие: %s" % data.get_current_weapon_name()


func _on_fusion_applied() -> void:
	if data == null:
		return
	_sync_mold(%LeftMold, data.left)
	_sync_mold(%CenterMold, data.center)
	_sync_mold(%RightMold, data.right)
	_update_fusion_button()


func _sync_mold(mold_: Mold, mold_data_: MoldData) -> void:
	if mold_.data == mold_data_:
		mold_._on_changed()
		return
	mold_.data = mold_data_


func _on_center_changed() -> void:
	if data == null:
		return
	_sync_mold(%CenterMold, data.center)
	_update_fusion_button()


func _on_right_changed() -> void:
	if data == null:
		return
	_sync_mold(%RightMold, data.right)


func _on_selection_changed() -> void:
	_update_fusion_button()


func _update_fusion_button() -> void:
	if data == null:
		return
	%FusionButton.disabled = not data.is_fusion_available()


func _place_molds() -> void:
	_place_mold(%LeftMold, %LeftCaption)
	_place_mold(%CenterMold, %CenterCaption)
	_place_mold(%RightMold, %RightCaption)


func _place_mold(mold_: Mold, caption_: Control) -> void:
	if mold_.data == null or mold_.data.template == null:
		return
	var span := float(Catalog.MOLD_CELL_SIZE)
	var template := mold_.data.template
	var size := Vector2(template.width, template.height) * span
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var column_width := caption_.size.x
	var available_height := 820.0
	var fit := minf(column_width / size.x, available_height / size.y)
	mold_.scale = Vector2(fit, fit)
	var caption_center := caption_.position.x + column_width * 0.5
	mold_.position = Vector2(caption_center - size.x * fit * 0.5, caption_.position.y + caption_.size.y + 12.0)
