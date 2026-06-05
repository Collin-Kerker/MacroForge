"""
ETL: load USDA FoodData Central generic foods into the food_items table.

Reads the SR Legacy + Foundation Foods CSV bundles, joins food.csv with
food_nutrient.csv, extracts the four macros per 100g, and bulk-inserts.

Run inside the api container:
    docker compose exec api python -m app.scripts.load_usda

Idempotent: clears food_items first, then reloads. Safe to re-run.
"""

import csv
import os
import sys

# nutrient_id values in USDA data
NUTRIENT_PROTEIN = "1003"
NUTRIENT_FAT = "1004"
NUTRIENT_CARB = "1005"
# Energy: 1008 is the standard kcal; some foods only have Atwater (2047/2048)
NUTRIENT_ENERGY = "1008"
NUTRIENT_ENERGY_ATWATER_GENERAL = "2047"
NUTRIENT_ENERGY_ATWATER_SPECIFIC = "2048"

# Where the unzipped USDA folders live (relative to api/ working dir)
DATA_DIRS = [
    "data/usda/FoodData_Central_sr_legacy_food_csv_2018-04",
    "data/usda/FoodData_Central_foundation_food_csv_2026-04-30",
]

# csv field size: USDA descriptions can be long
csv.field_size_limit(min(sys.maxsize, 2**31 - 1))


def load_food_descriptions(data_dir):
    """fdc_id -> (description, data_type, food_category_id)"""
    foods = {}
    path = os.path.join(data_dir, "food.csv")
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = row["fdc_id"].strip()
            if not fdc_id:
                continue
            cat = row.get("food_category_id", "").strip()
            foods[fdc_id] = {
                "description": row["description"].strip(),
                "data_type": row.get("data_type", "").strip(),
                "food_category_id": int(cat) if cat.isdigit() else None,
            }
    return foods


def load_nutrients_for_foods(data_dir, wanted_fdc_ids):
    """
    fdc_id -> {kcal, protein, carbs, fat}
    Only keeps the four macros. Energy prefers 1008, falls back to Atwater.
    """
    nutrients = {}
    path = os.path.join(data_dir, "food_nutrient.csv")
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            fdc_id = row["fdc_id"].strip()
            if fdc_id not in wanted_fdc_ids:
                continue
            nid = row["nutrient_id"].strip()
            amt = row["amount"].strip()
            if not amt:
                continue
            try:
                amount = float(amt)
            except ValueError:
                continue

            entry = nutrients.setdefault(fdc_id, {})
            if nid == NUTRIENT_PROTEIN:
                entry["protein"] = amount
            elif nid == NUTRIENT_FAT:
                entry["fat"] = amount
            elif nid == NUTRIENT_CARB:
                entry["carbs"] = amount
            elif nid == NUTRIENT_ENERGY:
                entry["kcal"] = amount  # 1008 wins
            elif nid in (NUTRIENT_ENERGY_ATWATER_GENERAL, NUTRIENT_ENERGY_ATWATER_SPECIFIC):
                entry.setdefault("kcal_fallback", amount)
    return nutrients


def build_rows():
    rows = []
    seen = set()
    for data_dir in DATA_DIRS:
        if not os.path.isdir(data_dir):
            print(f"  WARNING: {data_dir} not found, skipping")
            continue
        print(f"  Reading {data_dir} ...")
        foods = load_food_descriptions(data_dir)
        nutrients = load_nutrients_for_foods(data_dir, set(foods.keys()))

        for fdc_id, food in foods.items():
            if fdc_id in seen:
                continue
            seen.add(fdc_id)
            n = nutrients.get(fdc_id, {})
            kcal = n.get("kcal", n.get("kcal_fallback"))
            rows.append((
                int(fdc_id),
                food["description"],
                food["data_type"],
                food["food_category_id"],
                n.get("kcal", kcal),
                n.get("protein"),
                n.get("carbs"),
                n.get("fat"),
            ))
    return rows


def main():
    print("Building rows from USDA CSVs...")
    rows = build_rows()
    print(f"  Built {len(rows)} food rows.")

    # Only import DB stuff when actually running (so build_rows is unit-testable)
    from sqlalchemy import text
    from app.database import engine

    print("Loading into food_items (clearing existing first)...")
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE food_items"))
        conn.execute(
            text("""
                INSERT INTO food_items
                  (id, description, data_type, food_category_id,
                   kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g)
                VALUES
                  (:id, :description, :data_type, :food_category_id,
                   :kcal, :protein, :carbs, :fat)
                ON CONFLICT (id) DO NOTHING
            """),
            [
                {
                    "id": r[0], "description": r[1], "data_type": r[2],
                    "food_category_id": r[3], "kcal": r[4], "protein": r[5],
                    "carbs": r[6], "fat": r[7],
                }
                for r in rows
            ],
        )
    print(f"Done. Inserted {len(rows)} foods.")


if __name__ == "__main__":
    main()