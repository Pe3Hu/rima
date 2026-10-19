# Шаг 9. Выбор Piece и смена варианта Ingot'а (A / D)

**Цель.** Игрок кликает ЛКМ по Piece в центральной Mold — выбирается
Ingot, которому эта Piece принадлежит. `A` / `D` меняют вариант Ingot'а
из Warehouse той же формы. Правая Mold пересчитывается.

**Зависит от.** Шаги 7–8.

## Требования

### Выбор

- ЛКМ по `%CenterMold` → `%CenterMold.get_piece_at_global(pos)`:
  - найден Piece → `ForgeData.apply_selection(piece.ingot_data)`;
  - не найден (клик по пустой клетке) → `ForgeData.apply_selection(null)`.
- `ForgeData.apply_selection`:
  - `center.apply_selection(ingot_data_)` (устанавливает/снимает
    `selected_ingot`, шлёт `center.changed` → `recalc_right`);
  - обновляет `self.selected_ingot`;
  - эмитит `selection_changed`.
- Сцена `Mold` в `_on_changed` обводит **все** Piece, у которых
  `piece_data.ingot_data == data.selected_ingot`.
- Повторный ЛКМ по тому же Ingot'у — снять выбор (по умолчанию).
  Зафиксировать в `notes.md`.

### Смена варианта

- `ForgeData.apply_variant_change(delta_: int)`:
  - если `selected_ingot == null` — ранний выход;
  - `shape = selected_ingot.shape`;
  - `count = warehouse.get_variant_count(shape)`; если `count == 0` — выход;
  - новый индекс варианта у Warehouse — по индексу; **проблема**: у Ingot'а
    нет своего `variant_index` — только `thicknesses`. Нужно либо:
    - (A) хранить `variant_index` в `IngotData` (добавить поле в шаг 3;
      в шаг 3 не заложено — расширить здесь);
    - (B) искать вариант по `thicknesses` среди вариантов Warehouse
      (дороже, но без поля).
  - **Принять (A)**: добавить `variant_index: int` в `IngotData`.
    При генерации левого/правого/центрального Ingot'а заполнять корректно
    (для центрального — индекс варианта в Warehouse на момент генерации;
    для левого — согласовать с источником; если варианта нет в Warehouse —
    `variant_index = -1`).
  - `new_index = posmod(selected_ingot.variant_index + delta_, count)`;
  - `new_ingot = warehouse.get_variant(shape, new_index)`;
  - **не менять** `origin`, `rotation_steps`, `is_flipped` у старого
    `selected_ingot`: скопировать их в `new_ingot` перед подстановкой;
  - `center.update_ingot(new_ingot)`;
  - обновить `selected_ingot = new_ingot`;
  - эмитить `selection_changed`.
- Сцена `Forge` в `_unhandled_input` вызывает `data.apply_variant_change(-1)`
  / `(+1)` на экшены `forge_prev_variant` / `forge_next_variant`.
- Форма не меняется: все варианты одной формы имеют одинаковый `shape`
  и одинаковые `cells`.

### Обновление левой Mold

- Левая Mold — не редактируется. Выбор и смена варианта влияют только
  на центр и правую.

## Обновление `IngotData` (расширение шага 3)

- Добавить `variant_index: int` (по умолчанию `-1`).
- `init_with_thicknesses(shape_, thicknesses_, variant_index_ = -1,
  origin_ = Vector2i.ZERO, rotation_steps_ = 0, is_flipped_ = false)` —
  единый конструктор.
- При подстановке варианта в плейсмент — копировать `origin`/`rotation`/`flip`
  из старого Ingot'а.

## Правила

`rules/architecture.mdc`, `rules/gdscript-style.mdc`, `rules/scene-and-data.mdc`.

## Чек-лист

- [ ] ЛКМ по Piece центрует выбор на весь Ingot (все клетки подсвечены).
- [ ] Повторный ЛКМ снимает выбор (или иное поведение — по решению
      в `notes.md`).
- [ ] `A` / `D` меняют вариант с зацикливанием.
- [ ] При смене варианта `origin`/`rotation`/`flip` сохраняются.
- [ ] `variant_index` в `IngotData` консистентен с `warehouse.get_variant`.
- [ ] Правая Mold пересчитывается автоматически.
- [ ] Выбор и смена варианта не затрагивают левую Mold.
- [ ] Консоль без ошибок.