local BF = NeutzePantry
BF.RegisterSection({ sortBySpec=true, display=4, kind="flask", title="Flasks", noun="flask", order=30,
  classify = function(name, text, use, deals)
    if BF.has(name, "flask") and use ~= "" and not deals then return use end
  end,
  cats = {
    { key="sp",     macro="FlaskSpellPower", label="Spell Power",   words=BF.SP_WORDS },
    { key="heal",   macro="FlaskHealing",    label="Healing",       words=BF.HEAL_WORDS },
    { key="ap",     macro="FlaskAP",         label="Attack Power",  words={"attack power"} },
    { key="hp",     macro="FlaskHealth",     label="Health",        words={"maximum health", "max health"} },
    { key="mana",   macro="FlaskMana",       label="Mana",          words={"maximum mana", "max mana", "mana every 5", "mana per 5"} },
    { key="res",    macro="FlaskResist",     label="Resistance",    words={"resistance"} },
    { key="immune", macro="FlaskPetrify",    label="Petrification", words={"immune", "stone"} },
    { key="agi",    macro="FlaskAgility",    label="Agility",       words={"agility"} },
    { key="str",    macro="FlaskStrength",   label="Strength",      words={"strength"} },
    { key="sta",    macro="FlaskStamina",    label="Stamina",       words={"stamina"} },
    { key="int",    macro="FlaskIntellect",  label="Intellect",     words={"intellect"} },
  }})
