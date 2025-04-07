setfenv(1, WhatsTraining)
WhatsTraining = {}

WhatsTraining_Initialized = false

function WhatsTraining:Initialise()
  if WhatsTraining_Initialized == false then
    local name = UnitName("player")
    if name then
      PlayerData:SetName(name)
    end
    PlayerData:SetClass(UnitClass("player"))
    PlayerData:SetRace(UnitRace("player"))
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
    WhatsTraining_Initialized = true
  end
end

local function OnEvent()
  local level = 1
  if event == "PLAYER_ENTERING_WORLD" then
    WhatsTraining:Initialise()
  elseif event == "SPELLS_CHANGED" then
    WhatsTrainingUI:HideFrame()
  elseif event == "PLAYER_LEVEL_UP" or event == "LEARNED_SPELL_IN_TAB" then
    if WhatsTraining_Initialized == true then
      -- Stupid WoW API doesn't allow Frame to be destroyed! So just Hide and forget about them
      -- this will leave garbage in memory but ... it is what it is
      for i, row in ipairs(WhatsTrainingUI.rows) do
        row:Hide()
      end
      if event == "PLAYER_LEVEL_UP" then
        level = arg1
      else
        level = UnitLevel("player")
      end
      PlayerData:SetLevel(level)
      PlayerData:SetSpellsByLevel(ClassSpellsByLevel[PlayerData.class])
      local overridenSpells = OverridenSpells[PlayerData.class]
      if (overridenSpells) then
        PlayerData:SetOverriddenSpells(overridenSpells)
      end
        WhatsTrainingUI.rows = {}
      PlayerData:GetKnownSpells()
      PlayerData:GetAvailableSpells()
      WhatsTrainingUI:SetItems(PlayerData.spellsByCategory)     
      WhatsTrainingUI:Update() 
    end  
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SPELLS_CHANGED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("LEARNED_SPELL_IN_TAB")
f:SetScript("OnEvent", OnEvent)
