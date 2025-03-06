setfenv(1, WhatsTraining)

---@class RequiredTalent
---@field id integer ID of the talent
---@field tabIndex integer tabIndex of the talent

---@class Spell
---@field id integer The database ID of the spell
---@field name string Name of the spell
---@field subText? string Rank of the spell
---@field level integer Base level required for the spell
---@field icon string Icon of the spell
---@field requiredIds? integer[] List of required spell ids for this spell
---@field requiredTalent? RequiredTalent The required talent for this spell
---@field school string The school of the spell
---@field race? string The single race that this spell is allowed to be used
---@field races? integer[] The list of races that this spell is allowed to be used
---@field faction? string The faction requirement for the spell

PlayerData = {
  ---@type string
  name = "",
  ---@type string
  race = "",
  ---@type string
  class = "",
  ---@type integer
  level = 1,
  ---@type SpellsByLevel
  spellsByLevel = {},
  ---@type table<integer, Spell>
  spellsById = {},
  ---@type table<string, Spell>
  spellsByNameAndRank = {},
  ---@type table<integer>
  knownSpellIds = {},
  ---@type table<SpellCategories, Spell[]>
  spellsByCategory = {},
  ---@type table<number, table<number, number>>
  overridenSpells = {}
}

function PlayerData:SayHello()
  Utils.log("Hello! My name is " ..
    self.name .. " and I'm a level " .. self.level .. " " .. self.race .. " " .. self.class)
end

---Sets the player name
---@param name string
function PlayerData:SetName(name)
  self.name = name
end

---Sets the player race
---@param race string
function PlayerData:SetRace(race)
  self.race = race
end

---Sets the player class
---@param class string
function PlayerData:SetClass(class)
  self.class = class
end

---Sets the player class
---@param level integer
function PlayerData:SetLevel(level)
  self.level = level
end

---Sets the spells by level for the player
---@param spellsByLevel SpellsByLevel
function PlayerData:SetSpellsByLevel(spellsByLevel)
  self.spellsByLevel = Utils.FilterByRace(spellsByLevel, self.race)

  for _, spells in pairs(self.spellsByLevel) do
    for _, spell in ipairs(spells) do
      self.spellsById[spell.id] = spell

      local spellNameKey = Utils.getSpellWithRankKey(spell.name, spell.subText)
      self.spellsByNameAndRank[spellNameKey] = spell
    end
  end
end

--[[
    overridenSpells is just a set of tables, where each table is a list of spell ids that
    totally overwrite a previous rank of that ability ordered by rank.
    Most warrior and rogue abilities are like this, as they cost the same amount
    of resources but just last longer or do more damage.
]]
---@param overridenSpells table<number, table<number, number>>
function PlayerData:SetOverriddenSpells(overridenSpells)
  self.overridenSpells = overridenSpells
end

function PlayerData:GetKnownSpells()
  -- Reset the known spells every time we call this function
  self.knownSpellIds = {}
  local i = 1
  while true do
    local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then
      break
    end

    local spellNameKey = Utils.getSpellWithRankKey(name, rank)
    local spell = self.spellsByNameAndRank[spellNameKey]

    if (spell) then
      -- Utils.log(name .. " (" .. rank .. ") - [" .. spell.id .. "]")
      tinsert(self.knownSpellIds, spell.id)

      local overridenSpellIds = self.overridenSpells[spell.id]
      if (overridenSpellIds) then
        for _, spellId in ipairs(overridenSpellIds) do
          tinsert(self.knownSpellIds, spellId)
        end
      end
    end

    i = i + 1
  end
end

function PlayerData:IsSpellRequirementsMet(spellIds)
  local isRequiredSpellKnown = true
  for _, spellId in ipairs(spellIds) do
    if not Utils.TableHasValue(self.knownSpellIds, spellId) then
      isRequiredSpellKnown = false
      break
    end
  end

  return isRequiredSpellKnown
end

function PlayerData:GetAvailableSpells()
  self.spellsByCategory = {}

  ---@type Spell[]
  local availableSpells = {}
  ---@type Spell[]
  local missingTalentRequirement = {}
  ---@type Spell[]
  local missingRequirements = {}
  ---@type Spell[]
  local comingSoon = {}
  ---@type Spell[]
  local notAvailable = {}
  ---@type Spell[]
  local knownSpells = {}

  for level, spells in pairs(self.spellsByLevel) do
    for _, spell in ipairs(spells) do
      if not (Utils.TableHasValue(self.knownSpellIds, spell.id)) then -- spell is not learned yet
        if (spell.level > self.level) then
          if (spell.level - self.level <= 2) then
            tinsert(comingSoon, spell)
          else
            tinsert(notAvailable, spell)
          end
        else
          -- Check for talents
          if spell.requiredTalent ~= nil and not PlayerData:IsTalentKnown(spell.name, spell.requiredTalent.tabIndex) then
            tinsert(missingTalentRequirement, spell)
          elseif spell.requiredIds ~= nil and not PlayerData:IsSpellRequirementsMet(spell.requiredIds) then
            tinsert(missingRequirements, spell)
          else
            tinsert(availableSpells, spell)
          end
        end
      else -- spell is known
        tinsert(knownSpells, spell)
      end
    end
  end

  table.sort(missingTalentRequirement, function(a, b) return a.level < b.level end)
  table.sort(missingRequirements, function(a, b) return a.level < b.level end)
  table.sort(comingSoon, function(a, b) return a.level < b.level end)
  table.sort(notAvailable, function(a, b) return a.level < b.level end)
  table.sort(knownSpells, function(a, b) return a.level < b.level end)
  table.sort(availableSpells, function(a, b)
    if a.school == b.school and a.level == b.level then
      return a.name < b.name
    elseif a.school == b.school then
      return a.level < b.level   -- Secondary sort by level
    else
      return a.school < b.school -- Primary sort by school
    end
  end)

  self.spellsByCategory[SpellCategories.MISSING_TALENT] = missingTalentRequirement
  self.spellsByCategory[SpellCategories.MISSING_REQS] = missingRequirements
  self.spellsByCategory[SpellCategories.AVAILABLE] = availableSpells
  self.spellsByCategory[SpellCategories.NEXT_LEVEL] = comingSoon
  self.spellsByCategory[SpellCategories.NOT_LEVEL] = notAvailable
  self.spellsByCategory[SpellCategories.KNOWN] = knownSpells
end

function PlayerData:IsTalentKnown(spellname, talentTabIndex)
  local numTalents = GetNumTalents(talentTabIndex);
  for i = 1, numTalents do
    local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(talentTabIndex, i);
    if spellname == nameTalent then
      return currRank == maxRank
    end
  end
end