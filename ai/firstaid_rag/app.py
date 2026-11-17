import logging
import os
import secrets
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from .corpus import load_artifact
from .engine import Engine
from .models import Query, Response

logger = logging.getLogger(__name__)


def create_app(*, token=None, index_path=None, max_review_days=None):
    secret = token if token is not None else os.getenv("AI_INTERNAL_TOKEN", "")
    path = Path(index_path or os.getenv("AI_INDEX_PATH", "data/index/corpus.json"))
    review_days = int(max_review_days or os.getenv("AI_MAX_REVIEW_DAYS", "180"))
    if review_days < 1 or review_days > 365:
        raise ValueError("AI_MAX_REVIEW_DAYS must be between 1 and 365")

    @asynccontextmanager
    async def lifespan(app):
        if len(secret) < 24:
            raise ValueError("Set AI_INTERNAL_TOKEN to a random secret of at least 24 characters")
        try:
            app.state.engine = Engine(load_artifact(path), review_days)
        except (OSError, ValueError, KeyError, TypeError):
            logger.error("Corpus unavailable; query responses will fail closed")
            app.state.engine = Engine()
        yield

    app = FastAPI(title="FirstAid internal retrieval", lifespan=lifespan,
                  docs_url=None, redoc_url=None, openapi_url=None)

    def authenticate(x_internal_token: str | None = Header(default=None)):
        if not x_internal_token or not secrets.compare_digest(x_internal_token, secret):
            raise HTTPException(status_code=401, detail="Unauthorized")

    @app.exception_handler(RequestValidationError)
    async def validation_error(request, exc):
        # Do not echo the user's potentially sensitive message in validation details.
        return JSONResponse(status_code=400, content={"detail": "Invalid query"})

    @app.get("/health", dependencies=[Depends(authenticate)])
    def health():
        engine = app.state.engine
        return JSONResponse(status_code=200 if engine.version else 503, content={
            "status": "ready" if engine.version else "unavailable",
            "mode": "extractive", "corpus_version": engine.version,
            "document_count": len(engine.documents)})

    @app.post("/internal/v1/query", response_model=Response, dependencies=[Depends(authenticate)])
    def query(body: Query):
        try:
            return app.state.engine.query(body)
        except (ValueError, KeyError, TypeError):
            logger.error("Evidence validation failed; answer withheld")
            return Response(request_id=body.request_id, status="unavailable")

    return app
