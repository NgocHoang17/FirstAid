"""Optional model-backed, evidence-bounded generation with extractive fallback.

Semantic checking reduces risk; it is not an independent clinical validation.
"""
import json
import os
import re
import time
from threading import BoundedSemaphore
from urllib.parse import urlparse
import httpx
from pydantic import BaseModel, ConfigDict, Field
from typing import Literal
from .prompts import SYSTEM_PROMPT, VERIFY_PROMPT, PROMPT_VERSION
from .models import AnswerBlock
from .retrieval import normalize

class GeneratedBlock(BaseModel):
    model_config = ConfigDict(extra='forbid')
    kind: Literal['paragraph','heading','steps']
    text: str = Field(min_length=1,max_length=2000)
    evidence_ids: list[str] = Field(min_length=1,max_length=30)

class Draft(BaseModel):
    model_config = ConfigDict(extra='forbid')
    supported: bool
    blocks: list[GeneratedBlock] = Field(max_length=12)

class Verdict(BaseModel):
    model_config = ConfigDict(extra='forbid')
    supported: bool

class GroundedGenerator:
    def __init__(self, base_url, model, timeout=8, transport=None):
        parsed=urlparse(base_url)
        if parsed.scheme not in ('http','https') or not parsed.hostname or parsed.username or parsed.password or parsed.query or parsed.fragment:
            raise ValueError('Invalid model server URL')
        if not model.strip() or not 1 <= timeout <= 90:
            raise ValueError('Configure model name and a bounded timeout')
        self.url=base_url.rstrip('/')+'/api/chat'
        self.model=model
        self.timeout=timeout
        self.transport=transport
        self.slot=BoundedSemaphore(1)

    @classmethod
    def from_environment(cls):
        mode=os.getenv('AI_GENERATION_MODE','extractive')
        if mode=='extractive': return None
        if mode!='grounded': raise ValueError('Unknown AI_GENERATION_MODE')
        provider=os.getenv('AI_GENERATION_PROVIDER','gemini')
        if provider=='gemini':
            return GeminiGenerator(os.getenv('AI_GEMINI_MODEL','gemini-3.8-flash'),
                                   os.getenv('GEMINI_API_KEY',''),
                                   float(os.getenv('AI_GENERATION_TIMEOUT_SECONDS','30')))
        if provider!='ollama': raise ValueError('Unknown AI_GENERATION_PROVIDER')
        return cls(os.getenv('AI_OLLAMA_URL','http://127.0.0.1:11434'),
                   os.getenv('AI_OLLAMA_MODEL',''),float(os.getenv('AI_GENERATION_TIMEOUT_SECONDS','8')))

    def _chat(self, client, prompt, content, schema, deadline):
        remaining=deadline-time.monotonic()
        if remaining <= 0: raise ValueError('Generation budget exceeded')
        result=client.post(self.url,json={
            'model':self.model,'stream':False,'think':False,'keep_alive':'5m',
            'messages':[{'role':'system','content':prompt},
                        {'role':'user','content':json.dumps(content,ensure_ascii=False)}],
            'format':schema.model_json_schema(),
            'options':{'temperature':0,'num_predict':1000,'num_ctx':8192},
        },timeout=remaining)
        result.raise_for_status()
        payload=result.json()
        if payload.get('done') is not True or payload.get('done_reason')=='length':
            raise ValueError('Incomplete model response')
        return schema.model_validate_json(payload['message']['content'])

    def generate(self, query, document, selected, citation_ids):
        if not self.slot.acquire(blocking=False): return None
        try: return self._generate(query,document,selected,citation_ids)
        finally: self.slot.release()

    def _generate(self, query, document, selected, citation_ids):
        deadline=time.monotonic()+self.timeout
        evidence={f'e{i+1}':text for i,text in enumerate(document['paragraphs'])}
        scope=document['paragraphs'][1]
        # Send the complete reviewed article so omitted exceptions remain visible
        # to both model calls. The focused spans guide relevance, not the evidence.
        content={'prompt_version':PROMPT_VERSION,'QUESTION':query.message,
                 'HISTORY':query.context_messages,'AGE_GROUP':query.age_group,
                 'SCOPE':scope,'EVIDENCE':evidence,'FOCUS':selected}
        try:
            with httpx.Client(timeout=self.timeout,trust_env=False,transport=self.transport,follow_redirects=False) as client:
                draft=self._chat(client,SYSTEM_PROMPT,content,Draft,deadline)
                if not draft.supported or not draft.blocks: return None
                for block in draft.blocks:
                    if len(set(block.evidence_ids))!=len(block.evidence_ids) or any(key not in evidence for key in block.evidence_ids): return None
                    support='\n'.join(evidence[key] for key in block.evidence_ids)
                    # A source ID is not proof of entailment. Reject obvious new
                    # quantities/actions before the separate semantic review.
                    numbers=set(re.findall(r'\d+(?:[.,]\d+)?',block.text))
                    if not numbers.issubset(set(re.findall(r'\d+(?:[.,]\d+)?',support))): return None
                    if any(term in block.text for term in ('http://','https://','```','<script','**')): return None
                    for action in ['uong thuoc','boi kem','khang sinh','tiem','ke don']:
                        if action in normalize(block.text) and action not in normalize(support): return None
                verdict=self._chat(client,VERIFY_PROMPT,{'QUESTION':query.message,'AGE_GROUP':query.age_group,'SCOPE':scope,'EVIDENCE':evidence,'DRAFT':draft.model_dump()},Verdict,deadline)
                if not verdict.supported: return None
                blocks=[AnswerBlock(text=block.text,citation_ids=citation_ids,kind=block.kind) for block in draft.blocks]
                # Retain scope and all source warnings/help verbatim as a second
                # layer. A model cannot silently omit these critical boundaries.
                mandatory=[('paragraph',scope)]+[('warning',s) for s in document['sections']['warnings']]+[('help',s) for s in document['sections']['seek_help']]
                seen={block.text for block in blocks}
                for kind,text in mandatory:
                    if text not in seen:
                        blocks.append(AnswerBlock(text=text,citation_ids=citation_ids,kind=kind));seen.add(text)
                return blocks
        except (httpx.HTTPError,ValueError,KeyError,TypeError,IndexError,AttributeError):
            return None


class GeminiGenerator(GroundedGenerator):
    """Server-side Gemini REST adapter; uses the same evidence checks as local models."""

    def __init__(self, model, api_key, timeout=30, transport=None):
        if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]{0,127}',model):
            raise ValueError('Invalid Gemini model ID')
        if not api_key.strip():
            raise ValueError('Set GEMINI_API_KEY on the AI server')
        super().__init__('https://generativelanguage.googleapis.com',model,timeout,transport)
        self.url=f'https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent'
        self._api_key=api_key.strip()

    def _chat(self, client, prompt, content, schema, deadline):
        remaining=deadline-time.monotonic()
        if remaining<=0: raise ValueError('Generation budget exceeded')
        result=client.post(self.url,headers={'x-goog-api-key':self._api_key},json={
            'systemInstruction':{'parts':[{'text':prompt}]},
            'contents':[{'role':'user','parts':[{'text':json.dumps(content,ensure_ascii=False)}]}],
            'generationConfig':{
                'temperature':0,'maxOutputTokens':4096,'candidateCount':1,
                'responseMimeType':'application/json',
                'responseJsonSchema':schema.model_json_schema(),
            },
        },timeout=remaining)
        result.raise_for_status()
        payload=result.json()
        if payload.get('promptFeedback',{}).get('blockReason'):
            raise ValueError('Provider blocked prompt')
        candidates=payload.get('candidates',[])
        if len(candidates)!=1 or candidates[0].get('finishReason')!='STOP':
            raise ValueError('Incomplete or blocked model response')
        parts=candidates[0]['content']['parts']
        text=''.join(part.get('text','') for part in parts if not part.get('thought'))
        return schema.model_validate_json(text)
