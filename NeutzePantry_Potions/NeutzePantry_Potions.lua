local BF = NeutzePantry
local MAX_SECONDS = 120   -- "combat" potion = buff of 2 minutes or less (e.g. 30 sec)
BF.RegisterSection({ page="Battle Potions", sortBySpec=true, display=5, kind="potion", title="Combat potions (short buffs)", noun="combat potion", order=50,
  classify = function(name, text, use, deals)
    if BF.has(name, "potion", "draught") and use ~= "" then
      local sec = tonumber(use:match("(%d+) sec"))
      if sec and sec <= MAX_SECONDS then return use end
    end
  end,
  cats = {
    { key="rage",   macro="NPpoRage", old="PotionRage",       label="Rage",            words={"rage"} },
    { key="free",   macro="NPpoFree", old="PotionFreeAction", label="Free Action",     words={"movement impairing", "stun and movement", "immune to stun"} },
    { key="invul",  macro="NPpoInvul", old="PotionInvuln",     label="Invulnerability", words={"immune to physical", "invulnerab"} },
    { key="speed",  macro="NPpoSpeed", old="PotionSpeed",      label="Speed",           words={"run speed", "movement speed"} },
    { key="haste",  macro="NPpoHaste", old="PotionHaste",      label="Haste",           words={"haste", "attack speed", "casting speed"} },
    { key="sp",     macro="NPpoSP", old="PotionSpellPower", label="Spell Power",     words=BF.SP_WORDS },
    { key="ap",     macro="NPpoAP", old="PotionAP",         label="Attack Power",    words={"attack power"} },
    { key="agi",    macro="NPpoAgi", old="PotionAgility",    label="Agility",         words={"agility"} },
    { key="str",    macro="NPpoStr", old="PotionStrength",   label="Strength",        words={"strength"} },
    { key="armor",  macro="NPpoArmor", old="PotionArmor",      label="Armor",           words={"armor"} },
    { key="absorb", macro="NPpoAbsorb", old="PotionAbsorb",     label="Absorb",          words={"absorb"} },
  }})
