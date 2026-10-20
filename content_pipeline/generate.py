"""Roz ka AI content: date-aware German quotes + mausam quotes + photos -> site/feed.json

Usage:
  python pipeline/generate.py --root content            # kal ka din (+ aaj agar missing)
  python pipeline/generate.py --root content --ahead 3  # aaj se 3 din tak (pehla run)
  python pipeline/generate.py --root content --seed-photos
"""
import argparse, difflib, hashlib, json, os, re, sys
from datetime import date, datetime, timedelta, timezone

sys.path.insert(0, os.path.dirname(__file__))
from calendar_de import context  # noqa: E402
import llm  # noqa: E402
import photos as photo_step  # noqa: E402

MOODS = ["sonnenaufgang", "kaffee", "blumen", "rosen", "natur", "wald", "meer", "berge", "himmel",
         "nacht", "mond", "sterne", "kerzen", "regen", "schnee", "nebel", "herbst", "fruehling",
         "sommer", "winter", "feier", "herz"]

CATEGORIES = {  # id -> (count, default heading, beschreibung)
    "guten_morgen": (6, "Guten Morgen", "Guten-Morgen-Grüße zum Verschicken"),
    "gute_nacht": (6, "Gute Nacht", "Gute-Nacht-Grüße zum Verschicken"),
    "motivation": (5, "Gedanke des Tages", "kurze, ermutigende Lebensweisheiten (eigene, keine Zitate berühmter Personen)"),
    "wochentage": (3, None, "Grüße passend zum Wochentag"),
    "freundschaft": (2, "Für dich", "liebe Grüße an Freunde und Familie"),
}
DEFAULT_MOOD = {"guten_morgen": "sonnenaufgang", "gute_nacht": "nacht", "motivation": "berge",
                "wochentage": "kaffee", "freundschaft": "herz", "heute": "feier"}

WEATHER = {  # type -> (beschreibung, heading, mood)
    "sonne": ("strahlender Sonnenschein", "Sonnige Grüße", "himmel"),
    "wolken": ("grauer, bewölkter Himmel", "Grauer Tag? Kopf hoch!", "himmel"),
    "regen": ("Regenwetter", "Regenwetter-Gruß", "regen"),
    "schnee": ("Schnee", "Winterzauber", "schnee"),
    "nebel": ("Nebel", "Nebliger Gruß", "nebel"),
    "wind": ("Wind und Sturm", "Stürmische Grüße", "meer"),
    "hitze": ("große Hitze über 28 °C", "Heiße Grüße", "sommer"),
    "kaelte": ("Kälte und Frost", "Warme Grüße", "winter"),
}
WEATHER_PER_TYPE = 2
WEATHER_POOL_KEEP = 60
FEED_DAYS = 30

SYSTEM_WRITER = """Du bist Texterin für die App „Zitatecke: Sprüche & Grüße“.
Zielgruppe: Menschen in Deutschland, Österreich und der Schweiz, meist 40–75 Jahre, die liebe Grüße per WhatsApp an Familie und Freunde schicken.
Regeln:
- Natürliches, warmes, modernes Deutsch. Duzen („du“). Korrekte Rechtschreibung und Zeichensetzung, deutsche Anführungszeichen „…“.
- Jeder Spruch ist ORIGINAL (keine bekannten Zitate, keine Autorennamen, keine Liedtexte).
- 40 bis 170 Zeichen. Höchstens jeder dritte Spruch mit genau einem passenden Emoji am Ende.
- Abwechslungsreich: keine Floskel-Wiederholungen, unterschiedliche Satzanfänge, nicht jeder Spruch beginnt mit „Guten Morgen“.
- Positiv, herzlich, gerne mit leichtem Humor. Kein Kitsch-Überfluss, keine Politik, keine Religion außer bei religiösen Feiertagen (dann sanft), nichts Anzügliches, kein Alkohol als Pointe.
Antworte ausschließlich mit JSON."""

SYSTEM_CHECKER = """Du bist strenge Lektorin für deutsche Grußtexte. Prüfe jeden Spruch auf:
Rechtschreibung, Grammatik, natürliche Formulierung (klingt wie von einer Muttersprachlerin), Sinn, Länge (max. 180 Zeichen),
Originalität (kein bekanntes Zitat / Liedtext / Werbeslogan, keine Autorennamen), Angemessenheit (freundlich, nicht anzüglich, unpolitisch).
Kleine Fehler korrigierst du (fix). Unpassende, holprige oder unoriginelle Sprüche lehnst du ab (reject).
Antworte ausschließlich mit JSON."""


# ---------------- helpers ----------------

def norm(t):
    t = t.lower().replace("ß", "ss")
    return re.sub(r"[^a-zäöü0-9 ]", "", re.sub(r"\s+", " ", t)).strip()


def too_similar(text, pool, thr=0.82):
    n = norm(text)
    for p in pool:
        if n == p or difflib.SequenceMatcher(None, n, p).ratio() >= thr:
            return True
    return False


def load_archive(root):
    p = os.path.join(root, "data", "archive.json")
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    return {"days": {}, "weather": {k: [] for k in WEATHER}, "photos": []}


def save_archive(root, a):
    os.makedirs(os.path.join(root, "data"), exist_ok=True)
    json.dump(a, open(os.path.join(root, "data", "archive.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)


def recent_texts(a, limit=400):
    out = []
    for d in sorted(a["days"], reverse=True):
        out += [q["text"] for q in a["days"][d]["quotes"]]
        if len(out) >= limit:
            break
    for items in a["weather"].values():
        out += [w["text"] for w in items[:20]]
    return out


# ---------------- generation ----------------

def build_prompt(ctx, avoid):
    cats = []
    for cid, (n, _, desc) in CATEGORIES.items():
        extra = f" (passend zum {ctx['weekday']})" if cid == "wochentage" else ""
        cats.append(f'- "{cid}": {n} Sprüche – {desc}{extra}')
    if ctx["special"]:
        s = ctx["special"]
        cats.append(f'- "heute": 4 Sprüche zum Anlass „{s["name"]}“ (Ton: {s["tone"]})')
    weather = "\n".join(f'- "{k}": {WEATHER_PER_TYPE} Sprüche für {v[0]}' for k, v in WEATHER.items())
    special = f'Besonderer Tag: {ctx["special"]["name"]}.' if ctx["special"] else "Kein besonderer Feiertag."
    avoid_txt = "\n".join(f"- {t}" for t in avoid[:120])
    return f"""TASK: generate
Datum: {ctx['pretty']} · Jahreszeit: {ctx['season']} · {special}
Beziehe Wochentag und Jahreszeit natürlich mit ein, wo es passt (nicht in jedem Spruch).

Schreibe Sprüche für diese Kategorien:
{chr(10).join(cats)}

Und Wetter-Sprüche (unabhängig vom Datum, aber zur Jahreszeit passend wo sinnvoll):
{weather}

Für jeden Spruch: "heading" = kurze Überschrift für die Grußkarte (2–4 Wörter, z. B. „Guten Morgen“, „Schönen {ctx['weekday']}“, „Gute Nacht“),
"mood" = genau eines von: {", ".join(MOODS)} (passendes Hintergrundbild).

Diese Sprüche gab es schon – NICHT wiederholen oder ähnlich formulieren:
{avoid_txt}

JSON-Format:
{{"quotes":[{{"category":"guten_morgen","text":"…","heading":"…","mood":"sonnenaufgang"}}],
 "weather":[{{"type":"regen","text":"…","heading":"…","mood":"regen"}}]}}"""


def review(items):
    """items: list of dicts with 'text'. Returns filtered list (texts possibly fixed)."""
    if not items:
        return items
    listing = "\n".join(f"{i}: {it['text']}" for i, it in enumerate(items))
    res = llm.ask_json(SYSTEM_CHECKER, f"""TASK: review
Prüfe diese {len(items)} Sprüche:
{listing}

JSON-Format: {{"reject":[{{"i":3,"reason":"…"}}], "fix":[{{"i":5,"text":"korrigierter Spruch"}}]}}
Nur Sprüche mit Problemen auflisten.""", role="checker", temperature=0.2)
    rejected = {int(r["i"]) for r in res.get("reject", []) if str(r.get("i", "")).isdigit() or isinstance(r.get("i"), int)}
    for r in res.get("reject", []):
        print("  reject:", r)
    for f in res.get("fix", []):
        try:
            i = int(f["i"])
            if 0 <= i < len(items) and i not in rejected and 20 <= len(f["text"]) <= 200:
                print(f"  fix {i}: {items[i]['text']}  ->  {f['text']}")
                items[i]["text"] = f["text"].strip()
        except (KeyError, ValueError, TypeError):
            pass
    return [it for i, it in enumerate(items) if i not in rejected]


def clean_text(t):
    t = t.strip().strip('"').strip()
    t = re.sub(r"\s+", " ", t)
    return t


def generate_day(a, d: date):
    ctx = context(d)
    print(f"== {ctx['pretty']}  special={ctx['special']}")
    avoid = recent_texts(a)
    data = llm.ask_json(SYSTEM_WRITER, build_prompt(ctx, avoid), role="writer", temperature=0.95)

    pool = [norm(t) for t in avoid]
    allowed = set(CATEGORIES) | ({"heute"} if ctx["special"] else set())
    quotes, weather = [], []
    for q in data.get("quotes", []):
        cat, text = q.get("category"), clean_text(q.get("text", ""))
        if cat not in allowed or not (25 <= len(text) <= 200) or too_similar(text, pool):
            print("  drop:", cat, text[:60])
            continue
        pool.append(norm(text))
        mood = q.get("mood") if q.get("mood") in MOODS else DEFAULT_MOOD[cat]
        quotes.append({"category": cat, "text": text, "heading": (q.get("heading") or "").strip()[:40], "mood": mood})
    for w in data.get("weather", []):
        typ, text = w.get("type"), clean_text(w.get("text", ""))
        if typ not in WEATHER or not (25 <= len(text) <= 200) or too_similar(text, pool):
            print("  drop weather:", typ, text[:60])
            continue
        pool.append(norm(text))
        mood = w.get("mood") if w.get("mood") in MOODS else WEATHER[typ][2]
        weather.append({"type": typ, "text": text, "heading": (w.get("heading") or "").strip()[:40], "mood": mood})

    checked = review(quotes + weather)
    quotes = [x for x in checked if "category" in x]
    weather = [x for x in checked if "type" in x]

    stamp = d.strftime("%Y%m%d")
    counters = {}
    day_quotes = []
    for q in quotes:
        c = q["category"]
        counters[c] = counters.get(c, 0) + 1
        item = {
            "id": f"ai{stamp}_{c}_{counters[c]}",
            "category": c,
            "text": q["text"],
            "heading": q["heading"] or default_heading(c, ctx),
            "mood": q["mood"],
            "date": d.isoformat(),
        }
        if c == "wochentage":
            item["tag"] = ctx["weekday_tag"]
        day_quotes.append(item)
    a["days"][d.isoformat()] = {
        "date": d.isoformat(),
        "special": None if not ctx["special"] else {"name": ctx["special"]["name"], "heading": ctx["special"]["heading"]},
        "quotes": day_quotes,
    }
    for i, w in enumerate(weather):
        a["weather"].setdefault(w["type"], [])
        a["weather"][w["type"]].insert(0, {
            "id": f"aiw{stamp}_{w['type']}_{i}",
            "text": w["text"],
            "heading": w["heading"] or WEATHER[w["type"]][1],
            "mood": w["mood"],
            "date": d.isoformat(),
        })
        a["weather"][w["type"]] = a["weather"][w["type"]][:WEATHER_POOL_KEEP]
    print(f"   saved {len(day_quotes)} quotes, {len(weather)} weather")


def default_heading(cat, ctx):
    if cat == "wochentage":
        return f"Schönen {ctx['weekday']}"
    if cat == "heute" and ctx["special"]:
        return ctx["special"]["heading"]
    return CATEGORIES.get(cat, (0, "Für dich"))[1] or "Für dich"


# ---------------- feed ----------------

def build_feed(root, a, today: date):
    site = os.path.join(root, "site")
    os.makedirs(site, exist_ok=True)
    keep_from = (today - timedelta(days=FEED_DAYS)).isoformat()
    days = {k: v for k, v in a["days"].items() if k >= keep_from}
    feed = {
        "version": 1,
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "days": days,
        "weather": {k: v[:30] for k, v in a["weather"].items()},
        "photos": [{k: p[k] for k in ("id", "file", "tags", "dim")} for p in a["photos"][:200]],
    }
    with open(os.path.join(site, "feed.json"), "w", encoding="utf-8") as f:
        json.dump(feed, f, ensure_ascii=False, separators=(",", ":"))
    write_landing(site)
    write_legal(site)
    # alte Fotos vom Server entfernen (nur die neuesten 200 bleiben)
    keep = {p["file"] for p in a["photos"][:200]}
    pdir = os.path.join(site, "photos")
    if os.path.isdir(pdir):
        for fn in os.listdir(pdir):
            if f"photos/{fn}" not in keep:
                os.remove(os.path.join(pdir, fn))
    print(f"feed: {len(days)} days, {sum(len(v['quotes']) for v in days.values())} quotes, "
          f"{sum(len(v) for v in feed['weather'].values())} weather, {len(feed['photos'])} photos")


def write_landing(site):
    """Landing page (index.html + img/) für zitatecke.moezzadigital.com."""
    import shutil
    here = os.path.dirname(os.path.abspath(__file__))
    src = os.path.join(here, "landing")
    page = open(os.path.join(src, "index.html"), encoding="utf-8").read()
    head, _, body = page.partition("<!--BODY-->")
    html_doc = ('<!doctype html>\n<html lang="de">\n<head>\n<meta charset="utf-8">\n'
                '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
                + head + '\n</head>\n<body>\n' + body + '\n</body>\n</html>\n')
    with open(os.path.join(site, "index.html"), "w", encoding="utf-8") as f:
        f.write(html_doc)
    dst = os.path.join(site, "img")
    if os.path.isdir(dst):
        shutil.rmtree(dst)
    shutil.copytree(os.path.join(src, "img"), dst)
    print("landing: index.html")


def write_legal(site):
    """Datenschutz + Impressum (Play Store braucht die URL). Nur wenn legal.json ausgefüllt ist."""
    here = os.path.dirname(os.path.abspath(__file__))
    try:
        cfg = json.load(open(os.path.join(here, "legal.json"), encoding="utf-8"))
    except Exception as e:
        print("legal: skip", e)
        return
    if not (cfg.get("NAME") and cfg.get("ADDRESS") and cfg.get("EMAIL")):
        print("legal: legal.json noch leer – Seiten nicht geschrieben")
        return
    import html
    css = open(os.path.join(here, "legal", "_style.css"), encoding="utf-8").read()
    vals = {k: html.escape(str(v)) for k, v in cfg.items()}
    vals["ADDRESS"] = "<br>".join(html.escape(x.strip()) for x in str(cfg["ADDRESS"]).split(","))
    vals["PHONE_LINE"] = f"<br>Telefon: {html.escape(cfg['PHONE'])}" if cfg.get("PHONE") else ""
    vals["CSS"] = css
    for name in ("datenschutz.html", "impressum.html"):
        t = open(os.path.join(here, "legal", name), encoding="utf-8").read()
        for k, v in vals.items():
            t = t.replace("{{" + k + "}}", v)
        with open(os.path.join(site, name), "w", encoding="utf-8") as f:
            f.write(t)
    print("legal: datenschutz.html + impressum.html")


def berlin_today():
    # Europe/Berlin ohne extra Pakete: UTC+1 (Winter) / UTC+2 (Sommer) – reicht für das Datum.
    now = datetime.now(timezone.utc)
    y = now.year
    def last_sunday(m):
        d = date(y, m, 31)
        return d - timedelta(days=(d.weekday() + 1) % 7)
    dst = last_sunday(3) <= now.date() < last_sunday(10)
    return (now + timedelta(hours=2 if dst else 1)).date()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="content")
    ap.add_argument("--ahead", type=int, default=1, help="kitne din aage tak (1 = kal)")
    ap.add_argument("--seed-photos", action="store_true")
    ap.add_argument("--no-photos", action="store_true")
    args = ap.parse_args()

    a = load_archive(args.root)
    today = berlin_today()
    targets = [today + timedelta(days=i) for i in range(0, args.ahead + 1)]
    for d in targets:
        if d.isoformat() in a["days"] and a["days"][d.isoformat()]["quotes"]:
            print("skip (already have):", d)
            continue
        try:
            generate_day(a, d)
            save_archive(args.root, a)
        except Exception as e:  # ek din fail ho to baaki chalein
            print(f"!! generation failed for {d}: {e}")

    if not args.no_photos:
        try:
            photo_step.run(a, args.root, seed=args.seed_photos, day=today)
        except Exception as e:
            print(f"!! photos failed: {e}")
        save_archive(args.root, a)

    build_feed(args.root, a, today)


if __name__ == "__main__":
    main()
