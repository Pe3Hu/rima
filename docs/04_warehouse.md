# Шаг 4. Сущность `Warehouse` (обновление)

**Цель.** Склад становится частью `ForgeData`, а не самостоятельным
`RefCounted`. Добавить вычитание Ingot'ов, использованных в центральной Mold.

**Зависит от.** Шаг 3.

## Что меняется

- `WarehouseData` создаётся в `ForgeData._init` (шаг 7), регистрируется
  у родителя. Сам по себе нигде не создаётся.
- Методы склада:
  - `get_variants(shape_: Bozo.Shape) -> Array`
  - `get_variant_count(shape_: Bozo.Shape) -> int`
  - `get_variant(shape_: Bozo.Shape, index_: int) -> IngotData`
  - `apply_removal(ingot_data_: IngotData) -> bool` — убрать один экземпляр,
    совпадающий по `shape` и `thicknesses`; вернуть `true`, если удалён.
  - `get_total_count() -> int`
- Инвариант: `shape_to_variants` для каждой из 12 форм содержит
  `0..Catalog.COPIES_PER_SHAPE` экземпляров. Изначально 3, после Fusion
  может уменьшиться.
- Инициализация: 12 форм × 3 экземпляра, толщины 1..5, `Helper.rng`.
- Seed по умолчанию не задаётся (non-seeded), решение шага 4.

## Размещение в проекте

- `forge/warehouse/warehouse_data.gd` — обновить.
- Сцены нет.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`, `rules/gdscript-style.mdc`.

## Чек-лист

- [ ] `WarehouseData` создаётся только в `ForgeData._init`.
- [ ] 12 форм × 3 = 36 экземпляров при инициализации.
- [ ] `apply_removal` корректно убирает один экземпляр и возвращает `true/false`.
- [ ] После 3 Fusion подряд каждая форма может обнулиться.
- [ ] Случайность — только `Helper.rng`.
- [ ] В `notes.md` записано: склад живёт под `ForgeData`; seed не задаётся.