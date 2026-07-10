# PeaversIconSearch

Adds an item search box to the transmog outfit icon picker.

When you create or edit a transmog outfit, Blizzard's icon picker offers thousands of icons with no way to search them. PeaversIconSearch adds a search box next to the icon filter dropdown: type an item's name and the icon grid filters down to the icons of matching items. Click one, and it becomes the outfit's icon — even if it isn't part of Blizzard's normal icon list.

## Features

- Search box in the outfit create/edit popup at the transmogrifier
- Searches 80,000+ item names, including gear whose icon comes from its appearance
- Multi-word search: every word must match, in any order (`replica marshal silk`)
- Slot and type keywords work alongside names: `cloth shoulder`, `plate helm`, `leather belt`, `sword 2h`, `dagger`, `cloak`
- Works offline — the item database ships with the addon, no server queries
- Clearing the search restores the full default icon grid

## Usage

1. Visit a transmogrifier and create (or right-click to edit) an outfit
2. Type an item name — e.g. `Thunderfury` — into the search box; partial words work (`thunderf`), and you can mix name and slot words (`field marshal cloth shoulder`)
3. The icon grid filters to matching items' icons; click one and save

## Regenerating the item database

`src/Data/ItemIcons.lua` is generated from Blizzard's client database (via [wago.tools](https://wago.tools) db2 exports) by joining `ItemSearchName`, `Item`, `ItemModifiedAppearance`, and `ItemAppearance`. Regenerate it for a new game build with the `gen_itemicons.py` script (see file header).
