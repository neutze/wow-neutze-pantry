local BF = NeutzePantry
BF.RegisterSection({ page="Flasks", sortBySpec=true, display=4, kind="flask", title="Flasks", noun="flask", order=30,
  classify = function(name, text, use, deals)
    if BF.has(name, "flask") and use ~= "" and not deals then return use end
  end,
  cats = {
    { key="sp",     macro="NPflSP", old="FlaskSpellPower", label="Spell Power",   words=BF.SP_WORDS },
    { key="heal",   macro="NPflHeal", old="FlaskHealing",    label="Healing",       words=BF.HEAL_WORDS },
    { key="ap",     macro="NPflAP", old="FlaskAP",         label="Attack Power",  words={"attack power"} },
    { key="hp",     macro="NPflHP", old="FlaskHealth",     label="Health",        words={"maximum health", "max health"} },
    { key="mana",   macro="NPflMana", old="FlaskMana",       label="Mana",          words={"maximum mana", "max mana", "mana every 5", "mana per 5"} },
    { key="res",    macro="NPflResist", old="FlaskResist",     label="Resistance",    words={"resistance"} },
    { key="immune", macro="NPflPetrify", old="FlaskPetrify",    label="Petrification", words={"immune", "stone"} },
    { key="agi",    macro="NPflAgi", old="FlaskAgility",    label="Agility",       words={"agility"} },
    { key="str",    macro="NPflStr", old="FlaskStrength",   label="Strength",      words={"strength"} },
    { key="sta",    macro="NPflSta", old="FlaskStamina",    label="Stamina",       words={"stamina"} },
    { key="int",    macro="NPflInt", old="FlaskIntellect",  label="Intellect",     words={"intellect"} },
  }})
