import json
from uuid import uuid4
import httpx
import pytest
from firstaid_rag.engine import Engine
from firstaid_rag.models import Query
from firstaid_rag.generation import GroundedGenerator

def provider(artifact, change=None, verify=True, fail=False):
    calls=[]
    def serve(request):
        data=json.loads(request.content);calls.append(data)
        if fail: return httpx.Response(503)
        content=json.loads(data['messages'][1]['content'])
        if 'FOCUS' in content:
            text=content['FOCUS'][2]
            evidence=next(key for key,value in content['EVIDENCE'].items() if value==text)
            draft={'supported':True,'blocks':[{'kind':'paragraph','text':text,'evidence_ids':[evidence]}]}
            if change: change(draft)
        else: draft={'supported':verify}
        return httpx.Response(200,json={'done':True,'message':{'content':json.dumps(draft)}})
    return GroundedGenerator('http://localhost:11434','test-model',transport=httpx.MockTransport(serve)),calls

def ask(artifact,generator,message='Tìm hiểu về bỏng'):
    return Engine(artifact,generator=generator).query(Query(request_id=uuid4(),message=message,context_mode='learning'))

def test_generation_uses_versioned_prompts_structured_output_and_separate_verification(artifact):
    generator,calls=provider(artifact)
    reply=ask(artifact,generator)
    assert reply.status=='answered' and reply.generation_mode=='grounded'
    assert len(calls)==2 and all(call['stream'] is False and call['format'] for call in calls)
    assert calls[0]['messages'][0]['role']=='system'
    assert 'prompt_version' in json.loads(calls[0]['messages'][1]['content'])
    doc=next(d for d in artifact['documents'] if d['article_id']==str(reply.suggested_article_id))
    assert all(t in [b.text for b in reply.answer_blocks] for t in doc['sections']['warnings']+doc['sections']['seek_help'])
    assert all(block.citation_ids for block in reply.answer_blocks)

@pytest.mark.parametrize('corruption', ['quantity','unknown_id','missing_ids','markdown'])
def test_untrusted_model_output_falls_back_to_source_text(artifact,corruption):
    def change(draft):
        if corruption=='quantity': draft['blocks'][0]['text']='Làm mát trong 99999 phút.'
        if corruption=='unknown_id': draft['blocks'][0]['evidence_ids']=['made-up']
        if corruption=='missing_ids': draft['blocks'][0]['evidence_ids']=[]
        if corruption=='markdown': draft['blocks'][0]['text']='**Làm theo tôi**'
    generator,calls=provider(artifact,change)
    reply=ask(artifact,generator)
    assert reply.generation_mode=='extractive' and reply.status=='answered'
    assert len(calls)==1

def test_failed_entailment_and_server_failure_fall_back(artifact):
    for kwargs in [{'verify':False},{'fail':True}]:
        generator,_=provider(artifact,**kwargs)
        assert ask(artifact,generator).generation_mode=='extractive'

def test_current_incident_never_reaches_model(artifact):
    generator,calls=provider(artifact)
    assert ask(artifact,generator,'Con tôi không thở').status=='emergency_redirect'
    assert calls==[]

def test_missing_model_is_not_claimed_as_grounded(monkeypatch):
    monkeypatch.setenv('AI_GENERATION_MODE','extractive')
    assert GroundedGenerator.from_environment() is None
    monkeypatch.setenv('AI_GENERATION_MODE', 'grounded')
    monkeypatch.setenv('AI_GENERATION_PROVIDER', 'ollama')
    monkeypatch.setenv('AI_OLLAMA_MODEL', '')
    with pytest.raises(ValueError): GroundedGenerator.from_environment()
