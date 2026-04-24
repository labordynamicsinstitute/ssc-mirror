{smcl}
{* *! version 1.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:m69tom11} {hline 2} Recode MTUS Main 69 activity categories into 11 broad activity groups

{title:Syntax}

{p 8 16 2}
{cmd:m69tom11} {it:varname}{cmd:,} {opt gen(newvar)}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:varname}}numeric variable coded in the MTUS Main 69 activity scheme{p_end}
{synopt:{opt gen(newvar)}}name of the new recoded variable to create; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:m69tom11} recodes an activity variable from the {bf:MTUS Main 69} scheme into a simplified variable with {bf:11 broad activity groups}.

{pstd}
This is useful when researchers want more detail than a very coarse classification, but less detail than the full 69-category scheme.

{pstd}
The command creates a new variable specified in {opt gen()} and assigns it one of eleven categories. A value label is attached to the generated variable.

{title:Arguments}

{phang}
{it:varname} must be a {bf:numeric} variable coded in the MTUS Main 69 activity scheme.

{phang}
{opt gen(newvar)} specifies the name of the new variable to be created.

{title:How categories are recoded}

{pstd}
The mapping used by {cmd:m69tom11} is:

{synoptset 28 tabbed}{...}
{synopthdr:New category}
{synoptline}
{synopt:{cmd:1 personal care}}original codes 1 to 6{p_end}
{synopt:{cmd:2 paid work}}original codes 7 to 16{p_end}
{synopt:{cmd:3 study}}original code 17{p_end}
{synopt:{cmd:4 household work}}original codes 18 to 25{p_end}
{synopt:{cmd:5 childcare}}original codes 26 to 28{p_end}
{synopt:{cmd:6 shopping/services}}original codes 29 to 32{p_end}
{synopt:{cmd:7 leisure}}original codes 33 to 54{p_end}
{synopt:{cmd:8 sport/outdoor}}original codes 55 to 62{p_end}
{synopt:{cmd:9 travel to work/study}}original codes 63 and 64{p_end}
{synopt:{cmd:10 other travel}}original codes 65 to 68{p_end}
{synopt:{cmd:11 unpaid work other}}original codes 66 and 67{p_end}
{synoptline}

{pstd}
Original code {cmd:69} is recoded to system missing.

{pstd}
If your local version of the ado differs slightly, use the ado file as the definitive mapping.

{title:What the command creates}

{pstd}
{cmd:m69tom11} creates a new numeric variable named in {opt gen()}.

{pstd}
The new variable receives an attached value label corresponding to the eleven groups.

{pstd}
The generated variable also receives a descriptive variable label.

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Recode a Main 69 activity variable}

{phang2}{cmd:. m69tom11 main69, gen(main11)}{p_end}

{pstd}
This creates {cmd:main11}, an eleven-category version of {cmd:main69}.

{marker ex2}{...}
{bf:Example 2: Tabulate the new groups}

{phang2}{cmd:. m69tom11 activity, gen(activity11)}{p_end}
{phang2}{cmd:. tab activity11}{p_end}

{title:Remarks}

{pstd}
{bf:1. Input must be numeric}

{pstd}
The command requires a numeric input variable. If the source variable is stored as a string, convert it before use.

{pstd}
{bf:2. The original variable is not modified}

{pstd}
{cmd:m69tom11} leaves the source variable unchanged and creates a new recoded variable.

{pstd}
{bf:3. Intermediate level of aggregation}

{pstd}
This command is useful when the 4-group version is too coarse but the full 69-group version is unnecessarily detailed.

{pstd}
{bf:4. Code 69 becomes missing}

{pstd}
Original code 69 is recoded to system missing in the generated variable.

{title:Stored results}

{pstd}
{cmd:m69tom11} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the created variable.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
{help m69tom4} for a coarser 4-group version of the same scheme.
