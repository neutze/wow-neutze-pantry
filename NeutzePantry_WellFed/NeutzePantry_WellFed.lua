-- Neutze's Well Fed: buff food per stat, with a fallback.
-- Every stat macro eats your best food for that stat. If you have none, it eats another Well Fed food
-- (Forever: every Well Fed food also gives +5% kill XP): it walks your stat priority and takes the
-- LOWEST food of the first stat you carry, so leftovers get used up and good food is kept.
-- AutoWellFed: one button that eats the best food of your top stat. Fishing food is always last.
local BF = NeutzePantry
local FED = {"well fed", "also increase", "nutritious"}

local CATS = {
  { key="fish",  macro="AutoFishing",    label="Fishing",      words={"fishing"} },
  { key="ap",    macro="AutoAP",         label="Attack Power", words={"attack power"} },
  { key="heal",  macro="AutoHealing",    label="Healing",      words=BF.HEAL_WORDS },
  { key="sp",    macro="AutoSpellPower", label="Spell Power",  words=BF.SP_WORDS },
  { key="mp5",   macro="AutoMP5",        label="Mana Regen",   words={"mana every 5", "mana per 5"} },
  { key="speed", macro="AutoSpeed",      label="Speed",        words={"movement speed", "run speed"} },
  { key="armor", macro="AutoArmor",      label="Armor",        words={"armor"} },
  { key="str",   macro="AutoStrength",   label="Strength",     words={"strength"} },
  { key="agi",   macro="AutoAgility",    label="Agility",      words={"agility"} },
  { key="int",   macro="AutoIntellect",  label="Intellect",    words={"intellect"} },
  { key="sta",   macro="AutoStamina",    label="Stamina",      words={"stamina"} },
  { key="spi",   macro="AutoSpirit",     label="Spirit",       words={"spirit"} },
  { key="any",   macro="AutoWellFed",    label="Any (priority)", words={"pool:never"} },
}
local LABEL = {}; for _, c in ipairs(CATS) do LABEL[c.key] = c.label end

local DEFAULTS = {
  WARRIOR = {"str","sta","ap","agi","armor"},  ROGUE  = {"agi","ap","str","sta"},
  HUNTER  = {"agi","ap","int","sta"},          PALADIN= {"str","sta","int","heal","sp"},
  SHAMAN  = {"int","sp","sta","agi","ap"},     DRUID  = {"sta","agi","int","heal","sp"},
  PRIEST  = {"sp","int","spi","heal","sta"},   MAGE   = {"sp","int","spi","sta"},
  WARLOCK = {"sp","sta","int","spi"},
}
local ALL = {"str","agi","sta","int","spi","ap","sp","heal","mp5","armor","speed"}

-- Stat priority for this character: class default, then every other stat; Fishing always last.
local function Priority()
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  if not NeutzePantryCharDB.priority then
    local _, class = UnitClass("player")
    local list, seen = {}, {}
    for _, k in ipairs(DEFAULTS[class] or {}) do list[#list+1] = k; seen[k] = true end
    for _, k in ipairs(ALL) do if not seen[k] then list[#list+1] = k end end
    NeutzePantryCharDB.priority = list
  end
  return NeutzePantryCharDB.priority
end

local function use(id) return "#showtooltip\n/use item:" .. id end

BF.RegisterSection({ kind="food", title="Well Fed food", noun="food", order=60,
  classify = function(name, text)
    local pos
    for _, w in ipairs(FED) do local q = text:find(w, 1, true); if q and (not pos or q < pos) then pos = q end end
    return pos and text:sub(pos) or nil
  end,
  body = function(c, best)
    local prio = Priority()
    if c.key == "any" then                                  -- best food of your top stat
      for _, k in ipairs(prio) do if best[k] then return use(best[k].id) end end
      if best.fish then return use(best.fish.id) end
      return nil
    end
    if best[c.key] then return use(best[c.key].id) end      -- the stat you asked for
    for _, k in ipairs(prio) do                             -- fallback: lowest leftover, by priority
      if k ~= c.key and best[k] then return use(best[k].loId) end
    end
    if c.key ~= "fish" and best.fish then return use(best.fish.loId) end
    return nil
  end,
  extraUI = function(panel, anchor)
    local h = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
    h:SetText("Fallback order for this character (click a stat to move it up). Fishing is always last:")
    local row, last = {}
    local function refresh()
      for i, k in ipairs(Priority()) do
        local b = row[i]
        b:SetText(i .. ". " .. LABEL[k])
        b.key = k
      end
    end
    for i = 1, #ALL do
      local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
      b:SetSize(88, 20)
      if i == 1 then b:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
      elseif i == 7 then b:SetPoint("TOPLEFT", row[1], "BOTTOMLEFT", 0, -2)
      else b:SetPoint("LEFT", last, "RIGHT", 2, 0) end
      b:SetScript("OnClick", function(self)
        local p = Priority()
        for j, k in ipairs(p) do
          if k == self.key and j > 1 then p[j], p[j-1] = p[j-1], p[j]; break end
        end
        refresh(); BF.Update()
      end)
      row[i] = b; last = b
    end
    refresh()
    return row[7]
  end,
  cats = CATS })
