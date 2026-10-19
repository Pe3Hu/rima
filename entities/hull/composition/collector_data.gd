class_name CollectorData
extends DlxSolutionReceiver

## Приёмник DLX: считает сырые сетки, орбиты и по флагу хранит канонических представителей.

var coverage: CoverageData
var task: TaskData
var canonicalizer: SolutionCanonicalizer
var dedupe: bool = true
var max_solutions: int = 0

var raw_total: int = 0
var invalid_total: int = 0
var stopped_early: bool = false
var orbits: Dictionary = {}
var solutions: Array[Solution] = []
var invalid_reasons: Array[String] = []
var progress_callback: Callable = Callable()


func _init(coverage_: CoverageData, task_: TaskData) -> void:
	coverage = coverage_
	task = task_
	dedupe = task.dedupe_by_symmetry
	max_solutions = task.max_solutions
	canonicalizer = SolutionCanonicalizer.new(task.board, task.pieces, task.symmetry)
	expected_pieces = task.pieces.pieces.size()


func on_solution(row_ids: Array[int]) -> bool:
	raw_total += 1
	var found: Array[AllocationData] = []
	for row_id in row_ids:
		found.append(coverage.allocations[int(row_id)])

	var reason := Solution.invalid_reason(task.board, task.pieces, found)
	if reason != "":
		invalid_total += 1
		if invalid_reasons.size() < 5:
			invalid_reasons.append(reason)

	var _hash := canonicalizer.canonical_hash(found)
	var is_new_orbit := not orbits.has(_hash)
	if is_new_orbit:
		orbits[_hash] = true

	var stored := found
	if dedupe:
		if not is_new_orbit:
			_notify()
			return true
		var canonical := canonicalizer.canonicalize(found)
		if canonical.is_empty():
			invalid_total += 1
			if invalid_reasons.size() < 5:
				invalid_reasons.append("canonical orientation is missing")
		else:
			stored = canonical

	var solution := Solution.new()
	solution.allocations = stored
	solution.index = solutions.size()
	solution.task_id = task.id
	solution.symmetry_group = task.board.symmetry_group
	solution.canonical_hash = _hash
	solutions.append(solution)
	_notify()
	if max_solutions > 0 and solutions.size() >= max_solutions:
		stopped_early = true
		return false
	return true


func _notify() -> void:
	if progress_callback.is_valid():
		progress_callback.call(raw_total, max_solutions)
