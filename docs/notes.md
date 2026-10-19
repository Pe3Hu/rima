# Notes — решения и ограничения

## Конспект правил (шаг 1)

- Архитектура: сцена (`Node`) показывает, `*Data` хранит состояние и правила. Корень создаёт только `Mother` в `_ready`. Чтение — `Mother.hull`, не поиск по дереву.
- Автозагрузки: `Mother` (корневые data), `Helper` (общие функции и `Helper.rng`), `Bozo` (enum), `Digest` (таблицы), `Catalog` (числа и списки), `Gear` (длительности). Новые не заводить. Ход раунда, выбор, подсветка и обучение — уже занятые роли, к этому шагу не относятся.
- Структура: папка фичи держит скрипт, data, сцену, картинки и шейдер. Общих `scripts/`, `scenes/`, `datas/`, `components/` нет. Вложенность повторяет владение. Общее — в `global/`.
- Enum: только `Bozo`, у каждого `NONE = 0`, остальные значения не пересекаются. Строка — `Bozo.enum_to_string`.
- Сцена: единственный вход — сеттер `data`. Он раздаёт детей, подписывает сигналы и собирает экземпляры. Состояние меняется в data, сцена в `_on_*` только рисует.
- Имена: `class_name` совпадает с файлом (`hull.gd` — `Hull`, `hull_data.gd` — `HullData`). Параметр с `_`, типы на месте. `bool` — `is_*`. Чтение — `get_`, изменение — `apply_` / `update_` / `refill_` / `recalc_`, сборка — `init_` / `add_`.

## Карта модулей (шаг 1)

| Файл | Ответственность | Что меняем |
|---|---|---|
| `global/mother.gd` | создаёт `HullData` | новый автозагруз |
| `global/bozo.gd` | реестр enum | новый, без форм пентамино (шаг 2) |
| `global/catalog.gd` | `PROGRESS_EVERY` | новый |
| `global/gear.gd` | длительности твинов | новый, анимаций пока нет |
| `global/Helper.gd` | `rng`, `clear_children` | типы у подписей |
| `global/Digest.gd` | `shape_to_color` | типы у подписей |
| `entities/hull/hull.gd` + `hull.tscn` | рисует доску и фигуры, Q/E | состояние ушло в `HullData`, фон через `@export` |
| `entities/hull/hull_data.gd` | задача, композиции, индекс | новый корень `Mother.hull` |
| `entities/hull/module/module.gd` | одна фигура на доске | вход `data`, не `allocation` |
| `entities/world/world.gd` | корень сцены, Escape | без изменений смысла |
| `entities/hull/composition/*` | загрузка JSON, DLX, проверки | имена классов под файлы; data → `RefCounted`, кроме `ShapeData` |
| `tools/task_runner.gd`, `tools/run_task.gd` | прогон задачи в `out/` | шаг прогресса из `Catalog` |
| `tests/run_all.gd` | проверки солвера | шаг прогресса остался литералом `100` |
| `tasks/`, `out/` | доски и готовые решения | не трогаем |

## Переносы и переименования

- `loader_data.gd` → `composition_loader.gd` (`CompositionLoader`)
- `canonicalizer_data.gd` → `solution_canonicalizer.gd` (`SolutionCanonicalizer`)
- `dlx/solver_dlx.gd` → `dlx/dlx_solver.gd` (`DlxSolver`)
- `dlx/receiver_dlx.gd` → `dlx/dlx_solution_receiver.gd` (`DlxSolutionReceiver`)
- `dlx/matrix_dlx.gd` → `dlx/dlx_matrix.gd` (`DlxMatrix`)
- `dlx/cell_dlx.gd` → `dlx/dlx_cell.gd` (`DlxCell`)
- `dlx/header_dlx.gd` → `dlx/dlx_column_header.gd` (`DlxColumnHeader`)
- Новые: `hull_data.gd`, `global/mother.gd`, `global/bozo.gd`, `global/catalog.gd`, `global/gear.gd`

`tasks/` и `out/` остаются на месте. В `forge/boards/` и `forge/solutions/` не переносились: формат и пути в JSON менять нельзя.

## Принятые решения

- Корень просмотра — `Mother.hull: HullData`. Сцена `Hull` назначает `data`, вешает палитру `Digest.bind_pieces` и рисует. Цвет — часть вида, data его не считает.
- При запуске через `-s` / `--script` `Mother` создаёт `HullData`, но не читает `active_task.txt`, чтобы солвер и тесты не открывали доску просмотрщика.
- Q — предыдущее решение, E и пробел — следующее, Escape — выход. Коды клавиш те же, InputMap не вводился.
- Поле оружия в `tasks/board_xxx.json` — `weapon` (значение вроде `shield`, `chokuto`). Не `weapon_name`.
- `ShapeData` остаётся `Resource`: это статические `.tres` фигур. Игровое состояние — `RefCounted`. Других исключений нет.
- Активная доска просмотрщика — `res://tasks/board_4x16.json` (`tasks/active_task.txt`).
- `Hull` ставится так, чтобы центр прямоугольника доски совпал с центром экрана. Размер клетки берётся из тайлсета `Background`.
- Подложку рисует отдельный узел `Background`: по клетке на каждую свободную клетку доски. Модули её не заполняют.
- Параметр и локальные `set` переименованы в `piece_set`: имя затеняло `Object.set`.
- Шаг печати прогресса — `Catalog.PROGRESS_EVERY` (100) в `TaskRunner`. `tests/run_all.gd` оставлен с литералом `100`: скрипт, запущенный через `-s`, не видит имена автозагрузок на компиляции. Пороги внутри DLX не выносились.
- `Gear.appears[0] = 0.0`: твинов в прототипе нет.
- `Bozo.Shape`: F…Z = 1…12 в порядке F, I, L, P, N, T, U, V, W, X, Y, Z. `Type.SHAPE = 13`. Оба enum имеют `NONE = 0`.
- `Digest.shape_to_cells` — клетки 12 форм в порядке `.tres`. Индекс толщины слитка — индекс в этом массиве. `Dictionary[Bozo.Shape, Array]` без вложенного `Array[Vector2i]` / `Array[IngotData]` — ограничение Godot 4.4. Проверка типа на вызывающей стороне. Тот же паттерн для `BoardData`, `ForgeData` и дальше.
- `IngotData` допускает 0 как пустой слиток. `is_valid()` проверяет только `>= 0`, совпадение длины и что форма не `NONE`. `WarehouseData` генерирует только `Catalog.THICKNESS_MIN..THICKNESS_MAX` (1..5). Ноль в склад не попадает.
- Склад живёт только под `ForgeData`: `WarehouseData` создаётся в `ForgeData._init`. Seed не задаётся, толщины 1..5. `apply_removal` снимает один экземпляр по форме и толщинам; после этого число может стать меньше 36.
- Чёрная обводка — узел `Background` (`forge/mold/background.gd`), `TileMapLayer` позади `Ingot`. В git репозитория нет, исходный `background.png` был удалён вместе с Hull; тайлсет пересобран как у старого Hull: текстура 80×80, клетка 64×64, `set_cell` на каждую свободную клетку шаблона (`MoldData.coords`), не только клетки фигур. Это не `ingot.tres`.
- `out/compositions_7x14.json` — без пары в `tasks/`, не загружается Forge.
- Формат `tasks/board_xxx.json`, поля которые читает `BoardTemplateData`: `id`, `name`, `weapon` (в data это `weapon_name`), `board.type`, `board.width`, `board.height`, `board.holes`, `pieces.source`, `symmetry`, `solver.max_solutions`, `solver.dedupe_by_symmetry`, `solver.anchor_policy`, `output.format`, `output.path`. Тип доски в текущих файлах — `rect_with_holes`. Папка — `Catalog.TASKS_PATH`, не зашита в шаблон.
- Солверная маска переименована в `MaskBoardData` (`mask_board_data.gd`): глобальное имя `BoardData` нужно кузнечной доске. Логика Q/E не менялась.
- Плейсмент: `is_flipped` отражает X, затем `rotation_steps` крутит по часовой на 90° (как `OrientationData`), мир = `origin` + локальная клетка. Повторной нормализации нет.
- Сцена `Board` рисует от (0, 0) и сама не центрируется. В virtual-режиме поверх клеток шаблона рисуется `virtual_thickness_map`.
- Стартовые толщины left-Mold = 1 на каждую клетку: решение из `out/` толщин не содержит, это плоский слой до ковки. Так остаётся в шаге 7 и после Fusion: левые толщины растут за счёт центра.
- `chokuto` — индекс 0. Пустой или отсутствующий `out/<weapon>.json` даёт пустую Mold.
- После исключения текущего левого решения список может опустеть (одно решение в файле). Тогда `refill_center` берёт любое из исходного списка, чтобы не застрять.
- Оружие без решений: `refill_center` пишет предупреждение и оставляет центр пустым. Fusion недоступен: в центре нет 12 слитков со склада.
- Кэш решений лежит в `ForgeData.weapon_name_to_solutions` и ключуется именем оружия, JSON не парсится заново на каждый `refill_center`.
- Отдельная команда «другое решение» вне Fusion отложена на потом, не в этой итерации. Ручная пересборка центра — будущая фича, не часть базовой механики.
- Временный просмотр `forge/mold/mold_preview.tscn` удалён. F5 открывает `res://forge/forge.tscn`.
- Fusion ограничен запасом Warehouse: на старте 36 слитков, каждый Fusion списывает 12, доступны ровно 3. Пополнение склада — за рамками этой итерации.
- Перерисовка Fusion идёт одним сигналом `fusion_applied`. Левая и правая Mold при той же раскладке обновляют только числа, без новых сцен. Центр пересобирается, когда решение другое. Повторный разбор `out/` не делается: решения уже в `weapon_name_to_solutions`. Если толщины правой Mold не изменились, её Ingot'ы не создаются заново.
- Baseline Fusion на `chokuto`, headless, время до обновления сцены: 26 мс, 33 мс и 5 мс на трёх Fusion подряд. Порог 100 мс. Предупреждение об исчерпании склада пишется после обновления сцены.
- После исчерпания склада центр пустой, Fusion disabled. Сообщение игроку «металл закончился» — открытый вопрос UX, не в этой итерации.
- `apply_removal` не нашёл слиток в складе: warning, Fusion не падает. Редкий случай, thicknesses центра и склада обычно совпадают.
- `Hull`/`Module`/`Capsule` переименованы в `Mold`/`Ingot`/`Piece` и лежат в `forge/`. `MaskBoardData` и DLX не переименовывались.
- `tasks/board_*.json` → `tasks/<weapon>.json`, `out/compositions_*.json` → `out/<weapon>.json`. В JSON изменено только `output.path`.
- `IngotData` хранит `origin`, `rotation_steps` (0..3), `is_flipped`, `variant_index`. Мир = origin + отражение X + поворот по часовой. `get_thickness_at` даёт -1 вне слитка. `IngotPlacementData` удалён.
- Повторный ЛКМ по тому же Ingot'у центра снимает выбор (`apply_selection(null)`). Клик по пустой клетке шаблона тоже снимает выбор. Клик вне центральной Mold игнорируется.
- Если у формы в складе не осталось вариантов (`get_variant_count == 0`), `apply_variant_change` ничего не делает.
- Склад и выбор решения центра — non-seeded `Helper.rng`.

## Известные ограничения

- Массово суффикс `_` у параметров солвера не проставлялся.

## Конфликты правил с текущим кодом

- Имена в `docs/` приведены к файлам `rules/`: `feature-structure.mdc`, `bozo-enums.mdc`, `gdscript-style.mdc`, `scene-and-data.mdc`. Содержательного конфликта не было.
- Правило: `*Data` — `RefCounted`. Согласованное исключение: `ShapeData` остаётся `Resource`, потому что статические фигуры лежат в `.tres`. Игровое состояние — `RefCounted`.
- Правило: `class_name` совпадает с файлом. У автозагрузок `class_name` нет: имя синглтона уже занимает глобал (`Mother`, `Helper`, …). Иначе Godot ругается на конфликт.
- `Helper.gd` и `Digest.gd` названы с заглавной буквы. Не переименовывались: uid в `project.godot` смотрит на эти пути. Новые автозагрузки — строчные `mother.gd`, `bozo.gd`, `catalog.gd`, `gear.gd`.
- `tools/` и `tests/` не фичи игры. Это не запрещённые `scripts/` / `scenes/` / `datas/` / `components/`. Путь `res://tools/run_task.gd` оставлен.
