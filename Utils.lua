setfenv(1, WhatsTraining)
Utils = {}

function Utils.FormatMoney(amount)
  local gold = math.floor(amount / 10000)
  local silver = math.floor((amount - gold * 10000) / 100)
  local copper = amount - gold * 10000 - silver * 100
  local text = ""
  if gold > 0 then
    text = text .. gold .. "|cffffd700g|r "
  end
  if silver > 0 or gold > 0 then
    text = text .. silver .. "|cffc7c7c7s|r "
  end
  text = text .. copper .. "|cffeda55fc|r"
  return text
end

--- Filters the spellsByLevel table with the given predicate
---@param spellsByLevel SpellsByLevel
---@param predicate fun(spell: Spell): boolean
---@return SpellsByLevel
local function filter(spellsByLevel, predicate)
  local output = {}
  for level, spells in pairs(spellsByLevel) do
    output[level] = {}
    for _, spell in ipairs(spells) do
      if (predicate(spell) == true) then
        tinsert(output[level], spell)
      end
    end
  end
  return output
end

function Utils.TableHasValue(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end

  return false
end

--- Returns the table of spells filtered by the given race
---@param spellsByLevel SpellsByLevel
---@param playerRace string
---@return SpellsByLevel
function Utils.FilterByRace(spellsByLevel, playerRace)
  return filter(spellsByLevel, function(spell)
    if (spell.race == nil and spell.races == nil) then
      return true
    end

    if (spell.races == nil) then
      return spell.race == playerRace
    end

    return Utils.TableHasValue(spell.races, playerRace)
  end)
end

--- Returns the table of spells that has level requirements less than or equal the given level
---@param spellsByLevel SpellsByLevel
---@param playerLevel integer
---@return SpellsByLevel
function Utils.FilterByLevel(spellsByLevel, playerLevel)
  return filter(spellsByLevel, function(spell)
    return (spell.level <= playerLevel)
  end)
end

--- Splits the given string by the given separator
---@param input string
---@param separator? string
--- Returns the rank number of a given rankText
---@param rankText? string
---@return integer?
function Utils.GetRankNumber(rankText)
  if rankText == nil or rankText == "" then
    return 0 -- Lua arrays start from 1.
  end

  local _, _, rankNumber = string.find(rankText, "(%d+)")
  return tonumber(rankNumber) or 0
end

function Utils.log(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

---Returns the spell key for a given name and rank
---@param name string
---@param rank string|nil
---@return string
function Utils.getSpellWithRankKey(name, rank)
  local spellNameKey = name
  if (rank ~= "" and rank ~= nil) then
    spellNameKey = spellNameKey .. "-" .. rank
  end

  return spellNameKey
end

---Returns the length of a table
---@param t table
---@return integer
function Utils.tableLength(t)
  if not t then return 0 end
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end