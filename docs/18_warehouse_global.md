# Шаг 18. Warehouse как общий инвентарь игрока. Переключение оружия Q/E

**Цель.** `WarehouseData` становится общим инвентарём игрока и единственным
источником оружий и слитков. `Mother.weapons` и `Mother.current_weapon_index`
переезжают в `WarehouseData`. Переключение оружия в Forge — новая пара Q/E;
A/D по-прежнему меняют вариант Ingot'а (шаг 9).

**Зависит от.** Шаги 1–17 (приняты).

## Supersede

- `docs/04_warehouse.md`, «Что меняется»: «`WarehouseData` создаётся в
  `ForgeData._init`, регистрируется у родителя» — **отменено**. Теперь
  создаётся в `Mother._ready` и живёт под `Mother`.
- `docs/06_weapon.md`, «Mother»: `weapons` и `current_weapon_index` в
  `Mother` — **переехали** в `WarehouseData`. Метод
  `Mother.get_current_weapon()` остаётся тонким прокси к складу.
- `docs/07_forge_scene.md`: «`WarehouseData` — дочерняя data `ForgeData`,
  зарегистрирована в `_init`» — **отменено**. `ForgeData.warehouse` —
  ссылка на `Mother.warehouse`.
- Ранний черновик шага 18 с A/D для оружия — **отменён**, эта версия
  его заменяет.

## Архитектурное изменение

`WarehouseData` — общий на игрока. Живёт под `Mother` (`Mother.warehouse`),
создаётся один раз в `Mother._ready` и переживает переключения оружия и
Fusion. `ForgeData.warehouse` — **ссылка** на `Mother.warehouse`, не
собственный экземпляр.

Слитки общие на все оружия. Fusion на chokuto списывает из общего пула;
после исчерпания формы — Fusion недоступен ни на одном оружии. Это
сознательное решение.

## Изменения в `WarehouseData` (`forge/warehouse/warehouse_data.gd`)

Новые поля:
- `weapons: Array` — все оружия (`WeaponData`).
- `current_weapon_index: int` — по умолчанию `0` (chokuto).

Новые методы:
- `get_weapons() -> Array`
- `get_current_weapon() -> WeaponData`
- `apply_current_weapon_index(index_: int) -> void` — с валидацией
  диапазона; эмитит `current_weapon_changed`.

Новый сигнал:
- `current_weapon_changed`

Инициализация оружий:
- `WarehouseData` сам не грузит `tasks/*.json` — загрузку делает `Mother`
  (по шагу 6) и складывает результат в `warehouse.weapons`. Так
  `WarehouseData` остаётся про инвентарь, а чтение файлов остаётся в
  `Mother._ready`.
- Опционально: `WarehouseData` может сам заполнить `weapons` через
  `Helper`-лоадер, если `Mother` передаст ему шаблоны. По умолчанию —
  `Mother` заполняет после `new()`.

## Изменения в `Mother` (`global/mother.gd`)

Порядок `_ready`:
1. `warehouse = WarehouseData.new()` — создаёт 36 слитков (12 форм × 3,
   как в шаге 4), оружий ещё нет.
2. Загрузить все `tasks/*.json`, для каждого собрать `WeaponData` с
   начальной Mold из первого решения `out/<weapon>.json` (шаг 6).
   Сложить в `warehouse.weapons`.
3. `warehouse.current_weapon_index = 0`.
4. `Mother.warehouse = warehouse` (поле автозагрузки).
5. `Mother.forge = ForgeData.new()` — `ForgeData` получает
   `warehouse` ссылкой.

Убрать:
- `Mother.weapons`
- `Mother.current_weapon_index`

Оставить как тонкий прокси:
- `Mother.get_current_weapon() -> WeaponData` —
  `return warehouse.get_current_weapon()`.
- `Mother.apply_current_weapon_index(index_: int) -> void` — опционально;
  предпочтительно удалить и звать `Mother.warehouse.apply_current_weapon_index`.
  Если оставляем — тонкий прокси.

Все читатели `Mother.weapons` / `Mother.current_weapon_index` в коде
переводятся на `Mother.warehouse.*`.

## Изменения в `ForgeData` (`forge/forge_data.gd`)

- Поле `warehouse: WarehouseData` — устанавливается снаружи
  (`forge_data.warehouse = Mother.warehouse`) или читается напрямую.
  В `_init` не создаётся, у родителя не регистрируется.
- `init_with_weapon(weapon_)` — без изменений, читает решения из
  `weapon_name_to_solutions` (кэш остаётся в `ForgeData`).
- `refill_center()` — читает слитки из `warehouse` как раньше, но из
  общего пула.
- `apply_fusion()` — `warehouse.apply_removal(...)` теперь списывает
  из общего пула; поведение при исчерпании — как в шаге 10
  (warning, Fusion disabled).

## Input map

- `forge_prev_weapon` = `Q`
- `forge_next_weapon` = `E`
- `forge_prev_variant` = `A` — **не трогать**
- `forge_next_variant` = `D` — **не трогать**
- Q/E освободились в шаге 5 (удалены из просмотра решений). Возвращаем
  как prev/next weapon.

## Переключение оружия

`ForgeData.apply_weapon_switch(delta_: int) -> void`:
- `count = warehouse.get_weapons().size()`; `count == 0` → ранний выход;
- `new_index = posmod(warehouse.current_weapon_index + delta_, count)`;
- `warehouse.apply_current_weapon_index(new_index)`;
- `init_with_weapon(warehouse.get_current_weapon())`;
- `selected_ingot = null`; `center.apply_selection(null)`;
  `apply_highlight([])`;
- `weapon_switched.emit()`.

Сигнал `weapon_switched` (без параметров).

`ForgeData.init_with_weapon(weapon_)` — переподписать
`center.changed → recalc_right`, `left.changed → recalc_right` на новые
`MoldData`.

Сцена `Forge` (`forge/forge.gd`):
- `_unhandled_input`:
  - `forge_prev_weapon` → `data.apply_weapon_switch(-1)`;
  - `forge_next_weapon` → `data.apply_weapon_switch(+1)`;
  - `forge_prev_variant` / `forge_next_variant` →
    `data.apply_variant_change(-1 / +1)` — без изменений (шаг 9).
  - `get_viewport().set_input_as_handled()`.
- `_on_weapon_switched()`:
  - `%WeaponNameLabel.text = "Текущее оружие: %s" % data.get_current_weapon_name()`;
  - переустановить `data` у `%LeftMold` / `%CenterMold` / `%RightMold`;
  - `%FusionButton.disabled = not data.is_fusion_available()`.
- `connect_signals` подписывает `data.weapon_switched.connect(_on_weapon_switched)`
  и вызывает обработчик сразу (единый вид на старте).

## Открытые вопросы (notes.md)

- Общий склад: исчерпание формы блокирует Fusion на всех оружиях. Так
  задумано.
- `weapon_name_to_solutions` (кэш решений) остаётся в `ForgeData`, не
  пересоздаётся при переключении оружия.
- `Mother.weapons` / `Mother.current_weapon_index` удалены; `Mother.get_current_weapon()`
  остаётся как тонкий прокси без состояния.
- `current_weapon_index = 0` (chokuto) — как в шаге 6.
- Q/E в шаге 5 были удалены как навигация решений; здесь семантика другая
  (prev/next оружие) — конфликта нет.

## Чек-лист

- [x] `WarehouseData` живёт под `Mother`, создаётся в `Mother._ready`
      один раз, переживает переключения оружия и Fusion.
- [x] В `WarehouseData` есть `weapons: Array`, `current_weapon_index: int`,
      `get_weapons()`, `get_current_weapon()`,
      `apply_current_weapon_index()`, сигнал `current_weapon_changed`.
- [x] `Mother.weapons` и `Mother.current_weapon_index` удалены.
      Все читатели переведены на `Mother.warehouse.*`.
- [x] `Mother.get_current_weapon()` — тонкий прокси к `warehouse` (или
      удалён, если все места переведены на `Mother.warehouse.get_current_weapon()`).
- [x] `ForgeData.warehouse` — ссылка на `Mother.warehouse`, не создаётся
      в `_init` и не регистрируется.
- [x] `forge_prev_weapon = Q`, `forge_next_weapon = E` в InputMap.
- [x] Q/E переключают оружие, `%WeaponNameLabel` обновляется, выбор и
      подсветка снимаются.
- [x] A/D по-прежнему меняют вариант Ingot'а (шаг 9), никаких изменений.
- [x] Fusion списывает слитки из общего пула.
- [x] В шапках `docs/04`, `docs/06`, `docs/07` добавлено примечание
      «superseded by docs/18 в части …».
- [x] В `docs/notes.md`: warehouse под `Mother`; weapons+index в warehouse;
      Q/E — оружие, A/D — вариант; склад общий; кэш решений в ForgeData.
- [x] Консоль без ошибок.