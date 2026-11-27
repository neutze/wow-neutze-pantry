# Changelog

## v0.0.1 — 2026-11-27
First release of Neutze's Pantry for WoW Forever.
- Panel: /np, /pantry or /neutze. Click a button to create its macro (General tab) and pick it up; only macros you create are kept up to date. Scrollable, sections in a fixed order.
- Every macro uses the best matching item in your bags and shows that item's icon.
- Basics (Buffet-style): Health (auto) and Mana (auto) — food/drink out of combat, Healthstone or mana gem, then potion, in combat; Hearthstone if you have no food/drink. Plus food only, drink only, potions, Healthstone, mana gem, bandage. Conjured food/water preferred.
- Well Fed: buff food per stat, AutoWellFed (best food of your top stat) and AutoFishing. When a stat runs out it falls back to your other Well Fed food, lowest leftover first, following a per-character stat priority you can reorder or set from the class/spec dropdown at the top of /np (e.g. Elemental / Enhancement / Restoration), which also sorts food, elixir, flask and potion buttons best-first for that spec. "Best for my spec" (AutoWellFed) eats the right food. Also Mana/Health Regen, Hit, Crit and Fire Breath food; multi-stat food counts for each of its stats. Fishing is always last.
- Elixirs, Flasks, Battle Potions (short combat buffs), Dynamite (engineering explosives, highest tier first) and Alchemy Bombs — no fallback, on purpose.
- Respects Buffet's ignored-items list when Buffet is installed.
- Neutze's Companion: one companion pet per character, summoned again whenever no pet is out. Writes the character macro "Companion" with the pet's icon. Field at the bottom of /np, or /nc.
- Neutze's Stable: one mount per character; writes the character macro "Mount" (mount / dismount). Field at the bottom of /np, or /stable.
