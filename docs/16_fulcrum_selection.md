# Шаг 16. Клик по Fulcrum — подсветка суммы и piece'ов

**Цель.** ЛКМ по Fulcrum подсвечивает его значение и все piece'ы его stratum'а.

**Зависит от.** Шаг 15.

## Данные (`MoldData`)
- Поле `highlighted_pieces: Array` — ссылки на `PieceData` (без вложенного типа). По умолчанию пусто.
- Сигнал `highlight_changed`.
- Метод `apply_highlight(pieces_: Array) -> void` — заменить массив, эмитить `highlight_changed`. Пустой массив — снять подсветку.

## `ForgeData`
- Метод `apply_stratum_highlight(stratum_: StratumData) -> void`:
  - если `stratum_ == null` — `left.apply_highlight([])`;
  - иначе — `left.apply_highlight(stratum_.pieces)`.
- Ничего больше; сигнал `highlight_changed` пробрасывается сцене через `left`.

## Сцена `Fulcrum`
- ЛКМ (левая кнопка мыши) в `_gui_input(event)`: `event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT` → `pressed.emit()` и `accept_event()`.
- Свойство `is_highlighted: bool` — сеттер меняет цвет Label (обводка / яркий цвет).

## Сцена `Stratum`
- Подписан на `fulcrum.pressed` → эмитит наружу `fulcrum_pressed(stratum_: StratumData)`.
- Проброс в `Mold` (см. ниже).

## Сцена `Mold`
- `_on_highlight_changed()`:
  - для каждого `Piece`-ребёнка: если его `data` в `data.highlighted_pieces` → включить обводку (как при выборе Ingot'а, но с другим цветом или только рамкой — переиспользовать существующий механизм подсветки Piece в `Mold`); иначе — снять.
  - для каждого `Stratum`/`Fulcrum` в `%StrataLayer`: `fulcrum.is_highlighted = (fulcrum.data.pieces пересекается с data.highlighted_pieces)` — практически достаточно сравнить `fulcrum.data.pieces == data.highlighted_pieces` или проверить вхождение первого элемента.
- В `init_strata()` (шаг 15) подписать `stratum.fulcrum_pressed.connect(_on_fulcrum_pressed)`.
- `_on_fulcrum_pressed(stratum_)` → `data.apply_highlight(stratum_.pieces)`.

## Сцена `Forge`
- В `_unhandled_input(event)`: если ЛКМ и клик не попал ни в один Fulcrum (проверять через `%LeftMold` — попадание вне `%StrataLayer` или явно: ни один Fulcrum не принял событие) → `data.left.apply_highlight([])`. Проще: подписаться на глобальный клик через `_unhandled_input` в `Mold` и снимать подсветку, если клик не по Fulcrum (Fulcrum делает `accept_event`, поэтому глобальный обработчик увидит только «не Fulcrum» клики).

## Поведение
- Повторный ЛКМ по тому же Fulcrum — переключить (снять / оставить). **По умолчанию — переключение** (снять). Зафиксировать в notes.
- Клик по другому Fulcrum — переключить подсветку на новый.

## Чек-лист
- [x] Fulcrum принимает клики (`accept_event`).
- [x] Клик подсвечивает Fulcrum визуально.
- [x] Клик подсвечивает все piece'ы stratum'а (обводкой, как у выбранного Ingot'а).
- [x] Клик по другому Fulcrum переключает.
- [x] Повторный клик снимает подсветку.
- [x] Клик вне Fulcrum снимает подсветку.
- [x] Сцена не мутирует `data.*` напрямую (только через `apply_*` методы `ForgeData` / `MoldData`).
- [x] Консоль без ошибок.