-- Ammunition: the best arrows or bullets for the ranged weapon you have equipped.
local BF = NeutzePantry
local RANGED_SLOT = 18

-- "arrow", "bullet" or nil, from the equipped ranged weapon's type.
local function WantedAmmo()
  local id = GetInventoryItemID("player", RANGED_SLOT)
  local sub = id and select(7, GetItemInfo(id))
  sub = sub and sub:lower() or ""
  if sub:find("bow", 1, true) then return "arrow" end    -- Bows, Crossbows
  if sub:find("gun", 1, true) then return "bullet" end
end

BF.RegisterSection({ display=6.2, kind="ammo", title="Ammunition", noun="ammunition", order=75,
  classify = function(name, text, use, deals)
    local dps = text:match("adds ([%d%.]+) damage per second")
    if not dps then return nil end
    -- tenths, so 13.5 beats 13; the tag tells arrows from bullets
    return (BF.has(name, "arrow") and "ammo:arrow " or "ammo:bullet ") .. math.floor(tonumber(dps) * 10 + 0.5)
  end,
  body = function(c, best)
    local want = c.key == "auto" and WantedAmmo() or c.key
    local b = want and best[want] or (c.key == "auto" and (best.arrow or best.bullet))
    return b and ("#showtooltip\n/use item:" .. b.id)    -- using ammo in your bags loads it
  end,
  cats = {
    { key="auto",   macro="NPamAuto", old="PantryAmmo",   label="Ammo for my weapon", tip="Loads your best arrows if you have a bow or crossbow equipped, your best bullets if you have a gun.", words={"ammo:auto-never"} },
    { key="arrow",  macro="NPamArrow", old="PantryArrows", label="Arrows",  words={"ammo:arrow "} },
    { key="bullet", macro="NPamBullet", old="PantryBullets",label="Bullets", words={"ammo:bullet "} },
  }})
