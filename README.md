# MacroForge

A full-stack meal-planning app that builds a week of meals hitting your calorie and macro targets. You give it your stats and your goal. It works out your daily targets, then uses an integer-programming solver to choose recipes and serving sizes for each meal slot. It also produces a combined grocery list and a meal-prep plan.

Live API: `https://api.macro-forge.org`

## Features

- **Goal-based targets.** You enter your current weight, goal weight and how fast you want to get there. The app works out whether you're cutting, bulking or maintaining, then computes daily calorie, protein, carb and fat targets (`api/app/nutrition.py`).
- **Meal solver.** A PuLP integer program picks one recipe and a serving size (1×, 1.5× or 2×) for each meal slot. It minimises a weighted deviation from your targets. Protein is weighted heaviest, and repeating a recipe within a day is penalised (`api/app/solver.py`).
- **Weekly planner.** Generate a week, regenerate single days, lock days you like, and mark meals as cooked.
- **Grocery list.** Ingredients from the whole week are combined and grouped by store section. Units are converted only within their own family (volume or weight). Vague amounts like "to taste" are listed as-is instead of guessed (`api/app/grocery.py`).
- **Prep plan.** Choose a batch-prep session (make-ahead items first) or a cook-each-day list (`api/app/prep.py`).
- **Food logging.** Search foods from USDA FoodData Central and log what you ate each day.
- **Auth.** JWT access tokens and rotating refresh tokens (revoked on logout), with bcrypt password hashing.

## Tech stack

| Layer | Technology |
|---|---|
| Client | Flutter (web + mobile), Riverpod, GoRouter, Dio, fl_chart |
| API | FastAPI, Pydantic v2, SQLAlchemy 2, Alembic |
| Optimisation | PuLP (CBC solver) |
| Data | PostgreSQL 16, Redis 7, USDA FoodData Central |
| Infra | Docker Compose |

## Repository layout

```
api/                 FastAPI backend
  app/
    routers/         auth, profile, foods, logs, recipes, solve, meal_plan
    solver.py        integer-programming meal solver (pure, no DB)
    nutrition.py     target calculation (pure)
    grocery.py       grocery-list aggregation (pure)
    prep.py          prep-plan builder (pure)
    scripts/         USDA loader and recipe seeding
  migrations/        Alembic migrations
  tests/             pytest suite for the solver and nutrition math
app/                 Flutter client
  lib/
    models/  providers/  screens/  services/  widgets/
infra/               docker-compose.yml and .env.example
docs/                technical design document and implementation plan
```

The core logic (solver, nutrition, grocery, prep) lives in pure modules with no database or web-framework imports. That keeps it testable on its own, and the routers stay thin.

## Running locally

**Backend**

```bash
cp infra/.env.example infra/.env        # then set DB_PASSWORD and JWT_SECRET_KEY
cd infra
docker compose up -d --build
docker compose exec api alembic upgrade head
docker compose exec api python -m app.scripts.load_usda      # needs USDA CSVs in api/data/usda/
docker compose exec api python -m app.scripts.seed_recipes
```

Interactive API docs are at `http://localhost:8000/docs`.

**Tests**

```bash
cd api
pip install -r requirements.txt pytest
pytest
```

**Client**

```bash
cd app
flutter pub get
flutter run -d chrome
```

The client points at `https://api.macro-forge.org` by default. To use a local backend, change `baseUrl` in `app/lib/services/api_client.dart`.

## Design docs

The full technical design and the build plan are in [`docs/`](docs/).
