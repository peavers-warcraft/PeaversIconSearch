# PeaversIconSearch

A World of Warcraft addon that adds an item search box to the transmog outfit icon picker.

## Features

<!-- peavers:features -->
- Search box in the outfit create/edit popup — type an item's name and the icon grid filters to matching items' icons
- Multi-select item type filters (Armor slots and Weapon types) that combine with the search text
- Searches 80,000+ item names, including gear whose icon comes from its appearance
- Multi-word search: every word must match, in any order (`replica marshal silk`)
- Slot and type keywords work alongside names: `cloth shoulder`, `plate helm`, `sword 2h`, `dagger`, `cloak`
- Picks icons that aren't in Blizzard's normal icon list
- Works offline — the item database ships with the addon, no server queries
<!-- /peavers:features -->

## Usage

<!-- peavers:usage -->
1. Visit a transmogrifier and create (or right-click to edit) an outfit
2. Click the magnifier button next to the icon dropdown — it turns gold while a filter is active
3. Type an item name — e.g. `Thunderfury` — and/or tick item types; partial words work (`thunderf`), and you can mix name and slot words (`field marshal cloth shoulder`)
4. The icon grid filters to matching items' icons; click one and save
5. Clear the search to restore the full default icon grid
<!-- /peavers:usage -->

## Installation

### Recommended: PeaversUpdater

Download and install [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest), the desktop updater for the whole Peavers collection. It installs PeaversIconSearch together with its required dependencies and delivers updates before they reach CurseForge.

### Alternative: CurseForge

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaversiconsearch)
2. Ensure [PeaversCommons](https://www.curseforge.com/wow/addons/peaverscommons) is also installed
3. Ensure [PeaversConfig](https://www.curseforge.com/wow/addons/peaversconfig) is also installed
4. Enable the addon on the character selection screen

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversIconSearch/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*
