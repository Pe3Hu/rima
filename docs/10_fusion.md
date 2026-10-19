# Шаг 10. Пересчёт правой Mold и Fusion

**Цель.** Правая Mold — Mold, которой станет `weapon.mold` после Fusion.
Кнопка Fusion применяет правую Mold к оружию и списывает Ingot'ы из Warehouse.

**Зависит от.** Шаги 7–9.

## Пересчёт правой Mold (`ForgeData.recalc_right()`)

- Очистить `right.ingots`.
- Для каждого левого Ingot'а `L`:
  - создать копию с теми же `shape`, `origin`, `rotation_steps`, `is_flipped`
    и `variant_index`;
  - `thicknesses_new[i] = L.thicknesses[i] + thickness_from_center_at(L.get_world_cells()[i])`;
    если клетка не покрыта центром (не должно случаться при полном
    замощении, но защита нужна) — прибавить 0;
  - добавить в `right`.
- `variant_index` у правого Ingot'а — `-1` (это не вариант Warehouse,
  это результат Fusion).
- После пересчёта — эмитить `right_changed`.
- Инвариант: в `right` ровно 12 Ingot'ов, все клетки шаблона покрыты.

## Fusion (`ForgeData.apply_fusion() -> bool`)

- Условие: `is_fusion_available() == true`, иначе `return false`.
  `is_fusion_available()` = в `center` есть хотя бы один Ingot (по факту —
  всегда 12 при полном замощении, поэтому проверка эквивалентна
  «центр сгенерирован»).
- Шаги:
  1. `Mother.get_current_weapon().apply_mold(right)` — заменить Mold оружия.
  2. Для каждого Ingot'а центра — `warehouse.apply_removal(center_ingot)`
     (сравнение по `shape` + `thicknesses`; если не найден — не падать,
     записать в `notes.md` как редкий кейс).
  3. `left := right` (или пересобрать left из нового `weapon.mold`).
  4. `refill_center()` — новая случайная Mold, отличная от нового левого
     (шаг 8).
  5. `recalc_right()`.
  6. Эмитить `right_changed`, `center_changed`, `selection_changed`
     (сброс выбора).
- Возвращает `true`.
- После Fusion `weapon.mold` — новый Mold с увеличенными толщинами.
  Игрок видит: левая Mold = бывшая правая, центр пересобран, правая
  снова = left + новый center.

## UI

- `%FusionButton.disabled = not data.is_fusion_available()`.
- Состояние обновляется в `_on_selection_changed` и `_on_center_changed`
  сцены Forge.
- Кнопка вызывает `data.apply_fusion()`; при `true` — обновить
  `%WeaponNameLabel` (не меняется) и ничего больше (визуал сам
  обновится через сигналы).

## Правила

`rules/architecture.mdc`, `rules/gdscript-style.mdc`.

## Чек-лист

- [ ] `recalc_right()` правильно копирует левые Ingot'ы и прибавляет
      толщины центра по клеткам.
- [ ] В `right` ровно 12 Ingot'ов, все клетки покрыты.
- [ ] `apply_fusion()` успешно заменяет `weapon.mold`, списывает 12 Ingot'ов
      из Warehouse, пересобирает левую и центр.
- [ ] После 3 Fusion подряд какая-то форма в Warehouse обнуляется;
      4-й Fusion — либо падает по `is_fusion_available`, либо
      обрабатывается внятно. Решение зафиксировать в `notes.md`.
- [ ] `%FusionButton` корректно disabled/enabled.
- [ ] После Fusion `right == left` при пустом центре не выполняется
      (центр не пуст), но `right == left + center` — да.
- [ ] Консоль без ошибок.