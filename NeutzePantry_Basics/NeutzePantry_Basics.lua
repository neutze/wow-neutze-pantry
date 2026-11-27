-- Basics: Buffet-style macros for normal food/drink, potions, healthstone, mana gem and bandage.
local BF = NeutzePantry
local CONJURED = 1000000   -- conjured food/water wins over bought food, like Buffet

local function pool(tag, text, conjured)
  return "pool:" .. tag .. " " .. text .. (conjured and (" " .. CONJURED) or "")
end

local function item(best, key) return best[key] and ("item:" .. best[key].id) end

BF.RegisterSection({ display=1, kind="basic", title="Basics: food, drink, potions, stones", noun="item", order=70, useMax=true,
  classify = function(name, text, use, deals)
    if use == "" then return nil end
    local conjured = text:find("conjured item", 1, true)
    if BF.has(name, "healthstone") then return pool("stone", use) end
    if BF.has(name, "bandage") or BF.has(text, "first aid") then return pool("bandage", use) end
    if BF.has(name, "mana ") and BF.has(name, "agate", "jade", "citrine", "ruby", "emerald", "gem") then return pool("gem", use) end
    if BF.has(name, "potion", "draught") then
      if use:find("health", 1, true) and use:find("restore", 1, true) then return pool("hppot", use) end
      if use:find("mana", 1, true) and use:find("restore", 1, true) then return pool("mppot", use) end
      return nil
    end
    if text:find("remain seated", 1, true) or text:find("must remain seated", 1, true) then
      if use:find("health", 1, true) then return pool("food", use, conjured) end
      if use:find("mana", 1, true) then return pool("drink", use, conjured) end
    end
  end,
  body = function(c, best)
    local parts = {}
    local function add(cond, key) local i = item(best, key); if i then parts[#parts+1] = (cond and ("[" .. cond .. "] ") or "") .. i; return true end end
    local HEARTH = "item:6948"   -- like Buffet: no food/drink left -> Hearthstone
    if c.key == "hp" then
      if not add("combat", "stone") then add("combat", "hppot") end   -- healthstone first, then health potion
      if not add(nil, "food") then parts[#parts+1] = HEARTH end
    elseif c.key == "mp" then
      if not add("combat", "gem") then add("combat", "mppot") end     -- mana gem first, then mana potion
      if not add(nil, "drink") then parts[#parts+1] = HEARTH end
    elseif c.key == "food" or c.key == "drink" then
      if not add(nil, c.key) then parts[#parts+1] = HEARTH end
    elseif c.key == "bandage" then
      local i = item(best, "bandage"); if i then return "#showtooltip\n/use [@player] " .. i end
    else
      add(nil, c.key)
    end
    if #parts == 0 then return nil end
    return "#showtooltip\n/use " .. table.concat(parts, "; ")
  end,
  cats = {
    { key="hp",      macro="NPbaHP", old="PantryHP",      label="Health (auto)", tip="Out of combat: best food (Hearthstone if none). In combat: Healthstone, else best health potion.",  words={"pool:hp-never"} },
    { key="mp",      macro="NPbaMP", old="PantryMP",      label="Mana (auto)", tip="Out of combat: best drink (Hearthstone if none). In combat: mana gem, else best mana potion.",   words={"pool:mp-never"} },
    { key="food",    macro="NPbaFood", old="PantryFood",    label="Food only",          words={"pool:food"} },
    { key="drink",   macro="NPbaDrink", old="PantryDrink",   label="Drink only",         words={"pool:drink"} },
    { key="hppot",   macro="NPbaHPPot", old="PantryHPPot",   label="Health potion",      words={"pool:hppot"} },
    { key="mppot",   macro="NPbaMPPot", old="PantryMPPot",   label="Mana potion",        words={"pool:mppot"} },
    { key="stone",   macro="NPbaStone", old="PantryStone",   label="Healthstone",        words={"pool:stone"} },
    { key="gem",     macro="NPbaGem", old="PantryGem",     label="Mana gem",           words={"pool:gem"} },
    { key="bandage", macro="NPbaBandage", old="PantryBandage", label="Bandage",            words={"pool:bandage"} },
  }})
