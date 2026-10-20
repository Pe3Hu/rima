# Шаг 6. `WeaponData` и массив оружий в Mother

> Superseded by docs/18 в части оружия: `weapons` и `current_weapon_index` живут в `WarehouseData`. `Mother.get_current_weapon()` — прокси без своего состояния.

**Цель.** Ввести оружие как первоклассную сущность и массив оружий
в `Mother`.

**Зависит от.** Шаг 5.

## `WeaponData` (`RefCounted`)

- `name: String` — имя (совпадает с полем `weapon` в JSON).
- `mold: MoldData` — актуальная Mold оружия.
- `init_with_mold(name_: String, mold_: MoldData) -> void`
- `apply_mold(mold_: MoldData) -> void` — заменить Mold (используется
  в Fusion, шаг 10); шлёт `mold_changed`.

## `Mother` (`global/mother.gd`)

- `weapons: Array` — типизировать без вложенного типа (ограничение Godot 4.4).
- `current_weapon_index: int`
- `forge: ForgeData`
- Методы:
  - `get_current_weapon() -> WeaponData`
  - `apply_current_weapon_index(index_: int) -> void`
- `_ready`: загрузить все `tasks/*.json`, для каждого собрать `WeaponData`
  с начальной Mold из соответствующего `out/<weapon>.json` (первое
  решение). `current_weapon_index = 0` (chokuto — первый в списке).
  `Mother.hull` больше нет.
- Пути — `Catalog.TASKS_PATH`, `Catalog.OUT_PATH`.

## Размещение в проекте

- `forge/weapon/weapon_data.gd` → `WeaponData`.
- `global/mother.gd` — расширить.
- Сцены у Weapon нет.

## Правила

`rules/architecture.mdc`, `rules/feature-structure.mdc`, `rules/gdscript-style.mdc`.

## Чек-лист

- [ ] `WeaponData` — `RefCounted`, `name` + `mold`.
- [ ] `Mother.weapons` заполнен всеми задачами из `tasks/`.
- [ ] `current_weapon_index = 0` на старте.
- [ ] `Mother.hull` удалён.
- [ ] Начальная `weapon.mold` собрана из первого решения `out/<weapon>.json`.
- [ ] В `notes.md`: решение «стартовый Mold = первое решение из out/».
- [ ] Консоль без ошибок.