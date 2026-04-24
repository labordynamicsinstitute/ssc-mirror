{smcl}
{* *! version 3.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:timealloc} {hline 2} Create diary-level time-allocation variables from episode data

{title:Syntax}

{p 8 16 2}
{cmd:timealloc} {it:varlist}{cmd:,} {opt did(varlist)} [{opt shares(string)}]

{pstd}
where {it:varlist} contains {bf:1 to 6 numeric categorical diary fields}.

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt did(varlist)}}variables that uniquely identify each diary; required{p_end}
{synopt:{opt shares(string)}}custom proportions used to split episode duration across supplied variables; optional{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:timealloc} converts an {bf:episode-level} diary dataset into a {bf:diary-level} dataset with one row per diary.

{pstd}
For each category of the first variable in {it:varlist}, the command creates variables showing how much time the diarist spent in that category during the day. If only one diary field is supplied, {cmd:timealloc} also creates variables counting 
how many episodes fall into each category.

{pstd}
This command is especially useful when researchers want a diary-level file summarising time spent in categories such as activities, locations, or co-presence states.

{pstd}
You may supply up to six diary fields. When more than one variable is supplied, the first is treated as the primary field, and the others are treated as secondary, tertiary, and so on. This makes it possible to allocate time across simultaneous activities rather than relying only on the primary activity.

{pstd}
By default, when more than one variable is supplied, episode duration is divided equally across all nonmissing supplied variables within the episode. Alternatively, the {opt shares()} option may be used to assign a custom split.

{pstd}
After creating the diary-level variables, {cmd:timealloc} reports whether the generated time-allocation variables sum to {bf:1440 minutes}. If they do not, this usually means that the diary field being summarised contains missing or unclassified values.

{title:Required variables}

{phang}
{cmd:start} must be present in the data and must record the start minute of each episode.

{phang}
{cmd:end} must be present in the data and must record the end minute of each episode.

{pstd}
Episode duration is calculated as {cmd:end - start}.

{title:Arguments}

{phang}
{it:varlist} specifies one to six {bf:numeric categorical} diary fields whose categories define the dimension over which time will be allocated. These might include activity variables, location variables, or co-presence variables. Value labels are strongly recommended, because they are used in the labels of the generated output variables when available.

{phang}
{opt did(varlist)} specifies one or more variables that, taken together, uniquely identify a diary. These variables may be numeric or string.

{title:Options}

{phang}
{opt shares(string)} specifies how episode duration should be split across the supplied variables when more than one variable appears in {it:varlist}.

{pstd}
In practice, users should provide a list of percentages, one for each supplied variable. The number of values in {opt shares()} must match the number of variables in {it:varlist}. Values must be between 0 and 100 and must sum to 100.

{pstd}
For example:

{phang2}
{cmd:timealloc main sec, did(hldid persid id) shares(90 10)}

{pstd}
assigns 90% of each episode's duration to the first variable and 10% to the second, after ignoring missing activity slots within the episode and rescaling among the activities that are actually present.

{pstd}
If only one variable is supplied, {opt shares()} is ignored.

{title:What the command creates}

{pstd}
Suppose the first variable in {it:varlist} is {cmd:main4}, and it contains categories 1 through 4.

{pstd}
Then {cmd:timealloc} creates:

{phang2}
{cmd:main4_1} to {cmd:main4_4} {hline 2} minutes per day spent in each category

{pstd}
If only one variable was supplied, it also creates:

{phang2}
{cmd:main4_1_n} to {cmd:main4_4_n} {hline 2} number of episodes in each category

{pstd}
When value labels are attached to the variable, they are used in the variable labels of the generated outputs.

{title:How simultaneous activities are handled}

{pstd}
When more than one variable is supplied, {cmd:timealloc} first redistributes each episode's duration across the nonmissing supplied variables.

{pstd}
By default, this split is equal. For example, if an episode has both a primary and a secondary activity, each receives half of the episode duration.

{pstd}
If {opt shares()} is used, the split follows the proportions provided by the user. If some later activity variables are missing in a particular episode, the specified shares are rescaled across the activities that are actually present in that episode.

{pstd}
Because episode counts become hard to interpret when one episode contributes time to several simultaneous activities, {cmd:timealloc} does {bf:not} create count variables when more than one diary field is supplied.

{title:Automatic correction of gapped activity fields}

{pstd}
If multiple activity variables are supplied and an episode contains a missing earlier field but a nonmissing later field, {cmd:timealloc} shifts the valid later values left so that the first supplied activity field is nonmissing whenever possible.

{pstd}
For example, if the first activity variable is missing but the second contains a valid code, the second activity will be moved into the first position. When this happens, the command displays a note in the Results window.

{pstd}
This behavior is intended to make simultaneous-activity fields easier to use when they contain internal gaps.

{title:Dataset after running the command}

{pstd}
After running {cmd:timealloc}, the data are reduced to {bf:one row per diary}.

{pstd}
The identifier variables specified in {opt did()} and the newly created diary-level summary variables are placed first in the dataset. Other variables originally present in the file are preserved, although episode-level variables are no longer meaningful once the data have been converted to diary level.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Primary activity only}

{pstd}
This example allocates time using only the primary activity field. Because only one variable is supplied, both minutes-per-day variables and episode-count variables are created.

{phang2}{cmd:. use MTUS_hef, clear}{p_end}
{phang2}{cmd:. m69tom4 main, gen(main4)}{p_end}
{phang2}{cmd:. timealloc main4, did(hldid persid id)}{p_end}

{marker ex2}{...}
{bf:Example 2: Primary and secondary activities, equal split}

{pstd}
This example uses both primary and secondary activities. Because no {opt shares()} option is specified, each episode's duration is divided equally across the nonmissing supplied activities.

{phang2}{cmd:. use MTUS_hef, clear}{p_end}
{phang2}{cmd:. m69tom4 main, gen(main4)}{p_end}
{phang2}{cmd:. m69tom4 sec, gen(sec4)}{p_end}
{phang2}{cmd:. timealloc main4 sec4, did(hldid persid id)}{p_end}

{marker ex3}{...}
{bf:Example 3: Primary and secondary activities, custom split}

{pstd}
This example gives greater weight to the primary activity than to the secondary one.

{phang2}{cmd:. use MTUS_hef, clear}{p_end}
{phang2}{cmd:. m69tom4 main, gen(main4)}{p_end}
{phang2}{cmd:. m69tom4 sec, gen(sec4)}{p_end}
{phang2}{cmd:. timealloc main4 sec4, did(hldid persid id) shares(90 10)}{p_end}

{title:Remarks}

{pstd}
{bf:1. Missing values and the 1440-minute check}

{pstd}
If the generated minute variables do not sum to 1440, this usually means that the first supplied diary field contains missing or uncoded values. This is not necessarily an error, but users who want complete daily totals should recode those values before running {cmd:timealloc}.

{pstd}
{bf:2. Counts are only created with one diary field}

{pstd}
Episode counts are created only when a single variable is supplied. This is intentional: once one episode is split across several simultaneous activities, the meaning of “number of episodes” becomes ambiguous.

{pstd}
{bf:3. Output variable names are based on the first supplied variable}

{pstd}
Even when several diary fields are supplied, the created output variables are named using the first variable in {it:varlist}. This first variable acts as the common activity field after simultaneous activities have been redistributed.

{pstd}
{bf:4. Input data should be structurally sound}

{pstd}
{cmd:timealloc} assumes that {cmd:start} and {cmd:end} correctly describe episode timing. If the input file may contain gaps, overlaps, or other episode-structure problems, it is good practice to check and fix the 
episode file before using {cmd:timealloc}.

{title:Stored results}

{pstd}
{cmd:timealloc} does not store results in {cmd:r()} or {cmd:e()}. Its results are returned through the transformed dataset.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
Related commands in the same toolkit may include commands used to check, reshape, or repair episode-level diary files before diary-level summaries are created.
