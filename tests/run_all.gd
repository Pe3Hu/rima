extends SceneTree

## Headless-проверки солвера. Ожидания лежат в tests/manifest.json.


func _initialize() -> void:
	var failed := _run()
	if failed == 0:
		print("ALL PASSED")
	else:
		print("FAILED %d" % failed)
	quit(failed)


func _run() -> int:
	var manifest_path := "res://tests/manifest.json"
	if not FileAccess.file_exists(manifest_path):
		push_error("missing " + manifest_path)
		return 1
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if parsed == null or not (parsed is Dictionary):
		push_error("bad manifest")
		return 1
	var cases: Array = parsed.get("cases", [])
	var failed := 0
	for spec in cases:
		if not (spec is Dictionary):
			push_error("manifest case is not an object")
			failed += 1
			continue
		if _run_case(spec) != 0:
			failed += 1
	return failed


func _run_case(spec: Variant) -> int:
	var name := str(spec.get("name", ""))
	var path := str(spec.get("task", ""))
	print("CASE %s" % name)
	var task := TaskData.load_from_json(path)
	var solver := PuzzleSolver.new()
	solver.progress.connect(func(done: int, _total: int) -> void:
		if done % 100 == 0:
			print("  progress ", done)
	)
	var result := solver.solve(task)
	print(result.summary())
	var problems: Array[String] = []
	if result.diagnostics.has("errors"):
		problems.append("solver errors")
	if bool(result.diagnostics.get("stopped_early", false)):
		problems.append("search stopped early")
	if int(result.diagnostics.get("invalid_solutions", 0)) != 0:
		problems.append("invalid raw solutions")

	_expect_count(problems, spec, "exact_solutions", result.solutions_total)
	_expect_count(problems, spec, "exact_orbits", result.orbits_total)
	_expect_count(problems, spec, "exact_skipped_anchor_on_hole", int(result.diagnostics.get("skipped_anchor_on_hole", -1)))
	if spec.has("min_solutions") and result.solutions_total < int(spec["min_solutions"]):
		problems.append("solutions %d < min %d" % [result.solutions_total, int(spec["min_solutions"])])
	if spec.has("min_skipped_anchor_on_hole"):
		var skipped := int(result.diagnostics.get("skipped_anchor_on_hole", 0))
		if skipped < int(spec["min_skipped_anchor_on_hole"]):
			problems.append("skipped anchor %d is too small" % skipped)

	for solution in result.solutions:
		var reason := Solution.invalid_reason(task.board, task.pieces, solution.allocations)
		if reason != "":
			problems.append("stored solution %d: %s" % [solution.index, reason])
			break
		if bool(spec.get("check_canonical", false)):
			var canonical := SolutionCanonicalizer.new(task.board, task.pieces, task.symmetry)
			var identity := canonical.hash_grid(canonical.create_grid(solution.allocations))
			if identity != solution.canonical_hash:
				problems.append("solution %d is not the canonical image" % solution.index)
				break

	if bool(spec.get("check_roundtrip", false)) and problems.is_empty():
		if not result.save(task.output_path):
			problems.append("save failed")
		else:
			var loader := CompositionLoader.new()
			var loaded := loader.load_compositions(task.output_path, task.board, task.pieces)
			if loaded.size() != result.solutions.size():
				problems.append("roundtrip count %d != %d" % [loaded.size(), result.solutions.size()])
			else:
				for i in loaded.size():
					var left := _coverage_key(result.solutions[i].allocations)
					var right := _coverage_key(loaded[i].allocations)
					if left != right:
						problems.append("roundtrip mismatch at %d" % i)
						break

	if problems.is_empty():
		print("PASS %s" % name)
		return 0
	print("FAIL %s" % name)
	for problem in problems:
		print("  ", problem)
	return 1


func _expect_count(problems: Array[String], spec: Dictionary, key: String, actual: int) -> void:
	if not spec.has(key):
		return
	var expected := int(spec[key])
	if actual != expected:
		problems.append("%s: got %d expected %d" % [key, actual, expected])


func _coverage_key(allocations: Array[AllocationData]) -> String:
	var parts := PackedStringArray()
	for allocation in allocations:
		var cells := PackedStringArray()
		for cell in allocation.coords:
			cells.append("%d,%d" % [cell.x, cell.y])
		cells.sort()
		parts.append("%s=%s" % [allocation.orientation.shape.id, ";".join(cells)])
	parts.sort()
	return "|".join(parts)
