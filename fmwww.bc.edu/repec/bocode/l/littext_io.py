"""littext_io: write pandas DataFrames into Stata frames via the sfi module.
"""

from __future__ import annotations

from typing import List

import pandas as pd

try:
    from sfi import Frame, SFIToolkit
except Exception:
    Frame = None
    SFIToolkit = None


# Maximum length for string variables (Stata str# capped at 2045; strL > that).
# We cap evidence_text at 500 and other strings at 244 to stay safely in str244.
_STR_CAP = 244
_EVIDENCE_CAP = 500


def _coerce_str(value, cap: int = _STR_CAP) -> str:
    if value is None:
        return ""
    s = str(value)
    if len(s) > cap:
        return s[:cap]
    return s


def _add_var(frame, name: str, kind: str, n: int) -> None:
    """Add a variable to a frame with appropriate storage type."""
    if kind == "long":
        frame.addVarLong(name)
    elif kind == "double":
        frame.addVarDouble(name)
    elif kind == "int":
        frame.addVarInt(name)
    elif kind == "byte":
        frame.addVarByte(name)
    elif kind == "str":
        frame.addVarStr(name, _STR_CAP)
    elif kind == "str_evidence":
        frame.addVarStr(name, _EVIDENCE_CAP)
    elif kind == "str_short":
        frame.addVarStr(name, 80)
    else:
        raise ValueError(f"unknown kind: {kind}")


def write_constructs_frame(df: pd.DataFrame) -> None:
    """Populate the lt_constructs frame."""
    if Frame is None:
        raise RuntimeError("sfi is unavailable; this function must be called from Stata.")
    f = Frame.connect("lt_constructs")
    f.setObsTotal(0)
    n = len(df)
    _add_var(f, "construct_id",    "long",      n)
    _add_var(f, "surface_form",    "str_short", n)
    _add_var(f, "canonical_form",  "str_short", n)
    _add_var(f, "cluster_id",      "long",      n)
    _add_var(f, "freq_doc",        "long",      n)
    _add_var(f, "freq_total",      "long",      n)
    # v0.3 hierarchy columns. Defaults written when the columns are
    # absent from the DataFrame (e.g., when assign_hierarchy was not
    # called in older test invocations).
    _add_var(f, "parent_canonical","str_short", n)
    _add_var(f, "canonical_root",  "str_short", n)
    _add_var(f, "hierarchy_depth", "long",      n)
    _add_var(f, "is_root",         "byte",      n)
    if n == 0:
        return
    f.setObsTotal(n)
    for i, row in df.reset_index(drop=True).iterrows():
        f.store("construct_id",   i, int(row["construct_id"]))
        f.store("surface_form",   i, _coerce_str(row["surface_form"], 80))
        f.store("canonical_form", i, _coerce_str(row.get("canonical_form", row["surface_form"]), 80))
        f.store("cluster_id",     i, int(row.get("cluster_id", -1)))
        f.store("freq_doc",       i, int(row["freq_doc"]))
        f.store("freq_total",     i, int(row["freq_total"]))
        f.store("parent_canonical", i, _coerce_str(row.get("parent_canonical", ""), 80))
        # canonical_root defaults to the construct's own canonical_form
        # when no hierarchy is set (i.e., the construct is itself the root).
        canon_root_default = row.get("canonical_form", row["surface_form"])
        f.store("canonical_root",   i, _coerce_str(row.get("canonical_root", canon_root_default), 80))
        f.store("hierarchy_depth",  i, int(row.get("hierarchy_depth", 0)))
        f.store("is_root",          i, int(row.get("is_root", 1)))


def write_relations_frame(df: pd.DataFrame) -> None:
    if Frame is None:
        raise RuntimeError("sfi is unavailable; this function must be called from Stata.")
    f = Frame.connect("lt_relations")
    f.setObsTotal(0)
    n = len(df)
    _add_var(f, "rel_id",              "long",         n)
    _add_var(f, "doc_id",              "str_short",    n)
    _add_var(f, "unit_id",             "str_short",    n)
    _add_var(f, "source",              "str_short",    n)
    _add_var(f, "target",              "str_short",    n)
    _add_var(f, "source_construct_id", "long",         n)
    _add_var(f, "target_construct_id", "long",         n)
    _add_var(f, "relation_type",       "str_short",    n)
    _add_var(f, "confidence",          "double",       n)
    _add_var(f, "extraction_method",   "str_short",    n)
    _add_var(f, "evidence_text",       "str_evidence", n)
    _add_var(f, "text_polarity",       "double",       n)
    if n == 0:
        return
    f.setObsTotal(n)
    for i, row in df.reset_index(drop=True).iterrows():
        f.store("rel_id",              i, int(row["rel_id"]))
        f.store("doc_id",              i, _coerce_str(row["doc_id"], 80))
        f.store("unit_id",             i, _coerce_str(row["unit_id"], 80))
        f.store("source",              i, _coerce_str(row["source"], 80))
        f.store("target",              i, _coerce_str(row["target"], 80))
        f.store("source_construct_id", i, int(row["source_construct_id"]))
        f.store("target_construct_id", i, int(row["target_construct_id"]))
        f.store("relation_type",       i, _coerce_str(row["relation_type"], 80))
        f.store("confidence",          i, float(row["confidence"]))
        f.store("extraction_method",   i, _coerce_str(row["extraction_method"], 80))
        f.store("evidence_text",       i, _coerce_str(row["evidence_text"], _EVIDENCE_CAP))
        tp = row.get("text_polarity")
        if tp is None or (isinstance(tp, float) and (tp != tp)):
            # Leave as Stata system missing. Newly added double vars default
            # to missing; skip the store call rather than passing None,
            # which sfi.Frame.store rejects with TypeError.
            pass
        else:
            f.store("text_polarity", i, float(tp))


def write_diag_frame(df: pd.DataFrame) -> None:
    if Frame is None:
        raise RuntimeError("sfi is unavailable; this function must be called from Stata.")
    f = Frame.connect("lt_diag")
    f.setObsTotal(0)
    n = len(df)
    _add_var(f, "doc_id",                  "str_short", n)
    _add_var(f, "year",                    "int",       n)
    _add_var(f, "journal",                 "str_short", n)
    _add_var(f, "n_constructs_extracted",  "long",      n)
    _add_var(f, "n_relations_extracted",   "long",      n)
    if n == 0:
        return
    f.setObsTotal(n)
    for i, row in df.reset_index(drop=True).iterrows():
        f.store("doc_id",  i, _coerce_str(row["doc_id"], 80))
        yr = row.get("year")
        if yr is None or (isinstance(yr, float) and (yr != yr)):
            # Leave as Stata system missing; do not pass None to f.store.
            pass
        else:
            f.store("year", i, int(yr))
        f.store("journal", i, _coerce_str(row.get("journal", ""), 80))
        f.store("n_constructs_extracted", i, int(row["n_constructs_extracted"]))
        f.store("n_relations_extracted",  i, int(row["n_relations_extracted"]))
