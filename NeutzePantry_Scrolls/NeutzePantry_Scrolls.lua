-- Scrolls: Scroll of Agility/Strength/Stamina/Intellect/Spirit/Protection, highest rank first.
local BF = NeutzePantry
BF.RegisterSection({ sortBySpec=true, display=3.5, kind="scroll", title="Scrolls", noun="scroll", order=45,
  classify = function(name, text, use, deals)
    if BF.has(name, "scroll of") and use ~= "" and not deals then return use end
  end,
  body = function(c, best)
    local b = best[c.key]
    return b and ("#showtooltip\n/use [@player] item:" .. b.id)
  end,
  cats = {
    { key="agi",   macro="ScrollAgility",   label="Agility",          words={"agility"} },
    { key="str",   macro="ScrollStrength",  label="Strength",         words={"strength"} },
    { key="sta",   macro="ScrollStamina",   label="Stamina",          words={"stamina"} },
    { key="int",   macro="ScrollIntellect", label="Intellect",        words={"intellect"} },
    { key="spi",   macro="ScrollSpirit",    label="Spirit",           words={"spirit"} },
    { key="armor", macro="ScrollArmor",     label="Protection (armor)", words={"armor"} },
  }})
