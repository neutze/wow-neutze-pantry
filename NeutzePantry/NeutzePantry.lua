-- Neutze's Pantry core. Modules (NeutzePantry_WellFed, _Elixirs, _Flasks, _Potions, _Dynamite, _Alchemy, _Basics) register sections.
-- Each section is a group of macro buttons; each macro always uses the strongest matching item in your bags.
NeutzePantry = NeutzePantry or {}
local BF = NeutzePantry
BF.sections = {}
BF.ICON = 134400        -- the empty "?" macro icon: with #showtooltip the button shows the item itself
BF.SP_WORDS   = {"spell damage", "damage done by", "magical spells", "spell power"}
BF.HEAL_WORDS = {"healing done", "healing by", "healing spells"}

function BF.has(s, ...) for _, w in ipairs({...}) do if s:find(w, 1, true) then return true end end end

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

local function TooltipText(bag, slot)
  tip:ClearLines(); tip:SetOwner(WorldFrame, "ANCHOR_NONE"); tip:SetBagItem(bag, slot)
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

local function Match(sec, part, name, id, best)
  local first, maxv = Numbers(part)
  local num = sec.useMax and maxv or first
  for _, c in ipairs(sec.cats) do
    for _, w in ipairs(c.words) do
      if (c.byName and name:find(w, 1, true)) or part:find(w, 1, true) then
        if not best[c.key] or num > best[c.key].v then best[c.key] = { id=id, v=num } end
        return   -- an item counts for its first (most specific) category only
      end
    end
  end
end

function BF.Scan()
  local best = {}
  for _, sec in ipairs(BF.sections) do best[sec.kind] = {} end
  for bag = 0, 4 do
    for slot = 1, (GetNumSlots(bag) or 0) do
      local id = GetItemID(bag, slot)
      if id and not Ignored(id) then
        local name, text = TooltipText(bag, slot)
        local p = text:find("use:", 1, true)
        local use = p and text:sub(p) or ""
        local deals = BF.has(use, "inflict", "damage to", "deals ")
        for _, sec in ipairs(BF.sections) do
          local part = sec.classify(name, text, use, deals)
          if part then Match(sec, part, name, id, best[sec.kind]); break end
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

-- Like Buffet: only macros you created (from the panel) are kept up to date.
function BF.Update()
  if InCombatLockdown() then return end
  local best = BF.Scan()
  for _, sec in ipairs(BF.sections) do
    for _, c in ipairs(sec.cats) do
      local idx = GetMacroIndexByName(c.macro)
      if idx and idx > 0 then
        local body = BodyFor(sec, c, best[sec.kind])
        local _, _, oldBody = GetMacroInfo(idx)
        if oldBody ~= body then EditMacro(idx, c.macro, BF.ICON, body) end
      end
    end
  end
end

local pending = false
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
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

local function Section(sec, anchor, yOff)
  local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  h:SetText(sec.title)
  h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff)
  local perRow, w, last, rowStart = 5, 118
  for i, c in ipairs(sec.cats) do
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetText(c.label)
    if i == 1 then b:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4); rowStart = b
    elseif (i - 1) % perRow == 0 then b:SetPoint("TOPLEFT", rowStart, "BOTTOMLEFT", 0, -3); rowStart = b
    else b:SetPoint("LEFT", last, "RIGHT", 3, 0) end
    b:SetScript("OnClick", function() MakeOrPickup(c) end)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine(c.macro)
      local all = BF.Scan()[sec.kind]
      local pick = all[c.key]
      if sec.body and not pick then
        local body = sec.body(c, all)
        local id = body and tonumber(body:match("item:(%d+)[^\n]*$"))
        pick = id and { id = id, v = 0 }
      end
      GameTooltip:AddLine(pick and ("Uses: " .. ((GetItemInfo(pick.id)) or ("item " .. pick.id)) .. " (" .. pick.v .. ")") or ("No " .. c.label .. " " .. sec.noun .. " in your bags"), 1, 1, 1, true)
      local id = GetMacroIndexByName(c.macro)
      GameTooltip:AddLine((id and id > 0) and "Click to pick it up and drop it on a bar." or "Click to create it in your General macros and pick it up.", .7, .7, .7, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    last = b
  end
  return rowStart
end

panel:SetScript("OnShow", function(self)
  if self.built then return end
  self.built = true
  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Neutze's Pantry")
  local sub = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetWidth(600); sub:SetJustifyH("LEFT")
  sub:SetText("Click a button to create its macro (General tab) and pick it up. Each macro always uses the strongest matching item in your bags. Turn sections on or off with the Neutze's modules in the AddOns list.")
  local anchor, gap = sub, -12
  if #BF.sections == 0 then
    local none = self:CreateFontString(nil, "ARTWORK", "GameFontRed")
    none:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
    none:SetText("No Neutze's Pantry modules are enabled.")
  end
  for _, sec in ipairs(BF.sections) do anchor = Section(sec, anchor, gap); gap = -12 end
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

SLASH_NEUTZEPANTRY1 = "/pantry"
SLASH_NEUTZEPANTRY2 = "/np"
SLASH_NEUTZEPANTRY3 = "/bf"
SlashCmdList.NEUTZEPANTRY = function(msg)
  if msg and msg:lower():find("list") then
    BF.Update()
    local best = BF.Scan()
    for _, sec in ipairs(BF.sections) do
      print("|cff66ccffNeutze's Pantry|r — " .. sec.title .. ":")
      for _, c in ipairs(sec.cats) do
        local b = best[sec.kind][c.key]
        if b then print(string.format("  %s: %s (%d)", c.macro, (GetItemInfo(b.id)) or ("item "..b.id), b.v)) end
      end
    end
    return
  end
  if category and Settings and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel); InterfaceOptionsFrame_OpenToCategory(panel) end
end
