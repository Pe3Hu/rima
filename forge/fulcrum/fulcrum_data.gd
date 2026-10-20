class_name FulcrumData
extends RefCounted

## Сумма толщин stratum'а и клетка за его краем. На stratum не ссылается.

var coord: Vector2i = Vector2i.ZERO
var sum: int = 0
var pieces: Array = []

var _is_built: bool = false


func init_at(coord_: Vector2i, pieces_: Array) -> void:
	if _is_built:
		return
	coord = coord_
	var copy: Array = []
	copy.assign(pieces_)
	pieces = copy
	sum = 0
	for item in pieces:
		var piece := item as PieceData
		if piece == null:
			continue
		sum += piece.thickness
	_is_built = true
