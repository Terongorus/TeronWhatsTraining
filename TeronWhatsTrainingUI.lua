setfenv(1, WhatsTraining)
WhatsTrainingUI = {}

local HIGHLIGHT_TEXTURE_FILEID = "Interface\\AddOns\\TeronWhatsTraining\\textures\\highlight"
local LEFT_BG_TEXTURE_FILEID = "Interface\\AddOns\\TeronWhatsTraining\\textures\\left"
local RIGHT_BG_TEXTURE_FILEID = "Interface\\AddOns\\TeronWhatsTraining\\textures\\right"
local TAB_TEXTURE_FILEID = "Interface\\Icons\\INV_Misc_QuestionMark"
local TAB_BACKDROP_FILEID = "Interface\\Spellbook\\SpellBook-SkillLineTab"
local TAB_HIGHLIGHT_TEXTURE_FILEID = "Interface\\Buttons\\ButtonHilight-Square"
local TAB_CHECKED_TEXTURE_FILEID = "Interface\\Buttons\\CheckButtonHilight"

local ROW_HEIGHT = 14
local MAX_VISIBLE_ROWS = 22

function WhatsTrainingUI:Initialize()
  self:InitDisplay()
  self.rows = {}
  self.tooltip = CreateFrame("GameTooltip", "WhatsTrainingTooltip", UIParent,
    "GameTooltipTemplate")
end

function WhatsTrainingUI:Update()
  local totalItems = Utils.tableLength(self.rows) + 1
  FauxScrollFrame_Update(self.scrollBar, totalItems, MAX_VISIBLE_ROWS, ROW_HEIGHT);

  local offset = FauxScrollFrame_GetOffset(self.scrollBar)
  for i, row in ipairs(self.rows) do
    if i >= offset and i < offset + MAX_VISIBLE_ROWS then
      local previousRow = self.rows[i - 1]
      if previousRow and previousRow:IsVisible() then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -2)
      else
        row:SetPoint("TOPLEFT", self.frame, 26, -78)
      end
      row:Show()
    else
      row:Hide()
    end
  end
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
end

function WhatsTrainingUI:ShowFrame()
  self.tab:SetChecked(true)
  self.frame:Show()
end

function WhatsTrainingUI:handleTabToggle()
  if self.tab:GetChecked() then
    self.frame:Show()
  else
    self.frame:Hide()
  end
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

  tab:SetScript("OnClick", function() WhatsTrainingUI:handleTabToggle() end)
  tab:SetScript("OnEnter", function() WhatsTrainingUI:showTabTooltip() end)
  tab:SetScript("OnLeave", function() WhatsTrainingUI:hideTabTooltip() end)

  return tab
end

function WhatsTrainingUI:InitDisplay()
  self.frame = CreateFrame("Frame", "WhatsTrainingFrame", SpellBookFrame)
  self.frame:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 0, 0)
  self.frame:SetPoint("BOTTOMRIGHT", SpellBookFrame, "BOTTOMRIGHT", 0, 0)
  self.frame:SetFrameStrata("HIGH")
  -- prevents mouse hover leaking
  self.frame:EnableMouse(true)

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

  self.frame:Hide()
end

---Sets the given spells as rows
---@param spells table<SpellCategories, Spell[]>
function WhatsTrainingUI:SetItems(spells)
  local i = 1
  local spellSchool = nil
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
        row:SetScript("OnEnter", function()
          self.tooltip:SetOwner(row, "ANCHOR_RIGHT")
          self.tooltip:AddDoubleLine(row.spell.name, row.spell.id, 1, 1, 1, 1, 1, 1)
          self.tooltip:AddDoubleLine(row.spell.school, row.spell.subText)
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
