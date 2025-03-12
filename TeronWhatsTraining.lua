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
  if event == "PLAYER_ENTERING_WORLD" then
    WhatsTraining:Initialise()
  elseif event == "SPELLS_CHANGED" then
    WhatsTrainingUI:HideFrame()
    if WhatsTraining_Initialized == true then
      PlayerData:GetAvailableSpells()
    end  
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("SPELLS_CHANGED")
f:SetScript("OnEvent", OnEvent)