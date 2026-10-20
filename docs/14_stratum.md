 # Шаг 14. Stratum — enum, флаги симметрии, данные и генерация

**Цель.** Ввести `Bozo.Stratum`, `Bozo.Direction`, флаги симметрии в
`tasks/<weapon>.json` и `StratumData` с генерацией из текущей Mold.
Stratum — это BEVEL-инициируемый отрезок SPINE'ов: всегда начинается с
BEVEL, заканчивается SPINE, длина >= 2.

**Зависит от.** Шаги 12–13.

## Enum (в `Bozo`, продолжение общего ряда)
- `Bozo.Stratum`: `NONE = 0`, `RAZOR`, `SPIKE`.
- `Bozo.Direction`: `NONE = 0`, `RIGHT`, `LEFT`, `TOP`, `BOTTOM`.
  - `RIGHT` — обход справа налево, Fulcrum справа.
  - `LEFT` — обход слева направо, Fulcrum слева.
  - `TOP` — обход сверху вниз, Fulcrum сверху.
  - `BOTTOM` — обход снизу вверх, Fulcrum снизу.
- Регистрация в `Type`/`type_to_index`/`type_to_enum` — только если
  понадобятся строки (для debug). Если нет — не регистрировать.

## JSON и `MoldTemplateData`
- Поля `is_horizontal_symmetric: bool` и `is_fully_symmetric: bool`
  в `tasks/<weapon>.json` (top-level; пользователь заполняет руками,
  по умолчанию `false`).
- `MoldTemplateData` получает эти поля.
- Если `is_fully_symmetric == true`, `is_horizontal_symmetric` игнорируется.

## Конфигурация направлений
Метод `MoldTemplateData.get_strata_config() -> Array` (массив словарей без
вложенных типов — ограничение Godot 4.4). Элемент:
`{subtype: Bozo.Stratum, direction: Bozo.Direction}`.

- default (`false/false`): `[{RAZOR, RIGHT}, {SPIKE, TOP}]`.
- `is_horizontal_symmetric` (`true/false`):
  `[{RAZOR, RIGHT}, {RAZOR, LEFT}, {SPIKE, TOP}]`.
- `is_fully_symmetric` (`*/true`):
  `[{RAZOR, RIGHT}, {RAZOR, LEFT}, {RAZOR, TOP}, {RAZOR, BOTTOM}]` —
  Spike нет.

## `StratumData` (`RefCounted`, `forge/stratum/stratum_data.gd`)
- `subtype: Bozo.Stratum`
- `direction: Bozo.Direction`
- `pieces: Array` — `Array[PieceData]` без вложенного типа; порядок —
  в порядке обхода (первый — BEVEL, последний — SPINE).
- `fulcrum: FulcrumData` — `null` на этом шаге; создаётся в шаге 15.

## Генерация (`MoldData.recalc_strata() -> void`)

Вызывается из `MoldData` после любого изменения Ingot'ов (`add_ingot`,
`update_ingot`, `clear_ingots`), а также один раз при `init_with_*`.

### Обход

Для каждого конфига из `get_strata_config()`:
- Для каждой строки (RIGHT/LEFT) или столбца (TOP/BOTTOM), где есть хотя бы
  одна занятая клетка:
  - Взять крайнюю клетку со стороны входа: RIGHT → max x в строке,
	LEFT → min x, TOP → min y в столбце, BOTTOM → max y.
  - Идти в направлении обхода, применяя правила ниже.
  - Пустая клетка (нет Ingot) — стоп.
  - `part == Bozo.Part.NONE` — стоп (трактуется как разрыв).
  - `part == Bozo.Part.BEVEL`:
	- если в массиве уже есть BEVEL → стоп, эту клетку **не** добавлять,
	  обход не продолжать;
	- иначе → добавить, продолжить.
  - `part == Bozo.Part.SPINE` → добавить, продолжить.
  - Конец строки/столбца — стоп.

### Валидация

Stratum создаётся только если:
- `pieces.size() >= 2`;
- `pieces[0].part == Bozo.Part.BEVEL`;
- `pieces[pieces.size() - 1].part == Bozo.Part.SPINE`.

Иначе — stratum не создаётся. Следствия:
- только-SPINE отрезок → stratum не создан;
- только-BEVEL отрезок (одиночный BEVEL) → stratum не создан;
- начинающийся со SPINE отрезок → stratum не создан;
- в каждом созданном stratum'е ровно один BEVEL, на позиции 0.

### Сохранение

- Сохранить все валидные `StratumData` в `MoldData.strata: Array`
  (без вложенного типа).
- Эмитить `strata_changed` (или переиспользовать `changed`).

## Порядок операций в `Mold`
- `data.changed` → сцена `Mold._on_changed()`: сначала пересобрать Piece'ы
  (как сейчас), затем (если `shows_strata`) — пересобрать Stratum/Fulcrum
  сцены.
- `pieces` в `StratumData` должны ссылаться на актуальные `PieceData` —
  поэтому `recalc_strata` вызывается после пересборки Piece'ов.

## Чек-лист
- [x] `Bozo.Stratum`, `Bozo.Direction` добавлены и не конфликтуют
      с существующими значениями.
- [x] Флаги в JSON и `MoldTemplateData`.
- [x] `get_strata_config()` возвращает правильные списки для трёх режимов.
- [x] `StratumData` (`RefCounted`).
- [x] `MoldData.recalc_strata()` вызывается после изменений.
- [x] На доске без флагов: Razor-RIGHT и Spike-TOP.
- [x] При `is_horizontal_symmetric` добавлен Razor-LEFT.
- [x] При `is_fully_symmetric` — 4 Razor (RIGHT/LEFT/TOP/BOTTOM), без Spike.
- [x] Пустая клетка разрывает stratum.
- [x] `part == NONE` разрывает stratum.
- [x] Только-SPINE ряд → stratum не создан.
- [x] Только-BEVEL ряд → stratum не создан.
- [x] BEVEL, SPINE → валидный stratum.
- [x] BEVEL, SPINE, BEVEL, SPINE → stratum = [BEVEL, SPINE]
      (второй BEVEL не добавлен, обход остановлен).
- [x] SPINE, BEVEL, SPINE (со стороны входа) → stratum не создан.
- [x] В каждом созданном stratum'е ровно один BEVEL, на позиции 0.
- [x] Консоль без ошибок.
