from _loader import m

def test_escalated_fails_closed_without_key(tmp_path):
    (tmp_path / "PKGBUILD").write_text("pkgname=x\npkgver=1\n")
    m.ANTHROPIC_API_KEY = ""           # simulate no key
    v = m.escalated_scan(tmp_path, "x", "some diff")
    assert v["safe"] is False and v["risk"] == "critical"

def test_escalation_defaults():
    assert m.ESCALATION_PASSES >= 1
    assert "claude" in m.ESCALATION_MODEL


# --- risk-gating: hold only on high/critical, ignore the biased safe flag ---
def _fake_anthropic(verdict):
    class _Msgs:
        def create(self, **k):
            return type("M", (), {"content": [type("B", (), {"type": "tool_use", "input": verdict})()]})()
    class _Client:
        def __init__(self, **k): pass
        messages = _Msgs()
    return type("A", (), {"Anthropic": _Client})

def _prep(tmp_path, monkeypatch, verdict):
    (tmp_path / "PKGBUILD").write_text("pkgname=x\npkgver=1\nbuild(){ :; }\n")
    monkeypatch.setattr(m, "ANTHROPIC_API_KEY", "x")
    monkeypatch.setattr(m, "_HAS_ANTHROPIC", True)
    monkeypatch.setattr(m, "ESCALATION_PASSES", 1)
    monkeypatch.setattr(m, "_anthropic", _fake_anthropic(verdict))

def test_medium_risk_clears(tmp_path, monkeypatch):
    # safe=false but only medium -> should CLEAR (no false-positive hold)
    _prep(tmp_path, monkeypatch, {"safe": False, "risk": "medium", "summary": "nitpick"})
    assert m.escalated_scan(tmp_path, "x", None)["safe"] is True

def test_high_risk_holds(tmp_path, monkeypatch):
    # safe=true but high -> should HOLD (we gate on risk, not the biased flag)
    _prep(tmp_path, monkeypatch, {"safe": True, "risk": "high", "summary": "curl|bash added"})
    assert m.escalated_scan(tmp_path, "x", None)["safe"] is False
