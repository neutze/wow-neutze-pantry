# Changelog

## v0.0.3 — 27 Nov 2026
- Commands: /np, /pantry and /neutze open the panel (/bf removed). /np list prints what every macro uses.
- Well Fed: every stat macro now falls back to your other Well Fed food when you run out
  (Forever's +5% kill XP comes with any Well Fed food). It follows your stat priority and eats the
  lowest leftover first, so your good food is kept.
- Well Fed: new AutoWellFed button (best food of your top stat) and AutoFishing (fishing food, always last).
- Well Fed: stat priority per character, with class defaults; reorder it in the panel.
- Elixirs and flasks deliberately have no fallback.

## v0.0.1 — 27 Nov 2026
First release.
- Core panel (/pantry, /bf) with one button per macro; only macros you create are kept up to date.
- Modules: Basics, Well Fed, Elixirs, Flasks, Battle Potions, Dynamite, Alchemy Bombs.
- Picks the strongest item per job; conjured food/water preferred; Hearthstone fallback for HP/MP/food/drink.
- Respects Buffet's ignored-items list when Buffet is installed.
