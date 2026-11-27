# Changelog

## Unreleased
- Options pages no longer stay blank sometimes. They build one frame after they open, rebuild when they get their real width, and if a page fails to build, the error is printed in chat and it tries again the next time you open it.
- Options: every enabled module has its own page under Neutze's Pantry (Basics, Well Fed, Elixirs, ..., Alerts), followed by Companion, Stable and Macros. The first page only holds the spec picker and your role (Tank, Healer or Damage, from the spec). Disabled modules have no page.
- Alerts: the stock grid, the shopping list and the sections after them start at the left edge again. They had been anchored under the last vendor checkbox and ran off the panel. The shopping list no longer shows negative amounts: a macro running on a fallback counts 0 of its own item and says what it uses in the meantime.
- Alerts: the stock grid, shopping list and the sections after it start at the left edge again (they were anchored under the last vendor checkbox and ran off the panel). The shopping list no longer shows negative amounts: a macro on a fallback counts 0 of its own item and says what it uses meanwhile. Items never seen are listed without "(none seen yet)".
- Every macro is now named NP + module code + item (NPbaHP, NPwfAP, NPelAgi, NPwbAuto, ...), so they sort by module. Old macros (PantryHP, AutoAP, ...) are renamed in place on login, so they stay on your bars. A leftover duplicate is deleted, and Alerts settings move along. Only General-tab macros that Pantry wrote are touched.
- New modules: Protection Potions, Scrolls, Juju & Zanza, Runes, Weapon Buffs (stones, oils, poisons; Auto picks by spec and weapon) and Ammunition (arrows or bullets for your ranged weapon).
- Pantry is now the parent of the suite: Neutze's Companion, Stable and Macros require it and put their options pages under Neutze's Pantry (`NeutzePantry.AddSubPage`).
- Macros also update when you change equipment.
- New module **Neutze's Alerts**: pulsing macro button and chat reminder when Well Fed, an elixir or a flask is missing or running out; per-character "keep at least" stock targets with a steady border and coloured count on the button and a last-one warning; shopping list (`/np shop`); automatic vendor restock of N stacks of drinks, plain food and ammunition (Shift skips); low-ammo warning.
- Core: bag scan now counts how many items each category holds; `/np <word>` commands and update hooks for modules.

## v0.0.1 — 2026-11-27
First release of Neutze's Pantry for WoW Forever.
- Panel: /np, /pantry or /neutze. Click a button to create its macro (General tab) and pick it up; only macros you create are kept up to date. Scrollable, sections in a fixed order.
- Every macro uses the best matching item in your bags and shows that item's icon.
- Basics (Buffet-style): Health (auto) and Mana (auto) — food/drink out of combat, Healthstone or mana gem, then potion, in combat; Hearthstone if you have no food/drink. Plus food only, drink only, potions, Healthstone, mana gem, bandage. Conjured food/water preferred.
- Well Fed: buff food per stat, AutoWellFed (best food of your top stat) and AutoFishing. When a stat runs out it falls back to your other Well Fed food, lowest leftover first, following a per-character stat priority you can reorder or set from the class/spec dropdown in /np (under the Basics) (e.g. Elemental / Enhancement / Restoration), which also sorts food, elixir, flask and potion buttons best-first for that spec. "Best for my spec" (AutoWellFed) eats the right food. Also Mana/Health Regen, Hit, Crit and Fire Breath food; multi-stat food counts for each of its stats. Fishing is always last.
- Elixirs, Flasks, Battle Potions (short combat buffs), Dynamite (engineering explosives, highest tier first) and Alchemy Bombs — no fallback, on purpose.
- Respects Buffet's ignored-items list when Buffet is installed.
