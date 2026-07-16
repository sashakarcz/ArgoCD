import os, importlib.util, pathlib
from importlib.machinery import SourceFileLoader
os.environ.setdefault("REPO_DIR", "/tmp")
_p = pathlib.Path(__file__).resolve().parent.parent / "aur-build-all"
_spec = importlib.util.spec_from_loader("aurbuildall", SourceFileLoader("aurbuildall", str(_p)))
m = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(m)
