# Шаг 2. Enum `Shape` в Bozo

**Цель.** Добавить в `Bozo` перечисление 12 форм пентамино — единый источник форм для `Ingot`, `Warehouse`, `Board`, `Forge`.

**Зависит от.** Шаг 1.

## Требования

- Добавить в `Bozo` новое перечисление `Shape` (PascalCase для типа, UPPER_SNAKE для значений). У каждого enum есть `NONE = 0`; остальные значения продолжают общий целочисленный ряд и не повторяются между enum.
- Значения: `NONE = 0`, далее 12 пентамино в фиксированном порядке: F, I, L, P, N, T, U, V, W, X, Y, Z.
- Регистрация в `Type`, `type_to_index`, `type_to_enum` — строковые имена нужны для парсинга решений из `out/` и для возможных путей сцен. Строковый ключ — в нижнем регистре (`f`, `i`, `l`, `p`, `n`, `t`, `u`, `v`, `w`, `x`, `y`, `z`).
- Не копировать enum в `IngotData`, `BoardData`, `ForgeData` — ссылаться на `Bozo.Shape`.
- Не заводить отдельный файл под enum — только в `global/Bozo.gd`.

## Где использовать дальше

- `IngotData.shape: Bozo.Shape` — форма слитка.
- `WarehouseData.shape_to_variants: Dictionary` — склад (ключ — `Bozo.Shape`, значение — `Array[IngotData]`).
- `Digest.shape_to_cells: Dictionary` — координаты ячеек формы (ключ — `Bozo.Shape`, значение — `Array[Vector2i]`).

## Правила

Ссылки: `rules/bozo-enums.mdc`, `rules/gdscript-style.mdc`.

## Чек-лист

- [ ] В `Bozo` появился enum `Shape` с `NONE = 0` и 12 пентамино.
- [ ] Значения не пересекаются с другими enum в `Bozo`.
- [ ] Enum зарегистрирован в `Type`, `type_to_index`, `type_to_enum`.
- [ ] `Bozo.enum_to_string(Bozo.Type.SHAPE, Bozo.Shape.F)` возвращает `f`.
- [ ] Обратное преобразование из строки работает через `type_to_enum`.
- [ ] Дублирующих enum в других файлах нет.