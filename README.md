# Teron's What's Training?

A World of Warcraft **Vanilla 1.12.1** addon that tells you, at a glance, every spell your
class can ever learn — which ones you can train right now, which ones are coming up as you
level, which ones you're missing a requirement or talent point for, and which ones you've
told it to stop bothering you about.

This is Kaloyan "Terongorus" Kolev's personal fork of the community **WhatsTraining**
backport, targeting pure Vanilla 1.12.1 servers such as **TwinStar Kronos V**.

> **Looking for the Turtle WoW version?** That's a separate sibling fork,
> **[TeronWhatsTraining-TW](../TeronWhatsTraining-TW)**. Turtle WoW's custom class spells
> differ enough from pure Vanilla's that the two addons can't share a spell database — hence
> two separate forks instead of one addon trying to detect and support both rulesets.

---

## What it actually shows you

Every spell in your class's full trainable list gets sorted into one of nine buckets:

| Category | Meaning |
|---|---|
| **Available now** | You meet the level, prerequisite, and talent requirements — go train it. |
| **Available but missing requirements** | Level's fine, but you're missing a prerequisite spell/rank. |
| **Coming soon** | Within 2 levels of being available. |
| **Not yet available** | More than 2 levels away. |
| **Pet Abilities** | Trainable hunter pet abilities not yet known. |
| **Missing required talent** | You need to spend a talent point before this unlocks. |
| **Ignored** | Spells you've explicitly told WhatsTraining to stop showing. |
| **Known** | Spells you already have. |
| **Known (Pet)** | Pet abilities / warlock grimoires your pet already knows. |

Every entry shows its rank, level requirement, training cost (colored red if you can't
currently afford it), and a full tooltip — mana cost, range, cast time, cooldown, and
description — synthesized from a companion spell-description database, since unlearned
spells don't have a real in-game tooltip to fall back on.

## ModernSpellBook integration

If **[TeronModernSpellBook](../TeronModernSpellBook)** is installed and loaded, this addon
stops touching the default Blizzard spellbook entirely. Instead, it registers its own native
**"What's Training"** tab directly inside ModernSpellBook's frame — same fonts, icons,
badges, tooltips, and category headers as every other tab, rather than a separate window
glued onto the corner of the old frame.

Without ModernSpellBook installed (or if you toggle it off with `/msb`), WhatsTraining falls
back to its original behavior: a tab bolted onto the bottom-right corner of the default
Blizzard spellbook, exactly as it's always worked.

You don't need to configure anything for this — it's detected automatically at login.

## Right-click menu

Right-click any spell row (in either UI) for:

- **Ignore rank** — hide just that rank from the list from now on.
- **Ignore all ranks** — hide every rank of that spell.
- **Mark as learned** — Hunter pet abilities and Warlock grimoires only, for cases the
  addon's automatic detection can't catch on its own.

## Other conveniences

- **Hunter Beast Training scanning** — automatically detects newly learned pet abilities
  and nudges you to open Beast Training once so it can cache them.
- **Warlock grimoire tracking** — watches the merchant window for tome purchases and marks
  learned grimoires automatically.
- **Locale-independent spell matching** — matching known spells by icon + rank number
  instead of localized name, so this works correctly on non-English clients.

## Installation

1. Clone or download this repository into your `Interface\AddOns\` folder.
2. Make sure the folder is named exactly `TeronWhatsTraining` — WoW requires the folder
   name to match the `.toc` filename inside it, or the client won't detect the addon.
3. Restart the game client (or `/reload`).
4. *(Optional)* Install **TeronModernSpellBook** as well for the native tab experience
   described above — no load order or configuration needed, just have both installed.

## Compatibility

- **Pure Vanilla 1.12.1** servers (TwinStar Kronos V and similar) — primary target.
- **Not** compatible with Turtle WoW's custom class spells — use
  **TeronWhatsTraining-TW** there instead.
- Optional soft dependency on **TeronModernSpellBook** for the native tab UI; works
  completely standalone without it.

## How it's built (for the curious)

The addon is split cleanly into a data layer and a UI layer:

- **Data layer** — `PlayerData.lua` (the categorization engine), `Constants.lua` (category
  definitions/order), `SpellsByLevel.lua` + `Classes\*.lua` (the per-class trainable spell
  database), `SpellDescriptions.lua` (generated tooltip text), `Utils.lua`.
- **UI layer** — `WhatsTrainingUI.lua` (the original Blizzard-spellbook overlay renderer)
  and `WhatsTrainingUI_MSB.lua` (the ModernSpellBook-native tab renderer, active only when
  MSB is detected). Both implement the same small interface
  (`Initialize` / `SetItems` / `ClearItems` / `Update`), so the controller
  (`WhatsTraining.lua`) doesn't need to know or care which one is active.
- **Controller** — `WhatsTraining.lua` wires events (`PLAYER_ENTERING_WORLD`,
  `PLAYER_LEVEL_UP`, `SPELLS_CHANGED`, plus class-specific hunter/warlock hooks) to the
  data layer and asks the active UI layer to redraw.

This separation is exactly what makes the ModernSpellBook integration possible without
touching a single line of the spell database or categorization logic.

## Credits

- Original **WhatsTraining** addon (Classic Era 1.14.2+) by **Sveng**.
- 1.12.1 Vanilla backport by **spawnedc & Antigravity**.
- ModernSpellBook integration and ongoing maintenance of this fork by
  **Kaloyan "Terongorus" Kolev**.

---

# Тerongorus' What's Training? (кратко, на русском)

Аддон для **World of Warcraft Vanilla 1.12.1**, показывающий все доступные для изучения
заклинания вашего класса: что можно выучить прямо сейчас, что появится в ближайших
уровнях, чего не хватает (уровня, требования, таланта), и что вы решили скрыть вручную.
Это личный форк Kaloyan "Terongorus" Kolev, нацеленный на чистые Vanilla 1.12.1 сервера
(например, TwinStar Kronos V).

> Версия для **Turtle WoW** — отдельный форк **TeronWhatsTraining-TW**, так как списки
> заклинаний классов на Turtle WoW отличаются от чистой Vanilla.

Если установлен и загружен **TeronModernSpellBook**, аддон создаёт нативную вкладку
"What's Training" прямо внутри его книги заклинаний вместо старого оверлея поверх
стандартного окна Blizzard. Без ModernSpellBook — работает как раньше, отдельной вкладкой
поверх стандартной книги заклинаний.

**Установка:** поместите папку в `Interface\AddOns\` под именем ровно `TeronWhatsTraining`
и перезапустите клиент.
