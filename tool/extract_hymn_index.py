"""Dump id, title, first two lines of stanza 1 for a language pack, one per line.

Usage: python3 -I tool/extract_hymn_index.py <en|yo>
Used to build assets/hymnal/pairs/yo_en.json by hand (content matching).
"""
import json
import sys

lang = sys.argv[1]
d = json.load(open(f"assets/hymnal/languages/{lang}.json"))
for hid, h in d["hymns"].items():
    st = (h.get("lyrics") or {}).get("stanzas") or []
    text = st[0]["text"] if st else ""
    first = " / ".join(text.split("\n")[:2])
    print(f"{hid[6:]}|{h.get('title', '')}|{first[:90]}")
