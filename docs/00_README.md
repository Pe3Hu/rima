# Blacksmith Forge — Implementation Guide

**Фантазия.** Игрок — кузнец. Оружие/щит (Weapon) имеет свой слой металла (Mold),
собранный из 12 слитков (Ingot). Толщина металла в клетке — число.
Forge позволяет изменить Mold оружия через Fusion.

## Иерархия сущностей

- **Weapon** (`WeaponData`, `RefCounted`) — оружие/щит. Хранит `name` и `mold: MoldData`.
- **Mold** (`MoldData`, `RefCounted`) — замощение доски. Ровно 12 `IngotData`,
  покрывающих все клетки шаблона без пересечений.
- **Ingot** (`IngotData`, `RefCounted`) — слиток. Форма (`Bozo.Shape`),
  толщины по клеткам, позиция (`origin`), `rotation_steps`, `is_flipped`.
- **Piece** (`PieceData`, `RefCounted`) — одна клетка одного Ingot'а на Mold:
  `coord`, `thickness`, ссылка на `ingot_data`. Сцена `Piece` рисует
  толщину по центру клетки.

Старые сущности (`Hull`, `Module`, `Capsule`, `Board*` из шагов 5–6) удаляются.

## Схема Forge

Три Mold в одной сцене:

- **Левая** — актуальный `weapon.mold` (не редактируется).
- **Центральная** — временный Mold из Warehouse (случайное решение из `out/`,
  варианты Ingot'ов случайны). Здесь игрок выбирает Piece и меняет варианты.
- **Правая** — Mold, которой станет `weapon.mold` после Fusion. Толщины =
  `left + center` на тех же клетках; формы/позиции/повороты Ingot'ов — как у левой.

Кнопка **Fusion**:
- неактивна, пока в центре нет Piece;
- по нажатию: `weapon.mold := right`, из Warehouse удаляются 12 Ingot'ов
  центральной Mold, центр очищается, левая = новый `weapon.mold`.

## Управление

- ЛКМ по Piece в центральной Mold — выбрать Piece (подсветка всего Ingot'а).
- `A` / `D` — предыдущий/следующий вариант Ingot'а из Warehouse (той же формы).
- `Fusion` — применить правую Mold к оружию.
- `Q` / `E` — удалены из проекта.

## Метаданные досок

`tasks/board_xxx.json` → `tasks/<weapon>.json` (например, `tasks/chokuto.json`).
`out/board_xxx.json` → `out/<weapon>.json`. Содержимое файлов не меняется —
только имена. Пути в солвере и тестах обновить соответственно.

## Порядок шагов

1. `01_refactor.md` — сделан.
2. `02_bozo_shape_enum.md` — сделан.
3. `03_ingot.md` — обновить Ingot (позиция/поворот/flip).
4. `04_warehouse.md` — привязать Warehouse к ForgeData, добавить вычитание.
5. `05_mold.md` — новые MoldData/PieceData, сцены Mold/Piece; удалить
   Hull/Module/Capsule и Board*; переименовать tasks/out.
6. `06_weapon.md` — WeaponData, массив оружий в Mother.
7. `07_forge_scene.md` — сцена Forge с тремя Mold, кнопка Fusion.
8. `08_center_mold_generation.md` — заполнение центральной Mold из out/.
9. `09_piece_selection_variant.md` — выбор Piece, A/D.
10. `10_fusion.md` — Fusion.
11. `11_testing.md` — приёмка.

## Общие ограничения

- `rules/*.mdc` приоритетнее этой документации.
- Не заводить новые автозагрузки.
- Корневые `*Data` — только через `Mother`.
- Случайность — только `Helper.rng`.
- Enum — только в `Bozo`. Числа и списки — `Catalog`. Таблицы — `Digest`.
- `*Data` — `RefCounted`, кроме согласованного исключения `ShapeData` (`.tres`).
- `Dictionary` без вложенных типов — ограничение Godot 4.4, тип проверяет
  вызывающая сторона.
- `MaskBoardData` (солвер) не переименовывается в рамках этой итерации —
  это внутренний класс прототипа-солвера, не видим в игре. Открытый вопрос
  на будущее, в `notes.md`.

## Реальные имена правил

`rules/feature-structure.mdc`, `rules/bozo-enums.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.