local BF = NeutzePantry
BF.RegisterSection({ page="Elixirs", sortBySpec=true, display=3, kind="elixir", title="Elixirs", noun="elixir", order=40,
  classify = function(name, text, use, deals)
    if BF.has(name, "elixir") and use ~= "" and not deals then return use end
  end,
  cats = {
    { key="fire",   macro="NPelFire", old="ElixirFire",       label="Fire Power",   words={"fire damage", "fire spell"} },
    { key="frost",  macro="NPelFrost", old="ElixirFrost",      label="Frost Power",  words={"frost damage", "frost spell"} },
    { key="shadow", macro="NPelShadow", old="ElixirShadow",     label="Shadow Power", words={"shadow damage", "shadow spell"} },
    { key="heal",   macro="NPelHeal", old="ElixirHealing",    label="Healing",      words=BF.HEAL_WORDS },
    { key="sp",     macro="NPelSP", old="ElixirSpellPower", label="Spell Power",  words=BF.SP_WORDS },
    { key="ap",     macro="NPelAP", old="ElixirAP",         label="Attack Power", words={"attack power"} },
    { key="agi",    macro="NPelAgi", old="ElixirAgility",    label="Agility",      words={"agility"} },
    { key="str",    macro="NPelStr", old="ElixirStrength",   label="Strength",     words={"strength"} },
    { key="hp",     macro="NPelHP", old="ElixirHealth",     label="Health",       words={"maximum health", "max health"} },
    { key="regen",  macro="NPelHP5", old="ElixirRegen",      label="Health Regen", words={"health every 5", "health per 5", "health regeneration"} },
    { key="mp5",    macro="NPelMP5", old="ElixirMP5",        label="Mana Regen",   words={"mana every 5", "mana per 5"} },
    { key="armor",  macro="NPelArmor", old="ElixirArmor",      label="Armor",        words={"armor"} },
    { key="int",    macro="NPelInt", old="ElixirIntellect",  label="Intellect",    words={"intellect"} },
    { key="sta",    macro="NPelSta", old="ElixirStamina",    label="Stamina",      words={"stamina"} },
    { key="spi",    macro="NPelSpi", old="ElixirSpirit",     label="Spirit",       words={"spirit"} },
  }})
