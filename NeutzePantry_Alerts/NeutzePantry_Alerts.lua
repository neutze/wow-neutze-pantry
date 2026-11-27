-- Neutze's Alerts: reminders for Neutze's Pantry.
--  * Buffs: a pulsing glow on your Pantry macro when Well Fed, an elixir or a flask is missing or about to run out.
--  * Stock: a "keep at least" number per Pantry macro; below it the button gets a steady border and a coloured count.
--  * Shopping list: what you're short of, in /np and with /np shop.
--  * Vendor restock: keeps N stacks of the best drink, food and ammunition the vendor sells (hold Shift to skip).
-- Everything is per character (NeutzePantryCharDB.alerts).
local BF = NeutzePantry
local A = {}
BF.Alerts = A
local P = BF.Print

-- ---------- settings ----------
local DEFAULT_TARGET = {           -- by section kind, then by category key; 0 = no stock alert
  basic  = { hp=20, mp=20, food=20, drink=20, hppot=5, mppot=5, stone=1, gem=1, bandage=10 },
  food   = 10, elixir = 5, flask = 2, ammo = 200, scroll = 0, rune = 0, juju = 0, protection = 0, weapon = 0,
}
local function DB()
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  local d = NeutzePantryCharDB.alerts
  if not d then
    local _, class = UnitClass("player")
    d = { buff = { food=true, elixir=true, flask=false }, minutes = 2, chat = true, sound = false, resting = false,
          restock = { drink = { on=false, stacks=2 }, food = { on=false, stacks=1 }, ammo = { on=(class == "HUNTER"), stacks=3 } },
          targets = {}, last = {} }
    NeutzePantryCharDB.alerts = d
  end
  d.targets, d.last = d.targets or {}, d.last or {}
  return d
end
A.DB = DB

local function Target(sec, c)
  local t = DB().targets[c.macro]
  if t then return t end
  local def = DEFAULT_TARGET[sec.kind]
  if type(def) == "table" then return def[c.key] or 0 end
  return def or 5
end

local function HasMacro(name) local i = GetMacroIndexByName(name); return i and i > 0 end

-- ---------- action buttons that hold a Pantry macro ----------
local BARS = { "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton", "MultiBarRightButton",
               "MultiBarLeftButton", "BT4Button", "DominosActionButton" }
local function ButtonsFor()
  local map = {}                 -- macro name -> { buttons }
  for _, prefix in ipairs(BARS) do
    for i = 1, (prefix == "BT4Button" and 120 or prefix == "DominosActionButton" and 60 or 12) do
      local b = _G[prefix .. i]
      local slot = b and (b.action or (b.GetAttribute and b:GetAttribute("action")))
      if b and b:IsVisible() and type(slot) == "number" and HasAction(slot) then
        local kind, id = GetActionInfo(slot)
        if kind == "macro" and id then
          local name = GetMacroInfo(id)
          if name then map[name] = map[name] or {}; table.insert(map[name], b) end
        end
      end
    end
  end
  return map
end

local deco = {}                  -- button -> our overlay frame
local function Deco(b)
  local f = deco[b]
  if f or InCombatLockdown() then return f end   -- new overlays only out of combat
  f = CreateFrame("Frame", nil, b)
  f:SetAllPoints(b); f:SetFrameLevel(b:GetFrameLevel() + 3)
  f.border = f:CreateTexture(nil, "OVERLAY")
  f.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  f.border:SetBlendMode("ADD")
  f.border:SetPoint("CENTER"); f.border:SetSize(b:GetWidth() * 1.9, b:GetHeight() * 1.9)
  f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  f.count:SetPoint("TOPLEFT", 2, -2)
  f.pulse = f.border:CreateAnimationGroup()
  local a = f.pulse:CreateAnimation("Alpha")
  a:SetFromAlpha(1); a:SetToAlpha(0.25); a:SetDuration(0.6); a:SetSmoothing("IN_OUT")
  f.pulse:SetLooping("BOUNCE")
  deco[b] = f
  return f
end

local COLORS = { low = {1, .55, 0}, empty = {1, .15, .15}, fallback = {.6, .6, .6} }
-- state per macro name: { stock = "low"|"empty"|"fallback"|nil, n = count, buff = true|nil }
local state = {}
A.state = state

-- Missing buff: pulsing gold border. Low stock: steady coloured border plus the count in the corner.
local function Paint()
  local map, want = ButtonsFor(), {}
  for name, s in pairs(state) do
    if s.buff or s.stock then
      for _, b in ipairs(map[name] or {}) do want[b] = s end
    end
  end
  for b in pairs(want) do Deco(b) end
  for b, f in pairs(deco) do
    local s = want[b]
    if not s then f:Hide(); f.pulse:Stop()
    else
      f:Show()
      local c = s.buff and {1, .85, .2} or COLORS[s.stock]
      f.border:SetVertexColor(c[1], c[2], c[3])
      if s.buff then if not f.pulse:IsPlaying() then f.pulse:Play() end
      else f.pulse:Stop(); f.border:SetAlpha(1) end
      if s.stock then
        local k = COLORS[s.stock]
        f.count:SetText(s.stock == "fallback" and "alt" or tostring(s.n)); f.count:SetTextColor(k[1], k[2], k[3]); f.count:Show()
      else f.count:Hide() end
    end
  end
end

-- ---------- stock ----------
local STOCK_KEY = { hp="food", mp="drink" }    -- Basics auto macros run on food / drink
local warned = {}                              -- macro -> count at the last check (no warning on the first one)
local firstStock = true
local shopping = {}                            -- list of { macro, label, have, want, id }

local function ItemName(id) return id and ((GetItemInfo(id)) or ("item " .. id)) or "?" end

local function MacroItem(name)
  local i = GetMacroIndexByName(name)
  if not i or i == 0 then return end
  local _, _, body = GetMacroInfo(i)
  local id = body and tonumber(body:match("item:(%d+)[^\n]*$"))
  if id ~= 6948 then return id end      -- the Hearthstone fallback of the Basics means: nothing left
end

local function UpdateStock(scan)
  local d = DB()
  for k in pairs(state) do state[k].stock, state[k].n = nil, nil end
  wipe(shopping)
  for _, sec in ipairs(BF.sections) do
    local best = sec.kind and scan[sec.kind]
    for _, c in ipairs(best and sec.cats or {}) do
      local want = Target(sec, c)
      if want > 0 and HasMacro(c.macro) then
        local key = STOCK_KEY[c.key] or c.key
        local e = best[key]
        local have, kind
        if e then
          have = e.n or 0
          d.last[c.macro] = e.id
        else
          local used = MacroItem(c.macro)
          have = used and GetItemCount(used) or 0
          kind = (used and c.key ~= "any") and "fallback" or (have == 0 and "empty") or nil
          if c.key == "any" and used then d.last[c.macro] = used end
        end
        if not kind and have < want then kind = (have == 0) and "empty" or "low" end
        state[c.macro] = state[c.macro] or {}
        state[c.macro].stock, state[c.macro].n = kind, have
        if kind then
          shopping[#shopping + 1] = { macro=c.macro, label=c.label .. " (" .. c.macro .. ")", have=have, want=want, id=d.last[c.macro] }
        end
        -- chat warning when you use the last one / run out
        if d.chat and e and have <= 1 and not firstStock and (warned[c.macro] or 99) > have and not InCombatLockdown() then
          P((have == 1 and "last " or "out of ") .. "|cffffd100" .. ItemName(e.id) .. "|r (" .. c.macro .. ").")
        end
        warned[c.macro] = have
      end
    end
  end
  firstStock = false
  table.sort(shopping, function(x, y) return (x.have / x.want) < (y.have / y.want) end)
end


function A.ShoppingLines()
  local lines = {}
  for _, s in ipairs(shopping) do
    lines[#lines + 1] = string.format("%s: %d / %d, buy %d x %s", s.label, s.have, s.want, s.want - s.have, s.id and ItemName(s.id) or "(none seen yet)")
  end
  return lines
end

-- ---------- buffs ----------
local BUFF_SECTIONS = { food = "Well Fed", elixir = "Elixir", flask = "Flask" }
local function Auras()
  local list = {}
  for i = 1, 40 do
    local name, _, _, _, _, expires, _, _, _, spellId
    if UnitBuff then name, _, _, _, _, expires, _, _, _, spellId = UnitBuff("player", i)
    elseif C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
      local a = C_UnitAuras.GetBuffDataByIndex("player", i)
      if a then name, expires, spellId = a.name, a.expirationTime, a.spellId end
    end
    if not name then break end
    list[#list + 1] = { name = name, left = (expires and expires > 0) and (expires - GetTime()) or math.huge, id = spellId }
  end
  return list
end

-- Learns which buff each elixir/flask in your bags gives (the item's spell), so it also works after the bags run dry.
local function Learn(scan)
  NeutzePantryDB = NeutzePantryDB or {}
  local known = NeutzePantryDB.alertSpells or {}
  NeutzePantryDB.alertSpells = known
  for _, kind in ipairs({ "elixir", "flask" }) do
    known[kind] = known[kind] or {}
    for _, e in pairs(scan[kind] or {}) do
      for _, id in ipairs({ e.id, e.loId }) do
        local sname, sid = GetItemSpell(id)
        if sid then known[kind][sid] = true end
        if sname then known[kind][sname] = true end
      end
    end
  end
  return known
end

local remindAt, remindWhy = {}, {}   -- kind -> time and reason ("missing"/"expiring") of the last chat reminder
local lastScan = {}

local function UpdateBuffs()
  local d = DB()
  for k in pairs(state) do state[k].buff = nil end
  if UnitIsDeadOrGhost("player") or (IsResting() and not d.resting) or UnitOnTaxi("player") then return end
  local known = Learn(lastScan)
  local auras = Auras()
  local limit = (d.minutes or 2) * 60
  for kind, label in pairs(BUFF_SECTIONS) do
    local sec
    for _, s in ipairs(BF.sections) do if s.kind == kind then sec = s end end
    local items = lastScan[kind]
    if d.buff[kind] and sec and items and next(items) then
      local macros = {}
      for _, c in ipairs(sec.cats) do if HasMacro(c.macro) then macros[#macros + 1] = c end end
      if #macros > 0 then
        local left
        for _, a in ipairs(auras) do
          local hit = (kind == "food" and a.name == "Well Fed") or (known[kind] and (known[kind][a.id] or known[kind][a.name]))
          if hit then left = math.max(left or 0, a.left) end
        end
        if not left or left < limit then
          for _, c in ipairs(macros) do
            if items[STOCK_KEY[c.key] or c.key] or c.key == "any" then state[c.macro] = state[c.macro] or {}; state[c.macro].buff = true end
          end
          local why = left and "expiring" or "missing"
          if not InCombatLockdown() and (why ~= remindWhy[kind] or (GetTime() - (remindAt[kind] or -9999)) > 600) then
            remindAt[kind], remindWhy[kind] = GetTime(), why
            if d.chat then P("|cffffd100" .. label .. "|r " .. (left and string.format("runs out in %d:%02d", math.floor(left / 60), math.floor(left % 60)) or "is missing") .. ".") end
            if d.sound and PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959) end
          end
        else
          remindAt[kind], remindWhy[kind] = nil, nil
        end
      end
    end
  end
end

local function Refresh() UpdateBuffs(); Paint() end
A.Refresh = Refresh

table.insert(BF.onUpdate, function(scan)
  lastScan = scan
  UpdateStock(scan)
  Refresh()
end)

-- ---------- ammunition ----------
local AMMO_FOR = { [2] = 2, [18] = 2, [3] = 3 }   -- weapon subclass (bow, crossbow, gun) -> projectile subclass (arrow, bullet)
local function AmmoKind()
  local id = GetInventoryItemID("player", 18)
  if not id then return end
  local _, _, _, _, _, classID, sub = GetItemInfoInstant(id)
  return classID == 2 and AMMO_FOR[sub] or nil
end
A.AmmoKind = AmmoKind

-- ---------- vendor restock ----------
local function ReqLevel(text) return tonumber(text:match("requires level (%d+)")) or 0 end
local function Value(use) local m = 0; for s in (use:gsub(",", "")):gmatch("(%d+)") do m = math.max(m, tonumber(s)) end; return m end

-- What a vendor/bag item is: "drink", "food", "ammo" (plus its strength) or nil.
local function Kind(name, text, id)
  local _, _, _, _, _, classID, sub = GetItemInfoInstant(id)
  if classID == 6 then
    local dps = tonumber(text:match("([%d%.]+) damage per second")) or 0
    return "ammo", dps, sub
  end
  local p = text:find("use:", 1, true)
  local use = p and text:sub(p) or ""
  if use ~= "" and text:find("remain seated", 1, true) and not text:find("well fed", 1, true) then
    if use:find("mana", 1, true) then return "drink", Value(use) end
    if use:find("health", 1, true) then return "food", Value(use) end
  end
end

-- How many of this kind you carry that are at least as good as `minValue`.
local function Carried(kind, minValue, ammoSub)
  local n = 0
  for bag = 0, 4 do
    for slot = 1, (BF.GetNumSlots(bag) or 0) do
      local id = BF.GetItemID(bag, slot)
      if id then
        local name, text = BF.BagText(bag, slot)
        local k, v, sub = Kind(name, text, id)
        if k == kind and v >= minValue and (kind ~= "ammo" or sub == ammoSub) then n = n + BF.SlotCount(bag, slot) end
      end
    end
  end
  return n
end

local function FreeSlots(ammo)
  local free = 0
  for bag = 0, 4 do
    local n, t
    if C_Container and C_Container.GetContainerNumFreeSlots then n, t = C_Container.GetContainerNumFreeSlots(bag)
    else n, t = GetContainerNumFreeSlots(bag) end
    if (t or 0) == 0 or (ammo and t ~= 0) then free = free + (n or 0) end   -- quivers/ammo pouches only take ammo
  end
  return free
end

local buying = false
local function Restock()
  local d = DB()
  if buying or IsShiftKeyDown() or InCombatLockdown() then return end
  local level, ammoSub = UnitLevel("player"), AmmoKind()
  local pick = {}                                    -- kind -> best vendor item
  for i = 1, (GetMerchantNumItems() or 0) do
    local link = GetMerchantItemLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then
      local price, batch, avail
      if GetMerchantItemInfo then local _; _, _, price, batch, avail = GetMerchantItemInfo(i)
      elseif C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = C_MerchantFrame.GetItemInfo(i) or {}
        price, batch, avail = info.price, info.stackCount, info.numAvailable
      end
      local name, text = BF.MerchantText(i)
      local kind, value, sub = Kind(name, text, id)
      local r = kind and d.restock[kind]
      if r and r.on and (r.stacks or 0) > 0 and ReqLevel(text) <= level and (avail == -1 or (avail or 0) > 0)
         and (kind ~= "ammo" or sub == ammoSub) then
        local cur = pick[kind]
        if not cur or value > cur.value then pick[kind] = { i=i, id=id, value=value, price=price or 0, batch=math.max(1, batch or 1), sub=sub } end
      end
    end
  end
  local queue, total = {}, 0
  for kind, p in pairs(pick) do
    local stack = select(8, GetItemInfo(p.id)) or (kind == "ammo" and 200 or 20)
    local want = d.restock[kind].stacks * stack
    local need = want - Carried(kind, p.value, p.sub)
    if need > 0 then
      local slots = FreeSlots(kind == "ammo")
      need = math.min(need, slots * stack)
      local buys = math.ceil(need / p.batch)                    -- purchases of `batch` items each
      local afford = p.price > 0 and math.floor((GetMoney() - total) / p.price) or buys
      buys = math.min(buys, afford)
      if buys > 0 then
        total = total + buys * p.price
        queue[#queue + 1] = { p = p, buys = buys, count = buys * p.batch, stack = stack }
      elseif slots == 0 then P("bags full, no " .. kind .. " bought.")
      else P("not enough money for " .. ItemName(p.id) .. ".") end
    end
  end
  if #queue == 0 then return end
  buying = true
  local steps = {}
  for _, q in ipairs(queue) do
    local left = q.count
    while left > 0 do
      local n
      if q.p.batch > 1 then n = 1; left = left - q.p.batch      -- batched items: one batch per click
      else n = math.min(left, q.stack); left = left - n end
      steps[#steps + 1] = { i = q.p.i, n = n }
    end
    P(string.format("buying %d x %s.", q.count, ItemName(q.p.id)))
  end
  local k = 0
  local function step()
    k = k + 1
    local s = steps[k]
    if not s or not MerchantFrame or not MerchantFrame:IsShown() then
      buying = false
      if total > 0 then P("spent " .. (GetCoinTextureString and GetCoinTextureString(total) or (total .. "c")) .. ".") end
      return
    end
    BuyMerchantItem(s.i, s.n)
    C_Timer.After(0.25, step)
  end
  step()
end

-- At a vendor: say which shopping-list items it sells.
local function ShopHint()
  local ids = {}
  for _, s in ipairs(shopping) do if s.id then ids[s.id] = s end end
  for i = 1, (GetMerchantNumItems() or 0) do
    local link = GetMerchantItemLink(i)
    local id = link and tonumber(link:match("item:(%d+)"))
    local s = id and ids[id]
    if s then P(string.format("this vendor sells %s (you have %d of %d).", ItemName(id), s.have, s.want)) end
  end
end

-- ---------- low ammo warning ----------
local ammoWarnAt = 0
local function CheckAmmo()
  local d = DB()
  if not (d.restock.ammo and d.restock.ammo.on) or not AmmoKind() or InCombatLockdown() then return end
  local n = GetInventoryItemCount("player", 0) or 0
  if n > 0 and n < 200 and GetTime() - ammoWarnAt > 600 then
    ammoWarnAt = GetTime()
    P("|cffffd100ammunition low|r (" .. n .. " left).")
  end
end

-- ---------- events ----------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "UNIT_AURA", "PLAYER_REGEN_ENABLED", "PLAYER_UPDATE_RESTING", "ACTIONBAR_SLOT_CHANGED",
                     "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "MERCHANT_SHOW",
                     "MERCHANT_CLOSED", "UNIT_INVENTORY_CHANGED", "PLAYER_DEAD", "PLAYER_UNGHOST" }) do ev:RegisterEvent(e) end
local queued = false
ev:SetScript("OnEvent", function(_, e, unit)
  if (e == "UNIT_AURA" or e == "UNIT_INVENTORY_CHANGED") and unit ~= "player" then return end
  if e == "MERCHANT_SHOW" then C_Timer.After(0.3, function() ShopHint(); Restock() end); return end
  if e == "MERCHANT_CLOSED" then buying = false; return end
  if e == "UNIT_INVENTORY_CHANGED" then CheckAmmo(); return end
  if queued then return end
  queued = true
  C_Timer.After(0.5, function() queued = false; Refresh() end)
end)
C_Timer.NewTicker(10, function() Refresh(); CheckAmmo() end)   -- buffs tick down without events

-- ---------- /np shop ----------
BF.commands.shop = function()
  BF.Update()
  local lines = A.ShoppingLines()
  if #lines == 0 then P("nothing to buy, everything is above its target."); return end
  P("shopping list:")
  for _, l in ipairs(lines) do print("  " .. l) end
end

-- ---------- options section in /np ----------
local function Check(parent, anchor, x, y, text, get, set)
  local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  cb:SetSize(24, 24)
  cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
  if type(cb.text) == "table" and cb.text.SetText then cb.text:SetText("") end
  local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("LEFT", cb, "RIGHT", 2, 0); fs:SetText(text)
  cb:SetChecked(get())
  cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false); BF.Update(); Refresh() end)
  return cb
end

local function NumBox(parent, point, rel, x, y, get, set, width)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(width or 32, 20); box:SetAutoFocus(false); box:SetNumeric(true); box:SetMaxLetters(3)
  box:SetPoint(point, rel, x, y)
  box:SetText(tostring(get()))
  local function apply(b) local n = tonumber(b:GetText()); if n then set(n) end; b:SetText(tostring(get())); BF.Update(); Refresh() end
  box:SetScript("OnEnterPressed", function(b) apply(b); b:ClearFocus() end)
  box:SetScript("OnEditFocusLost", apply)
  box:SetScript("OnEscapePressed", function(b) b:SetText(tostring(get())); b:ClearFocus() end)
  return box
end

local function Note(parent, anchor, y, text, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
  fs:SetWidth(BF.CONTENT_W()); fs:SetJustifyH("LEFT"); fs:SetText(text)
  return fs
end

local SEC = { display = 90, order = 95, title = "Alerts: buffs, stock and shopping" }
SEC.custom = function(p, h)
  local d = DB()
  local height = 0
  -- buffs
  local t = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  t:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -6)
  t:SetText("Remind me (pulsing macro, chat out of combat) when a buff is missing or has less than")
  local box = NumBox(p, "LEFT", t, (BF.TextWidth({ GetFontString = function() return t end })) + 10, 0, function() return d.minutes end, function(n) d.minutes = n end, 26)
  local mins = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  mins:SetPoint("LEFT", box, "RIGHT", 4, 0); mins:SetText("minutes left:")
  local row = t
  local c1 = Check(p, row, 0, -4, "Well Fed", function() return d.buff.food end, function(v) d.buff.food = v end)
  Check(p, row, 110, -4, "Elixir", function() return d.buff.elixir end, function(v) d.buff.elixir = v end)
  Check(p, row, 220, -4, "Flask", function() return d.buff.flask end, function(v) d.buff.flask = v end)
  local c2 = Check(p, c1, 0, -2, "Chat message", function() return d.chat end, function(v) d.chat = v end)
  Check(p, c1, 110, -2, "Sound", function() return d.sound end, function(v) d.sound = v end)
  Check(p, c1, 220, -2, "Also in cities and inns", function() return d.resting end, function(v) d.resting = v end)
  height = height + 20 + 26 + 26

  -- vendor restock
  local v = Note(p, c2, -10, "At a vendor, keep this many stacks of the best one you can use (hold Shift when you open the vendor to skip):", "GameFontNormalSmall")
  local last = v
  for i, k in ipairs({ { "drink", "Drinks" }, { "food", "Food (plain)" }, { "ammo", "Ammunition" } }) do
    local r = d.restock[k[1]]
    local cb = Check(p, v, (i - 1) * 180, -4, k[2], function() return r.on end, function(x) r.on = x end)
    NumBox(p, "LEFT", cb, 110, 0, function() return r.stacks end, function(n) r.stacks = math.min(n, 10) end)
    last = cb
  end
  height = height + 24 + 26

  -- stock targets
  local s = Note(p, last, -10, "Keep at least (0 = no alert). Below it the button gets a steady border and a count: orange low, red empty, grey 'alt' = using a fallback:", "GameFontNormalSmall")
  local rows, col, prev, rowStart = 0, 0, nil, nil
  local W = 200
  local perRow = math.max(1, math.floor(BF.CONTENT_W() / W))
  for _, sec in ipairs(BF.sections) do
    for _, c in ipairs(sec.kind and sec.cats or {}) do
      if HasMacro(c.macro) then
        local lbl = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        if not rowStart or col >= perRow then
          lbl:SetPoint("TOPLEFT", rowStart or s, "BOTTOMLEFT", 0, rowStart and -6 or -8)
          rowStart, col, rows = lbl, 0, rows + 1
        else
          lbl:SetPoint("TOPLEFT", rowStart, "TOPLEFT", col * W, 0)
        end
        lbl:SetWidth(150); lbl:SetJustifyH("LEFT"); lbl:SetText(c.macro)
        NumBox(p, "LEFT", lbl, 152, 0, function() return Target(sec, c) end, function(n) d.targets[c.macro] = n end)
        col = col + 1
      end
    end
  end
  if rows == 0 then rowStart = Note(p, s, -6, "Create some Pantry macros above first."); rows = 1 end
  height = height + 24 + rows * 22

  -- shopping list
  local sh = Note(p, rowStart, -12, "Shopping list (also /np shop):", "GameFontNormalSmall")
  local lines = A.ShoppingLines()
  local body = Note(p, sh, -4, #lines > 0 and table.concat(lines, "\n") or "Nothing to buy.")
  height = height + 30 + math.max(1, #lines) * 13
  SEC.height = height
  return body
end
BF.RegisterSection(SEC)
