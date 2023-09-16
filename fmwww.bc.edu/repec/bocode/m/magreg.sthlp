{smcl}
{* *! version 1.0.0 15sep2023 Matteo Bottai}{...}

{cmd:help magreg}
{hline}

{hi:magreg}: Maximum agreement regression

{title:Syntax}

{p 8 13 2}
{cmd:mareg} {it:{help varlist}} {ifin} [{it:{help regress##weight:weight}}] [{cmd:,} bsopts options]}

{title:Description}

{pstd}
{cmd:magreg} estimates the maximum agreement regression model specified in {it:varlist}.

{title:Options}

{synoptset 15 tabbed}{...}
{synopt:{opth bs:opts(string)}}specifies the options for the bootstrap command ({manhelp bootstrap R:bootstrap}){p_end}
{synopt:options}specifies options as for the regress command ({manhelp regress R:regress}){p_end}

{title:Examples}

{phang}{stata "sysuse auto"}{p_end}
{phang}{stata "magreg price displacement"}{p_end}
{phang}{stata "predict predicted"}{p_end}
{phang}{stata "twoway scatter price predicted || line price price, sort"}{p_end}
{phang}{stata "magreg price displacement weight if foreign==1, nocons bsopts(rep(10))"}{p_end}

{title:Also see}

{phang}{manhelp regress R:regress}, {manhelp bootstrap R:bootstrap}{p_end}

{title:Reference}

{pstd}Bottai M, Kim T, Lieberman B, Luta G, Peña E{p_end}
{pstd}On Optimal Correlation-Based Prediction{p_end}
{pstd}The American Statistician, 76:4, 313-321, 2022{p_end}

{title:Author}

{pstd}Matteo Bottai{p_end}
{pstd}Division of Biostatistics{p_end}
{pstd}{browse "http://ki.se/":Institute of Environmental Medicine, Karolinska Institutet}{p_end}
{pstd}Stockholm, Sweden{p_end}
