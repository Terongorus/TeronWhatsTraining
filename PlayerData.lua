setfenv(1, WhatsTraining)

local ExtraSpells = {
  [78] = { name = "Heroic Strike", subText = "Rank 1", icon = "Interface\\Icons\\Ability_Rogue_Ambush" },
  [133] = { name = "Fireball", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Fire_FlameBolt" },
  [168] = { name = "Frost Armor", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Frost_FrostArmor02" },
  [331] = { name = "Healing Wave", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity" },
  [403] = { name = "Lightning Bolt", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
  [585] = { name = "Smite", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Holy_HolySmite" },
  [635] = { name = "Holy Light", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
  [686] = { name = "Shadow Bolt", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Shadow_ShadowBolt" },
  [687] = { name = "Demon Armor", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Shadow_RagingScream" },
  [1515] = { name = "Tame Beast", subText = "", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
  [1752] = { name = "Sinister Strike", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Shadow_RitualOfSacrifice" },
  [2050] = { name = "Lesser Heal", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Holy_LesserHeal" },
  [2098] = { name = "Eviscerate", subText = "Rank 1", icon = "Interface\\Icons\\Ability_Rogue_Eviscerate" },
  [5176] = { name = "Wrath", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_AbolishMagic" },
  [5185] = { name = "Healing Touch", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" },
  [5487] = { name = "Bear Form", subText = "Shapeshift", icon = "Interface\\Icons\\Ability_Racial_BearForm" },
  [5570] = { name = "Insect Swarm", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_InsectSwarm" },
  [6807] = { name = "Maul", subText = "Rank 1", icon = "Interface\\Icons\\Ability_Druid_Maul" },
  [16857] = { name = "Faerie Fire (Feral)", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_FaerieFire" },
  [19306] = { name = "Counterattack", subText = "Rank 1", icon = "Interface\\Icons\\Ability_Warrior_Challange" },
  [19386] = { name = "Wyvern Sting", subText = "Rank 1", icon = "Interface\\Icons\\INV_Spear_02" },
  [25290] = { name = "Blessing of Wisdom", subText = "Rank 6", icon = "Interface\\Icons\\Spell_Holy_SealOfWisdom" },
  [25291] = { name = "Blessing of Might", subText = "Rank 7", icon = "Interface\\Icons\\Spell_Holy_FistOfJustice" },
  
  -- Talents
  [11113] = { name = "Blast Wave", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Holy_Fireshield" },
  [11366] = { name = "Pyroblast", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Fire_Fireball02" },
  [11426] = { name = "Ice Barrier", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Ice_Lavanaskin" },
  [16511] = { name = "Hemorrhage", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain" },
  [16689] = { name = "Nature's Grasp", subText = "Rank 1", icon = "Interface\\Icons\\Spell_Nature_NaturesWrath" },
  [21084] = { name = "Seal of Command", subText = "Rank 1", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" }
}

---@class RequiredTalent
---@field name string Name of the talent
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
---@field cost integer The copper cost of the spell
---@field race? string The single race that this spell is allowed to be used
---@field races? integer[] The list of races that this spell is allowed to be used
---@field faction? string The faction requirement for the spell
---@field isTome? boolean True if this spell is a warlock pet grimoire tome

PlayerData = {
  name = "",
  race = "",
  class = "",
  level = 1,
  spellsByLevel = {},
  spellsById = {},
  spellsByNameAndRank = {},
  knownSpellIds = {},
  spellsByCategory = {},
  overridenSpells = {}
}

function PlayerData:SayHello()
  Utils.log("Hello! My name is " ..
    self.name .. " and I'm a level " .. self.level .. " " .. self.race .. " " .. self.class)
end

function PlayerData:SetName(name)
  self.name = name
end

function PlayerData:SetRace(race)
  self.race = race
end

function PlayerData:SetClass(class)
  self.class = class
end

function PlayerData:SetLevel(level)
  self.level = level
end

function PlayerData:SetSpellsByLevel(spellsByLevel)
  self.spellsById = {}
  self.spellsByNameAndRank = {}
  self.spellsByLevel = Utils.FilterByRace(spellsByLevel, self.race)

  for _, spells in pairs(self.spellsByLevel) do
    for _, spell in ipairs(spells) do
      self.spellsById[spell.id] = spell

      local spellNameKey = Utils.getSpellWithRankKey(spell.name, spell.subText)
      if not self.spellsByNameAndRank[spellNameKey] then
        self.spellsByNameAndRank[spellNameKey] = {}
      end
      tinsert(self.spellsByNameAndRank[spellNameKey], spell)
    end
  end
end

function PlayerData:SetOverriddenSpells(overridenSpells)
  self.overridenSpells = overridenSpells
end

function PlayerData:GetKnownSpells()
  self.knownSpellIds = {}
  self.spellbookSpells = {}
  local i = 1
  while true do
    local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
    if not name then
      break
    end

    local icon = GetSpellTexture(i, BOOKTYPE_SPELL)
    if icon then
      icon = string.lower(icon)
    end
    local _, _, rankNumStr = string.find(rank or "", "(%d+)")
    local rankNum = tonumber(rankNumStr) or 0

    tinsert(self.spellbookSpells, {
      name = name,
      rank = rank,
      rankNum = rankNum,
      icon = icon
    })

    local spellNameKey = Utils.getSpellWithRankKey(name, rank)
    local spells = self.spellsByNameAndRank[spellNameKey]

    if (spells) then
      for _, spell in ipairs(spells) do
        tinsert(self.knownSpellIds, spell.id)

        local overridenSpellIds = self.overridenSpells[spell.id]
        if (overridenSpellIds) then
          for _, spellId in ipairs(overridenSpellIds) do
            tinsert(self.knownSpellIds, spellId)
          end
        end
      end
    end

    i = i + 1
  end
end

function PlayerData:IsSpellKnown(spell)
  if Utils.TableHasValue(self.knownSpellIds, spell.id) then
    return true
  end

  local _, _, dbRankNumStr = string.find(spell.subText or "", "(%d+)")
  local dbRankNum = tonumber(dbRankNumStr) or 0
  local dbIcon = string.lower(spell.icon or "")

  if self.spellbookSpells then
    for _, sbSpell in ipairs(self.spellbookSpells) do
      if sbSpell.icon == dbIcon and sbSpell.rankNum == dbRankNum then
        if spell.level <= self.level then
          return true
        end
      end
    end
  end

  return false
end

function PlayerData:IsSpellRequirementsMet(spellIds)
  local isRequiredSpellKnown = true
  for _, spellId in ipairs(spellIds) do
    local reqSpell = self.spellsById[spellId]
    if reqSpell then
      if not self:IsSpellKnown(reqSpell) then
        isRequiredSpellKnown = false
        break
      end
    else
      local extraSpell = ExtraSpells[spellId]
      if extraSpell then
        local tempSpell = {
          id = spellId,
          name = extraSpell.name,
          subText = extraSpell.subText,
          icon = extraSpell.icon,
          level = 1
        }
        if not self:IsSpellKnown(tempSpell) then
          isRequiredSpellKnown = false
          break
        end
      else
        if not Utils.TableHasValue(self.knownSpellIds, spellId) then
          isRequiredSpellKnown = false
          break
        end
      end
    end
  end

  return isRequiredSpellKnown
end

function PlayerData:IsPetSpellKnown(spell)
  if not WT_LearnedPetAbilities then return false end
  if spell.isTome then
    return WT_LearnedPetAbilities[spell.id] == true
  elseif spell.school == "Pet Training" then
    local icon = string.lower(spell.icon or "")
    return (WT_LearnedPetAbilities[spell.name] and WT_LearnedPetAbilities[spell.name][spell.subText] == true)
        or (WT_LearnedPetAbilities[icon] and WT_LearnedPetAbilities[icon][spell.subText] == true)
  end
  return false
end

function PlayerData:GetAvailableSpells()
  self.spellsByCategory = {}

  local availableSpells = {}
  local missingTalentRequirement = {}
  local missingRequirements = {}
  local comingSoon = {}
  local notAvailable = {}
  local knownSpells = {}
  local petSpells = {}
  local knownPetSpells = {}
  local ignoredSpells = {}

  if not _G.WT_IgnoredSpells then _G.WT_IgnoredSpells = {} end
  if not _G.WT_LearnedPetAbilities then _G.WT_LearnedPetAbilities = {} end

  for level, spells in pairs(self.spellsByLevel) do
    for _, spell in ipairs(spells) do
      -- 1. Check if ignored
      if WT_IgnoredSpells[spell.id] then
        tinsert(ignoredSpells, spell)

      -- 2. Check if known class spell
      elseif PlayerData:IsSpellKnown(spell) then
        if spell.school == "Pet Training" or spell.isTome then
          tinsert(knownPetSpells, spell)
        else
          tinsert(knownSpells, spell)
        end

      -- 3. Check if known pet spell
      elseif PlayerData:IsPetSpellKnown(spell) then
        tinsert(knownPetSpells, spell)

      -- 4. Check if available pet spell
      elseif spell.school == "Pet Training" or spell.isTome then
        tinsert(petSpells, spell)

      -- 5. Upcoming level spells
      elseif (spell.level > self.level) then
        if (spell.level - self.level <= 2) then
          tinsert(comingSoon, spell)
        else
          tinsert(notAvailable, spell)
        end

      -- 6. Check talent and level requirements
      else
        if spell.requiredTalent ~= nil and not PlayerData:IsTalentKnown(spell.requiredTalent.name, spell.requiredTalent.tabIndex) then
          tinsert(missingTalentRequirement, spell)
        elseif spell.requiredIds ~= nil and not PlayerData:IsSpellRequirementsMet(spell.requiredIds) then
          tinsert(missingRequirements, spell)
        else
          tinsert(availableSpells, spell)
        end
      end
    end
  end

  table.sort(missingTalentRequirement, function(a, b) return a.level < b.level end)
  table.sort(missingRequirements, function(a, b) return a.level < b.level end)
  table.sort(comingSoon, function(a, b) return a.level < b.level end)
  table.sort(notAvailable, function(a, b) return a.level < b.level end)
  table.sort(knownSpells, function(a, b) return a.level < b.level end)
  table.sort(petSpells, function(a, b) return a.level < b.level end)
  table.sort(knownPetSpells, function(a, b) return a.level < b.level end)
  table.sort(ignoredSpells, function(a, b) return a.level < b.level end)
  
  table.sort(availableSpells, function(a, b)
    if a.school == b.school and a.level == b.level then
      return a.name < b.name
    elseif a.school == b.school then
      return a.level < b.level
    else
      return a.school < b.school
    end
  end)

  self.spellsByCategory[SpellCategories.MISSING_TALENT] = missingTalentRequirement
  self.spellsByCategory[SpellCategories.MISSING_REQS] = missingRequirements
  self.spellsByCategory[SpellCategories.AVAILABLE] = availableSpells
  self.spellsByCategory[SpellCategories.NEXT_LEVEL] = comingSoon
  self.spellsByCategory[SpellCategories.NOT_LEVEL] = notAvailable
  self.spellsByCategory[SpellCategories.PET] = petSpells
  self.spellsByCategory[SpellCategories.KNOWN_PET] = knownPetSpells
  self.spellsByCategory[SpellCategories.IGNORED] = ignoredSpells
  self.spellsByCategory[SpellCategories.KNOWN] = knownSpells
end

function PlayerData:IsTalentKnown(spellname, talentTabIndex)
  local numTalents = GetNumTalents(talentTabIndex);
  for i = 1, numTalents do
    local nameTalent, icon, tier, column, currRank, maxRank = GetTalentInfo(talentTabIndex, i);
    if spellname == nameTalent then
      return currRank > 0
    end
  end
  return false
end

function PlayerData:GetAllRanksOfSpell(spellName)
  local spellIds = {}
  for level, spells in pairs(self.spellsByLevel) do
    for _, spell in ipairs(spells) do
      if spell.name == spellName then
        tinsert(spellIds, spell.id)
      end
    end
  end
  return spellIds
end