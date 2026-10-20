# Шаг 12. `Bozo.Part` и поля `spine`/`bevel`

**Цель.** Ввести enum `Bozo.Part` (SPINE/BEVEL) и связать каждую Piece с её Part по новым полям `spine`/`bevel` в `tasks/<weapon>.json`.

**Зависит от.** Шаги 1–11 (приняты).

## Требования

### Enum `Bozo.Part`
- `NONE = 0`, `SPINE`, `BEVEL`.
- Значения продолжают общий целочисленный ряд `Bozo` (взять текущий максимум из `Bozo.gd`, следующее значение — `max + 1`).
- Зарегистрировать в `Bozo.Type` (новое значение `PART`), `type_to_index`, `type_to_enum`. Строки — `spine`, `bevel` в нижнем регистре.
- Не дублировать enum в других файлах.

### JSON
- В `tasks/<weapon>.json` появились поля `spine` и `bevel`. Формат координат — как у существующих полей `board.holes` (см. `MoldTemplateData` и соответствующий лоадер).
- Отсутствие поля трактуется как пустой массив, без ошибки.

### `MoldTemplateData`
- Новое поле `cell_to_part: Dictionary` — `Vector2i → Bozo.Part`. Заполняется при загрузке: `spine` → `SPINE`, `bevel` → `BEVEL`. Клетка вне обоих массивов → `NONE`.
- Метод `get_part_at(cell_: Vector2i) -> Bozo.Part`.

### `PieceData`
- Новое поле `part: Bozo.Part` (по умолчанию `NONE`).
- Заполняется в сцене `Mold` при пересборке Piece'ов: `data.template.get_part_at(coord)`.

### Сцена `Mold`
- При пересборке передаёт `part` в `PieceData`.
- Сцена `Piece` пока это поле не использует (Part рисуется отдельным слоем — шаг 13).

## Инвариант
- Все три Mold (левая/центральная/правая) используют один шаблон, поэтому `piece.part` у них одинаков для одинаковых клеток.

## Чек-лист
- [x] `Bozo.Part` с `NONE=0, SPINE, BEVEL`.
- [x] Зарегистрирован в `Type`, `type_to_index`, `type_to_enum` (строки `spine`/`bevel`).
- [x] `MoldTemplateData.cell_to_part` заполняется из JSON, `get_part_at` работает.
- [x] `PieceData.part` выставлен при сборке Piece'ов во всех трёх Mold.
- [x] Отсутствие полей `spine`/`bevel` не ломает загрузку (пустые массивы → все `NONE`).
- [x] Консоль без ошибок.