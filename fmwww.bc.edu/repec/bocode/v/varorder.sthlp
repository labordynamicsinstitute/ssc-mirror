{smcl}
{* *! version 1.0.0 21aug2026}{...}
{vieweralsosee "order" "help order"}{...}
{vieweralsosee "notes" "help notes"}{...}

{title:Title}

{phang}
{bf:varorder} {hline 2} Automated detection of temporal structure and ordering of variables
using semantic information in variable names, labels, variable notes, and attached value labels{p_end}


{title:Description}

{pstd}
This module automatically examines the current wide-format dataset, identifies variables with
sufficiently clear temporal structure using semantic information from variable names, variable
labels, variable notes, attached value-label metadata, or agreement across these sources, and places eligible variables into a
defensible temporal order. When the available information is ambiguous or conflicting,
{cmd:varorder} reports the issue rather than guessing.{p_end}


{title:Why use varorder?}

{pstd}
Stata's native {cmd:order} command is effective when the user already knows
exactly which variables should move and where they should go.  In large
wide-format datasets, however, the difficult part may be identifying which
variables belong to the same repeated-measure structure and determining their
correct temporal sequence.  {cmd:varorder} is designed to reduce the manual
work required to locate scattered repeated-measure variables, determine their
temporal sequence, and reorganize them safely.{p_end}


{title:Key features}

{p 4 6 2}• {bf:Semantic detection from four sources.} {cmd:varorder} uses semantic
information in variable names, variable labels, variable notes, and attached value-label metadata
to identify variables that belong together and determine whether they contain a defensible
temporal structure. Value labels provide value-domain evidence; their category text is not treated
as a variable's measurement occasion.{p_end}

{p 4 6 2}• {bf:Temporal and hierarchical ordering.} The command recognizes high-confidence
temporal patterns such as {cmd:T1/T2/T3}, {cmd:Wave 1/2/3}, {cmd:Visit 1/2/3}, explicit calendar
years, and sequences such as {cmd:pre < mid < post} and
{cmd:baseline < during treatment < follow-up}. When multiple ordered temporal components are
supported by the semantic information, {cmd:varorder} can use hierarchical keys such as
{cmd:year > quarter}, {cmd:grade > term}, or {cmd:day > within-day period}. Bare numeric suffixes are
not treated as temporal unless the available semantics support that interpretation.{p_end}

{p 4 6 2}• {bf:Metadata normalization across semantic sources.} Formatting inconsistencies
such as capitalization, separators, compact forms, and leading zeros may occur in any metadata
source. {cmd:varorder} normalizes such differences internally for detection while preserving the
original variable names, labels, notes, and attached value labels and retaining each source separately so that agreement
and conflict remain detectable.{p_end}

{p 4 6 2}• {bf:Dataset safety.} {cmd:varorder} acts only when temporal evidence is sufficiently
clear. Related but non-temporal variables, semantically insufficient numeric sequences, ambiguous
hierarchical structures, normalized-key collisions, and metadata conflicts are reported for review
rather than guessed into an order. The command is preview-first, proposes one complete ordering
plan, asks for at most one confirmation, and changes only the physical order of variables.{p_end}


{title:Syntax}

{p 4 22 2}{cmd:varorder}{p_end}
{p 4 22 2}{cmd:varorder, undo}{p_end}


{title:Practical applications}

{title:Example 1. Use the module to automatically detect temporal families and order their variables in the provided example dataset}

{p 4 4 2}{cmd:. use varorder_example_data.dta, clear}{p_end}
{p 4 4 2}{cmd:. varorder}{p_end}

{p 8 8 2}{txt:varorder preview summary}{p_end}

{p 8 8 2}{txt:Examined: 106 variables}{p_end}
{p 8 8 2}{txt:Confirmed temporal structures: 19}{p_end}
{p 8 8 2}{txt:Variables to be reordered: 101}{p_end}
{p 8 8 2}{txt:Maximum displacement: 90 columns}{p_end}

{p 8 8 2}{txt:Issues requiring review:}{p_end}
{p 10 10 2}{txt:Gap warnings but ordering allowed (1): mobility}{p_end}
{p 10 10 2}{txt:Related or unverified - no action (6): eng, exercise, lab, mood, promotion_status, reading}{p_end}
{p 10 10 2}{txt:Ambiguous or conflicting - no action (5): focus, memory, pain, score, survey}{p_end}

{p 8 8 2}{txt:All eligible structures will be included in the proposed ordering.}
{txt:Structures marked as no action will remain unchanged.}{p_end}

{p 8 8 2}{txt: }{p_end}
{p 8 8 2}{txt:Press Enter to apply the proposed ordering.}{p_end}

{p 8 8 2}{txt:Variable order updated.}{p_end}


{title:Example 2. Undo the most recent ordering}

{pstd}
After a successful mutating {cmd:varorder}, restore the immediately preceding
physical variable order with:{p_end}

{p 4 4 2}{cmd:. varorder, undo}{p_end}


{title:Stored results}

{pstd}
After {cmd:varorder}, the command stores the following in {cmd:r()}:{p_end}

{synoptset 34 tabbed}{...}
{synopt:{cmd:r(changed)}}1 if physical variable order changed; 0 otherwise{p_end}
{synopt:{cmd:r(k)}}number of variables examined{p_end}
{synopt:{cmd:r(n_families_detected)}}number of candidate structures detected{p_end}
{synopt:{cmd:r(n_families_confirmed)}}number of confirmed temporal structures{p_end}
{synopt:{cmd:r(n_families_related)}}number of related or temporally unverified structures{p_end}
{synopt:{cmd:r(n_families_ambiguous)}}number of ambiguous or conflicting structures{p_end}
{synopt:{cmd:r(n_families_changed)}}number of confirmed structures proposed for reorganization{p_end}
{synopt:{cmd:r(n_families_suppressed)}}sum of related and ambiguous structures{p_end}
{synopt:{cmd:r(n_moved)}}number of variables whose physical positions changed{p_end}
{synopt:{cmd:r(max_displacement)}}largest position displacement among moved variables{p_end}
{synopt:{cmd:r(order_lists_returned)}}1 when complete order lists are returned{p_end}
{synopt:{cmd:r(oldorder)}}complete pre-command physical variable order{p_end}
{synopt:{cmd:r(neworder)}}complete resulting physical variable order{p_end}


{title:Compatibility}

{pstd}
{cmd:varorder} requires Stata 16 or later.{p_end}


{title:Author}

{pstd}
Hao Ma, Ph.D.{p_end}

{pstd}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}{p_end}


{title:Citation}

{pstd}
If you use {cmd:varorder} in research, please cite the software.  Before an
SSC/RePEc identifier is assigned, the suggested citation is:{p_end}

{phang}
Ma, H. (2026). {it:varorder: Automated semantic detection and temporal ordering of variables in Stata}. Stata module, version 1.0.0.{p_end}


{title:License}

{pstd}
{cmd:varorder} is free software licensed under the GNU General Public License version 3
(GPL-3.0).{p_end}
