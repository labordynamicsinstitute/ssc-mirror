{smcl}
{* *! version 1.1.0  7Mars2013}{...}
{cmd:help qn} {right: (Wouter Gelade, Vincenzo Verardi and Catherine Vermandele)}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{cmd:qn} {hline 2}} Rousseeuw and Croux (1993) robust measure of dispersion{p_end}
{p2colreset}{...}


{title:Syntax}

{phang}

{pstd}
{cmd:qn} {varname} {ifin}



{title:Description}

{pstd}
{cmd:qn} Estimates Qn, a robust measure of dispersion

{pstd}
When estimating dispersion parameters, please see {manhelp summarize R} for classical estimators.


{title:Examples}

{pstd}Setup{p_end}
{phang2}{stata "webuse auto"}{p_end}

{pstd}Estimating measure of dispersion Qn {p_end}
{phang2}{stata "qn price"}{p_end}


{title:Saved results}

{pstd}
{cmd:qn} saves the following in {cmd:e()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:e(qn)}}The Qn dispersion statistic{p_end}

{p2col 5 15 19 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}The sample identifier{p_end}


{title:References}


Rousseeuw, Peter J.; Croux, Christophe (December 1993), "Alternatives to the Median Absolute Deviation"
Journal of the American Statistical Association 88(424): 1273–1283.

{title:Also see}

{psee}
Manual:  {manlink R summarize}  {break} {p_end}
