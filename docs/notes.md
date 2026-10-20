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
- `Bozo.Part`: `NONE = 0`, `SPINE = 18`, `BEVEL = 19`. `Type.PART = 20`. Строки регистра — `spine` и `bevel`.
- `spine` и `bevel` в `tasks/<weapon>.json` лежат внутри `board`, рядом с `holes`: массив пар `[x, y]`. Нет ключа — пустой массив, `get_part_at` даёт `NONE`. У `shield` этих полей нет.
- `PieceData.part` проставляется при пересборке Piece'ов в `Mold.init_pieces` (`template.get_part_at`). Левая, центральная и правая Mold — один шаблон, на одинаковых клетках `part` совпадает.
- `Bozo.Layer`: `NONE = 0`, `INGOT = 21`, `PART = 22`. `Type.LAYER = 23`. Строки регистра — `ingot` и `part`.
- `Digest.part_to_color`: `SPINE` — `#0077bb`, `BEVEL` — `#ee7733`. Клетка Part — `Catalog.MOLD_CELL_SIZE` (64), отдельного ключа нет.
- Part устроен как Ingot: `PartData` + сцена `forge/part/part.tscn` (`TileMapLayer`, тайлсет `part.tres` — копия тайлсета Ingot). В `Mold` контейнер `%Parts` (`Node2D`), как `%Ingots`. На шаблоне два экземпляра: spine и bevel. Цвет — `modulate` слоя.
- Видимость `%Ingots` и `%Parts` на всех трёх Mold задаёт `ForgeData.display_layer` (по умолчанию `INGOT`). Кнопки 1/2 и клавиши `KEY_1` / `KEY_2`.
- Piece-Label с толщиной виден в обоих режимах слоёв. Режим «только Part» без подписи — отдельная задача.
- Флаги симметрии в `tasks/<weapon>.json`, top-level: `is_horizontal_symmetric` и `is_fully_symmetric`. По умолчанию `false`, пользователь задаёт их руками.
- `is_fully_symmetric` важнее `is_horizontal_symmetric`: горизонтальный флаг при полной симметрии не используется. Конфиг — четыре `RAZOR` (`RIGHT`, `LEFT`, `TOP`, `BOTTOM`), без `SPIKE`. `TOP`/`BOTTOM` остаются вертикальными по обходу; Fulcrum для них — шаг 15.
- Stratum идёт от края входа и обрывается на первой пустой клетке. Клетки за разрывом в этот stratum не входят.
- `Bozo.Stratum`: `NONE = 0`, `RAZOR = 24`, `SPIKE = 25`. `Bozo.Direction`: `NONE = 0`, `RIGHT = 26`, `LEFT = 27`, `TOP = 28`, `BOTTOM = 29`. В `Type` не регистрировались. `MoldData.recalc_strata` вызывается из `Mold._rebuild` после пересборки Piece'ов. Сигнал `changed` не менялся. Результат — `MoldData.strata`, сигнал `strata_changed`.
- Валидный stratum — только отрезок BEVEL → SPINE: первый piece — `BEVEL`, последний — `SPINE`, длина не меньше 2. Только-SPINE, только-BEVEL и отрезок, начатый со SPINE, не создаются. Так Fulcrum шага 15 встаёт у входа, а тело stratum'а — это spine за скосом.
- `part == NONE` обрывает обход так же, как пустая клетка. Второй `BEVEL` тоже останавливает обход, и эта клетка в `pieces` не входит. В созданном stratum'е ровно один `BEVEL`, на позиции 0.
- Вход всегда с крайней клетки линии, и валидный stratum с неё начинается. Поэтому край входа у stratum'а совпадает с краем линии: `RIGHT` — max x, `LEFT` — min x, `TOP` — min y, `BOTTOM` — max y. Дальний конец — последний SPINE и может не доходить до противоположного края. Для Fulcrum берётся край по клеткам stratum'а.
- Strata рисуются только на левой Mold: `shows_strata = true` у `%LeftMold`, у центральной и правой — `false`. `Digest.fulcrum_color` — `#ffe066`. `FulcrumData` хранит `coord`, `sum` и `pieces` и не ссылается на `StratumData`.
- На текущем левом `chokuto` 21 Fulcrum стоят в разных клетках, совпадений нет. Если соседние stratum'ы займут одну клетку — сдвигать наружу; решать в шаге 16 или отдельной задачей.
- У `Fulcrum` уже есть сигнал `pressed`, у `Stratum` — `fulcrum_pressed`. Слушатель не подключён: это шаг 16.
- Повторный клик по тому же Fulcrum снимает подсветку, если piece'ы этого stratum'а уже в `highlighted_pieces`. Клик по другому Fulcrum переключает набор. Выбор Ingot'а в центре (шаг 9) эту подсветку не трогает.
- Снятие кликом вне Fulcrum: Fulcrum вызывает `accept_event()`, поэтому `_unhandled_input` сцены Forge видит только остальные клики и зовёт `left.apply_highlight([])`. Клик по piece центра туда не приводит.
- Цвета: `Digest.fulcrum_color_highlight` — `#ffffff`, `Digest.stratum_highlight_color` — `#b8ff4d` (обводка толщины). База Fulcrum — `Digest.fulcrum_color`.

## Известные ограничения

- Массово суффикс `_` у параметров солвера не проставлялся.

## Конфликты правил с текущим кодом

- Имена в `docs/` приведены к файлам `rules/`: `feature-structure.mdc`, `bozo-enums.mdc`, `gdscript-style.mdc`, `scene-and-data.mdc`. Содержательного конфликта не было.
- Правило: `*Data` — `RefCounted`. Согласованное исключение: `ShapeData` остаётся `Resource`, потому что статические фигуры лежат в `.tres`. Игровое состояние — `RefCounted`.
- Правило: `class_name` совпадает с файлом. У автозагрузок `class_name` нет: имя синглтона уже занимает глобал (`Mother`, `Helper`, …). Иначе Godot ругается на конфликт.
- `Helper.gd` и `Digest.gd` названы с заглавной буквы. Не переименовывались: uid в `project.godot` смотрит на эти пути. Новые автозагрузки — строчные `mother.gd`, `bozo.gd`, `catalog.gd`, `gear.gd`.
- `tools/` и `tests/` не фичи игры. Это не запрещённые `scripts/` / `scenes/` / `datas/` / `components/`. Путь `res://tools/run_task.gd` оставлен.

## Приёмка Part / Stratum / Fulcrum

Прогон headless на сцене `forge.tscn`: те же узлы, кнопки, клавиши и `apply_*`, без взгляда в окно редактора. Временный зонд в `forge.gd` удалён. В `tests/run_all.gd` проверки не добавлялись: запуск через `-s` не видит автозагрузки, а `MoldTemplateData` на них опирается.

Коды strata: `24-26` Razor-RIGHT, `24-27` Razor-LEFT, `24-28` Razor-TOP, `24-29` Razor-BOTTOM, `25-28` Spike-TOP.

### Ручные сценарии

| Сценарий | Результат | Комментарий |
|---|---|---|
| 1. spine/bevel | pass | `chokuto`: (0,1) SPINE, (2,0) BEVEL, клетка вне — NONE. `shield` без полей грузится, `get_part_at` даёт NONE. `part` на трёх Mold совпадает с шаблоном. |
| 2. слои 1/2 | pass | Кнопки и клавиши 1/2. На всех трёх Mold Ingot и Part переключаются. Два цвета Part. Piece-Label виден в обоих режимах. |
| 3. default | pass | `chokuto`: 19 Razor-RIGHT и 2 Spike-TOP. Fulcrum справа и сверху, сумма верна, клетки подряд, один BEVEL в начале. `saber` тоже оба направления. `falchion` — только Razor-RIGHT. `greatsword` — пусто: край входа не даёт BEVEL→SPINE. |
| 4. горизонтальная симметрия | pass | Razor-LEFT и Fulcrum слева: axe 2, longsword 10, spear 3, trident 2. Spike-TOP в конфиге остаётся, на этих силуэтах не рисуется. `hammer` — ни одного stratum. |
| 5. полная симметрия | fail | Spike нигде не создаётся. Все 4 направления сразу не рисуются: `shuriken` — LEFT, TOP, BOTTOM, без RIGHT; `shield` — флаг есть, полей spine/bevel нет, strata пустые. |
| 6. сумма | pass | `FulcrumData.sum` равен сумме толщин. После Fusion на `chokuto` сумма Fulcrum'ов 97 → 381. |
| 7. клик | pass | Подсветка Fulcrum и всех piece'ов, повторный клик снимает, другой Fulcrum переключает, клик вне снимает. Центр и право без узлов strata. |
| 8. регрессии | pass | Клик по piece центра не снимает левую подсветку. A меняет вариант (0→2). Fusion работает. Слои 1/2 не сбрасывают выбор и не гасят Fusion. Q/E в игровых действиях нет; keycode E есть только у встроенного `ui_text_caret_line_end.macos`. |

### Автоматические проверки

| Проверка | Результат | Комментарий |
|---|---|---|
| `get_part_at` spine/bevel/вне | pass | `chokuto` и пустой `shield`. |
| default: ≥1 Razor-RIGHT и ≥1 Spike-TOP | pass | `chokuto`, `saber`. Не у каждого оружия без флагов. |
| horizontal: ≥1 Razor-LEFT | pass | axe, longsword, spear, trident. |
| full: нет SPIKE | pass | `shield`, `shuriken`. |
| full: все 4 direction в strata | fail | Ни одно текущее fully-symmetric оружие не даёт все четыре. |
| `FulcrumData.sum` | pass | На всех непустых strata, и на сцене после клика. |

Консоль этого прогона без новых ошибок и предупреждений.

### Открытые вопросы и ограничения после итерации

- Пополнение склада и сообщение «металл закончился» — вне этого фронта.
- Переключения оружия в игре нет. Флаги проверялись по уже загруженным `Mother.weapons`, не кнопкой в сцене.
- Перекрытие Fulcrum'ов соседних stratum'ов на `chokuto` не встретилось. Если появится — сдвиг наружу, отдельная задача.
- Режим «только Part» без Piece-Label не делался.

### Следующая итерация

Силуэты и правило BEVEL→SPINE расходятся с ожиданием «все запрошенные стороны видны». Не чинилось: JSON и правило входа в этом шаге не меняются.

- `greatsword`, `hammer`: strata пустые.
- Оружие с горизонтальной симметрией не рисует Spike-TOP.
- `shuriken` при полной симметрии без Razor-RIGHT.
- `shield` с `is_fully_symmetric` не имеет spine/bevel.

Нужно решить, править раскладку spine/bevel в `tasks/<weapon>.json` или ослаблять вход stratum'а. Это отдельная задача, не баг обхода.

## Шаг 19 — фикс подсветки

Обрыв шага 16 не в сигналах и не в ссылках `PieceData`: `Fulcrum.pressed` доходит до `left.apply_highlight`, и piece'ы stratum'а — те же экземпляры, что на сцене (`MoldData._coord_to_piece`, вариант 1 уже был). `Piece._show_thickness` писал outline в theme, а Label рисует контур из общего `LabelSettings` и theme игнорирует. Fulcrum — Button, поэтому подсвечивался.

У каждой клетки своя копия `LabelSettings`. `Piece.is_selected` и `Piece.is_highlighted` разделены. Оба включены — `Digest.stratum_highlight_color`, только выбор — `Digest.selection_color` (`#9ecbff`), иначе базовый тёмный контур. Вариант 2 не использовался.

## Шаг 18 — warehouse-рефактор

`WarehouseData` живёт под `Mother` (`Mother.warehouse`), создаётся один раз в `Mother._ready`. `weapons` и `current_weapon_index` переехали в склад. `Mother.weapons` и `Mother.current_weapon_index` удалены. `Mother.get_current_weapon()` — прокси без своего состояния. `ForgeData.warehouse` — ссылка на `Mother.warehouse`, в `_init` не создаётся.

Q/E — предыдущее/следующее оружие (`forge_prev_weapon` / `forge_next_weapon`). A/D по-прежнему меняют вариант Ingot'а. Q/E в шаге 5 убрали как навигацию решений; здесь другая семантика, конфликта нет.

Слитки общие на все оружия. Fusion списывает из одного пула: на прогоне 36 → 24 на `chokuto`, затем 24 → 12 на `axe`. Исчерпание формы блокирует Fusion на всех оружиях. Кэш решений `weapon_name_to_solutions` остаётся в `ForgeData` и переживает переключение.
