# Шаг 3. Сущность `Ingot` (обновление)

**Цель.** Расширить Ingot: слиток сам знает своё положение на Mold.

**Зависит от.** Шаг 2.

## Что меняется

- В `IngotData` добавляются поля:
  - `origin: Vector2i` — привязка формы на Mold.
  - `rotation_steps: int` (0..3).
  - `is_flipped: bool`.
- Метод `get_world_cells() -> Array[Vector2i]` — мировые клетки с учётом
  `origin`, `rotation_steps`, `is_flipped` (порядок: reflect X, затем
  поворот по часовой).
- Метод `get_thickness_at(world_cell_: Vector2i) -> int` — толщина в
  мировых координатах или -1, если клетка не принадлежит слитку.
- `IngotData` остаётся immutable после `init_*`.

## Что убрать

- Плейсмент (`IngotPlacementData` из шага 5) больше не нужен: Ingot сам
  хранит позицию. Все ссылки на `IngotPlacementData` удалить.

## Размещение в проекте

- `forge/ingot/ingot_data.gd` → класс `IngotData` (расширяется).
- `forge/ingot/ingot.gd`, `ingot.tscn` — сцена отображения (без изменений).

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `IngotData` содержит `shape`, `thicknesses`, `origin`, `rotation_steps`, `is_flipped`.
- [ ] `get_world_cells()` даёт корректные клетки для rotation 0..3 и flip true/false.
- [ ] `get_thickness_at(cell)` возвращает толщину или -1.
- [ ] `is_valid()` проверяет `>= 0`, длину, форму не NONE, диапазон
      `rotation_steps`.
- [ ] `IngotPlacementData` удалён, ссылок на него нет.
- [ ] Консоль без ошибок.