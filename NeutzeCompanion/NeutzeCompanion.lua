-- Neutze's Companion: keeps the companion pet you typed in for this character summoned.
-- It only summons when you have NO pet out, so a pet you call by hand is left alone.
-- Never in combat, while stealthed/invisible/feigning, mounted, on a flight path, dead,
-- casting, channeling, or eating/drinking. Optional: pause in dungeons, raids and battlegrounds.
NeutzeCompanion = NeutzeCompanion or {}
local NC = NeutzeCompanion
local PREFIX = "|cff66ccffNeutze's Companion|r: "

local function DB()
  NeutzeCompanionDB = NeutzeCompanionDB or {}
  local d = NeutzeCompanionDB
  if d.pauseInstances == nil then d.pauseInstances = false end
  if d.dismissStealth == nil then d.dismissStealth = true end
  return d
end

-- ---------- pet lookup (pet journal; falls back to the old companion API) ----------
local function lower(s) return s and s:lower() or "" end

local function FindPet(name)
  if not name or name == "" then return nil end
  local want = lower(name)
  if C_PetJournal then
    if C_PetJournal.FindPetIDByName then
      local _, guid = C_PetJournal.FindPetIDByName(name)
      if guid then return { guid = guid, name = name } end
    end
    local n = C_PetJournal.GetNumPets and select(1, C_PetJournal.GetNumPets()) or 0
    for i = 1, n do
      local guid, _, owned, custom, _, _, _, species = C_PetJournal.GetPetInfoByIndex(i)
      if guid and owned ~= false and (lower(custom) == want or lower(species) == want) then
        return { guid = guid, name = (custom and custom ~= "" and custom) or species }
      end
    end
  elseif GetNumCompanions then
    for i = 1, GetNumCompanions("CRITTER") do
      local _, cname = GetCompanionInfo("CRITTER", i)
      if lower(cname) == want then return { index = i, name = cname } end
    end
  end
  return nil
end

local function SummonedGUID()
  if C_PetJournal and C_PetJournal.GetSummonedPetGUID then return C_PetJournal.GetSummonedPetGUID() end
  if GetNumCompanions then
    for i = 1, GetNumCompanions("CRITTER") do
      local _, _, _, _, active = GetCompanionInfo("CRITTER", i)
      if active then return "companion-" .. i end
    end
  end
  return nil
end

local function Summon(pet)
  if pet.guid then C_PetJournal.SummonPetByGUID(pet.guid)
  elseif pet.index then CallCompanion("CRITTER", pet.index) end
end

local function Dismiss()
  local cur = SummonedGUID()
  if not cur then return end
  if C_PetJournal and C_PetJournal.SummonPetByGUID and not tostring(cur):find("^companion%-") then
    C_PetJournal.SummonPetByGUID(cur)          -- summoning the active pet again puts it away
  elseif DismissCompanion then DismissCompanion("CRITTER") end
end

-- ---------- when is it OK to summon ----------
local FOOD = { ["Food"]=true, ["Drink"]=true, ["Food & Drink"]=true, ["Refreshment"]=true }
local function EatingOrDrinking()
  for i = 1, 40 do
    local name = UnitBuff and UnitBuff("player", i)
    if not name then
      if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
        local a = C_UnitAuras.GetBuffDataByIndex("player", i); name = a and a.name
      end
    end
    if not name then return false end
    if FOOD[name] then return true end
  end
  return false
end

local function Hidden()
  return (IsStealthed and IsStealthed()) or (UnitIsFeignDeath and UnitIsFeignDeath("player"))
end

local function CanSummon()
  local d = DB()
  if InCombatLockdown() or UnitAffectingCombat("player") then return false end
  if UnitIsDeadOrGhost("player") or Hidden() then return false end
  if IsMounted() or (UnitOnTaxi and UnitOnTaxi("player")) or (UnitInVehicle and UnitInVehicle("player")) then return false end
  if (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")) then return false end
  if EatingOrDrinking() then return false end
  if d.pauseInstances then
    local inInst, kind = IsInInstance()
    if inInst and (kind == "party" or kind == "raid" or kind == "pvp" or kind == "arena") then return false end
  end
  return true
end

function NC.Check()
  local d = DB()
  if d.dismissStealth and Hidden() and SummonedGUID() and not InCombatLockdown() then Dismiss(); return end
  if not d.name or d.name == "" then return end
  if SummonedGUID() then return end                 -- a pet is out (yours or one you called by hand)
  if not CanSummon() then return end
  local pet = FindPet(d.name)
  if pet then Summon(pet) end
end

-- ---------- events ----------
local pending = false
local function Soon(delay)
  if pending then return end
  pending = true
  C_Timer.After(delay or 1.5, function() pending = false; NC.Check() end)
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA", "PLAYER_UNGHOST", "PLAYER_ALIVE",
                     "PLAYER_REGEN_ENABLED", "PLAYER_MOUNT_DISPLAY_CHANGED", "UPDATE_STEALTH",
                     "COMPANION_UPDATE", "PLAYER_CONTROL_GAINED", "UNIT_SPELLCAST_STOP" }) do
  pcall(f.RegisterEvent, f, e)
end
f:SetScript("OnEvent", function(_, e, unit)
  if e == "UNIT_SPELLCAST_STOP" and unit ~= "player" then return end
  if (e == "PLAYER_ENTERING_WORLD" and not NC.macroDone) or (e == "PLAYER_REGEN_ENABLED" and NC.macroPending) then
    NC.macroDone, NC.macroPending = true, false
    if C_Timer and NC.WriteMacro then C_Timer.After(3, NC.WriteMacro) end   -- keep the "Companion" macro current
  end
  Soon(e == "PLAYER_ENTERING_WORLD" and 4 or 1.5)
end)
if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(5, function() NC.Check() end) end  -- after eating, landing, ...

-- ---------- options panel ----------
local panel = CreateFrame("Frame")
panel.name = "Neutze's Companion"
local category, status, box

-- ---------- character macro "Companion" (so the pet shows on your bar) ----------
local MACRO = "Companion"
local function PetIcon(pet)
  if pet.guid and C_PetJournal and C_PetJournal.GetPetInfoByPetID then
    local icon = select(9, C_PetJournal.GetPetInfoByPetID(pet.guid))
    if icon then return icon end
  end
  if pet.index and GetCompanionInfo then
    local _, _, _, icon = GetCompanionInfo("CRITTER", pet.index)
    if icon then return icon end
  end
  return 134400
end

local function MacroBody(pet)
  if pet.guid then
    return '/run local g="' .. pet.guid .. '" if C_PetJournal.GetSummonedPetGUID()~=g then C_PetJournal.SummonPetByGUID(g) end'
  end
  return "/run CallCompanion(\"CRITTER\"," .. pet.index .. ")"
end

-- Create or update the macro; returns a short note (or nil).
local function WriteMacro(pet)
  if not pet or not CreateMacro then return nil end
  if InCombatLockdown() then NC.macroPending = true; return "Macro updates after combat." end
  local idx = GetMacroIndexByName(MACRO)
  if idx and idx > 0 then EditMacro(idx, MACRO, PetIcon(pet), MacroBody(pet)); return nil end
  local _, perChar = GetNumMacros()
  if perChar and perChar >= (MAX_CHARACTER_MACROS or 18) then
    return "|cffff5555Character macro tab is full|r - free a slot for the \"Companion\" macro."
  end
  CreateMacro(MACRO, PetIcon(pet), MacroBody(pet), true)
  return "Macro |cffffd200Companion|r created on the character tab - drag it to your bar."
end
NC.WriteMacro = function() return WriteMacro(FindPet(DB().name)) end

local function SetPet(name)
  local d = DB()
  NC.lastNote = nil
  d.name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
  local pet = FindPet(d.name)
  if d.name == "" then
    if status then status:SetText("No companion set for this character.") end
  elseif pet then
    local note = WriteMacro(pet)
    if status then status:SetText("|cff33ff33Found:|r " .. pet.name .. " - it will be summoned whenever no pet is out." .. (note and ("  " .. note) or "")) end
    NC.lastNote = note
    if CanSummon() and (not pet.guid or SummonedGUID() ~= pet.guid) then Summon(pet) end   -- swap to the new choice now
  else
    if status then status:SetText("|cffff5555Not found|r in your pet journal. Check the spelling (the pet's name as shown in the journal).") end
  end
  return pet
end

local function CurrentPetName()
  local cur = SummonedGUID()
  if not cur then return nil end
  if C_PetJournal and C_PetJournal.GetPetInfoByPetID and not tostring(cur):find("^companion%-") then
    local _, custom, _, _, _, _, _, species = C_PetJournal.GetPetInfoByPetID(cur)
    return (custom and custom ~= "") and custom or species
  end
  if GetCompanionInfo then
    local i = tonumber(tostring(cur):match("(%d+)"))
    if i then local _, n = GetCompanionInfo("CRITTER", i); return n end
  end
end

local function Check(label, key, anchor, tip)
  local cb = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
  local t = cb.Text or cb.text or _G[(cb.GetName and cb:GetName() or "") .. "Text"]
  if not t and cb.CreateFontString then t = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight"); t:SetPoint("LEFT", cb, "RIGHT", 2, 0) end
  if t then t:SetText(label) end
  cb:SetChecked(DB()[key])
  cb:SetScript("OnClick", function(self) DB()[key] = self:GetChecked() and true or false; NC.Check() end)
  cb.tooltipText = tip
  return cb
end

panel:SetScript("OnShow", function(self)
  if self.built then
    box:SetText(DB().name or ""); SetPet(DB().name)
    return
  end
  self.built = true
  local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("Neutze's Companion")
  local sub = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetWidth(580); sub:SetJustifyH("LEFT")
  sub:SetText("Type the companion pet for THIS character. Whenever you have no pet out, it is summoned again (after login, loading screens, landing, dismounting, reviving, eating). A pet you call by hand is left alone.")

  local label = self:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -16)
  label:SetText("Companion for this character:")

  box = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  box:SetSize(260, 24)
  box:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 6, -6)
  box:SetAutoFocus(false)
  box:SetText(DB().name or "")
  box:SetScript("OnEnterPressed", function(b) SetPet(b:GetText()); b:ClearFocus() end)
  box:SetScript("OnEditFocusLost", function(b) SetPet(b:GetText()) end)
  box:SetScript("OnEscapePressed", function(b) b:SetText(DB().name or ""); b:ClearFocus() end)

  local use = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  use:SetSize(150, 22)
  use:SetPoint("LEFT", box, "RIGHT", 8, 0)
  use:SetText("Use current pet")
  use:SetScript("OnClick", function()
    local n = CurrentPetName()
    if n then box:SetText(n); SetPet(n) else status:SetText("Summon a pet first, then click this.") end
  end)

  status = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  status:SetPoint("TOPLEFT", box, "BOTTOMLEFT", -6, -6)
  status:SetWidth(580); status:SetJustifyH("LEFT")

  local c1 = Check("Put the pet away while stealthed, invisible or feigning death", "dismissStealth", status,
                   "So it doesn't give you away.")
  Check("Pause in dungeons, raids and battlegrounds", "pauseInstances", c1,
        "No automatic summoning inside instances.")
  SetPet(DB().name)
end)

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

SLASH_NEUTZECOMPANION1 = "/nc"
SLASH_NEUTZECOMPANION2 = "/companion"
SlashCmdList.NEUTZECOMPANION = function(msg)
  msg = msg and msg:gsub("^%s+", ""):gsub("%s+$", "") or ""
  if msg ~= "" then
    local pet = SetPet(msg)
    print(PREFIX .. (pet and ("companion set to " .. pet.name .. ".") or ("no pet called \"" .. msg .. "\" in your pet journal.")))
    return
  end
  if category and Settings and Settings.OpenToCategory then Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then InterfaceOptionsFrame_OpenToCategory(panel); InterfaceOptionsFrame_OpenToCategory(panel) end
end

-- ---------- field at the end of the Neutze's Pantry panel ----------
if NeutzePantry and NeutzePantry.RegisterSection and NeutzePantry.FieldRow then
  local function StatusText()
    local d = DB()
    if not d.name or d.name == "" then return "No companion set for this character." end
    local pet = FindPet(d.name)
    if not pet then return "|cffff5555Not found|r in your pet journal." end
    return "|cff33ff33Found:|r " .. pet.name .. "  " .. (NC.lastNote or "Character macro |cffffd200Companion|r summons it.")
  end
  NeutzePantry.RegisterSection({ display = 90, order = 900, title = "Companion (Neutze's Companion)", height = 62,
    custom = function(parent, anchor)
      return NeutzePantry.FieldRow(parent, anchor, {
        label = "Companion pet for this character - summoned again whenever no pet is out:",
        get = function() return DB().name end,
        set = function(text) SetPet(text); return StatusText() end,
        status = StatusText,
        button = "Use current pet", current = CurrentPetName, noCurrent = "Summon a pet first, then click this.",
      })
    end })
end
