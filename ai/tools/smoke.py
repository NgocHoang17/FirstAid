"""Start the real local ASGI server, check HTTP responses, and stop it.

Uses only a temporary token and local corpus. Does not call Spring or a provider.
"""
import json
import os
import secrets
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from uuid import uuid4

import httpx

AI_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(AI_ROOT))
from firstaid_rag.corpus import compile_corpus, read_json, write_artifact


def main():
    library = AI_ROOT.parent / "mobile/assets/content/reference_library.json"
    with tempfile.TemporaryDirectory(prefix="firstaid-http-") as directory:
        path = Path(directory) / "corpus.json"
        write_artifact(compile_corpus(read_json(library)), path)
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            port = sock.getsockname()[1]
        secret = secrets.token_urlsafe(32)
        process = subprocess.Popen(
            [sys.executable, "-m", "uvicorn", "firstaid_rag.app:create_app", "--factory",
             "--host", "127.0.0.1", "--port", str(port), "--no-access-log", "--log-level", "error"],
            cwd=AI_ROOT, env={**os.environ, "AI_INTERNAL_TOKEN": secret, "AI_INDEX_PATH": str(path)},
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        try:
            with httpx.Client(base_url=f"http://127.0.0.1:{port}", timeout=9,
                              headers={"X-Internal-Token": secret}, trust_env=False) as client:
                for attempt in range(40):
                    if process.poll() is not None:
                        raise RuntimeError("Local AI process exited before readiness")
                    try:
                        health = client.get("/health")
                        health.raise_for_status()
                        break
                    except httpx.ConnectError:
                        time.sleep(.1)
                else:
                    raise RuntimeError("Local AI did not become ready")
                statuses = []
                for message, age, expected in [
                    ("Kiến thức sơ cứu bỏng nhiệt nhẹ", None, "answered"),
                    ("Kiến thức CPR trẻ em", "CHILD", "answered"),
                    ("Cách làm CPR", None, "clarification_needed"),
                    ("Mẹ tôi không thở", None, "emergency_redirect"),
                    ("Liều thuốc chữa bỏng", None, "out_of_scope"),
                    ("Thời tiết hôm nay", None, "insufficient_evidence"),
                ]:
                    request_id = str(uuid4())
                    result = client.post("/internal/v1/query", json={"request_id": request_id,
                                         "message": message, "age_group": age, "context_mode": "learning"})
                    result.raise_for_status()
                    response = result.json()
                    assert response["request_id"] == request_id
                    assert response["status"] == expected
                    statuses.append(expected)
                print(json.dumps({"health": health.json()["status"], "http_checks": len(statuses),
                                  "statuses": statuses, "scope": "real FastAPI HTTP; no Spring/database"}))
        finally:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)


if __name__ == "__main__":
    main()
