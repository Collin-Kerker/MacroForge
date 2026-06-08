"""
Seed the recipes table with 30 starter recipes.

Run inside the api container:
    docker compose exec api python -m app.scripts.seed_recipes

Idempotent: clears recipes first, then reloads. Safe to re-run.
Macros are per-serving, computed by hand at authoring time (Option A:
recipes carry their own macros rather than deriving from USDA lookups).
"""

RECIPES = [
    # ───────────────────────── BREAKFAST ─────────────────────────
    {
        "name": "Greek Yogurt Protein Bowl",
        "description": "Thick Greek yogurt with berries, honey, and almonds.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 5,
        "ingredients": [
            {"item": "Nonfat Greek yogurt", "amount": "200 g"},
            {"item": "Mixed berries", "amount": "100 g"},
            {"item": "Honey", "amount": "1 tbsp"},
            {"item": "Sliced almonds", "amount": "15 g"},
        ],
        "steps": [
            "Spoon the Greek yogurt into a bowl.",
            "Top with berries and a drizzle of honey.",
            "Sprinkle sliced almonds over the top and serve.",
        ],
        "kcal": 320, "protein": 26, "carbs": 38, "fat": 9,
    },
    {
        "name": "Three-Egg Veggie Scramble",
        "description": "Fluffy eggs scrambled with spinach, peppers, and onion.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 10,
        "ingredients": [
            {"item": "Large eggs", "amount": "3"},
            {"item": "Spinach", "amount": "50 g"},
            {"item": "Bell pepper, diced", "amount": "60 g"},
            {"item": "Onion, diced", "amount": "30 g"},
            {"item": "Olive oil", "amount": "1 tsp"},
            {"item": "Salt and pepper", "amount": "to taste"},
        ],
        "steps": [
            "Heat olive oil in a nonstick pan over medium heat.",
            "Saute onion and pepper until softened, about 3 minutes.",
            "Add spinach and cook until wilted.",
            "Beat the eggs, pour in, and scramble until just set. Season and serve.",
        ],
        "kcal": 290, "protein": 21, "carbs": 8, "fat": 19,
    },
    {
        "name": "Overnight Protein Oats",
        "description": "Make-ahead oats with protein powder and banana.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 5,
        "ingredients": [
            {"item": "Rolled oats", "amount": "60 g"},
            {"item": "Whey protein powder", "amount": "1 scoop (30 g)"},
            {"item": "Milk (or almond milk)", "amount": "240 ml"},
            {"item": "Banana, sliced", "amount": "1 small"},
            {"item": "Chia seeds", "amount": "1 tbsp"},
        ],
        "steps": [
            "Combine oats, protein powder, milk, and chia seeds in a jar.",
            "Stir well, cover, and refrigerate overnight.",
            "In the morning, top with sliced banana and eat cold.",
        ],
        "kcal": 480, "protein": 38, "carbs": 62, "fat": 10,
    },
    {
        "name": "Avocado Toast with Egg",
        "description": "Whole-grain toast, smashed avocado, and a fried egg.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 10,
        "ingredients": [
            {"item": "Whole-grain bread", "amount": "2 slices"},
            {"item": "Avocado", "amount": "1/2 medium"},
            {"item": "Large egg", "amount": "1"},
            {"item": "Lemon juice", "amount": "1 tsp"},
            {"item": "Red pepper flakes", "amount": "pinch"},
        ],
        "steps": [
            "Toast the bread.",
            "Mash avocado with lemon juice, salt, and pepper; spread on toast.",
            "Fry the egg to your liking and place on top.",
            "Finish with red pepper flakes.",
        ],
        "kcal": 380, "protein": 17, "carbs": 34, "fat": 21,
    },
    {
        "name": "Cottage Cheese & Fruit Plate",
        "description": "High-protein cottage cheese with pineapple and walnuts.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 5,
        "ingredients": [
            {"item": "Low-fat cottage cheese", "amount": "200 g"},
            {"item": "Pineapple chunks", "amount": "120 g"},
            {"item": "Walnuts, chopped", "amount": "15 g"},
        ],
        "steps": [
            "Scoop cottage cheese into a bowl.",
            "Add pineapple chunks alongside.",
            "Top with chopped walnuts.",
        ],
        "kcal": 300, "protein": 28, "carbs": 24, "fat": 11,
    },
    {
        "name": "Banana Protein Pancakes",
        "description": "Simple oat-and-banana pancakes with a protein boost.",
        "meal_type": "breakfast",
        "servings": 2,
        "prep_minutes": 15,
        "ingredients": [
            {"item": "Rolled oats", "amount": "80 g"},
            {"item": "Banana", "amount": "1 large"},
            {"item": "Large eggs", "amount": "2"},
            {"item": "Whey protein powder", "amount": "1 scoop (30 g)"},
            {"item": "Baking powder", "amount": "1 tsp"},
        ],
        "steps": [
            "Blend all ingredients into a smooth batter.",
            "Heat a nonstick pan over medium and pour small pancakes.",
            "Cook until bubbles form, flip, and cook through.",
            "Serve warm.",
        ],
        "kcal": 290, "protein": 22, "carbs": 36, "fat": 7,
    },
    {
        "name": "Smoked Salmon Bagel",
        "description": "Whole-wheat bagel with cream cheese and smoked salmon.",
        "meal_type": "breakfast",
        "servings": 1,
        "prep_minutes": 5,
        "ingredients": [
            {"item": "Whole-wheat bagel", "amount": "1"},
            {"item": "Light cream cheese", "amount": "30 g"},
            {"item": "Smoked salmon", "amount": "60 g"},
            {"item": "Capers", "amount": "1 tsp"},
            {"item": "Red onion, thin slices", "amount": "10 g"},
        ],
        "steps": [
            "Toast the bagel halves.",
            "Spread cream cheese on both halves.",
            "Layer smoked salmon, capers, and red onion.",
        ],
        "kcal": 420, "protein": 28, "carbs": 48, "fat": 13,
    },
    # ───────────────────────── LUNCH ─────────────────────────
    {
        "name": "Grilled Chicken & Quinoa Bowl",
        "description": "Lean chicken over quinoa with roasted vegetables.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 25,
        "ingredients": [
            {"item": "Chicken breast", "amount": "150 g"},
            {"item": "Cooked quinoa", "amount": "150 g"},
            {"item": "Broccoli", "amount": "100 g"},
            {"item": "Cherry tomatoes", "amount": "80 g"},
            {"item": "Olive oil", "amount": "1 tbsp"},
        ],
        "steps": [
            "Season and grill the chicken breast until cooked through, then slice.",
            "Roast broccoli and tomatoes with olive oil at 200C for 15 minutes.",
            "Spoon quinoa into a bowl, top with chicken and vegetables.",
        ],
        "kcal": 520, "protein": 46, "carbs": 42, "fat": 18,
    },
    {
        "name": "Turkey & Hummus Wrap",
        "description": "Whole-wheat wrap with turkey, hummus, and greens.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 10,
        "ingredients": [
            {"item": "Whole-wheat tortilla", "amount": "1 large"},
            {"item": "Sliced turkey breast", "amount": "100 g"},
            {"item": "Hummus", "amount": "40 g"},
            {"item": "Mixed greens", "amount": "40 g"},
            {"item": "Cucumber, sliced", "amount": "50 g"},
        ],
        "steps": [
            "Spread hummus across the tortilla.",
            "Layer turkey, greens, and cucumber.",
            "Roll up tightly and slice in half.",
        ],
        "kcal": 400, "protein": 34, "carbs": 40, "fat": 11,
    },
    {
        "name": "Tuna Salad Lettuce Cups",
        "description": "Light tuna salad served in crisp lettuce.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 10,
        "ingredients": [
            {"item": "Canned tuna in water, drained", "amount": "1 can (120 g)"},
            {"item": "Light mayonnaise", "amount": "1 tbsp"},
            {"item": "Celery, diced", "amount": "30 g"},
            {"item": "Romaine lettuce leaves", "amount": "4 large"},
            {"item": "Lemon juice", "amount": "1 tsp"},
        ],
        "steps": [
            "Mix tuna, mayo, celery, and lemon juice.",
            "Spoon into lettuce leaves and serve.",
        ],
        "kcal": 250, "protein": 30, "carbs": 6, "fat": 11,
    },
    {
        "name": "Black Bean & Rice Burrito Bowl",
        "description": "Plant-forward bowl with beans, rice, corn, and salsa.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 15,
        "ingredients": [
            {"item": "Cooked brown rice", "amount": "150 g"},
            {"item": "Black beans", "amount": "120 g"},
            {"item": "Corn", "amount": "60 g"},
            {"item": "Salsa", "amount": "60 g"},
            {"item": "Avocado", "amount": "1/4 medium"},
        ],
        "steps": [
            "Warm the rice and beans.",
            "Layer rice, beans, and corn in a bowl.",
            "Top with salsa and sliced avocado.",
        ],
        "kcal": 490, "protein": 17, "carbs": 82, "fat": 11,
    },
    {
        "name": "Chicken Caesar Salad (Light)",
        "description": "Romaine, grilled chicken, and a lighter Caesar dressing.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 15,
        "ingredients": [
            {"item": "Chicken breast", "amount": "130 g"},
            {"item": "Romaine lettuce", "amount": "120 g"},
            {"item": "Light Caesar dressing", "amount": "2 tbsp"},
            {"item": "Parmesan, grated", "amount": "15 g"},
            {"item": "Whole-grain croutons", "amount": "20 g"},
        ],
        "steps": [
            "Grill and slice the chicken breast.",
            "Toss romaine with dressing.",
            "Top with chicken, parmesan, and croutons.",
        ],
        "kcal": 410, "protein": 42, "carbs": 16, "fat": 19,
    },
    {
        "name": "Lentil Soup with Bread",
        "description": "Hearty lentil soup served with a slice of whole-grain bread.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 30,
        "ingredients": [
            {"item": "Dry lentils", "amount": "80 g"},
            {"item": "Carrot, diced", "amount": "60 g"},
            {"item": "Onion, diced", "amount": "50 g"},
            {"item": "Vegetable broth", "amount": "500 ml"},
            {"item": "Whole-grain bread", "amount": "1 slice"},
        ],
        "steps": [
            "Saute onion and carrot in a pot until softened.",
            "Add lentils and broth; simmer 25 minutes until tender.",
            "Season to taste and serve with bread.",
        ],
        "kcal": 430, "protein": 24, "carbs": 70, "fat": 5,
    },
    {
        "name": "Shrimp & Veggie Stir-Fry",
        "description": "Quick shrimp stir-fry over rice.",
        "meal_type": "lunch",
        "servings": 1,
        "prep_minutes": 20,
        "ingredients": [
            {"item": "Shrimp, peeled", "amount": "150 g"},
            {"item": "Mixed stir-fry vegetables", "amount": "150 g"},
            {"item": "Cooked white rice", "amount": "120 g"},
            {"item": "Soy sauce", "amount": "1 tbsp"},
            {"item": "Sesame oil", "amount": "1 tsp"},
        ],
        "steps": [
            "Heat sesame oil in a wok over high heat.",
            "Stir-fry shrimp until pink, then remove.",
            "Stir-fry vegetables until crisp-tender; return shrimp, add soy sauce.",
            "Serve over rice.",
        ],
        "kcal": 420, "protein": 36, "carbs": 48, "fat": 8,
    },
    # ───────────────────────── DINNER ─────────────────────────
    {
        "name": "Baked Salmon with Sweet Potato",
        "description": "Oven-baked salmon fillet with roasted sweet potato and asparagus.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 30,
        "ingredients": [
            {"item": "Salmon fillet", "amount": "170 g"},
            {"item": "Sweet potato", "amount": "200 g"},
            {"item": "Asparagus", "amount": "100 g"},
            {"item": "Olive oil", "amount": "1 tbsp"},
            {"item": "Lemon", "amount": "1/2"},
        ],
        "steps": [
            "Preheat oven to 200C.",
            "Cube sweet potato, toss with half the oil, roast 15 minutes.",
            "Add salmon and asparagus to the tray, drizzle remaining oil and lemon.",
            "Bake another 12-15 minutes until salmon flakes.",
        ],
        "kcal": 560, "protein": 40, "carbs": 44, "fat": 24,
    },
    {
        "name": "Lean Beef & Broccoli",
        "description": "Stir-fried lean beef and broccoli in a savory sauce over rice.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 25,
        "ingredients": [
            {"item": "Lean beef strips", "amount": "150 g"},
            {"item": "Broccoli florets", "amount": "150 g"},
            {"item": "Cooked white rice", "amount": "150 g"},
            {"item": "Soy sauce", "amount": "2 tbsp"},
            {"item": "Garlic, minced", "amount": "2 cloves"},
        ],
        "steps": [
            "Sear beef strips in a hot pan, then remove.",
            "Stir-fry broccoli and garlic until bright green.",
            "Return beef, add soy sauce, toss to coat.",
            "Serve over rice.",
        ],
        "kcal": 580, "protein": 44, "carbs": 56, "fat": 18,
    },
    {
        "name": "Chicken Fajita Bowl",
        "description": "Seasoned chicken with peppers and onions over rice.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 25,
        "ingredients": [
            {"item": "Chicken breast", "amount": "160 g"},
            {"item": "Bell peppers, sliced", "amount": "120 g"},
            {"item": "Onion, sliced", "amount": "60 g"},
            {"item": "Cooked brown rice", "amount": "150 g"},
            {"item": "Fajita seasoning", "amount": "1 tbsp"},
        ],
        "steps": [
            "Toss chicken with fajita seasoning and saute until cooked; slice.",
            "Saute peppers and onions until charred at the edges.",
            "Serve chicken and vegetables over rice.",
        ],
        "kcal": 540, "protein": 48, "carbs": 58, "fat": 12,
    },
    {
        "name": "Turkey Meatballs & Zucchini Noodles",
        "description": "Lean turkey meatballs over zoodles with marinara.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 30,
        "ingredients": [
            {"item": "Ground turkey (93% lean)", "amount": "150 g"},
            {"item": "Zucchini, spiralized", "amount": "200 g"},
            {"item": "Marinara sauce", "amount": "120 g"},
            {"item": "Egg", "amount": "1"},
            {"item": "Breadcrumbs", "amount": "20 g"},
        ],
        "steps": [
            "Mix turkey, egg, and breadcrumbs; form meatballs.",
            "Bake at 200C for 18 minutes.",
            "Warm marinara and toss with zucchini noodles briefly.",
            "Top with meatballs.",
        ],
        "kcal": 430, "protein": 40, "carbs": 24, "fat": 20,
    },
    {
        "name": "Tofu & Vegetable Curry",
        "description": "Coconut curry with tofu and vegetables over rice.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 30,
        "ingredients": [
            {"item": "Firm tofu, cubed", "amount": "150 g"},
            {"item": "Mixed vegetables", "amount": "150 g"},
            {"item": "Light coconut milk", "amount": "120 ml"},
            {"item": "Curry paste", "amount": "1 tbsp"},
            {"item": "Cooked jasmine rice", "amount": "150 g"},
        ],
        "steps": [
            "Pan-fry tofu until golden, then set aside.",
            "Saute curry paste, add coconut milk and vegetables; simmer 10 minutes.",
            "Return tofu, warm through, and serve over rice.",
        ],
        "kcal": 510, "protein": 24, "carbs": 60, "fat": 20,
    },
    {
        "name": "Pork Tenderloin with Green Beans",
        "description": "Roasted pork tenderloin with garlic green beans and potatoes.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 35,
        "ingredients": [
            {"item": "Pork tenderloin", "amount": "150 g"},
            {"item": "Green beans", "amount": "120 g"},
            {"item": "Baby potatoes", "amount": "180 g"},
            {"item": "Olive oil", "amount": "1 tbsp"},
            {"item": "Garlic, minced", "amount": "2 cloves"},
        ],
        "steps": [
            "Roast potatoes at 200C for 20 minutes.",
            "Sear pork, then roast alongside potatoes 15 minutes; rest and slice.",
            "Saute green beans with garlic until tender.",
            "Plate everything together.",
        ],
        "kcal": 520, "protein": 42, "carbs": 46, "fat": 16,
    },
    {
        "name": "Egg Fried Rice with Peas",
        "description": "Quick veggie fried rice with scrambled egg.",
        "meal_type": "dinner",
        "servings": 1,
        "prep_minutes": 15,
        "ingredients": [
            {"item": "Cooked rice (day-old)", "amount": "200 g"},
            {"item": "Large eggs", "amount": "2"},
            {"item": "Frozen peas and carrots", "amount": "100 g"},
            {"item": "Soy sauce", "amount": "1 tbsp"},
            {"item": "Sesame oil", "amount": "1 tsp"},
        ],
        "steps": [
            "Scramble eggs in a hot wok, then push aside.",
            "Add rice and vegetables, stir-fry until hot.",
            "Add soy sauce and sesame oil, toss, and serve.",
        ],
        "kcal": 470, "protein": 19, "carbs": 68, "fat": 14,
    },
    {
        "name": "Stuffed Bell Peppers",
        "description": "Peppers stuffed with lean turkey, rice, and tomato.",
        "meal_type": "dinner",
        "servings": 2,
        "prep_minutes": 40,
        "ingredients": [
            {"item": "Bell peppers", "amount": "2 large"},
            {"item": "Ground turkey (93% lean)", "amount": "200 g"},
            {"item": "Cooked rice", "amount": "150 g"},
            {"item": "Tomato sauce", "amount": "150 g"},
            {"item": "Shredded mozzarella", "amount": "40 g"},
        ],
        "steps": [
            "Halve and seed the peppers.",
            "Brown the turkey, mix with rice and tomato sauce.",
            "Stuff peppers, top with cheese.",
            "Bake at 190C for 25 minutes.",
        ],
        "kcal": 380, "protein": 30, "carbs": 34, "fat": 14,
    },
    # ───────────────────────── SNACK ─────────────────────────
    {
        "name": "Apple with Peanut Butter",
        "description": "Classic crunchy-creamy snack.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 3,
        "ingredients": [
            {"item": "Apple", "amount": "1 medium"},
            {"item": "Natural peanut butter", "amount": "2 tbsp"},
        ],
        "steps": [
            "Slice the apple.",
            "Serve with peanut butter for dipping.",
        ],
        "kcal": 280, "protein": 8, "carbs": 32, "fat": 16,
    },
    {
        "name": "Protein Shake",
        "description": "Simple whey shake with banana and milk.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 3,
        "ingredients": [
            {"item": "Whey protein powder", "amount": "1 scoop (30 g)"},
            {"item": "Milk", "amount": "300 ml"},
            {"item": "Banana", "amount": "1 small"},
        ],
        "steps": [
            "Add all ingredients to a blender.",
            "Blend until smooth and drink.",
        ],
        "kcal": 330, "protein": 34, "carbs": 36, "fat": 6,
    },
    {
        "name": "Hummus & Veggie Sticks",
        "description": "Crunchy raw vegetables with hummus.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 5,
        "ingredients": [
            {"item": "Hummus", "amount": "60 g"},
            {"item": "Carrot sticks", "amount": "80 g"},
            {"item": "Cucumber sticks", "amount": "80 g"},
            {"item": "Bell pepper strips", "amount": "60 g"},
        ],
        "steps": [
            "Cut vegetables into sticks.",
            "Serve alongside hummus.",
        ],
        "kcal": 220, "protein": 8, "carbs": 26, "fat": 11,
    },
    {
        "name": "Hard-Boiled Eggs & Almonds",
        "description": "Portable high-protein snack.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 2,
        "ingredients": [
            {"item": "Hard-boiled eggs", "amount": "2"},
            {"item": "Almonds", "amount": "20 g"},
        ],
        "steps": [
            "Peel the eggs.",
            "Serve with a small handful of almonds.",
        ],
        "kcal": 270, "protein": 18, "carbs": 5, "fat": 20,
    },
    {
        "name": "Greek Yogurt with Honey",
        "description": "Quick protein-rich snack.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 2,
        "ingredients": [
            {"item": "Nonfat Greek yogurt", "amount": "170 g"},
            {"item": "Honey", "amount": "1 tbsp"},
            {"item": "Cinnamon", "amount": "pinch"},
        ],
        "steps": [
            "Spoon yogurt into a bowl.",
            "Drizzle with honey and dust with cinnamon.",
        ],
        "kcal": 180, "protein": 17, "carbs": 26, "fat": 0,
    },
    {
        "name": "Rice Cakes with Cottage Cheese",
        "description": "Light, crunchy, high-protein snack.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 3,
        "ingredients": [
            {"item": "Rice cakes", "amount": "2"},
            {"item": "Low-fat cottage cheese", "amount": "100 g"},
            {"item": "Cherry tomatoes, halved", "amount": "50 g"},
        ],
        "steps": [
            "Spread cottage cheese on the rice cakes.",
            "Top with cherry tomatoes and a pinch of pepper.",
        ],
        "kcal": 190, "protein": 15, "carbs": 26, "fat": 2,
    },
    {
        "name": "Trail Mix (Portioned)",
        "description": "A controlled portion of nuts and dried fruit.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 1,
        "ingredients": [
            {"item": "Mixed nuts", "amount": "25 g"},
            {"item": "Dried cranberries", "amount": "15 g"},
            {"item": "Dark chocolate chips", "amount": "10 g"},
        ],
        "steps": [
            "Combine in a small container and enjoy.",
        ],
        "kcal": 250, "protein": 6, "carbs": 24, "fat": 16,
    },
    {
        "name": "Edamame Bowl",
        "description": "Steamed edamame with sea salt.",
        "meal_type": "snack",
        "servings": 1,
        "prep_minutes": 6,
        "ingredients": [
            {"item": "Edamame in pods", "amount": "150 g"},
            {"item": "Sea salt", "amount": "to taste"},
        ],
        "steps": [
            "Steam or microwave edamame until hot.",
            "Sprinkle with sea salt and serve.",
        ],
        "kcal": 190, "protein": 17, "carbs": 15, "fat": 8,
    },
]


def main():
    from sqlalchemy import text
    from app.database import engine

    print(f"Seeding {len(RECIPES)} recipes (clearing existing first)...")
    with engine.begin() as conn:
        conn.execute(text("TRUNCATE TABLE recipes"))
        for r in RECIPES:
            conn.execute(
                text("""
                    INSERT INTO recipes
                      (id, name, description, meal_type, servings, prep_minutes,
                       ingredients, steps,
                       kcal_per_serving, protein_g_per_serving,
                       carbs_g_per_serving, fat_g_per_serving, created_at)
                    VALUES
                      (gen_random_uuid(), :name, :description, :meal_type, :servings, :prep_minutes,
                       CAST(:ingredients AS JSON), CAST(:steps AS JSON),
                       :kcal, :protein, :carbs, :fat, now())
                """),
                {
                    "name": r["name"],
                    "description": r["description"],
                    "meal_type": r["meal_type"],
                    "servings": r["servings"],
                    "prep_minutes": r["prep_minutes"],
                    "ingredients": __import__("json").dumps(r["ingredients"]),
                    "steps": __import__("json").dumps(r["steps"]),
                    "kcal": r["kcal"],
                    "protein": r["protein"],
                    "carbs": r["carbs"],
                    "fat": r["fat"],
                },
            )
    print(f"Done. Inserted {len(RECIPES)} recipes.")


if __name__ == "__main__":
    main()