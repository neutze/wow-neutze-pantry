# CurseForge project page (copy & paste)

**Name:** Neutze's
**Summary (short):** One macro button per job: best food, buff food by stat, elixirs, flasks, potions, explosives, plus a per-character companion and mount. For WoW: Forever.
**Game version:** World of Warcraft: Forever (Classic Era 1.15 / interface 11509 if Forever isn't listed)
**Categories:** Bags & Inventory (main), Buffs & Debuffs, Collections
**License:** MIT
**Source:** https://github.com/neutze/wow-neutze
**Issues:** https://github.com/neutze/wow-neutze/issues
**Logo:** art/logo-400.png
**Screenshots:** screenshots/pantry-panel.png, screenshots/potions-explosives.png, screenshots/companion-stable.png

## Description

**Neutze's** is a small add-on suite that keeps your action bars smart. Every button always uses the **best item in your bags**, and updates itself when you loot something better.

### Neutze's Pantry (`/np`)
Open the panel, click a button to create its macro and drag it to your bar. Each macro shows the icon of the item it will use.

- **Basics (Buffet-style):** Health (auto) and Mana (auto). They eat or drink out of combat and use a Healthstone or Mana Gem, then a potion, in combat. If you have no food, they use your Hearthstone. Also food only, drink only, potions, Healthstone, Mana Gem and bandages.
- **Well Fed:** buff food per stat: Strength, Agility, Stamina, Intellect, Spirit, Attack Power, Spell Power, Healing, Hit, Crit, Mana/Health Regen, Armor, Speed, Fire Breath and Fishing. Pick your spec (for example Elemental, Enhancement or Restoration) to set the stat priority. When a stat runs out, the macro falls back to your other Well Fed food, lowest leftover first. Fishing food always comes last.
- **Elixirs, Flasks, Battle Potions, Engineering explosives and Alchemy bombs:** one button per type, best tier first. These have no fallback, on purpose.

Every module is its own add-on, so turn off what you don't need. If Buffet is installed, its ignore list is respected.

### Neutze's Companion (`/nc`)
Type the pet you want on this character. It's summoned again whenever no pet is out, but never in combat, in stealth, while mounted, or while eating. You also get a **Companion** macro with the pet's icon.

### Neutze's Stable (`/stable`)
Type the mount for this character. It writes a **Mount** macro that mounts that mount, or dismounts you.

### Notes
- English game client only: items are recognised by their tooltip text, so new Forever recipes work without an item list.
- Macros are only changed out of combat.
