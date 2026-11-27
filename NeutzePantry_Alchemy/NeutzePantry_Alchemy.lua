local BF = NeutzePantry
BF.RegisterSection({ page="Alchemy Bombs", display=7, kind="alchdmg", title="Alchemy damage items", noun="alchemy damage item", order=20, useMax=true,
  classify = function(name, text, use, deals)
    if deals and BF.has(name, "flask", "oil of", "alchemist", "vial", "concoction") then return use end
  end,
  cats = {
    { key="dmg", macro="NPalDmg", old="AlchemyDamage", label="Alchemy Damage", words={"damage"} },
  }})
