-- Scrolls: Scroll of Agility/Strength/Stamina/Intellect/Spirit/Protection, highest rank first.
local BF = NeutzePantry
BF.RegisterSection({ page="Scrolls", sortBySpec=true, display=3.5, kind="scroll", title="Scrolls", noun="scroll", order=45,
  classify = function(name, text, use, deals)
    if BF.has(name, "scroll of") and use ~= "" and not deals then return use end
  end,
  body = function(c, best)
    local b = best[c.key]
    return b and ("#showtooltip\n/use [@player] item:" .. b.id)
  end,
  cats = {
    { key="agi",   macro="NPscAgi", old="ScrollAgility",   label="Agility",          words={"agility"} },
    { key="str",   macro="NPscStr", old="ScrollStrength",  label="Strength",         words={"strength"} },
    { key="sta",   macro="NPscSta", old="ScrollStamina",   label="Stamina",          words={"stamina"} },
    { key="int",   macro="NPscInt", old="ScrollIntellect", label="Intellect",        words={"intellect"} },
    { key="spi",   macro="NPscSpi", old="ScrollSpirit",    label="Spirit",           words={"spirit"} },
    { key="armor", macro="NPscArmor", old="ScrollArmor",     label="Protection (armor)", words={"armor"} },
  }})
