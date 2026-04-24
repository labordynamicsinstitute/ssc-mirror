{smcl}
{* *! version 1.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:whattime} {hline 2} Convert a minute-of-day value into clock time

{title:Syntax}

{p 8 16 2}
{cmd:whattime} {it:minute}{cmd:,} {opt dst(string)}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:minute}}minute-of-day value to be converted{p_end}
{synopt:{opt dst(string)}}diary start time, written as {cmd:HH:MM}; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:whattime} converts a {bf:minute-of-day} value into a readable clock time such as {cmd:18:30} or {cmd:07:45}.

{pstd}
This is useful when working with timing variables such as {cmd:start}, {cmd:end}, {cmd:start1}, or {cmd:start_last}, which are often stored as minutes relative to the start of the diary.

{pstd}
The displayed clock time depends on the diary start time given in {opt dst()}.

{title:Arguments}

{phang}
{it:minute} is the minute-of-day value to convert.

{phang}
{opt dst(string)} specifies the diary start time, written in {cmd:HH:MM} format.

{title:Important note on {cmd:dst()}}

{pstd}
In this command, {opt dst()} must be written as a {bf:clock string}, for example:

{phang2}{cmd:dst(04:00)}{p_end}
{phang2}{cmd:dst(00:00)}{p_end}

{pstd}
This differs from several other commands in the toolkit, where diary start time is given as an integer hour such as {cmd:dst(4)}.

{pstd}
Be careful: writing {cmd:dst(4)} here is not the same thing and may lead to errors.

{title:How the command works}

{pstd}
{cmd:whattime} adds the supplied minute value to the diary start time and displays the corresponding clock time.

{pstd}
This makes it easy to interpret minute-based timing variables in familiar clock notation.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Convert a minute value in a diary starting at 04:00}

{phang2}{cmd:. whattime 870, dst(04:00)}{p_end}

{pstd}
This displays the clock time corresponding to minute 870 in a diary that starts at 04:00.

{marker ex2}{...}
{bf:Example 2: Convert midnight-based minute values}

{phang2}{cmd:. whattime 90, dst(00:00)}{p_end}

{pstd}
This displays the clock time corresponding to 90 minutes after midnight.

{title:Remarks}

{pstd}
{bf:1. Use the same diary start convention as the source data}

{pstd}
To interpret a minute value correctly, {cmd:dst()} must match the diary design used when the minute variable was created.

{pstd}
{bf:2. Useful for interpretation}

{pstd}
This command is especially helpful when reading outputs from episode-based or diary-level timing variables.

{pstd}
{bf:3. Companion command}

{pstd}
Use {help whatmin} for the reverse operation: converting a clock time into minute-of-day format.

{title:Stored results}

{pstd}
{cmd:whattime} does not store results in {cmd:r()} or {cmd:e()}. It displays the converted clock time in the Results window.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help whatmin} for converting clock times into minute-of-day values.
