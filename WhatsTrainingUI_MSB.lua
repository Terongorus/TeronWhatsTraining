setfenv(1, WhatsTraining)

-- Only active when ModernSpellBook (folder/TOC: TeronModernSpellBook) is installed and
-- loaded. MSB constructs all of the globals checked below at its own file scope, and it
-- loads before this file ("...M..." < "...W..." alphabetically), so this check is safe
-- to run immediately at file-load time.
local active = IsAddOnLoaded and IsAddOnLoaded("TeronModernSpellBook")
    and _G.SpellBook and _G.ModernSpellBookFrame
    and _G.SpellDataService and _G.CSpellItem and _G.CCategoryItem
if not active then return end

-- Keep the old Blizzard-overlay renderer reachable (used only to delegate the
-- right-click ignore/learn menu, which is self-contained and UI-independent).
local BlizzardSpellbookUI = WhatsTrainingUI

local MSBRenderer = {
  frame = nil,
  tab = nil,
  source = nil,
  adapted = nil,
  onShowHooked = false,
  beastNoticeShown = false,
}

-- ===================== helpers =====================

--- Finds the real spellbook slot for a known WT spell, matched by icon + rank number
--- (locale-independent, same approach as the old Blizzard-overlay UI).
---@param spell Spell
---@return integer? slot, string? bookName, string? bookRank
local function findBookSlot(spell)
  local spellIcon = string.lower(spell.icon or "")
  local spellRankNum = Utils.GetRankNumber(spell.subText)

  local i = 1
  while true do
    local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then break end

    local icon = GetSpellTexture(i, BOOKTYPE_SPELL)
    if icon then icon = string.lower(icon) end
    local rankNum = Utils.GetRankNumber(rank)

    if icon == spellIcon and rankNum == spellRankNum then
      return i, name, rank
    end
    i = i + 1
  end

  return nil
end

--- Builds the tooltip description text (mana/range, cast/cooldown, description, cost)
--- from the generated SpellDescriptions table plus the WT spell's copper cost.
---@param spell Spell
---@return string
local function buildDescription(spell)
  local lines = {}
  local desc = SpellDescriptions and SpellDescriptions[spell.id]

  if desc then
    if desc.manaCost or desc.range then
      tinsert(lines, (desc.manaCost or "") .. ((desc.manaCost and desc.range) and "   " or "") .. (desc.range or ""))
    end
    if desc.castTime or desc.cooldown then
      tinsert(lines, (desc.castTime or "") .. ((desc.castTime and desc.cooldown) and "   " or "") .. (desc.cooldown or ""))
    end
    if desc.description then
      tinsert(lines, desc.description)
    end
  end

  if spell.cost and spell.cost > 0 then
    local costText = Utils.FormatMoney(spell.cost)
    if GetMoney() < spell.cost then
      tinsert(lines, "Cost: |cffff3333" .. costText .. "|r")
    else
      tinsert(lines, "Cost: " .. costText)
    end
  end

  return table.concat(lines, "\n")
end

--- MSB sorts category names alphabetically; a numeric prefix keeps WT's semantic
--- category order, and is stripped for display by the CCategoryItem.Set wrap below.
---@param index integer
---@param header SpellCategoryHeader
---@return string
local function categoryDisplayName(index, header)
  return index .. ". " .. header.name
end

-- ===================== data adapter =====================

--- Maps PlayerData.spellsByCategory (via SpellCategoryHeaders for order) into the
--- { [categoryDisplayName] = spellInfo[] } shape ModernSpellBook's render pipeline expects.
function MSBRenderer:BuildAdapted()
  local result = {}
  local source = self.source or {}

  for index, header in ipairs(SpellCategoryHeaders) do
    local categorySpells = source[header.key]
    if categorySpells and Utils.tableLength(categorySpells) > 0 then
      local displayName = categoryDisplayName(index, header)
      local list = {}

      for _, spell in ipairs(categorySpells) do
        local spellInfo = {
          spellName = spell.name,
          spellRank = spell.subText or "",
          spellIcon = spell.icon,
          category = displayName,
          levelReq = spell.level,
          isUnlearned = true,
          isTalent = (header.key == SpellCategories.MISSING_TALENT),
          isPassive = false,
          isPetSpell = false,
          spellID = nil,
          bookType = nil,
          castName = nil,
          description = buildDescription(spell),
          wtSpell = spell,
        }

        if header.key == SpellCategories.KNOWN then
          local slot, bookName, bookRank = findBookSlot(spell)
          if slot then
            spellInfo.isUnlearned = false
            spellInfo.spellID = slot
            spellInfo.bookType = BOOKTYPE_SPELL
            spellInfo.castName = (bookRank and bookRank ~= "") and (bookName .. "(" .. bookRank .. ")") or bookName
          end
        end

        tinsert(list, spellInfo)
      end

      result[displayName] = list
    end
  end

  return result
end

-- ===================== MSB-side hooks =====================
-- Installed once at file load. MSB is already fully loaded by this point (checked above),
-- so all of these globals exist.

-- Content routing: shadow the SpellDataService SINGLETON instance only (not the class),
-- so /msbdebug's phased replay of GetPlayerSpells internals is unaffected.
local origGetAvailableSpells = SpellDataService.GetAvailableSpells
SpellDataService.GetAvailableSpells = function(svc)
  local tab = MSBRenderer.tab
  if tab and ModernSpellBookFrame.selectedTab == tab.tab_number then
    if not MSBRenderer.adapted then
      MSBRenderer.adapted = MSBRenderer:BuildAdapted()
    end
    return MSBRenderer.adapted, false
  end

  -- Insurance: if MSB creates its "Other" tab on a LATER OnShow than ours, it gets an
  -- index one higher than MSB's hardcoded ==4 check expects.
  if ModernSpellBookFrame.selectedTab and ModernSpellBookFrame.selectedTab > 4 then
    for _, t in ipairs(ModernSpellBookFrame.Tabgroups) do
      if t.tab_number == ModernSpellBookFrame.selectedTab and t.name == "Other" then
        return svc:GetOtherTabSpells(), false
      end
    end
  end

  return origGetAvailableSpells(svc)
end

-- Category header display: strip our synthetic ordering prefix. Class-level wrap (shared
-- by every tab's headers) is safe because no native MSB category name starts with digits.
local origCategorySet = CCategoryItem.Set
CCategoryItem.Set = function(item, categoryName, currentPageRows, page, fallbackIcon)
  local displayName = string.gsub(categoryName, "^%d+%. ", "")
  return origCategorySet(item, displayName, currentPageRows, page, fallbackIcon)
end

-- Row interactivity: attach WT's right-click ignore/learn menu to our rows. Class-level
-- wrap is safe because CSpellItem:Set re-wires OnClick on every render (pooled reuse
-- self-heals when a widget later renders a different tab's spell).
local origSetClickHandler = CSpellItem.SetClickHandler
CSpellItem.SetClickHandler = function(item, spellInfo)
  if not spellInfo.wtSpell then
    return origSetClickHandler(item, spellInfo)
  end

  item.frame:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      BlizzardSpellbookUI:OnRowRightClick(item.frame, spellInfo.wtSpell)
      return
    end
    if IsShiftKeyDown() or spellInfo.isUnlearned or spellInfo.isPassive then return end
    if spellInfo.castName then
      CastSpellByName(spellInfo.castName)
    end
  end)
end

-- ===================== tab registration =====================

--- Creates the "What's Training" tab exactly once, after MSB's own OnShow has finished
--- creating tab1-3 and the conditional "Other" tab (verified: CreateCustomTabs and the
--- first DrawPage always run before this post-hook fires).
function MSBRenderer:EnsureTab()
  if self.tab then return end

  self.tab = SpellBook:NewTab("What's Training")
  SpellBook:PositionAllTabs()

  if ModernSpellBookFrame.selectedTab == self.tab.tab_number then
    -- ModernSpellBook_DB.lastTab pointed at our (not-yet-existing) index; the original
    -- OnShow already drew an empty page for that dangling index. Fix both.
    self.tab:SetSelected()
    SpellBook:DrawPage()
  end
end

-- ===================== controller surface =====================
-- Implements the same 5-point surface the old Blizzard-overlay renderer did, so
-- WhatsTraining.lua needs zero changes: Initialize/SetItems/ClearItems/Update + .frame.

function MSBRenderer:Initialize()
  self.frame = ModernSpellBookFrame

  if not self.onShowHooked then
    local originalOnShow = ModernSpellBookFrame:GetScript("OnShow")
    ModernSpellBookFrame:SetScript("OnShow", function()
      if originalOnShow then originalOnShow() end
      MSBRenderer:EnsureTab()
    end)
    self.onShowHooked = true
  end

  if _G.WT_ShowIgnoreNotice then
    Utils.log("|cff82c5ffWhatsTraining:|r Right-click spells on the What's Training tab to ignore them.")
    _G.WT_ShowIgnoreNotice = false
  end
end

function MSBRenderer:SetItems(spells)
  self.source = spells
  self.adapted = nil

  if _G.WT_NeedsToOpenBeastTraining then
    if not self.beastNoticeShown then
      Utils.log("|cffff8040WhatsTraining:|r Open Beast Training once to scan and cache your pet abilities.")
      self.beastNoticeShown = true
    end
  else
    self.beastNoticeShown = false
  end
end

function MSBRenderer:ClearItems()
  self.adapted = nil
end

function MSBRenderer:Update()
  if not self.tab then return end
  if not ModernSpellBookFrame:IsVisible() then return end
  if ModernSpellBookFrame.selectedTab ~= self.tab.tab_number then return end
  SpellBook:DrawPage()
end

-- ===================== activate =====================
-- From here on, the controller (WhatsTraining.lua) talks to MSBRenderer instead of the
-- old Blizzard-overlay UI. The old UI's Initialize/InitDisplay/SetupHooks never run, so
-- WhatsTrainingFrame, WhatsTrainingTab, and all SpellBookFrame hooks never come into being.
WhatsTrainingUI = MSBRenderer
