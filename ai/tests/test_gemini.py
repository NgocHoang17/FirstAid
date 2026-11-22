import json

import httpx
import pytest

from firstaid_rag.generation import GeminiGenerator, GroundedGenerator
from test_generation import ask


def provider(change=None, verify=True, failure=None):
    calls=[]
    def serve(request):
        calls.append(request)
        if isinstance(failure,int): return httpx.Response(failure)
        data=json.loads(request.content)
        content=json.loads(data['contents'][0]['parts'][0]['text'])
        if 'FOCUS' in content:
            text=content['FOCUS'][2]
            evidence=next(k for k,v in content['EVIDENCE'].items() if v==text)
            draft={'supported':True,'blocks':[{'kind':'paragraph','text':text,'evidence_ids':[evidence]}]}
            if change: change(draft)
        else: draft={'supported':verify}
        payload={'candidates':[{'finishReason':'STOP','content':{'parts':[{'text':json.dumps(draft)}]}}]}
        if failure=='truncated': payload['candidates'][0]['finishReason']='MAX_TOKENS'
        if failure=='blocked': payload={'promptFeedback':{'blockReason':'SAFETY'}}
        if failure=='empty': payload={'candidates':[]}
        if failure=='malformed': payload['candidates'][0]['content']['parts']=[{'text':'not json'}]
        return httpx.Response(200,json=payload)
    return GeminiGenerator('test-model','secret-test-key',transport=httpx.MockTransport(serve)),calls


def test_gemini_structured_generation_keeps_secret_in_header_and_verifies(artifact):
    generator,calls=provider()
    reply=ask(artifact,generator)
    assert reply.generation_mode=='grounded' and len(calls)==2
    for request in calls:
        assert request.url.host=='generativelanguage.googleapis.com'
        assert request.url.path.endswith('/test-model:generateContent')
        assert request.headers['x-goog-api-key']=='secret-test-key'
        assert 'secret-test-key' not in str(request.url) and b'secret-test-key' not in request.content
        data=json.loads(request.content)
        assert data['systemInstruction']['parts'][0]['text']
        assert data['generationConfig']['responseMimeType']=='application/json'
        assert data['generationConfig']['responseJsonSchema']['type']=='object'


@pytest.mark.parametrize('failure',[401,429,503,'truncated','blocked','empty','malformed'])
def test_gemini_errors_fall_back_without_exposing_provider_output(artifact,failure):
    generator,calls=provider(failure=failure)
    reply=ask(artifact,generator)
    assert reply.status=='answered' and reply.generation_mode=='extractive'
    assert len(calls)==1
    assert 'secret-test-key' not in reply.model_dump_json()


def test_gemini_cannot_bypass_evidence_checks_or_verification(artifact):
    for kwargs in [{'change':lambda draft:draft['blocks'][0].update(evidence_ids=['fake'])},{'verify':False}]:
        generator,_=provider(**kwargs)
        assert ask(artifact,generator).generation_mode=='extractive'


def test_gemini_environment_and_no_requests_in_extractive_mode(monkeypatch):
    monkeypatch.setenv('AI_GENERATION_MODE','grounded')
    monkeypatch.setenv('AI_GENERATION_PROVIDER','gemini')
    monkeypatch.setenv('GEMINI_API_KEY','test-secret')
    assert isinstance(GroundedGenerator.from_environment(),GeminiGenerator)
    monkeypatch.setenv('GEMINI_API_KEY','')
    with pytest.raises(ValueError): GroundedGenerator.from_environment()
    monkeypatch.setenv('AI_GENERATION_MODE','extractive')
    assert GroundedGenerator.from_environment() is None


def test_gemini_does_not_receive_emergency_questions(artifact):
    generator,calls=provider()
    assert ask(artifact,generator,'Con tôi không thở').status=='emergency_redirect'
    assert not calls
