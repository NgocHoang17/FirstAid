import json

import pytest

from firstaid_rag.corpus import compile_corpus, load_artifact, write_artifact


def test_all_reviewed_articles_preserve_scope_warnings_and_references(library, artifact):
    assert len(artifact["documents"]) == 24
    assert len({doc["category_code"] for doc in artifact["documents"]}) == 18
    for document in artifact["documents"]:
        article = next(a for a in library["articles"] if a["id"] == document["article_id"])
        assert article["applies_to"] in document["paragraphs"]
        assert all(warning in document["paragraphs"] for warning in article["warnings"])
        assert len(document["references"]) == len(article["references"])
        assert document["article_revision"] == article["content_revision"]


@pytest.mark.parametrize("field,value", [("status", "DRAFT"), ("content_checked", False)])
def test_unreviewed_and_draft_are_excluded(library, field, value):
    library["articles"][0][field] = value
    assert len(compile_corpus(library)["documents"]) == 23


def test_untrusted_raw_and_quiz_are_not_ingested(library):
    library["quiz"] = ["MALICIOUS QUIZ ANSWER"]
    library["articles"][0]["quiz"] = "MALICIOUS QUIZ ANSWER"
    assert "MALICIOUS QUIZ ANSWER" not in json.dumps(compile_corpus(library))
    with pytest.raises(ValueError):
        compile_corpus({"schema_version": 2, "kind": "raw_pdf"})


@pytest.mark.parametrize("mutation", ["inactive", "missing", "page", "duplicate", "revision", "review"])
def test_invalid_published_evidence_fails_build(library, mutation):
    if mutation == "inactive":
        library["sources"][0]["is_active"] = False
    elif mutation == "missing":
        library["sources"].pop(0)
    elif mutation == "page":
        library["articles"][0]["references"][0]["page_end"] = 10000
    elif mutation == "duplicate":
        library["articles"].append(library["articles"][0])
    elif mutation == "revision":
        library["articles"][0]["content_revision"] = 0
    else:
        library["articles"][0]["checked_at"] = "2099-01-01T00:00:00Z"
    with pytest.raises(ValueError):
        compile_corpus(library)


def test_artifact_integrity_and_atomic_replacement(tmp_path, artifact, library, monkeypatch):
    path = tmp_path / "index.json"
    write_artifact(artifact, path)
    assert load_artifact(path) == artifact
    library["articles"][0]["content_revision"] += 1
    replacement = compile_corpus(library)
    assert replacement["corpus_version"] != artifact["corpus_version"]
    def fail_replace(*args):
        raise OSError("disk unavailable")
    monkeypatch.setattr("firstaid_rag.corpus.os.replace", fail_replace)
    with pytest.raises(OSError):
        write_artifact(replacement, path)
    assert load_artifact(path) == artifact
    assert len(list(tmp_path.iterdir())) == 1
    artifact["documents"][0]["paragraphs"][0] = "tampered"
    path.write_text(json.dumps(artifact), encoding="utf-8")
    with pytest.raises(ValueError):
        load_artifact(path)
