# Шаг 19. Исправление: клик по Fulcrum не подсвечивает piece'ы

**Цель.** Починить баг шага 16: `Fulcrum` визуально подсвечивается, а
`Piece` его stratum'а — нет.

**Зависит от.** Шаг 16 (выполнен).

## Диагностика (проверить в этом порядке)

1. **Сигнал `fulcrum.pressed` не доходит до `Mold`**:
   - В сцене `Stratum` `_init_fulcrum` подписывает
     `fulcrum.pressed.connect(_on_fulcrum_pressed)`?
   - В сцене `Mold` `init_strata()` подписывает
     `stratum.fulcrum_pressed.connect(_on_fulcrum_pressed)`?
   - `Fulcrum._gui_input` эмитит `pressed` и вызывает `accept_event()`?
     `mouse_filter == STOP`?
2. **`ForgeData.apply_stratum_highlight` применяет к правильной Mold**:
   - `left.apply_highlight(stratum_.pieces)` — именно `left`, потому что
     `shows_strata=true` только у `%LeftMold`.
3. **`Mold._on_highlight_changed` не перекрашивает Piece'ы**:
   - `PieceData` — `RefCounted` без `_eq`, сравнение `piece in
     highlighted_pieces` идёт по ссылке. Убедиться, что
     `StratumData.pieces` содержат **те же** экземпляры, что `Mold._on_changed`
     создаёт/обновляет.
   - Если `Mold._on_changed` каждый раз пересоздаёт `PieceData`, а
     `StratumData.pieces` держат старые — сравнение не сработает.
4. **`_on_highlight_changed` вообще вызывается**:
   - `Mold.connect_signals` подписан на `data.highlight_changed`?
   - Подписка не потеряна при повторных `data = ...`?
5. **Механизм подсветки Piece один на выбор Ingot и stratum**:
   - Если Piece-обводка смотрит только на `selected_ingot`, а не на
     `highlighted_pieces`, piece'ы не подсветятся. Нужно разделить:
     `Piece.is_selected` (выбранный Ingot, шаг 9) и `Piece.is_highlighted`
     (stratum, шаг 16). Итоговая обводка учитывает оба флага — приоритет
     цвета/стиля по `Digest`.
6. **Штатный лог**:
   - Временно `print` в `Mold._on_fulcrum_pressed` (передан stratum_) и
     `_on_highlight_changed` (размер `highlighted_pieces`). Прогнать клик,
     найти обрыв. Убрать после фикса.

## Минимальный фикс

- Восстановить недостающие подключения (п. 1).
- Привести `apply_highlight` к `left` (п. 2).
- Синхронизировать `PieceData` между `MoldData` и `StratumData.pieces`:
  - **Вариант 1 (предпочтительный)**: `MoldData.cell_to_piece: Dictionary`
    заполняется в `Mold._on_changed`. `recalc_strata` и
    `_on_highlight_changed` читают из кэша. Piece'ы не пересоздаются,
    если клетка не менялась.
  - **Вариант 2 (быстрый)**: `MoldData.highlighted_coords: Dictionary`
    (`Vector2i → true`), `apply_highlight` строит по `pieces`,
    `_on_highlight_changed` сверяет по `piece.coord`. Точечный фикс
    шага 16, не ломает шаги 14–15.
- Разделить `Piece.is_selected` и `Piece.is_highlighted`; `Mold`
  устанавливает оба флага через сеттеры `Piece`. Обводка — одна, но с
  цветом по приоритету (`stratum_highlight_color` при подсветке,
  `selection_color` при выборе, если оба — приоритет за подсветкой
  stratum'а; зафиксировать в notes.md).

## Не делать

- Не переписывать генерацию stratum (шаг 14) и размещение Fulcrum
  (шаг 15).
- Не менять правило BEVEL→SPINE.
- Не менять форму `StratumData.pieces` (порядок BEVEL → SPINE).

## Чек-лист

- [x] Место обрыва цепочки найдено и зафиксировано в `notes.md`
      (1–2 предложения).
- [x] ЛКМ по Fulcrum: сам Fulcrum подсвечен **и** все piece'ы его
      stratum'а подсвечены.
- [x] Повторный ЛКМ — снятие подсветки с Fulcrum и piece'ов.
- [x] ЛКМ по другому Fulcrum — переключение.
- [x] Клик вне Fulcrum — снятие.
- [x] Выбор Ingot'а (шаг 9) и stratum-подсветка независимы: клик по
      piece'у в центре не снимает stratum на левой; клик по Fulcrum
      не меняет `selected_ingot`.
- [x] Консоль без ошибок.