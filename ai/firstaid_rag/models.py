from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

AgeGroup = Literal["ADULT", "CHILD", "ALL"]
Status = Literal[
    "answered", "clarification_needed", "emergency_redirect",
    "insufficient_evidence", "out_of_scope", "unavailable",
]


class Query(BaseModel):
    model_config = ConfigDict(extra="forbid")
    request_id: UUID
    message: str = Field(min_length=1, max_length=2000)
    age_group: AgeGroup | None = None
    context_mode: Literal["learning", "unspecified"] = "unspecified"

    @field_validator("message", mode="before")
    @classmethod
    def trim_message(cls, value):
        return value.strip() if isinstance(value, str) else value


class Citation(BaseModel):
    id: str
    evidence_id: str
    source_id: UUID
    source_revision: int = Field(gt=0)
    source_title: str
    page_start: int | None
    page_end: int | None
    article_id: UUID
    article_revision: int = Field(gt=0)


class AnswerBlock(BaseModel):
    text: str
    citation_ids: list[str]


class Response(BaseModel):
    request_id: UUID
    status: Status
    answer_blocks: list[AnswerBlock] = Field(default_factory=list)
    citations: list[Citation] = Field(default_factory=list)
    suggested_category_code: str | None = None
    suggested_article_id: UUID | None = None
    safety_message_code: Literal["CONTACT_HELP", "OPEN_FIRST_AID_GUIDE"] | None = None
    clarification_question: str | None = None
    corpus_version: str | None = None
