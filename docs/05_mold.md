# Шаг 5. Сцены и данные Mold/Piece, удаление старых сущностей

**Цель.** Ввести `MoldData`, `PieceData`, сцены `Mold` и `Piece`; удалить
Hull/Module/Capsule/Board* и переименовать `tasks/`, `out/`.

**Зависит от.** Шаги 3–4.

## Переименовать и доработать

- `entities/hull/hull.gd`, `hull.tscn`
- `entities/hull/module/*` (Module и связанные сцены)
- `entities/hull/composition/*` — **кроме** `MaskBoardData` и DLX/солвера
  (они нужны для загрузки решений из `out/`).
- `forge/board/*` (агент создал на шаге 5-старом): `board.gd`,
  `board_data.gd`, `board_template_data.gd`, `ingot_placement_data.gd`,
  `board.tscn`.
- Все упоминания `Hull`, `Module`, `Capsule`, `Board*` (кроме `MaskBoardData`).
- Из `Mother` убрать `hull`. Оставить только `weapons`, `current_weapon_index`, `forge`.

## Переименовать файлы

- `tasks/board_xxx.json` → `tasks/<weapon>.json` (имя из поля `weapon`).
- `out/board_xxx.json` → `out/<weapon>.json`.
- Обновить пути в солвере и тестах (проверить `entities/hull/composition/*`,
  `tools/*`, `tests/*`). Содержимое файлов не менять.

## `MoldTemplateData` (`RefCounted`)

Неизменяемый шаблон досок. Поля:
- `id: String`
- `weapon_name: String` (из поля `weapon` в JSON; в data — `weapon_name`)
- `cells: Array[Vector2i]` — все клетки доски (без вырезов)
- `holes: Array[Vector2i]` — координаты вырезов
- `source_path: String` — путь исходного JSON (для логов/отладки)

Загрузка из JSON через `Helper`. Путь — `Catalog.TASKS_PATH`.

## `MoldData` (`RefCounted`)

Состояние Mold.

- `template: MoldTemplateData`
- `ingots: Array` (12 `IngotData`; без вложенного типа — ограничение Godot 4.4)
- `coords: Array[Vector2i]` — все клетки шаблона в детерминированном порядке
  (сортировка по `y`, затем `x`); кэш для быстрого обхода.
- `selected_ingot: IngotData` — `null` в левой и правой; только в центральной.
- Сигнал `changed` (единый).

Методы:
- `init_with_template(template_: MoldTemplateData) -> void` — сборка с пустым
  массивом ingot.
- `init_with_ingots(template_: MoldTemplateData, ingots_: Array) -> void`
- `get_thickness_at(cell_: Vector2i) -> int` — суммарная толщина (или 0,
  если клетка не покрыта).
- `get_thickness_map() -> Dictionary` — клетка → толщина.
- `get_ingot_at(cell_: Vector2i) -> IngotData`
- `add_ingot(ingot_data_: IngotData) -> void`
- `update_ingot(ingot_data_: IngotData) -> void` — заменить по позиции в массиве.
- `apply_selection(ingot_data_: IngotData) -> void` — установить/снять
  (`null`); шлёт `changed`.
- `clear_ingots() -> void`
- `is_cell_free(cell_: Vector2i) -> bool`

`is_virtual` из старого `BoardData` **удаляется**: правая Mold — это
обычный `MoldData` с посчитанными Ingot'ами (см. шаг 7).

## `PieceData` (`RefCounted`)

Одна клетка одного Ingot'а на Mold.

- `coord: Vector2i`
- `thickness: int`
- `ingot_data: IngotData` — ссылка на Ingot, которому принадлежит клетка.
- `side: int` — из `Bozo` (`Bozo.PieceSide.LEFT/CENTER/RIGHT`), только для
  отображения; в data левой/центральной/правой Mold сторона задаётся
  при создании. Добавить `PieceSide` в `Bozo` с `NONE=0`, продолжив ряд.

`PieceData` не мутирует после создания. Смена варианта — это замена Ingot'а
в Mold, за ней пересборка Piece'ов (см. шаг 9).

## Сцена `Mold`

- `forge/mold/mold.gd`, `mold.tscn`.
- Единственный вход — сеттер `data: MoldData`.
- `connect_signals` → `_on_changed()` для синхронизации с состоянием.
- `_on_changed()` пересобирает дочерние `Piece` под текущие Ingot'ы:
  для каждого `coords` берёт покрывающий Ingot, толщину, создаёт/обновляет
  `PieceData` и передаёт в `Piece`.
- `@export is_interactive: bool` — конфигурация. Интерактивна только
  центральная.
- `get_piece_at_global(pos: Vector2) -> PieceData` — hit-test.
- Никакой игровой логики в сцене.

## Сцена `Piece`

- `forge/piece/piece.gd`, `piece.tscn`.
- Единственный вход — сеттер `data: PieceData`.
- Рисует Label с толщиной. Позиция Label:
  `coord * cell_size + cell_size * 0.5` (центрирование по клетке).
  Размер клетки — `Catalog.MOLD_CELL_SIZE`.
- Подсветка выбранного Ingot'а: если `MoldData.selected_ingot == data.ingot_data`,
  Piece обводится рамкой. Логика подсветки — в `Mold`, а не в `Piece`.
- Игрового состояния в сцене нет.

## Числа и таблицы

- `Catalog`: `MOLD_CELL_SIZE`, `TASKS_PATH`, `OUT_PATH`.
- `Digest`: `shape_to_cells` — оставить.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`, `rules/bozo-enums.mdc`,
`rules/gdscript-style.mdc`, `rules/scene-and-data.mdc`.

## Чек-лист

- [ ] Старые сущности удалены, ссылок нет.
- [ ] `tasks/`, `out/` переименованы; солвер и тесты обновлены, работают.
- [ ] `MoldTemplateData`, `MoldData`, `PieceData` — `RefCounted`.
- [ ] В `Bozo` добавлен `PieceSide` (`NONE=0`).
- [ ] `Mold` рендерит клетки и Piece, `Piece` показывает толщину по центру.
- [ ] `get_piece_at_global` корректно возвращает Piece.
- [ ] Консоль без ошибок.
- [ ] В `notes.md`: `MaskBoardData` не переименовывался (внутренний класс солвера).