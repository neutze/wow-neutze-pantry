-- Runes: Demonic Rune / Dark Rune (mana for health, shared cooldown), biggest first.
local BF = NeutzePantry
BF.RegisterSection({ display=1.5, kind="rune", title="Runes", noun="rune", order=65, useMax=true,
  classify = function(name, text, use, deals)
    if BF.has(name, "demonic rune", "dark rune") and use ~= "" then return use end
  end,
  cats = {
    { key="rune", macro="NPruMana", old="PantryRune", label="Mana", tip="Demonic Rune or Dark Rune: restores mana and costs health.", words={"mana"} },
  }})
