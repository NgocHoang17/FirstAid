import math
import re
import unicodedata
from collections import Counter


def normalize(text):
    text = unicodedata.normalize("NFD", text.lower().replace("đ", "d"))
    return " ".join(re.findall(r"[a-z0-9]+", "".join(
        char for char in text if unicodedata.category(char) != "Mn")))


def contains(text, phrase):
    return f" {phrase} " in f" {text} "


def query_text(text):
    # Preserve semantic distinctions lost by accent folding (học / hóc).
    text = unicodedata.normalize("NFC", text).lower()
    text = normalize(text.replace("học", "study").replace("bóng", "ball").replace("phỏng", "bong"))
    return re.sub(r"\bhoc (?=cach|so cuu|kien thuc|ve )", "study ", text)


# Search aliases are routing vocabulary, never medical instructions or evidence.
TOPICS = {
    "FA01": ["bat tinh", "khong dap ung", "mat y thuc"],
    "FA02": ["cpr", "aed", "ngung tim", "hoi suc tim phoi", "ep tim"],
    "FA03": ["hoc di vat", "hoc", "nghen", "sac thuc an"],
    "FA04": ["duoi nuoc", "ngat nuoc"],
    "FA05": ["chay mau ngoai", "cam mau", "vet thuong chay mau"],
    "FA06": ["vet cat", "tray xuoc", "vet thuong nho"],
    "FA07": ["chay mau cam", "chay mau mui"],
    "FA08": ["gay xuong"],
    "FA09": ["bong gan", "trat khop", "sai khop"],
    "FA10": ["chan thuong dau", "chan thuong co", "cot song"],
    "FA11": ["bong", "bong nhiet"],
    "FA12": ["dien giat"],
    "FA13": ["say nong", "soc nhiet", "say nang"],
    "FA14": ["dot quy", "tai bien mach mau nao"],
    "FA15": ["co giat", "dong kinh"],
    "FA16": ["phan ve", "di ung nang"],
    "FA17": ["ngo doc", "trung doc"],
    "FA18": ["cho can", "ran can", "ong dot", "ong chich", "dong vat can", "con trung dot"],
}
VARIANTS = {"bong gan": "bong gan", "trat khop": "trat khop", "sai khop": "trat khop",
            "cho can": "cho can", "ran can": "ran can", "ong dot": "ong dot", "ong chich": "ong dot"}


def topics(query):
    normalized = query_text(query)
    # 'bỏng' and 'bong gân' share an accent-free token; remove the longer phrase first.
    if contains(normalized, "bong gan"):
        normalized = normalized.replace("bong gan", "sprain")
        result = {"FA09"}
    else:
        result = set()
    return result | {code for code, aliases in TOPICS.items()
                     if any(contains(normalized, alias) for alias in aliases)}


class BM25:
    def __init__(self, documents):
        self.documents = documents
        self.terms = [Counter(normalize(" ".join(
            [doc["title"]] * 3 + [doc["category_name"]] + doc["paragraphs"])).split())
            for doc in documents]
        self.lengths = [sum(terms.values()) for terms in self.terms]
        self.average = sum(self.lengths) / max(1, len(self.lengths))
        self.frequency = Counter(term for terms in self.terms for term in terms)

    def search(self, query, candidates, limit=5):
        tokens = set(normalize(query).split())
        scored = []
        for index in candidates:
            score = 0.0
            for token in tokens:
                frequency = self.terms[index][token]
                if not frequency:
                    continue
                idf = math.log(1 + (len(self.documents) - self.frequency[token] + .5)
                               / (self.frequency[token] + .5))
                denominator = frequency + 1.2 * (.25 + .75 * self.lengths[index] / self.average)
                score += idf * frequency * 2.2 / denominator
            if score > 0:
                scored.append((score, self.documents[index]))
        return sorted(scored, key=lambda item: (-item[0], item[1]["article_id"]))[:limit]
