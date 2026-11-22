import asyncio
from types import SimpleNamespace
import httpx
from firstaid_rag.engine import Engine
from firstaid_rag.snapshot_sync import refresh
from firstaid_rag.corpus import load_artifact

def test_publish_and_unpublish_swap_engine_then_use_etag(tmp_path,library,artifact):
    app=SimpleNamespace(state=SimpleNamespace(engine=Engine(artifact)))
    source=library['articles'][0]
    source['status']='DRAFT'
    def snapshot(request):
        if request.headers.get('If-None-Match')=='"new"':
            return httpx.Response(304)
        return httpx.Response(200,json=library,headers={'etag':'"new"'})
    async def run():
        path=tmp_path/'index.json'
        async with httpx.AsyncClient(transport=httpx.MockTransport(snapshot)) as client:
            etag=await refresh(client,'https://example.test/snapshot',None,app,path,180)
            current=app.state.engine
            assert not any(d['article_id']==source['id'] for d in current.documents)
            assert current.version==load_artifact(path)['corpus_version']
            assert await refresh(client,'https://example.test/snapshot',etag,app,path,180)==etag
            assert app.state.engine is current
    asyncio.run(run())
