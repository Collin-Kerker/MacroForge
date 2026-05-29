from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth

app = FastAPI(title="MacroForge API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # we'll tighten this later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)


@app.get("/health")
def health():
    return {"status": "ok", "service": "macroforge-api"}