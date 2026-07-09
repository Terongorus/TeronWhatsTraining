setfenv(1, WhatsTraining)
WhatsTraining = getfenv(1)

function WhatsTraining:Initialise()
  local localisedClass, englishClass = UnitClass("player")
  
  -- Initialize saved variables in the real global namespace _G
  if _G.WT_ShowIgnoreNotice == nil then _G.WT_ShowIgnoreNotice = true end
  if _G.WT_ShowLearnedNotice == nil then _G.WT_ShowLearnedNotice = true end
  if _G.WT_IgnoredSpells == nil then _G.WT_IgnoredSpells = {} end
  if _G.WT_LearnedPetAbilities == nil then _G.WT_LearnedPetAbilities = {} end
  if _G.WT_NeedsToOpenBeastTraining == nil and englishClass == "HUNTER" then
    _G.WT_NeedsToOpenBeastTraining = true
  end

  local name = UnitName("player")
  if name then
    PlayerData:SetName(name)
  end
  local localisedRace, englishRace = UnitRace("player")
  PlayerData:SetClass(englishClass)
  PlayerData:SetRace(englishRace)
  PlayerData:SetLevel(UnitLevel("player"))
  PlayerData:SetSpellsByLevel(ClassSpellsByLevel[PlayerData.class])

  local overridenSpells = OverridenSpells[PlayerData.class]
  if (overridenSpells) then
    PlayerData:SetOverriddenSpells(overridenSpells)
  end

  PlayerData:GetKnownSpells()
  PlayerData:GetAvailableSpells()

  WhatsTrainingUI:Initialize()
  WhatsTrainingUI:SetItems(PlayerData.spellsByCategory)

  -- Register Hunter Beast Training scanning
  if englishClass == "HUNTER" and not self.hunterHooked then
    local petAbilityUpdateFrame = CreateFrame("Frame")
    petAbilityUpdateFrame:RegisterEvent("CRAFT_UPDATE")
    petAbilityUpdateFrame:RegisterEvent("SPELLS_CHANGED")
    petAbilityUpdateFrame:SetScript("OnEvent", function()
      local numCrafts = GetNumCrafts()
      if numCrafts == 0 or GetCraftDisplaySkillLine() then return end
      if not _G.WT_LearnedPetAbilities then _G.WT_LearnedPetAbilities = {} end
      for i = 1, numCrafts do
        local name, rank = GetCraftInfo(i)
        if name then
          if not _G.WT_LearnedPetAbilities[name] then
            _G.WT_LearnedPetAbilities[name] = {}
          end
          if rank ~= nil then
            _G.WT_LearnedPetAbilities[name][rank] = true
          end
          
          local icon = GetCraftIcon(i)
          if icon then
            icon = string.lower(icon)
            if not _G.WT_LearnedPetAbilities[icon] then
              _G.WT_LearnedPetAbilities[icon] = {}
            end
            if rank ~= nil then
              _G.WT_LearnedPetAbilities[icon][rank] = true
            end
          end
        end
      end
      _G.WT_NeedsToOpenBeastTraining = false
      WhatsTraining:Refresh()
    end)

    local learnedSpellMatchPattern = string.gsub(ERR_LEARN_SPELL_S, "%%s", "(.+)")
    local petChatParserFrame = CreateFrame("Frame")
    petChatParserFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    petChatParserFrame:SetScript("OnEvent", function()
      local msg = arg1
      if msg then
        local _, _, matchedSpellName = string.find(msg, learnedSpellMatchPattern)
        if matchedSpellName then
          _G.WT_NeedsToOpenBeastTraining = true
          WhatsTraining:Refresh()
        end
      end
    end)
    self.hunterHooked = true
  end

  -- Register Warlock Grimoire Merchant scanning
  if englishClass == "WARLOCK" and not self.warlockHooked then
    local scan = CreateFrame("GameTooltip", "WTWarlockTomeScanningTooltip", nil, "GameTooltipTemplate")
    scan:SetOwner(UIParent, "ANCHOR_NONE")
    
    local requiresLevelPattern = string.gsub(SPELL_REQUIRED_FORM, "%%d", "(%%d+)")
    
    local function isKnown(merchantIndex)
      scan:ClearLines()
      local link = GetMerchantItemLink(merchantIndex)
      if not link then return false end
      scan:SetHyperlink(link)
      local lines = scan:NumLines()
      for i = lines, 1, -1 do
        local text = getglobal("WTWarlockTomeScanningTooltipTextLeft" .. i):GetText()
        if text then
          if string.find(text, requiresLevelPattern) then
            return false
          end
          if text == ITEM_SPELL_KNOWN then
            return true
          end
        end
      end
      return false
    end

    local original_MerchantFrame_Update = MerchantFrame_Update
    MerchantFrame_Update = function()
      original_MerchantFrame_Update()
      
      local numMerchantItems = GetMerchantNumItems()
      for i = 1, MERCHANT_ITEMS_PER_PAGE do
        local index = ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i
        if index <= numMerchantItems then
          local merchantItemID = GetMerchantItemID(index)
          if merchantItemID then
            local isTome = false
            if PlayerData.spellsById[merchantItemID] and PlayerData.spellsById[merchantItemID].isTome then
              isTome = true
            end
            if isTome then
              if not _G.WT_LearnedPetAbilities[merchantItemID] then
                if isKnown(index) then
                  _G.WT_LearnedPetAbilities[merchantItemID] = true
                  WhatsTraining:Refresh()
                end
              end
              if _G.WT_LearnedPetAbilities[merchantItemID] then
                local merchantButton = getglobal("MerchantItem" .. i)
                local itemButton = getglobal("MerchantItem" .. i .. "ItemButton")
                if merchantButton and itemButton then
                  SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0)
                  SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0)
                  SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0)
                  SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0)
                end
              end
            end
          end
        end
      end
    end
    self.warlockHooked = true
  end
end

function WhatsTraining:Refresh()
  if not WhatsTrainingUI.frame then return end
  PlayerData:SetLevel(UnitLevel("player"))
  PlayerData:GetKnownSpells()
  PlayerData:GetAvailableSpells()
  
  WhatsTrainingUI:ClearItems()
  WhatsTrainingUI:SetItems(PlayerData.spellsByCategory)
  WhatsTrainingUI:Update()
end

local function OnEvent()
  if event == "PLAYER_ENTERING_WORLD" then
    WhatsTraining:Initialise()
  elseif event == "PLAYER_LEVEL_UP" then
    WhatsTraining:Refresh()
  elseif event == "SPELLS_CHANGED" then
    WhatsTraining:Refresh()
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("SPELLS_CHANGED")
f:SetScript("OnEvent", OnEvent)