# Шаг 15. Fulcrum — данные, сцена, размещение

**Цель.** `FulcrumData` — сумма толщин stratum'а и координата за пределами оружия. Сцена `Fulcrum` — Label с суммой. Дочерний элемент у `Stratum`.

**Зависит от.** Шаг 14.

## `FulcrumData` (`RefCounted`, `forge/fulcrum/fulcrum_data.gd`)
- `coord: Vector2i` — клетка размещения (за пределами оружия).
- `sum: int` — сумма `PieceData.thickness` по всем piece stratum'а.
- `pieces: Array` — ссылки на `PieceData` этого stratum'а (для подсветки, шаг 16). Дублирование с `StratumData.pieces` допустимо (без вложенного типа). Обратной ссылки на stratum — **нет** (избегаем циклов RefCounted).
- Вычисляется в `StratumData._recalc_fulcrum()`, вызывается в `_init` stratum'а.

## Размещение
Для stratum'а с клетками `cells`:
- RIGHT: `coord = (max_x + 1, row_y)`.
- LEFT: `coord = (min_x - 1, row_y)`.
- TOP: `coord = (col_x, min_y - 1)`.
- BOTTOM: `coord = (col_x, max_y + 1)`.

`row_y` / `col_x` — общая координата строки/столбца (у всех piece stratum'а она одинаковая).

## Сцена `Fulcrum` (`forge/fulcrum/fulcrum.gd`, `fulcrum.tscn`)
- `Node2D` (или `Control`), единственный вход — сеттер `data: FulcrumData`.
- Дочерний `Label` — текст суммы (без знака +).
- Позиция в мировых координатах: `coord * Catalog.MOLD_CELL_SIZE + Catalog.MOLD_CELL_SIZE * 0.5` — центр клетки, как Piece-Label.
- Стиль: цвет из `Digest` (например, `Digest.fulcrum_color`); при `is_highlighted == true` — обводка/яркий цвет.
- Сигнал `pressed` — пока не подключается (шаг 16). `mouse_filter` — `STOP` для приёма кликов (настроить уже сейчас, чтобы не менять в шаге 16).
- Данные не мутирует.

## Сцена `Stratum` (`forge/stratum/stratum.gd`, `stratum.tscn`)
- `Node2D`, единственный вход — сеттер `data: StratumData`.
- Дочерний `Fulcrum` (создаётся в `init_fulcrum`).
- Визуально пустой контейнер; подсветка piece'ов — на стороне `Mold` (шаг 16).
- `_on_changed` / пересборка — по сигналу от `Mold` (см. ниже).

## Сцена `Mold` — отображение strata
- Новый `Node2D` `%StrataLayer` (уникальное имя).
- Слой над `Background`/Ingot, но под Piece-Label'ами (порядок детей — отредактировать в `mold.tscn`).
- `@export shows_strata: bool = false` — у левой Mold в `forge.tscn` поставить `true`, у центральной и правой — `false`.
- В `_on_changed()`: если `shows_strata`, вызвать `init_strata()`:
  - `Helper.clear_children(%StrataLayer)`.
  - Для каждого `stratum_data` в `data.strata`: экземпляр `Stratum` сцены, `stratum.data = stratum_data`, `add_child` в `%StrataLayer`.

## Открытые вопросы (в notes.md)
- Показывать Fulcrum только на левой Mold (по умолчанию) или на всех трёх? Если понадобится — `@export shows_strata` уже готов.
- Возможное перекрытие Fulcrum'ов от соседних stratum'ов. Если встретится — сдвиг наружу на 1 клетку (отложить; зафиксировать кейс в notes).

## Чек-лист
- [x] `FulcrumData` с `coord`, `sum`, `pieces`.
- [x] Сумма считается верно (равна сумме `thickness` всех piece stratum'а).
- [x] Размещение по направлению совпадает с правилами RIGHT/LEFT/TOP/BOTTOM.
- [x] Сцена `Fulcrum` рисует Label с суммой в правильной позиции.
- [x] Сцена `Stratum` содержит Fulcrum.
- [x] `Mold` с `shows_strata = true` пересобирает `%StrataLayer` при изменениях.
- [x] На центральной/правой Mold strata не отображаются.
- [x] Консоль без ошибок.