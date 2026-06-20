{smcl}
{* *! version 1.0  17june2026}{...}
{title:Title}

{phang}
{bf:littext} {hline 2} Automated construct discovery and relationship
inference from an academic text


{title:Syntax}

{p 8 16 2}
{bf:littext analyze} {cmd:,} {opt t:ext(varname)} [ {it:options} ]

{p 8 16 2}
{bf:littext graph} {cmd:,} [ {opt t:ype(string)} {opt top(#)}
{opt out:dir(string)} {opt we:ighted} {opt lev:el(string)}
{opt format(string)} {opt emb:ed(string)} {opt sav:ing(string)} {opt rep:lace} ]

{p 8 16 2}
{bf:littext export} {cmd:,} {opt out:dir(string)} [ {opt n:ame(string)}
{opt format(string)} {opt minc:onf(#)} {opt t:ype(string)} {opt top(#)}
{opt col:umns(string)} ]

{p 8 16 2}
{bf:littext example} [ {cmd:,} {opt clear} ]

{p 8 16 2}
{bf:littext install} [ {cmd:,} {opt q:uiet} {opt v:erbose} ]

{title:Description}

{pstd}
{bf:littext} extracts candidate construct relationships from an unstructured
corpus of academic text (titles, abstracts, full texts) or other research
text such as interview transcripts, consumer reviews, and social media
comments. It is intended for the exploratory researcher who has assembled a
large corpus and wants to generate candidate relationships of the form
"X is associated with Y", "X moderates the effect of Z on Y", etc., that
can then be hand-curated into a formal, systematic literature review coding
scheme.

{pstd}
The pipeline is: text-kind-appropriate cleaning; spaCy noun-chunk
extraction; sentence-transformer embedding of candidate constructs;
HDBSCAN clustering into synonym groups; lexical construct-hierarchy
detection; co-occurrence-based relation candidacy with normalized
PMI scoring; dependency-pattern matching for relationship valence.

{pstd}
Results are returned in three Stata frames left in memory:

{p 8 12 2}{bf:lt_constructs}  -  one row per extracted construct{p_end}
{p 8 12 2}{bf:lt_relations}   -  one row per candidate relationship{p_end}
{p 8 12 2}{bf:lt_diag}        -  one row per source document with diagnostics{p_end}

{pstd}
After {bf:littext analyze} returns, a user remains in the frame it called
from; the results are in the named frames {bf:lt_constructs},
{bf:lt_relations}, and {bf:lt_diag}, queried with a frame prefix, e.g.
{cmd:frame lt_relations: list source target relation_type confidence}.
Files on disk are produced only if you pass {opt sav:ing()}.

{title:Options for {cmd:littext analyze}}

{phang}
{opt t:ext(varname)} (required) - the variable in the current dataset that
holds the document text. May be a {bf:str#} or {bf:strL} variable. Must be
a string variable; numeric variables are rejected with an error.

{phang}
{opt i:d(varname)} - a per-document identifier. If omitted, {bf:_n} is used.

{phang}
{opt y:ear(varname)} - publication year (numeric). Used for the trend graph
and stored in {bf:lt_diag}.

{phang}
{opt j:ournal(varname)} - outlet name (string). Stored in {bf:lt_diag} for
comparative analysis.

{phang}
{opt textt:ype(string)} - declares the kind of text in the corpus. One of:

{p 8 12 2}{bf:abstract}    - academic abstracts (default; Emerald and copyright cleaners){p_end}
{p 8 12 2}{bf:fulltext}    - full papers (above plus LaTeX, references, captions){p_end}
{p 8 12 2}{bf:transcript}  - interview / focus group transcripts (speaker labels, timestamps){p_end}
{p 8 12 2}{bf:review}      - consumer reviews (HTML, ratings, verified-purchase labels){p_end}
{p 8 12 2}{bf:comment}     - social-media comments (URLs; emoticons preserved){p_end}
{p 8 12 2}{bf:other}       - minimal cleaning only (whitespace, control chars){p_end}

{pstd}
If {opt textt:ype()} is not declared, the package defaults to
{bf:abstract} and emits a note indicating that this default was applied.
The declaration drives the cleaning regime, the default {opt u:nit()},
and the default {opt mint:extlen()}. A post-clean median-length sanity
check warns when the corpus length is outside the typical window for
the declared texttype, which most often indicates a misdeclared
{opt t:ext()} variable.

{phang}
{opt u:nit(string)} - unit of analysis for relationship candidacy. One of
{bf:sentence}, {bf:abstract}, {bf:paragraph}. If not specified, defaults
from {opt textt:ype()}: sentence for abstract/transcript/review/comment/other,
paragraph for fulltext.

{phang}
{opt emb:edmodel(string)} - name of the sentence-transformers model used for
construct embeddings.

{phang}
{opt minf:req(#)} - minimum document frequency for a candidate construct to
be retained. Default: {bf:1} for corpora with fewer than 50 documents,
{bf:2} otherwise. Resolved value and rationale are printed at run time.

{phang}
{opt maxr:elations(#)} - cap on the number of candidate relationships
written to {bf:lt_relations} (highest-confidence first). Default {bf:100000}.

{phang}
{opt mint:extlen(#)} - minimum text length in characters. Rows whose
{opt t:ext()} value is shorter than this threshold are dropped before the
pipeline runs. If not specified, defaults from {opt textt:ype()}: 50 for
abstract/other, 500 for fulltext, 30 for transcript, 20 for review,
10 for comment. Pass {opt keepe:mpty} to disable row-dropping entirely.

{phang}
{opt keepe:mpty} - retain all rows including empty, whitespace-only, and
below-threshold ones. The default behavior is to drop these with a logged
count. Use this when the corpus is being analyzed for a purpose that
requires preserving the input row count.

{phang}
{opt addsentiment} - additionally compute VADER affective polarity on each
evidence sentence and store it in {bf:text_polarity}. Note: this is
{it:affective sentiment} of the text, NOT {it:relationship valence}.
Relationship valence is always computed and stored in {bf:relation_type}.

{phang}
{opt q:uiet} - suppress progress output.

{phang}
{opt sav:ing(string)} - if specified, the three frames are also saved as
{it:stub}_constructs.dta, {it:stub}_relations.dta, {it:stub}_diag.dta.

{phang}
{opt rep:lace} - allow overwriting existing files when {opt sav:ing()} is used.

{title:Options for {cmd:littext graph}}

{phang}
{opt t:ype(string)} - figure type. One of:

{p 8 12 2}{bf:frequency}     - bar chart of top-k constructs (Stata-native){p_end}
{p 8 12 2}{bf:distribution}  - distribution of relation types (Stata-native){p_end}
{p 8 12 2}{bf:trend}         - extraction yield over years (Stata-native){p_end}
{p 8 12 2}{bf:confidence}    - histogram of confidence scores (Stata-native){p_end}
{p 8 12 2}{bf:extraction}    - distribution by extraction method (Stata-native){p_end}
{p 8 12 2}{bf:map}           - UMAP concept map (matplotlib; default){p_end}
{p 8 12 2}{bf:network}       - relationship network (matplotlib){p_end}
{p 8 12 2}{bf:dendrogram}    - construct-cluster dendrogram (matplotlib){p_end}
{p 8 12 2}{bf:cooccurrence}  - pairwise NPMI heatmap of top-k constructs (matplotlib){p_end}
{p 8 12 2}{bf:roles}         - construct x relation-type heatmap (matplotlib){p_end}

{phang}
{opt top(#)} - number of top constructs or relationships to display.
Default {bf:20}. For heatmaps, controls the matrix dimensions.

{phang}
{opt we:ighted} - for {bf:type(network)} only: color edges continuously by
confidence (viridis) rather than discretely by relation type. Useful when
edge strength matters more than syntactic type.

{phang}
{opt lev:el(string)} - hierarchy specificity for construct-vocabulary graph
types. Accepts {bf:leaf} (default; constructs at maximum specificity),
{bf:root} (each construct replaced by its hierarchy root), or a
non-negative integer N (collapse to depth N). Honoured by
{bf:type(frequency)} and by the matplotlib {bf:type(map)}
and {bf:type(network)} renderers. In {bf:map} a rolled construct is drawn
at the frequency-weighted centroid of its children. In {bf:network} edges
are aggregated within each relation type but never across types: a
positive and a negative edge between the same rolled pair stay distinct.
Other Stata-native types, the heatmaps ({bf:cooccurrence}, {bf:roles}),
and {bf:dendrogram} (whose tree is built from cluster distances, not the
construct hierarchy) ignore {opt level()} and emit a one-line note. The
hierarchy is computed by the lexical right-substring rule plus the
hyphenated-prefix rule described in the Notes section.

{phang}
{opt out:dir(string)} - directory where figure files will be written.
REQUIRED. Pass an absolute path (e.g. {bf:"D:\projects\figures"}). If
omitted, {cmd:littext graph} stops with an error rather than guessing a
location. A relative path is accepted but resolved against the current
working directory ({bf:c(pwd)}) with a warning. The resolved absolute
path is printed on every save.

{phang}
{opt sav:ing(string)} - output file stub for matplotlib figures (PNG and PDF
are written). For Stata-native graphs, the file is saved as PNG via
{cmd:graph export}.

{phang}
{opt format(string)} - output format for the matplotlib figure types
({bf:map}, {bf:network}, {bf:dendrogram}, {bf:cooccurrence}, {bf:roles}).
Accepts {bf:static} (default; PNG and PDF via matplotlib), {bf:html}
(interactive Plotly HTML), or {bf:both}. Ignored with a note for
Stata-native types, which are always static.

{phang}
{opt emb:ed(string)} - how plotly.js is embedded in {bf:format(html)}
output. {bf:selfcontained} (default) writes a standalone file (~3.5 MB)
that opens offline on any machine; {bf:cdn} writes a small file that
loads plotly.js from a content-delivery network and therefore needs an
internet connection to render.

{title:Options for {cmd:littext export}}

{pstd}
{cmd:littext export} writes the candidate relationships from the most recent
{cmd:littext analyze} (the {bf:lt_relations} frame) as a hypothesis register
for hand-curation: a clean candidate table, sorted strongest-first, with no
curation columns added (the analyst adds their own). Run {cmd:littext
analyze} first.

{phang}
{opt out:dir(string)} - REQUIRED. Absolute path to the directory where the
register is written. A relative path is resolved against {bf:c(pwd)} with a
warning.

{phang}
{opt n:ame(string)} - file-name stub for the register (default
{bf:littext_register}). The extension is added per {opt format()}.

{phang}
{opt format(string)} - output format: {bf:csv} (default), {bf:xlsx}, or
{bf:both}. CSV is written with full quoting, so evidence spans containing
commas or quotes survive intact.

{phang}
{opt minc:onf(#)} - keep only candidates with {bf:confidence} at or above
this value (default: keep all).

{phang}
{opt t:ype(string)} - restrict to one or more relation types, given as a
space- or comma-separated list (e.g. {bf:type(pos_assoc neg_assoc)}).

{phang}
{opt top(#)} - keep only the top {bf:#} candidates after sorting by
descending confidence (default: keep all).

{phang}
{opt col:umns(string)} - space-separated list of {bf:lt_relations} columns
to export. Unknown columns are skipped with a note.

{title:Stata frames produced}

{pstd}
{bf:lt_constructs}: construct_id, surface_form, canonical_form, cluster_id,
freq_doc, freq_total, parent_canonical, canonical_root, hierarchy_depth,
is_root.

{pstd}
{bf:lt_relations}: rel_id, doc_id, unit_id, source, target,
source_construct_id, target_construct_id, relation_type, confidence,
extraction_method, evidence_text, text_polarity.

{pstd}
{bf:lt_diag}: doc_id, year, journal, n_constructs_extracted,
n_relations_extracted.

{title:relation_type vocabulary}

{phang}
{bf:pos_assoc}  - positive association (X increases/enhances/predicts Y){p_end}
{phang}
{bf:neg_assoc}  - negative association (X reduces/attenuates Y){p_end}
{phang}
{bf:moderates}  - X moderates the relationship between two others{p_end}
{phang}
{bf:mediates}   - X mediates the effect of one construct on another{p_end}
{phang}
{bf:causes}     - X causes / leads to Y{p_end}
{phang}
{bf:assoc}      - non-directional or unclassified co-occurrence{p_end}

{title:Notes}

{pstd}
{bf:row-drop behavior.} By default, {cmd:littext analyze} drops rows
where the {opt t:ext()} variable is missing or whitespace-only, rows where
a user-supplied {opt i:d()} variable is missing, and rows whose text is
shorter than {opt mint:extlen()} characters. A summary of the drops is
printed (suppressed under {opt q:uiet}). A warning is emitted if more
than 25% of input rows are dropped, which most often indicates that the
{opt t:ext()} variable points at the wrong column.

{pstd}
{bf:text-kind declaration.} The {opt textt:ype()} option drives
three downstream defaults: which cleaning regime is applied to the raw
text; the default segmentation {opt u:nit()}; and the default
{opt mint:extlen()}. Each derived default is overridable by passing the
corresponding option explicitly. The resolved values and their sources
("user-specified" vs "texttype default") are printed at run time.
A post-clean median-length sanity check warns when the corpus length
falls outside the typical window for the declared texttype.

{pstd}
{bf:construct hierarchy.} Four new columns are added to
{bf:lt_constructs}: {bf:parent_canonical} (the canonical form of the
immediate IS-A parent, or empty if the construct is a root),
{bf:canonical_root} (the topmost ancestor; equals {bf:canonical_form}
for roots), {bf:hierarchy_depth} (zero for roots, one for direct
children), and {bf:is_root} (1 if root, 0 otherwise). The hierarchy is
detected by a lexical right-substring rule with a frequency prior,
supplemented by a hyphenated-prefix rule that admits constructs of the
form {it:X-based Parent}, {it:X-driven Parent}, {it:X-led Parent}, and
{it:X-oriented Parent} as children of {it:Parent} regardless of the
frequency prior. The rule is English-specific and is silent on
conceptually-subsumed but lexically-distinct relations (e.g., it does
not link {it:brand reputation} to {it:brand equity} because they
share no right substring).

{pstd}
{bf:Example hierarchies the rule recovers.} For instance, if a corpus contains
{it:brand equity} and any of {it:consumer-based brand equity},
{it:financial-based brand equity}, {it:online brand equity}, or
{it:employee-based brand equity}, the rule places each subtype as a
depth-1 child of {it:brand equity}. Query the hierarchy with:

{phang}{cmd:. frame lt_constructs: list canonical_form parent_canonical canonical_root, sepby(canonical_root)}{p_end}

{pstd}
or roll up at the graph level with:

{phang}{cmd:. littext graph, type(frequency) level(root)}{p_end}

{title:Examples}

{pstd}Load the bundled synthetic RBV corpus (300 abstracts) and analyze it:{p_end}

{phang}{cmd:. littext example, clear}{p_end}
{phang}{cmd:. littext analyze, text(abstract) id(article_id) year(year) journal(journal) texttype(abstract)}{p_end}
{phang}{cmd:. frame lt_relations: list source target relation_type confidence in 1/10}{p_end}
{phang}{cmd:. frame lt_relations: tab relation_type}{p_end}
{phang}{cmd:. littext graph, type(map) outdir("D:/figs")}{p_end}
{phang}{cmd:. littext graph, type(network) top(25)}{p_end}
{phang}{cmd:. littext graph, type(network) level(root)}{p_end}
{phang}{cmd:. littext graph, type(map) level(1)}{p_end}
{phang}{cmd:. littext graph, type(network) outdir("D:/figs") format(html)}{p_end}
{phang}{cmd:. littext graph, type(map) outdir("D:/figs") format(both)}{p_end}
{phang}{cmd:. littext export, outdir("D:/register") format(both)}{p_end}
{phang}{cmd:. littext export, outdir("D:/register") minconf(0.7) type(pos_assoc neg_assoc) top(200)}{p_end}
{phang}{cmd:. littext graph, type(frequency) level(root)}{p_end}

{pstd}For a corpus of interview transcripts:{p_end}

{phang}{cmd:. use my_transcripts.dta, clear}{p_end}
{phang}{cmd:. littext analyze, text(transcript) id(case_id) texttype(transcript)}{p_end}

{pstd}For a corpus of consumer reviews:{p_end}

{phang}{cmd:. use product_reviews.dta, clear}{p_end}
{phang}{cmd:. littext analyze, text(review_text) id(review_id) texttype(review)}{p_end}

{pstd}For full-text academic papers (LaTeX or PDF-extracted text):{p_end}

{phang}{cmd:. use my_fulltexts.dta, clear}{p_end}
{phang}{cmd:. littext analyze, text(body) id(paper_id) texttype(fulltext)}{p_end}

{title:Sentiment analysis: a note}

{pstd}
{bf:littext} draws a clear line between two distinct constructs that are often
conflated in social sciences/marketing/management applications:

{phang}
1. {it:Relationship valence} is the sign of the directional relationship
between two constructs (X positively/negatively related to Y). This is always
computed and stored in {bf:relation_type}. It is essential to the purpose of
the package; a hypothesis register that cannot distinguish "X increases Y"
from "X reduces Y" is not a hypothesis register.{p_end}

{phang}
2. {it:Affective sentiment} is the emotional polarity of a piece of text, in
the sense of VADER, LIWC, or the NRC Emotion Lexicon. This is meaningful for
consumer-text corpora (reviews, tweets) but largely uninformative for academic
abstracts. {bf:littext} computes it only on request via {opt addsentiment} and
stores it in {bf:text_polarity}.{p_end}

{pstd}
Users should not treat {bf:text_polarity} as a measure of relationship sign.

{title:Requirements}

{pstd}
Stata 19 or higher with Python integration configured. Python 3.14
recommended on Windows; spaCy on Python requires {bf:blis 1.3.3} or
higher. Required Python packages: spacy, sentence-transformers, hdbscan,
scikit-learn, umap-learn, matplotlib, networkx, plotly, pandas, numpy. The spaCy
model {bf:en_core_web_sm} must be downloaded once via
{cmd:python -m spacy download en_core_web_sm}.

{pstd}
On its first run, {bf:littext analyze} downloads the default
sentence-transformer embedding model ({bf:all-MiniLM-L6-v2}, about
90 MB) from the Hugging Face Hub. Inside Stata's Python bridge this
download prints no progress, so a first run on a new machine can
appear to hang during the pipeline stage. {bf:littext install} reports
whether the model is cached and, when it is not, prints the exact
command to fetch it once at the command prompt, where progress is
visible; later runs then load it from the local cache with no network.

{title:Limitations}

{pstd}
{bf:littext} uses noun-chunk extraction rather than a domain-trained NER
model, and co-occurrence plus dependency-pattern matching rather than a
trained relation extractor. It is therefore best understood as a
candidate-generation tool whose output requires manual curation before
being treated as a coding scheme. Quantitative precision/recall figures
should not be reported against the bundled synthetic corpus.

{pstd}
The construct-hierarchy detector and the {opt textt:ype()} cleaning
regimes are English-specific. The hierarchy rule does not recover
conceptual subsumption that lacks a lexical signal.

{title:References}

{pstd}
Bouma, G. (2009). Normalized (pointwise) mutual information in collocation
extraction. In {it:Proceedings of GSCL, 30}, 31-40.

{pstd}
Hearst, M. A. (1992). Automatic acquisition of hyponyms from large text
corpora. In {it:Proceedings of COLING-92}, 539-545.

{pstd}
Hutto, C. J., & Gilbert, E. (2014). VADER: A parsimonious rule-based model
for sentiment analysis of social media text. In {it:Proceedings of ICWSM}, 8(1), 216-225.

{pstd}
Li, J., Larsen, K. R., & Abbasi, A. (2020). TheoryOn: A design framework and
system for unlocking behavioral knowledge through ontology learning. {it:MIS Quarterly}, 44(4), 1733-1772.


{title:Aliases}

{pstd}
{cmd:litt} is provided as a short-form alias for {cmd:littext}. It
forwards every argument and propagates returned scalars and macros.


{title:Author}

{pstd}
Nebojsa S. Davcik{break}
EM Normandie Business School, Oxford, UK{break}
ORCID: 0000-0003-1041-8788{break}
{browse "https://orcid.org/0000-0003-1041-8788":https://orcid.org/0000-0003-1041-8788}{break}
Email: {browse "mailto:davcik@live.com":davcik@live.com}


{title:Citation}

{pstd}
When citing {cmd:littext} in academic work, please use:

{phang2}
Davcik, N. S. 2026. {it:LITTEXT: Stata module for automated construct discovery and relationship inference from academic text.}
Available at: {browse "https://github.com/Davcik/littext":https://github.com/Davcik/littext}


{title: License}

{pstd}
{cmd:littext} is free software released under the
{browse "https://www.gnu.org/licenses/gpl-3.0.html":GNU General Public License version 3 or later} (GPL-3.0-or-later).
You may redistribute and modify it under the terms of that license;
modified versions and larger works that incorporate {cmd:littext}
must also be released under GPL-3 or later. See the LICENSE file in
the repository root for the full license text.

{pstd}
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


{title:Also see}

{phang}Short-form alias: {helpb litt}{p_end}

