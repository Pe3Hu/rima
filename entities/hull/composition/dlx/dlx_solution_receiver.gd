class_name DlxSolutionReceiver
extends RefCounted

## Сколько фигур должно войти в покрытие. Ноль отключает проверку длины.
var expected_pieces: int = 0


## Вернуть false, чтобы остановить весь поиск.
func on_solution(row_ids: Array[int]) -> bool:
	if expected_pieces > 0 and row_ids.size() != expected_pieces:
		push_warning("solution rows %d != pieces %d" % [row_ids.size(), expected_pieces])
	return true
