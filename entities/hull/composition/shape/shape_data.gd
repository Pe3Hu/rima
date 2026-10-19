class_name ShapeData
extends Resource

## Одна фигура: имя, числовой id сетки, клетки и уникальные ориентации.
## Остаётся Resource: определения лежат в `.tres`.
##
## `coords` заданы относительно произвольного начала, отрицательные значения допустимы.
## После ориентации клетки сдвигаются так, что минимальные X и Y становятся нулём.
## Угол ограничивающего прямоугольника может не принадлежать фигуре.
## `symmetry` — фильтр генерации, а не описание доски:
## - x == 0 и y == 0: все четыре поворота; x == 0 и y != 0: только разворот на 180°;
## - x != 0 и y == 0: поворот на 90°; оба ненулевые: без дополнительных поворотов;
## - z == 0: строится отражение.

@export var id: String = ""
@export var type: int = 0
@export var coords: Array[Vector2i] = []
@export var symmetry: Vector3i = Vector3i.ZERO

var piece_index: int = -1

var _orientations: Array[OrientationData] = []
var _orientation_keys: Dictionary = {}


func _init() -> void:
	coords = []


## Клетки базовой ориентации.
func cells() -> Array[Vector2i]:
	return coords


## Уникальные ориентации с учётом `symmetry`. Повторный вызов возвращает тот же набор.
func generate_orientations() -> Array[OrientationData]:
	if not _orientations.is_empty():
		return _orientations

	var twists: Array[int] = [0]
	var flips: Array[bool] = [false]

	if symmetry.x == 0:
		for step in 3:
			if symmetry.y == 0 or step % 2 == 1:
				twists.append(step + 1)
	elif symmetry.y == 0:
		twists.append(1)

	if symmetry.z == 0:
		flips.append(true)

	for flip in flips:
		for twist in twists:
			var orientation := OrientationData.new(self, flip, twist)
			var key := coord_key(orientation.coords)
			if _orientation_keys.has(key):
				continue
			_orientation_keys[key] = orientation
			_orientations.append(orientation)
	return _orientations


## Ориентация с тем же набором клеток, что `local_cells`, или null.
func orientation_for(local_cells: Array[Vector2i]) -> OrientationData:
	generate_orientations()
	var key := coord_key(local_cells)
	if not _orientation_keys.has(key):
		return null
	return _orientation_keys[key]


static func coord_key(cells_: Array) -> String:
	var parts := PackedStringArray()
	for cell in cells_:
		var point := cell as Vector2i
		parts.append("%d,%d" % [point.x, point.y])
	parts.sort()
	return ";".join(parts)
