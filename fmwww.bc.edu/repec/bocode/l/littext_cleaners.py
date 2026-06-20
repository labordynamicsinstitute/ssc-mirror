"""littext_cleaners: per-texttype text-cleaning regimes.

Design note:

  abstract    Emerald section headers; copyright tails; arXiv tags.
  fulltext    All of the above; LaTeX residues; reference-section
              detection; figure/table captions.
  transcript  Speaker labels (SPEAKER:, Q:, A:, all-caps name colon);
              timestamp markers ([HH:MM:SS], (MM:SS)).
  review      HTML residues; rating-row noise ("5 out of 5 stars");
              "Verified Purchase" labels.
  comment     URL stripping; emoticons left intact (they carry
              sentiment and may be substantive content).
  other       Minimal: whitespace collapse and control-character
              removal only.

The cleaners are deliberately conservative: each pattern is anchored
or bounded so it cannot accidentally consume legitimate text. 
"""

from __future__ import annotations

import re
from typing import Callable, Dict


# -------------------------------------------------------------------- #
# Texttype taxonomy. Used by the dispatcher and exported for
# validation by callers (the Stata-side analysis command).
# -------------------------------------------------------------------- #

TEXTTYPE_NAMES = (
    "abstract",
    "fulltext",
    "transcript",
    "review",
    "comment",
    "other",
)


# Defaults for Table 1.
# Each entry maps texttype -> (default_unit, default_min_text_len).
# The Stata layer honors these defaults when the corresponding
# option is not explicitly passed.
TEXTTYPE_DEFAULTS: Dict[str, dict] = {
    "abstract":   {"unit": "sentence",  "mintextlen": 50},
    "fulltext":   {"unit": "paragraph", "mintextlen": 500},
    "transcript": {"unit": "sentence",  "mintextlen": 30},
    "review":     {"unit": "sentence",  "mintextlen": 20},
    "comment":    {"unit": "sentence",  "mintextlen": 10},
    "other":      {"unit": "sentence",  "mintextlen": 50},
}


# Expected median character-length windows from the design note's
# Table 2. The format is (warn_below, warn_above);
# either bound can be None to disable the corresponding direction.
TEXTTYPE_LENGTH_WINDOWS: Dict[str, tuple] = {
    "abstract":   (200, 10000),
    "fulltext":   (3000, 200_000),
    "transcript": (1000, 200_000),
    "review":     (30, 3000),
    "comment":    (10, 1000),
    "other":      (None, None),
}


# -------------------------------------------------------------------- #
# Shared regex patterns (used by multiple cleaners)
# -------------------------------------------------------------------- #

_WHITESPACE_RUN = re.compile(r"\s+")

_CONTROL_CHARS = re.compile(r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]")


def _finalise(s: str) -> str:
    """Whitespace collapse + strip control characters. Final step in
    every cleaner."""
    s = _CONTROL_CHARS.sub(" ", s)
    s = _WHITESPACE_RUN.sub(" ", s).strip()
    return s


# -------------------------------------------------------------------- #
# Cleaner: abstract (preserves _clean_text behavior)
# -------------------------------------------------------------------- #

_EMERALD_SECTIONS = re.compile(
    r"\b(Purpose|Design/methodology/approach|Methodology|Methodology/approach|"
    r"Findings|Originality/value|Originality|Research limitations/implications|"
    r"Research limitations|Practical implications|Social implications|"
    r"Theoretical implications|Managerial implications|Implications|"
    r"Limitations|Conclusion|Conclusions|Contribution|Background|Aim|Aims|"
    r"Objective|Objectives|Approach|Results|Discussion)"
    r"\s*[:\-\u2013\u2014]\s*",
    flags=re.IGNORECASE,
)

_COPYRIGHT_TAIL = re.compile(
    r"(?:\u00a9|\(c\)|Copyright\s|All rights reserved|"
    r"Published by\b|Elsevier B\.V\.|Elsevier Ltd\.?|Emerald Publishing|"
    r"Informa UK|Taylor\s*&\s*Francis|Wiley[- ]Blackwell|Springer Nature|"
    r"SAGE Publications).*$",
    flags=re.IGNORECASE | re.DOTALL,
)

# arXiv-style abstract tags (e.g. "Comments: 12 pages, 3 figures.")
_ARXIV_COMMENT_TAG = re.compile(
    r"^\s*(?:Comments?|Subjects?|MSC class|Journal-ref|DOI|Cite as|ACM-class|Report-no)\s*:.*$",
    flags=re.IGNORECASE | re.MULTILINE,
)


def _clean_abstract(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    s = _COPYRIGHT_TAIL.sub("", s)
    s = _EMERALD_SECTIONS.sub("", s)
    s = _ARXIV_COMMENT_TAG.sub("", s)
    return _finalise(s)


# -------------------------------------------------------------------- #
# Cleaner: fulltext
# -------------------------------------------------------------------- #

# LaTeX command patterns. 
_LATEX_CITATIONS = re.compile(
    r"\\(?:cite|citep|citet|citeauthor|citeyear|ref|eqref|label|footnote|footnotemark)"
    r"(?:\[[^\]]*\])?(?:\{[^{}]*\})+",
    flags=re.IGNORECASE,
)

_LATEX_ENVIRONMENT_INLINE = re.compile(
    r"\\(?:begin|end)\{[a-z*]+\}",
    flags=re.IGNORECASE,
)

_LATEX_COMMAND_GENERIC = re.compile(
    r"\\[a-zA-Z]+\*?(?:\[[^\]]*\])?(?:\{[^{}]*\})?",
)

# References section: from a line containing only "References" or
# "Bibliography" (with optional surrounding whitespace) to end of string.
_REFS_SECTION = re.compile(
    r"^\s*(References|Bibliography|Works Cited)\s*$.*",
    flags=re.IGNORECASE | re.MULTILINE | re.DOTALL,
)

# Figure / table captions. Match a line starting "Figure N." or
# "Table N." followed by caption text; the conservative version
# matches only the caption opener line, not the following description.
_FIGURE_TABLE_CAPTION = re.compile(
    r"^\s*(?:Figure|Fig\.|Table|Tab\.)\s+\d+[\.\:].*$",
    flags=re.IGNORECASE | re.MULTILINE,
)

_NUMERIC_CITATION = re.compile(r"\[\s*\d+(?:\s*[-,]\s*\d+)*\s*\]")


def _clean_fulltext(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    # Apply abstract-level cleanings first
    s = _COPYRIGHT_TAIL.sub("", s)
    s = _EMERALD_SECTIONS.sub("", s)
    s = _ARXIV_COMMENT_TAG.sub("", s)
    # Then fulltext-specific patterns
    s = _REFS_SECTION.sub("", s)
    s = _FIGURE_TABLE_CAPTION.sub("", s)
    s = _LATEX_CITATIONS.sub("", s)
    s = _LATEX_ENVIRONMENT_INLINE.sub("", s)
    s = _LATEX_COMMAND_GENERIC.sub("", s)
    s = _NUMERIC_CITATION.sub("", s)
    return _finalise(s)


# -------------------------------------------------------------------- #
# Cleaner: transcript
# -------------------------------------------------------------------- #

# Timestamp markers. Three common forms:
#   [00:23:15]   square-bracketed HH:MM:SS or MM:SS
#   (15:42)      parenthesised MM:SS
#   00:23:15     bare HH:MM:SS at line start
_TIMESTAMP_BRACKET = re.compile(r"[\[\(]\s*\d{1,2}:\d{2}(?::\d{2})?\s*[\]\)]")
_TIMESTAMP_LINESTART = re.compile(
    r"^\s*\d{1,2}:\d{2}(?::\d{2})?\s*[:\-]?\s*",
    flags=re.MULTILINE,
)

# Speaker labels. Three forms:
#   SPEAKER:        all-caps word followed by colon
#   Q:  / A:        question / answer markers
#   John Smith:     proper-name-colon at line start (conservative: two
#                    capitalised words followed by a colon)
_SPEAKER_ALLCAPS = re.compile(
    r"^\s*[A-Z][A-Z0-9_\-]{1,30}(?:\s+[A-Z][A-Z0-9_\-]{1,30}){0,3}\s*:\s*",
    flags=re.MULTILINE,
)
_SPEAKER_QA = re.compile(r"^\s*[QA]\s*:\s*", flags=re.MULTILINE)
_SPEAKER_PROPER_NAME = re.compile(
    r"^\s*[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2}\s*:\s+",
    flags=re.MULTILINE,
)


def _clean_transcript(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    s = _TIMESTAMP_BRACKET.sub(" ", s)
    s = _TIMESTAMP_LINESTART.sub("", s)
    s = _SPEAKER_ALLCAPS.sub("", s)
    s = _SPEAKER_QA.sub("", s)
    s = _SPEAKER_PROPER_NAME.sub("", s)
    return _finalise(s)


# -------------------------------------------------------------------- #
# Cleaner: review
# -------------------------------------------------------------------- #

# HTML tags. Match opening, closing, and self-closing tags.
_HTML_TAG = re.compile(r"<[/]?[a-zA-Z][a-zA-Z0-9\-]*(?:\s[^>]*)?\/?>")
# HTML entities &amp; &lt; etc.
_HTML_ENTITY = re.compile(r"&(?:[a-zA-Z]+|#\d+|#x[0-9a-fA-F]+);")


_STAR_RATING = re.compile(
    r"\b\d(?:\.\d)?\s+(?:out of|/)\s+\d\s+stars?\b",
    flags=re.IGNORECASE,
)
_RATING_LABEL = re.compile(
    r"\b(?:Verified Purchase|Vine Customer Review|Top Contributor|"
    r"Hall of Fame Reviewer|Recommended|Not Recommended)\b",
    flags=re.IGNORECASE,
)
_HELPFUL_VOTES = re.compile(
    r"\b\d+\s+(?:of\s+\d+\s+)?(?:people|users)\s+found\s+this\s+(?:review\s+)?helpful\b",
    flags=re.IGNORECASE,
)


def _clean_review(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    s = _HTML_TAG.sub(" ", s)
    s = _HTML_ENTITY.sub(" ", s)
    s = _STAR_RATING.sub(" ", s)
    s = _RATING_LABEL.sub(" ", s)
    s = _HELPFUL_VOTES.sub(" ", s)
    return _finalise(s)


# -------------------------------------------------------------------- #
# Cleaner: comment
# -------------------------------------------------------------------- #

_URL_HTTP = re.compile(
    r"https?://\S+",
    flags=re.IGNORECASE,
)
_URL_WWW = re.compile(
    r"\bwww\.[a-zA-Z0-9\-]+(?:\.[a-zA-Z0-9\-]+)+(?:/\S*)?",
    flags=re.IGNORECASE,
)
# @mentions and #hashtags are NOT stripped: they may carry substantive
# content (which user / which topic is being discussed).


def _clean_comment(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    s = _URL_HTTP.sub(" ", s)
    s = _URL_WWW.sub(" ", s)
    return _finalise(s)


# -------------------------------------------------------------------- #
# Cleaner: other (minimal)
# -------------------------------------------------------------------- #

def _clean_other(s: str) -> str:
    if not isinstance(s, str) or not s:
        return ""
    return _finalise(s)


# -------------------------------------------------------------------- #
# Dispatcher
# -------------------------------------------------------------------- #

_DISPATCH: Dict[str, Callable[[str], str]] = {
    "abstract":   _clean_abstract,
    "fulltext":   _clean_fulltext,
    "transcript": _clean_transcript,
    "review":     _clean_review,
    "comment":    _clean_comment,
    "other":      _clean_other,
}


def clean_for_texttype(s: str, texttype: str) -> str:
    """Apply the cleaning regime appropriate for the declared texttype.

    Unknown texttype values fall through to _clean_other (minimal
    cleaning) with no exception raised; the validation responsibility
    sits with the caller. The Stata-side analyze command validates the
    texttype against TEXTTYPE_NAMES before invoking the pipeline.
    """
    fn = _DISPATCH.get((texttype or "").lower(), _clean_other)
    return fn(s)


def get_texttype_defaults(texttype: str) -> dict:
    """Return (unit, mintextlen) defaults for the given texttype.

    Returns the 'other' defaults if the texttype is unknown, so the
    caller never has to handle a missing-key exception.
    """
    return TEXTTYPE_DEFAULTS.get(
        (texttype or "").lower(),
        TEXTTYPE_DEFAULTS["other"],
    )


def get_texttype_length_window(texttype: str) -> tuple:
    """Return (warn_below, warn_above) char-length window for the
    given texttype. Either bound may be None (no warning in that
    direction). Returns (None, None) if texttype is unknown.
    """
    return TEXTTYPE_LENGTH_WINDOWS.get(
        (texttype or "").lower(),
        (None, None),
    )
