# CLAUDE.md — wow-neutze

Notes for Claude sessions working on this repo: Neutze's add-on suite for **World of Warcraft: Forever** (Classic+, client 1.60.1, `## Interface: 16001, 11509`).

## Owner's rules
- **No version tag, release or CurseForge upload until the owner says so.** Everything should work first. Version stays **v0.0.1** (CHANGELOG entry "unreleased").
- CurseForge upload is manual by the owner. GitHub releases are created in the owner's browser (the session git proxy can't push tags, and the API blocks release writes). Publishing a release runs `.github/workflows/release.yml` (BigWigsMods/packager@v2), which builds `Neutze-v<ver>.zip`. CF upload in CI is optional (`CF_API_KEY` secret, `CURSEFORGE_PROJECT_ID` var).
- Commit straight to `main`.
- Slash commands: `/np`, `/pantry`, `/neutze` (never `/bf`). Companion: `/nc`, `/companion`. Stable: `/stable`, `/ns`.

## Layout
| Folder | Add-on | Notes |
|---|---|---|
| `NeutzePantry` | core | panel, bag scan, macro update; global `NeutzePantry` (`BF` locally) |
| `NeutzePantry_Basics` | Basics | Buffet-style: PantryHP/MP (food or drink out of combat; healthstone or mana gem, then potion, in combat; Hearthstone if nothing), food, drink, potions, stone, gem, bandage |
| `NeutzePantry_WellFed` | Well Fed | food per stat, AutoWellFed, AutoFishing (always last); **only Well Fed has a fallback**, which uses the lowest leftover food of the next stat in the priority; spec presets now live in the core (`BF.SPECS`, `BF.Priority()`, `BF.ApplySpec`, `BF.Rank`; dropdown under the Basics section (before the first sortBySpec section), `sortBySpec=true` sections sort best-first, `BF.Rebuild()` redraws); `multi=true` (multi-stat food counts for each stat) |
| `NeutzePantry_Elixirs`, `_Flasks`, `_Potions`, `_Dynamite`, `_Alchemy` | categories | **no fallback**, on purpose |
| `NeutzeCompanion` | Companion | per-character pet (`NeutzeCompanionDB`), re-summons whenever no pet is out; never in combat, stealth, mounted, taxi, casting or eating; writes the **character** macro `Companion` (pet icon, summons it if not out) |
| `NeutzeStable` | Stable | per-character mount (`NeutzeStableDB`), writes the **character** macro `Mount` (`/dismount [mounted]` + `C_MountJournal.SummonByID(id)`) |

`.pkgmeta` packages everything as one `Neutze/` zip with `move-folders`. Add new add-ons there **and** in the README.

## Core API (NeutzePantry.lua)
- `RegisterSection{display, kind, title, noun, order, cats, classify(name,text,use,deals), body(c,best), useMax, multi, extraUI(parent,anchor), custom(parent,anchor), height}`.
  - `order` = classify priority (an item goes to the first section that claims it): Dynamite 10, Alchemy 20, Flasks 30, Elixirs 40, Potions 50 (≤120 s, `(%d+) sec`), WellFed 60, Basics 70.
  - `display` = panel order: 1 Basics … 7 Alchemy, 90 Companion, 91 Stable.
  - `custom` sections (Companion/Stable) draw their own UI, usually with `NeutzePantry.FieldRow(parent, anchor, {label, get, set(text)->status, status, button, current, noCurrent})`.
- Items are recognized from **tooltip text** (English client) via the hidden tooltip `NeutzePantryScanTip`. There is no item ID list.
- Macros: icon 134400 + `#showtooltip`. Only macros the user created from the panel are updated (Buffet-like), and only out of combat. `BuffetDB.ignoredItems` is respected.
- `NeutzePantryCharDB` (per character): `priority`, `spec`.
- `NeutzePantry.Open()` opens the panel.

## Testing
There's no WoW in the sandbox. Use Python `lupa` (Lua 5.5) with mocked WoW APIs; examples are in the owner's session scratch (`test11.py` panel and Well Fed, `test12.py` Companion and Stable fields, `test13.py` spec dropdown and food categories, `testc.py` Companion logic). Mock gotchas: a panel `OnShow` frame needs `rawset(frame,"built",false)`. Keep only the first `OnShow` handler. In Lua 5.5, for-loop variables are const.

## The owner's game install (via the device bridge, macOS)
- Root: `/Applications/World of Warcraft/_forever_/` (bridge: `~/mnt/World of Warcraft/_forever_/`). Add-ons go in `Interface/AddOns/`.
- WTF: `WTF/Account/HIGHWAVE/macros-cache.txt` holds the General macros (IDs 0000…). `WTF/Account/HIGHWAVE/93/<Char>-Neutze/macros-cache.txt` holds character macros (IDs 0100…), in the format `VER 3 <16hex> "Name" "icon"\nbody\nEND`. Also `AddOns.txt` per character, `config-cache.wtf`, and `bindings-cache.wtf`.
- **Edit WTF only while WoW is fully closed** (the game overwrites it on exit). Check that it's closed via the mtimes in `Logs/`. Back up first, into `~/Documents/curseforge/backups/WTF-backup-<date>`.
- After `device_commit_files`, check with `md5sum` on the device: a just-written staged file can be committed in its old version. Commit again if it differs.
- New add-ons have to be added as `<Name>: enabled` to every character's `AddOns.txt` (23 character folders), or the owner enables them in game.
- Macro limit: about 30 per character. Shared macros (Riding, Weapon Buff, etc.) live in the General tab.

## Owner's macro style (for class macros)
One ability per macro (switch stance if needed, then use it). No stance-dependent multi-ability macros, and no modifier keys (Shift is already bound). Use the spell + `/startattack` for melee, but not on caster spells (it breaks wanding). Use mouseover where useful. Each class has one Horde and one Alliance character with identical macros and settings. Mathilda (warrior) and Nora (shaman) are the source of truth.

## Work folder (outside the repo)
`~/Documents/curseforge/` on the owner's Mac: `upload/` (CurseForge kit), `curseforge.md` (page text), `macros/`, keybind planner, `backups/` (WTF), `scripts/`. Keep non-code files there, not in the WoW folder.

## Open items
- NeutzeCompanion and NeutzeStable still need adding to every character's `AddOns.txt` (only while WoW is closed). The owner should disable AutoCompanion.
- Screenshots go to `screenshots/` and are embedded in the README before v0.0.1 ships.
- Still to confirm in game: two-line stance+ability macros fire in one press; `[@cursor]` works.
