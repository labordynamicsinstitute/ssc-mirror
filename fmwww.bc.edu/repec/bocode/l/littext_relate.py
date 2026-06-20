"""littext_relate: score candidate relationships between constructs (v0.2).

If add_sentiment=True, an affective-polarity score on the evidence sentence
is added in `text_polarity` (VADER). This is distinct from relationship
valence and should not be interpreted as one.
"""

from __future__ import annotations

import math
from collections import Counter, defaultdict
from typing import Dict, List, Optional, Tuple

import numpy as np
import pandas as pd


# --- Verb lexicons (inflected forms; legacy, kept for compatibility) ---

_POS_VERBS = {
    "increase", "increases", "increased", "increasing",
    "enhance", "enhances", "enhanced", "enhancing",
    "drive", "drives", "drove", "driving",
    "boost", "boosts", "boosted", "boosting",
    "strengthen", "strengthens", "strengthened", "strengthening",
    "improve", "improves", "improved", "improving",
    "predict", "predicts", "predicted", "predicting",
    "promote", "promotes", "promoted", "promoting",
    "raise", "raises", "raised", "raising",
    "amplify", "amplifies", "amplified", "amplifying",
    "facilitate", "facilitates", "facilitated", "facilitating",
}
_NEG_VERBS = {
    "decrease", "decreases", "decreased", "decreasing",
    "reduce", "reduces", "reduced", "reducing",
    "weaken", "weakens", "weakened", "weakening",
    "attenuate", "attenuates", "attenuated", "attenuating",
    "diminish", "diminishes", "diminished", "diminishing",
    "lower", "lowers", "lowered", "lowering",
    "undermine", "undermines", "undermined", "undermining",
    "harm", "harms", "harmed", "harming",
    "inhibit", "inhibits", "inhibited", "inhibiting",
    "dampen", "dampens", "dampened", "dampening",
}
_CAUSE_VERBS = {
    "cause", "causes", "caused", "causing",
    "lead", "leads", "led", "leading",
    "produce", "produces", "produced", "producing",
}
_MODERATE_VERBS = {"moderate", "moderates", "moderated", "moderating"}
_MEDIATE_VERBS = {"mediate", "mediates", "mediated", "mediating"}

# --- Lemma sets used by the v0.2 dependency-arc matchers ---

_POS_LEMMAS = {
    "increase", "enhance", "drive", "boost", "strengthen", "improve",
    "predict", "promote", "raise", "amplify", "facilitate",
    # v0.2.5: bipolar verbs that appear at high frequency in real marketing
    # abstracts (drawn from parse inspection of the 33-paper test corpus).
    # These are bipolar in principle ("X affects Y negatively") but default
    # to pos_assoc; explicit negative valence is layered on by pattern E
    # via adjectival modification of a relationship-anchor noun.
    "affect", "shape", "determine", "explain", "contribute", "influence", "impact",
}
_NEG_LEMMAS = {
    "decrease", "reduce", "weaken", "attenuate", "diminish", "lower",
    "undermine", "harm", "inhibit", "dampen",
}
_CAUSE_LEMMAS = {"cause", "lead", "produce"}

# Adjectival valence markers used by pattern E. We keep this small and
# high-precision; ambiguous adjectives like "significant" are not in this
# set (they describe statistical significance, not valence).
_POS_ADJ_LEMMAS = {"positive", "beneficial", "favorable", "favourable"}
_NEG_ADJ_LEMMAS = {"negative", "detrimental", "adverse", "harmful"}

# Backward-compatible aliases retained for any external import
_POS_VERBS_LEMMAS = _POS_LEMMAS
_NEG_VERBS_LEMMAS = _NEG_LEMMAS
_CAUSE_VERBS_LEMMAS = _CAUSE_LEMMAS

# Confidence boosts per pattern type.
_BOOST = {
    "A": 0.30,   # nominal moderation / mediation
    "C": 0.25,   # passive
    "F": 0.22,   # v0.2.3 copular nominal anchor (high specificity)
    "B": 0.20,   # finite-verb VSO
    "E": 0.15,   # adjectival valence
    "D": 0.10,   # nominal-pattern relationship
}


# --- Utilities ---

def _npmi(p_xy: float, p_x: float, p_y: float) -> float:
    """Normalised pointwise mutual information; returns value in [-1, 1]."""
    if p_xy <= 0 or p_x <= 0 or p_y <= 0:
        return 0.0
    pmi = math.log(p_xy / (p_x * p_y))
    h = -math.log(p_xy)
    if h <= 0:
        return 0.0
    return pmi / h


def _vader_scorer():
    """Return a VADER analyzer if available, else None."""
    try:
        from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
        return SentimentIntensityAnalyzer()
    except Exception:
        return None


def _find_construct_span(doc, surface: str) -> Optional[Tuple[int, int]]:
    """Return the (start_token_index, end_token_index) of the construct in
    the parsed doc, matching on lowercased text. Returns None if not found."""
    surface_l = surface.lower().strip()
    if not surface_l:
        return None
    surface_tokens = surface_l.split()
    n_st = len(surface_tokens)
    toks = [tok.text.lower() for tok in doc]
    for i in range(len(toks) - n_st + 1):
        if toks[i:i + n_st] == surface_tokens:
            return (i, i + n_st)
    return None


def _find_any_span(doc, surfaces) -> Optional[Tuple[int, int]]:
    """
    Background: HDBSCAN clustering in the synonym-collapse step assigns a
    canonical_form to each surface form. When the canonical form differs
    lexically from the surface form that actually appears in a given
    sentence (e.g. surface "loyalty" clustered under canonical "brand
    loyalty"), _find_construct_span(doc, canonical) cannot find a
    contiguous match and returns None. 
    """
    if isinstance(surfaces, str):
        return _find_construct_span(doc, surfaces)
    candidates = sorted({s.lower().strip() for s in surfaces if s and s.strip()},
                        key=lambda s: (-len(s.split()), s))
    for cand in candidates:
        span = _find_construct_span(doc, cand)
        if span is not None:
            return span
    return None


def _sentence_flags(doc) -> Dict[str, bool]:
    """optimisation: pre-compute which patterns can possibly fire on
    a given parsed sentence. The pattern matchers themselves then check this
    flag first and exit immediately if the relevant trigger is absent,
    avoiding a full O(N) token scan per (sentence, construct-pair) combination.

    Returns a dict with keys A, B, C, D, E, F. Value True means "this pattern
    might match"; False means "this pattern definitely cannot match".

    F flag is the copular-nominal-anchor pattern.
    """
    has_mod_med_verb = False
    has_valence_verb = False
    has_passive = False
    has_anchor_noun = False
    has_assoc_relate_verb = False
    has_valence_adj_on_anchor = False
    has_valence_adv = False
    has_copular_anchor = False
    for tok in doc:
        lem = tok.lemma_.lower()
        if tok.pos_ == "VERB":
            if lem in _MODERATE_VERBS or lem in _MEDIATE_VERBS:
                has_mod_med_verb = True
            if lem in _POS_LEMMAS or lem in _NEG_LEMMAS or lem in _CAUSE_LEMMAS:
                has_valence_verb = True
                for child in tok.children:
                    if child.dep_ == "nsubjpass":
                        has_passive = True
                        break
            if lem in {"associate", "relate", "link", "correlate"}:
                has_assoc_relate_verb = True
        if lem in _REL_ANCHOR_NOUNS:
            has_anchor_noun = True
            for child in tok.children:
                if child.dep_ != "amod":
                    continue
                if child.lemma_.lower() in (_POS_ADJ_LEMMAS | _NEG_ADJ_LEMMAS):
                    has_valence_adj_on_anchor = True
                    break
                # Walk conj siblings of this amod
                for sibling in child.children:
                    if sibling.dep_ == "conj" and sibling.lemma_.lower() in (_POS_ADJ_LEMMAS | _NEG_ADJ_LEMMAS):
                        has_valence_adj_on_anchor = True
                        break
                if has_valence_adj_on_anchor:
                    break
        if lem in _COPULAR_ANCHOR_LEXICON:
            has_copular_anchor = True
        if tok.dep_ == "advmod" and lem in {"positively", "negatively"}:
            has_valence_adv = True
    return {
        "A": has_mod_med_verb,
        "B": has_valence_verb,
        "C": has_passive and has_valence_verb,
        "D": has_anchor_noun or has_assoc_relate_verb,
        "E": has_valence_adj_on_anchor or (has_valence_adv and has_assoc_relate_verb),
        "F": has_copular_anchor,
    }


def _head_token(doc, span: Tuple[int, int]):
    """Return the syntactic head token of a span (its rightmost noun in
    practice). We use the last token of the span, which is usually the
    head noun in English noun phrases (e.g. "brand authenticity" -> "authenticity")."""
    return doc[span[1] - 1]


def _is_within_or_descendant(target_token, anchor_span: Tuple[int, int]) -> bool:
    """True if target_token is inside the anchor_span or is a syntactic
    descendant of any token in the anchor_span.   
    """
    a_start, a_end = anchor_span
    if a_start <= target_token.i < a_end:
        return True
    cur = target_token
    doc_len = len(target_token.doc)
    steps = 0
    while cur.head is not cur:
        steps += 1
        if steps > doc_len:
            return False  # safety bound: cyclic or pathologically deep parse
        cur = cur.head
        if a_start <= cur.i < a_end:
            return True
    return False


def _construct_anywhere_below(start_token, construct_span: Tuple[int, int], max_depth: int = 4) -> bool:
    """descend the dependency tree from start_token through prep/pobj
    arcs, looking for a construct head within `construct_span`.   
    """
    c_start, c_end = construct_span
    # BFS through allowed dependency arcs
    frontier = [(start_token, 0)]
    visited = {start_token.i}
    while frontier:
        tok, depth = frontier.pop(0)
        if c_start <= tok.i < c_end:
            return True
        if depth >= max_depth:
            continue
        for child in tok.children:
            if child.i in visited:
                continue
            if child.dep_ in {"prep", "pobj", "dobj", "attr", "conj", "nmod", "amod", "compound"}:
                visited.add(child.i)
                frontier.append((child, depth + 1))
    return False


def _all_pobjs(prep_token) -> List:
    """return ALL pobj children of a preposition, not just the first.
    """
    return [c for c in prep_token.children if c.dep_ == "pobj"]


def _any_pobj_reaches(prep_token, construct_span: Tuple[int, int]) -> bool:
    """True if ANY pobj child of `prep_token` reaches the construct
    span via `_construct_anywhere_below`."""
    for pobj in _all_pobjs(prep_token):
        if _construct_anywhere_below(pobj, construct_span):
            return True
    return False


def _collect_preps_in_subtree(anchor_token, prep_texts: set, max_depth: int = 3) -> List:
    """collect all `prep` tokens whose surface text is in `prep_texts`,
    reachable from `anchor_token` by walking down through prep/pobj/conj/nmod
    arcs, up to `max_depth`.    
    """
    found = []
    frontier = [(anchor_token, 0)]
    visited = {anchor_token.i}
    while frontier:
        tok, depth = frontier.pop(0)
        if depth >= max_depth:
            continue
        for child in tok.children:
            if child.i in visited:
                continue
            visited.add(child.i)
            if child.dep_ == "prep" and child.text.lower() in prep_texts:
                found.append(child)
            # Descend through arcs that can carry further preps
            if child.dep_ in {"prep", "pobj", "conj", "nmod", "compound", "amod"}:
                frontier.append((child, depth + 1))
    return found

def _pattern_A_nominal_moderation(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """Nominal moderation/mediation patterns.

    Examples:
      "the moderating role of X on the relationship between A and B"
      "X mediates the effect of A on B"
      "the mediating role of M"    
    """
    for tok in doc:
        if tok.pos_ != "VERB":
            continue
        lem = tok.lemma_.lower()
        if lem not in _MODERATE_VERBS and lem not in _MEDIATE_VERBS:
            continue
        rel = "moderates" if lem in _MODERATE_VERBS else "mediates"

        # branch on verbal vs nominal use.
        if tok.dep_ == "amod":
            # Nominal mediation/moderation. The trigger modifies a head
            # noun ("role", "effect", "influence"). The mediator is the
            # head noun's "of" pobj. The (source, target) pair is left
            # in the order it was passed in; full triple resolution is
            # deferred to v0.3.
            head_noun = tok.head
            mediator_pobj = None
            for ch in head_noun.children:
                if ch.dep_ == "prep" and ch.text.lower() == "of":
                    pobjs = _all_pobjs(ch)
                    if pobjs:
                        mediator_pobj = pobjs[0]
                        break
            if mediator_pobj is None:
                # No "of" pobj; we cannot identify the mediator. Skip.
                continue
            # If either construct IS the mediator, put it first.
            if a_span[0] <= mediator_pobj.i < a_span[1]:
                return (rel, a, b, "A")
            if b_span[0] <= mediator_pobj.i < b_span[1]:
                return (rel, b, a, "A")
            # Neither construct is the mediator; the sentence describes a
            # mediation that involves our pair tangentially. Keep input order.
            return (rel, a, b, "A")

        # Verbal mediation/moderation.
        a_head = _head_token(doc, a_span)
        b_head = _head_token(doc, b_span)
        a_connected = _is_within_or_descendant(a_head, (tok.i, tok.i + 1))
        b_connected = _is_within_or_descendant(b_head, (tok.i, tok.i + 1))
        if a_connected or b_connected:
            subj = None
            for child in tok.children:
                if child.dep_ in {"nsubj", "nsubjpass"}:
                    subj = child
                    break
            if subj is not None:
                if subj.i >= a_span[0] and subj.i < a_span[1]:
                    return (rel, a, b, "A")
                if subj.i >= b_span[0] and subj.i < b_span[1]:
                    return (rel, b, a, "A")
            return (rel, a, b, "A")
    return None


def _pattern_B_finite_vso(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """Finite-verb VSO with dependency-arc direction.

    "X drives Y": find a VERB whose nsubj is in one construct span and whose
    dobj/pobj is in the other. The valence is determined by the verb's lemma.
    """
    for tok in doc:
        if tok.pos_ != "VERB":
            continue
        lem = tok.lemma_.lower()
        valence = None
        if lem in _POS_LEMMAS:
            valence = "pos_assoc"
        elif lem in _NEG_LEMMAS:
            valence = "neg_assoc"
        elif lem in _CAUSE_LEMMAS:
            valence = "causes"
        if valence is None:
            continue
        # Find the verb's subject and direct object/complement, plus any
        # prepositional objects (multiple preps are possible: "X drove Y in Z").
        subj_tok = None
        direct_obj_tok = None
        prep_objs = []  # list of pobj tokens from any prep child of the verb
        for child in tok.children:
            if child.dep_ == "nsubj":
                subj_tok = child
            elif child.dep_ in {"dobj", "attr", "oprd"}:
                direct_obj_tok = child
            elif child.dep_ == "prep":
                prep_objs.extend(_all_pobjs(child))
        if subj_tok is None or (direct_obj_tok is None and not prep_objs):
            continue
        
        obj_candidates = ([direct_obj_tok] if direct_obj_tok is not None else []) + prep_objs
        # Subject reaches?
        subj_reaches_a = _construct_anywhere_below(subj_tok, a_span)
        subj_reaches_b = _construct_anywhere_below(subj_tok, b_span)
        # Object set reaches?
        obj_reaches_a = any(_construct_anywhere_below(o, a_span) for o in obj_candidates)
        obj_reaches_b = any(_construct_anywhere_below(o, b_span) for o in obj_candidates)
        if subj_reaches_a and obj_reaches_b:
            return (valence, a, b, "B")
        if subj_reaches_b and obj_reaches_a:
            return (valence, b, a, "B")
    return None


def _pattern_C_passive(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """Passive constructions: "Y is driven by X" -> source=X, target=Y.    
    """
    for tok in doc:
        if tok.pos_ != "VERB":
            continue
        lem = tok.lemma_.lower()
        valence = None
        if lem in _POS_LEMMAS:
            valence = "pos_assoc"
        elif lem in _NEG_LEMMAS:
            valence = "neg_assoc"
        elif lem in _CAUSE_LEMMAS:
            valence = "causes"
        if valence is None:
            continue
        nsubjpass = None
        agent_pobjs = []
        for child in tok.children:
            if child.dep_ == "nsubjpass":
                nsubjpass = child
            elif child.dep_ == "agent":
                agent_pobjs.extend(_all_pobjs(child))
        if nsubjpass is None or not agent_pobjs:
            continue
        subj_reaches_a = _construct_anywhere_below(nsubjpass, a_span)
        subj_reaches_b = _construct_anywhere_below(nsubjpass, b_span)
        agent_reaches_a = any(_construct_anywhere_below(g, a_span) for g in agent_pobjs)
        agent_reaches_b = any(_construct_anywhere_below(g, b_span) for g in agent_pobjs)
        if subj_reaches_a and agent_reaches_b:
            return (valence, b, a, "C")  # agent is source
        if subj_reaches_b and agent_reaches_a:
            return (valence, a, b, "C")
    return None


# Nouns that act as relationship anchors in nominal patterns.
_REL_ANCHOR_NOUNS = {
    # v0.2.0 originals
    "effect", "effects", "influence", "influences", "impact", "impacts",
    "role", "relationship", "relationships", "association", "associations",
    "link", "links", "correlation", "correlations",
    # v0.2.3 additions: nominal-anchor terms drawn from real marketing
    # abstracts that v0.2.2 missed
    "antecedent", "antecedents", "precursor", "precursors",
    "predictor", "predictors", "determinant", "determinants",
    "driver", "drivers", "outcome", "outcomes",
    "consequence", "consequences", "mediator", "mediators",
    "moderator", "moderators",
}

# anchor nouns that carry an INHERENT directional meaning when used
# copularly ("X is the antecedent of Y").

_COPULAR_ANCHOR_LEXICON = {
    "antecedent":  ("pos_assoc", "forward"),
    "antecedents": ("pos_assoc", "forward"),
    "precursor":   ("pos_assoc", "forward"),
    "precursors":  ("pos_assoc", "forward"),
    "predictor":   ("pos_assoc", "forward"),
    "predictors":  ("pos_assoc", "forward"),
    "determinant": ("pos_assoc", "forward"),
    "determinants":("pos_assoc", "forward"),
    "driver":      ("pos_assoc", "forward"),
    "drivers":     ("pos_assoc", "forward"),
    "outcome":     ("pos_assoc", "backward"),
    "outcomes":    ("pos_assoc", "backward"),
    "consequence": ("pos_assoc", "backward"),
    "consequences":("pos_assoc", "backward"),
}


def _pattern_F_copular_anchor(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """copular nominal-anchor pattern; v0.2.8: extended with two
    additional configurations discovered in real-corpus parses.

    Recognises sentences such as:
      (config 1, original) "X is the most important antecedent of Y"
                           "Z is a predictor of consumer loyalty"
                           "loyalty is the outcome of brand authenticity"
      (config 2, v0.2.8)   "Brand image as a determinant of brand attitude"
                           "X as determinants of Y" (predicative complement)
      (config 3, v0.2.8)   "The main predictor of brand equity is consumer trust"
                           (anchor noun as subject; X is the attr)    
    """
    for tok in doc:
        lem = tok.lemma_.lower()
        if lem not in _COPULAR_ANCHOR_LEXICON:
            continue

        relation_type, direction = _COPULAR_ANCHOR_LEXICON[lem]
        
        of_prep = None
        for ch in tok.children:
            if ch.dep_ == "prep" and ch.text.lower() == "of":
                of_prep = ch
                break
        if of_prep is None:
            # Without an "of" prep there's no anchor->Y structure; F cannot fire.
            continue
        
        subj = None
        # The anchor needs to be a copular attribute (dep=attr, oprd, or
        # acomp) directly, or its head needs to walk back to such a node
        # via bridge arcs.
        BRIDGE_DEPS = {"amod", "compound", "nmod", "det", "quantmod"}
        cur = tok
        if tok.dep_ in {"attr", "oprd", "acomp"}:
            # Direct attribute of a copula. cur.head should be the copula.
            verb = tok.head
            if verb.lemma_.lower() == "be" or verb.pos_ in {"VERB", "AUX"}:
                for ch in verb.children:
                    if ch.dep_ in {"nsubj", "nsubjpass"}:
                        subj = ch
                        break
        else:            
            steps = 0
            while cur.head is not cur and steps < len(doc):
                steps += 1
                if cur.dep_ not in (BRIDGE_DEPS | {"attr", "oprd", "acomp"}):
                    # Hit a non-bridge dep before reaching the copula; abort.
                    break
                cur = cur.head
                if cur.lemma_.lower() == "be" or (cur.pos_ in {"VERB", "AUX"} and tok.dep_ in {"attr", "oprd", "acomp"}):
                    for ch in cur.children:
                        if ch.dep_ in {"nsubj", "nsubjpass"}:
                            subj = ch
                            break
                    if subj is not None:
                        break
        
        if subj is None and tok.dep_ == "pobj":
            governing_prep = tok.head
            if governing_prep.pos_ == "ADP" and governing_prep.text.lower() == "as":
                matrix = governing_prep.head                
                candidates = sorted(
                    [ch for ch in matrix.children if ch.dep_ in {"dobj", "nsubj", "nsubjpass"}],
                    key=lambda c: 0 if c.dep_ == "dobj" else 1
                )
                if candidates:
                    subj = candidates[0]
        
        if subj is None and tok.dep_ == "nsubj":
            copula = tok.head
            if copula.lemma_.lower() == "be" or copula.pos_ in {"VERB", "AUX"}:
                for ch in copula.children:
                    if ch.dep_ in {"attr", "acomp", "oprd"}:
                        subj = ch
                        break

        if subj is None:
            continue

        # Determine which construct sits at the subject end vs the pobj end.
        subj_reaches_a = _construct_anywhere_below(subj, a_span)
        subj_reaches_b = _construct_anywhere_below(subj, b_span)
        pobj_reaches_a = _any_pobj_reaches(of_prep, a_span)
        pobj_reaches_b = _any_pobj_reaches(of_prep, b_span)

        if subj_reaches_a and pobj_reaches_b:
            if direction == "forward":
                return (relation_type, a, b, "F")
            else:
                return (relation_type, b, a, "F")
        if subj_reaches_b and pobj_reaches_a:
            if direction == "forward":
                return (relation_type, b, a, "F")
            else:
                return (relation_type, a, b, "F")
    return None


def _pattern_D_nominal(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """Nominal-pattern relationships.

    "the effect of X on Y", "the influence of X on Y" -> source=X, target=Y
    "the relationship between X and Y" -> assoc (symmetric)
    "X is associated with Y" -> assoc (symmetric)
    "X is related to Y" -> assoc
    "X have an effect on Y" -> source=X (nsubj of matrix verb), target=Y
    """
    
    for tok in doc:
        if tok.lemma_.lower() not in _REL_ANCHOR_NOUNS:
            continue
        # "of" prep is generally a direct child; "on" / "for" / "between" /
        # "with" may live further down in the subtree.
        of_preps = _collect_preps_in_subtree(tok, {"of"}, max_depth=1)
        on_preps = _collect_preps_in_subtree(tok, {"on", "for"}, max_depth=3)
        between_preps = _collect_preps_in_subtree(tok, {"between"}, max_depth=2)
        with_preps = _collect_preps_in_subtree(tok, {"with", "to"}, max_depth=2)

        of_objs: List = []
        on_objs: List = []
        between_objs: List = []
        with_objs: List = []
        for p in of_preps: of_objs.extend(_all_pobjs(p))
        for p in on_preps: on_objs.extend(_all_pobjs(p))
        for p in between_preps:
            base_pobjs = _all_pobjs(p)
            between_objs.extend(base_pobjs)
            # "between A and B" can parse as either conj or nmod on the pobj
            for bp in base_pobjs:
                for ch in bp.children:
                    if ch.dep_ in {"conj", "nmod"}:
                        between_objs.append(ch)
        for p in with_preps: with_objs.extend(_all_pobjs(p))

        # Pattern "X effect on Y" with directional reading
        if of_objs and on_objs:
            of_in_a = any(_construct_anywhere_below(o, a_span) for o in of_objs)
            of_in_b = any(_construct_anywhere_below(o, b_span) for o in of_objs)
            on_in_a = any(_construct_anywhere_below(o, a_span) for o in on_objs)
            on_in_b = any(_construct_anywhere_below(o, b_span) for o in on_objs)
            if of_in_a and on_in_b:
                return ("assoc", a, b, "D")
            if of_in_b and on_in_a:
                return ("assoc", b, a, "D")
        # Pattern "relationship between A and B" (symmetric)
        if between_objs:
            in_a = any(_construct_anywhere_below(t, a_span) for t in between_objs)
            in_b = any(_construct_anywhere_below(t, b_span) for t in between_objs)
            if in_a and in_b:
                return ("assoc", a, b, "D")
        # v0.2.5: Pattern "X have an effect on Y" - source is nsubj of the
        # matrix verb that takes the anchor noun as dobj/attr.
        if on_objs and tok.dep_ in {"dobj", "attr", "oprd"}:
            matrix_verb = tok.head
            nsubj = None
            for ch in matrix_verb.children:
                if ch.dep_ == "nsubj":
                    nsubj = ch
                    break
            if nsubj is not None:
                nsubj_in_a = _construct_anywhere_below(nsubj, a_span)
                nsubj_in_b = _construct_anywhere_below(nsubj, b_span)
                on_in_a = any(_construct_anywhere_below(o, a_span) for o in on_objs)
                on_in_b = any(_construct_anywhere_below(o, b_span) for o in on_objs)
                if nsubj_in_a and on_in_b:
                    return ("assoc", a, b, "D")
                if nsubj_in_b and on_in_a:
                    return ("assoc", b, a, "D")
        # Pattern "associated with" / "related to"
        if with_objs:
            with_in_a = any(_construct_anywhere_below(o, a_span) for o in with_objs)
            with_in_b = any(_construct_anywhere_below(o, b_span) for o in with_objs)
            if with_in_a or with_in_b:
                return ("assoc", a, b, "D")
    # Also detect "X is associated with Y" via copular construction
    for tok in doc:
        if tok.lemma_.lower() not in {"associate", "relate", "link", "correlate"}:
            continue
        if tok.pos_ not in {"VERB", "ADJ"}:
            continue
        subj = None
        prep_objs: List = []
        for child in tok.children:
            if child.dep_ in {"nsubj", "nsubjpass"}:
                subj = child
            elif child.dep_ == "prep":
                prep_objs.extend(_all_pobjs(child))
        if subj is not None and prep_objs:
            subj_in_a = _construct_anywhere_below(subj, a_span)
            subj_in_b = _construct_anywhere_below(subj, b_span)
            prep_in_a = any(_construct_anywhere_below(o, a_span) for o in prep_objs)
            prep_in_b = any(_construct_anywhere_below(o, b_span) for o in prep_objs)
            if (subj_in_a and prep_in_b) or (subj_in_b and prep_in_a):
                return ("assoc", a, b, "D")
    return None


def _pattern_E_adjectival(doc, a_span, b_span, a, b) -> Optional[Tuple[str, str, str, str]]:
    """Adjectival valence specialisation of pattern D.

    "a positive effect of X on Y" / "a significant negative impact of X on Y"
    Same syntactic structure as D, but with a valence adjective modifying
    the relationship anchor noun.    
    """
    for tok in doc:
        if tok.lemma_.lower() not in _REL_ANCHOR_NOUNS:
            continue
        # v0.2.5: find an adjectival modifier with valence; follow conj.
        valence = None
        for child in tok.children:
            if child.dep_ != "amod":
                continue
            alem = child.lemma_.lower()
            if alem in _POS_ADJ_LEMMAS:
                valence = "pos_assoc"
                break
            if alem in _NEG_ADJ_LEMMAS:
                valence = "neg_assoc"
                break
            # Walk conj from this amod
            for sib in child.children:
                if sib.dep_ != "conj":
                    continue
                slem = sib.lemma_.lower()
                if slem in _POS_ADJ_LEMMAS:
                    valence = "pos_assoc"
                    break
                if slem in _NEG_ADJ_LEMMAS:
                    valence = "neg_assoc"
                    break
            if valence is not None:
                break
        if valence is None:
            continue
        
        of_preps = _collect_preps_in_subtree(tok, {"of"}, max_depth=1)
        on_preps = _collect_preps_in_subtree(tok, {"on", "for"}, max_depth=3)
        between_preps = _collect_preps_in_subtree(tok, {"between"}, max_depth=2)
        of_objs: List = []
        on_objs: List = []
        between_objs: List = []
        for p in of_preps: of_objs.extend(_all_pobjs(p))
        for p in on_preps: on_objs.extend(_all_pobjs(p))
        for p in between_preps:
            base_pobjs = _all_pobjs(p)
            between_objs.extend(base_pobjs)
            for bp in base_pobjs:
                for ch in bp.children:
                    if ch.dep_ in {"conj", "nmod"}:
                        between_objs.append(ch)

        # "of X on Y" with directional reading
        if of_objs and on_objs:
            of_in_a = any(_construct_anywhere_below(o, a_span) for o in of_objs)
            of_in_b = any(_construct_anywhere_below(o, b_span) for o in of_objs)
            on_in_a = any(_construct_anywhere_below(o, a_span) for o in on_objs)
            on_in_b = any(_construct_anywhere_below(o, b_span) for o in on_objs)
            if of_in_a and on_in_b:
                return (valence, a, b, "E")
            if of_in_b and on_in_a:
                return (valence, b, a, "E")
        # "between A and B" symmetric case with valence
        if between_objs:
            in_a = any(_construct_anywhere_below(t, a_span) for t in between_objs)
            in_b = any(_construct_anywhere_below(t, b_span) for t in between_objs)
            if in_a and in_b:
                return (valence, a, b, "E")
        # "X have an [adj] effect on Y": nsubj of matrix verb is source
        if on_objs and tok.dep_ in {"dobj", "attr", "oprd"}:
            matrix_verb = tok.head
            nsubj = None
            for ch in matrix_verb.children:
                if ch.dep_ == "nsubj":
                    nsubj = ch
                    break
            if nsubj is not None:
                nsubj_in_a = _construct_anywhere_below(nsubj, a_span)
                nsubj_in_b = _construct_anywhere_below(nsubj, b_span)
                on_in_a = any(_construct_anywhere_below(o, a_span) for o in on_objs)
                on_in_b = any(_construct_anywhere_below(o, b_span) for o in on_objs)
                if nsubj_in_a and on_in_b:
                    return (valence, a, b, "E")
                if nsubj_in_b and on_in_a:
                    return (valence, b, a, "E")
    # "X is positively related to Y" — handled in pattern D as assoc; we
    # specialise it here when an explicit valence adverb is present.
    for tok in doc:
        if tok.lemma_.lower() not in {"relate", "associate", "link", "correlate"}:
            continue
        if tok.pos_ not in {"VERB", "ADJ"}:
            continue
        valence = None
        for child in tok.children:
            if child.dep_ == "advmod":
                alem = child.lemma_.lower()
                if alem == "positively":
                    valence = "pos_assoc"
                    break
                if alem == "negatively":
                    valence = "neg_assoc"
                    break
        if valence is None:
            continue
        subj = None
        prep_objs: List = []
        for child in tok.children:
            if child.dep_ in {"nsubj", "nsubjpass"}:
                subj = child
            elif child.dep_ == "prep":
                prep_objs.extend(_all_pobjs(child))
        if subj is not None and prep_objs:
            subj_in_a = _construct_anywhere_below(subj, a_span)
            subj_in_b = _construct_anywhere_below(subj, b_span)
            prep_in_a = any(_construct_anywhere_below(o, a_span) for o in prep_objs)
            prep_in_b = any(_construct_anywhere_below(o, b_span) for o in prep_objs)
            if subj_in_a and prep_in_b:
                return (valence, a, b, "E")
            if subj_in_b and prep_in_a:
                return (valence, b, a, "E")
    return None


def _classify_pair(doc, a: str, b: str, flags: Optional[Dict[str, bool]] = None,
                   a_surfaces=None, b_surfaces=None) -> Tuple[str, str, str, str]:
    """Returns (rel_type, source, target, pattern_id). pattern_id is "A".."F" for
    a matched pattern or "Z" if no pattern fired (fallback assoc).
    """
    a_surfaces = a_surfaces if a_surfaces else [a]
    b_surfaces = b_surfaces if b_surfaces else [b]
    a_span = _find_any_span(doc, a_surfaces)
    b_span = _find_any_span(doc, b_surfaces)
    if a_span is None or b_span is None:
        # Should rarely happen because constructs were extracted from this
        # very sentence; falls back to assoc with alphabetical ordering.
        s, t = sorted([a, b])
        return ("assoc", s, t, "Z")
    if flags is None:
        flags = {"A": True, "B": True, "C": True, "D": True, "E": True, "F": True}
    # Try patterns in priority order, skipping those whose triggers are absent.
    # v0.2.3 dispatch order: high-precision specific patterns first (A, F, C),
    # then medium (B, E), then catch-all nominal (D).
    if flags.get("A", False):
        out = _pattern_A_nominal_moderation(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    if flags.get("F", False):
        out = _pattern_F_copular_anchor(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    if flags.get("C", False):
        out = _pattern_C_passive(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    if flags.get("B", False):
        out = _pattern_B_finite_vso(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    if flags.get("E", False):
        out = _pattern_E_adjectival(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    if flags.get("D", False):
        out = _pattern_D_nominal(doc, a_span, b_span, a, b)
        if out is not None:
            return out
    # Fallback: assoc, alphabetical ordering
    s, t = sorted([a, b])
    return ("assoc", s, t, "Z")


# --- Main entry point ---

def score_relations(
    units_df: pd.DataFrame,
    constructs_df: pd.DataFrame,
    max_relations: int = 100_000,
    add_sentiment: bool = False,
) -> pd.DataFrame:
    """Score candidate construct-construct relationships using the v0.2
    five-pattern dependency-arc matcher."""
    empty_cols = [
        "rel_id", "doc_id", "unit_id", "source", "target",
        "source_construct_id", "target_construct_id",
        "relation_type", "confidence", "extraction_method",
        "evidence_text", "text_polarity",
    ]
    if len(units_df) == 0 or len(constructs_df) == 0:
        return pd.DataFrame(columns=empty_cols)

    surf_to_canon = dict(zip(constructs_df["surface_form"], constructs_df["canonical_form"]))
    surf_to_cid = dict(zip(constructs_df["surface_form"], constructs_df["construct_id"]))

    udf = units_df.copy()
    udf["canonical_form"] = udf["surface_form"].map(surf_to_canon)
    udf["construct_id"] = udf["surface_form"].map(surf_to_cid)
    udf = udf.dropna(subset=["canonical_form"])

    n_units = udf["unit_id"].nunique()
    if n_units == 0:
        return pd.DataFrame(columns=empty_cols)

    canon_unit_pairs = udf[["unit_id", "canonical_form"]].drop_duplicates()
    canon_counts = canon_unit_pairs.groupby("canonical_form").size().to_dict()
    pair_counts: Counter = Counter()
    pair_units: Dict[Tuple[str, str], List[str]] = defaultdict(list)
    for uid, grp in canon_unit_pairs.groupby("unit_id"):
        canons = sorted(grp["canonical_form"].unique().tolist())
        for i in range(len(canons)):
            for j in range(i + 1, len(canons)):
                pair_counts[(canons[i], canons[j])] += 1
                pair_units[(canons[i], canons[j])].append(uid)

    import spacy
    nlp = spacy.load("en_core_web_sm", disable=["ner"])
    
    doc_cache: Dict[str, object] = {}
    flag_cache: Dict[str, Dict[str, bool]] = {}

    def _get_doc(uid: str, text: str):
        if uid not in doc_cache:
            d = nlp(text)
            doc_cache[uid] = d
            flag_cache[uid] = _sentence_flags(d)
        return doc_cache[uid], flag_cache[uid]
    
    uid_first_row: Dict[str, Dict[str, str]] = {}
    for uid in udf["unit_id"].unique():
        sub = udf[udf["unit_id"] == uid]
        if len(sub) > 0:
            r = sub.iloc[0]
            uid_first_row[uid] = {
                "doc_id":    r["doc_id"],
                "unit_text": r["unit_text"],
            }
    
    canon_to_cid: Dict[str, int] = {}
    for _, cr in constructs_df.iterrows():
        canon = cr["canonical_form"]
        if canon not in canon_to_cid:
            canon_to_cid[canon] = int(cr["construct_id"])
    
    canon_to_surfaces: Dict[str, List[str]] = defaultdict(list)
    for _, cr in constructs_df.iterrows():
        canon = cr["canonical_form"]
        surface = cr["surface_form"]
        if surface not in canon_to_surfaces[canon]:
            canon_to_surfaces[canon].append(surface)
        # Always include the canonical form itself as a candidate; in many
        # clusters the canonical equals one of the surfaces but we want to
        # be safe in case the constructs_df schema evolves.
        if canon not in canon_to_surfaces[canon]:
            canon_to_surfaces[canon].append(canon)

    rows: List[dict] = []
    rel_id = 0
    n_pairs = len(pair_counts)
    progress_every = max(1, n_pairs // 10)
    pair_idx = 0
    import sys as _sys
    for (a, b), c_ab in pair_counts.items():
        pair_idx += 1
        if pair_idx % progress_every == 0 or pair_idx == n_pairs:
            print(f"    scoring pair {pair_idx}/{n_pairs} ({pair_idx*100//n_pairs}%)", flush=True)
            try:
                _sys.stdout.flush()
            except Exception:
                pass
        p_xy = c_ab / n_units
        p_x = canon_counts[a] / n_units
        p_y = canon_counts[b] / n_units
        npmi = _npmi(p_xy, p_x, p_y)
        # Representative unit: first occurrence
        for uid in pair_units[(a, b)][:1]:
            ur = uid_first_row.get(uid)
            if ur is None:
                continue
            evidence = ur["unit_text"]
            doc_id   = ur["doc_id"]
            doc, sflags = _get_doc(uid, evidence)
            rel_type, source, target, pattern = _classify_pair(
                doc, a, b, flags=sflags,
                a_surfaces=canon_to_surfaces.get(a, [a]),
                b_surfaces=canon_to_surfaces.get(b, [b]),
            )
            # Confidence: NPMI rescaled to [0,1], plus pattern-specific boost
            conf = max(0.0, min(1.0, (npmi + 1.0) / 2.0))
            if pattern in _BOOST:
                conf = min(1.0, conf + _BOOST[pattern])
            rel_id += 1
            rows.append({
                "rel_id": rel_id,
                "doc_id": doc_id,
                "unit_id": uid,
                "source": source,
                "target": target,
                "source_construct_id": canon_to_cid.get(source, 0),
                "target_construct_id": canon_to_cid.get(target, 0),
                "relation_type": rel_type,
                "confidence": round(conf, 4),
                "extraction_method": ("cooccur+dep:" + pattern) if pattern != "Z" else "cooccur",
                "evidence_text": evidence[:500],
                "text_polarity": float("nan"),
            })

    rels = pd.DataFrame(rows)
    if len(rels) == 0:
        return rels

    if add_sentiment:
        vader = _vader_scorer()
        if vader is not None:
            rels["text_polarity"] = rels["evidence_text"].map(
                lambda t: round(vader.polarity_scores(t)["compound"], 4) if isinstance(t, str) and t else float("nan")
            )

    rels = rels.sort_values("confidence", ascending=False)
    if len(rels) > max_relations:
        rels = rels.head(max_relations)
    rels = rels.reset_index(drop=True)
    rels["rel_id"] = range(1, len(rels) + 1)
    return rels
