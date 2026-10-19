class_name SolveResult
extends RefCounted

## Итог `PuzzleSolver.solve`: решения, счётчики орбит и диагностика матрицы.

var task_id: String = ""
var board: MaskBoardData
var solutions: Array[Solution] = []
var solutions_total: int = 0
var orbits_total: int = 0
var symmetry_group: String = ""
var elapsed_ms: int = 0
var diagnostics: Dictionary = {}


func summary() -> String:
	var free_count := 0
	if board != null:
		free_count = board.free_cells().size()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("task: %s" % task_id)
	lines.append("free cells: %d" % free_count)
	lines.append("dlx rows: %d" % int(diagnostics.get("rows_built", 0)))
	lines.append("dlx columns: %d" % int(diagnostics.get("columns", 0)))
	lines.append("solutions before dedupe: %d" % solutions_total)
	lines.append("solutions after dedupe: %d" % solutions.size())
	lines.append("orbits: %d" % orbits_total)
	lines.append("symmetry: %s" % symmetry_group)
	lines.append("elapsed ms: %d" % elapsed_ms)
	lines.append("skipped anchor on hole: %d" % int(diagnostics.get("skipped_anchor_on_hole", 0)))
	if diagnostics.has("rows_per_piece"):
		lines.append("rows per piece: %s" % [diagnostics["rows_per_piece"]])
	if diagnostics.has("errors"):
		lines.append("errors: %s" % [diagnostics["errors"]])
	return "\n".join(lines)


## Пишет JSON-массив. Прежние ключи записи сохранены, новые поля добавлены рядом.
func save(path: String) -> bool:
	if path == "":
		push_error("output path is empty")
		return false
	var directory := path.get_base_dir()
	if directory != "":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var width := 0
	if board != null:
		width = board.width
	var payload: Array = []
	for solution in solutions:
		payload.append(solution.to_dictionary(width))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open file: " + path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true
