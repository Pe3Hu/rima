extends Node

## Статичные числа. Шаг печати прогресса солвера.

const PROGRESS_EVERY := 100
const INGOT_CELL_SIZE := 32
const BOARD_CELL_SIZE := 32
const MOLD_CELL_SIZE := 64
const TASKS_PATH := "res://tasks"
const OUT_PATH := "res://out"
const THICKNESS_MIN := 1
const THICKNESS_MAX := 5
const COPIES_PER_SHAPE := 3

var pentomino_shapes: Array[Bozo.Shape] = [
	Bozo.Shape.F,
	Bozo.Shape.I,
	Bozo.Shape.L,
	Bozo.Shape.P,
	Bozo.Shape.N,
	Bozo.Shape.T,
	Bozo.Shape.U,
	Bozo.Shape.V,
	Bozo.Shape.W,
	Bozo.Shape.X,
	Bozo.Shape.Y,
	Bozo.Shape.Z,
]
