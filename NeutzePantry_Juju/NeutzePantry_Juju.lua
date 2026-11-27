-- Juju & Zanza: Juju (Winterspring), Zanza (Zul'Gurub), Blasted Lands buffs and Winterfall Firewater.
local BF = NeutzePantry
local NAMES = { "juju ", "of zanza", "r.o.i.d.s", "ground scorpok", "lung juice", "cerebral cortex", "gizzard gum", "firewater" }
BF.RegisterSection({ page="Juju & Zanza", sortBySpec=true, display=4.5, kind="juju", title="Juju, Zanza & Blasted Lands", noun="buff item", order=35, multi=true,
  classify = function(name, text, use, deals)
    if use ~= "" and not deals and BF.has(name, unpack(NAMES)) then return use end
  end,
  body = function(c, best)
    local b = best[c.key]
    return b and ("#showtooltip\n/use [@player] item:" .. b.id)   -- Juju is used on a target: always you
  end,
  cats = {
    { key="str",   macro="NPjuStr", old="JujuStrength",  label="Strength",     words={"strength"} },
    { key="agi",   macro="NPjuAgi", old="JujuAgility",   label="Agility",      words={"agility"} },
    { key="ap",    macro="NPjuAP", old="JujuAP",        label="Attack Power", words={"attack power"} },
    { key="haste", macro="NPjuHaste", old="JujuHaste",     label="Attack Speed", words={"attack speed"} },
    { key="sta",   macro="NPjuSta", old="JujuStamina",   label="Stamina",      words={"stamina"} },
    { key="int",   macro="NPjuInt", old="JujuIntellect", label="Intellect",    words={"intellect"} },
    { key="spi",   macro="NPjuSpi", old="JujuSpirit",    label="Spirit",       words={"spirit"} },
    { key="speed", macro="NPjuSpeed", old="JujuSpeed",     label="Speed",        words={"movement speed", "run speed"} },
  }})
