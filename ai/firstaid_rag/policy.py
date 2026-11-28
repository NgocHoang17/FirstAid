import re

from .retrieval import contains, query_text


def any_phrase(text, phrases):
    return any(contains(text, phrase) for phrase in phrases)


def decide(message):
    text = query_text(message)
    # Preserve negation: 'không thở' is a danger signal, not absence of an incident.
    learning = any_phrase(text, ["study", "on tap", "gia dinh tinh huong",
                                 "tinh huong gia dinh", "kien thuc", "trong tai lieu",
                                 "ly thuyet", "neu gap", "gia su", "hoc cach", "cach tiep can"])
    personal = bool(re.search(r"\b(toi|minh|ba|me|bo|ban|chau|be|con|em|anh|chi|ong) "
                              r"(?:(?:toi|minh|ay|nha|ben canh) )?(?:dang |vua )?"
                              r"(?:bi|khong tho|bat tinh|co giat|chay mau|ngung tim|hoc)\b", text))
    personal |= bool(re.search(r"\bnguoi (?:nha|ben canh|nay|kia) (?:dang |vua )?"
                               r"(?:bi|khong tho|bat tinh|co giat|chay mau|ngung tim|hoc)\b", text))
    current = any_phrase(text, ["ngay bay gio", "cuu voi", "cap cuu", "dang bi", "vua bi",
                               "khong tho duoc", "khong tho", "tho ngap", "tim tai",
                               "chay mau khong cam", "chay mau rat nhieu", "bat tinh"])
    # A learning disclaimer must never cancel an incident in another clause.
    incident = personal or current
    if incident and (not learning or personal or any_phrase(text, ["dang bi", "vua bi", "cuu voi"])):
        return "emergency_redirect"
    months = re.findall(r"\b(\d+)\s*(?:thang|months?)\b", text)
    if (any_phrase(text, ["nhu nhi", "so sinh", "duoi 1 tuoi", "duoi mot tuoi", "0 tuoi", "chua day 1 tuoi", "infant"])
            or any(int(age) < 12 for age in months)):
        return "out_of_scope"
    if any_phrase(text, ["bo qua", "ignore", "system prompt", "developer", "jailbreak",
                         "dap an", "lua chon a", "dung sai", "gia mao", "bia nguon",
                         "lieu thuoc", "ke don", "uong thuoc", "chan doan", "mg", "ml",
                         "khang sinh", "paracetamol", "adrenaline", "insulin",
                         "ung thu", "tieu duong", "chuyen tien", "lap trinh"]):
        return "out_of_scope"
    return None
