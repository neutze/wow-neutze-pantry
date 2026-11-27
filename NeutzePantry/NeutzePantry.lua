-- Neutze's Pantry core. Modules (NeutzePantry_Basics, _WellFed, _Elixirs, _Flasks, _Potions, _Protection, _Scrolls, _Juju,
-- _Runes, _WeaponBuffs, _Ammo, _Dynamite, _Alchemy) register sections. Neutze's Companion, Stable and Macros need this core too:
-- they add their own pages under Neutze's Pantry in the options (BF.AddSubPage).
-- Each section is a group of macro buttons; each macro always uses the strongest matching item in your bags.
NeutzePantry = NeutzePantry or {}
local BF = NeutzePantry
BF.sections = {}
BF.ICON = 134400        -- the empty "?" macro icon: with #showtooltip the button shows the item itself
BF.SP_WORDS   = {"spell damage", "damage done by", "magical spells", "spell power"}
BF.HEAL_WORDS = {"healing done", "healing by", "healing spells"}

function BF.has(s, ...) for _, w in ipairs({...}) do if s:find(w, 1, true) then return true end end end

-- ---------- class / spec: one stat priority per character, shared by all modules ----------
local DEFAULTS = {
  WARRIOR = {"str","ap","breath","sta","agi","armor"},  ROGUE  = {"agi","ap","breath","str","sta"},
  HUNTER  = {"agi","ap","breath","int","sta"},  MAGE   = {"sp","breath","int","spi","sta"},
  WARLOCK = {"sp","breath","sta","int","spi"},
}
BF.ALL = {"str","agi","sta","int","spi","ap","sp","heal","hit","crit","mp5","hp5","armor","breath","speed"}
BF.SPECS = {
  WARRIOR = { {"Arms / Fury", DEFAULTS.WARRIOR}, {"Protection", {"sta","armor","str","agi"}} },
  ROGUE   = { {"All specs", DEFAULTS.ROGUE} },
  HUNTER  = { {"All specs", DEFAULTS.HUNTER} },
  PALADIN = { {"Holy", {"heal","int","mp5","spi","sta"}}, {"Protection", {"sta","armor","str","sp"}}, {"Retribution", {"str","ap","breath","agi","sta","int"}} },
  SHAMAN  = { {"Elemental", {"sp","breath","int","mp5","sta"}}, {"Enhancement", {"str","agi","ap","breath","sta","int"}}, {"Restoration", {"heal","int","mp5","sta"}} },
  DRUID   = { {"Balance", {"sp","breath","int","mp5","spi","sta"}}, {"Feral (Cat)", {"agi","str","ap","breath","sta"}}, {"Feral (Bear)", {"sta","agi","armor","str"}}, {"Restoration", {"heal","int","mp5","spi","sta"}} },
  PRIEST  = { {"Holy / Discipline", {"heal","int","spi","mp5","sta"}}, {"Shadow", {"sp","breath","int","sta","spi"}} },
  MAGE    = { {"All specs", DEFAULTS.MAGE} },
  WARLOCK = { {"All specs", DEFAULTS.WARLOCK} },
}
function BF.Specs() local _, class = UnitClass("player"); return BF.SPECS[class] or {} end
local function Fill(first)
  local list, seen = {}, {}
  for _, k in ipairs(first or {}) do if not seen[k] then list[#list+1] = k; seen[k] = true end end
  for _, k in ipairs(BF.ALL) do if not seen[k] then list[#list+1] = k end end
  return list
end
-- Stat priority for this character (spec preset first, every other stat after).
function BF.Priority()
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  local db = NeutzePantryCharDB
  if not db.priority then local s = BF.Specs()[1]; db.priority = Fill(s and s[2]); db.spec = s and s[1] end
  local seen = {}
  for _, k in ipairs(db.priority) do seen[k] = true end
  for _, k in ipairs(BF.ALL) do if not seen[k] then db.priority[#db.priority+1] = k end end   -- stats added later
  return db.priority
end
function BF.ApplySpec(i)
  local spec = BF.Specs()[i]
  if not spec then return end
  NeutzePantryCharDB = NeutzePantryCharDB or {}
  NeutzePantryCharDB.priority, NeutzePantryCharDB.spec = Fill(spec[2]), spec[1]
end
function BF.SpecName()
  local db = NeutzePantryCharDB
  if db and db.spec then return db.spec end
  if db and db.priority then return "Custom" end   -- saved before specs existed
  BF.Priority()
  return NeutzePantryCharDB.spec or "-"
end
-- Buttons whose key is not a plain stat borrow the rank of a related stat.
local ALIAS = { fire="sp", frost="sp", shadow="sp", hp="sta", regen="hp5", mana="mp5" }
function BF.Rank(key)
  if key == "any" then return -1 end
  if key == "fish" then return 9999 end
  local extra = (key == "fire" or key == "frost" or key == "shadow") and 0.5 or 0   -- school power after plain spell power
  key = ALIAS[key] or key
  for i, k in ipairs(BF.Priority()) do if k == key then return i + extra end end
  return 500                                    -- not a stat (rage, free action, ...): after the stats
end

-- sec = { kind, title, noun, order, cats, classify(name, text, use, deals) -> part or nil, useMax }
function BF.RegisterSection(sec)
  table.insert(BF.sections, sec)
  table.sort(BF.sections, function(a, b) return a.order < b.order end)
end

local tip = CreateFrame("GameTooltip", "NeutzePantryScanTip", nil, "GameTooltipTemplate")
tip:SetOwner(WorldFrame, "ANCHOR_NONE")

local GetNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local function GetItemID(bag, slot)
  if C_Container and C_Container.GetContainerItemID then return C_Container.GetContainerItemID(bag, slot) end
  if C_Container and C_Container.GetContainerItemInfo then local i = C_Container.GetContainerItemInfo(bag, slot); return i and i.itemID end
  return GetContainerItemID and GetContainerItemID(bag, slot)
end

local function ReadTip()
  local first = _G["NeutzePantryScanTipTextLeft1"]
  local name = first and first:GetText() or ""
  local t = {}
  for i = 2, tip:NumLines() do
    local fs = _G["NeutzePantryScanTipTextLeft"..i]
    local s = fs and fs:GetText()
    if s then t[#t+1] = s:lower() end
  end
  return name:lower(), table.concat(t, " ")
end
local function TooltipText(bag, slot)
  tip:ClearLines(); tip:SetOwner(WorldFrame, "ANCHOR_NONE"); tip:SetBagItem(bag, slot)
  return ReadTip()
end
-- Shared helpers for modules (Alerts): tooltip text of a bag slot or a vendor item, lowercased.
BF.BagText = TooltipText
function BF.MerchantText(i)
  tip:ClearLines(); tip:SetOwner(WorldFrame, "ANCHOR_NONE"); tip:SetMerchantItem(i)
  return ReadTip()
end
BF.GetItemID, BF.GetNumSlots = GetItemID, GetNumSlots
function BF.SlotCount(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local i = C_Container.GetContainerItemInfo(bag, slot); return i and i.stackCount or 0
  end
  local _, n = GetContainerItemInfo(bag, slot); return n or 0
end
function BF.Print(msg) print("|cff66ccffNeutze's Pantry|r: " .. msg) end

local function Ignored(id)
  return BuffetDB and BuffetDB.ignoredItems and BuffetDB.ignoredItems[id]
end

local function Numbers(part)
  local first, maxv = nil, 0
  for s in (part:gsub(",", "")):gmatch("(%d+)") do
    local n = tonumber(s); first = first or n; if n > maxv then maxv = n end
  end
  return first or 0, maxv
end

local function Match(sec, part, name, id, best, count)
  local first, maxv = Numbers(part)
  local num = sec.useMax and maxv or first
  for _, c in ipairs(sec.cats) do
    for _, w in ipairs(c.words) do
      if (c.byName and name:find(w, 1, true)) or part:find(w, 1, true) then
        local e = best[c.key]
        if not e then best[c.key] = { id=id, v=num, loId=id, loV=num, n=count }
        else
          e.n = e.n + count                -- n: how many items of this category are in your bags
          if num > e.v then e.id, e.v = id, num end
          if num < e.loV then e.loId, e.loV = id, num end
        end
        if not sec.multi then return end   -- usually: first (most specific) category only
        break                               -- multi (Well Fed): e.g. Stamina AND Spirit food counts for both
      end
    end
  end
end

function BF.Scan()
  local best = {}
  for _, sec in ipairs(BF.sections) do if sec.kind then best[sec.kind] = {} end end
  for bag = 0, 4 do
    for slot = 1, (GetNumSlots(bag) or 0) do
      local id = GetItemID(bag, slot)
      if id and not Ignored(id) then
        local name, text = TooltipText(bag, slot)
        local p = text:find("use:", 1, true)
        local use = p and text:sub(p) or ""
        local deals = BF.has(use, "inflict", "damage to", "deals ")
        for _, sec in ipairs(BF.sections) do
          local part = sec.classify and sec.classify(name, text, use, deals)
          if part then Match(sec, part, name, id, best[sec.kind], BF.SlotCount(bag, slot)); break end
        end
      end
    end
  end
  return best
end

local function BodyFor(sec, c, best)
  if sec.body then
    local body = sec.body(c, best)
    if body then return body end
    return "#showtooltip\n/run print(\"|cff66ccffNeutze's Pantry|r: nothing for " .. c.label .. " in your bags\")"
  end
  local b = best[c.key]
  return b and ("#showtooltip\n/use item:" .. b.id)
           or ("#showtooltip\n/run print(\"|cff66ccffNeutze's Pantry|r: no " .. c.label .. " " .. sec.noun .. " in your bags\")")
end

-- Macro names are NP + module code + item (NPwfAP = Well Fed, Attack Power), so they sort by module.
-- Cats carry their pre-0.0.2 name in c.old (PantryHP, AutoAP, ...): a Pantry macro still under that name is
-- renamed in place (it stays on your bars); if both names exist, the old one is deleted.
-- Renames macro `old` to `new` when `old` exists on the right tab (General, or this character's tab when
-- perCharacter) and isOurs(body) says we wrote it. If `new` already exists, the old copy is deleted instead.
function BF.RenameMacro(old, new, isOurs, perCharacter)
  local oi = GetMacroIndexByName(old)
  if not oi or oi == 0 then return end
  local isChar = oi > (MAX_ACCOUNT_MACROS or 120)
  if isChar ~= (perCharacter and true or false) then return end
  local _, icon, body = GetMacroInfo(oi)
  if not body or not isOurs(body) then return end
  local ni = GetMacroIndexByName(new)
  if ni and ni > 0 then DeleteMacro(oi) else EditMacro(oi, new, icon, body) end
end
local function IsPantryBody(body) return body:find("item:%d") or body:find("Neutze's Pantry", 1, true) end
local function MigrateNames()
  local alerts = NeutzePantryCharDB and NeutzePantryCharDB.alerts
  for _, sec in ipairs(BF.sections) do
    for _, c in ipairs(sec.cats or {}) do
      if c.old then
        BF.RenameMacro(c.old, c.macro, IsPantryBody)
        if alerts then                                                  -- Alerts settings are keyed by macro name
          for _, t in ipairs({ alerts.targets or {}, alerts.last or {} }) do
            if t[c.old] ~= nil and t[c.macro] == nil then t[c.macro], t[c.old] = t[c.old], nil end
          end
        end
      end
    end
  end
end
-- Older names from before the Pantry modules (the Autopilot era) that have no NP equivalent to rename to.
-- They are deleted, but only from the General tab and only if the macro is nothing but #showtooltip,
-- /use and /run print lines, so a hand-written macro that happens to share a name is left alone.
BF.LEGACY = { "FoodAuto", "DrinkAuto", "HealthAuto", "ManaAuto", "BandageAuto", "BuffAuto",
              "Food+", "Drink+", "HP+", "MP+", "Bandage+", "Buff+" }
local function IsItemOnlyBody(body)
  local any = false
  for line in body:gmatch("[^\n]+") do
    line = line:gsub("^%s+", "")
    if line ~= "" then
      if not (line:find("^#show") or line:find("^/use ") or line:find("^/run print%(")) then return false end
      any = true
    end
  end
  return any
end
local function CleanLegacy()
  for _, name in ipairs(BF.LEGACY) do
    local i = GetMacroIndexByName(name)
    if i and i > 0 and i <= (MAX_ACCOUNT_MACROS or 120) then
      local _, _, body = GetMacroInfo(i)
      if body and IsItemOnlyBody(body) then DeleteMacro(i) end
    end
  end
end
local migrated = false
local function MigrateAll()
  MigrateNames()                    -- cheap, and catches macros made on another character later
  if not migrated then migrated = true; CleanLegacy() end
end
BF.MigrateNames = MigrateAll

-- Like Buffet: only macros you created (from the panel) are kept up to date.
function BF.Update()
  if InCombatLockdown() then return end
  MigrateAll()
  local best = BF.Scan()
  for _, sec in ipairs(BF.sections) do
    for _, c in ipairs(sec.cats or {}) do
      local idx = GetMacroIndexByName(c.macro)
      if idx and idx > 0 then
        local body = BodyFor(sec, c, best[sec.kind])
        local _, _, oldBody = GetMacroInfo(idx)
        if oldBody ~= body then EditMacro(idx, c.macro, BF.ICON, body) end
      end
    end
  end
  for _, f in ipairs(BF.onUpdate) do f(best) end
end
-- Modules can hook in: BF.onUpdate (called with the scan after macros are updated) and BF.commands (/np <word>).
BF.onUpdate, BF.commands = BF.onUpdate or {}, BF.commands or {}
BF.BodyFor = function(sec, c, best) return BodyFor(sec, c, best) end

local pending = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")   -- weapon buffs and ammo depend on what you wield
ev:SetScript("OnEvent", function(_, e)
  if pending then return end
  pending = true
  C_Timer.After(e == "PLAYER_ENTERING_WORLD" and 4 or 2, function() pending = false; BF.Update() end)
end)

-- Options panel (Options > AddOns > NeutzePantry): one button per macro, like Buffet.
local panel = CreateFrame("Frame")
panel.name = "Neutze's Pantry"
local category

local function MakeOrPickup(c)
  if InCombatLockdown() then return end
  local id = GetMacroIndexByName(c.macro)
  if not id or id == 0 then
    if GetNumMacros() >= (MAX_ACCOUNT_MACROS or 120) then print("|cff66ccffNeutze's Pantry|r: your General macro tab is full."); return end
    id = CreateMacro(c.macro, BF.ICON, "#showtooltip", nil)
    BF.Update()
  end
  PickupMacro(id)
end

-- Buttons size themselves to their label; rows wrap to the panel width.
local CONTENT_W = 600
local function TextWidth(b)
  local fs = b.GetFontString and b:GetFontString()
  local w = fs and fs.GetStringWidth and fs:GetStringWidth()
  return (type(w) == "number" and w > 0) and w or 90
end
BF.TextWidth = TextWidth
BF.CONTENT_W = function() return CONTENT_W end

-- Lays out a list of buttons in rows. Returns the last row's first button and the number of rows.
function BF.LayoutButtons(buttons, anchor, yOff)
  local w = 90
  for _, b in ipairs(buttons) do w = math.max(w, TextWidth(b) + 26) end
  local perRow = math.max(1, math.floor((CONTENT_W + 3) / (w + 3)))
  local rowStart, last
  for i, b in ipairs(buttons) do
    b:SetSize(w, 22)
    b:ClearAllPoints()
    if i == 1 then b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff); rowStart = b
    elseif (i - 1) % perRow == 0 then b:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -3); rowStart = b
    else b:SetPoint("LEFT", last, "RIGHT", 3, 0) end
    last = b
  end
  return rowStart, math.ceil(#buttons / perRow)
end

local content, usedHeight = nil, 0

local function Section(sec, anchor, yOff)
  local h = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  h:SetText(sec.heading or "")              -- the page title already names the module
  h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff)
  local buttons, cats = {}, {}
  for i, c in ipairs(sec.cats) do cats[i] = c end
  if sec.sortBySpec then                       -- best for your class/spec first
    local pos = {}
    for i, c in ipairs(cats) do pos[c] = i end
    table.sort(cats, function(x, y)
      local rx, ry = BF.Rank(x.key), BF.Rank(y.key)
      if rx ~= ry then return rx < ry end
      return pos[x] < pos[y]
    end)
  end
  for _, c in ipairs(cats) do
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetText(c.label)
    b:SetScript("OnClick", function() MakeOrPickup(c) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine(c.macro)
      if c.tip then GameTooltip:AddLine(c.tip, .9, .9, .9, true) end
      local all = BF.Scan()[sec.kind]
      local pick = all[c.key]
      if sec.body and not pick then
        local body = sec.body(c, all)
        local id = body and tonumber(body:match("item:(%d+)[^\n]*$") or body:match("item:(%d+)"))
        pick = id and { id = id, v = 0 }
      end
      GameTooltip:AddLine(pick and ("Uses: " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. (pick.v > 0 and (" (" .. pick.v .. ")") or "")) or ("No " .. c.label .. " " .. sec.noun .. " in your bags"), 1, 1, 1, true)
      local id = GetMacroIndexByName(c.macro)
      GameTooltip:AddLine((id and id > 0) and "Click to pick it up and drop it on a bar." or "Click to create it in your General macros and pick it up.", .7, .7, .7, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    buttons[#buttons + 1] = b
  end
  local last, rows = BF.LayoutButtons(buttons, h, -4)
  usedHeight = usedHeight + 18 + rows * 25 + 12
  return last
end

-- A labelled text field with a status line and an optional button; used by Companion and Stable.
function BF.FieldRow(parent, anchor, opts)
  local label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -6)
  label:SetText(opts.label)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetSize(240, 22)
  box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 6, -4)
  box:SetAutoFocus(false)
  local status = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -4)
  status:SetWidth(CONTENT_W); status:SetJustifyH("LEFT")
  local function apply(text) status:SetText(opts.set(text) or "") end
  box:SetText(opts.get() or "")
  box:SetScript("OnEnterPressed", function(b) apply(b:GetText()); b:ClearFocus() end)
  box:SetScript("OnEditFocusLost", function(b) apply(b:GetText()) end)
  box:SetScript("OnEscapePressed", function(b) b:SetText(opts.get() or ""); b:ClearFocus() end)
  if opts.button then
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(140, 22)
    btn:SetPoint("LEFT", box, "RIGHT", 8, 0)
    btn:SetText(opts.button)
    btn:SetScript("OnClick", function() local v = opts.current(); if v then box:SetText(v); apply(v) else status:SetText(opts.noCurrent or "") end end)
  end
  status:SetText(opts.status and opts.status() or "")
  return status
end

function BF.AddHeight(px) usedHeight = usedHeight + px end

local specDD

-- Role shown next to the spec (derived from it, so there is only one thing to pick).
function BF.Role()
  local n = BF.SpecName()
  if n:find("Protection") or n:find("Bear") then return "Tank" end
  if n:find("Holy") or n:find("Restoration") or n:find("Discipline") then return "Healer" end
  return "Damage"
end

-- Each options page gets its own scroll frame; content/usedHeight are the page being built right now.
local function NewCanvas(frame)
  if not frame.scroll then
    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 0, -4)
    frame.scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  end
  if frame.content then frame.content:Hide() end
  content = CreateFrame("Frame", nil, frame.scroll)
  frame.content = content
  local sw = frame.scroll.GetWidth and frame.scroll:GetWidth()
  if type(sw) == "number" and sw > 200 then CONTENT_W = math.floor(sw) - 40 end
  local fw = frame.GetWidth and frame:GetWidth()
  if type(fw) == "number" and fw > 200 then frame.builtW = fw end
  content:SetSize(CONTENT_W + 32, 1)
  frame.scroll:SetScrollChild(content)
  usedHeight = 70
end

local function Header(titleText, subText)
  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -12)
  title:SetText(titleText)
  local sub = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetWidth(CONTENT_W); sub:SetJustifyH("LEFT")
  sub:SetText(subText)
  return sub
end

-- Class / spec dropdown (main page); picking a spec re-sorts every module page.
local function SpecRow(anchor)
  local sl = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  sl:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
  local _, cname = UnitClass("player")
  sl:SetText((UnitClass("player") or cname or "Class") .. " spec:")
  local role = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local function pick(i) BF.ApplySpec(i); BF.Update(); BF.Rebuild() end
  if UIDropDownMenu_Initialize then
    if not specDD then
      specDD = CreateFrame("Frame", "NeutzePantrySpecDropDown", content, "UIDropDownMenuTemplate")
      UIDropDownMenu_SetWidth(specDD, 160)
      UIDropDownMenu_Initialize(specDD, function()
        for i, sp in ipairs(BF.Specs()) do
          local info = UIDropDownMenu_CreateInfo()
          info.text, info.checked = sp[1], (sp[1] == BF.SpecName())
          info.func = function() CloseDropDownMenus(); pick(i) end
          UIDropDownMenu_AddButton(info)
        end
      end)
    end
    specDD:SetParent(content); specDD:Show()
    specDD:ClearAllPoints(); specDD:SetPoint("LEFT", sl, "RIGHT", -8, -2)
    UIDropDownMenu_SetText(specDD, BF.SpecName())
    role:SetPoint("LEFT", specDD, "RIGHT", 120, 2)
  else
    local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    b:SetSize(170, 22); b:SetPoint("LEFT", sl, "RIGHT", 8, 0); b:SetText(BF.SpecName())
    b:SetScript("OnClick", function()
      local specs, cur = BF.Specs(), 0
      for i, sp in ipairs(specs) do if sp[1] == BF.SpecName() then cur = i end end
      pick(cur % math.max(1, #specs) + 1)
    end)
    role:SetPoint("LEFT", b, "RIGHT", 16, 0)
  end
  role:SetText("Role: |cffffffff" .. BF.Role() .. "|r")
  local note = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  note:SetPoint("TOPLEFT", sl, "BOTTOMLEFT", 0, -12)
  note:SetWidth(CONTENT_W); note:SetJustifyH("LEFT")
  note:SetText("Food, elixir, flask, potion, scroll and juju buttons are sorted best-first for this spec, \"Best for my spec\" eats the right food, and Weapon Buffs picks wizard oil for casters.")
  usedHeight = usedHeight + 60
  return note
end

local function SortedSections()
  local list = {}
  for _, sec in ipairs(BF.sections) do list[#list + 1] = sec end
  table.sort(list, function(a, b) return (a.display or a.order) < (b.display or b.order) end)
  return list
end
local function PageName(sec) return sec.page or sec.title end

-- First page: spec and role, and which module pages you have.
local function BuildMain(frame)
  NewCanvas(frame)
  local sub = Header("Neutze's Pantry", "Pick your spec here. Every module you have enabled has its own page below Neutze's Pantry on the left: click a button there to create its macro (General tab) and drop it on a bar. Turn modules on or off in the AddOns list.")
  local anchor = SpecRow(sub)
  local names = {}
  for _, sec in ipairs(SortedSections()) do names[#names + 1] = PageName(sec) end
  local l = content:CreateFontString(nil, "OVERLAY", #names > 0 and "GameFontHighlightSmall" or "GameFontRed")
  l:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
  l:SetWidth(CONTENT_W); l:SetJustifyH("LEFT")
  l:SetText(#names > 0 and ("Your modules: " .. table.concat(names, ", ") .. ".") or "No Neutze's Pantry modules are enabled.")
  usedHeight = usedHeight + 40
  content:SetHeight(usedHeight + 40)
end

-- One page per module (section).
local function BuildSection(frame, sec)
  NewCanvas(frame)
  local text = sec.custom and "" or "Click a button to create its macro (General tab) and pick it up. Each macro always uses the best matching item in your bags; hover a button to see which."
  if sec.sortBySpec then text = text .. " Sorted best-first for |cffffffff" .. BF.SpecName() .. "|r (change it on the Neutze's Pantry page)." end
  local sub = Header(PageName(sec), text)
  local anchor
  if sec.custom then
    anchor = sec.custom(content, sub) or sub
    usedHeight = usedHeight + (sec.height or 70) + 12
  else
    anchor = Section(sec, sub, -14)
    if sec.extraUI then sec.extraUI(content, anchor) end
  end
  content:SetHeight(usedHeight + 40)
end

-- Pages build the first time they are shown. The options window can show a page before it has its final
-- size (the scroll area is then 0 px and stays blank), and a Lua error mid-build used to leave a page empty
-- for good. So: build one frame later, catch errors (report once, try again next time the page is shown),
-- and rebuild when the page gets its real width.
local built = {}            -- frame -> rebuild function, for pages that have been shown
local function SafeBuild(frame, build)
  local ok, err = pcall(build, frame)
  if ok then
    frame.built = true
    built[frame] = function() SafeBuild(frame, build) end
    if frame.scroll and frame.scroll.UpdateScrollChildRect then frame.scroll:UpdateScrollChildRect() end
  else
    frame.built = false
    if not frame.reported then
      frame.reported = true
      print("|cff66ccffNeutze's Pantry|r: the page \"" .. tostring(frame.name) .. "\" could not be built: " .. tostring(err))
    end
  end
end
local function Lazy(frame, build)
  frame:SetScript("OnShow", function(self)
    if self.built or self.pending then return end
    self.pending = true
    C_Timer.After(0, function() self.pending = false; SafeBuild(self, build) end)
  end)
  frame:SetScript("OnSizeChanged", function(self, w)
    if self.built and type(w) == "number" and w > 200 and math.abs(w - (self.builtW or 0)) > 20 then
      self.builtW = w
      SafeBuild(self, build)
    end
  end)
end
Lazy(panel, BuildMain)
BF.Rebuild = function() for _, rebuild in pairs(built) do rebuild() end end

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

SLASH_NEUTZEPANTRY1 = "/pantry"
SLASH_NEUTZEPANTRY2 = "/np"
SLASH_NEUTZEPANTRY3 = "/neutze"
SlashCmdList.NEUTZEPANTRY = function(msg)
  local word, rest = (msg or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
  if word ~= "" and BF.commands[word] then BF.commands[word](rest); return end
  if msg and msg:lower():find("list") then
    BF.Update()
    local best = BF.Scan()
    for _, sec in ipairs(BF.sections) do
      if sec.cats then print("|cff66ccffNeutze's Pantry|r — " .. sec.title .. ":") end
      for _, c in ipairs(sec.cats or {}) do
        local b = best[sec.kind][c.key]
        if b then print(string.format("  %s: %s (%d)", c.macro, (GetItemInfo(b.id)) or ("item "..b.id), b.v)) end
      end
    end
    return
  end
  BF.Open()
end

function BF.Open()
  if category and Settings and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel); InterfaceOptionsFrame_OpenToCategory(panel) end
end

-- Sub-pages under "Neutze's Pantry": one per module, then Companion / Stable / Macros (BF.AddSubPage).
-- They are registered together at login, so the list is in module order whatever order the add-ons load in.
local queued, registered = {}, false
local function Register(q)
  local page = q.page
  page.parent = panel.name                       -- old options window: nest under Neutze's Pantry
  if category and Settings and Settings.RegisterCanvasLayoutSubcategory then
    q.sub = Settings.RegisterCanvasLayoutSubcategory(category, page, page.name)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(page)
  end
end
local function Opener(q)
  return function()
    if q.sub and Settings and Settings.OpenToCategory then Settings.OpenToCategory(q.sub:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(q.page); InterfaceOptionsFrame_OpenToCategory(q.page) end
  end
end
-- Returns a function that opens the page.
function BF.AddSubPage(page, order)
  local q = { page = page, order = order or 1000 + #queued }
  if registered then Register(q) else queued[#queued + 1] = q end
  return Opener(q)
end
local function RegisterAll()
  if registered then return end
  for _, sec in ipairs(SortedSections()) do
    local f = CreateFrame("Frame")
    f.name = PageName(sec)
    Lazy(f, function(self) BuildSection(self, sec) end)
    queued[#queued + 1] = { page = f, order = sec.display or sec.order }
  end
  table.sort(queued, function(x, y) return x.order < y.order end)
  for _, q in ipairs(queued) do Register(q) end
  registered = true
end
local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", RegisterAll)
