{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:epicheck} {hline 2} Diagnose structural problems in episode-format diary files

{title:Syntax}

{p 8 16 2}
{cmd:epicheck}{cmd:,} {opt did(varlist)} [{opt quiet}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt quiet}}suppress output when no issues are detected{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:epicheck} is a diagnostic command for {bf:episode-format} diary files.

{pstd}
Given a diary identifier and the variables {cmd:start} and {cmd:end}, it scans each diary for 
several types of structural problems that commonly arise in episode data. 
These include overlaps, gaps, zero-length episodes, and missing time boundaries.

{pstd}
The command is intended as a quality-checking step before analysis. Problems detected 
by {cmd:epicheck} should usually be investigated and, where appropriate, corrected 
before proceeding. In many workflows, these issues can later be addressed using a 
repair command such as {help epifix}.

{pstd}
A related command, {help tslotcheck}, performs analogous checks on {bf:calendar-format} files.

{title:Required variables}

{phang}
{cmd:start} must exist and contain the start minute of each episode.

{phang}
{cmd:end} must exist and contain the end minute of each episode.

{pstd}
The dataset should already be in episode format, with one row per episode.

{title:Arguments}

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely.

{title:Option}

{phang}
{opt quiet} suppresses output when no issues are detected.

{pstd}
If issues are found, the report is still printed even when {cmd:quiet} is specified.

{title:Issues checked}

{pstd}
{cmd:epicheck} checks for the following eight issue types:

{phang}
{bf:1. Full overlap}
Two or more episodes within a diary have the same {cmd:start} and {cmd:end} times.

{phang}
{bf:2. Nested episode}
One episode fully contains the next episode.

{phang}
{bf:3. Partial overlap}
Two consecutive episodes overlap in time without complete containment.

{phang}
{bf:4. Gap at min 0}
The first episode of a diary does not begin at minute 0.

{phang}
{bf:5. Gap at end of diary}
The final episode of a diary ends before minute 1440.

{phang}
{bf:6. Gap between episodes}
A positive gap exists between consecutive episodes.

{phang}
{bf:7. Row with start==end}
An episode has zero duration.

{phang}
{bf:8. Row with start==.|end==.}
At least one of {cmd:start} or {cmd:end} is missing.

{title:What the command creates}

{pstd}
When issues are detected, {cmd:epicheck} creates episode-level and diary-level flag variables in the dataset.

{synoptset 28 tabbed}{...}
{synopthdr:Output variables}
{synoptline}
{synopt:{cmd:__flag_case}}episode-level issue code: 0 = no issue, 1 to 8 = issue type{p_end}
{synopt:{cmd:__flag_diary}}diary-level flag: 1 if the diary contains any issue{p_end}
{synopt:{cmd:__flag_diary_1}}diary contains at least one full overlap{p_end}
{synopt:{cmd:__flag_diary_2}}diary contains at least one nested episode{p_end}
{synopt:{cmd:__flag_diary_3}}diary contains at least one partial overlap{p_end}
{synopt:{cmd:__flag_diary_4}}diary contains a gap at the beginning{p_end}
{synopt:{cmd:__flag_diary_5}}diary contains a gap at the end{p_end}
{synopt:{cmd:__flag_diary_6}}diary contains a gap between episodes{p_end}
{synopt:{cmd:__flag_diary_7}}diary contains at least one zero-length episode{p_end}
{synopt:{cmd:__flag_diary_8}}diary contains at least one row with missing {cmd:start} or {cmd:end}{p_end}
{synoptline}

{pstd}
If no issues are detected, these flag variables are dropped before the command finishes.

{title:How issue coding works}

{pstd}
Each episode is assigned at most one value in {cmd:__flag_case}. If a row could qualify for more than one issue type, the command applies the following priority order:

{phang2}
{cmd:8 > 7 > 1 > 2 > 3 > 4 > 5 > 6}

{pstd}
This means, for example, that a row with missing {cmd:start} or {cmd:end} is classified as issue 8 even if other problems would also apply.

{title:How missing values are handled}

{pstd}
Rows with missing values in one or more variables listed in {opt did()} are {bf:not dropped} from the dataset. However, they are ignored during structural issue detection, and the command reports how many such rows were found.

{pstd}
Rows with missing {cmd:start} or {cmd:end} are kept in the data and are classified as issue 8 in the final output.

{title:Output in the Results window}

{pstd}
If no issues are detected, {cmd:epicheck} prints:

{phang2}{cmd:No issues detected.}{p_end}

{pstd}
Otherwise, it prints a summary table showing: the number of flagged rows ({it:Cases}), number of diaries affected ({it:Diaries}), and 
percentage of diaries affected

{pstd}
A total row is shown at the bottom of the table.

{title:Dataset after running the command}

{pstd}
{cmd:epicheck} does not reshape or collapse the dataset. The file remains at the {bf:episode level}.

{pstd}
The command is diagnostic: it inspects the data, reports issues, and adds flag variables when needed.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Basic episode check}

{phang2}{cmd:. use mtus_hef, clear}{p_end}
{phang2}{cmd:. epicheck, did(hldid persid id)}{p_end}

{pstd}
If the file is structurally sound, the command reports that no issues were detected.

{marker ex2}{...}
{bf:Example 2: Quiet mode}

{phang2}{cmd:. epicheck, did(hldid persid id) quiet}{p_end}

{pstd}
This suppresses output only when no issues are present.

{marker ex3}{...}
{bf:Example 3: Investigate flagged rows}

{phang2}{cmd:. epicheck, did(hldid persid id)}{p_end}
{phang2}{cmd:. tab __flag_case}{p_end}
{phang2}{cmd:. list hldid persid id start end if __flag_case>0}{p_end}

{pstd}
This lets you inspect the problematic rows directly.

{title:Remarks}

{pstd}
{bf:1. Run before analysis}

{pstd}
It is good practice to run {cmd:epicheck} before commands that rely on structurally valid episode timing.

{pstd}
{bf:2. Flags are diagnostic, not corrections}

{pstd}
{cmd:epicheck} identifies problems but does not repair them. Use the flags to inspect the data or pass the file to a repair workflow.

{pstd}
{bf:3. Missing diary identifiers are treated separately}

{pstd}
Rows with missing values in {opt did()} are not used in the structural checks, because they cannot be assigned reliably to a diary.

{pstd}
{bf:4. Zero-length and missing-bound rows are preserved}

{pstd}
Unlike some structural checks that work on temporary filtered copies internally, the final output restores these rows and flags them in the original dataset.

{pstd}
{bf:5. No flag variables remain if the file is clean}

{pstd}
If the command finds no issues at all, the flag variables are removed before exit.

{title:Stored results}

{pstd}
{cmd:epicheck} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the report and, when relevant, through the created flag variables.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epifix} for repairing structural issues in episode files.

{pstd}
{help tslotcheck} for analogous checks in calendar-format files.
