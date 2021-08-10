{smcl}
{* *! version 1.1.0  7Mars2013}{...}
{cmd:help hl} {right: (Wouter Gelade, Vincenzo Verardi and Catherine Vermandele)}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{cmd:hl} {hline 2}} Hodges and Lehman (1963) robust measure of location{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}

{pstd}
{cmd:hl} {varname} {ifin} {cmd:,} 



{title:Description}

{pstd}
{cmd:hl} Estimates H-L, the Hodges-Lehman (1963) measure of location

{pstd}
When estimating location parameters, please see {manhelp summarize R} for classical estimators.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{stata "webuse auto"}{p_end}

{pstd}Estimating location parameter H-L {p_end}
{phang2}{stata "hl price"}{p_end}


{title:Saved results}

{pstd}
{cmd:hl} saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(hl)}}The H-L location statistic{p_end}

{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}The sample identifier{p_end}


{title:References}


Hodges, J. L. and Lehmann, E. L. (1963). "Estimation of location based on ranks".
Annals of Mathematical Statistics 34(2): 598–611. 

{title:Also see}

{psee}
Manual:  {manlink R summarize}  {break} {p_end}
