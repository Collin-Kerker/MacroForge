"""
Grocery list aggregation engine for MacroForge.

Pure, no DB. Takes a list of (recipe_ingredients, servings_multiplier) and
produces a consolidated, store-section-grouped shopping list.

Design decisions (Collin, Jun 15):
  - SAFE/LITERAL merging: only merge ingredients with the SAME item name
    (exact, case-insensitive) AND compatible units. Near-duplicate names
    ("Cooked white rice" vs "Cooked brown rice") are listed separately.
  - Volume units (tsp/tbsp/cup/ml/l) and weight units (g/kg) are converted
    within their own family before summing (pure arithmetic, no guessing).
  - Counts (no unit) sum as counts.
  - Unparseable amounts ("to taste", "pinch", "1/2 medium") pass through
    UNSCALED and are listed verbatim, never summed.
"""
import re
from fractions import Fraction

# ── unit normalization ───────────────────────────────────────────────────────
# Convert everything in a family to a base unit, sum, then render sensibly.
WEIGHT_TO_G = {"g": 1.0, "kg": 1000.0}
VOLUME_TO_ML = {
    "ml": 1.0, "l": 1000.0,
    "tsp": 4.92892, "tbsp": 14.7868, "cup": 236.588,
}
# unit aliases seen in the data
UNIT_ALIASES = {
    "g": "g", "gram": "g", "grams": "g",
    "kg": "kg",
    "ml": "ml", "l": "l", "liter": "l", "litre": "l",
    "tsp": "tsp", "teaspoon": "tsp", "teaspoons": "tsp",
    "tbsp": "tbsp", "tablespoon": "tbsp", "tablespoons": "tbsp",
    "cup": "cup", "cups": "cup",
}

# ── store sections via keyword lookup on item name ───────────────────────────
SECTION_KEYWORDS = [
    ("Produce", ["lettuce", "romaine", "spinach", "pepper", "onion", "tomato",
                 "broccoli", "carrot", "cucumber", "avocado", "banana", "apple",
                 "berries", "berry", "pineapple", "asparagus", "green bean",
                 "zucchini", "garlic", "lemon", "lime", "celery", "greens",
                 "potato", "sweet potato", "corn", "vegetable", "edamame",
                 "mixed vegetables", "peas"]),
    ("Meat & Seafood", ["chicken", "beef", "pork", "turkey", "salmon", "tuna",
                        "shrimp", "fish", "bacon"]),
    ("Dairy & Eggs", ["egg", "eggs", "yogurt", "cheese", "milk", "cream",
                      "mozzarella", "parmesan", "cottage", "butter"]),
    ("Frozen", ["frozen"]),
    ("Bakery", ["bread", "bagel", "tortilla", "croutons", "bun"]),
    ("Pantry", ["rice", "oats", "quinoa", "lentil", "beans", "bean", "flour",
                "oil", "sauce", "soy", "honey", "salsa", "hummus", "broth",
                "protein powder", "whey", "chia", "almond", "walnut", "nuts",
                "peanut butter", "seasoning", "salt", "pepper", "cinnamon",
                "baking powder", "breadcrumbs", "mayonnaise", "mayo", "capers",
                "coconut milk", "curry paste", "dressing", "cranberries",
                "chocolate", "rice cakes", "marinara", "tomato sauce",
                "pineapple chunks"]),
]

def _section_for(item_name):
    low = item_name.lower()
    for section, keywords in SECTION_KEYWORDS:
        for kw in keywords:
            if kw in low:
                return section
    return "Other"

# ── amount parsing ───────────────────────────────────────────────────────────
# Returns (qty: float|None, unit: str|None, raw: str). qty/unit None = unparseable.
_NUM = r"(\d+(?:\.\d+)?|\d+\s*/\s*\d+|\d+\s+\d+\s*/\s*\d+)"

def _parse_number(s):
    s = s.strip()
    # mixed number "1 1/2"
    m = re.fullmatch(r"(\d+)\s+(\d+)\s*/\s*(\d+)", s)
    if m:
        whole, num, den = map(int, m.groups())
        return whole + num / den
    # fraction "1/2"
    m = re.fullmatch(r"(\d+)\s*/\s*(\d+)", s)
    if m:
        num, den = map(int, m.groups())
        return num / den
    # plain number
    m = re.fullmatch(r"\d+(?:\.\d+)?", s)
    if m:
        return float(s)
    return None

def parse_amount(amount):
    """
    Parse a free-text amount into (qty, unit, raw).
      "200 g"          -> (200.0, "g", "200 g")
      "1 tbsp"         -> (1.0, "tbsp", "1 tbsp")
      "1/2 medium"     -> (None, None, "1/2 medium")   # 'medium' not a real unit -> count-ish, but keep raw
      "3"              -> (3.0, None, "3")              # bare count
      "1 scoop (30 g)" -> (30.0, "g", "1 scoop (30 g)") # prefer the parenthetical metric
      "to taste"       -> (None, None, "to taste")
      "pinch"          -> (None, None, "pinch")
    """
    raw = amount.strip()
    low = raw.lower()

    # prefer a parenthetical metric weight/volume if present: "1 scoop (30 g)"
    paren = re.search(r"\(([^)]*)\)", raw)
    if paren:
        inner = paren.group(1).strip()
        m = re.fullmatch(rf"{_NUM}\s*([a-zA-Z]+)", inner)
        if m:
            qty = _parse_number(m.group(1))
            unit = UNIT_ALIASES.get(m.group(2).lower())
            if qty is not None and unit:
                return (qty, unit, raw)

    # "<number> <unit>"
    m = re.fullmatch(rf"{_NUM}\s*([a-zA-Z]+)", low)
    if m:
        qty = _parse_number(m.group(1))
        unit = UNIT_ALIASES.get(m.group(2))
        if qty is not None and unit:
            return (qty, unit, raw)
        # number + non-unit word ("1 medium", "2 slices", "1 large", "2 cloves")
        # -> treat as a COUNT with a descriptor we keep in raw, not a real unit
        if qty is not None:
            return (qty, None, raw)

    # bare number "3"
    if _parse_number(low) is not None:
        return (_parse_number(low), None, raw)

    # unparseable ("to taste", "pinch")
    return (None, None, raw)

# ── scaling ──────────────────────────────────────────────────────────────────
def _format_qty(q):
    # tidy: 4.0 -> "4", 1.5 -> "1.5"
    if abs(q - round(q)) < 1e-6:
        return str(int(round(q)))
    return f"{q:.2f}".rstrip("0").rstrip(".")

def _render_family(total_base, family):
    """Render a summed base quantity back into a readable unit."""
    if family == "weight":
        if total_base >= 1000:
            return f"{_format_qty(total_base/1000)} kg"
        return f"{_format_qty(total_base)} g"
    if family == "volume":
        # Large liquid volumes read better in ml/l than as fractional cups
        # (e.g. broth). Reserve cup/tbsp/tsp for small spoon-scale amounts.
        if total_base >= 500:
            if total_base >= 1000:
                return f"{_format_qty(total_base/1000)} l"
            return f"{_format_qty(total_base)} ml"
        if total_base >= VOLUME_TO_ML["tbsp"]:
            return f"{_format_qty(total_base/VOLUME_TO_ML['tbsp'])} tbsp"
        if total_base >= VOLUME_TO_ML["tsp"]:
            return f"{_format_qty(total_base/VOLUME_TO_ML['tsp'])} tsp"
        return f"{_format_qty(total_base)} ml"
    return _format_qty(total_base)  # count

def _family_of(unit):
    if unit in WEIGHT_TO_G: return "weight"
    if unit in VOLUME_TO_ML: return "volume"
    return None

def build_grocery_list(items):
    """
    items: list of (item_name: str, amount: str, servings: float)
    Returns list of sections: [{"section": str, "items": [{"name","quantity","notes"}]}]
    """
    # bucket key = (lower item name, family-or-rawunit). Mergeable buckets sum;
    # unparseable ones accumulate raw strings.
    summable = {}   # key -> {"name", "family", "base_total"}
    countable = {}  # key -> {"name", "total", "descriptor"}
    verbatim = {}   # name -> list of raw strings (unscaled, can't sum)

    for name, amount, servings in items:
        qty, unit, raw = parse_amount(amount)
        key = name.strip().lower()

        if qty is not None and unit and _family_of(unit):
            family = _family_of(unit)
            base = (WEIGHT_TO_G if family == "weight" else VOLUME_TO_ML)[unit] * qty * servings
            bkey = (key, family)
            if bkey not in summable:
                summable[bkey] = {"name": name.strip(), "family": family, "base_total": 0.0}
            summable[bkey]["base_total"] += base
        elif qty is not None and unit is None:
            # bare count or "<n> <descriptor>" -> sum the number, keep one descriptor
            descriptor = raw
            # strip leading number for the descriptor label
            dm = re.match(rf"\s*{_NUM}\s*(.*)", raw)
            desc_word = dm.group(2).strip() if dm and dm.group(2).strip() else ""
            bkey = (key, "count:" + desc_word.lower())
            if bkey not in countable:
                countable[bkey] = {"name": name.strip(), "total": 0.0, "descriptor": desc_word}
            countable[bkey]["total"] += qty * servings
        else:
            verbatim.setdefault(name.strip(), [])
            if raw not in verbatim[name.strip()]:
                verbatim[name.strip()].append(raw)

    # assemble flat list of (name, quantity_str, notes, section)
    flat = []
    for (key, family), v in summable.items():
        flat.append((v["name"], _render_family(v["base_total"], family), "", _section_for(v["name"])))
    for (key, fam), v in countable.items():
        q = _format_qty(v["total"])
        desc = v["descriptor"]
        qstr = f"{q} {desc}".strip() if desc else q
        flat.append((v["name"], qstr, "", _section_for(v["name"])))
    for name, raws in verbatim.items():
        flat.append((name, " + ".join(raws), "as needed", _section_for(name)))

    # group by section, sort sections in store-walk order, items alpha
    order = ["Produce", "Meat & Seafood", "Dairy & Eggs", "Bakery", "Frozen", "Pantry", "Other"]
    by_section = {}
    for name, qty, notes, section in flat:
        by_section.setdefault(section, []).append({"name": name, "quantity": qty, "notes": notes})
    result = []
    for sec in order:
        if sec in by_section:
            items_sorted = sorted(by_section[sec], key=lambda x: x["name"].lower())
            result.append({"section": sec, "items": items_sorted})
    return result