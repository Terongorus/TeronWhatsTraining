setfenv(1, WhatsTraining)
WhatsTrainingUI = {}

local HIGHLIGHT_TEXTURE_FILEID = "Interface\\AddOns\\WhatsTraining\\textures\\highlight"
local LEFT_BG_TEXTURE_FILEID = "Interface\\AddOns\\WhatsTraining\\textures\\left"
local RIGHT_BG_TEXTURE_FILEID = "Interface\\AddOns\\WhatsTraining\\textures\\right"
local TAB_TEXTURE_FILEID = "Interface\\Icons\\INV_Misc_QuestionMark"
local TAB_BACKDROP_FILEID = "Interface\\Spellbook\\SpellBook-SkillLineTab"
local TAB_HIGHLIGHT_TEXTURE_FILEID = "Interface\\Buttons\\ButtonHilight-Square"
local TAB_CHECKED_TEXTURE_FILEID = "Interface\\Buttons\\CheckButtonHilight"

local ROW_HEIGHT = 14
local MAX_VISIBLE_ROWS = 22

local menuFrame = CreateFrame("Frame", "WTRightClickFrame", UIParent, "UIDropDownMenuTemplate")

function WhatsTrainingUI:Initialize()
  self.rows = {}
  self:InitDisplay()
  self.tooltip = CreateFrame("GameTooltip", "WhatsTrainingTooltip", UIParent,
    "GameTooltipTemplate")
  self:SetupHooks()
end

function WhatsTrainingUI:Update()
  if not self.scrollBar then return end
  local totalItems = Utils.tableLength(self.rows) + 1
  FauxScrollFrame_Update(self.scrollBar, totalItems, MAX_VISIBLE_ROWS, ROW_HEIGHT);

  local offset = FauxScrollFrame_GetOffset(self.scrollBar)
  local rowLevel = self.frame:GetFrameLevel() + 2
  for i, row in ipairs(self.rows) do
    if i >= offset and i < offset + MAX_VISIBLE_ROWS then
      row:ClearAllPoints()
      local previousRow = self.rows[i - 1]
      if previousRow and previousRow:IsVisible() then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -2)
      else
        row:SetPoint("TOPLEFT", self.frame, 26, -78)
      end
      row:SetPoint("RIGHT", self.scrollBar)
      row:SetFrameLevel(rowLevel)
      row:Show()
    else
      row:Hide()
    end
  end
end

function WhatsTrainingUI:ClearItems()
  if not self.rows then return end
  for i, row in ipairs(self.rows) do
    row:Hide()
    row:SetParent(nil)
  end
  self.rows = {}
end

function WhatsTrainingUI:showTabTooltip()
  GameTooltip:SetOwner(self.tab, "ANCHOR_RIGHT");
  GameTooltip:SetText("What can I train?");
end

function WhatsTrainingUI:hideTabTooltip()
  GameTooltip:Hide();
end

function WhatsTrainingUI:HideFrame()
  if (self.tab) then
    self.tab:SetChecked(false)
  end
  if (self.frame) then
    self.frame:Hide()
  end
  -- Restore spellbook page content
  for i = 1, SPELLS_PER_PAGE do
    local btn = getglobal("SpellButton" .. i)
    if btn then btn:Show() end
  end
  if SpellBookPrevPageButton then SpellBookPrevPageButton:Show() end
  if SpellBookNextPageButton then SpellBookNextPageButton:Show() end
  if SpellBookPageText then SpellBookPageText:Show() end
end

function WhatsTrainingUI:ShowFrame()
  -- Uncheck all spell skill tabs
  local i = 1
  while getglobal("SpellBookSkillLineTab"..i) do
    getglobal("SpellBookSkillLineTab"..i):SetChecked(false)
    i = i + 1
  end
  
  -- Hide spellbook page content so it doesn't show through
  for i = 1, SPELLS_PER_PAGE do
    local btn = getglobal("SpellButton" .. i)
    if btn then btn:Hide() end
  end
  if SpellBookPrevPageButton then SpellBookPrevPageButton:Hide() end
  if SpellBookNextPageButton then SpellBookNextPageButton:Hide() end
  if SpellBookPageText then SpellBookPageText:Hide() end

  self.tab:SetChecked(true)
  self.frame:Show()
end

function WhatsTrainingUI:handleTabClick()
  -- Hook spell tabs now if not already done (spellbook is definitely open)
  self:HookSpellTabs()
  -- Always show when clicked (like a tab, not a toggle)
  self:ShowFrame()
end

-- Sets up the tab
---@return CheckButton
function WhatsTrainingUI:SetupTab()
  local tab = CreateFrame("CheckButton", "WhatsTrainingTab", SpellBookFrame)
  tab:SetFrameStrata("HIGH")
  tab:SetPoint('BOTTOMRIGHT', SpellBookFrame, -7, 86)
  tab:SetWidth(24)
  tab:SetHeight(24)

  tab:SetHighlightTexture(TAB_HIGHLIGHT_TEXTURE_FILEID)
  tab:SetCheckedTexture(TAB_CHECKED_TEXTURE_FILEID)

  local TAB_BACKDROP_TEXTURE = tab:CreateTexture(nil, "BACKGROUND")
  TAB_BACKDROP_TEXTURE:SetTexture(TAB_BACKDROP_FILEID)
  TAB_BACKDROP_TEXTURE:SetWidth(54)
  TAB_BACKDROP_TEXTURE:SetHeight(54)
  TAB_BACKDROP_TEXTURE:SetPoint("TOPLEFT", -4, 11)
  tab:SetBackdrop(TAB_BACKDROP_TEXTURE)

  tab:SetNormalTexture(TAB_TEXTURE_FILEID)

  tab:SetScript("OnClick", function() WhatsTrainingUI:handleTabClick() end)
  tab:SetScript("OnEnter", function() WhatsTrainingUI:showTabTooltip() end)
  tab:SetScript("OnLeave", function() WhatsTrainingUI:hideTabTooltip() end)

  return tab
end

function WhatsTrainingUI:InitDisplay()
  self.frame = CreateFrame("Frame", "WhatsTrainingFrame", SpellBookFrame)
  self.frame:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 0, 0)
  self.frame:SetPoint("BOTTOMRIGHT", SpellBookFrame, "BOTTOMRIGHT", 0, 0)
  self.frame:SetFrameStrata("MEDIUM")
  self.frame:SetFrameLevel(SpellBookFrame:GetFrameLevel() + 5)
  -- prevents mouse hover leaking but allows close button clicks
  self.frame:EnableMouse(false)
  self.frame:EnableMouseWheel(true)

  self.tab = WhatsTrainingUI:SetupTab()

  local left = self.frame:CreateTexture(nil, "ARTWORK")
  left:SetTexture(LEFT_BG_TEXTURE_FILEID)
  left:SetWidth(256)
  left:SetHeight(512)
  left:SetPoint("TOPLEFT", self.frame)

  local right = self.frame:CreateTexture(nil, "ARTWORK")
  right:SetTexture(RIGHT_BG_TEXTURE_FILEID)
  right:SetWidth(128)
  right:SetHeight(512)
  right:SetPoint("TOPRIGHT", self.frame)

  self.scrollBar = CreateFrame("ScrollFrame", "FrameScrollBar", self.frame, "FauxScrollFrameTemplate")
  self.scrollBar:SetPoint("TOPLEFT", 0, -75)
  self.scrollBar:SetPoint("BOTTOMRIGHT", -65, 81)

  self.scrollBar:SetScript("OnShow", function() WhatsTrainingUI:Update() end)

  self.scrollBar:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, function() WhatsTrainingUI:Update() end)
  end)
  
  -- Enable mouse on scrollbar content area - positioned to not block spell tabs on left
  -- Frame level is set lower than rows so that Hide()/Show() during scrolling
  -- doesn't let this frame steal mouse events from the row buttons
  local scrollContent = CreateFrame("Frame", nil, self.frame)
  scrollContent:SetPoint("TOPLEFT", 60, -70)
  scrollContent:SetPoint("BOTTOMRIGHT", -60, 80)
  scrollContent:EnableMouse(true)
  scrollContent:SetFrameLevel(self.frame:GetFrameLevel() + 1)

  self.frame:Hide()
end

function WhatsTrainingUI:HookSpellTabs()
  -- Hook individual spell tab buttons directly after they exist
  for i = 1, 8 do
    local tab = getglobal("SpellBookSkillLineTab"..i)
    if tab and not tab.whatsTrainingHooked then
      -- Manual hooking for 1.12.1 compatibility
      local originalOnClick = tab:GetScript("OnClick")
      tab:SetScript("OnClick", function()
        -- Hide WhatsTraining when a spell tab is clicked
        if WhatsTrainingUI.frame and WhatsTrainingUI.frame:IsVisible() then
          WhatsTrainingUI:HideFrame()
        end
        -- Call original handler
        if originalOnClick then
          originalOnClick()
        end
      end)
      tab.whatsTrainingHooked = true
    end
  end
end

function WhatsTrainingUI:SetupHooks()
  -- Hook into SpellBookFrame's hide event (manual hooking for 1.12.1)
  local originalOnHide = SpellBookFrame:GetScript("OnHide")
  SpellBookFrame:SetScript("OnHide", function()
    WhatsTrainingUI:HideFrame()
    if originalOnHide then
      originalOnHide()
    end
  end)
  
  -- Hook spell tabs after they're created when spellbook opens
  local originalOnShow = SpellBookFrame:GetScript("OnShow")
  SpellBookFrame:SetScript("OnShow", function()
    WhatsTrainingUI:HookSpellTabs()
    if originalOnShow then
      originalOnShow()
    end
  end)
  
  -- If spellbook is already visible, hook tabs immediately
  if SpellBookFrame:IsVisible() then
    WhatsTrainingUI:HookSpellTabs()
  end
end

---Sets the given spells as rows
---@param spells table<SpellCategories, Spell[]>
function WhatsTrainingUI:SetItems(spells)
  local i = 1
  local spellSchool = nil

  -- Render top level ignore feature notice if active
  if _G.WT_ShowIgnoreNotice then
    local ignoreNoticeName = "$parentIgnoreNoticeRow"
    local ignoreNoticeRow = CreateFrame("Button", ignoreNoticeName, self.frame)
    ignoreNoticeRow:SetHeight(ROW_HEIGHT)
    ignoreNoticeRow:EnableMouse(true)
    ignoreNoticeRow:RegisterForClicks("LeftButtonUp")
    ignoreNoticeRow:SetScript("OnClick", function()
      _G.WT_ShowIgnoreNotice = false
      WhatsTraining:Refresh()
    end)

    local noticeLabel = ignoreNoticeRow:CreateFontString(ignoreNoticeName .. "-label", "OVERLAY", "GameFontNormal")
    noticeLabel:SetAllPoints()
    noticeLabel:SetJustifyH("Center")
    noticeLabel:SetText("|cff82c5ffRight-click spells to ignore them (Click to dismiss)|r")

    ignoreNoticeRow:SetPoint("RIGHT", self.scrollBar)
    if (self.rows[i - 1] == nil) then
      ignoreNoticeRow:SetPoint("TOPLEFT", self.frame, 26, -78)
    else
      ignoreNoticeRow:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)
    end

    rawset(self.rows, i, ignoreNoticeRow)
    i = i + 1
  end

  for categoryIndex, spellCategory in ipairs(SpellCategoryHeaders) do
    local categorySpells = spells[spellCategory.key]
    local categoryHasSpells = categorySpells ~= nil and Utils.tableLength(categorySpells) > 0

    if categoryHasSpells then
      local headerName = "$headerRow-" .. spellCategory.name
      local header = CreateFrame("Button", headerName, self.frame)
      header:SetHeight(ROW_HEIGHT)

      local headerLabel = header:CreateFontString(headerName .. "-header", "OVERLAY", "GameFontWhite")
      headerLabel:SetAllPoints()
      headerLabel:SetJustifyV("Middle")
      headerLabel:SetJustifyH("Center")
      headerLabel:SetText(spellCategory.color .. spellCategory.name .. FONT_COLOR_CODE_CLOSE)

      header:SetPoint("RIGHT", self.scrollBar)

      if (self.rows[i - 1] == nil) then
        header:SetPoint("TOPLEFT", self.frame, 26, -78)
      else
        header:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)
      end

      -- add header to the list
      rawset(self.rows, i, header)
      i = i + 1

      -- Render Hunter Beast Training notice if applicable
      if spellCategory.key == SpellCategories.PET and PlayerData.class == "HUNTER" and _G.WT_NeedsToOpenBeastTraining then
        local warningRowName = "$parentPetWarningRow"
        local warningRow = CreateFrame("Button", warningRowName, self.frame)
        warningRow:SetHeight(ROW_HEIGHT)
        warningRow:EnableMouse(true)
        warningRow:RegisterForClicks("LeftButtonUp")
        warningRow:SetScript("OnClick", function()
          CastSpellByName("Beast Training")
        end)
        warningRow:SetScript("OnEnter", function()
          self.tooltip:SetOwner(warningRow, "ANCHOR_RIGHT")
          self.tooltip:SetText("WhatsTraining needs you to open Beast Training once to scan and cache your pet abilities.", 1, 1, 1, 1, true)
          self.tooltip:Show()
        end)
        warningRow:SetScript("OnLeave", function() self.tooltip:Hide() end)
        
        local warningLabel = warningRow:CreateFontString(warningRowName .. "-label", "OVERLAY", "GameFontNormal")
        warningLabel:SetAllPoints()
        warningLabel:SetJustifyH("Center")
        warningLabel:SetText("|cffff8040Open Beast Training to update|r")
        
        warningRow:SetPoint("RIGHT", self.scrollBar)
        warningRow:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)
        
        rawset(self.rows, i, warningRow)
        i = i + 1
      end

      -- Render Warlock Grimoire notice if applicable
      if spellCategory.key == SpellCategories.PET and PlayerData.class == "WARLOCK" and _G.WT_ShowLearnedNotice then
        local warningRowName = "$parentPetWarningRow"
        local warningRow = CreateFrame("Button", warningRowName, self.frame)
        warningRow:SetHeight(ROW_HEIGHT)
        warningRow:EnableMouse(true)
        warningRow:RegisterForClicks("LeftButtonUp")
        warningRow:SetScript("OnClick", function()
          _G.WT_ShowLearnedNotice = false
          WhatsTraining:Refresh()
        end)
        
        local warningLabel = warningRow:CreateFontString(warningRowName .. "-label", "OVERLAY", "GameFontNormal")
        warningLabel:SetAllPoints()
        warningLabel:SetJustifyH("Center")
        warningLabel:SetText("|cff82c5ffRight-click grimoires to mark as learned (Click to dismiss)|r")
        
        warningRow:SetPoint("RIGHT", self.scrollBar)
        warningRow:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)
        
        rawset(self.rows, i, warningRow)
        i = i + 1
      end

      for spellIndex, categorySpell in ipairs(categorySpells) do
        if spellCategory.showSpellSchoolHeader then
          if spellSchool ~= categorySpell.school then
            local schoolName = "$schoolRow-" .. spellCategory.name
            local school = CreateFrame("Button", schoolName, self.frame)
            school:SetHeight(ROW_HEIGHT)

            local schoolLabel = school:CreateFontString(schoolName .. "-school", "OVERLAY", "GameFontWhite")
            schoolLabel:SetAllPoints()
            schoolLabel:SetJustifyH("Left")
            schoolLabel:SetText(categorySpell.school)

            school:SetPoint("RIGHT", self.scrollBar)
            school:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)

            -- add school to the list
            rawset(self.rows, i, school)
            spellSchool = categorySpell.school
            i = i + 1
          end
        end

        local rowFrameName = "$parentRow-" .. categoryIndex .. "-" .. spellIndex
        local row = CreateFrame("Button", rowFrameName, self.frame)
        row.spell = categorySpell
        row:SetHeight(ROW_HEIGHT)
        row:EnableMouse(true)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function()
          if arg1 == "RightButton" then
            WhatsTrainingUI:OnRowRightClick(row, row.spell)
          end
        end)
        row:SetScript("OnEnter", function()
          self.tooltip:SetOwner(row, "ANCHOR_RIGHT")
          -- Try to find the spell in spellbook for proper tooltip
          local spellIcon = string.lower(row.spell.icon or "")
          local _, _, spellRankNumStr = string.find(row.spell.subText or "", "(%d+)")
          local spellRankNum = tonumber(spellRankNumStr) or 0
          local found = false
          
          local i = 1
          while true do
            local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
            if not name then break end
            
            local icon = GetSpellTexture(i, BOOKTYPE_SPELL)
            if icon then
              icon = string.lower(icon)
            end
            local _, _, rankNumStr = string.find(rank or "", "(%d+)")
            local rankNum = tonumber(rankNumStr) or 0
            
            if icon == spellIcon and rankNum == spellRankNum then
              self.tooltip:SetSpell(i, BOOKTYPE_SPELL)
              found = true
              break
            end
            i = i + 1
          end
          
          if not found then
            -- Fallback to custom tooltip using generated SpellDescriptions
            local desc = SpellDescriptions and SpellDescriptions[row.spell.id]
            self.tooltip:AddLine(row.spell.name, 1, 1, 1)
            if row.spell.subText and row.spell.subText ~= "" then
              self.tooltip:AddLine(row.spell.subText, 0.5, 0.5, 0.5)
            end
            
            if desc then
              -- Mana / Range
              if desc.manaCost or desc.range then
                self.tooltip:AddDoubleLine(desc.manaCost or "", desc.range or "", 1, 1, 1, 1, 1, 1)
              end
              -- Cast / Cooldown
              if desc.castTime or desc.cooldown then
                self.tooltip:AddDoubleLine(desc.castTime or "", desc.cooldown or "", 1, 1, 1, 1, 1, 1)
              end
              -- Description
              if desc.description then
                self.tooltip:AddLine(desc.description, 1, 0.82, 0, true)
              end
            else
              -- Basic fallback if description is missing
              self.tooltip:AddLine(" ")
              self.tooltip:AddLine(row.spell.school, 1, 0.82, 0)
              self.tooltip:AddLine("Level " .. row.spell.level .. " spell", 0.5, 0.5, 0.5)
            end
          end
          
          if row.spell.cost and row.spell.cost > 0 then
            local costText = Utils.FormatMoney(row.spell.cost)
            if GetMoney() < row.spell.cost then
              self.tooltip:AddLine("Cost: " .. "|cffff3333" .. costText .. "|r")
            else
              self.tooltip:AddLine("Cost: " .. costText)
            end
          end
          
          self.tooltip:Show()
        end)
        row:SetScript("OnLeave", function() self.tooltip:Hide() end)

        local highlight = row:CreateTexture("$parentHighlight", "HIGHLIGHT")
        highlight:SetAllPoints()
        highlight:SetTexture(HIGHLIGHT_TEXTURE_FILEID)

        local spell = CreateFrame("Frame", "$parentSpell", row)
        spell:SetPoint("LEFT", row, "Left")
        spell:SetPoint("TOP", row, "TOP")
        spell:SetPoint("BOTTOM", row, "BOTTOM")

        local spellIcon = spell:CreateTexture(nil, "OVERLAY")
        if spellCategory.showSpellSchoolHeader then
          spellIcon:SetPoint("TOPLEFT", spell, "TOPLEFT", ROW_HEIGHT, 0)
        else
          spellIcon:SetPoint("TOPLEFT", spell, "TOPLEFT")
        end
        spellIcon:SetTexture(categorySpell.icon)

        local iconWidth = ROW_HEIGHT
        spellIcon:SetWidth(iconWidth)
        spellIcon:SetHeight(iconWidth)

        local spellLabel = spell:CreateFontString("$parentLabel", "OVERLAY", "GameFontNormal")
        spellLabel:SetPoint("TOPLEFT", spellIcon, "TOPLEFT", iconWidth + 4, 0)
        spellLabel:SetPoint("BOTTOM", spell)
        spellLabel:SetJustifyV("Middle")
        spellLabel:SetJustifyH("Left")
        spellLabel:SetText(categorySpell.name)

        local spellSublabel = spell:CreateFontString("$parentSubLabel", "OVERLAY", "InvoiceTextFontSmall")
        spellSublabel:SetJustifyH("Left")
        spellSublabel:SetPoint("TOPLEFT", spellLabel, "TOPRIGHT", 2, 0)
        spellSublabel:SetPoint("BOTTOM", spellLabel)
        if categorySpell.subText ~= "" then
          spellSublabel:SetText("(" .. categorySpell.subText .. ")")
          spellSublabel:SetTextColor(0.82, 0.7, 0.54, 1)
        end

        local spellLevelLabel = spell:CreateFontString("$parentLevelLabel", "OVERLAY", "GameFontWhite")
        spellLevelLabel:SetPoint("TOPRIGHT", spell, -4, 0)
        spellLevelLabel:SetPoint("BOTTOM", spell)
        spellLevelLabel:SetJustifyH("Right")
        spellLevelLabel:SetJustifyV("Middle")
        spellLevelLabel:SetText("Level " .. categorySpell.level)
        local levelColour = GetDifficultyColor(categorySpell.level)
        spellLevelLabel:SetTextColor(levelColour.r, levelColour.g, levelColour.b)
        if spellCategory.hideLevel then
          spellLevelLabel:Hide()
        end

        spellSublabel:SetPoint("RIGHT", spellLevelLabel, "Left")
        spellSublabel:SetJustifyV("Middle")

        row:SetPoint("RIGHT", self.scrollBar)
        row:SetPoint("TOPLEFT", self.rows[i - 1], "BOTTOMLEFT", 0, -2)

        rawset(self.rows, i, row)

        i = i + 1
      end
    end
  end
end

function WhatsTrainingUI:ShowContextMenu(anchorFrame, menuList)
  local initialize = function()
    for _, info in ipairs(menuList) do
      UIDropDownMenu_AddButton(info)
    end
  end
  UIDropDownMenu_Initialize(menuFrame, initialize, "MENU")
  ToggleDropDownMenu(1, nil, menuFrame, anchorFrame, 10, 10)
end

function WhatsTrainingUI:OnRowRightClick(row, spell)
  local menu = {}

  tinsert(menu, {
    text = spell.name .. (spell.subText and spell.subText ~= "" and " (" .. spell.subText .. ")" or ""),
    isTitle = true
  })

  local isIgnored = _G.WT_IgnoredSpells[spell.id] == true
  tinsert(menu, {
    text = "Ignore rank",
    checked = isIgnored,
    func = function()
      if _G.WT_IgnoredSpells[spell.id] then
        _G.WT_IgnoredSpells[spell.id] = nil
      else
        _G.WT_IgnoredSpells[spell.id] = true
      end
      WhatsTraining:Refresh()
    end,
    isNotRadio = true
  })

  local allRanks = PlayerData:GetAllRanksOfSpell(spell.name)
  if allRanks and table.getn(allRanks) > 1 then
    local allIgnored = true
    for _, id in ipairs(allRanks) do
      if not _G.WT_IgnoredSpells[id] then
        allIgnored = false
        break
      end
    end
    tinsert(menu, {
      text = "Ignore all ranks",
      checked = allIgnored,
      func = function()
        for _, id in ipairs(allRanks) do
          if allIgnored then
            _G.WT_IgnoredSpells[id] = nil
          else
            _G.WT_IgnoredSpells[id] = true
          end
        end
        WhatsTraining:Refresh()
      end,
      isNotRadio = true
    })
  end

  if spell.isTome or spell.school == "Pet Training" then
    local isLearned = PlayerData:IsPetSpellKnown(spell)
    tinsert(menu, {
      text = "Mark as learned",
      checked = isLearned,
      func = function()
        if spell.isTome then
          if isLearned then
            _G.WT_LearnedPetAbilities[spell.id] = nil
          else
            _G.WT_LearnedPetAbilities[spell.id] = true
          end
        elseif spell.school == "Pet Training" then
          if not _G.WT_LearnedPetAbilities[spell.name] then
            _G.WT_LearnedPetAbilities[spell.name] = {}
          end
          if isLearned then
            _G.WT_LearnedPetAbilities[spell.name][spell.subText] = nil
          else
            _G.WT_LearnedPetAbilities[spell.name][spell.subText] = true
          end
        end
        WhatsTraining:Refresh()
      end,
      isNotRadio = true
    })
  end

  self:ShowContextMenu(row, menu)
end