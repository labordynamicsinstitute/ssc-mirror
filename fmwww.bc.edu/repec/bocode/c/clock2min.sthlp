{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:clock2min} {hline 2} Convert clock-style time variables into minute-of-day {cmd:start} and {cmd:end}

{title:Syntax}

{p 8 16 2}
{cmd:clock2min} {it:var1} [{it:var2}]{cmd:,} {opt did(varlist)} {opt dst(#)} {opt clockt(type)}

{pstd}
where {it:var1} is the clock-style start-time variable and {it:var2}, if supplied, is the clock-style end-time variable.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt dst(#)}}diary start hour on a 24-hour clock (0 to 23); required{p_end}
{synopt:{opt clockt(type)}}format of the input clock strings: {cmd:h}, {cmd:hm}, or {cmd:hms}; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:clock2min} creates the variables {cmd:start} and {cmd:end} in the minute-of-day format used by the time-use commands in this toolkit.

{pstd}
Many diary datasets store times as strings such as {cmd:"11:30"}, {cmd:"04:00:00"}, or {cmd:"7"}. {cmd:clock2min} converts those clock-style variables into numeric minutes measured relative to the diary start time.

{pstd}
This command is especially useful when preparing data for commands such as {help epigen}, {help epigenx}, {help timealloc}, {help timeallocx}, or {help epicheck}.

{pstd}
The command is a wrapper around Stata's built-in date-time conversion functions.

{title:Required variables}

{phang}
The dataset must contain the variables supplied as {it:var1} and, if used, {it:var2}.

{pstd}
The data should be sorted or sortable by the diary identifiers in {opt did()} and by episode order if {it:var2} is omitted.

{title:Arguments}

{phang}
{it:var1} is a string variable containing the {bf:start time} of each episode in clock format.

{pstd}
Examples:

{phang2}{cmd:"04"}{p_end}
{phang2}{cmd:"04:30"}{p_end}
{phang2}{cmd:"04:30:15"}{p_end}

{phang}
{it:var2}, if supplied, is a string variable containing the {bf:end time} of each episode in the same clock format.

{pstd}
If {it:var2} is omitted, {cmd:end} is inferred from the start time of the following episode within diary. The final episode of each diary is assigned {cmd:end = 1440}.

{title:Options}

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely.

{phang}
{opt dst(#)} specifies the diary start hour using an integer from 0 to 23.

{pstd}
Examples:

{phang2}{cmd:dst(0)} = diary begins at midnight{p_end}
{phang2}{cmd:dst(4)} = diary begins at 04:00{p_end}
{phang2}{cmd:dst(18)} = diary begins at 18:00{p_end}

{pstd}
Minute values are measured relative to this diary start time.

{phang}
{opt clockt(type)} specifies the format of the input clock variables.

{pstd}
Allowed values are:

{phang2}{cmd:h} = hours only (for example {cmd:"04"}){p_end}
{phang2}{cmd:hm} = hours and minutes (for example {cmd:"04:30"}){p_end}
{phang2}{cmd:hms} = hours, minutes, and seconds (for example {cmd:"04:30:15"}){p_end}

{title:What the command creates}

{pstd}
{cmd:clock2min} creates:

{synoptset 18 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:start}}episode start time in minute-of-day format{p_end}
{synopt:{cmd:end}}episode end time in minute-of-day format{p_end}
{synoptline}

{pstd}
The created variables receive readable clock-time value labels.

{title:How minute-of-day works}

{pstd}
Minute-of-day values are measured from the diary start time given in {opt dst()}.

{pstd}
For example, with {cmd:dst(4)}:

{phang2}{cmd:start = 0} means 04:00{p_end}
{phang2}{cmd:start = 60} means 05:00{p_end}
{phang2}{cmd:start = 120} means 06:00{p_end}

{pstd}
With {cmd:dst(0)}, minute 0 corresponds to midnight.

{title:How the command works}

{pstd}
{cmd:clock2min} converts the supplied clock strings into internal clock times, adjusts them relative to the diary start time, and expresses the result as minutes from 0 to 1440.

{pstd}
If an observed clock time occurs earlier than the diary start hour, it is treated as belonging to the {bf:following calendar day}. This allows diaries that cross midnight to be handled correctly.

{pstd}
When {it:var2} is omitted, the command calculates {cmd:end} using the next episode's {cmd:start} time within each diary.

{title:Checks and warnings}

{pstd}
{cmd:clock2min} checks that:

{phang2}
- one or two variables have been supplied{break}
- {cmd:dst()} is between 0 and 23{break}
- {cmd:clockt()} is one of {cmd:h}, {cmd:hm}, or {cmd:hms}

{pstd}
If invalid values are supplied, the command stops with an error message.

{title:Dataset after running the command}

{pstd}
The dataset remains in its original structure. No observations are added or removed.

{pstd}
The command simply adds or replaces the variables {cmd:start} and {cmd:end}.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Start and end stored separately}

{phang2}{cmd:. use us2020, clear}{p_end}
{phang2}{cmd:. clock2min tustarttim tustoptime, did(tucaseid) dst(4) clockt(hms)}{p_end}

{pstd}
This creates {cmd:start} and {cmd:end} using two clock variables.

{marker ex2}{...}
{bf:Example 2: Only start times available}

{phang2}{cmd:. clock2min clock_start, did(id) dst(4) clockt(hm)}{p_end}

{pstd}
Here {cmd:end} is inferred from the next episode's start time, and the last episode ends at 1440.

{marker ex3}{...}
{bf:Example 3: Diary begins at midnight}

{phang2}{cmd:. clock2min stime etime, did(pid day) dst(0) clockt(hm)}{p_end}

{marker ex4}{...}
{bf:Example 4: Inspect created values}

{phang2}{cmd:. list tustarttim start tustoptime end in 1/5}{p_end}
{phang2}{cmd:. list tustarttim start tustoptime end in 1/5, nolabel}{p_end}

{pstd}
The first display shows clock labels; the second shows raw numeric minutes.

{title:Remarks}

{pstd}
{bf:1. Use the correct clock format}

{pstd}
Choose {cmd:clockt(h)}, {cmd:clockt(hm)}, or {cmd:clockt(hms)} to match the stored strings exactly.

{pstd}
{bf:2. Two-variable input is preferable when available}

{pstd}
If end times are explicitly recorded, supplying both variables is usually preferable to inferring {cmd:end}.

{pstd}
{bf:3. Midnight crossing is handled automatically}

{pstd}
Times earlier than the diary start hour are treated as next-day times.

{pstd}
{bf:4. Check sorting when inferring end times}

{pstd}
If only one variable is supplied, ensure observations are correctly ordered within diary before running the command.

{pstd}
{bf:5. Useful first step in harmonisation}

{pstd}
Many raw diary files need {cmd:start}/{cmd:end} before other commands can be used. {cmd:clock2min} is often the first preparation step.

{title:Stored results}

{pstd}
{cmd:clock2min} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the created variables.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epigen} to create episodes from slot-based calendar files.

{pstd}
{help timealloc} for diary-level summaries once {cmd:start} and {cmd:end} exist.
