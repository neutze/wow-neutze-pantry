-- Weapon buffs: sharpening stones, weightstones, oils and rogue poisons.
-- Each macro uses the item, then puts it on your main hand (left-click) or off hand (right-click).
local BF = NeutzePantry

-- name -> tag, most specific first. "max" = rank by the biggest number in the text (poisons), else the first one.
local KINDS = {
  { tag="undead",    names={"consecrated sharpening", "blessed wizard oil"} },
  { tag="sharpcrit", names={"elemental sharpening"} },
  { tag="sharp",     names={"sharpening stone"} },
  { tag="weight",    names={"weightstone"} },
  { tag="manaoil",   names={"mana oil"} },
  { tag="wizard",    names={"wizard oil"} },
  { tag="proc",      names={"frost oil", "shadow oil"} },
  { tag="instant",   names={"instant poison"},      max=true },
  { tag="deadly",    names={"deadly poison"},       max=true },
  { tag="wound",     names={"wound poison"},        max=true },
  { tag="crippling", names={"crippling poison"},    max=true },
  { tag="mind",      names={"mind-numbing poison"}, max=true },
}

local function Number(s, max)
  local first, best = nil, 0
  for d in (s:gsub(",", "")):gmatch("(%d+)") do
    local n = tonumber(d); first = first or n; if n > best then best = n end
  end
  return max and best or (first or 0)
end

-- Auto: casters (spell power or healing on top of the spec priority) get wizard oil (healers: mana oil first),
-- everyone else a weightstone on blunt weapons and a sharpening stone on edged ones; Elemental stone as fallback.
local CASTER = { sp=true, heal=true, int=true, spi=true, mp5=true }
local BLUNT = { "mace", "staff", "staves" }
local function AutoPick(best, slot)
  local id = GetInventoryItemID("player", slot)
  if not id then return nil end
  local _, _, _, _, _, class, sub = GetItemInfo(id)
  if not class or not class:lower():find("weapon", 1, true) then return nil end   -- shield, held in off hand, ...
  sub = (sub or ""):lower()
  local order
  local top = BF.Priority()[1]
  if CASTER[top] then order = (top == "heal" or top == "mp5") and {"manaoil", "wizard"} or {"wizard", "manaoil"}
  elseif BF.has(sub, unpack(BLUNT)) then order = {"weight", "sharpcrit"}
  else order = {"sharp", "sharpcrit"} end
  for _, k in ipairs(order) do if best[k] then return best[k].id end end
end
BF.WeaponAutoPick = AutoPick

BF.RegisterSection({ page="Weapon Buffs", display=6.5, kind="weapon", title="Weapon buffs (left-click: main hand, right-click: off hand)", noun="weapon buff", order=15,
  classify = function(name, text, use, deals)
    if use == "" then return nil end
    for _, k in ipairs(KINDS) do
      if BF.has(name, unpack(k.names)) then return "wb:" .. k.tag .. " " .. Number(use, k.max) end
    end
  end,
  body = function(c, best)
    if c.key == "auto" then
      local mh, oh = AutoPick(best, 16), AutoPick(best, 17)
      if not mh and not oh then return nil end
      local use = (mh and oh) and ("[btn:2] item:" .. oh .. "; item:" .. mh)
               or mh and ("[nobtn:2] item:" .. mh) or ("[btn:2] item:" .. oh)
      return "#showtooltip\n/use " .. use .. "\n/use [btn:2] 17; 16\n/click StaticPopup1Button1"
    end
    local b = best[c.key]
    -- /click confirms "replace the current enchantment?" if one is already on the weapon
    return b and ("#showtooltip\n/use item:" .. b.id .. "\n/use [btn:2] 17; 16\n/click StaticPopup1Button1")
  end,
  cats = {
    { key="auto",      macro="NPwbAuto", old="WeaponAuto",     label="Auto (spec + weapon)", tip="Casters: wizard oil (healers: mana oil). Others: weightstone on maces and staves, sharpening stone on edged weapons, Elemental stone if you have neither. Left-click main hand, right-click off hand.", words={"wb:auto-never"} },
    { key="sharp",     macro="NPwbSharp", old="WeaponSharpen",  label="Sharpening stone", words={"wb:sharp "} },
    { key="sharpcrit", macro="NPwbElem", old="WeaponCrit",     label="Elemental stone",  words={"wb:sharpcrit "} },
    { key="weight",    macro="NPwbWeight", old="WeaponWeight",   label="Weightstone",      words={"wb:weight "} },
    { key="wizard",    macro="NPwbWizard", old="WeaponWizard",   label="Wizard oil",       words={"wb:wizard "} },
    { key="manaoil",   macro="NPwbManaOil", old="WeaponManaOil",  label="Mana oil",         words={"wb:manaoil "} },
    { key="undead",    macro="NPwbUndead", old="WeaponUndead",   label="Vs. undead",       words={"wb:undead "} },
    { key="proc",      macro="NPwbProcOil", old="WeaponProcOil",  label="Frost/Shadow oil", words={"wb:proc "} },
    { key="instant",   macro="NPwbInstant", old="PoisonInstant",  label="Instant poison",   words={"wb:instant "} },
    { key="deadly",    macro="NPwbDeadly", old="PoisonDeadly",   label="Deadly poison",    words={"wb:deadly "} },
    { key="wound",     macro="NPwbWound", old="PoisonWound",    label="Wound poison",     words={"wb:wound "} },
    { key="crippling", macro="NPwbCrip", old="PoisonCrippling",label="Crippling poison", words={"wb:crippling "} },
    { key="mind",      macro="NPwbMind", old="PoisonMindNumb", label="Mind-numbing poison", words={"wb:mind "} },
  }})
