"""Free photos (CC0 / Public Domain via Openverse) dhoondho, AI se check karwao, tag lagao."""
import hashlib, json, os, urllib.parse, urllib.request
from datetime import date
from io import BytesIO

import llm

THEMES = [  # (search query, moods)
    ("coffee cup morning", ["kaffee"]),
    ("rain window drops", ["regen"]),
    ("umbrella rain street", ["regen"]),
    ("foggy forest morning", ["nebel", "wald"]),
    ("autumn leaves", ["herbst"]),
    ("candles cozy", ["kerzen"]),
    ("snow landscape", ["schnee", "winter"]),
    ("sunrise landscape", ["sonnenaufgang"]),
    ("red roses", ["rosen", "herz"]),
    ("wildflowers meadow", ["blumen", "natur"]),
    ("full moon", ["mond", "nacht"]),
    ("starry night sky", ["sterne", "nacht"]),
    ("sea waves beach", ["meer", "sommer"]),
    ("mountain landscape", ["berge"]),
    ("spring blossom tree", ["fruehling", "blumen"]),
    ("summer field sun", ["sommer", "natur"]),
    ("forest light", ["wald", "natur"]),
    ("blue sky clouds", ["himmel"]),
    ("christmas candles", ["kerzen", "winter"]),
    ("sunset lake", ["himmel", "meer"]),
]
PER_THEME = 6
DAILY_THEMES = 2
MAX_APPROVE_PER_THEME = 3
UA = {"User-Agent": "Mozilla/5.0 (ZitateckeBot; +https://zitatecke.de)"}

SYSTEM_PHOTO = """Du prüfst Fotos als Hintergrund für Grußkarten (weißer Text liegt darüber).
Akzeptiere nur schöne, scharfe, stimmungsvolle Naturfotos/Stillleben.
Lehne ab: erkennbare Personen/Gesichter, Text/Schrift/Schilder/Wasserzeichen, Logos/Marken, Comic/Zeichentrick/Gemälde,
Tiere im Mittelpunkt, unscharf/verrauscht/schief, düster-traurig, unordentlich, Collagen, Screenshots.
Antworte ausschließlich mit JSON."""


def _get(url, headers=None, timeout=40):
    req = urllib.request.Request(url, headers=headers or UA)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def _openverse(query):
    url = "https://api.openverse.org/v1/images/?" + urllib.parse.urlencode(
        {"q": query, "license": "cc0,pdm", "page_size": 30, "mature": "false"})
    data = json.loads(_get(url, {**UA, "Accept": "application/json"}))
    return data.get("results", [])


def _square(img, size):
    from PIL import Image
    w, h = img.size
    s = min(w, h)
    img = img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
    return img.resize((size, size), Image.LANCZOS)


def _candidates(theme, known_sources):
    from PIL import Image
    query, moods = theme
    out = []
    for r in _openverse(query):
        if len(out) >= PER_THEME:
            break
        src = r.get("url")
        if not src or src in known_sources:
            continue
        if (r.get("width") or 0) < 900 or (r.get("height") or 0) < 700:
            continue
        try:
            img = Image.open(BytesIO(_get(src, timeout=60))).convert("RGB")
        except Exception as e:
            print("   skip download:", e)
            continue
        if min(img.size) < 700:
            continue
        big = _square(img, 1080)
        thumb = BytesIO()
        _square(img, 384).save(thumb, "JPEG", quality=80)
        out.append({"src": src, "page": r.get("foreign_landing_url", ""), "credit": r.get("creator") or "",
                    "license": (r.get("license") or "cc0").upper(), "moods": moods,
                    "big": big, "thumb": thumb.getvalue()})
    return out


def _review(cands):
    if not cands:
        return []
    listing = "\n".join(f"Bild {i}: gesucht für Stimmung „{', '.join(c['moods'])}“" for i, c in enumerate(cands))
    res = llm.ask_json(SYSTEM_PHOTO, f"""TASK: photos
Die {len(cands)} Bilder sind in Reihenfolge angehängt (Bild 0, Bild 1, …).
{listing}

Für jedes Bild: ok (true/false), score (1–10, wie schön als Grußkarten-Hintergrund),
tags (1–3 aus: sonnenaufgang, kaffee, blumen, rosen, natur, wald, meer, berge, himmel, nacht, mond, sterne, kerzen, regen, schnee, nebel, herbst, fruehling, sommer, winter, feier, herz),
dim (0.0–0.3: wie stark abdunkeln, damit weißer Text gut lesbar ist; helle Bilder höher).
JSON: {{"photos":[{{"i":0,"ok":true,"score":8,"tags":["kaffee"],"dim":0.1}}]}}""",
                       images=[c["thumb"] for c in cands], role="checker", temperature=0.1)
    return res.get("photos", [])


def run(a, root, seed=False, day=None):
    day = day or date.today()
    known = {p.get("source") for p in a["photos"]}
    if seed:
        themes = THEMES
    else:
        start = (day.toordinal() * DAILY_THEMES) % len(THEMES)
        themes = [THEMES[(start + i) % len(THEMES)] for i in range(DAILY_THEMES)]
    pdir = os.path.join(root, "site", "photos")
    os.makedirs(pdir, exist_ok=True)

    # 2 themes ek saath ek AI request mein (free limit bachane ke liye)
    for k in range(0, len(themes), 2):
        batch = []
        for th in themes[k:k + 2]:
            print(f"photos: {th[0]}")
            try:
                cs = _candidates(th, known)
                batch += cs
            except Exception as e:
                print("   openverse failed:", e)
        verdicts = _review(batch)
        approved_per_theme = {}
        for v in sorted(verdicts, key=lambda v: -int(v.get("score", 0) or 0)):
            try:
                c = batch[int(v["i"])]
            except (KeyError, ValueError, IndexError, TypeError):
                continue
            key = tuple(c["moods"])
            if not v.get("ok") or int(v.get("score", 0) or 0) < 7:
                continue
            if approved_per_theme.get(key, 0) >= MAX_APPROVE_PER_THEME:
                continue
            tags = [t for t in (v.get("tags") or []) if t in ALLOWED_TAGS] or c["moods"]
            for m in c["moods"]:
                if m not in tags:
                    tags.append(m)
            pid = "ph_" + hashlib.sha1(c["src"].encode()).hexdigest()[:10]
            c["big"].save(os.path.join(pdir, f"{pid}.jpg"), "JPEG", quality=78, optimize=True, progressive=True)
            dim = max(0.0, min(0.3, float(v.get("dim", 0.1) or 0.1)))
            a["photos"].insert(0, {"id": pid, "file": f"photos/{pid}.jpg", "tags": tags[:4], "dim": round(dim, 2),
                                   "source": c["src"], "page": c["page"], "credit": c["credit"],
                                   "license": c["license"], "added": day.isoformat()})
            known.add(c["src"])
            approved_per_theme[key] = approved_per_theme.get(key, 0) + 1
            print(f"   + {pid} {tags} score={v.get('score')}")


ALLOWED_TAGS = {"sonnenaufgang", "kaffee", "blumen", "rosen", "natur", "wald", "meer", "berge", "himmel",
                "nacht", "mond", "sterne", "kerzen", "regen", "schnee", "nebel", "herbst", "fruehling",
                "sommer", "winter", "feier", "herz"}
