class_name PuzzleSolver
extends RefCounted

## Публичный запуск задачи: описание на вход, все замощения на выход.

signal progress(done: int, total: int)
signal solved(result: SolveResult)


func solve(task: TaskData) -> SolveResult:
	var started := Time.get_ticks_msec()
	var result := SolveResult.new()
	result.task_id = task.id
	result.board = task.board
	if task.board != null:
		result.symmetry_group = task.board.symmetry_group

	var errors: Array[String] = []
	errors.append_array(task.load_errors)
	if task.board != null and task.pieces != null:
		errors.append_array(task.validate())
	elif errors.is_empty():
		errors.append("task is incomplete")

	if not errors.is_empty() or task.board == null or task.pieces == null:
		return _finish(result, errors, started, {}, 0, 0)

	var coverage := CoverageData.new(task.board, task.pieces, task.anchor_policy)
	var fit := coverage.fit_errors()
	if fit.size() > 0:
		errors.append_array(fit)
		return _finish(result, errors, started, coverage.diagnostics(), 0, 0)

	var collector := CollectorData.new(coverage, task)
	collector.progress_callback = Callable(self, "_on_collector_progress")
	var solver := DlxSolver.new(coverage, collector)
	solver.solve()

	result.solutions = collector.solutions
	result.solutions_total = collector.raw_total
	result.orbits_total = collector.orbits.size()
	var diagnostics := coverage.diagnostics()
	diagnostics["invalid_solutions"] = collector.invalid_total
	diagnostics["stopped_early"] = collector.stopped_early
	if collector.invalid_total > 0:
		errors.append_array(collector.invalid_reasons)
	return _finish(result, errors, started, diagnostics, result.solutions_total, result.orbits_total)


func _on_collector_progress(done: int, total: int) -> void:
	progress.emit(done, total)


func _finish(
	result: SolveResult,
	errors: Array[String],
	started: int,
	diagnostics: Dictionary,
	solutions_total: int,
	orbits_total: int
) -> SolveResult:
	result.solutions_total = solutions_total
	result.orbits_total = orbits_total
	result.elapsed_ms = Time.get_ticks_msec() - started
	result.diagnostics = diagnostics
	if not errors.is_empty():
		result.diagnostics["errors"] = errors
	if not result.diagnostics.has("rows_built"):
		result.diagnostics["rows_built"] = 0
	if not result.diagnostics.has("columns"):
		result.diagnostics["columns"] = 0
	if not result.diagnostics.has("skipped_anchor_on_hole"):
		result.diagnostics["skipped_anchor_on_hole"] = 0
	solved.emit(result)
	return result
