from datetime import datetime, timedelta, timezone
import re
from uuid import UUID

from .models import AnswerBlock, Citation, Query, Response
from .policy import any_phrase, decide
from .retrieval import BM25, VARIANTS, contains, normalize, topics
from .conversation import contextualize, focused_paragraphs


class Engine:
    def __init__(self, artifact=None, max_review_days=180, generator=None):
        self.version = artifact["corpus_version"] if artifact else None
        self.documents = artifact["documents"] if artifact else []
        self.index = BM25(self.documents)
        self.max_review_days = max_review_days
        self.generator=generator

    def retrieve(self, query, code):
        normalized = normalize(query.message)
        variants = {target for phrase, target in VARIANTS.items() if contains(normalized, phrase)}
        now = datetime.now(timezone.utc)
        candidates = []
        for index, doc in enumerate(self.documents):
            checked = datetime.fromisoformat(doc["checked_at"].replace("Z", "+00:00"))
            if not now - timedelta(days=self.max_review_days) <= checked <= now:
                continue
            if doc["category_code"] != code:
                continue
            if doc["age_group"] != "ALL" and doc["age_group"] != query.age_group:
                continue
            if variants and not any(contains(normalize(doc["title"]), variant) for variant in variants):
                continue
            candidates.append(index)
        return self.index.search(query.message, candidates)

    def query(self, query: Query, *, image_topic=None):
        response = Response(request_id=query.request_id, status="insufficient_evidence",
                            corpus_version=self.version)
        policy = decide(query.message)
        if policy:
            response.status = policy
            if policy == "emergency_redirect":
                response.safety_message_code = "CONTACT_HELP"
            return response
        if self.version is None:
            response.status = "unavailable"
            return response
        original_message=query.message
        if image_topic:
            label = next(d['category_name'] for d in self.documents if d['category_code'] == image_topic)
            query = query.model_copy(update={'message': f'{query.message} {label}'})
            codes = {image_topic}
        else:
            query = contextualize(query)
            codes = topics(query.message)
        if not codes:
            return response
        if len(codes) > 1:
            response.status = "clarification_needed"
            response.clarification_question = "Bạn muốn tìm hiểu tình huống nào? Hãy hỏi riêng từng tình huống."
            return response
        code = next(iter(codes))
        response.suggested_category_code = code
        text = normalize(query.message)
        if code == "FA11" and any_phrase(text, ["hoa chat", "axit", "acid", "dien", "bong nang", "bong rong"]):
            # The reviewed burn article only covers minor thermal burns.
            return response
        variants = {target for phrase, target in VARIANTS.items() if contains(text, phrase)}
        if len(variants) > 1:
            response.status = "clarification_needed"
            response.clarification_question = "Bạn muốn tìm hiểu tình huống cụ thể nào? Hãy hỏi riêng từng tình huống."
            return response
        mentions_child = any_phrase(text, ["tre em", "tre", "be", "hoc sinh"])
        mentions_adult = any_phrase(text, ["nguoi lon", "nguoi truong thanh"])
        ages = [int(age) for age in re.findall(r"\b(\d+) tuoi\b", text)]
        months = [int(age) for age in re.findall(r"\b(\d+) thang\b", text)]
        mentions_child |= any(1 <= age < 18 for age in ages) or any(12 <= age < 216 for age in months)
        mentions_adult |= any(age >= 18 for age in ages) or any(age >= 216 for age in months)
        if ((mentions_child and query.age_group == "ADULT") or
                (mentions_adult and query.age_group == "CHILD") or
                (code in ("FA02", "FA03", "FA04") and query.age_group in (None, "ALL"))):
            response.status = "clarification_needed"
            response.clarification_question = (
                "Bạn cần bài cho người lớn hay trẻ em từ 1 tuổi? "
                "Hãy chọn đúng đối tượng và gửi lại câu hỏi đầy đủ. Chưa hỗ trợ trẻ dưới 1 tuổi.")
            return response
        if code == "FA18" and not any(contains(text, key) for key in VARIANTS):
            response.status = "clarification_needed"
            response.clarification_question = "Bạn muốn tìm hiểu chó cắn, rắn cắn hay ong đốt?"
            return response
        matches = self.retrieve(query, code)
        if not matches:
            return response
        document = matches[0][1]
        selected=focused_paragraphs(document,original_message)
        needs_generation=selected is None
        if needs_generation:
            if image_topic or self.generator is None or not any_phrase(normalize(original_message),['tai sao','vi sao']): return response
            selected=document['paragraphs']
        # Deterministic extractive answer: all text comes from a single complete,
        # reviewed article. No model can add doses or fabricate citations.
        response.citations = [Citation(id=f"c{index}", evidence_id=document["evidence_id"],
                                       article_id=document["article_id"],
                                       article_revision=document["article_revision"], **reference)
                              for index, reference in enumerate(document["references"], start=1)]
        ids = [citation.id for citation in response.citations]
        sections = document.get('sections', {})
        def block_kind(index, paragraph):
            if index == 0:
                return 'heading'
            for key, kind in [('warnings','warning'), ('seek_help','help'), ('steps','steps')]:
                if paragraph in sections.get(key, []):
                    return kind
            return 'paragraph'
        response.answer_blocks = [AnswerBlock(text=paragraph, citation_ids=ids,kind=block_kind(i, paragraph))
                                  for i,paragraph in enumerate(selected)]
        if not image_topic and self.generator is not None and document.get('sections'):
            generated=self.generator.generate(query.model_copy(update={'message':original_message}),document,selected,ids)
            if generated:
                response.answer_blocks=generated
                response.generation_mode='grounded'
            elif needs_generation:
                response.answer_blocks=[]
                response.citations=[]
                return response
        response.suggested_article_id = UUID(document["article_id"])
        response.status = "answered"
        return response
