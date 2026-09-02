{smcl}
{* *! version 2.0.0 31aug2026}{...}
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
labels, variable notes, attached value-label metadata, or agreement across these sources. It
represents supported time expressions as temporal components, combines them with defensible
precedence relations, and moves a family only when the resulting order is unique and conflict-free.
When the available information is ambiguous, incomplete, or conflicting,
{cmd:varorder} reports the issue rather than guessing.{p_end}


{title:Why use varorder?}

{pstd}
Stata's native {cmd:order} command is effective when the user already knows
exactly which variables should move and where they should go.  In large
wide-format datasets, however, the difficult part may be identifying which
variables belong to the same repeated-measure structure and determining their
correct temporal sequence.  {cmd:varorder} is designed to reduce the manual
work required to locate scattered repeated-measure variables, determine their
temporal sequence, and reorganize them safely. {cmd:varorder} applies one common
decision framework across supported indexes, stages, dates, relative times, and
hierarchies, so ordinary users do not need to select a pattern or learn new
options as metadata conventions vary across datasets.{p_end}


{title:Key features}

{p 4 6 2}• {bf:Semantic detection and normalization across four sources.} {cmd:varorder} uses
variable names, labels, notes, and attached value-label metadata to identify related variables and
assess temporal structure. Formatting differences such as capitalization, separators, compact
forms, and zero-padding in temporal indexes are normalized internally, while original metadata
remain unchanged and source-specific agreement or conflict remains detectable. Value labels
provide value-domain evidence; category text is not treated as a measurement occasion.{p_end}

{p 4 6 2}• {bf:General temporal, stage, and date ordering.} {cmd:varorder} recognizes
high-confidence temporal patterns including indexed occasions, calendar periods, validated dates,
relative time, hierarchical structures, and supported stage sequences. Explicit metadata may
define additional stage order. Ambiguous dates, cycles, disconnected or non-unique relations, and
unsupported numeric suffixes are not guessed; invalid dates and two-digit years are not
interpreted.{p_end}

{p 4 6 2}• {bf:Auditable and conservative operation.} Default output remains compact, while
readable, self-identifying {cmd:r()} results provide family decisions, temporal types, evidence
sources, normalized keys, and warning or no-action reasons. {cmd:varorder} orders variables only when evidence is
sufficiently clear; ambiguity, metadata conflicts, invalid values, collisions, and unsupported
sequences are reported instead. It is preview-first, asks for at most one confirmation, and changes
only physical variable order. Indexed gaps warn but do not by themselves prevent an otherwise
unambiguous ordering.{p_end}


{title:Syntax}

{p 4 22 2}{cmd:varorder}{p_end}
{p 4 22 2}{cmd:varorder, undo}{p_end}


{title:Practical applications}

{title:Example 1. Use the module to automatically detect temporal families and order their variables in the provided example dataset}

{pstd}
The example dataset contains 5,000 observations and 272 variables. It includes indexed and
relative time, calendar periods and dates, stage sequences, temporal hierarchies, and explicit
precedence constraints, together with gaps, collisions, metadata conflicts, ambiguous relations,
and non-temporal controls.{p_end}

{p 4 4 2}{cmd:. use varorder_example_data.dta, clear}{p_end}
{p 4 4 2}{cmd:. varorder}{p_end}

{p 8 8 2}{txt:varorder preview summary}{p_end}

{p 8 8 2}{txt:Examined: 272 variables}{p_end}
{p 8 8 2}{txt:Confirmed temporal structures: 48}{p_end}
{p 8 8 2}{txt:Variables to be reordered: 186}{p_end}
{p 8 8 2}{txt:Maximum displacement: 89 columns}{p_end}

{p 8 8 2}{txt:Issues requiring review:}{p_end}
{p 10 10 2}{txt:Gap warnings but ordering allowed (3): fortitude, mobility, vigor}{p_end}
{p 10 10 2}{txt:Related/unverified — no action (14): barcode, batchcode, chronological_comfort, eng, exercise, lab, moduleitem, mood, ...}{p_end}
{p 10 10 2}{txt:Ambiguous/conflicting — no action (20): acoustic_calibration, apex, decision_confidence, finance, focus, memory, mirage, motor_coordination, ...}{p_end}

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


{title:Main stored results}

{pstd}
After {cmd:varorder}, the command stores the following in {cmd:r()}:{p_end}

{synoptset 34 tabbed}{...}
{synopt:{cmd:r(changed)}}1 if physical variable order changed; 0 otherwise{p_end}
{synopt:{cmd:r(k)}}number of variables examined{p_end}
{synopt:{cmd:r(n_families_detected)}}number of candidate structures detected{p_end}
{synopt:{cmd:r(n_families_confirmed)}}number of confirmed temporal structures{p_end}
{synopt:{cmd:r(n_families_related)}}number of related or temporally unverified structures{p_end}
{synopt:{cmd:r(n_families_ambiguous)}}number of ambiguous or conflicting structures{p_end}
{synopt:{cmd:r(n_families_changed)}}number of confirmed structures contributing to changed positions{p_end}
{synopt:{cmd:r(n_families_suppressed)}}sum of related and ambiguous structures{p_end}
{synopt:{cmd:r(families_detected)}}normalized family names of candidate structures detected{p_end}
{synopt:{cmd:r(families_confirmed)}}normalized family names of confirmed temporal structures{p_end}
{synopt:{cmd:r(families_related)}}normalized family names of related or temporally unverified structures{p_end}
{synopt:{cmd:r(families_ambiguous)}}normalized family names of ambiguous or conflicting structures{p_end}
{synopt:{cmd:r(families_changed)}}normalized family names of confirmed structures contributing to changed positions{p_end}
{synopt:{cmd:r(families_suppressed)}}normalized family names of related and ambiguous structures{p_end}
{synopt:{cmd:r(n_moved)}}number of variables whose physical positions changed{p_end}
{synopt:{cmd:r(max_displacement)}}largest position displacement among moved variables{p_end}
{synopt:{cmd:r(order_lists_returned)}}1 when complete order lists are returned{p_end}
{synopt:{cmd:r(oldorder)}}complete pre-command physical variable order, directly usable as a varlist{p_end}
{synopt:{cmd:r(neworder)}}complete resulting physical variable order, directly usable as a varlist{p_end}
{synopt:{cmd:r(audit_lists_returned)}}1 when every readable audit result is returned completely; 0 otherwise{p_end}
{synopt:{cmd:r(audit_family_types)}}family names and recognized temporal-structure types{p_end}
{synopt:{cmd:r(audit_family_evidence)}}family names and evidence sources written in words{p_end}
{synopt:{cmd:r(audit_family_reasons)}}family names and readable warning or no-action explanations{p_end}
{synopt:{cmd:r(audit_variable_keys)}}variable names, family names, and inferred temporal keys{p_end}
{synopt:{cmd:r(audit_variable_evidence)}}variable names, family names, and evidence sources written in words{p_end}
{synopt:{cmd:r(audit_variable_reasons)}}variable names, family names, and specific readable explanations for no action{p_end}

{pstd}
To view a main stored result, use a command such as
{cmd:di `"`r(audit_variable_reasons)'"'}; for another result, replace
{cmd:audit_variable_reasons} with the desired {cmd:r()} name listed above.{p_end}


{title:Compatibility}

{pstd}
{cmd:varorder} requires Stata 16 or later.{p_end}


{title:Version history}

{pstd}
2.0.0, 31 August 2026. Replaced form-by-form family comparison with a common
temporal-component and precedence-constraint engine. Added additional validated English
calendar-date forms, explicit ordering for otherwise unknown semantic stages, stronger cross-source
evidence fusion, conservative cycle and non-unique-order suppression, and readable family- and
variable-level audit results. Expanded the single example dataset from 146 to 272 variables by
adding 126 independent V2 cases. The ordinary syntax, compact preview, single confirmation,
physical-order-only mutation, rollback, and single-level undo remain unchanged.{p_end}

{pstd}
1.1.0, 23 August 2026. Added a typed temporal-component model and conservative
support for calendar months, valid ISO dates, fiscal year/quarter, academic
year/indexed term, extended observation stages, cycle/visit,
year/quarter/month, and signed relative time. The ordinary syntax, conservative
no-action rules, one-confirmation workflow, data and metadata preservation, and
single-level undo remain unchanged. Complete returned order lists are directly
usable as Stata varlists.{p_end}

{pstd}
1.0.0, 21 August 2026. Initial SSC release for automatic semantic detection
and safe temporal ordering from variable names, variable labels, variable
notes, and attached value-label metadata.{p_end}


{title:Author}

{pstd}
Hao Ma, Ph.D.{p_end}

{pstd}
Email: {browse "mailto:shouhuoxiwang2027@gmail.com":shouhuoxiwang2027@gmail.com}{p_end}


{title:Suggested citation}

{phang}
Hao Ma, 2026. "{browse "https://ideas.repec.org/c/boc/bocode/s459871.html":VARORDER: Stata module for automatic semantic temporal ordering of variables in wide-format Stata datasets}", Statistical Software Components S459871, Boston College Department of Economics.{p_end}


{title:License}

{pstd}
{cmd:varorder} is free software licensed under the GNU General Public License version 3
(GPL-3.0).{p_end}
