"""Candidate background photos (Unsplash License, free) downloaden.
GitHub Actions mein chalta hai; result 'photos' branch pe jaata hai.
"""
import json, os, sys, time, urllib.parse, urllib.request
from io import BytesIO
from PIL import Image, ImageDraw

QUERIES = {
    "morgen": ["sunrise meadow", "coffee cup morning light", "flowers morning dew", "sunflower field"],
    "nacht": ["starry night sky", "full moon night", "candle cozy evening"],
    "motivation": ["mountain peak sunrise", "calm ocean horizon", "forest path sunlight"],
    "blumen": ["pink roses", "tulips bouquet", "lavender field"],
    "geburtstag": ["birthday cake candles", "colorful balloons"],
    "winter": ["christmas lights bokeh", "snowy winter forest"],
    "fruehling": ["cherry blossom spring", "easter eggs pastel"],
    "sommer": ["summer beach", "lake sunset"],
}
PER_QUERY = 4
OUT = sys.argv[1] if len(sys.argv) > 1 else "photos_out"
os.makedirs(OUT, exist_ok=True)
UA = {"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/124 Safari/537.36",
      "Accept": "application/json"}


def get(url, headers=UA):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=40) as r:
        return r.read()


def unsplash(q):
    url = "https://unsplash.com/napi/search/photos?" + urllib.parse.urlencode(
        {"query": q, "per_page": 30, "orientation": "squarish"})
    data = json.loads(get(url))
    out = []
    for r in data.get("results", []):
        raw = r.get("urls", {}).get("raw", "")
        if r.get("premium") or r.get("plus") or "plus.unsplash.com" in raw:
            continue
        out.append({
            "src": raw + "&w=1080&h=1080&fit=crop&crop=entropy&q=80&fm=jpg",
            "credit": r.get("user", {}).get("name", ""),
            "page": r.get("links", {}).get("html", ""),
            "license": "Unsplash License",
        })
    return out


def openverse(q):
    url = "https://api.openverse.org/v1/images/?" + urllib.parse.urlencode(
        {"q": q, "license": "cc0,pdm", "page_size": 20, "aspect_ratio": "square,wide"})
    data = json.loads(get(url))
    return [{"src": r["url"], "credit": r.get("creator") or "", "page": r.get("foreign_landing_url", ""),
             "license": r.get("license", "cc0").upper()} for r in data.get("results", [])]


def square(img, size=1080):
    w, h = img.size
    s = min(w, h)
    img = img.crop(((w - s) // 2, (h - s) // 2, (w - s) // 2 + s, (h - s) // 2 + s))
    return img.resize((size, size), Image.LANCZOS)


credits = []
thumbs = []
for theme, qs in QUERIES.items():
    for q in qs:
        cands = []
        for fn in (unsplash, openverse):
            try:
                cands = fn(q)
                if cands:
                    print(f"{q}: {len(cands)} via {fn.__name__}")
                    break
            except Exception as e:
                print(f"{q}: {fn.__name__} failed: {e}")
        n = 0
        for c in cands:
            if n >= PER_QUERY:
                break
            try:
                img = Image.open(BytesIO(get(c["src"], {"User-Agent": UA["User-Agent"]}))).convert("RGB")
                if min(img.size) < 700:
                    continue
                img = square(img)
                name = f"{theme}_{q.replace(' ', '-')}_{n}.jpg"
                img.save(os.path.join(OUT, name), quality=82, optimize=True)
                credits.append({"file": name, **c})
                thumbs.append((name, img.resize((220, 220))))
                n += 1
            except Exception as e:
                print("  skip:", e)
            time.sleep(0.3)

json.dump(credits, open(os.path.join(OUT, "credits.json"), "w"), indent=1, ensure_ascii=False)

cols = 6
rows = (len(thumbs) + cols - 1) // cols
sheet = Image.new("RGB", (cols * 230, max(1, rows) * 250), "white")
d = ImageDraw.Draw(sheet)
for i, (name, t) in enumerate(thumbs):
    x, y = (i % cols) * 230 + 5, (i // cols) * 250 + 5
    sheet.paste(t, (x, y))
    d.text((x, y + 223), f"{i}: {name[:30]}", fill="black")
sheet.save(os.path.join(OUT, "_sheet.jpg"), quality=80)
with open(os.path.join(OUT, "_index.txt"), "w") as f:
    for i, (name, _) in enumerate(thumbs):
        f.write(f"{i} {name}\n")
print("total", len(thumbs))
