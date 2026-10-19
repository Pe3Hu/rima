extends Node

## Цвета форм и клетки пентамино.
## Порядок клеток совпадает с `entities/hull/composition/shape/data/*.tres`.
## Палитра Пола Тола: 12 цветов, различимых при дейтеранопии и протанопии.

var shape_to_color: Dictionary[Bozo.Shape, Color] = {
	Bozo.Shape.F: Color("4477aa"),
	Bozo.Shape.I: Color("ee6677"),
	Bozo.Shape.L: Color("228833"),
	Bozo.Shape.P: Color("ccbb44"),
	Bozo.Shape.N: Color("66ccee"),
	Bozo.Shape.T: Color("aa3377"),
	Bozo.Shape.U: Color("332288"),
	Bozo.Shape.V: Color("44aa99"),
	Bozo.Shape.W: Color("882255"),
	Bozo.Shape.X: Color("ddcc77"),
	Bozo.Shape.Y: Color("117733"),
	Bozo.Shape.Z: Color("e69f00"),
}

var shape_to_cells: Dictionary[Bozo.Shape, Array] = {
	Bozo.Shape.F: [Vector2i(0, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(-1, 1)],
	Bozo.Shape.I: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(2, 0)],
	Bozo.Shape.L: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(1, 0), Vector2i(2, 0)],
	Bozo.Shape.P: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 0)],
	Bozo.Shape.N: [Vector2i(0, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(1, 0), Vector2i(2, 0)],
	Bozo.Shape.T: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)],
	Bozo.Shape.U: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(1, 0), Vector2i(1, 1)],
	Bozo.Shape.V: [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 0), Vector2i(2, 0)],
	Bozo.Shape.W: [Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(1, -1)],
	Bozo.Shape.X: [Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1)],
	Bozo.Shape.Y: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 0)],
	Bozo.Shape.Z: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(1, 0), Vector2i(1, -1)],
}


func color_of_shape(shape_: Bozo.Shape) -> Color:
	if shape_to_color.has(shape_):
		return shape_to_color[shape_]
	return Color.WHITE


func color_of(shape_: ShapeData) -> Color:
	var shape_id := Bozo.string_to_enum(Bozo.Type.SHAPE, shape_.id)
	return color_of_shape(shape_id)
