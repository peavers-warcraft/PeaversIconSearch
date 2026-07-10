# PeaversIconSearch

Adds an item search box to the transmog outfit icon picker.

When you create or edit a transmog outfit, Blizzard's icon picker offers thousands of icons with no way to search them. PeaversIconSearch adds a search box next to the icon filter dropdown: type an item's name and the icon grid filters down to the icons of matching items. Click one, and it becomes the outfit's icon — even if it isn't part of Blizzard's normal icon list.

## Features

- A single magnifier button in the outfit create/edit popup opens the search menu; the icon turns gold while a filter is active
- The menu holds a search box plus multi-select item type checkboxes (Armor slots and Weapon types — e.g. Shoulders + Dagger) that combine with the search text
- Searches 80,000+ item names, including gear whose icon comes from its appearance
- Multi-word search: every word must match, in any order (`replica marshal silk`)
- Slot and type keywords work alongside names: `cloth shoulder`, `plate helm`, `leather belt`, `sword 2h`, `dagger`, `cloak`
- Works offline — the item database ships with the addon, no server queries
- Clearing the search restores the full default icon grid

## Usage

1. Visit a transmogrifier and create (or right-click to edit) an outfit
2. Click the magnifier button next to the icon dropdown
3. Type an item name — e.g. `Thunderfury` — and/or tick item types; partial words work (`thunderf`), and you can mix name and slot words (`field marshal cloth shoulder`)
4. The icon grid filters to matching items' icons; click one and save

## The item database

The item database ships with the [PeaversIconSearchData](https://github.com/peavers-warcraft/PeaversIconSearchData) dependency. It is generated from Blizzard's client database (via [wago.tools](https://wago.tools) db2 exports) by joining `ItemSearchName`, `Item`, `ItemModifiedAppearance`, and `ItemAppearance`, and refreshed daily against the latest retail build by the `iconsearch-module` Lambda in PeaversAddonDataSupplier.
