import os, importlib.util, pathlib
from importlib.machinery import SourceFileLoader
os.environ.setdefault("REPO_DIR", "/tmp")
_p = pathlib.Path(__file__).resolve().parent.parent / "aur-build-all"
# aur-build-all has no .py extension, so pass an explicit source loader.
_spec = importlib.util.spec_from_file_location(
    "aurbuildall", _p, loader=SourceFileLoader("aurbuildall", str(_p)))
m = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(m)

def test_track_latest_never_skips():
    assert m.should_skip_build({"name": "x", "track": "latest"}, "abc", "abc", False) is False

def test_skips_when_commit_matches_and_not_tracking():
    assert m.should_skip_build({"name": "x"}, "abc", "abc", False) is True

def test_rebuilds_on_new_commit():
    assert m.should_skip_build({"name": "x"}, "old", "new", False) is False

def test_py_stale_forces_rebuild():
    assert m.should_skip_build({"name": "x"}, "abc", "abc", True) is False
