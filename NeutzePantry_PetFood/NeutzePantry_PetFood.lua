-- Pet Food (hunters): one Feed Pet macro that always feeds the right food for your pet's diet, and the
-- vendor keeps N stacks of it in your bags. Per character: NeutzePantryCharDB.petfood.
local BF = NeutzePantry
if select(2, UnitClass("player")) ~= "HUNTER" then return end
local P = BF.Print

-- Vendor food by diet, cheapest first: { itemID, required level }. The client has no API that tells an
-- item's diet, so these lists decide what counts as pet food (plus the food you pick yourself).
local FOOD = {
  meat   = { {117,1}, {2287,5}, {3770,15}, {3771,25}, {4599,35}, {8952,45} },
  bread  = { {4540,1}, {4541,5}, {4542,15}, {4544,25}, {4601,35}, {8950,45} },
  fish   = { {787,1}, {4592,5}, {4593,15}, {4594,25}, {21552,35}, {8957,45} },
  fruit  = { {4536,1}, {4537,5}, {4538,15}, {4539,25}, {4602,35}, {8953,45} },
  fungus = { {4604,1}, {4605,5}, {4606,15}, {4607,25}, {4608,35}, {8948,45} },
  cheese = { {2070,1}, {414,5}, {422,15}, {1707,25}, {3927,35}, {8932,45} },
}
local INFO = {}                                   -- itemID -> { diet, req }
for diet, list in pairs(FOOD) do for _, f in ipairs(list) do INFO[f[1]] = { diet = diet, req = f[2] } end end

-- GetPetFoodTypes() names (English and German clients) -> our diet keys
local DIET = { meat="meat", fish="fish", bread="bread", fruit="fruit", fungus="fungus", cheese="cheese",
               fleisch="meat", fisch="fish", brot="bread", obst="fruit", pilz="fungus", pilze="fungus", ["käse"]="cheese" }

local function DB()
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  local d = NeutzePantryCharDB.petfood
  if not d then
    d = { buy = true, stacks = 1, food = "", happy = true, diet = {} }
    NeutzePantryCharDB.petfood = d
  end
  d.diet = d.diet or {}
  return d
end

-- What the current pet eats; remembered so the vendor still buys the right food when the pet is away.
local function Diet()
  local d = DB()
  if HasPetUI and HasPetUI() and GetPetFoodTypes then
    local t = {}
    for _, name in ipairs({ GetPetFoodTypes() }) do
      local k = DIET[tostring(name):lower()]
      if k then t[k] = true end
    end
    if next(t) then d.diet = t end
  end
  return d.diet
end

local function Chosen()
  local f = DB().food or ""
  f = f:gsub("^%s+", ""):gsub("%s+$", "")
  if f == "" then return end
  return tonumber(f) or f:lower()
end
local function IsChosen(id, want)
  if type(want) == "number" then return id == want end
  local name = GetItemInfo(id)
  return name and name:lower() == want
end

local function ItemLevel(id)
  local lvl = select(4, GetItemInfo(id))
  return lvl or ((INFO[id] and INFO[id].req or 1) + 10)
end

-- Best pet food in your bags: your picked food if you have it, otherwise the diet food the pet still
-- loves (item level within 10 of the pet) with the lowest level, so leftovers get eaten first; if none
-- is that good, the highest one you have.
local function BestInBags()
  local want, diet = Chosen(), Diet()
  local petLevel = UnitLevel("pet") or 0
  if petLevel <= 0 then petLevel = UnitLevel("player") or 1 end
  local found = {}
  for bag = 0, 4 do
    for slot = 1, (BF.GetNumSlots(bag) or 0) do
      local id = BF.GetItemID(bag, slot)
      if id then
        local mine = want and IsChosen(id, want)
        local ok = mine or (not want and INFO[id] and diet[INFO[id].diet])
        if ok then
          local e = found[id] or { id = id, n = 0, lvl = ItemLevel(id) }
          e.n = e.n + BF.SlotCount(bag, slot)
          found[id] = e
        end
      end
    end
  end
  local good, top, total = nil, nil, 0
  for _, e in pairs(found) do
    total = total + e.n
    if e.lvl >= petLevel - 10 and (not good or e.lvl < good.lvl) then good = e end
    if not top or e.lvl > top.lvl then top = e end
  end
  local pick = good or top
  return pick, total
end

local SEC = { page = "Pet Food", display = 6.3, kind = "petfood", title = "Pet Food", noun = "pet food", order = 76 }
SEC.cats = {
  { key = "feed", macro = "NPpfFeed", label = "Feed Pet",
    tip = "Casts Feed Pet on the best food for your pet's diet (or the food you picked below)." },
}
SEC.body = function(c, best)
  local pick, total = BestInBags()
  if not pick then return end
  -- Alerts reads this: stock border, "last one" warning and the shopping list
  best.feed = { id = pick.id, v = 0, loId = pick.id, loV = 0, n = total }
  return "#showtooltip Feed Pet\n/cast Feed Pet\n/use item:" .. pick.id
end

-- ---------- vendor ----------
local buying = false
local function FreeSlots()
  local free = 0
  for bag = 0, 4 do
    local n, t
    if C_Container and C_Container.GetContainerNumFreeSlots then n, t = C_Container.GetContainerNumFreeSlots(bag)
    else n, t = GetContainerNumFreeSlots(bag) end
    if (t or 0) == 0 then free = free + (n or 0) end
  end
  return free
end

local function MerchantInfo(i)
  if GetMerchantItemInfo then local _, _, price, batch, avail = GetMerchantItemInfo(i); return price, batch, avail end
  local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(i) or {}
  return info.price, info.stackCount, info.numAvailable
end

-- Buys up to `stacks` stacks of the best food this vendor sells for your pet (or of your picked food).
local function Restock()
  local d = DB()
  if buying or not d.buy or (d.stacks or 0) <= 0 or IsShiftKeyDown() or InCombatLockdown() then return end
  local want, diet, level = Chosen(), Diet(), UnitLevel("player") or 1
  if not want and not next(diet) then return end           -- diet unknown until you've had a pet out once
  local pick
  for i = 1, (GetMerchantNumItems() or 0) do
    local link = GetMerchantItemLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then
      local price, batch, avail = MerchantInfo(i)
      local inf = INFO[id]
      local ok
      if want then ok = IsChosen(id, want) or (type(want) == "string" and GetMerchantItemInfo and tostring(GetMerchantItemInfo(i) or ""):lower() == want)
      else ok = inf and diet[inf.diet] and inf.req <= level end
      if ok and (avail == -1 or avail == nil or avail > 0) then
        local v = inf and inf.req or 0
        if not pick or v > pick.v then pick = { i = i, id = id, v = v, price = price or 0, batch = math.max(1, batch or 1) } end
      end
    end
  end
  if not pick then return end
  local stack = select(8, GetItemInfo(pick.id)) or 20
  local need = d.stacks * stack - GetItemCount(pick.id)
  if need <= 0 then return end
  local slots = FreeSlots()
  need = math.min(need, slots * stack)
  local buys = math.ceil(need / pick.batch)
  if pick.price > 0 then buys = math.min(buys, math.floor(GetMoney() / pick.price)) end
  local name = GetItemInfo(pick.id) or ("item " .. pick.id)
  if buys <= 0 then
    P(slots == 0 and "bags full, no pet food bought." or ("not enough money for " .. name .. ".")); return
  end
  local steps, left = {}, buys * pick.batch
  while left > 0 do
    local n
    if pick.batch > 1 then n = 1; left = left - pick.batch else n = math.min(left, stack); left = left - n end
    steps[#steps + 1] = n
  end
  P(string.format("buying %d x %s for your pet.", buys * pick.batch, name))
  buying = true
  local k = 0
  local function step()
    k = k + 1
    if not steps[k] or not MerchantFrame or not MerchantFrame:IsShown() then buying = false; return end
    BuyMerchantItem(pick.i, steps[k])
    C_Timer.After(0.25, step)
  end
  step()
end

-- ---------- happiness ----------
local lastWarn, lastHappy = 0, 3
local function CheckHappy()
  local d = DB()
  if not d.happy or not (HasPetUI and HasPetUI()) or not GetPetHappiness or UnitIsDead("pet") then return end
  local h = GetPetHappiness()
  if not h then return end
  if h < 3 and not InCombatLockdown() and (h < lastHappy or GetTime() - lastWarn > 300) then
    lastWarn = GetTime()
    local pick = BestInBags()
    P("|cffffd100your pet is " .. (h == 1 and "unhappy" or "only content") .. "|r: feed it"
      .. (pick and (" (NPpfFeed: " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. ")") or ", but you have no pet food") .. ".")
  end
  lastHappy = h
end

local ev = CreateFrame("Frame")
for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "UNIT_PET", "UNIT_HAPPINESS", "PET_UI_UPDATE", "PLAYER_REGEN_ENABLED" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, unit)
  if e == "MERCHANT_SHOW" then C_Timer.After(0.4, Restock); return end   -- after Alerts' own restock
  if e == "MERCHANT_CLOSED" then buying = false; return end
  if e == "UNIT_PET" and unit ~= "player" then return end
  if e == "UNIT_PET" or e == "PET_UI_UPDATE" then Diet(); C_Timer.After(1, BF.Update) end
  C_Timer.After(0.5, CheckHappy)
end)
C_Timer.NewTicker(60, CheckHappy)

-- ---------- settings (below the Feed Pet button) ----------
local function Check(parent, anchor, y, text, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(24, 24); cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
  if type(cb.text) == "table" and cb.text.SetText then cb.text:SetText("") end
  local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", cb, "RIGHT", 2, 0); fs:SetText(text)
  cb:SetChecked(get())
  cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  return cb, fs
end

local function DietText()
  local t = {}
  for k in pairs(Diet()) do t[#t + 1] = k end
  table.sort(t)
  return #t > 0 and ("Your pet eats: " .. table.concat(t, ", ") .. ".") or "Call your pet once so I learn what it eats."
end

SEC.extraUI = function(p, anchor)
  local d = DB()
  local diet = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  diet:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  diet:SetText(DietText())
  local buy, fs = Check(p, diet, -6, "At a vendor, keep this many stacks of it (hold Shift when you open the vendor to skip):",
    function() return d.buy end, function(v) d.buy = v end)
  local box = CreateFrame("EditBox", nil, p, "InputBoxTemplate")
  box:SetSize(28, 20); box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(2)
  box:SetPoint("LEFT", fs, "RIGHT", 10, 0)
  box:SetText(tostring(d.stacks))
  local function apply(b) local n = tonumber(b:GetText()); if n then d.stacks = math.min(n, 10) end; b:SetText(tostring(d.stacks)) end
  box:SetScript("OnEnterPressed", function(b) apply(b); b:ClearFocus() end)
  box:SetScript("OnEditFocusLost", apply)
  local happy = Check(p, buy, -2, "Tell me in chat when my pet is not happy",
    function() return d.happy end, function(v) d.happy = v end)
  local status = BF.FieldRow(p, happy, {
    label = "Always use this food (name or item ID; empty = the best food for your pet's diet):",
    get = function() return d.food end,
    set = function(text)
      d.food = text or ""
      BF.Update()
      local pick = BestInBags()
      if d.food:match("%S") then
        return pick and ("Using " .. ((GetItemInfo(pick.id)) or d.food) .. ".") or ("None of \"" .. d.food .. "\" in your bags yet; the vendor buys it if it sells it.")
      end
      return pick and ("Using " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. ".") or "No pet food in your bags yet."
    end,
    status = function()
      local pick, total = BestInBags()
      return pick and ("Using " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. ", " .. total .. " in your bags.") or "No pet food in your bags yet."
    end,
  })
  BF.AddHeight(20 + 26 + 26 + 70)
  return status
end

BF.RegisterSection(SEC)

BF.commands.petfood = function()
  local pick, total = BestInBags()
  P(DietText() .. " " .. (pick and ("NPpfFeed uses " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. " (" .. total .. " in bags).") or "No pet food in your bags."))
end
