from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, RefreshToken
from app.schemas import (
    UserRegister,
    UserLogin,
    UserPublic,
    TokenResponse,
    RefreshRequest,
)
from app.security import (
    hash_password,
    verify_password,
    create_access_token,
    decode_access_token,
    generate_refresh_token,
    refresh_token_expiry,
)

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")


# ── Helper: issue a fresh access + refresh token pair ─────────
def _issue_tokens(user: User, db: Session) -> TokenResponse:
    access = create_access_token(str(user.id))
    refresh = generate_refresh_token()
    db_token = RefreshToken(
        user_id=user.id,
        token=refresh,
        expires_at=refresh_token_expiry(),
    )
    db.add(db_token)
    db.commit()
    return TokenResponse(access_token=access, refresh_token=refresh)


# ── Dependency: get current user from access token ───────────
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user_id = decode_access_token(token)
    if user_id is None:
        raise credentials_exception
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user


# ── POST /auth/register ───────────────────────────────────────
@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: UserRegister, db: Session = Depends(get_db)):
    if len(payload.password.encode("utf-8")) > 72:
        raise HTTPException(status_code=400, detail="Password must be 72 bytes or fewer.")
    if len(payload.password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters.")
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="An account with this email already exists.")
    user = User(email=payload.email, hashed_password=hash_password(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_tokens(user, db)


# ── POST /auth/login ──────────────────────────────────────────
@router.post("/login", response_model=TokenResponse)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if user is None or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect email or password.")
    return _issue_tokens(user, db)


# ── POST /auth/refresh ────────────────────────────────────────
@router.post("/refresh", response_model=TokenResponse)
def refresh(payload: RefreshRequest, db: Session = Depends(get_db)):
    invalid = HTTPException(status_code=401, detail="Invalid or expired refresh token.")

    db_token = db.query(RefreshToken).filter(
        RefreshToken.token == payload.refresh_token
    ).first()

    if db_token is None or db_token.revoked:
        raise invalid
    if db_token.expires_at < datetime.now(timezone.utc):
        raise invalid

    user = db.query(User).filter(User.id == db_token.user_id).first()
    if user is None:
        raise invalid

    # Rotate: revoke the old refresh token, issue a new pair
    db_token.revoked = True
    db.commit()
    return _issue_tokens(user, db)


# ── POST /auth/logout ─────────────────────────────────────────
@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(payload: RefreshRequest, db: Session = Depends(get_db)):
    db_token = db.query(RefreshToken).filter(
        RefreshToken.token == payload.refresh_token
    ).first()
    if db_token:
        db_token.revoked = True
        db.commit()
    return None


# ── GET /auth/me ──────────────────────────────────────────────
@router.get("/me", response_model=UserPublic)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user