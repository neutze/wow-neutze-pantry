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
  { key="hp5",   macro="AutoHP5",        label="Health Regen", words={"health every 5", "health per 5"} },
  { key="hit",   macro="AutoHit",        label="Hit",          words={"hit rating", "chance to hit"} },
  { key="crit",  macro="AutoCrit",       label="Crit",         words={"critical strike"} },
  { key="breath",macro="AutoFireBreath", label="Fire Breath",  tip="Dragonbreath Chili and similar damage-proc food.", words={"belch"} },
  { key="speed", macro="AutoSpeed",      label="Speed",        words={"movement speed", "run speed"} },
  { key="armor", macro="AutoArmor",      label="Armor",        words={"armor"} },
  { key="str",   macro="AutoStrength",   label="Strength",     words={"strength"} },
  { key="agi",   macro="AutoAgility",    label="Agility",      words={"agility"} },
  { key="int",   macro="AutoIntellect",  label="Intellect",    words={"intellect"} },
  { key="sta",   macro="AutoStamina",    label="Stamina",      words={"stamina"} },
  { key="spi",   macro="AutoSpirit",     label="Spirit",       words={"spirit"} },
  { key="any",   macro="AutoWellFed",    label="Any (priority)", tip="Best food of your top stat; falls back down your priority list.", words={"pool:never"} },
}
local LABEL = {}; for _, c in ipairs(CATS) do LABEL[c.key] = c.label end

local DEFAULTS = {
  WARRIOR = {"str","sta","ap","agi","armor"},  ROGUE  = {"agi","ap","str","sta"},
  HUNTER  = {"agi","ap","int","sta"},          PALADIN= {"str","sta","int","heal","sp"},
  SHAMAN  = {"int","sp","sta","agi","ap"},     DRUID  = {"sta","agi","int","heal","sp"},
  PRIEST  = {"sp","int","spi","heal","sta"},   MAGE   = {"sp","int","spi","sta"},
  WARLOCK = {"sp","sta","int","spi"},
}
local ALL = {"str","agi","sta","int","spi","ap","sp","heal","hit","crit","mp5","hp5","armor","breath","speed"}

-- Spec presets per class (the first one is the class default above).
local SPECS = {
  WARRIOR = { {"Arms / Fury", DEFAULTS.WARRIOR}, {"Protection", {"sta","armor","str","agi"}} },
  ROGUE   = { {"All specs", DEFAULTS.ROGUE} },
  HUNTER  = { {"All specs", DEFAULTS.HUNTER} },
  PALADIN = { {"Holy", {"heal","int","mp5","spi","sta"}}, {"Protection", {"sta","armor","str","sp"}}, {"Retribution", {"str","ap","agi","sta","int"}} },
  SHAMAN  = { {"Elemental", {"sp","int","mp5","sta"}}, {"Enhancement", {"str","agi","ap","sta","int"}}, {"Restoration", {"heal","int","mp5","sta"}} },
  DRUID   = { {"Balance", {"sp","int","mp5","spi","sta"}}, {"Feral (Cat)", {"agi","str","ap","sta"}}, {"Feral (Bear)", {"sta","agi","armor","str"}}, {"Restoration", {"heal","int","mp5","spi","sta"}} },
  PRIEST  = { {"Holy / Discipline", {"heal","int","spi","mp5","sta"}}, {"Shadow", {"sp","int","sta","spi"}} },
  MAGE    = { {"All specs", DEFAULTS.MAGE} },
  WARLOCK = { {"All specs", DEFAULTS.WARLOCK} },
}

-- Stat priority for this character: class default, then every other stat; Fishing always last.
local function Priority()
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  if not NeutzePantryCharDB.priority then
    local _, class = UnitClass("player")
    local list, seen = {}, {}
    local first = SPECS[class] and SPECS[class][1]
    for _, k in ipairs(first and first[2] or DEFAULTS[class] or {}) do list[#list+1] = k; seen[k] = true end
    for _, k in ipairs(ALL) do if not seen[k] then list[#list+1] = k end end
    NeutzePantryCharDB.priority = list
  end
  local list, seen = NeutzePantryCharDB.priority, {}
  for _, k in ipairs(list) do seen[k] = true end
  for _, k in ipairs(ALL) do if not seen[k] then list[#list+1] = k end end   -- stats added in newer versions
  return list
end

-- Replace the priority with a spec preset (preset stats first, every other stat after).
local function ApplySpec(i)
  local _, class = UnitClass("player")
  local spec = (SPECS[class] or {})[i]
  if not spec then return end
  local list, seen = {}, {}
  for _, k in ipairs(spec[2]) do list[#list+1] = k; seen[k] = true end
  for _, k in ipairs(ALL) do if not seen[k] then list[#list+1] = k end end
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  NeutzePantryCharDB.priority, NeutzePantryCharDB.spec = list, spec[1]
end

local function use(id) return "#showtooltip\n/use item:" .. id end

BF.RegisterSection({ display=2, kind="food", title="Well Fed food", noun="food", order=60, multi=true,
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
  extraUI = function(parent, anchor)
    local _, class = UnitClass("player")
    local specs = SPECS[class] or {}
    local sl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sl:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
    sl:SetText("Spec:")
    local row, dd = {}, nil
    local function specName() return (NeutzePantryCharDB and NeutzePantryCharDB.spec) or "Choose spec" end
    local function refresh()
      for i, k in ipairs(Priority()) do row[i]:SetText(i .. ". " .. LABEL[k]); row[i].key = k end
      if dd then
        if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dd, specName()) else dd:SetText(specName()) end
      end
    end
    local function pick(i) ApplySpec(i); refresh(); BF.Update() end
    if UIDropDownMenu_Initialize then                 -- Blizzard dropdown
      dd = CreateFrame("Frame", "NeutzePantrySpecDropDown", parent, "UIDropDownMenuTemplate")
      dd:SetPoint("LEFT", sl, "RIGHT", -8, -2)
      UIDropDownMenu_SetWidth(dd, 150)
      UIDropDownMenu_Initialize(dd, function()
        for i, sp in ipairs(specs) do
          local info = UIDropDownMenu_CreateInfo()
          info.text, info.checked = sp[1], (sp[1] == specName())
          info.func = function() pick(i); CloseDropDownMenus() end
          UIDropDownMenu_AddButton(info)
        end
      end)
    else                                              -- fallback: button that cycles specs
      dd = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
      dd:SetSize(160, 22); dd:SetPoint("LEFT", sl, "RIGHT", 8, 0)
      dd:SetScript("OnClick", function()
        local cur = 1
        for i, sp in ipairs(specs) do if sp[1] == specName() then cur = i end end
        pick(cur % math.max(1, #specs) + 1)
      end)
    end
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 0, -14)
    h:SetText("Fallback order for this character (picking a spec resets it; click a stat to move it up). Fishing is always last:")
    for i = 1, #ALL do
      local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
      b:SetScript("OnClick", function(self)
        local p = Priority()
        for j, k in ipairs(p) do
          if k == self.key and j > 1 then p[j], p[j-1] = p[j-1], p[j]; NeutzePantryCharDB.spec = "Custom"; break end
        end
        refresh(); BF.Update()
      end)
      row[i] = b
    end
    -- size every button for the longest possible label, then lay them out
    for i, b in ipairs(row) do b:SetText("11. Attack Power") end
    local last, rows = BF.LayoutButtons(row, h, -4)
    refresh()
    BF.AddHeight(52 + rows * 25)
    return last
  end,
  cats = CATS })
