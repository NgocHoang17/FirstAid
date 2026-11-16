"""Run the authored regression benchmark; report failures without hiding them."""
import argparse
import json
import sys
import time
from collections import Counter
from pathlib import Path
from uuid import UUID

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cases import CASES
from firstaid_rag.corpus import compile_corpus, read_json
from firstaid_rag.engine import Engine
from firstaid_rag.models import Query
from firstaid_rag.retrieval import topics


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--library", default="../mobile/assets/content/reference_library.json")
    parser.add_argument("--output", default="evaluation/results.json")
    args = parser.parse_args()
    library = read_json(args.library)
    artifact = compile_corpus(library)
    engine = Engine(artifact)
    articles = {a["variant_key"]: a for a in library["articles"]}
    tune = {case["family"] for case in CASES if case["split"] == "tune"}
    test = {case["family"] for case in CASES if case["split"] == "test"}
    assert not tune & test
    assert len(CASES) == 120 and Counter(case["split"] for case in CASES) == {"tune": 40, "test": 80}
    results = []
    for index, case in enumerate(CASES, start=1):
        query = Query(request_id=UUID(int=index), message=case["message"],
                      age_group=case["age_group"], context_mode="learning")
        start = time.perf_counter()
        response = engine.query(query)
        elapsed = (time.perf_counter() - start) * 1000
        gold = articles[case["variant"]]["id"] if case["variant"] else None
        candidates = [doc["article_id"] for code in topics(case["message"])
                      for _, doc in engine.retrieve(query, code)]
        valid = all(any(str(citation.source_id) == ref["source_id"]
                        and citation.source_revision == ref["source_revision"]
                        and citation.page_start == ref["page_start"] and citation.page_end == ref["page_end"]
                        for doc in engine.documents if str(citation.article_id) == doc["article_id"]
                        and citation.article_revision == doc["article_revision"] for ref in doc["references"])
                    for citation in response.citations)
        correct = response.status == case["status"] and (not gold or str(response.suggested_article_id) == gold)
        results.append({"id": case["id"], "split": case["split"], "kind": case["kind"],
                        "correct": correct, "expected": case["status"], "actual": response.status,
                        "recall_at_5": gold in candidates if gold else None,
                        "citations_valid": valid, "answered": response.status == "answered", "latency_ms": elapsed})
    report = {"purpose": "authored regression, not independent medical validation",
              "corpus_version": artifact["corpus_version"], "splits": {}, "results": results}
    for split in ("tune", "test"):
        selected = [row for row in results if row["split"] == split]
        retrieval = [row for row in selected if row["recall_at_5"] is not None]
        answered = [row for row in selected if row["answered"]]
        latencies = sorted(row["latency_ms"] for row in selected)
        report["splits"][split] = {"count": len(selected), "correct": sum(r["correct"] for r in selected),
                                    "recall_at_5": sum(r["recall_at_5"] for r in retrieval) / len(retrieval),
                                    "answered_citations_valid": sum(r["citations_valid"] for r in answered),
                                    "answered_count": len(answered), "p95_engine_ms": latencies[int(.95 * (len(latencies) - 1))]}
    Path(args.output).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report["splits"], indent=2))
    failures = [r for r in results if not r["correct"] or not r["citations_valid"]]
    if failures:
        print(json.dumps(failures, indent=2))
        raise SystemExit(1)


if __name__ == "__main__":
    main()
