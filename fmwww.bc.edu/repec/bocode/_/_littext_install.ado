/*!
_littext_install: verify that the Python environment has the required packages.

The verbose path additionally imports each package to read its version; this is slow on the first call (sentence-
transformers + torch can take 30-90s cold on Windows), and is therefore done
only when the user explicitly requests it via the verbose option.

It also reports whether the default sentence-transformer embedding model is
cached and, if not, tells the user how to pre-fetch it at the command prompt
(with visible progress), so that the first -littext analyze- does not appear
to hang during a silent model download inside Stata's Python bridge.
*/

program define _littext_install
    version 19.0
    syntax [, Quiet Verbose]
    local q = ("`quiet'" != "")
    local v = ("`verbose'" != "")
    if !`q' di as txt "littext: checking Python environment..."
    capture python query
    if _rc {
        di as err "littext: Python is not configured in Stata."
        di as txt `"Run -python set exec "C:\path\to\python.exe"- (use your actual path)."'
        exit 198
    }
    _littext_resolve, subdir(python) name(littext_run.py)
    local pypath `"`r(dir)'"'
    python: import sys, os
    python: _pypath_abs = os.path.abspath(r"`pypath'")
    python: sys.path.insert(0, _pypath_abs) if _pypath_abs not in sys.path else None
    capture python: from littext_env import check_environment, report_environment
    if _rc {
        di as err `"littext: cannot import littext_env from `pypath'"'
        di as txt "The littext Python modules could not be imported; reinstall the package."
        exit 198
    }
    /* Only run the (slow, importing) verbose report when the user asks for it. */
    if `v' python: report_environment(verbose=True)
    /* Always run the cheap (non-importing) check; it returns a bool to Stata via Macro. */
    python: from sfi import Macro
    python: Macro.setLocal("pyok", "1" if check_environment() else "0")
    if "`pyok'" != "1" {
        di as err "littext: one or more required Python packages are missing."
        di as txt "Install them in the Python environment that Stata is bound to:"
        di as txt "  pip install spacy sentence-transformers hdbscan scikit-learn umap-learn matplotlib networkx pandas"
        di as txt "  python -m spacy download en_core_web_sm"
        di as txt "(Run -littext install, verbose- to see exactly which package is missing.)"
        exit 198
    }
    /* Default embedding-model cache check.
       The first -littext analyze- on a fresh machine downloads the default
       sentence-transformer model (~90 MB) from the Hugging Face Hub. Inside
       Stata's Python bridge downloads and prints no progress, so an uncached
       first run appears to hang at stage 5 for 1-2 minutes. Detect the cache
       here, without importing torch and without triggering a download, and
       if the model is absent, direct the user to fetch it at the Windows
       command prompt where progress is visible. A missing cache is a
       heads-up, not an error; the package still runs. Users who pass a
       non-default embedmodel() should cache that model instead. */
    local lt_stmodel "sentence-transformers/all-MiniLM-L6-v2"
    local lt_modelcache "unknown"
    capture python: from huggingface_hub import try_to_load_from_cache
    if _rc == 0 {
        capture {
            python: from sfi import Macro
            python: import os
            python: _lt_repo = "`lt_stmodel'"
            python: _lt_names = ["modules.json", "config.json", "model.safetensors", "pytorch_model.bin"]
            python: _lt_paths = [try_to_load_from_cache(repo_id=_lt_repo, filename=_n) for _n in _lt_names]
            python: _lt_hit = any(isinstance(_p, str) and os.path.exists(_p) for _p in _lt_paths)
            python: Macro.setLocal("lt_modelcache", "yes" if _lt_hit else "no")
        }
    }
    if "`lt_modelcache'" == "yes" {
        if !`q' di as txt "littext: default embedding model is cached (`lt_stmodel')."
    }
    else if "`lt_modelcache'" == "no" {
        di as txt ""
        di as txt "littext: NOTE -- the default embedding model is not yet cached."
        di as txt "        The first -littext analyze- downloads it (~90 MB) from the"
        di as txt "        Hugging Face Hub. Inside Stata that download shows no progress,"
        di as txt "        so the first run appears to hang at stage 5 for 1-2 minutes."
        di as txt "        To fetch it now with visible progress, run this once at the"
        di as txt "        Windows command prompt (not inside Stata):"
        di as txt ""
        di as txt `"    python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('all-MiniLM-L6-v2')""'
        di as txt ""
        di as txt "        It caches under your Hugging Face hub folder; later runs load it"
        di as txt "        from disk with no network. Then re-run -littext install-."
        di as txt ""
    }
    else {
        if !`q' di as txt "littext: embedding-model cache status undetermined (continuing)."
    }
    if !`q' di as txt "littext: environment OK."
end
