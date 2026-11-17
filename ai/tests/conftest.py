import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from firstaid_rag.corpus import compile_corpus, read_json
from firstaid_rag.engine import Engine

LIBRARY = Path(__file__).resolve().parents[2] / "mobile/assets/content/reference_library.json"


@pytest.fixture
def library():
    return read_json(LIBRARY)


@pytest.fixture
def artifact(library):
    return compile_corpus(library)


@pytest.fixture
def engine(artifact):
    return Engine(artifact)
