{smcl}
{* *! version 1.0.0 21 Apr 2026}{...}

{title:Title}

{pstd}
{hi:c25tom5} {hline 2} Recode MTUS Core 25 activity categories into 5 broad activity groups

{title:Syntax}

{p 8 16 2}
{cmd:c25tom5} {it:varname}{cmd:,} {opt gen(newvar)}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{it:varname}}numeric variable coded in the MTUS Core 25 activity scheme{p_end}
{synopt:{opt gen(newvar)}}name of the new recoded variable to create; required{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:c25tom5} recodes an activity variable from the {bf:MTUS Core 25} scheme into a simpler variable with {bf:5 broad activity groups}.

{pstd}
This is useful when a more aggregated classification is sufficient for analysis, graphs, or descriptive summaries.

{pstd}
The command creates a new variable specified in {opt gen()} and assigns it one of five categories:

{phang2} 
1 = personal{break}
2 = paid work{break}
3 = unpaid work{break}
4 = leisure{break}
5 = travel

{pstd}
A value label is also attached to the generated variable.

{title:Arguments}

{phang}
{it:varname} must be a {bf:numeric} variable coded in the MTUS Core 25 activity scheme.

{phang}
{opt gen(newvar)} specifies the name of the new variable to be created.

{title:How categories are recoded}

{pstd}
The mapping used by {cmd:c25tom5} is:

{synoptset 20 tabbed}{...}
{synopthdr:New category}
{synoptline}
{synopt:{cmd:1 personal}}original codes 1, 2, 3{p_end}
{synopt:{cmd:2 paid work}}original codes 4, 5, 17{p_end}
{synopt:{cmd:3 unpaid work}}original codes 6, 7, 8, 9, 10, 11, 12, 13, 14{p_end}
{synopt:{cmd:4 leisure}}original codes 15, 16, 19, 20, 21, 22, 23, 24{p_end}
{synopt:{cmd:5 travel}}original code 18{p_end}
{synoptline}

{pstd}
Original code {cmd:25} is recoded to system missing.

{pstd}
Extended missing values {cmd:.a}, {cmd:.b}, {cmd:.c}, and {cmd:.d} are also recoded to system missing.

{title:What the command creates}

{pstd}
{cmd:c25tom5} creates a new numeric variable named in {opt gen()}.

{pstd}
The new variable receives the following value label:

{phang2}
1 {hline 2} personal{break}
2 {hline 2} paid work{break}
3 {hline 2} unpaid work{break}
4 {hline 2} leisure{break}
5 {hline 2} travel

{title:Examples}

{marker ex1}{...}
{bf:Example 1: Recode a Core 25 activity variable}

{phang2}{cmd:. c25tom5 c25, gen(c5)}{p_end}

{pstd}
This creates {cmd:c5}, a five-category version of {cmd:c25}.

{marker ex2}{...}
{bf:Example 2: Tabulate the new groups}

{phang2}{cmd:. c25tom5 activity25, gen(activity5)}{p_end}
{phang2}{cmd:. tab activity5}{p_end}

{title:Remarks}

{pstd}
{bf:1. Input must be numeric}

{pstd}
The command requires a numeric input variable. If your activity variable is stored as a string, it must be converted before using {cmd:c25tom5}.

{pstd}
{bf:2. The original variable is not modified}

{pstd}
{cmd:c25tom5} leaves the source variable unchanged and creates a new recoded variable.

{pstd}
{bf:3. Missing and residual categories}

{pstd}
Code 25 and extended missing values are recoded to system missing in the generated variable.

{title:Stored results}

{pstd}
{cmd:c25tom5} does not store results in {cmd:r()} or {cmd:e()}. Results are returned through the created variable.

{title:Author}

{pstd}
Juana Lamote de Grignon-Pérez
{break}
Centre for Time Use Research (CTUR)

{title:Also see}

{pstd}
Other small recode utilities in the same toolkit may provide similar crosswalks for alternative activity classifications.
