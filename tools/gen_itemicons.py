"""Generate src/Data/ItemIcons.lua from wago.tools db2 CSV exports.

Joins ItemSearchName (player-visible item names) with Item (IconFileDataID),
falling back to ItemModifiedAppearance -> ItemAppearance for equippable gear
whose icon comes from its appearance. Emits Lua chunks of
"iconFileID:Item Name<TAB>search tags" lines, sorted by name. The tags add
slot/armor-type words (e.g. "cloth shoulder", "plate helm", "sword 2h") so
gear is findable without knowing its exact name.

Usage: python gen_itemicons.py [build]
  build defaults to the latest retail build reported by wago.tools.
"""
import csv
import io
import json
import sys
import urllib.request
from pathlib import Path

CHUNK_LINES = 20000
OUT_FILE = Path(__file__).resolve().parent.parent / "src" / "Data" / "ItemIcons.lua"

ITEM_CLASS_WEAPON = 2
ITEM_CLASS_ARMOR = 4

ARMOR_SUBCLASS_TAGS = {
    1: "cloth",
    2: "leather",
    3: "mail",
    4: "plate",
    5: "cosmetic",
    6: "shield offhand",
}

# InventoryType -> slot words (with common synonyms)
SLOT_TAGS = {
    1: "head helm helmet",
    2: "neck necklace",
    3: "shoulder shoulders spaulders pauldrons",
    4: "shirt",
    5: "chest",
    6: "waist belt",
    7: "legs pants",
    8: "feet boots",
    9: "wrist bracers",
    10: "hands gloves gauntlets",
    11: "finger ring",
    12: "trinket",
    16: "back cloak cape",
    19: "tabard",
    20: "chest robe",
    23: "offhand held",
    28: "relic",
}

WEAPON_SUBCLASS_TAGS = {
    0: "axe 1h",
    1: "axe 2h",
    2: "bow ranged",
    3: "gun ranged",
    4: "mace 1h",
    5: "mace 2h",
    6: "polearm 2h",
    7: "sword 1h",
    8: "sword 2h",
    9: "warglaive",
    10: "staff 2h",
    13: "fist",
    15: "dagger",
    16: "thrown",
    18: "crossbow ranged",
    19: "wand",
    20: "fishing pole",
}


def build_tags(class_id, subclass_id, inventory_type):
    words = []
    if class_id == ITEM_CLASS_WEAPON:
        words.append(WEAPON_SUBCLASS_TAGS.get(subclass_id, "weapon"))
        words.append("weapon")
    elif class_id == ITEM_CLASS_ARMOR:
        armor = ARMOR_SUBCLASS_TAGS.get(subclass_id)
        if armor:
            words.append(armor)
        slot = SLOT_TAGS.get(inventory_type)
        if slot:
            words.append(slot)
    # Dedupe words while keeping order
    seen = set()
    out = []
    for word in " ".join(words).split():
        if word not in seen:
            seen.add(word)
            out.append(word)
    return " ".join(out)


def fetch(url):
    # wago.tools returns 403 for Python's default User-Agent
    request = urllib.request.Request(url, headers={"User-Agent": "PeaversIconSearch-generator"})
    with urllib.request.urlopen(request) as response:
        return response.read()


def fetch_csv(table, build):
    data = fetch(f"https://wago.tools/db2/{table}/csv?build={build}")
    return csv.DictReader(io.StringIO(data.decode("utf-8")))


def main():
    if len(sys.argv) > 1:
        build = sys.argv[1]
    else:
        builds = json.loads(fetch("https://wago.tools/api/builds"))
        build = builds["wow"][0]["version"]
    print(f"build: {build}")

    appearance_icons = {}
    for row in fetch_csv("ItemAppearance", build):
        icon = int(row["DefaultIconFileDataID"] or 0)
        if icon > 0:
            appearance_icons[int(row["ID"])] = icon

    # Lowest-OrderIndex appearance wins as the item's default look.
    item_appearance = {}
    for row in fetch_csv("ItemModifiedAppearance", build):
        item_id = int(row["ItemID"])
        order = int(row["OrderIndex"] or 0)
        icon = appearance_icons.get(int(row["ItemAppearanceID"]))
        if icon and (item_id not in item_appearance or order < item_appearance[item_id][0]):
            item_appearance[item_id] = (order, icon)

    icons = {}
    item_class = {}
    for row in fetch_csv("Item", build):
        item_id = int(row["ID"])
        item_class[item_id] = (
            int(row["ClassID"] or -1),
            int(row["SubclassID"] or -1),
            int(row["InventoryType"] or 0),
        )
        icon = int(row["IconFileDataID"] or 0)
        if icon > 0:
            icons[item_id] = icon
        elif item_id in item_appearance:
            icons[item_id] = item_appearance[item_id][1]

    entries = {}
    skipped_no_icon = 0
    for row in fetch_csv("ItemSearchName", build):
        name = (row["Display_lang"] or "").strip()
        if not name:
            continue
        item_id = int(row["ID"])
        icon = icons.get(item_id)
        if not icon:
            skipped_no_icon += 1
            continue
        name = " ".join(name.split())
        if "]==]" in name:
            sys.exit(f"name contains long-bracket terminator: {name!r}")
        class_id, subclass_id, inventory_type = item_class.get(item_id, (-1, -1, 0))
        tags = build_tags(class_id, subclass_id, inventory_type)
        # Same (name, icon) from several items: merge their tags
        key = (name, icon)
        if key in entries and entries[key]:
            merged = dict.fromkeys(entries[key].split() + tags.split())
            tags = " ".join(merged)
        entries[key] = tags

    rows = sorted(entries.items(), key=lambda e: (e[0][0].casefold(), e[0][1]))
    lines = [
        f"{icon}:{name}\t{tags}" if tags else f"{icon}:{name}"
        for (name, icon), tags in rows
    ]

    with open(OUT_FILE, "w", encoding="utf-8", newline="\n") as out:
        out.write(f"-- Auto-generated from wago.tools db2 exports (build {build}). Do not edit by hand.\n")
        out.write(f"-- {len(lines)} unique (name, icon) pairs. Regenerate with tools/gen_itemicons.py.\n")
        out.write("local _, PIS = ...\n\n")
        out.write("PIS.ItemIconData = PIS.ItemIconData or {}\n")
        out.write("local D = PIS.ItemIconData\n")
        for start in range(0, len(lines), CHUNK_LINES):
            chunk = "\n".join(lines[start:start + CHUNK_LINES])
            out.write("\nD[#D + 1] = [==[\n")
            out.write(chunk)
            out.write("]==]\n")

    print(f"entries={len(lines)} skipped_no_icon={skipped_no_icon} -> {OUT_FILE}")


if __name__ == "__main__":
    main()
