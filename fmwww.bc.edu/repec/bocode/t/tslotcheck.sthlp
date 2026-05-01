{smcl}
{* *! version 3.0.0 30 Apr 2026}{...}

{title:Title}

{pstd}
{hi:tslotcheck} {hline 2} Check time-slot completeness and consistency in calendar-format diary files

{title:Syntax}

{p 8 16 2}
{cmd:tslotcheck}{cmd:,} {opt did(varlist)} [{opt quiet}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt quiet}}suppress the success message when no problems are detected{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:tslotcheck} checks whether a calendar-format diary file contains a complete and internally consistent sequence of time slots within each diary.

{pstd}
The command is intended for files in which each row represents one fixed time interval, such as a 10-minute, 15-minute, 30-minute, or 60-minute slot. It is especially useful before running {help epigen}, which converts calendar files into episode files and assumes that {cmd:tslot} correctly represents the order of time slots within each diary.

{pstd}
{cmd:tslotcheck} checks three types of problems: duplicate time slots within diary, time-slot values outside the expected range, and diaries with an unexpected number of rows. It then creates a diary-level flag indicating whether each diary has any detected issue.

{title:Required variables}

{phang}
{cmd:tslot} must exist in the data and must be numeric. It should indicate the order of time slots within each diary.

{pstd}
For example, in a diary with 144 ten-minute slots, {cmd:tslot} should normally run from 1 to 144 within each diary.

{title:Arguments}

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely. Variables may be numeric or string.

{title:Options}

{phang}
{opt quiet} suppresses the success message when all diaries appear to have the expected number of slots. If problems are detected, a warning is still displayed.

{title:How the expected number of slots is determined}

{pstd}
{cmd:tslotcheck} determines the expected number of slots by first finding the maximum value of {cmd:tslot} within each diary and then taking the median of those diary-level maxima.

{pstd}
This means that the command does not require the user to specify the expected number of slots directly. In a standard 10-minute diary, the inferred number will usually be 144; in a 30-minute diary, it will usually be 48; and in a 60-minute diary, it will usually be 24.

{title:Checks performed}

{pstd}
The command checks for the following problems:

{synoptset 22 tabbed}{...}
{synopthdr:Problem code}
{synoptline}
{synopt:{cmd:1}}duplicate {cmd:tslot} values within diary{p_end}
{synopt:{cmd:2}}out-of-range {cmd:tslot} values, i.e. below 1 or above the expected maximum{p_end}
{synopt:{cmd:3}}diary has an unexpected number of rows/slots{p_end}
{synoptline}

{pstd}
The command records the first applicable problem found for each observation in {cmd:problem_case}. The diary-level variable {cmd:problem_diary} is then set to 1 for diaries with at least one detected issue and 0 otherwise.

{title:What the command creates}

{pstd}
{cmd:tslotcheck} creates or replaces the following variables:

{synoptset 22 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:problem_case}}observation-level problem code; missing when no issue is detected for that row{p_end}
{synopt:{cmd:problem_diary}}diary-level flag: 0 = OK diary, 1 = diary has issues{p_end}
{synoptline}

{pstd}
The command also creates an internal grouped diary identifier, {cmd:__udid}. In normal use this variable can be ignored; users may drop it after checking the output if they do not need it.

{title:Output in the Results window}

{pstd}
If no problems are detected and {opt quiet} is not specified, the command displays a message such as:

{phang2}{cmd:All diaries have the expected number of time slots (144).}{p_end}

{pstd}
If problems are detected, the command displays a warning and lists the number and percentage of diaries with and without issues.

{title:Dataset after running the command}

{pstd}
{cmd:tslotcheck} does not collapse, reshape, or otherwise change the structure of the data. The original rows remain in place. The command only adds diagnostic variables and replaces any previous variables named {cmd:problem_case} or {cmd:problem_diary}.

{pstd}
Because the command is diagnostic, it does not fix duplicated, missing, or out-of-range time slots. If problems are detected, users should inspect and correct them before running {help epigen}.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Check a standard calendar file}

{pstd}
This checks whether each diary identified by {cmd:uid} and {cmd:day} has the expected sequence of time slots.

{phang2}{cmd:. tslotcheck, did(uid day)}{p_end}

{marker ex2}{...}
{bf:Example 2: Run quietly before episode creation}

{pstd}
This suppresses the success message if no problems are detected. This is useful inside harmonisation scripts or before running {cmd:epigen}.

{phang2}{cmd:. tslotcheck, did(uid day) quiet}{p_end}
{phang2}{cmd:. epigen activity location, did(uid day) dst(4)}{p_end}

{marker ex3}{...}
{bf:Example 3: Inspect problem diaries}

{pstd}
After running {cmd:tslotcheck}, list diaries where at least one issue was found.

{phang2}{cmd:. tslotcheck, did(uid day)}{p_end}
{phang2}{cmd:. list uid day tslot problem_case if problem_diary == 1, sepby(uid day)}{p_end}

{title:Remarks}

{pstd}
{bf:1. The command assumes {cmd:tslot} is the intended within-diary ordering variable}

{pstd}
If {cmd:tslot} is incorrectly constructed, {cmd:tslotcheck} may identify problems correctly, but it cannot infer the correct order of the diary without additional information.

{pstd}
{bf:2. The expected number of slots is inferred from the data}

{pstd}
Because the expected number of slots is based on the median of the maximum observed {cmd:tslot} values, the command is robust to a small number of incomplete diaries. However, if many diaries are incomplete in the same way, the inferred expected number may be wrong.

{pstd}
{bf:3. The command reports slot-structure problems, not content problems}

{pstd}
{cmd:tslotcheck} does not check whether activity, location, or other diary fields are valid. It only checks whether the time-slot structure appears complete and non-duplicated.

{pstd}
{bf:4. Run before {cmd:epigen}}

{pstd}
It is good practice to run {cmd:tslotcheck} before {help epigen}. If the time-slot sequence is incomplete or duplicated, the episode file created by {cmd:epigen} may have incorrect timing.

{title:Stored results}

{pstd}
{cmd:tslotcheck} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the diagnostic variables created in the dataset.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epigen} to create an episode file from a calendar-format diary file.

{pstd}
{help epicheck} to check structural problems in episode-format diary files.
