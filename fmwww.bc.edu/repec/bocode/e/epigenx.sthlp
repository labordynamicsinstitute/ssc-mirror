{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:epigenx} {hline 2} Redefine an existing episode file using different episode boundaries

{title:Syntax}

{p 8 16 2}
{cmd:epigenx} {it:varlist}{cmd:,} {opt did(varlist)} [{opt dst(#)} {opt nolabel}]

{pstd}
where {it:varlist} contains the variables that should define the new episodes.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt dst(#)}}diary start hour on a 24-hour clock; required unless {cmd:nolabel} is used{p_end}
{synopt:{opt nolabel}}do not create clock-time labels or {cmd:clockst}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:epigenx} takes a dataset that is {bf:already in episode format} and creates a {bf:new episode file} using different episode boundaries.

{pstd}
A new episode is created whenever any variable listed in {it:varlist} changes value.

{pstd}
This is useful when an existing episode file is defined using many dimensions, but your research question focuses on only one or a few of them.

{pstd}
For example:

{pmore}
- redefine episodes using only {cmd:location} to study mobility  
- redefine episodes using only {cmd:Enjoy} to study mood changes across the day  
- redefine episodes using only {cmd:activity} to simplify a complex file  
- redefine episodes using {cmd:activity location} to retain both dimensions

{pstd}
In short:

{pmore}
{help epigen} = calendar file to episode file  
{cmd:epigenx} = episode file to a different episode file

{title:Required variables}

{phang}
{cmd:start} must exist and contain the start minute of each episode.

{phang}
{cmd:end} must exist and contain the end minute of each episode.

{pstd}
The file should already contain one row per episode.

{title:Arguments}

{phang}
{it:varlist} specifies the variables that define the new episodes. Consecutive existing episodes are merged whenever all supplied variables remain unchanged.

{pstd}
Variables in {it:varlist} may be numeric or string.

{pstd}
The current version allows up to {bf:20} variables in {it:varlist}.

{phang}
{opt did(varlist)} specifies one or more variables that jointly identify each diary uniquely. Variables may be numeric or string.

{title:Options}

{phang}
{opt dst(#)} specifies the diary start hour using an integer from 0 to 23.

{pstd}
Examples:

{pmore}
{cmd:dst(0)} = diary begins at midnight  
{cmd:dst(4)} = diary begins at 04:00  
{cmd:dst(18)} = diary begins at 18:00

{pstd}
This option is used to create readable clock labels for {cmd:start} and {cmd:end}, and to generate {cmd:clockst}.

{pstd}
{opt dst()} is required unless {cmd:nolabel} is specified.

{phang}
{opt nolabel} suppresses creation of clock-time labels and suppresses {cmd:clockst}.

{title:What the command creates}

{pstd}
{cmd:epigenx} returns a new episode file with one row per newly defined episode.

{pstd}
It creates or recreates the following variables:

{synoptset 22 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:epnum}}episode number within diary{p_end}
{synopt:{cmd:start}}start minute of episode{p_end}
{synopt:{cmd:end}}end minute of episode{p_end}
{synopt:{cmd:time}}episode duration in minutes ({cmd:end-start}){p_end}
{synopt:{cmd:clockst}}clock-time start variable; omitted with {cmd:nolabel}{p_end}
{synoptline}

{pstd}
The variables listed in {it:varlist} are retained as the defining diary fields of the new file.

{title:How the command works}

{pstd}
Within each diary, {cmd:epigenx} compares consecutive existing episodes.

{pstd}
If all variables in {it:varlist} remain unchanged, adjacent episodes are merged into one longer episode.

{pstd}
If any supplied variable changes, a new episode begins.

{pstd}
This means the resulting file often contains {bf:fewer episodes} than the starting file, especially when simplifying a richly coded sequence file.

{title:Checks and warnings}

{pstd}
{cmd:epigenx} checks that:

{pmore}
- {cmd:start} exists  
- {cmd:end} exists  
- the dataset appears to be in episode format  
- identifier variables are present

{pstd}
If observations contain missing values in any variable listed in {opt did()}, those observations may be dropped after warning messages.

{title:Dataset after running the command}

{pstd}
The output remains an {bf:episode-level} file, but with newly defined episodes.

{pstd}
Variables listed in {opt did()}, timing variables, and the new episode number appear first in the dataset.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Redefine episodes using enjoyment only}

{pstd}
Suppose the original file contains many short episodes, but the goal is to analyse changes in enjoyment across the day.

{phang2}{cmd:. use UK2014, clear}{p_end}
{phang2}{cmd:. gen start = tid*10 - 10}{p_end}
{phang2}{cmd:. gen end   = start + eptime}{p_end}
{phang2}{cmd:. epicheck, did(serial pnum daynum)}{p_end}
{phang2}{cmd:. epigenx Enjoy, did(serial pnum daynum) dst(4)}{p_end}

{pstd}
Adjacent episodes with the same enjoyment score are merged.

{marker ex2}{...}
{bf:Example 2: Redefine episodes using location}

{phang2}{cmd:. epigenx where, did(pid day) dst(4)}{p_end}

{pstd}
Useful for analysing movement between places during the day.

{marker ex3}{...}
{bf:Example 3: Redefine episodes using activity and location}

{phang2}{cmd:. epigenx activity where, did(pid day) dst(4)}{p_end}

{pstd}
A new episode begins when either activity or location changes.

{marker ex4}{...}
{bf:Example 4: Faster numeric-only output}

{phang2}{cmd:. epigenx Enjoy, did(serial pnum daynum) nolabel}{p_end}

{pstd}
Use {cmd:nolabel} when you only need numeric times.

{title:Remarks}

{pstd}
{bf:1. Use when the file is already episodic}

{pstd}
If your starting file is in calendar format (one row per slot), use {help epigen} instead.

{pstd}
{bf:2. Simplification often reduces file size}

{pstd}
If the original file uses many diary dimensions, redefining episodes with fewer variables often greatly reduces the number of rows.

{pstd}
{bf:3. Choose variables based on the research question}

{pstd}
Use only the dimensions relevant to your analysis. For example, mood research may only need enjoyment, while mobility research may only need location.

{pstd}
{bf:4. Consecutive identical episodes are merged}

{pstd}
If the same category reappears later after interruption, it becomes a new episode. Only adjacent episodes with identical values are merged.

{pstd}
{bf:5. {cmd:dst()} affects labels, not episode boundaries}

{pstd}
Episode boundaries come from {cmd:start} and {cmd:end}. The {cmd:dst()} option is used for clock labels and {cmd:clockst}.

{title:Stored results}

{pstd}
{cmd:epigenx} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset.

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
