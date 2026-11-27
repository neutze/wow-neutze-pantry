local BF = NeutzePantry
local FED = {"well fed", "also increase", "nutritious"}
BF.RegisterSection({ kind="food", title="Well Fed food", noun="food", order=60,
  classify = function(name, text)
    local pos
    for _, w in ipairs(FED) do local q = text:find(w, 1, true); if q and (not pos or q < pos) then pos = q end end
    return pos and text:sub(pos) or nil
  end,
  cats = {
    { key="ap",    macro="AutoAP",         label="Attack Power", words={"attack power"} },
    { key="heal",  macro="AutoHealing",    label="Healing",      words=BF.HEAL_WORDS },
    { key="sp",    macro="AutoSpellPower", label="Spell Power",  words=BF.SP_WORDS },
    { key="mp5",   macro="AutoMP5",        label="Mana Regen",   words={"mana every 5", "mana per 5"} },
    { key="speed", macro="AutoSpeed",      label="Speed",        words={"movement speed", "run speed"} },
    { key="armor", macro="AutoArmor",      label="Armor",        words={"armor"} },
    { key="str",   macro="AutoStrength",   label="Strength",     words={"strength"} },
    { key="agi",   macro="AutoAgility",    label="Agility",      words={"agility"} },
    { key="int",   macro="AutoIntellect",  label="Intellect",    words={"intellect"} },
    { key="sta",   macro="AutoStamina",    label="Stamina",      words={"stamina"} },
    { key="spi",   macro="AutoSpirit",     label="Spirit",       words={"spirit"} },
  }})
