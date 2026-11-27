local BF = NeutzePantry
local MAX_SECONDS = 120   -- "combat" potion = buff of 2 minutes or less (e.g. 30 sec)
BF.RegisterSection({ display=5, kind="potion", title="Combat potions (short buffs)", noun="combat potion", order=50,
  classify = function(name, text, use, deals)
    if BF.has(name, "potion", "draught") and use ~= "" then
      local sec = tonumber(use:match("(%d+) sec"))
      if sec and sec <= MAX_SECONDS then return use end
    end
  end,
  cats = {
    { key="rage",   macro="PotionRage",       label="Rage",            words={"rage"} },
    { key="free",   macro="PotionFreeAction", label="Free Action",     words={"movement impairing", "stun and movement", "immune to stun"} },
    { key="invul",  macro="PotionInvuln",     label="Invulnerability", words={"immune to physical", "invulnerab"} },
    { key="speed",  macro="PotionSpeed",      label="Speed",           words={"run speed", "movement speed"} },
    { key="haste",  macro="PotionHaste",      label="Haste",           words={"haste", "attack speed", "casting speed"} },
    { key="sp",     macro="PotionSpellPower", label="Spell Power",     words=BF.SP_WORDS },
    { key="ap",     macro="PotionAP",         label="Attack Power",    words={"attack power"} },
    { key="agi",    macro="PotionAgility",    label="Agility",         words={"agility"} },
    { key="str",    macro="PotionStrength",   label="Strength",        words={"strength"} },
    { key="armor",  macro="PotionArmor",      label="Armor",           words={"armor"} },
    { key="absorb", macro="PotionAbsorb",     label="Absorb",          words={"absorb"} },
  }})
