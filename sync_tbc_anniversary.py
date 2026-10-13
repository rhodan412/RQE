"""Copy BurningCrusade quests into BurningCrusadeAnniversary.

The Retail BurningCrusade table is read only. Existing Anniversary-only quests
remain byte for byte unchanged; a copied quest replaces an Anniversary quest
with the same ID. Coordinate tags in copied step descriptions receive the zone ID map;
the count of Anniversary quests with coordOrder routes is printed.
Run with --dry-run to inspect counts without changing RQEDatabase.lua.
"""

import argparse
import os
from pathlib import Path
import re
import sys
import tempfile


SOURCE_TABLE = b"BurningCrusade"
TARGET_TABLE = b"BurningCrusadeAnniversary"
MAP_IDS = {
    94: 1941, 95: 1942, 97: 1943, 100: 1944, 102: 1946,
    103: 1947, 104: 1948, 105: 1949, 106: 1950, 107: 1951,
    108: 1952, 109: 1953, 110: 1954, 111: 1955, 122: 1957,
}
CONTINENT_IDS = {101: 1945}

TABLE_CLOSE = re.compile(rb"(?m)^\t\},[ \t]*\r?$")
QUEST_OPEN = re.compile(rb"(?m)^\t\t\[(\d+)\][ \t]*=[ \t]*\{[^\r\n]*\r?$")
QUEST_CLOSE = re.compile(rb"(?m)^\t\t\},[ \t]*\r?$")
MAP_FIELD = re.compile(rb"\bmapID([ \t]*=[ \t]*)(\d+)\b")
CONTINENT_FIELD = re.compile(rb"\bcontinentID([ \t]*=[ \t]*)(\d+)\b")
STEP_OPEN = re.compile(rb"^\t\t\t\[(\d+)\][ \t]*=[ \t]*\{")
STEP_DESCRIPTION = re.compile(rb"^[ \t]*description[ \t]*=")
INLINE_COORD_MAP_ID = re.compile(
    rb"(\{(?:coords|coordblock):[ \t]*"
    rb"[+-]?(?:\d+(?:\.\d*)?|\.\d+)[ \t]*,"
    rb"[ \t]*[+-]?(?:\d+(?:\.\d*)?|\.\d+)[ \t]*,"
    rb"[ \t]*)(\d+)(?=;)"
)
COORDINATE_FIELD = re.compile(
    rb"^[ \t]*(?:--[ \t]*)?(?:location|locations|coordinates|coordinateHotspots|coordOrder)[ \t]*=[ \t]*\{"
)
COORD_ORDER_FIELD = re.compile(rb"(?m)^[ \t]*coordOrder[ \t]*=[ \t]*\{")


def line_end(data, position):
    end = data.find(b"\n", position)
    return len(data) if end < 0 else end + 1


def table_body_bounds(data, table_name):
    opening = re.compile(
        rb"(?m)^\t" + re.escape(table_name) + rb"[ \t]*=[ \t]*\{[ \t]*\r?$"
    )
    matches = list(opening.finditer(data))
    if len(matches) != 1:
        raise ValueError(f"Expected one {table_name.decode()} table, found {len(matches)}")
    body_start = line_end(data, matches[0].end())
    closing = TABLE_CLOSE.search(data, body_start)
    if closing is None:
        raise ValueError(f"Could not find the end of {table_name.decode()}")
    return body_start, closing.start()


def quest_entries(body, table_name):
    """Return (quest ID, start, end) for the two-tab outer quest entries."""
    openings = list(QUEST_OPEN.finditer(body))
    entries = []
    for index, opening in enumerate(openings):
        following_start = openings[index + 1].start() if index + 1 < len(openings) else len(body)
        closing = QUEST_CLOSE.search(body, opening.end(), following_start)
        if closing is None:
            quest_id = int(opening.group(1))
            raise ValueError(f"Quest {quest_id} in {table_name.decode()} has no two-tab closing line")
        entries.append((int(opening.group(1)), opening.start(), line_end(body, closing.end())))
    if len({quest_id for quest_id, _, _ in entries}) != len(entries):
        raise ValueError(f"{table_name.decode()} already contains duplicate quest IDs")
    return entries


def remap_fields(entry):
    def replace_map(match):
        old = int(match.group(2))
        new = MAP_IDS.get(old, old)
        return b"mapID" + match.group(1) + str(new).encode("ascii")

    def replace_continent(match):
        old = int(match.group(2))
        new = CONTINENT_IDS.get(old, old)
        return b"continentID" + match.group(1) + str(new).encode("ascii")

    def replace_inline_map(match):
        old = int(match.group(2))
        new = MAP_IDS.get(old, old)
        return match.group(1) + str(new).encode("ascii")

    lines = []
    coordinate_braces = 0
    step_number = None
    for line in entry.splitlines(keepends=True):
        step_open = STEP_OPEN.match(line)
        if step_open:
            step_number = int(step_open.group(1))
        elif line.startswith(b"\t\t\t},"):
            step_number = None

        starts_coordinates = COORDINATE_FIELD.match(line) is not None
        if starts_coordinates or coordinate_braces > 0:
            line = CONTINENT_FIELD.sub(replace_continent, MAP_FIELD.sub(replace_map, line))
            coordinate_braces += line.count(b"{") - line.count(b"}")
            if coordinate_braces < 0:
                raise ValueError("Coordinate block has an unmatched closing brace")
        if step_number is not None and STEP_DESCRIPTION.match(line):
            line = INLINE_COORD_MAP_ID.sub(replace_inline_map, line)
        lines.append(line)
    if coordinate_braces:
        raise ValueError("Coordinate block has an unmatched opening brace")
    return b"".join(lines)


def merge_tables(data):
    source_start, source_end = table_body_bounds(data, SOURCE_TABLE)
    target_start, target_end = table_body_bounds(data, TARGET_TABLE)
    if source_end >= target_start:
        raise ValueError("The Burning Crusade tables are not in the expected order")

    source_body = data[source_start:source_end]
    target_body = data[target_start:target_end]
    source_entries = quest_entries(source_body, SOURCE_TABLE)
    target_entries = quest_entries(target_body, TARGET_TABLE)
    if not source_entries:
        raise ValueError("BurningCrusade has no quest entries to copy")

    source_ids = {quest_id for quest_id, _, _ in source_entries}
    target_ids = {quest_id for quest_id, _, _ in target_entries}
    pieces = []
    cursor = 0
    for quest_id, start, end in target_entries:
        pieces.append(target_body[cursor:start])
        if quest_id not in source_ids:
            pieces.append(target_body[start:end])
        cursor = end
    pieces.append(target_body[cursor:])
    pieces.extend(remap_fields(source_body[start:end]) for _, start, end in source_entries)
    merged_body = b"".join(pieces)

    merged_entries = quest_entries(merged_body, TARGET_TABLE)
    if len(merged_entries) != len(source_ids | target_ids):
        raise ValueError("Merged Anniversary quest count does not match the unique IDs")

    flagged = sorted(
        quest_id
        for quest_id, start, end in merged_entries
        if COORD_ORDER_FIELD.search(merged_body, start, end)
    )
    updated_data = data[:target_start] + merged_body + data[target_end:]
    return updated_data, flagged, len(source_entries), len(target_ids - source_ids), len(source_ids & target_ids)


def write_if_changed(path, content):
    if path.exists() and path.read_bytes() == content:
        return False
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(content)
        os.replace(temporary_name, path)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="show counts without changing files")
    args = parser.parse_args()
    addon_folder = Path(__file__).resolve().parent
    database_path = addon_folder / "RQEDatabase.lua"

    try:
        before = database_path.stat()
        original = database_path.read_bytes()
        updated, flagged, copied, preserved, replaced = merge_tables(original)

        print(f"Source quests: {copied}; Anniversary-only quests preserved: {preserved}; "
              f"matching Anniversary quests replaced: {replaced}; coordOrder quests flagged: {len(flagged)}")
        if args.dry_run:
            print("Dry run: no files changed")
            return 0

        current = database_path.stat()
        if (current.st_size, current.st_mtime_ns) != (before.st_size, before.st_mtime_ns):
            raise ValueError("RQEDatabase.lua changed while the script was reading it; run again")
        database_changed = write_if_changed(database_path, updated)
        print(f"RQEDatabase.lua: {'updated' if database_changed else 'already current'}")
        return 0
    except (OSError, ValueError) as error:
        print(f"Sync failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
