-- Protection potions: one-hour "absorbs X fire damage" potions, strongest (Greater) first.
local BF = NeutzePantry
BF.RegisterSection({ display=5.5, kind="protection", title="Protection potions", noun="protection potion", order=55,
  classify = function(name, text, use, deals)
    if BF.has(name, "protection") and BF.has(name, "potion", "draught") and use:find("absorb", 1, true) then return use end
  end,
  cats = {
    { key="pfire",   macro="ProtFire",   label="Fire",   words={"fire damage"} },
    { key="pfrost",  macro="ProtFrost",  label="Frost",  words={"frost damage"} },
    { key="pnature", macro="ProtNature", label="Nature", words={"nature damage"} },
    { key="pshadow", macro="ProtShadow", label="Shadow", words={"shadow damage"} },
    { key="parcane", macro="ProtArcane", label="Arcane", words={"arcane damage"} },
    { key="pholy",   macro="ProtHoly",   label="Holy",   words={"holy damage"} },
  }})
