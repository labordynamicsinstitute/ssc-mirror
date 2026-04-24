{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:epifix} {hline 2} Fix structural problems in episode-format diary files

{title:Syntax}

{p 8 16 2}
{cmd:epifix} {it:varlist}{cmd:,} {opt did(varlist)} [{opt attrib(varlist)} {opt fullfix} {opt errorsonly} {opt quiet}]

{pstd}
where {it:varlist} contains {bf:1 to 6 activity variables} to be corrected.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt attrib(varlist)}}attribute variables to carry forward when rows are inserted; optional{p_end}
{synopt:{opt fullfix}}also fix fully overlapping episodes (issue 1); optional{p_end}
{synopt:{opt errorsonly}}process only diaries flagged as problematic, then reassemble the full dataset; optional{p_end}
{synopt:{opt quiet}}reduce printed output; optional{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:epifix} corrects structural problems in {bf:episode-format} diary files.

{pstd}
It is designed to work after {help epicheck}. Internally, {cmd:epifix} uses the issue flags created by {cmd:epicheck} and applies a set of automatic repairs to the affected diaries.

{pstd}
By default, {cmd:epifix} addresses issues 2 to 8:

{p2colset 8 12 18 2}{...}
{p2col:2.}nested episode{p_end}
{p2col:3.}partial overlap{p_end}
{p2col:4.}gap at minute 0{p_end}
{p2col:5.}gap at end of diary{p_end}
{p2col:6.}gap between episodes{p_end}
{p2col:7.}row with {cmd:start==end}{p_end}
{p2col:8.}row with missing {cmd:start} or {cmd:end}{p_end}
{p2colreset}{...}

{pstd}
Fully overlapping episodes (issue 1) are {bf:not} fixed unless the user specifies {opt fullfix}. 
This is intentional, because full overlaps often reflect the structure of wide-interval diary files rather than genuine data errors. 
In those cases, {help epitrans} is often the better first step.

{pstd}
The command creates standardized internal activity layers such as {cmd:__pri}, {cmd:__sec}, and so on, applies the repairs, and prints a summary table of the fixes made.

{title:Required variables}

{phang}
{cmd:start} must exist and contain the start minute of each episode.

{phang}
{cmd:end} must exist and contain the end minute of each episode.

{pstd}
The data must already be in episode format.

{title:Arguments}

{phang}
{it:varlist} specifies one to six activity variables to be corrected. 
These may be numeric or string, but all supplied activity variables must be of the same type.

{pstd}
These variables are copied into standardized working layers and are not themselves 
dropped from the dataset.

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely.

{title:Options}

{phang}
{opt attrib(varlist)} specifies attribute variables to be carried forward when inserted rows are created.

{pstd}
This is useful for variables such as location, co-presence, transport mode, or any 
other diary field that should remain aligned with the repaired episode structure.

{phang}
{opt fullfix} tells {cmd:epifix} to also fix {bf:fully overlapping episodes} (issue 1).

{pstd}
Without this option, full overlaps are left untouched.

{phang}
{opt errorsonly} restricts processing to diaries with at least one detected issue, 
fixes only those diaries, and then appends them back into the full original dataset.

{pstd}
This can be useful on large files where only a small subset of diaries needs repair.

{phang}
{opt quiet} reduces printed output.

{pstd}
The command still prints essential messages when needed, but suppresses the final 
note about fixed layer names.

{title:What the command creates}

{pstd}
{cmd:epifix} returns a repaired episode-format dataset and creates standardized 
activity-layer variables as needed:

{synoptset 20 tabbed}{...}
{synopthdr:Output variables}
{synoptline}
{synopt:{cmd:__pri}}primary activity layer{p_end}
{synopt:{cmd:__sec}}secondary activity layer{p_end}
{synopt:{cmd:__ter}}tertiary activity layer{p_end}
{synopt:{cmd:__quat}}quaternary activity layer{p_end}
{synopt:{cmd:__fif}}fifth activity layer{p_end}
{synopt:{cmd:__six}}sixth activity layer{p_end}
{synoptline}

{pstd}
Only layers that contain at least one nonmissing value are kept in the final dataset.

{pstd}
The original activity variables supplied in {it:varlist} remain in the dataset.

{title:How the fixes work}

{pstd}
The command uses {help epicheck} flags and applies repairs in place.

{pstd}
The main repair logic is as follows:

{phang}
{bf:Issue 1: Full overlap}  
Only fixed when {opt fullfix} is specified. All rows sharing the same {cmd:did}, {cmd:start}, and {cmd:end} 
are collapsed to one survivor row, and the overlapping activities are projected into the available standardized layers.

{phang}
{bf:Issue 2: Nested episode}  
The outer episode is split around the inner one. The overlapping middle segment keeps the container activity as primary and places the nested activity in a secondary layer.

{phang}
{bf:Issue 3: Partial overlap}  
Overlapping episodes are split into non-overlapping segments so that timing becomes 
consistent and simultaneous content is represented through activity layers.

{phang}
{bf:Issue 4: Gap at minute 0}  
A new first row is inserted covering the gap from 0 to the first observed start.

{phang}
{bf:Issue 5: Gap at end of diary}  
A new final row is inserted covering the gap from the last observed end to minute 1440.

{phang}
{bf:Issue 6: Gap between episodes}  
A bridging row is inserted covering the gap between two consecutive episodes.

{phang}
{bf:Issue 7: Row with start==end}  
Zero-length rows are dropped.

{phang}
{bf:Issue 8: Missing start or end}  
Rows with missing time bounds are dropped.

{pstd}
Inserted rows receive empty activity layers. If {opt attrib()} is supplied, those attribute variables are also cleared appropriately on the inserted rows.

{title:Checks and internal workflow}

{pstd}
If the dataset does not already contain {cmd:__flag_case} and {cmd:__flag_diary}, {cmd:epifix} runs {help epicheck} internally.

{pstd}
If no issues are detected, the command stops without changing the data.

{pstd}
If {opt errorsonly} is specified, the command first identifies bad diaries using {cmd:epicheck}, 
keeps only those diaries for the repair stage, and then rebuilds the full dataset by appending the fixed subset back to the untouched original diaries.

{title:Dataset after running the command}

{pstd}
The dataset remains in {bf:episode format}, but structural timing problems are repaired where possible.

{pstd}
Depending on the issue types present, the number of rows may increase (for inserted 
gap-filling rows or split episodes) or decrease (for dropped zero-length rows, dropped rows with missing bounds, or collapsed full overlaps under {opt fullfix}).

{title:Printed summary}

{pstd}
{cmd:epifix} prints a summary table showing the number of affected rows ({it:Cases}), the number of diaries affected, and the percentage of diaries affected.

{pstd}
The summary reports:

{phang2}
- full overlaps if {opt fullfix} is used{break}
- nested episodes{break}
- partial overlaps{break}
- gaps at minute 0{break}
- gaps at end of diary{break}
- gaps between episodes{break}
- dropped zero-length rows{break}
- dropped rows with missing {cmd:start}/{cmd:end}

{pstd}
At the end, unless {cmd:quiet} is specified, the command also reports which 
standardized activity-layer variables were created and reminds the user that 
the original activity variables are still in the dataset.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Fix standard issues but leave full overlaps untouched}

{phang2}{cmd:. epifix main sec, did(hldid persid id) attrib(inout eloc mtrav alone child sppart oad ict)}{p_end}

{pstd}
This repairs issues 2 to 8 but does not modify fully overlapping rows.

{marker ex2}{...}
{bf:Example 2: Also fix fully overlapping rows}

{phang2}{cmd:. epifix main sec, did(hldid persid id) attrib(inout eloc mtrav alone child sppart oad ict) fullfix}{p_end}

{pstd}
This additionally collapses fully overlapping rows into layered activities.

{marker ex3}{...}
{bf:Example 3: Process only problem diaries}

{phang2}{cmd:. epifix main sec, did(hldid persid id) errorsonly}{p_end}

{pstd}
Useful for large datasets where most diaries are already clean.

{marker ex4}{...}
{bf:Example 4: Recheck after fixing}

{phang2}{cmd:. epicheck, did(hldid persid id)}{p_end}

{pstd}
A common workflow is to run {cmd:epicheck}, then {cmd:epifix}, and then {cmd:epicheck} again to confirm that the remaining structure is valid.

{title:Remarks}

{pstd}
{bf:1. Use {cmd:epitrans} first for wide-interval diaries}

{pstd}
If full overlaps reflect survey design rather than real errors, use {help epitrans} before {cmd:epifix}. This is often the right sequence for wide-interval diary data.

{pstd}
{bf:2. All activity variables must have the same type}

{pstd}
If one supplied activity variable is string and another is numeric, the command stops with an error.

{pstd}
{bf:3. {cmd:fullfix} is a switch, not an option with parentheses}

{pstd}
Use {cmd:fullfix}, not {cmd:fullfix()}. The command explicitly rejects {cmd:fullfix()}.

{pstd}
{bf:4. Attributes are optional but often useful}

{pstd}
If inserted rows should carry properly aligned diary attributes, specify them in {opt attrib()}.

{pstd}
{bf:5. Repairs can be iterative}

{pstd}
In practice, one pass of {cmd:epifix} often resolves the main problems, but it is still good practice to rerun {cmd:epicheck} afterward.

{title:Stored results}

{pstd}
{cmd:epifix} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset and the printed summary.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epicheck} for diagnosing structural issues in episode files.

{pstd}
{help epitrans} for transforming wide-interval diary data before repair.
