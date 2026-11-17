"""Check curated facility inputs and optionally export Admin create payloads.

No network or database writes. Human source verification remains necessary.
"""
import argparse
import json
import math
import re
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import unquote, urlparse

ROOT = Path(__file__).resolve().parents[1]
FIELDS = {"name", "region_code", "address", "phone", "latitude", "longitude",
          "emergency_24h", "verification_note", "verified_at", "is_active"}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def validate(data):
    require(data["schema_version"] == 1, "Unsupported facility dataset")
    keys = set()
    covered_ordinals = set()
    for record in data["records"]:
        key, facility, evidence = record["key"], record["facility"], record["evidence"]
        require(key not in keys, f"Duplicate key: {key}")
        keys.add(key)
        if "directory_ordinal" in evidence:
            covered_ordinals.add(evidence["directory_ordinal"])
        require(set(facility) == FIELDS, f"Unexpected payload fields: {key}")
        require(facility["region_code"] == data["region_code"], f"Region mismatch: {key}")
        for field in ("name", "address", "verification_note"):
            require(isinstance(facility[field], str) and facility[field].strip(), f"Missing {field}: {key}")
        require(type(facility["is_active"]) is bool, f"Invalid active flag: {key}")
        require(facility["emergency_24h"] in {"YES", "NO", "UNKNOWN"}, f"Invalid 24h flag: {key}")
        require(evidence["contact_urls"], f"Missing source: {key}")
        for url in evidence["contact_urls"]:
            require(urlparse(url).scheme == "https" and urlparse(url).hostname, f"Invalid source URL: {key}")
        if facility["is_active"]:
            require(not evidence["pending"], f"Unresolved verification: {key}")
            require(re.fullmatch(r"(?:\+?[0-9]{9,15}|1900[0-9]{4,6})", facility["phone"] or ""), f"Invalid verified phone: {key}")
            for field, limit in (("latitude", 90), ("longitude", 180)):
                value = facility[field]
                require(type(value) in (int, float) and math.isfinite(value) and abs(value) <= limit,
                        f"Invalid {field}: {key}")
            require(evidence["map_url"] and evidence["coordinate_basis"], f"Missing location evidence: {key}")
            require(urlparse(evidence["map_url"]).scheme == "https", f"Invalid map URL: {key}")
            map_url = unquote(evidence["map_url"])
            # Check stored coordinates against the actual linked point. Viewport
            # coordinates after @ are deliberately excluded.
            points = re.findall(r"!3d(-?[\d.]+)!4d(-?[\d.]+)", map_url)
            if not points:
                points = [(lat, lon) for lon, lat in re.findall(r"!2d(-?[\d.]+)!3d(-?[\d.]+)", map_url)]
            require(any(abs(float(lat) - facility["latitude"]) < 1e-7
                        and abs(float(lon) - facility["longitude"]) < 1e-7
                        for lat, lon in points), f"Coordinates do not match linked point: {key}")
            verified = datetime.fromisoformat((facility["verified_at"] or "").replace("Z", "+00:00"))
            require(verified.tzinfo is not None and verified <= datetime.now(timezone.utc), f"Invalid check date: {key}")
        if facility["emergency_24h"] != "UNKNOWN":
            require(evidence["emergency_24h_basis"], f"24h claim needs evidence: {key}")
    require(0 < len(keys) <= 100, "Dataset outside public directory limits")
    if "coverage" in data:
        coverage = data["coverage"]
        excluded = {item["directory_ordinal"] for item in coverage["excluded_entries"]}
        require(not covered_ordinals & excluded, "A directory entry cannot be both represented and excluded")
        require(len(covered_ordinals) == coverage["represented_entries"], "Incorrect represented entry count")
        require(covered_ordinals | excluded == set(range(1, coverage["source_entries"] + 1)),
                "Coverage is missing source entries")
    return [record["facility"] for record in data["records"]]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=ROOT / "data/facilities/danang.json")
    parser.add_argument("--export-admin", type=Path, help="Write a local array of create payloads, not an API request")
    args = parser.parse_args()
    data = json.loads(args.input.read_text(encoding="utf-8"))
    payloads = validate(data)
    if args.export_admin:
        args.export_admin.parent.mkdir(parents=True, exist_ok=True)
        args.export_admin.write_text(json.dumps(payloads, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"region_code": data["region_code"], "records": len(payloads),
                      "active": sum(f["is_active"] for f in payloads),
                      "pending": sum(not f["is_active"] for f in payloads)}))


if __name__ == "__main__":
    main()
