"""littext_extract: candidate-construct extraction from text.
"""

from __future__ import annotations

from typing import List, Tuple

import pandas as pd


# Conservative stop-list of generic academic noun phrases that should not be
# treated as constructs. Lowercase comparison. 
_STOP_PHRASES = {
    # Self-references
    "this paper", "this study", "this article", "the present study",
    "the present paper", "the results", "the findings", "our results",
    "our findings", "the data", "the literature", "the analysis",
    "the model", "the framework", "the authors", "previous research",
    "prior work", "future research", "this research", "the study",
    # Effect / impact / relationship meta-vocabulary (original v0.1)
    "an effect", "the effect", "an impact", "the impact", "a relationship",
    "the relationship", "the effects", "the impacts", "the relationships",
    "the role", "a role", "the influence", "an influence", "the context",
    "the field", "the area", "the topic", "the case", "the example",
    "the purpose", "the aim", "the goal", "the objective", "the question",
    "n =", "p <", "p =", "alpha", "beta", "table", "figure",
    # generic academic discourse that surfaced in real abstracts
    "paper", "study", "studies", "research", "researcher", "researchers",
    "literature", "data", "results", "findings", "evidence", "analysis",
    "author", "authors", "author(s", "implications", "limitations",
    "generalizability", "contribution", "contributions", "manuscript",
    "model", "models", "theoretical model", "research model",
    "framework", "frameworks", "model 4", "model 1",
    "addition", "case", "purpose", "aim", "aims", "goal", "objective",
    "conclusion", "conclusions", "discussion", "introduction",
    "background", "context", "approach", "methodology", "method", "methods",
    #Emerald-style structured-abstract section header residues
    "originality", "originality/value", "design/methodology/approach",
    "design/methodology", "research limitations", "practical implications",
    "social implications", "managerial implications",
    #methodological vocabulary (these are methods, not constructs)
    "structural equation modeling", "structural equation modelling",
    "online survey", "online surveys", "experiment", "experiments",
    "three experimental studies", "two experimental studies",
    "four experimental studies", "experimental study", "experimental studies",
    "panel data", "process macro", "process model", "anova", "ancova",
    "pls", "pls-sem", "cfa", "efa", "fsqca", "regression",
    "questionnaire", "questionnaires", "survey", "surveys", "interview",
    "interviews", "focus group", "focus groups",
    "mturk", "amazon mechanical turk", "prolific", "qualtrics",
    "convenience sampling", "convenience sample", "random sample",
    "sample", "samples", "participants", "respondent", "respondents",
    "response", "responses", "sample size",
    # publisher / copyright fragments that survive sentence splitting
    "elsevier b.v.", "elsevier ltd.", "elsevier ltd", "elsevier",
    "emerald publishing limited", "emerald publishing", "emerald",
    "informa uk limited", "informa uk", "informa", "taylor",
    "francis group", "all rights", "all rights reserved",
    "wiley", "wiley-blackwell", "springer", "springer nature", "sage",
    # orphan tokens from "X of Y" chunker failures
    # ("word of mouth" splits to "word" and "mouth"; treat both as stops
    # so a downstream MWE gazetteer can re-introduce the full phrase)
    "mouth", "turn", "use",
    # methodological-discourse phrases that are NOT constructs but
    # are descriptions of methodological roles. 
    "mediating role", "moderating effect", "mediating effect",
    "moderating role", "antecedents", "consequences", "antecedent",
    "consequence", "present study",
    # residual hedging / methodological phrases that surfaced at
    # the top of the confidence ranking on real corpora. "concept" is
    # stop-listed because in this corpus it appears overwhelmingly in
    # "proof of concept" (methodological); "terms" because it appears
    # overwhelmingly in "in terms of" (discourse-marker hedging).
    "concept", "proof of concept", "terms", "manifold ways",
    # Statistical methods are deliberately RETAINED as constructs (per user
    # preference) because methods-of-research is itself an object of analysis
    # in the marketing literature. 
    # (a) Writing boilerplate / paper-structure vocabulary that appears in
    #     abstracts as discourse markers rather than theoretical content:
    "main purpose", "recent years", "previous studies", "existing literature",
    "study results", "theoretical framework", "proposed conceptual model",
    "proposed model", "important implications", "investigation", "attempt",
    "idea", "issue", "part", "order", "total", "work", "world", "depth",
    "directions", "avenues", "lens", "light", "place", "presence",
    "prevalence", "application", "attribution theory",
    "control", "contrast", "core", "decline", "mechanism", "others",
    "practice", "support", "understanding", "hypotheses", "addition",
    # (b) Geographies. Country and region names are excluded because they
    #     typically appear as study-context indicators rather than as objects
    #     of theoretical claims. 
    "china", "chinese consumers", "kuwait", "united arab emirates",
    "united states",
    # (c) Methodology role markers. "Frequency analysis"
    #     and "thematic analysis" and "data analysis" describe analytic
    #     procedures used in the paper (and therefore overlap with statistical-
    #     methods vocabulary), but in real abstracts they appear almost
    #     exclusively as descriptions of what the paper DID rather than as
    #     objects of comparison. 
    "frequency analysis", "thematic analysis", "data analysis",
    "non-participatory netnography", "online experiment",
    # (d) Punctuation/tokenisation artefacts. 
    "(cbbe", "cbbe", "(sem", "sem",
}

_KEEP_POS = {"NOUN", "PROPN", "ADJ"}

def _load_spacy():
    """Load spaCy with parser + tagger; disable NER for speed (we use chunks)."""
    import spacy
    return spacy.load("en_core_web_sm", disable=["ner"])


def _clean_chunk(text: str) -> str:
    """Normalise a noun-chunk surface form.

    strip leading/trailing bracket and punctuation characters
    that spaCy's noun-chunker sometimes retains as part of the chunk. The
    most common case in real corpora is parenthetical glosses where the
    opening "(" is absorbed into the following token (e.g. "(cbbe" as a
    chunk for "(consumer-based brand equity)"). Quotes and stray comma/
    semicolon characters are stripped for the same reason.
    """
    t = text.strip().lower()
    t = t.strip("()[]{}<>\"'`,;:")
    t = t.strip()
    # Strip leading determiners / quantifiers that spaCy keeps inside chunks
    for prefix in ("the ", "a ", "an ", "this ", "that ", "these ", "those ",
                   "our ", "their ", "his ", "her ", "its ", "such "):
        if t.startswith(prefix):
            t = t[len(prefix):]
            break
    # Collapse internal whitespace
    t = " ".join(t.split())
    return t


def _is_valid_construct(text: str, tokens) -> bool:
    if len(text) < 4 or len(text) > 80:
        return False
    if text in _STOP_PHRASES:
        return False
    if text.replace(" ", "").isdigit():
        return False
    if not any(tok.pos_ in _KEEP_POS for tok in tokens):
        return False
    # Reject chunks that are a single pronoun or determiner
    if len(tokens) == 1 and tokens[0].pos_ in {"PRON", "DET"}:
        return False
    return True


def _segment_units(nlp, corpus: pd.DataFrame, unit: str) -> pd.DataFrame:
    """Return a long DataFrame: one row per (doc_id, unit_id, unit_text)."""
    rows: List[dict] = []
    texts = corpus["lt_text"].tolist()
    ids = corpus["lt_id"].tolist()
    for doc_id, doc in zip(ids, nlp.pipe(texts, batch_size=64)):
        if unit == "abstract":
            rows.append({"doc_id": doc_id, "unit_id": f"{doc_id}::0", "unit_text": doc.text, "unit_index": 0})
        elif unit == "paragraph":
            # spaCy does not split paragraphs natively; use double-newline heuristic
            paragraphs = [p.strip() for p in doc.text.split("\n\n") if p.strip()]
            for i, p in enumerate(paragraphs):
                rows.append({"doc_id": doc_id, "unit_id": f"{doc_id}::{i}", "unit_text": p, "unit_index": i})
        else:  # sentence
            for i, sent in enumerate(doc.sents):
                rows.append({"doc_id": doc_id, "unit_id": f"{doc_id}::{i}", "unit_text": sent.text, "unit_index": i})
    return pd.DataFrame(rows)


def extract_constructs(
    corpus: pd.DataFrame,
    unit: str = "sentence",
    min_freq: int = 2,
) -> Tuple[pd.DataFrame, pd.DataFrame]:
    """Run noun-chunk extraction over the corpus and return (constructs_df, units_df).

    constructs_df columns:
        construct_id, surface_form, freq_doc, freq_total
    units_df columns:
        doc_id, unit_id, unit_index, unit_text, construct_id, surface_form
    """
    nlp = _load_spacy()
    units = _segment_units(nlp, corpus, unit=unit)

    # Re-parse the unit_text to get chunks within each unit
    chunk_rows: List[dict] = []
    for (doc_id, unit_id, unit_index), parsed in zip(
        zip(units["doc_id"], units["unit_id"], units["unit_index"]),
        nlp.pipe(units["unit_text"].tolist(), batch_size=128),
    ):
        seen_in_unit = set()
        for chunk in parsed.noun_chunks:
            cleaned = _clean_chunk(chunk.text)
            if not _is_valid_construct(cleaned, [t for t in chunk]):
                continue
            if cleaned in seen_in_unit:
                continue
            seen_in_unit.add(cleaned)
            chunk_rows.append({
                "doc_id": doc_id,
                "unit_id": unit_id,
                "unit_index": unit_index,
                "surface_form": cleaned,
            })

    if not chunk_rows:
        empty_c = pd.DataFrame(columns=["construct_id", "surface_form", "freq_doc", "freq_total"])
        empty_u = pd.DataFrame(columns=["doc_id", "unit_id", "unit_index", "construct_id", "surface_form", "unit_text"])
        return empty_c, empty_u

    chunks = pd.DataFrame(chunk_rows)

    # Frequencies
    freq_total = chunks.groupby("surface_form").size().rename("freq_total")
    freq_doc = chunks.groupby("surface_form")["doc_id"].nunique().rename("freq_doc")
    construct_freq = pd.concat([freq_doc, freq_total], axis=1).reset_index()
    construct_freq = construct_freq[construct_freq["freq_doc"] >= min_freq].copy()
    construct_freq = construct_freq.sort_values("freq_doc", ascending=False).reset_index(drop=True)
    construct_freq["construct_id"] = range(1, len(construct_freq) + 1)
    construct_freq = construct_freq[["construct_id", "surface_form", "freq_doc", "freq_total"]]

    # Filter chunks down to retained constructs and attach construct_id
    chunks = chunks.merge(construct_freq[["construct_id", "surface_form"]], on="surface_form", how="inner")
    # Join unit_text back
    chunks = chunks.merge(units[["unit_id", "unit_text"]], on="unit_id", how="left")

    return construct_freq, chunks
