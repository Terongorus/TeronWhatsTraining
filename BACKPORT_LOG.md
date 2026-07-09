# WhatsTraining 1.12.1 Backport Work Log

This document outlines the detailed technical changes and architecture adjustments made to backport the **Classic Era (1.14.2)** version of **WhatsTraining** to **WoW Vanilla (1.12.1)**. This serves as a guide for future agents or developers working on this codebase.

---

## 1. Lua 5.0 Syntax & API Compatibility (WoW 1.12.1 Limitations)

The original 1.14.2 addon utilizes Lua 5.1 and modern WoW API features. The 1.12.1 client uses Lua 5.0, requiring the following adjustments:

- **Modulo `%` Operator Replacement:**
  - *Problem:* Lua 5.0 does not support the modulo `%` operator. 
  - *Fix:* Rewrote money formatting in `Utils.FormatMoney` (in [Utils.lua](Utils.lua)) to calculate silver and copper using subtraction-based division math:
    ```lua
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount - gold * 10000) / 100)
    local copper = amount - gold * 10000 - silver * 100
    ```
- **`string.match` and `string.gmatch` Replacement:**
  - *Problem:* `string.match` and `string.gmatch` were introduced in Lua 5.1 and are `nil` in Lua 5.0, causing client-wide interface crashes.
  - *Fix:* Replaced all occurrences with `string.find` utilizing capture groups (which return captured patterns as the 3rd, 4th, etc. values in Lua 5.0):
    ```lua
    -- Extract digits (ranks)
    local _, _, rankNumStr = string.find(rank or "", "(%d+)")
    local rankNum = tonumber(rankNumStr) or 0
    ```
    And for pattern matching checking:
    ```lua
    if string.find(text, requiresLevelPattern) then ...
    ```
- **Length `#` Operator Avoidance:**
  - Used standard `table.getn(tbl)` or custom `Utils.tableLength(tbl)` instead of `#tbl`.
- **No `hooksecurefunc`:**
  - Replaced secure hook mechanisms with standard function overrides (e.g., overriding `MerchantFrame_Update` and calling the original ref inside).

---

## 2. Localized Client Support (e.g., Russian ruRU)

- *Problem:* `GetSpellName(i, BOOKTYPE_SPELL)` returns spell names in the client's language (e.g., `"Лунное пламя"` for Moonfire), while the trainer database compiled from WoWhead contains English spell names (`"Moonfire"`). Direct name-based lookups failed, causing all learned spells to remain in the "Available now" category.
- *Fix:* Implemented a language-independent matching fallback:
  1. During the spellbook scan, `GetKnownSpells` builds a lookup table of learned spells (`self.spellbookSpells`) storing their name, rank, icon path (lowercased), and rank number (extracted via regex digits).
  2. Spells are compared using `IsSpellKnown`:
     - It first tries the exact English name/rank lookup (for English clients).
     - As a fallback, it compares the spell's lowercased icon texture (`string.lower(spell.icon)`) and rank number.
     - To prevent issues where different spells share the same icon (e.g., `Frost Armor` and `Ice Armor`), it checks if `spell.level <= player.level`.
  3. This matching logic is also used in `OnEnter` tooltips (in [WhatsTrainingUI.lua](WhatsTrainingUI.lua)) to display native, localized descriptions for learned spells, and in `IsPetSpellKnown` for Hunter pet abilities.

---

## 3. Prerequisite Quest & Starting Spells Resolution

- *Problem:* Spells like `Enrage` require quest-reward spells (like `Bear Form` quest spell ID `5487`) or starting spells (like `Wrath Rank 1` ID `5176`) to be trained. Since these spells aren't sold by trainers, they were omitted from the compiled database. Consequently, the addon couldn't verify them, causing `Enrage` to show under "Available but missing requirements".
- *Fix:* Defined an `ExtraSpells` lookup dictionary in [PlayerData.lua](PlayerData.lua) that maps these external/starting spell IDs to their English names and icons. Updated `IsSpellRequirementsMet` to fall back to `ExtraSpells` when checking requirements.

---

## 4. Custom Context Menu Engine (Dropdowns)

- *Problem:* Modern versions used `EasyMenu` with `"cursor"` anchoring. `"cursor"` is unsupported in 1.12.1 and threw errors.
- *Fix:* Replaced it with a native dropdown menu setup utilizing standard FrameXML APIs:
  ```lua
  function WhatsTrainingUI:ShowContextMenu(anchorFrame, menuList)
    local initialize = function()
      for _, info in ipairs(menuList) do
        UIDropDownMenu_AddButton(info)
      end
    end
    UIDropDownMenu_Initialize(menuFrame, initialize, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchorFrame, 10, 10)
  end
  ```
  The context menu now anchors directly next to the clicked row, preventing cursor anchoring crashes.

---

## 5. Database Compilation (`build_db.py`)

The databases inside the `Classes/` directory are compiled using a python parser (`build_db.py`). Key fixes applied to the compiler:
- Bypassed the outer level braces in `lvl_block` by starting the inner search at `spell_pos = 1` instead of `0`. This resolved a bug where only the first spell of each level block was parsed.
- Tagged Warlock tomes correctly with `isTome = true`.
- Escaped all backslashes in icon paths (`Interface\\Icons\\...`) to prevent Lua compilation failures.
