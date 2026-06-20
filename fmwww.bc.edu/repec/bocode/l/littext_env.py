"""littext_env: verify that required Python packages are installed.
"""

from __future__ import annotations

import importlib
import importlib.metadata
import importlib.util
import sys
from typing import Tuple

# Map: package import name -> (display name, install hint, required for v0.1)
REQUIRED = [
    ("spacy",                "spaCy",                "pip install spacy",                True),
    ("sentence_transformers","sentence-transformers","pip install sentence-transformers", True),
    ("hdbscan",              "hdbscan",              "pip install hdbscan",              True),
    ("sklearn",              "scikit-learn",         "pip install scikit-learn",         True),
    ("umap",                 "umap-learn",           "pip install umap-learn",           True),
    ("matplotlib",           "matplotlib",           "pip install matplotlib",           True),
    ("networkx",             "networkx",             "pip install networkx",             True),
    ("plotly",               "plotly",               "pip install plotly",               True),
    ("pandas",               "pandas",               "pip install pandas",               True),
    ("numpy",                "numpy",                "pip install numpy",                True),
]


def _is_installed(modname: str) -> bool:
    """Cheap presence check. Does NOT import the module."""
    try:
        spec = importlib.util.find_spec(modname)
        return spec is not None
    except (ImportError, ValueError):
        return False


def _import_for_version(modname: str, dist: str = "") -> Tuple[bool, str]:
    """Full import to read the version string. Use ONLY in verbose mode.

    Most packages expose __version__. Some (notably hdbscan) do not, so when
    __version__ is absent fall back to the installed-distribution metadata,
    trying the import name and then the distribution display name (these
    differ for, e.g., sklearn / scikit-learn and umap / umap-learn)."""
    try:
        mod = importlib.import_module(modname)
    except Exception as exc:
        return False, str(exc).splitlines()[0][:120]
    ver = getattr(mod, "__version__", None)
    if not ver:
        for name in (modname, dist):
            if not name:
                continue
            try:
                ver = importlib.metadata.version(name)
                break
            except Exception:
                ver = None
    return True, ver if ver else "?"


def _spacy_model_present(model_name: str = "en_core_web_sm") -> bool:
    """Check whether a spaCy model is installed, WITHOUT loading it."""
    return _is_installed(model_name)


def report_environment(verbose: bool = False) -> None:
    """Print a report of the Python environment. Verbose=True imports every
    package to read its version (slow). Verbose=False uses cheap presence checks."""
    print(f"  Python:        {sys.version.split()[0]}", flush=True)
    print(f"  Executable:    {sys.executable}", flush=True)
    if verbose:
        print(f"  sys.path[0:3]: {sys.path[:3]}", flush=True)
    for modname, display, hint, _required in REQUIRED:
        if verbose:
            ok, info = _import_for_version(modname, display)
            mark = "OK " if ok else "-- "
            if ok:
                print(f"  [{mark}] {display:24s} {info}", flush=True)
            else:
                print(f"  [{mark}] {display:24s} (missing; {hint})", flush=True)
        else:
            ok = _is_installed(modname)
            mark = "OK " if ok else "-- "
            print(f"  [{mark}] {display:24s} {'installed' if ok else '(missing; ' + hint + ')'}", flush=True)
    if _spacy_model_present():
        print(f"  [OK ] en_core_web_sm model is installed", flush=True)
    else:
        print(f"  [-- ] en_core_web_sm model missing; run  python -m spacy download en_core_web_sm", flush=True)


def check_environment() -> bool:
    """Return True iff all required packages are present (cheap, non-importing)."""
    for modname, _display, _hint, required in REQUIRED:
        if required and not _is_installed(modname):
            return False
    if not _spacy_model_present():
        return False
    return True
