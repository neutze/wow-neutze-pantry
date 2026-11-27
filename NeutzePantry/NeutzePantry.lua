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
        local e = best[c.key]
        if not e then best[c.key] = { id=id, v=num, loId=id, loV=num }
        else
          if num > e.v then e.id, e.v = id, num end
          if num < e.loV then e.loId, e.loV = id, num end
        end
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
  h:SetText(sec.title)
  h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, yOff)
  local buttons = {}
  for _, c in ipairs(sec.cats) do
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
        local id = body and tonumber(body:match("item:(%d+)[^\n]*$"))
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

function BF.AddHeight(px) usedHeight = usedHeight + px end

panel:SetScript("OnShow", function(self)
  if self.built then return end
  self.built = true
  local scroll = CreateFrame("ScrollFrame", nil, self, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  content = CreateFrame("Frame", nil, scroll)
  local sw = scroll.GetWidth and scroll:GetWidth()
  if type(sw) == "number" and sw > 200 then CONTENT_W = math.floor(sw) - 40 end
  content:SetSize(CONTENT_W + 32, 1)
  scroll:SetScrollChild(content)

  local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -12)
  title:SetText("Neutze's Pantry")
  local sub = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetWidth(CONTENT_W); sub:SetJustifyH("LEFT")
  sub:SetText("Click a button to create its macro (General tab) and pick it up. Each macro always uses the best matching item in your bags. Hover a button to see which item. Turn sections on or off with the Neutze's modules in the AddOns list.")
  usedHeight = 70
  local anchor, gap = sub, -14
  local list = {}
  for _, sec in ipairs(BF.sections) do list[#list + 1] = sec end
  table.sort(list, function(a, b) return (a.display or a.order) < (b.display or b.order) end)
  if #list == 0 then
    local none = content:CreateFontString(nil, "ARTWORK", "GameFontRed")
    none:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -12)
    none:SetText("No Neutze's Pantry modules are enabled.")
  end
  for _, sec in ipairs(list) do
    anchor = Section(sec, anchor, gap); gap = -14
    if sec.extraUI then anchor = sec.extraUI(content, anchor) or anchor end
  end
  content:SetHeight(usedHeight + 40)
end)

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
