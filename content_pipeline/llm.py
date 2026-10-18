"""AI provider wrapper. Abhi Google Gemini (free), baad mein Claude.

Provider choose hota hai is hisaab se:
  - env LLM_PROVIDER = "gemini" ya "anthropic" (agar set ho)
  - warna: ANTHROPIC_API_KEY ho to Claude, nahi to GEMINI_API_KEY se Gemini.
"""
import base64, json, os, re, time, urllib.error, urllib.request

ANTHROPIC_MODELS = {"writer": "claude-sonnet-5-5", "checker": "claude-haiku-5-5"}
GEMINI_PREFERENCE = [  # pehla jo available ho
    r"^gemini-[\d.]+-flash$",
    r"^gemini-[\d.]+-flash-latest$",
    r"^gemini-flash-latest$",
    r"^gemini-[\d.]+-flash-lite$",
    r"^gemini-flash-lite-latest$",
]


def provider() -> str:
    p = os.environ.get("LLM_PROVIDER", "").strip().lower()
    if p:
        return p
    if os.environ.get("ANTHROPIC_API_KEY"):
        return "anthropic"
    if os.environ.get("GEMINI_API_KEY"):
        return "gemini"
    raise SystemExit("Koi API key nahi mili (GEMINI_API_KEY ya ANTHROPIC_API_KEY).")


def _post(url, body, headers, tries=3):
    data = json.dumps(body).encode()
    for attempt in range(tries):
        req = urllib.request.Request(url, data=data, headers={"content-type": "application/json", **headers})
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read())
        except urllib.error.HTTPError as e:
            msg = e.read().decode(errors="replace")[:500]
            print(f"HTTP {e.code}: {msg}")
            if e.code in (429, 500, 502, 503, 529) and attempt < tries - 1:
                time.sleep(20 * (attempt + 1))
                continue
            raise
        except urllib.error.URLError:
            if attempt < tries - 1:
                time.sleep(10)
                continue
            raise


_gemini_model_cache = None


def _gemini_model():
    global _gemini_model_cache
    if _gemini_model_cache:
        return _gemini_model_cache
    forced = os.environ.get("GEMINI_MODEL")
    if forced:
        _gemini_model_cache = forced
        return forced
    key = os.environ["GEMINI_API_KEY"]
    req = urllib.request.Request(
        "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200",
        headers={"x-goog-api-key": key})
    with urllib.request.urlopen(req, timeout=60) as r:
        models = json.loads(r.read()).get("models", [])
    names = [m["name"].split("/", 1)[1] for m in models
             if "generateContent" in m.get("supportedGenerationMethods", [])]
    print("Gemini models:", ", ".join(sorted(names)))

    def ver(n):
        nums = re.findall(r"\d+(?:\.\d+)?", n)
        return float(nums[0]) if nums else 0.0

    for pat in GEMINI_PREFERENCE:
        cands = sorted([n for n in names if re.match(pat, n)], key=ver, reverse=True)
        if cands:
            _gemini_model_cache = cands[0]
            print("Using Gemini model:", cands[0])
            return cands[0]
    raise SystemExit("Koi Gemini flash model nahi mila.")


def ask(system: str, text: str, images=None, role="writer", max_tokens=8000, temperature=0.9) -> str:
    """images: list of JPEG bytes. Returns model text."""
    images = images or []
    p = provider()
    if p == "mock":
        return _mock(text, images)
    if p == "anthropic":
        content = [{"type": "image", "source": {"type": "base64", "media_type": "image/jpeg",
                                                 "data": base64.b64encode(b).decode()}} for b in images]
        content.append({"type": "text", "text": text})
        res = _post("https://api.anthropic.com/v1/messages", {
            "model": ANTHROPIC_MODELS[role],
            "max_tokens": max_tokens,
            "temperature": temperature,
            "system": system,
            "messages": [{"role": "user", "content": content}],
        }, {"x-api-key": os.environ["ANTHROPIC_API_KEY"], "anthropic-version": "2023-06-01"})
        u = res.get("usage", {})
        print(f"[claude {ANTHROPIC_MODELS[role]}] in={u.get('input_tokens')} out={u.get('output_tokens')}")
        return "".join(b.get("text", "") for b in res.get("content", []))

    if p == "gemini":
        model = _gemini_model()
        parts = [{"inline_data": {"mime_type": "image/jpeg", "data": base64.b64encode(b).decode()}} for b in images]
        parts.append({"text": text})
        res = _post(
            f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
            {
                "systemInstruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": parts}],
                "generationConfig": {
                    "temperature": temperature,
                    "maxOutputTokens": max_tokens,
                    "responseMimeType": "application/json",
                },
            },
            {"x-goog-api-key": os.environ["GEMINI_API_KEY"]},
        )
        u = res.get("usageMetadata", {})
        print(f"[gemini {model}] in={u.get('promptTokenCount')} out={u.get('candidatesTokenCount')}")
        cands = res.get("candidates") or []
        if not cands:
            raise RuntimeError(f"Gemini: no candidates: {json.dumps(res)[:400]}")
        return "".join(part.get("text", "") for part in cands[0].get("content", {}).get("parts", []))

    raise SystemExit(f"Unknown provider {p}")


def ask_json(system, text, images=None, role="writer", **kw):
    """ask() + JSON parse (ek baar retry)."""
    last = None
    for attempt in range(2):
        out = ask(system, text + ("" if attempt == 0 else "\n\nWICHTIG: Antworte NUR mit gültigem JSON."),
                  images=images, role=role, **kw)
        try:
            return parse_json(out)
        except ValueError as e:
            last = e
            print("JSON parse failed, retry:", out[:300])
    raise last


def parse_json(s: str):
    s = s.strip()
    s = re.sub(r"^```(?:json)?\s*|\s*```$", "", s)
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        m = re.search(r"\{.*\}", s, re.S)
        if m:
            try:
                return json.loads(m.group(0))
            except json.JSONDecodeError:
                pass
    raise ValueError("Invalid JSON from model")


def _mock(text, images):
    """Local testing ke liye nakli AI (LLM_PROVIDER=mock)."""
    import random
    if "TASK: generate" in text:
        cats = re.findall(r'- "(\w+)": (\d+) Sprüche', text)
        q, w = [], []
        for c, n in cats:
            for i in range(int(n)):
                words = ["Sonne", "Herz", "Kaffee", "Freude", "Morgen", "Wolke", "Lachen", "Garten", "Blume", "Reise", "Stern", "Mut", "Ruhe", "Wind", "Meer", "Licht"]
                item = {"text": " ".join(random.sample(words, 8)) + f" {random.randint(10**5, 10**6)}.", "heading": "", "mood": random.choice(["kaffee", "xyz"])}
                if c in ("sonne", "wolken", "regen", "schnee", "nebel", "wind", "hitze", "kaelte"):
                    w.append({"type": c, **item})
                else:
                    q.append({"category": c, **item})
        q.append({"category": "unbekannt", "text": "soll gedroppt werden weil kategorie falsch ist"})
        return json.dumps({"quotes": q, "weather": w})
    if "TASK: review" in text:
        return json.dumps({"reject": [{"i": 0, "reason": "test"}], "fix": [{"i": 1, "text": "Korrigierter Testspruch mit ausreichender Länge."}]})
    if "TASK: photos" in text:
        return json.dumps({"photos": [{"i": i, "ok": i % 2 == 0, "score": 8, "tags": ["kaffee"], "dim": 0.1} for i in range(len(images))]})
    return "{}"
