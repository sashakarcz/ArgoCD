from _loader import m

def test_escalated_fails_closed_without_key(tmp_path):
    (tmp_path / "PKGBUILD").write_text("pkgname=x\npkgver=1\n")
    m.ANTHROPIC_API_KEY = ""           # simulate no key
    v = m.escalated_scan(tmp_path, "x", "some diff")
    assert v["safe"] is False and v["risk"] == "critical"

def test_escalation_defaults():
    assert m.ESCALATION_PASSES >= 1
    assert "claude" in m.ESCALATION_MODEL
