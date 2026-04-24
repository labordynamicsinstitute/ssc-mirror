{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:epigen} {hline 2} Create an episode file from a calendar-format diary file

{title:Syntax}

{p 8 16 2}
{cmd:epigen} {it:varlist}{cmd:,} {opt did(varlist)} [{opt dst(#)} {opt nolabel}]

{pstd}
where {it:varlist} contains the diary fields that define when a new episode begins.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variable(s) that uniquely identify each diary; required{p_end}
{synopt:{opt dst(#)}}diary start hour on a 24-hour clock; required unless {cmd:nolabel} is specified{p_end}
{synopt:{opt nolabel}}do not create clock-time labels or {cmd:clockst}{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:epigen} converts a {bf:calendar-format} diary file into an {bf:episode-format} diary file.

{pstd}
In a calendar file, each row usually represents one fixed time slot, such as 10 minutes. In an episode file, consecutive time slots with the same values on selected diary fields are merged into a single episode.

{pstd}
A new episode is created whenever there is a change in one or more of the variables supplied in {it:varlist}.

{pstd}
This is useful because episode files are typically more compact and are needed by several downstream commands, including {help timealloc}.

{pstd}
If you are unsure which diary fields you may need later, a good strategy is to first build 
a detailed episode file using all available diary fields. You can then simplify or 
redefine episodes later if needed.

{title:Required variables}

{phang}
{cmd:tslot} must exist in the data, must be numeric, and must indicate the order of time slots within each diary.

{pstd}
For example, in a diary with 144 ten-minute slots, {cmd:tslot} should run from 1 to 144 within each diary.

{pstd}
If {cmd:tslot} is not present, but the observations are already correctly ordered within diary, create it before running {cmd:epigen}.

{title:Arguments}

{phang}
{it:varlist} specifies the diary fields that define the episodes. A new episode is created whenever any of these variables changes value from one slot to the next.

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

{phang2}{cmd:dst(0)} = diary begins at midnight{p_end}
{phang2}{cmd:dst(4)} = diary begins at 04:00{p_end}
{phang2}{cmd:dst(18)} = diary begins at 18:00{p_end}

{pstd}
This option is used to create readable clock-time labels for {cmd:start} and {cmd:end}, and to create the variable {cmd:clockst}.

{pstd}
If {cmd:nolabel} is not specified, then {cmd:dst()} is required.

{phang}
{opt nolabel} suppresses creation of clock-time labels and suppresses the variable {cmd:clockst}.

{pstd}
This is useful when you only need numeric start and end times.

{title:What the command creates}

{pstd}
{cmd:epigen} creates one row per episode and adds the following variables:

{synoptset 22 tabbed}{...}
{synopthdr:Output}
{synoptline}
{synopt:{cmd:epnum}}episode number within diary{p_end}
{synopt:{cmd:start}}start minute of episode, from 0 to 1439{p_end}
{synopt:{cmd:end}}end minute of episode, from 1 to 1440{p_end}
{synopt:{cmd:time}}episode duration in minutes{p_end}
{synopt:{cmd:clockst}}start time on a 24-hour clock; created unless {cmd:nolabel} is used{p_end}
{synoptline}

{pstd}
The diary fields supplied in {it:varlist} are retained in the resulting episode file.

{title:How episode boundaries are defined}

{pstd}
Within each diary, {cmd:epigen} compares consecutive time slots across the variables in {it:varlist}. Consecutive slots are merged into the same episode only if {bf:all} supplied variables remain unchanged.

{pstd}
A new episode begins as soon as at least one of those variables changes.

{pstd}
This means that the level of detail in the final episode file depends directly on the variables you include in {it:varlist}.

{pstd}
For example, using only {cmd:activity} usually gives broader episodes, while using {cmd:activity location alone} usually gives more detailed episodes.

{title:How timing is calculated}

{pstd}
{cmd:epigen} determines the expected number of slots per diary by taking the median of the maximum observed {cmd:tslot} values across diaries. It then calculates slot duration as:

{phang2}{cmd:1440 / number of slots}{p_end}

{pstd}
For example, if diaries typically contain 144 slots, slot duration is treated as 10 minutes.

{pstd}
Then:

{phang2}{cmd:start = tslot*slotdur - slotdur}{p_end}
{phang2}{cmd:end = next episode's start}{p_end}
{phang2}{cmd:time = end - start}{p_end}

{pstd}
For the last episode in a diary, {cmd:end} is set to 1440.

{title:Checks and warnings}

{pstd}
Before creating episodes, {cmd:epigen} checks that {cmd:tslot} exists and is numeric.

{pstd}
If {cmd:nolabel} is not specified, it also checks that {cmd:dst()} has been supplied and that its value is between 0 and 23.

{pstd}
The command warns if any observations have missing values in the variables listed in {opt did()}. Those observations are dropped before episodes are created.

{pstd}
The command also runs {cmd:tslotcheck, quiet} internally.

{title:Dataset after running the command}

{pstd}
After running {cmd:epigen}, the file is reduced from one row per time slot to one row per episode.

{pstd}
The output is ordered so that the diary identifiers and newly created episode variables come first, followed by the diary fields used to define episodes.

{pstd}
The original variable {cmd:tslot} is dropped from the final dataset.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Create episodes using one diary field}

{pstd}
This creates a new episode each time the activity changes.

{phang2}{cmd:. epigen activity, did(uid day) dst(4)}{p_end}

{marker ex2}{...}
{bf:Example 2: Create episodes using several diary fields}

{pstd}
This creates a new episode whenever any of the supplied diary fields changes.

{phang2}{cmd:. epigen activity location alone, did(uid day) dst(4)}{p_end}

{marker ex3}{...}
{bf:Example 3: Skip clock labels}

{pstd}
Use {cmd:nolabel} if you do not need labeled times or {cmd:clockst}.

{phang2}{cmd:. epigen activity location, did(uid day) nolabel}{p_end}

{marker ex4}{...}
{bf:Example 4: Calendar file begins at midnight but diary starts at 4 a.m.}

{pstd}
Suppose the file is ordered from 00:00 onward, but the diary day actually begins at 04:00. In that case, first rebuild {cmd:tslot} so that slot 1 corresponds to 04:00, then run {cmd:epigen}.

{phang2}{cmd:. bysort uid ad4: gen xtslot = _n}{p_end}
{phang2}{cmd:. gen tslot = xtslot - 24 if xtslot >= 25}{p_end}
{phang2}{cmd:. replace tslot = 120 + xtslot if xtslot < 25}{p_end}
{phang2}{cmd:. tslotcheck, did(uid ad4)}{p_end}
{phang2}{cmd:. sort uid ad4 tslot}{p_end}
{phang2}{cmd:. epigen activity activity2 transport alone partner parent kids, did(uid ad4) dst(4)}{p_end}

{title:Remarks}

{pstd}
{bf:1. Choose episode-defining variables carefully}

{pstd}
The more variables you include in {it:varlist}, the more episodes you will usually create. Even small changes in any included field will split an episode.

{pstd}
{bf:2. Start with a rich episode file if unsure}

{pstd}
If you are uncertain which diary fields will matter later, it is often safer to build a detailed episode file first and simplify later if needed.

{pstd}
{bf:3. Slot ordering must be correct}

{pstd}
{cmd:epigen} assumes that {cmd:tslot} correctly represents the within-diary order of the time slots. If {cmd:tslot} is wrong, the resulting episodes will also be wrong.

{pstd}
{bf:4. {cmd:dst()} affects labels, not episode boundaries}

{pstd}
Episode boundaries are determined by {cmd:tslot} and the variables in {it:varlist}. The {cmd:dst()} option is used only to label times and create {cmd:clockst}.

{pstd}
{bf:5. Input file should contain complete slot sequences}

{pstd}
Because slot duration is inferred from the diary structure, it is good practice to check the calendar file first and confirm that diaries have the expected number of slots.

{title:Stored results}

{pstd}
{cmd:epigen} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the transformed dataset.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help epigenx} to redefine an existing episode file using different episode boundaries.

{pstd}
{help timealloc} for diary-level summaries from episode files.
