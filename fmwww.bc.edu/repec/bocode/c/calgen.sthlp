{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:calgen} {hline 2} Convert an episode-format diary file into calendar format

{title:Syntax}

{p 8 16 2}
{cmd:calgen}{cmd:,} {opt did(varlist)} {opt slotd(#)} [{opt dst(#)}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt slotd(#)}}slot duration in minutes; required{p_end}
{synopt:{opt dst(#)}}diary start hour on a 24-hour clock; optional, default is 4{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:calgen} converts an {bf:episode-format} diary file into a {bf:calendar-format} diary file.

{pstd}
In an episode file, each row represents a continuous spell of time. In a calendar file, each row represents a fixed time slot such as 10 or 15 minutes.

{pstd}
Calendar files are especially useful for studying behaviour by time of day, producing tempograms or chronograms, and analysing activity within fixed windows such as 18:00 to 20:00.

{pstd}
After running {cmd:calgen}, each diary contains one row per time slot.

{title:Required variables}

{phang}
{cmd:start} must exist and contain the start minute of each episode.

{phang}
{cmd:end} must exist and contain the end minute of each episode.

{pstd}
The input data must already be in episode format.

{title:Arguments}

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely.

{phang}
{opt slotd(#)} specifies the desired slot duration in minutes.

{pstd}
Common values are {cmd:10}, {cmd:15}, and {cmd:30}. The slot duration must divide 1440 exactly.

{title:Options}

{phang}
{opt dst(#)} specifies the diary start hour using an integer from 0 to 23.

{pstd}
For example, {cmd:dst(0)} means the diary begins at midnight, {cmd:dst(4)} means it begins at 04:00, and {cmd:dst(18)} means it begins at 18:00.

{pstd}
If omitted, the default is {cmd:dst(4)}.

{title:What the command creates}

{pstd}
{cmd:calgen} creates a calendar-format file with one row per slot and adds the following variables:

{synoptset 22 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:tslot}}slot number within diary (1 to N){p_end}
{synopt:{cmd:start}}start minute of the slot{p_end}
{synopt:{cmd:end}}end minute of the slot{p_end}
{synoptline}

{pstd}
The number of slots per diary depends on the slot duration. For example, {cmd:slotd(10)} creates 144 slots per diary, and {cmd:slotd(15)} creates 96.

{pstd}
Diary fields from the episode file are repeated across the relevant slots.

{title:How the command works}

{pstd}
Each episode is expanded into as many fixed slots as needed to cover its duration.

{pstd}
For example, with {cmd:slotd(10)}, an episode from minute 0 to 30 becomes three rows, while an episode from minute 300 to 360 becomes six rows.

{pstd}
The resulting dataset contains evenly spaced time intervals for every diary.

{title:Checks and warnings}

{pstd}
{cmd:calgen} checks that {cmd:start} and {cmd:end} exist, that {cmd:slotd()} divides 1440 exactly, and that the episode structure is compatible with the requested slot size.

{pstd}
If the slot size is incompatible with the episode structure, review the source file or choose a different slot duration.

{title:Dataset after running the command}

{pstd}
The output becomes a {bf:calendar-format} file with one row per time slot.

{pstd}
For example, 1 diaries with {cmd:slotd(10)} become 144 rows, while a diaries with {cmd:slotd(15)} become 96 rows.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Convert to a 10-minute calendar file}

{phang2}{cmd:. use mtus_hef, clear}{p_end}
{phang2}{cmd:. calgen, did(hldid persid id) slotd(10) dst(4)}{p_end}

{pstd}
Each diary now contains 144 rows.

{marker ex2}{...}
{bf:Example 2: Convert to a 15-minute calendar file}

{phang2}{cmd:. calgen, did(pid day) slotd(15) dst(0)}{p_end}

{pstd}
Each diary now contains 96 rows.

{marker ex3}{...}
{bf:Example 3: Build a tempogram}

{phang2}{cmd:. calgen, did(id) slotd(10)}{p_end}
{phang2}{cmd:. gen work = (activity==2)}{p_end}
{phang2}{cmd:. collapse (mean) work, by(start)}{p_end}

{pstd}
The resulting series can then be graphed across the day.

{marker ex4}{...}
{bf:Example 4: Analyse an evening window}

{phang2}{cmd:. calgen, did(id) slotd(10)}{p_end}
{phang2}{cmd:. keep if inrange(start, 840, 960)}{p_end}

{pstd}
This keeps slots between 18:00 and 20:00.

{title:Remarks}

{pstd}
{bf:1. Choose slot size carefully}

{pstd}
Use the slot duration closest to the original diary instrument when possible. Very coarse slots may lose detail, while very fine slots may create unnecessarily large files.

{pstd}
{bf:2. Calendar files are often larger}

{pstd}
Episode files are compact. Calendar files usually contain many more rows because each diary is repeated across all slots.

{pstd}
{bf:3. Calendar format is useful for timing analysis}

{pstd}
Calendar format is often the easiest structure for studying behaviour at specific moments of the day.

{pstd}
{bf:4. Use {help epigen} to reverse the process}

{pstd}
If you later want to reconstruct episodes from a calendar file, use {help epigen}.

{pstd}
{bf:5. Slot boundaries matter}

{pstd}
Results for narrow time windows depend on the slot size chosen. Smaller slots give more precise timing.

{title:Stored results}

{pstd}
{cmd:calgen} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epigen} to convert calendar files into episode files.

{pstd}
{help timealloc} for diary-level summaries from episode files.
