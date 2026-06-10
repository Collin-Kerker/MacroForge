from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth, profile, foods, logs, recipes, solve, meal_plan

app = FastAPI(title="MacroForge API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(profile.router)
app.include_router(foods.router)
app.include_router(logs.router)
app.include_router(recipes.router)
app.include_router(solve.router)
app.include_router(meal_plan.router)

@app.get("/health")
def health():
    return {"status": "ok", "service": "macroforge-api"}