

{smcl}
{* *! version 1.0.2 22 Apr 2026}{...}

{title:Title}

{pstd}
{hi:clocklabel} {hline 2} Create a clock-style value label for minute-of-day variables

{title:Syntax}

{p 8 16 2}
{cmd:clocklabel} {it:#}{cmd:,} [{opt name(lblname)} | {opt gen(lblname)}] [{opt replace}]

{pstd}
where {it:#} is the diary start hour, given as an integer from 0 to 23.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:#}}diary start hour on a 24-hour clock, from 0 to 23{p_end}
{synopt:{opt name(lblname)}}name of the value label to create{p_end}
{synopt:{opt gen(lblname)}}alias for {cmd:name()}{p_end}
{synopt:{opt replace}}replace an existing value label with the same name{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:clocklabel} creates a reusable value label that translates {bf:minute-of-day values} into readable clock times.

{pstd}
This is useful for variables such as {cmd:start}, {cmd:end}, {cmd:start1}, {cmd:end_last}, or any other timing variable expressed as minutes from the start of the diary day.

{pstd}
The command does {bf:not} modify any data values and does {bf:not} attach labels to variables automatically. It simply creates a value label, which the user may then apply manually using Stata's {cmd:label values} command.

{title:Arguments}

{phang}
{it:#} specifies the diary start hour using an integer from 0 to 23.

{pstd}
Examples:

{phang2}{cmd:0} = diary begins at midnight{p_end}
{phang2}{cmd:4} = diary begins at 04:00{p_end}
{phang2}{cmd:18} = diary begins at 18:00{p_end}

{title:Options}

{phang}
{opt name(lblname)} specifies the name of the value label to be created.

{phang}
{opt gen(lblname)} is an alias for {cmd:name()}.

{pstd}
Use either {cmd:name()} or {cmd:gen()}, but not both.

{phang}
{opt replace} replaces an existing value label with the same name.

{pstd}
If a label with the chosen name already exists and {cmd:replace} is not specified, the command stops with an error.

{title:How minute-of-day values are interpreted}

{pstd}
Values are interpreted relative to the diary start time.

{pstd}
For example, with a diary start hour of {cmd:4}:

{p2colset 12 24 26 2}{...}
{p2col:0}04:00{p_end}
{p2col:60}05:00{p_end}
{p2col:120}06:00{p_end}
{p2col:600}14:00{p_end}
{p2colreset}{...}

{pstd}
With a diary start hour of {cmd:0}, value 0 corresponds to midnight.

{title:What the command creates}

{pstd}
{cmd:clocklabel} creates a value label with the name supplied in {cmd:name()} or {cmd:gen()}.

{pstd}
The label maps minute values from 0 to 1440 into readable clock times.

{pstd}
Code 0 is defined to display the same clock time as code 1440, corresponding to the diary start time on the next day.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Create a label called myclock}

{phang2}{cmd:. clocklabel 4, name(myclock)}{p_end}

{pstd}
This creates a value label called {cmd:myclock} for diaries that begin at 04:00.

{marker ex2}{...}
{bf:Example 2: Use gen() instead of name()}

{phang2}{cmd:. clocklabel 4, gen(myclock)}{p_end}

{pstd}
This does exactly the same thing as {cmd:name(myclock)}.

{marker ex3}{...}
{bf:Example 3: Attach the label to variables}

{phang2}{cmd:. clocklabel 4, name(myclock)}{p_end}
{phang2}{cmd:. label values start myclock}{p_end}
{phang2}{cmd:. label values end myclock}{p_end}

{marker ex4}{...}
{bf:Example 4: Replace an existing label}

{phang2}{cmd:. clocklabel 0, name(clock0) replace}{p_end}

{title:Remarks}

{pstd}
{bf:1. Label creation only}

{pstd}
This command creates the value label but does not attach it to variables.

{pstd}
{bf:2. Use either {cmd:name()} or {cmd:gen()}}

{pstd}
These options are equivalent. They should not be used together.

{pstd}
{bf:3. Integer hour input}

{pstd}
Unlike {help whatmin} and {help whattime}, this command expects the diary start time as an integer hour such as {cmd:4}, not as a clock string such as {cmd:04:00}.

{pstd}
{bf:4. Reusable across variables}

{pstd}
Once created, the same label can be applied to as many timing variables as needed.

{pstd}
{bf:5. Useful after data construction}

{pstd}
This command is often used after generating timing variables with {help clock2min}, {help epigen}, or {help timeallocx}.

{title:Stored results}

{pstd}
{cmd:clocklabel} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the created value label.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help clock2min} for converting clock strings into minute-of-day variables.

{pstd}
{help whatmin} and {help whattime} for quick conversions between clock times and minute-of-day values.

