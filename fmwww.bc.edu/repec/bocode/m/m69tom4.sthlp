{smcl}
{* *! version 1.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:m69tom4} {hline 2} Recode MTUS Main 69 activity categories into 4 broad activity groups

{title:Syntax}

{p 8 16 2}
{cmd:m69tom4} {it:varname}{cmd:,} {opt gen(newvar)}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:varname}}numeric variable coded in the MTUS Main 69 activity scheme{p_end}
{synopt:{opt gen(newvar)}}name of the new recoded variable to create; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:m69tom4} recodes an activity variable from the {bf:MTUS Main 69} scheme into a simpler variable with {bf:4 broad activity groups}.

{pstd}
This is useful when a more aggregated activity classification is sufficient for descriptive work, figures, or summary analysis.

{pstd}
The command creates a new variable specified in {opt gen()} and assigns it one of four categories:

{phang2}
1 = personal{break}
2 = paid{break}
3 = unpaid{break}
4 = leisure

{pstd}
A value label is attached to the generated variable.

{title:Arguments}

{phang}
{it:varname} must be a {bf:numeric} variable coded in the MTUS Main 69 activity scheme.

{phang}
{opt gen(newvar)} specifies the name of the new variable to be created.

{title:How categories are recoded}

{pstd}
The mapping used by {cmd:m69tom4} is:

{synoptset 22 tabbed}{...}
{synopthdr:New category}
{synoptline}
{synopt:{cmd:1 personal}}original codes 1 to 6{p_end}
{synopt:{cmd:2 paid}}original codes 7 to 16, 63, and 64{p_end}
{synopt:{cmd:3 unpaid}}original codes 18 to 32, 66, and 67{p_end}
{synopt:{cmd:4 leisure}}original code 17, original codes 33 to 62, and codes 65 and 68{p_end}
{synoptline}

{pstd}
Original code {cmd:69} is recoded to system missing.

{title:What the command creates}

{pstd}
{cmd:m69tom4} creates a new numeric variable named in {opt gen()}.

{pstd}
The new variable receives the value label:

{phang2}
1 {hline 2} personal{break}
2 {hline 2} paid{break}
3 {hline 2} unpaid{break}
4 {hline 2} leisure

{pstd}
The generated variable also receives the variable label:

{phang2}
{cmd:4-activity code in MTUS}

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Recode a Main 69 activity variable}

{phang2}{cmd:. m69tom4 main69, gen(main4)}{p_end}

{pstd}
This creates {cmd:main4}, a four-category version of {cmd:main69}.

{marker ex2}{...}
{bf:Example 2: Tabulate the new groups}

{phang2}{cmd:. m69tom4 activity, gen(activity4)}{p_end}
{phang2}{cmd:. tab activity4}{p_end}

{title:Remarks}

{pstd}
{bf:1. Input must be numeric}

{pstd}
The command requires a numeric input variable. If the source activity variable is stored as a string, convert it before using {cmd:m69tom4}.

{pstd}
{bf:2. The original variable is not modified}

{pstd}
{cmd:m69tom4} leaves the source variable unchanged and creates a new recoded variable.

{pstd}
{bf:3. Code 69 becomes missing}

{pstd}
Original code 69 is recoded to system missing in the generated variable.

{title:Stored results}

{pstd}
{cmd:m69tom4} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the created variable.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
Other small recode utilities in the same toolkit provide similar crosswalks for alternative activity classifications.
