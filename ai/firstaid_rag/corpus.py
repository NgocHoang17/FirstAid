"""Compile complete reviewed articles; never ingest raw PDF/quiz text."""
import hashlib
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from uuid import UUID

FORMAT_VERSION = 1
MAX_INPUT_BYTES = 16 * 1024 * 1024


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                     separators=(",", ":")).encode()).hexdigest()


def read_json(path):
    raw = Path(path).read_bytes()
    if len(raw) > MAX_INPUT_BYTES:
        raise ValueError("Corpus exceeds the supported bounded dataset")
    return json.loads(raw)


def unique_by_id(items):
    result = {}
    for item in items:
        identifier = str(UUID(item["id"]))
        if identifier in result:
            raise ValueError("Duplicate ID")
        result[identifier] = item
    return result


def positive(value):
    if type(value) is not int or value < 1:
        raise ValueError("Revision/page must be a positive integer")
    return value


def nonempty(value):
    if not isinstance(value, str) or not value.strip():
        raise ValueError("Missing required text")
    return value


def paragraphs(article):
    # Keep scope, warnings and help alongside actions. Never truncate a condition.
    blocks = [nonempty(article[key]) for key in ("title", "applies_to", "summary")]
    for key in ("recognition", "quick_actions", "steps", "warnings", "seek_help"):
        values = article[key]
        if not isinstance(values, list) or not values:
            raise ValueError("Incomplete reviewed article")
        if key == "steps":
            positions = [positive(step["position"]) for step in values]
            if sorted(positions) != list(range(1, len(values) + 1)):
                raise ValueError("Invalid step order")
            blocks.extend(nonempty(step["title"]) + ": " + nonempty(step["instruction"])
                          for step in sorted(values, key=lambda s: s["position"]))
        else:
            blocks.extend(nonempty(value) for value in values)
    return blocks


def compile_corpus(payload):
    data = payload.get("data", payload)
    if not ((data.get("schema_version") == 2 and data.get("kind") == "reference_library")
            or (data.get("schema_version") == 1 and "app_config" in data)):
        raise ValueError("Expected a reviewed reference library or public snapshot")
    sources = unique_by_id(data["sources"])
    categories = unique_by_id(data["categories"])
    articles = unique_by_id(data["articles"])
    if len(articles) > 500 or len(sources) > 100 or len(categories) > 30:
        raise ValueError("Dataset exceeds shared contract limits")
    documents = []
    for identifier, article in sorted(articles.items()):
        category = categories.get(article["category_id"])
        if (article.get("status") != "PUBLISHED" or article.get("content_checked") is not True
                or not category or category.get("is_active") is not True):
            continue
        checked_at = datetime.fromisoformat(article["checked_at"].replace("Z", "+00:00"))
        if checked_at.tzinfo is None or checked_at > datetime.now(timezone.utc):
            raise ValueError("Invalid review timestamp")
        if article["age_group"] not in ("ALL", "ADULT", "CHILD"):
            raise ValueError("Unsupported audience")
        revision = positive(article["content_revision"])
        refs = []
        for ref in article["references"]:
            source = sources.get(ref["source_id"])
            if not source or source.get("is_active") is not True:
                raise ValueError("Published article refers to missing/inactive source")
            start, end = ref.get("page_start"), ref.get("page_end")
            if source["media_type"] == "PDF":
                if not 1 <= positive(start) <= positive(end) <= positive(source["page_count"]):
                    raise ValueError("Invalid PDF page range")
            elif source["media_type"] == "WEB":
                if start is not None or end is not None:
                    raise ValueError("Web citation must not invent PDF pages")
                if not source.get("original_url", "").startswith("https://"):
                    raise ValueError("Web source needs its canonical HTTPS URL")
            else:
                raise ValueError("Unsupported source type")
            refs.append({"source_id": source["id"], "source_revision": positive(source["revision"]),
                         "source_title": nonempty(source["title"]), "page_start": start, "page_end": end})
        if not refs:
            raise ValueError("Published article has no references")
        documents.append({"article_id": identifier, "article_revision": revision,
                          "evidence_id": f"article:{identifier}:r{revision}",
                          "category_code": category["code"], "category_name": category["name"],
                          "title": article["title"], "age_group": article["age_group"],
                          "checked_at": article["checked_at"], "paragraphs": paragraphs(article),
                          "references": refs})
    manifest = {"format_version": FORMAT_VERSION, "input_sha256": digest(data),
                "documents": documents}
    return {**manifest, "corpus_version": digest(manifest)}


def write_artifact(artifact, destination):
    target = Path(destination)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent,
                                         delete=False) as stream:
            temporary = stream.name
            json.dump(artifact, stream, ensure_ascii=False, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)


def load_artifact(path):
    artifact = read_json(path)
    manifest = {key: artifact[key] for key in ("format_version", "input_sha256", "documents")}
    if artifact["format_version"] != FORMAT_VERSION or artifact["corpus_version"] != digest(manifest):
        raise ValueError("Corrupt or unsupported corpus artifact")
    return artifact
