"""Refresh the in-memory search index from the public educational snapshot."""
import asyncio
import logging

import httpx

from .corpus import compile_corpus, write_artifact
from .engine import Engine

log = logging.getLogger(__name__)


async def refresh(client, url, etag, app, path, review_days):
    response = await client.get(url, headers={'If-None-Match':etag} if etag else {})
    if response.status_code == 304:
        return etag
    response.raise_for_status()
    artifact = await asyncio.to_thread(compile_corpus, response.json())
    current = app.state.engine
    if current.version != artifact['corpus_version']:
        replacement = await asyncio.to_thread(Engine, artifact, review_days, current.generator)
        await asyncio.to_thread(write_artifact, artifact, path)
        app.state.engine = replacement
    return response.headers.get('etag')


async def watch(url, app, path, review_days):
    etag = None
    async with httpx.AsyncClient(timeout=8,trust_env=False,follow_redirects=False) as client:
        while True:
            try:
                etag = await refresh(client,url,etag,app,path,review_days)
            except (httpx.HTTPError, OSError, ValueError, TypeError, KeyError):
                log.warning('Public snapshot refresh failed')
            await asyncio.sleep(30)
