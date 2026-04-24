{smcl}
{* *! version 1.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:whatmin} {hline 2} Convert a clock time into minute-of-day format

{title:Syntax}

{p 8 16 2}
{cmd:whatmin} {it:clocktime}{cmd:,} {opt dst(string)}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:clocktime}}clock time to be converted, written as {cmd:HH:MM}{p_end}
{synopt:{opt dst(string)}}diary start time, written as {cmd:HH:MM}; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:whatmin} converts a clock time such as {cmd:18:30} or {cmd:07:45} into the {bf:minute-of-day} format used by the time-use commands in this toolkit.

{pstd}
The returned value is expressed relative to the diary start time given in {opt dst()}.

{pstd}
This is useful when you want to know what minute value corresponds to a given clock time, for example when defining time windows or checking timing variables.

{title:Arguments}

{phang}
{it:clocktime} is the clock time to convert, written in {cmd:HH:MM} format.

{phang}
{opt dst(string)} specifies the diary start time, also written in {cmd:HH:MM} format.

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
{cmd:whatmin} compares the supplied clock time to the diary start time and returns the number of minutes since the diary began.

{pstd}
If the clock time is earlier than the diary start time, it is treated as belonging to the following calendar day.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Convert an evening time in a diary starting at 04:00}

{phang2}{cmd:. whatmin 18:30, dst(04:00)}{p_end}

{pstd}
This returns the minute value corresponding to 18:30 in a diary that starts at 04:00.

{marker ex2}{...}
{bf:Example 2: Convert a time after midnight}

{phang2}{cmd:. whatmin 01:00, dst(04:00)}{p_end}

{pstd}
Because 01:00 is earlier than 04:00, it is treated as the following day.

{title:Remarks}

{pstd}
{bf:1. Use {cmd:HH:MM} format}

{pstd}
Both the target time and {cmd:dst()} should be written in standard clock format such as {cmd:04:00} or {cmd:18:30}.

{pstd}
{bf:2. Useful for defining time windows}

{pstd}
This command is handy when you want to translate clock times into minute cutoffs for data work.

{pstd}
{bf:3. Companion command}

{pstd}
Use {help whattime} for the reverse operation: converting a minute-of-day value back into a clock time.

{title:Stored results}

{pstd}
{cmd:whatmin} does not store results in {cmd:r()} or {cmd:e()}. It displays the converted minute value in the Results window.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help whattime} for converting minute-of-day values back into clock time.
