import re
from .policy import decide, any_phrase
from .retrieval import normalize, topics, TOPICS, VARIANTS, contains

def contextualize(query):
    """Resolve bounded topic references, never trust previous answers as evidence."""
    message=query.message
    text=normalize(message)
    current=topics(message)
    age=query.age_group
    if not current and (any_phrase(text,['con','vay','the','truong hop nay','dieu gi','can tranh','khong nen','can lam','buoc','nguoi lon','tre em','bao lau','bao nhieu','tai sao','vi sao','dau hieu','khi nao']) or re.fullmatch(r'\d+ tuoi',text)):
        for previous in reversed(query.context_messages):
            if decide(previous): continue
            if len(topics(previous))==1:
                code=next(iter(topics(previous)))
                variants={target for phrase,target in VARIANTS.items() if contains(normalize(previous),phrase)}
                topic=next(iter(variants)) if len(variants)==1 else TOPICS[code][0]
                message=topic+'\n'+message
                break
    return query.model_copy(update={'message':message[:4000],'age_group':age})

def focused_paragraphs(document, message):
    sections=document.get('sections')
    if not sections: return document['paragraphs']
    text=normalize(message)
    prefix=[document['title'],document['paragraphs'][1]]
    if any_phrase(text,['khong nen','can tranh','luu y','dieu tranh']):
        selected=sections['warnings']
    elif any_phrase(text,['dau hieu','nhan biet','trieu chung']):
        selected=sections['recognition']
    elif match:=re.search(r'\bbuoc (\d+)\b',text):
        index=int(match[1])-1
        if not 0<=index<len(sections['steps']): return None
        selected=[sections['steps'][index]]
    elif any_phrase(text,['tai sao','vi sao']):
        # The source catalogue supplies procedures, not a general explanation model.
        return None
    elif any_phrase(text,['cac buoc','lam gi','can lam','xu ly','xu tri','lam sao','nen lam gi','so cuu nhu the nao']):
        selected=sections['steps']
    elif any_phrase(text,['khi nao','di vien','goi 115','cap cuu']):
        selected=sections['seek_help']
    else: selected=sections['summary']+sections['quick_actions']
    return list(dict.fromkeys(prefix+selected+sections['warnings']+sections['seek_help']))
