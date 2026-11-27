local BF = NeutzePantry
BF.RegisterSection({ display=6, kind="explosive", title="Engineering explosives", noun="explosive", order=10, useMax=true,
  classify = function(name, text, use, deals)
    if deals and BF.has(name, "dynamite", "bomb", "grenade", "sapper", "explosive", "land mine", "charge") then return use end
  end,
  cats = {
    { key="grenade",  macro="Grenade",  label="Stun bomb", words={"stun"} },
    { key="dynamite", macro="Dynamite", label="Dynamite",       words={"dynamite"}, byName=true },
    { key="bomb",     macro="Bomb",     label="Bomb / other",   words={"damage"} },
  }})
