local BF = NeutzePantry
BF.RegisterSection({ sortBySpec=true, display=3, kind="elixir", title="Elixirs", noun="elixir", order=40,
  classify = function(name, text, use, deals)
    if BF.has(name, "elixir") and use ~= "" and not deals then return use end
  end,
  cats = {
    { key="fire",   macro="ElixirFire",       label="Fire Power",   words={"fire damage", "fire spell"} },
    { key="frost",  macro="ElixirFrost",      label="Frost Power",  words={"frost damage", "frost spell"} },
    { key="shadow", macro="ElixirShadow",     label="Shadow Power", words={"shadow damage", "shadow spell"} },
    { key="heal",   macro="ElixirHealing",    label="Healing",      words=BF.HEAL_WORDS },
    { key="sp",     macro="ElixirSpellPower", label="Spell Power",  words=BF.SP_WORDS },
    { key="ap",     macro="ElixirAP",         label="Attack Power", words={"attack power"} },
    { key="agi",    macro="ElixirAgility",    label="Agility",      words={"agility"} },
    { key="str",    macro="ElixirStrength",   label="Strength",     words={"strength"} },
    { key="hp",     macro="ElixirHealth",     label="Health",       words={"maximum health", "max health"} },
    { key="regen",  macro="ElixirRegen",      label="Health Regen", words={"health every 5", "health per 5", "health regeneration"} },
    { key="mp5",    macro="ElixirMP5",        label="Mana Regen",   words={"mana every 5", "mana per 5"} },
    { key="armor",  macro="ElixirArmor",      label="Armor",        words={"armor"} },
    { key="int",    macro="ElixirIntellect",  label="Intellect",    words={"intellect"} },
    { key="sta",    macro="ElixirStamina",    label="Stamina",      words={"stamina"} },
    { key="spi",    macro="ElixirSpirit",     label="Spirit",       words={"spirit"} },
  }})
