-- Neutze's Well Fed: buff food per stat, with a fallback.
-- Every stat macro eats your best food for that stat. If you have none, it eats another Well Fed food
-- (Forever: every Well Fed food also gives +5% kill XP): it walks your stat priority and takes the
-- LOWEST food of the first stat you carry, so leftovers get used up and good food is kept.
-- AutoWellFed: one button that eats the best food of your top stat. Fishing food is always last.
local BF = NeutzePantry
local FED = {"well fed", "also increase", "nutritious"}

local CATS = {
  { key="any",   macro="AutoWellFed",    label="Best for my spec", tip="Eats the best food for your class and spec (the Spec dropdown below): your top stat first, then down the list.", words={"pool:never"} },
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
}
local LABEL = {}; for _, c in ipairs(CATS) do LABEL[c.key] = c.label end

local ALL = BF.ALL
local Priority = BF.Priority

local function use(id) return "#showtooltip\n/use item:" .. id end

BF.RegisterSection({ display=2, kind="food", title="Well Fed food", noun="food", order=60, multi=true, sortBySpec=true,
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
    local row = {}
    local function refresh()
      for i, k in ipairs(Priority()) do row[i]:SetText(i .. ". " .. LABEL[k]); row[i].key = k end
    end
    local h = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    h:SetText("Fallback order for this character (the spec at the top sets it; click a stat to move it up). Fishing is always last:")
    for i = 1, #ALL do
      local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
      b:SetScript("OnClick", function(self)
        local p = Priority()
        for j, k in ipairs(p) do
          if k == self.key and j > 1 then p[j], p[j-1] = p[j-1], p[j]; NeutzePantryCharDB.spec = "Custom"; break end
        end
        BF.Update(); BF.Rebuild()
      end)
      row[i] = b
    end
    -- size every button for the longest possible label, then lay them out
    for i, b in ipairs(row) do b:SetText("11. Attack Power") end
    local last, rows = BF.LayoutButtons(row, h, -4)
    refresh()
    BF.AddHeight(26 + rows * 25)
    return last
  end,
  cats = CATS })
