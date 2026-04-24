{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:epitrans} {hline 2} Transform wide-interval diary rows into standard episode format

{title:Syntax}

{p 8 16 2}
{cmd:epitrans} {it:actvar}{cmd:,} {opt did(varlist)} {opt sim(varname)} {opt napi(#)} [{opt dur(varname)}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:actvar}}activity variable to be transformed; required{p_end}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt sim(varname)}}simultaneity flag (1 = simultaneous, 0 = sequential); required{p_end}
{synopt:{opt napi(#)}}maximum number of activity layers to create (2 to 6); required{p_end}
{synopt:{opt dur(varname)}}within-slot duration variable for unequal sequential splits; optional{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:epitrans} restructures data from {bf:wide-interval diary formats}, where multiple activities are listed in separate rows sharing the same time interval.

{pstd}
These formats are common in some surveys where respondents report several activities within a broad slot (for example 30 minutes or 1 hour), and the raw file stores one row per listed activity rather than one row per final episode.

{pstd}
{cmd:epitrans} converts this structure into a standard {bf:episode-format} file with clear {cmd:start} and {cmd:end} times and layered activity fields such as primary, secondary, and tertiary activities.

{pstd}
Sequential activities within the same slot are converted into consecutive non-overlapping sub-episodes. Simultaneous activities are consolidated into a single time window with multiple activity layers.


{title:Required variables}

{phang}
{cmd:start} must exist and contain the start minute of the interval or episode.

{phang}
{cmd:end} must exist and contain the end minute of the interval or episode.

{pstd}
The input data may already be in episode-style rows or may come from fixed slots converted into {cmd:start}/{cmd:end} using {help clock2min} or similar preparation.

{title:Arguments}

{phang}
{it:actvar} is the activity variable. It may be numeric or string.

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely.

{phang}
{opt sim(varname)} specifies the simultaneity flag.

{pstd}
Expected coding is:

{phang2}{cmd:1} = simultaneous activity{p_end}
{phang2}{cmd:0} = sequential activity{p_end}

{phang}
{opt napi(#)} specifies the maximum number of activity layers to retain in the output. Allowed values are from {cmd:2} to {cmd:6}.

{phang}
{opt dur(varname)} specifies a numeric duration variable containing within-slot durations for sequential activities.

{pstd}
When supplied, these durations are used instead of equal splitting for sequential activities. Durations attached to simultaneous rows are ignored.

{title:What the command creates}

{pstd}
{cmd:epitrans} transforms the data into an episode-format file and creates standard layered activity variables:

{synoptset 20 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:__pri}}primary activity{p_end}
{synopt:{cmd:__sec}}secondary activity{p_end}
{synopt:{cmd:__ter}}tertiary activity{p_end}
{synopt:{cmd:__quat}}quaternary activity{p_end}
{synopt:{cmd:__fif}}fifth activity layer{p_end}
{synopt:{cmd:__six}}sixth activity layer{p_end}
{synoptline}

{pstd}
Only the layers required by {opt napi()} are kept.

{pstd}
The original activity variable supplied to {cmd:epitrans} is removed and replaced by these standardised activity layers.

{title:How the transformation works}

{pstd}
Within each diary and time interval, {cmd:epitrans} groups rows that share the same {cmd:start}/{cmd:end} boundaries.

{pstd}
Then:

{phang}
{bf:If all activities are sequential}  
The interval is split into consecutive sub-episodes.

{phang}
{bf:If all activities are simultaneous}  
The interval remains one episode, with activities stored across layers.

{phang}
{bf:If a mixture is present}  
Sequential rows are laid out as separate episodes, while simultaneous rows are layered within the relevant interval according to row order.

{pstd}
Incoming row order matters. The command respects the order of rows when deciding sequence and activity priority.

{title:How duration splitting works}

{pstd}
By default, sequential activities sharing the same interval receive equal durations.

{pstd}
If equal division leaves remainder minutes, the earliest created sub-episode(s) receive the extra minute(s) so that the total duration matches the original interval exactly.

{pstd}
If {opt dur()} is supplied, those durations are used for sequential activities instead.

{title:Checks and warnings}

{pstd}
{cmd:epitrans} checks that:

{phang2}
- {cmd:start} and {cmd:end} exist{break}
- {cmd:napi()} is between 2 and 6{break}
- required variables are present

{pstd}
The command also reports summary tables describing the transformed overlap blocks.

{title:Dataset after running the command}

{pstd}
The dataset remains in {bf:episode format}, but with corrected timing and standardised activity layers.

{pstd}
The number of rows may increase or decrease depending on how many intervals are split or consolidated.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Basic transformation}

{phang2}{cmd:. epitrans act, did(hid pid) sim(simult) napi(3)}{p_end}

{pstd}
Creates primary, secondary, and tertiary layers.

{marker ex2}{...}
{bf:Example 2: Use recorded unequal durations}

{phang2}{cmd:. epitrans act, did(id) sim(sim) napi(2) dur(durmins)}{p_end}

{pstd}
Uses {cmd:durmins} to split sequential activities within intervals.

{marker ex3}{...}
{bf:Example 3: Check result afterward}

{phang2}{cmd:. epicheck, did(hid pid)}{p_end}

{pstd}
Useful to confirm the transformed file is structurally valid.

{title:Remarks}

{pstd}
{bf:1. Sort order matters}

{pstd}
Before running {cmd:epitrans}, sort carefully by diary identifier, then by interval ({cmd:start}/{cmd:end}), and then by any within-slot priority variable if one exists.

{pstd}
{bf:2. Use a major-activity indicator when available}

{pstd}
If the source data indicate which activity is the main one, sort so that the main activity appears first within each block.

{pstd}
{bf:3. Choose {cmd:napi()} realistically}

{pstd}
Most datasets only require 2 or 3 layers. Larger values retain more simultaneous activities but create wider files.

{pstd}
{bf:4. Equal splitting is a fallback}

{pstd}
If real within-slot durations are available, use {opt dur()} whenever possible.

{pstd}
{bf:5. Good harmonisation workflow}

{pstd}
A common sequence is:

{phang2}
raw file -> {help clock2min} -> {cmd:epitrans} -> {help epicheck} -> analysis

{title:Stored results}

{pstd}
{cmd:epitrans} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset and printed summaries.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epicheck} for diagnosing structural issues in episode files.

{pstd}
{help clock2min} for creating {cmd:start} and {cmd:end} from clock-style variables.
