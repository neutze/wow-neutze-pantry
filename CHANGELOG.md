# Changelog

## v0.0.1 — unreleased
First release of Neutze's Pantry for WoW Forever.
- Panel: /np, /pantry or /neutze. Click a button to create its macro (General tab) and pick it up; only macros you create are kept up to date. Scrollable, sections in a fixed order.
- Every macro uses the best matching item in your bags and shows that item's icon.
- Basics (Buffet-style): Health (auto) and Mana (auto) — food/drink out of combat, Healthstone or mana gem, then potion, in combat; Hearthstone if you have no food/drink. Plus food only, drink only, potions, Healthstone, mana gem, bandage. Conjured food/water preferred.
- Well Fed: buff food per stat, AutoWellFed (best food of your top stat) and AutoFishing. When a stat runs out it falls back to your other Well Fed food, lowest leftover first, following a per-character stat priority you can reorder. Fishing is always last.
- Elixirs, Flasks, Battle Potions (short combat buffs), Dynamite (engineering explosives, highest tier first) and Alchemy Bombs — no fallback, on purpose.
- Respects Buffet's ignored-items list when Buffet is installed.
