# Шаг 13. Слой Part и переключение слоёв (1 / 2)

**Цель.** Второй `TileMapLayer` — Part (spine/bevel) — параллельно существующему слою Ingot. Переключение между ними кнопками 1 / 2.

**Зависит от.** Шаг 12.

## Требования

### Данные
- `Digest.part_to_color: Dictionary` — `Bozo.Part → Color` (два различимых цвета).
- Если размер клетки у Part такой же, как у Ingot, дополнительный `Catalog`-ключ не вводить; иначе `Catalog.PART_CELL_SIZE`.

### Enum `Bozo.Layer`
- `NONE = 0`, `INGOT`, `PART` (продолжая общий ряд). Строковые имена — `ingot`, `part`.

### Тайлсет
- `forge/part/part.tres` — тайлсет как у Ingot (`capsule.png`, клетка 64×64).
- Цвет слоя — `modulate` из `Digest.part_to_color`.

### Сцена `Mold` (`forge/mold/mold.gd`, `mold.tscn`)
- `%Parts` — `Node2D`, как `%Ingots`. Внутри — экземпляры сцены `Part` (`forge/part/part.tscn`, `TileMapLayer`), по одному на spine и bevel.
- `init_parts()` при пересборке слоёв: `part.data = PartData` из шаблона.
- Видимость `%Parts` управляется снаружи (см. `ForgeData.display_layer`). Piece-Label с толщиной продолжает отображаться всегда.

### `ForgeData`
- Поле `display_layer: Bozo.Layer`, по умолчанию `INGOT`.
- Сигнал `display_layer_changed`.
- Метод `apply_display_layer(layer_: Bozo.Layer) -> void` — no-op, если совпадает; иначе обновить и эмитить.

### Сцена `Forge`
- Две UI-кнопки `%IngotLayerButton` (label «1») и `%PartLayerButton` (label «2»).
- Дополнительно — обработка клавиш `KEY_1` и `KEY_2` в `_unhandled_input` сцены Forge (как алиасы).
- Обе кнопки → `data.apply_display_layer(Bozo.Layer.INGOT / PART)`.
- `_on_display_layer_changed()` в сцене Forge: для каждой из `%LeftMold`, `%CenterMold`, `%RightMold` переключить видимость `%Ingots` и `%Parts`.
- Начальное состояние — оба обработчика вызываются сразу в `connect_signals`, чтобы вид совпал с данными.

## Открытые вопросы (в notes.md)
- Piece-Label видим в обоих режимах (по умолчанию — да). Если нужен режим «только Part» — отдельная задача.

## Чек-лист
- [x] `Bozo.Layer` и `Digest.part_to_color`.
- [x] `forge/part/part.tres` — тайлсет как у Ingot. Сцена `Part` рисует spine и bevel.
- [x] `%Parts` в `Mold` (Node2D, как `%Ingots`). Сцена `Part` собирается в `init_parts`.
- [x] `ForgeData.display_layer` + сигнал + метод `apply_display_layer`.
- [x] Кнопки 1 / 2 (и клавиши 1 / 2) переключают видимость слоёв на всех трёх Mold.
- [x] Piece-Label остаётся видимым.
- [x] Консоль без ошибок.