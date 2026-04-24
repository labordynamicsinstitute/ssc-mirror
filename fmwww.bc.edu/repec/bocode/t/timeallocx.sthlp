{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:timeallocx} {hline 2} Create diary-level duration, counts, and timing variables for one target activity or category

{title:Syntax}

{p 8 16 2}
{cmd:timeallocx} {it:varname}{cmd:,} {opt did(string)} {opt dst(string)}

{pstd}
where {it:varname} is intended to be a {bf:binary indicator} equal to 1 for episodes of interest and 0 otherwise.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(string)}}variable or variables that uniquely identify each diary; required{p_end}
{synopt:{opt dst(string)}}diary start time on a 24-hour clock; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:timeallocx} converts an {bf:episode-level} diary dataset into a {bf:diary-level} dataset with one row per diary.

{pstd}
It is designed for situations where the researcher wants detailed information about {bf:one specific activity or category}, such as eating, paid work, travel, childcare, or time spent at home.

{pstd}
Unlike {help timealloc}, which summarises all categories of a diary field, {cmd:timeallocx} focuses on a single category of the diary field and also creates {bf:timing variables}.

{pstd}
For each diary, the command creates total time, number of episodes, start and end times for each episode, durations for each episode, and a separate set of variables referring to the {bf:last} episode in the diary.

{pstd}
This is especially useful when the timing of an activity matters, for example when studying meal times, work start times, commuting, or the final occurrence of an activity during the day.

{pstd}
After running {cmd:timeallocx}, the dataset contains one row per diary. Existing variables are preserved, and identifiers plus the newly created variables are placed first.

{title:Required variables}

{phang}
{cmd:start} must be present in the data and must contain the start minute of each episode.

{phang}
{cmd:end} must be present in the data and must contain the end minute of each episode.

{pstd}
Episode duration is calculated as {cmd:end - start}.

{title:Arguments}

{phang}
{it:varname} should normally be a {bf:numeric binary variable} coded 1 for the category of interest and 0 otherwise.

{pstd}
For example:

{phang2}{cmd:. gen eating = (activity==150)}{p_end}

{pstd}
where code 150 corresponds to eating.

{phang}
{opt did(string)} specifies the variable or variables that jointly identify each diary uniquely.

{pstd}
For example:

{phang2}{cmd:. timeallocx eating, did(PUMFID) dst(4)}{p_end}
{phang2}{cmd:. timeallocx eating, did(hldid persid id) dst(4)}{p_end}

{phang}
{opt dst(string)} specifies the diary start time using a 24-hour clock.

{pstd}
Examples:

{phang2}{cmd:dst(0)} = diary begins at midnight{p_end}
{phang2}{cmd:dst(4)} = diary begins at 04:00{p_end}
{phang2}{cmd:dst(18)} = diary begins at 18:00{p_end}

{pstd}
This option is used to attach readable clock-time labels to the generated timing variables.

{title:What the command creates}

{pstd}
For each diary, {cmd:timeallocx} creates the following variables:

{synoptset 28 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:total}}total minutes where {it:varname}==1{p_end}
{synopt:{cmd:episodes}}number of episodes where {it:varname}==1{p_end}
{synopt:{cmd:start1 start2 ... startN}}start minute of each target episode{p_end}
{synopt:{cmd:end1 end2 ... endN}}end minute of each target episode{p_end}
{synopt:{cmd:duration1 duration2 ... durationN}}duration of each target episode{p_end}
{synopt:{cmd:start_last}}start minute of final target episode in diary{p_end}
{synopt:{cmd:end_last}}end minute of final target episode in diary{p_end}
{synopt:{cmd:duration_last}}duration of final target episode in diary{p_end}
{synoptline}

{pstd}
The number of numbered episode variables depends on the maximum number of target episodes observed in the data.

{title:Why the last-episode variables are useful}

{pstd}
Many activities occur a different number of times across diaries. For example, some people may eat twice, others three or four times.

{pstd}
When the researcher wants the timing of the final occurrence, using {cmd:start_last} is often more useful than using {cmd:start3} or {cmd:start4}, because not all diaries contain the same number of episodes.

{pstd}
Examples include the timing of dinner, the last childcare spell of the day, the last paid work episode, or the final screen-use episode before sleep.

{title:How the command works}

{pstd}
Internally, {cmd:timeallocx} first keeps the identifiers, 
{cmd:start}, {cmd:end}, and the target variable. 
It then uses {help epigenx} to redefine episodes based on the target variable, so that adjacent episodes with the same value of {it:varname} are merged.

{pstd}
After that, the command keeps only episodes where {it:varname}==1 and calculates totals, counts, and timing variables from those episodes.

{pstd}
Finally, it merges those results back with one-row-per-diary background information from the original file.

{title:Dataset after running the command}

{pstd}
After running {cmd:timeallocx}, the dataset is reduced to {bf:one row per diary}.

{pstd}
The variables listed in {opt did()} and the newly created summary variables 
appear first. Other variables originally in the file are retained, although 
episode-level variables are no longer meaningful once the file has been 
collapsed to diary level.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Meal timing}

{pstd}
This example identifies eating episodes and creates diary-level timing measures.

{phang2}{cmd:. use Canada2022, clear}{p_end}
{phang2}{cmd:. gen eating = (ACTIVITY==150)}{p_end}
{phang2}{cmd:. timeallocx eating, did(PUMFID) dst(4)}{p_end}

{pstd}
The resulting variables can then be inspected:

{phang2}{cmd:. list PUMFID total episodes start1 end1 start_last end_last}{p_end}

{marker ex2}{...}
{bf:Example 2: Paid work start times}

{phang2}{cmd:. gen work = inlist(activity,210,211,212)}{p_end}
{phang2}{cmd:. timeallocx work, did(id) dst(4)}{p_end}
{phang2}{cmd:. summarize start1}{p_end}

{pstd}
This gives the average first work-start time across diaries.

{marker ex3}{...}
{bf:Example 3: Last screen use before sleep}

{phang2}{cmd:. gen screen = inlist(activity,610,611)}{p_end}
{phang2}{cmd:. timeallocx screen, did(pid day) dst(4)}{p_end}

{pstd}
Use {cmd:start_last} to study the final screen-use episode of the day.

{title:Interpreting timing variables}

{pstd}
The variables {cmd:start1}, {cmd:end1}, {cmd:start_last}, and similar variables are stored as minutes since the diary start time specified in {opt dst()}.

{pstd}
If {cmd:dst(4)} is used, then 0 corresponds to 04:00, 60 to 05:00, and 120 to 06:00.

{pstd}
Because the command attaches clock-time labels, these timing variables can also be read directly in labeled form inside Stata.

{title:Remarks}

{pstd}
{bf:1. Intended for one binary target at a time}

{pstd}
{cmd:timeallocx} analyses one target variable at a time. If you want outputs for another category, reopen the original episode file and run the command again using a different variable.

{pstd}
{bf:2. Input should normally be coded 0/1}

{pstd}
The command is designed for indicator variables coded 1 for the category of interest and 0 otherwise. It is good practice to create that variable explicitly before running the command.

{pstd}
{bf:3. Diaries with no target activity}

{pstd}
If a diary contains no episodes where {it:varname}==1, {cmd:total} and {cmd:episodes} are set to zero and the timing variables remain missing.

{pstd}
{bf:4. If nobody in the dataset has the target activity}

{pstd}
If there are no episodes with {it:varname}==1 anywhere in the data, the command displays an error message indicating that there is no time in the activity.

{pstd}
{bf:5. Input data should be structurally valid}

{pstd}
The command assumes {cmd:start} and {cmd:end} correctly define episode timing. If the episode file may contain gaps or overlaps, check or repair it before using {cmd:timeallocx}.

{title:Stored results}

{pstd}
{cmd:timeallocx} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help timealloc} for diary-level summaries across all categories of a diary field.

{pstd}
{help epigenx} for redefining episode boundaries in an existing episode file.
