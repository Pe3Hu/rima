class_name StratumData
extends RefCounted

## Отрезок обхода: pieces[0] — BEVEL, последний — SPINE.
## fulcrum считается здесь и на stratum не ссылается.

var subtype: Bozo.Stratum = Bozo.Stratum.NONE
var direction: Bozo.Direction = Bozo.Direction.NONE
var pieces: Array = []
var fulcrum: FulcrumData

var _is_built: bool = false


func init_line(subtype_: Bozo.Stratum, direction_: Bozo.Direction, pieces_: Array) -> void:
	if _is_built:
		return
	subtype = subtype_
	direction = direction_
	var copy: Array = []
	copy.assign(pieces_)
	pieces = copy
	_recalc_fulcrum()
	_is_built = true


func _recalc_fulcrum() -> void:
	var fulcrum_data := FulcrumData.new()
	fulcrum_data.init_at(_fulcrum_coord(), pieces)
	fulcrum = fulcrum_data


func _fulcrum_coord() -> Vector2i:
	if pieces.is_empty():
		return Vector2i.ZERO
	var first := pieces[0] as PieceData
	if first == null:
		return Vector2i.ZERO
	var max_x := first.coord.x
	var min_x := first.coord.x
	var max_y := first.coord.y
	var min_y := first.coord.y
	for item in pieces:
		var piece := item as PieceData
		if piece == null:
			continue
		max_x = maxi(max_x, piece.coord.x)
		min_x = mini(min_x, piece.coord.x)
		max_y = maxi(max_y, piece.coord.y)
		min_y = mini(min_y, piece.coord.y)
	match direction:
		Bozo.Direction.RIGHT:
			return Vector2i(max_x + 1, first.coord.y)
		Bozo.Direction.LEFT:
			return Vector2i(min_x - 1, first.coord.y)
		Bozo.Direction.TOP:
			return Vector2i(first.coord.x, min_y - 1)
		Bozo.Direction.BOTTOM:
			return Vector2i(first.coord.x, max_y + 1)
		_:
			return first.coord
