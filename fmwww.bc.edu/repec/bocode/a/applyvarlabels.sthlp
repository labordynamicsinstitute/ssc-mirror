{smcl}
{* *! version 1.0.0  2026-07-18}{...}
{viewerjumpto "Syntax" "applyvarlabels##syntax"}{...}
{viewerjumpto "Description" "applyvarlabels##description"}{...}
{viewerjumpto "What you get back" "applyvarlabels##output"}{...}
{viewerjumpto "Options" "applyvarlabels##options"}{...}
{viewerjumpto "Examples" "applyvarlabels##examples"}{...}
{viewerjumpto "Stored results" "applyvarlabels##results"}{...}
{viewerjumpto "Remarks" "applyvarlabels##remarks"}{...}
{viewerjumpto "Author" "applyvarlabels##author"}{...}

{title:Title}

{p2colset 5 23 25 2}{...}
{p2col :{cmd:applyvarlabels} {hline 2}}Label the variables in memory from a two-column (Variable, Label) crosswalk in Excel or CSV{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:applyvarlabels} {cmd:using} {it:crosswalkfile} [{cmd:,} {it:options}]

{pstd}
{it:crosswalkfile} is a {cmd:.xlsx}/{cmd:.xls} workbook or a {cmd:.csv}/{cmd:.tsv}/{cmd:.txt}
file with one row per variable: a column of variable names and a column of the
labels to apply.  The dataset to label must already be in memory.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Crosswalk layout}
{synopt :{cmdab:v:ariable(}{it:name}{cmd:)}}column holding the variable names; default {cmd:variable(Variable)}{p_end}
{synopt :{cmdab:l:abel(}{it:name}{cmd:)}}column holding the labels; default {cmd:label(Label)}{p_end}
{synopt :{cmd:sheet(}{it:name}{cmd:)}}worksheet holding the crosswalk (Excel only); default is the first sheet{p_end}
{synopt :{cmd:nocase}}match crosswalk names to variables ignoring case{p_end}

{syntab :Output and control}
{synopt :{cmdab:do:file(}{it:filename}{cmd:)}}write the generated relabel do-file here and keep it; default is a temp-dir file{p_end}
{synopt :{cmd:norun}}write the relabel do-file but do {it:not} apply the labels{p_end}
{synopt :{cmd:smcl(}{it:filename}{cmd:)}}write the inventory to this {cmd:.smcl} file; default is a temp-dir file{p_end}
{synopt :{cmd:replace}}overwrite an existing {cmd:dofile()} or {cmd:smcl()} file{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:applyvarlabels} solves a recurring Statalist problem
({browse "https://www.statalist.org/forums/forum/general-stata-discussion/general/1768839":thread 1768839}):
you are handed a dataset of many variables, {it:none of them labeled}, together
with a spreadsheet that lists each variable name beside the label it should
carry.  The intuitive loop {c 45} {helpb levelsof} the labels, {helpb tokenize}
the variables, and march down both at once {c 45} puts the wrong label on the
wrong variable, because {cmd:levelsof} returns the distinct labels sorted
{it:alphabetically}, so pairing them positionally with the variables lines them
up in the wrong order.{p_end}

{pstd}
{cmd:applyvarlabels} reads the crosswalk in {bf:row order} and matches every
label to its variable {bf:by name}, never by position.  It then:{p_end}

{phang2}1. {bf:Writes a capture-guarded relabel do-file}: one
{cmd:capture label variable} line per crosswalk row.  {cmd:capture} means a
variable named in the crosswalk but absent from the data is skipped, not an
error {c 45} so the file is safe to rerun on any dataset that shares the
names.{p_end}

{phang2}2. {bf:Runs it} to apply the labels to the data in memory (unless you
say {cmd:norun}).{p_end}

{phang2}3. {bf:Prints an inventory} of everything that did not line up:
crosswalk rows with no such variable, and variables in memory the crosswalk
never mentions {c 45} on screen and to a viewable {cmd:.smcl} file.{p_end}

{pstd}
The data in memory are never sorted, dropped, or reordered.  The crosswalk is
read in its own {helpb frames:frame}, so nothing changes but the variable
labels themselves.{p_end}


{marker output}{...}
{title:What you get back}

{pstd}{bf:1. Labels on your variables.}  Exact-name matches are applied in
place; {helpb describe} shows the result.{p_end}

{pstd}{bf:2. A reusable relabel do-file.}  Every match is written as a
{cmd:capture label variable} line, wrapped in a {cmd:set varabbrev off}/restore
pair so an abbreviated name can never resolve to the wrong variable.  Name it
with {cmd:dofile()} to keep it beside your cleaning code; its path is in
{cmd:r(dofile)}, offered as a click-to-view link.{p_end}

{pstd}{bf:3. An inventory of what did not match.}  Two lists {c 45} crosswalk
rows with no such variable ({cmd:r(nomatch)}), and variables with no crosswalk
row ({cmd:r(nolabel)}) {c 45} plus notes on duplicate rows, empty-label rows,
and labels past Stata's 80-character limit.  The full inventory is also written
to {cmd:r(smcl)}.{p_end}


{marker options}{...}
{title:Options}

{phang}{cmd:variable(}{it:name}{cmd:)} and {cmd:label(}{it:name}{cmd:)} name the
two crosswalk columns.  The defaults, {cmd:Variable} and {cmd:Label}, are
matched case-insensitively, so a header of {cmd:variable} or {cmd:VARIABLE}
also works.{p_end}

{phang}{cmd:sheet(}{it:name}{cmd:)} selects the worksheet that holds the
crosswalk, for an Excel workbook whose crosswalk is not on the first sheet
(for example, a workbook whose first sheet is the data and whose second is the
labels).  Ignored, with a note, for a delimited file.{p_end}

{phang}{cmd:nocase} matches a crosswalk name to a variable ignoring case, so
{cmd:AgeYears} in the spreadsheet finds {cmd:ageyears} in the data.  The
generated do-file uses the variable's {it:actual} spelling, so {cmd:capture}
never misfires.  Without it, matching is exact.{p_end}

{phang}{cmd:dofile(}{it:filename}{cmd:)} writes the relabel do-file to a path
you choose and keeps it; a {cmd:.do} suffix is added if you omit it.  Without
this option the file goes to a temporary directory (viewable during the
session, overwritten on the next run).  Use {cmd:replace} to overwrite an
existing named file.{p_end}

{phang}{cmd:norun} writes the relabel do-file but does not apply the labels {c 45}
a dry run.  Inspect or edit the file, then {cmd:do} it yourself.  The inventory
still reports what would and would not have matched.{p_end}

{phang}{cmd:smcl(}{it:filename}{cmd:)} writes the inventory to a {cmd:.smcl}
file you name (a {cmd:.smcl} suffix is added if omitted); {cmd:replace}
overwrites it.  The default writes to a temporary-directory file offered as a
click-to-view link.{p_end}

{phang}{cmd:replace} permits {cmd:applyvarlabels} to overwrite an existing
{cmd:dofile()} or {cmd:smcl()} target.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}The headline case {c 45} data in memory, crosswalk on its own sheet:{p_end}
{phang2}{cmd:. import excel using "survey.xlsx", sheet("data") firstrow clear}{p_end}
{phang2}{cmd:. applyvarlabels using "survey.xlsx", sheet("var_labels")}{p_end}

{pstd}Crosswalk columns named something other than Variable/Label:{p_end}
{phang2}{cmd:. applyvarlabels using "labels.xlsx", variable(varname) label(description)}{p_end}

{pstd}A CSV crosswalk (importer chosen from the extension):{p_end}
{phang2}{cmd:. applyvarlabels using "labels.csv"}{p_end}

{pstd}Names that differ only in case:{p_end}
{phang2}{cmd:. applyvarlabels using "labels.xlsx", nocase}{p_end}

{pstd}Keep the relabel do-file as a reusable, auditable artifact:{p_end}
{phang2}{cmd:. applyvarlabels using "labels.xlsx", dofile("relabel_survey.do") replace}{p_end}

{pstd}Dry run {c 45} write the relabel do-file, apply nothing, inspect it first:{p_end}
{phang2}{cmd:. applyvarlabels using "labels.xlsx", norun dofile("relabel_preview.do") replace}{p_end}
{phang2}{cmd:. do "relabel_preview.do"}{p_end}

{pstd}The bundled {cmd:example_applyvarlabels.do} walks the whole workflow on
the shipped {cmd:example_varlabels.xlsx}, including the two crosswalk rows with
no matching variable and the one variable with no crosswalk row.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:applyvarlabels} stores the following in {cmd:r()}:{p_end}
{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt :{cmd:r(N_variables)}}variables in memory{p_end}
{synopt :{cmd:r(N_applied)}}variables that received a label{p_end}
{synopt :{cmd:r(N_nomatch)}}crosswalk rows with no matching variable{p_end}
{synopt :{cmd:r(N_nolabel)}}variables in memory with no crosswalk row{p_end}
{synopt :{cmd:r(N_normalized)}}labels altered for Stata (straight quotes, backticks){p_end}
{synopt :{cmd:r(N_long)}}labels over 80 characters (truncated by Stata){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt :{cmd:r(applied)}}variables that received a label{p_end}
{synopt :{cmd:r(nomatch)}}crosswalk names not found in memory{p_end}
{synopt :{cmd:r(nolabel)}}variables in memory with no crosswalk row{p_end}
{synopt :{cmd:r(dups)}}variables named more than once in the crosswalk (last label wins){p_end}
{synopt :{cmd:r(blanks)}}variables whose crosswalk label cell was empty (skipped){p_end}
{synopt :{cmd:r(normalized)}}variables whose label was altered for Stata (curly quotes, apostrophes){p_end}
{synopt :{cmd:r(dofile)}}path of the generated relabel do-file{p_end}
{synopt :{cmd:r(smcl)}}path of the inventory {cmd:.smcl} file{p_end}
{p2colreset}{...}

{pstd}Under {cmd:norun}, {cmd:r(N_applied)} counts the variables that would be
labeled (the do-file is written and left for you to run), and the labels are not
yet on the data.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}{bf:Why a do-file, and why capture.}  Writing the relabel commands to a
do-file makes the labeling an inspectable, version-controllable, rerunnable
step rather than a one-shot side effect {c 45} the same descsave-style logic
behind a codebook you can regenerate.  {cmd:capture} guards each line so a
crosswalk that is broader than the data at hand (extra rows, a variable dropped
upstream) applies cleanly to whatever is present and reports the rest.{p_end}

{pstd}{bf:Matching is exact by default.}  A crosswalk name must equal a variable
name (Stata is case-sensitive).  Variable-name abbreviation is turned off while
matching and inside the generated do-file, so a crosswalk row {cmd:inc} never
silently lands on a variable named {cmd:income}.  Use {cmd:nocase} for
case-insensitive matching.  Trailing and leading spaces in the crosswalk cells
are trimmed.{p_end}

{pstd}{bf:Labels are capped at 80 characters.}  Stata truncates a variable
label longer than 80 characters; {cmd:applyvarlabels} counts such labels in
{cmd:r(N_long)} and cautions you rather than failing.{p_end}

{pstd}{bf:Special characters.}  Apostrophes, ampersands, and dollar signs are
preserved exactly {c 45} a {cmd:{c 36}}name in a label is escaped in the
generated do-file so it is not macro-expanded when that file runs.  Two
characters a Stata variable label cannot carry are normalized instead, and the
affected variables are listed in {cmd:r(normalized)} with a note: a
{it:straight double quote} ({cmd:{c 34}}), which {helpb label:label variable}
cannot parse, becomes a typographic (curly) quote; and a {it:backtick}
({cmd:{c 96}}), which would open a macro reference when the relabel do-file
runs, becomes an apostrophe.{p_end}

{pstd}{bf:Nothing else changes.}  The crosswalk is read in a separate frame;
the data in memory keep their sort order, their observations, and their
variable order.  Only variable labels are touched, and only for matched
variables.  A variable that already had a label and appears in the crosswalk is
relabeled; one that is not in the crosswalk is left exactly as it was and
listed in {cmd:r(nolabel)}.{p_end}


{marker author}{...}
{title:Author}

{pstd}Eric A. Booth{break}
Sr Researcher, Texas 2036{break}
eric.a.booth@gmail.com{p_end}

{pstd}MIT License.  Report issues at the {browse "https://github.com/ericabooth/applyvarlabels-stata-public":GitHub repository}.{p_end}


{title:Also see}

{psee}Help: {helpb label}, {helpb label_language:label language}, {helpb import excel}, {helpb frames}{p_end}
{psee}Related: {helpb labelbook}, {helpb ds}, {helpb describe}{p_end}
