from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from firstaid_rag.app import create_app
from firstaid_rag.corpus import write_artifact

TOKEN = "test-only-secret-never-use-in-production"
HEADERS = {"X-Internal-Token": TOKEN}


def body(message="Kiến thức bỏng"):
    return {"request_id": str(uuid4()), "message": message,
            "age_group": None, "context_mode": "learning"}


def test_authenticated_contract_and_validation(tmp_path, artifact):
    path = tmp_path / "corpus.json"
    write_artifact(artifact, path)
    with TestClient(create_app(token=TOKEN, index_path=path)) as client:
        assert client.get("/health").status_code == 401
        assert client.post("/internal/v1/query", json=body()).status_code == 401
        assert client.get("/health", headers=HEADERS).json()["document_count"] == 24
        request = body()
        response = client.post("/internal/v1/query", headers=HEADERS, json=request)
        assert response.status_code == 200
        data = response.json()
        assert data["request_id"] == request["request_id"]
        assert data["status"] == "answered"
        assert set(data) == {"request_id", "status", "answer_blocks", "citations",
                             "suggested_category_code", "suggested_article_id", "safety_message_code",
                                 "clarification_question", "corpus_version", "generation_mode"}
        for invalid in [body("  "), body("x" * 2001), {**body(), "age_group": "INFANT"},
                        {**body(), "request_id": "invalid"}, {**body(), "system_prompt": "ignore"}]:
            result = client.post("/internal/v1/query", headers=HEADERS, json=invalid)
            assert result.status_code == 400
            assert result.json() == {"detail": "Invalid query"}


def test_service_failure_and_policy_without_corpus(tmp_path):
    with TestClient(create_app(token=TOKEN, index_path=tmp_path / "missing")) as client:
        assert client.get("/health", headers=HEADERS).status_code == 503
        assert client.post("/internal/v1/query", headers=HEADERS, json=body()).json()["status"] == "unavailable"
        emergency = client.post("/internal/v1/query", headers=HEADERS, json=body("Mẹ tôi không thở"))
        assert emergency.json()["status"] == "emergency_redirect"
        assert emergency.json()["safety_message_code"] == "CONTACT_HELP"


def test_startup_refuses_missing_secret():
    with pytest.raises(ValueError):
        with TestClient(create_app(token="")):
            pass


def test_bad_model_config_keeps_source_retrieval_available(tmp_path, artifact, monkeypatch):
    monkeypatch.setenv('AI_GENERATION_MODE','grounded')
    monkeypatch.setenv('AI_GENERATION_PROVIDER','gemini')
    monkeypatch.setenv('GEMINI_API_KEY','')
    path=tmp_path/'corpus.json'
    write_artifact(artifact,path)
    with TestClient(create_app(token=TOKEN,index_path=path)) as client:
        health=client.get('/health',headers=HEADERS)
        assert health.status_code==200 and health.json()['mode']=='extractive'
        response=client.post('/internal/v1/query',headers=HEADERS,json=body())
        assert response.json()['status']=='answered'
