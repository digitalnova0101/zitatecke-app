"""German calendar context: Wochentag, Jahreszeit, Feiertage & besondere Tage."""
from datetime import date, timedelta

WEEKDAYS = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
MONTHS = ["Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August",
          "September", "Oktober", "November", "Dezember"]


def easter(y: int) -> date:
    a = y % 19
    b, c = divmod(y, 100)
    d, e = divmod(b, 4)
    f = (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = divmod(c, 4)
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    day = ((h + l - 7 * m + 114) % 31) + 1
    return date(y, month, day)


def nth_weekday(y, month, weekday, n):
    d = date(y, month, 1)
    d += timedelta(days=(weekday - d.weekday()) % 7)
    return d + timedelta(weeks=n - 1)


def special_days(y: int) -> dict:
    """date -> (name, heading, mood, tone)"""
    e = easter(y)
    xmas = date(y, 12, 25)
    advent4 = xmas - timedelta(days=(xmas.weekday() + 1) % 7 or 7)
    s = {
        date(y, 1, 1): ("Neujahr", "Frohes neues Jahr", "feier", "fröhlich, hoffnungsvoll"),
        date(y, 2, 14): ("Valentinstag", "Alles Liebe zum Valentinstag", "rosen", "liebevoll"),
        date(y, 3, 8): ("Weltfrauentag", "Alles Gute zum Frauentag", "blumen", "wertschätzend"),
        date(y, 3, 20): ("Frühlingsanfang", "Hallo Frühling", "fruehling", "frisch, fröhlich"),
        date(y, 5, 1): ("Maifeiertag", "Schönen 1. Mai", "fruehling", "fröhlich"),
        date(y, 6, 21): ("Sommeranfang", "Hallo Sommer", "sommer", "sonnig, leicht"),
        date(y, 7, 30): ("Internationaler Tag der Freundschaft", "Für meine Lieben", "herz", "herzlich"),
        date(y, 9, 22): ("Herbstanfang", "Hallo Herbst", "herbst", "gemütlich"),
        date(y, 10, 3): ("Tag der Deutschen Einheit", "Schönen Feiertag", "feier", "freundlich, unpolitisch"),
        date(y, 11, 11): ("Martinstag", "Schönen Martinstag", "kerzen", "warm, teilen"),
        date(y, 12, 6): ("Nikolaustag", "Frohen Nikolaustag", "winter", "verspielt, warm"),
        date(y, 12, 21): ("Winteranfang", "Hallo Winter", "schnee", "gemütlich"),
        date(y, 12, 24): ("Heiligabend", "Frohe Weihnachten", "kerzen", "besinnlich, warm"),
        date(y, 12, 25): ("1. Weihnachtsfeiertag", "Frohe Weihnachten", "kerzen", "besinnlich"),
        date(y, 12, 26): ("2. Weihnachtsfeiertag", "Frohe Weihnachten", "winter", "gemütlich"),
        date(y, 12, 31): ("Silvester", "Guten Rutsch", "feier", "fröhlich, dankbar"),
        e - timedelta(days=52): ("Weiberfastnacht", "Helau und Alaaf", "feier", "lustig"),
        e - timedelta(days=48): ("Rosenmontag", "Helau und Alaaf", "feier", "lustig"),
        e - timedelta(days=2): ("Karfreitag", "Besinnliche Ostertage", "kerzen", "ruhig, besinnlich"),
        e: ("Ostersonntag", "Frohe Ostern", "fruehling", "fröhlich"),
        e + timedelta(days=1): ("Ostermontag", "Frohe Ostern", "fruehling", "fröhlich"),
        e + timedelta(days=39): ("Christi Himmelfahrt / Vatertag", "Alles Gute zum Vatertag", "sommer", "herzlich, mit Augenzwinkern"),
        e + timedelta(days=49): ("Pfingstsonntag", "Frohe Pfingsten", "fruehling", "freundlich"),
        e + timedelta(days=50): ("Pfingstmontag", "Frohe Pfingsten", "fruehling", "freundlich"),
        nth_weekday(y, 5, 6, 2): ("Muttertag", "Alles Liebe zum Muttertag", "blumen", "dankbar, liebevoll"),
        nth_weekday(y, 10, 6, 1): ("Erntedank", "Gesegnetes Erntedankfest", "herbst", "dankbar"),
    }
    for n, d in ((4, advent4), (3, advent4 - timedelta(7)), (2, advent4 - timedelta(14)), (1, advent4 - timedelta(21))):
        adv = (f"{n}. Advent", f"Schönen {n}. Advent", "kerzen", "besinnlich, gemütlich")
        if d in s:  # z.B. Nikolaus am 2. Advent
            old = s[d]
            adv = (f"{adv[0]} & {old[0]}", adv[1], adv[2], adv[3])
        s[d] = adv
    return s


def season(d: date) -> str:
    return {12: "Winter", 1: "Winter", 2: "Winter", 3: "Frühling", 4: "Frühling", 5: "Frühling",
            6: "Sommer", 7: "Sommer", 8: "Sommer"}.get(d.month, "Herbst")


def context(d: date) -> dict:
    sp = special_days(d.year).get(d)
    return {
        "date": d.isoformat(),
        "weekday": WEEKDAYS[d.weekday()],
        "weekday_tag": WEEKDAYS[d.weekday()].lower(),
        "pretty": f"{WEEKDAYS[d.weekday()]}, {d.day}. {MONTHS[d.month - 1]} {d.year}",
        "season": season(d),
        "special": None if sp is None else {"name": sp[0], "heading": sp[1], "mood": sp[2], "tone": sp[3]},
    }


if __name__ == "__main__":
    import sys
    y = int(sys.argv[1]) if len(sys.argv) > 1 else date.today().year
    for d, v in sorted(special_days(y).items()):
        print(d, WEEKDAYS[d.weekday()], v[0])
