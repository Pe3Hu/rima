# Шаг 7. Сцена Forge

**Цель.** Собрать сцену Forge: три Mold, заголовок оружия, кнопка Fusion.
Игровая логика — в `ForgeData`, сцена только отображает.

**Зависит от.** Шаги 5–6.

## `ForgeData` (`RefCounted`, корневой data кузницы)

- Создаётся в `Mother._ready`, живёт в `Mother.forge`.
- Поля:
  - `warehouse: WarehouseData` — дочерняя data, регистрируется в `_init`.
  - `left: MoldData` — копия `Mother.get_current_weapon().mold`.
  - `center: MoldData` — временная Mold (генерируется на шаге 8).
  - `right: MoldData` — результат Fusion (пересчитывается на каждом
    изменении left или center).
  - `selected_ingot: IngotData` — текущий выбранный в центре, может быть `null`.
- Сигналы:
  - `center_changed` — центр пересобран/изменён.
  - `right_changed` — правая пересчитана.
  - `selection_changed` — изменился `selected_ingot`.
- Методы:
  - `init_with_weapon(weapon_: WeaponData) -> void` — собрать left/center/right
    из оружия; вызвать генерацию центра (шаг 8); `recalc_right()`.
  - `recalc_right() -> void` — пересчитать правую Mold (шаг 10), эмитит
    `right_changed`.
  - `apply_selection(ingot_data_: IngotData) -> void` — установить/снять
    выбранный; транслирует в `center.apply_selection`; эмитит
    `selection_changed`.
  - `get_current_weapon_name() -> String` — из `Mother.get_current_weapon()`.
  - `apply_fusion() -> bool` — применить правую Mold к оружию (шаг 10);
    возвращает `true` при успехе.
  - `is_fusion_available() -> bool` — есть ли хотя бы один Ingot в центре.
  - `refill_center() -> void` — пересобрать центральную Mold (шаг 8).
- Подписки внутри `ForgeData`:
  - `center.changed` → `recalc_right`
  - `left.changed` → `recalc_right`

## Сцена `Forge` (`forge/forge.gd`, `forge/forge.tscn`)

- Корневой `Control` или `Node2D` (по правилам проекта).
- Дети:
  - `%WeaponNameLabel: Label` — «Текущее оружие: <name>».
  - `%LeftMold: Mold` (is_interactive = false)
  - `%CenterMold: Mold` (is_interactive = true)
  - `%RightMold: Mold` (is_interactive = false)
  - `%LeftCaption`, `%CenterCaption`, `%RightCaption` — «Текущее»,
    «Изменения», «Результат».
  - `%FusionButton: Button` — «Fusion».
- Единственный вход — сеттер `data: ForgeData`:
  - `connect_datas`: `data.left → %LeftMold`, `data.center → %CenterMold`,
    `data.right → %RightMold`.
  - `connect_signals`: подписка на `data.center_changed`, `data.right_changed`,
    `data.selection_changed`; вызвать обработчики сразу.
  - `init_labels`: обновить `%WeaponNameLabel`.
  - `%FusionButton.pressed.connect(_on_fusion_pressed)`.
- `_on_fusion_pressed()` → `data.apply_fusion()`.
- `_on_selection_changed()` → обновить состояние `%FusionButton.disabled`
  через `data.is_fusion_available()`.
- ЛКМ по `%CenterMold` в `_unhandled_input` сцены Forge:
  `%CenterMold.get_piece_at_global(pos)` → `data.apply_selection(piece.ingot_data)`
  или `data.apply_selection(null)` (см. шаг 9).
- Никаких правок `data.*` из сцены — только через методы `ForgeData`.
- `Q` / `E` в Forge не обрабатываются.

## Input map

Оставить существующие:
- `forge_prev_variant` — `A`
- `forge_next_variant` — `D`

`forge_prev_board`, `forge_next_board` удалить (переключение оружия в этом
фронте работ не делается).

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`, `rules/gdscript-style.mdc`,
`rules/scene-and-data.mdc`.

## Чек-лист

- [ ] `Mother.forge` создаётся в `_ready`.
- [ ] `WarehouseData` — дочерняя data `ForgeData`, зарегистрирована в `_init`.
- [ ] Три `Mold` и заголовок оружия на сцене.
- [ ] `%FusionButton` присутствует и вызывает `data.apply_fusion()`.
- [ ] Подписки `center.changed`, `left.changed` → `recalc_right` работают.
- [ ] Никаких правок `data.*` из сцены.
- [ ] `Q`/`E` в Forge не обрабатываются.
- [ ] Консоль без ошибок.