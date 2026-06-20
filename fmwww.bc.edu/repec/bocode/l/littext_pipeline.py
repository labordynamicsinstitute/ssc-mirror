"""littext_pipeline: top-level orchestrator called from _littext_analyze.ado.

This module wires together extraction, embedding, clustering, relation
candidacy, and writing back into Stata frames via the sfi interface.
"""

from __future__ import annotations

import os
import re
from typing import Optional

import pandas as pd

from littext_extract import extract_constructs
from littext_embed import embed_constructs
from littext_cluster import cluster_constructs
from littext_hierarchy import assign_hierarchy
from littext_relate import score_relations
from littext_io import write_constructs_frame, write_relations_frame, write_diag_frame
from littext_state import save_state


# Emerald-style structured-abstract section headers. These prefix substantive
# sentences but should be removed before parsing so the parser does not treat
# "Findings" as a noun chunk or as the subject of the following clause.

def _clean_text(s: str) -> str:
    """Deprecated since v0.3.0. Use littext_cleaners.clean_for_texttype
    instead. Preserved for backward compatibility with any external
    code that imports this function; delegates to the 'abstract'
    cleaner, which reproduces the v0.2.9 behaviour exactly."""
    from littext_cleaners import _clean_abstract
    return _clean_abstract(s)


def _load_corpus(corpus_path: str,
                 min_text_len: int = 0,
                 keep_empty: bool = False,
                 texttype: str = "abstract") -> pd.DataFrame:
    """Load the temp .dta written by _littext_analyze.ado and apply
    pre-extraction text cleanup (publisher boilerplate, copyright tails,
    and any further patterns appropriate to the declared texttype).
    
    Parameters
    ----------
    corpus_path : str
        Path to the temporary .dta marshalled by _littext_analyze.
    min_text_len : int, default 0
        Defensive secondary minimum. When > 0, rows whose cleaned text is
        shorter than this character count are dropped post-cleanup. The
        Stata-side filter has already applied the user-facing threshold
        from mintextlen(); this value is a safety net catching any
        substrings the cleaner stripped below the threshold.
    keep_empty : bool, default False
        If True, skip the post-cleanup drop entirely.
    texttype : str, default "abstract"
        Selects the cleaning regime. One of the names in
        littext_cleaners.TEXTTYPE_NAMES. Unknown values fall through
        to the 'other' cleaner (minimal cleaning).

    Returns
    -------
    pd.DataFrame with columns lt_id (str), lt_text (str, cleaned),
    lt_journal (str), lt_year (Int64).
    """
    from littext_cleaners import clean_for_texttype, get_texttype_length_window

    df = pd.read_stata(corpus_path, convert_categoricals=False, convert_missing=False)
    n_in = len(df)
    if "lt_id" not in df.columns:
        df["lt_id"] = [f"D{i+1:06d}" for i in range(n_in)]
    df["lt_id"] = df["lt_id"].astype(str)
    if "lt_text" not in df.columns:
        df["lt_text"] = [""] * n_in
    df["lt_text"] = df["lt_text"].fillna("").astype(str).map(
        lambda s: clean_for_texttype(s, texttype)
    )
    if "lt_journal" not in df.columns:
        df["lt_journal"] = [""] * n_in
    df["lt_journal"] = df["lt_journal"].fillna("").astype(str)
    if "lt_year" in df.columns:
        df["lt_year"] = pd.to_numeric(df["lt_year"], errors="coerce")
    else:
        df["lt_year"] = pd.Series([pd.NA] * n_in, dtype="Int64")

    if not keep_empty:
        mask = df["lt_text"].str.strip().str.len() > 0
        if min_text_len > 0:
            mask &= df["lt_text"].str.len() >= int(min_text_len)
        n_dropped = int((~mask).sum())
        if n_dropped > 0:
            print(f"  littext: _load_corpus dropped {n_dropped} additional row(s) "
                  f"after text-cleaning (rows became empty or shorter than "
                  f"min_text_len={min_text_len}).", flush=True)
            df = df[mask].reset_index(drop=True)
        if len(df) == 0:
            raise RuntimeError(
                "littext: no rows remain after text-cleaning. The corpus "
                "may consist entirely of publisher boilerplate, or "
                "mintextlen() may be set too high for this text kind."
            )

    # Compute the median character length of the kept rows and warn if it falls outside the
    # expected window for the declared texttype.
    warn_below, warn_above = get_texttype_length_window(texttype)
    if warn_below is not None or warn_above is not None:
        median_len = int(df["lt_text"].str.len().median())
        msg = None
        if warn_below is not None and median_len < warn_below:
            msg = (f"littext: WARNING -- median text length {median_len} chars "
                   f"is below the typical window for texttype({texttype}) "
                   f"({warn_below}-{warn_above}). The text() variable may be "
                   f"mis-declared (e.g., titles supplied in place of abstracts).")
        elif warn_above is not None and median_len > warn_above:
            msg = (f"littext: WARNING -- median text length {median_len} chars "
                   f"is above the typical window for texttype({texttype}) "
                   f"({warn_below}-{warn_above}). Consider texttype(fulltext) "
                   f"if the corpus contains full-text documents.")
        if msg is not None:
            print(f"  {msg}", flush=True)

    return df


def run_pipeline(
    corpus_path: str,
    unit: str = "sentence",
    embed_model: str = "all-MiniLM-L6-v2",
    min_freq: int = 2,
    max_relations: int = 100_000,
    add_sentiment: bool = False,
    quiet: bool = False,
    min_text_len: int = 0,
    keep_empty: bool = False,
    texttype: str = "abstract",
) -> None:
    """End-to-end pipeline.

    See module docstring for parameter semantics. The Stata-side
    _littext_analyze.ado performs the principal row-drop pass before
    marshalling.
    """
    import sys as _sys
    import time as _time

    def log(msg: str) -> None:
        # Always flush so messages appear in Stata's window as they happen
        print(f"  littext: {msg}", flush=True)
        try:
            _sys.stdout.flush()
        except Exception:
            pass

    t0 = _time.time()
    log("(a) loading corpus from temp .dta...")
    corpus = _load_corpus(corpus_path, min_text_len=min_text_len,
                          keep_empty=keep_empty, texttype=texttype)
    log(f"    -> {len(corpus)} documents loaded (texttype={texttype}) "
        f"({_time.time()-t0:.1f}s)")

    t1 = _time.time()
    log("(b) loading spaCy en_core_web_sm (first call may take ~5-15s)...")
    # Trigger spaCy import explicitly so the user sees the pause
    import spacy as _spacy
    _ = _spacy.load("en_core_web_sm", disable=["ner"])
    log(f"    -> spaCy loaded ({_time.time()-t1:.1f}s)")

    t2 = _time.time()
    log("(c) segmenting and extracting candidate constructs...")
    constructs_df, units_df = extract_constructs(corpus, unit=unit, min_freq=min_freq)
    log(f"    -> {len(constructs_df)} candidate constructs in {len(units_df)} units  ({_time.time()-t2:.1f}s)")

    t3 = _time.time()
    log(f"(d) loading sentence-transformer model '{embed_model}' (first call downloads ~90MB if not cached)...")
    construct_embeddings = embed_constructs(constructs_df["surface_form"].tolist(), model_name=embed_model)
    log(f"    -> embeddings shape {construct_embeddings.shape}  ({_time.time()-t3:.1f}s)")

    t4 = _time.time()
    log("(e) clustering constructs with HDBSCAN...")
    constructs_df = cluster_constructs(constructs_df, construct_embeddings)
    n_canon = constructs_df["canonical_form"].nunique()
    log(f"    -> {n_canon} canonical clusters  ({_time.time()-t4:.1f}s)")

    t4b = _time.time()
    log("(e2) detecting lexical construct hierarchy...")
    constructs_df = assign_hierarchy(constructs_df)
    n_roots = int(constructs_df["is_root"].sum())
    n_subtypes = int((constructs_df["parent_canonical"] != "").sum())
    log(f"    -> {n_roots} root constructs, {n_subtypes} subtype assignments  "
        f"({_time.time()-t4b:.1f}s)")

    t5 = _time.time()
    log("(f) scoring candidate relationships...")
    relations_df = score_relations(
        units_df=units_df,
        constructs_df=constructs_df,
        max_relations=max_relations,
        add_sentiment=add_sentiment,
    )
    log(f"    -> {len(relations_df)} candidate relationships  ({_time.time()-t5:.1f}s)")

    t6 = _time.time()
    log("(g) building diagnostics and writing Stata frames...")
    diag_df = _build_diagnostics(corpus, units_df, constructs_df, relations_df)
    write_constructs_frame(constructs_df)
    write_relations_frame(relations_df)
    write_diag_frame(diag_df)
    log(f"    -> frames populated  ({_time.time()-t6:.1f}s)")

    save_state(
        constructs_df=constructs_df,
        construct_embeddings=construct_embeddings,
        relations_df=relations_df,
        diag_df=diag_df,
    )
    log(f"done. total {_time.time()-t0:.1f}s")


def _build_diagnostics(corpus, units_df, constructs_df, relations_df):
    """Per-document diagnostic counts."""
    # Constructs per doc
    cpd = units_df.merge(
        constructs_df[["construct_id"]].drop_duplicates(),
        on="construct_id",
        how="inner",
    )
    n_con = cpd.groupby("doc_id")["construct_id"].nunique().rename("n_constructs_extracted")
    n_rel = relations_df.groupby("doc_id").size().rename("n_relations_extracted")
    out = corpus[["lt_id", "lt_year", "lt_journal"]].rename(columns={"lt_id": "doc_id", "lt_year": "year", "lt_journal": "journal"})
    out = out.merge(n_con, left_on="doc_id", right_index=True, how="left")
    out = out.merge(n_rel, left_on="doc_id", right_index=True, how="left")
    out[["n_constructs_extracted", "n_relations_extracted"]] = (
        out[["n_constructs_extracted", "n_relations_extracted"]].fillna(0).astype(int)
    )
    return out
