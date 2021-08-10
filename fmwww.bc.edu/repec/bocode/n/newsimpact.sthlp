{smcl}
{* *! version 1.1  2019-03-27}{...}
{cmd:help newsimpact}
{hline}

{title:News impact curve for ARCH models}


{title:Syntax}

{p 8 25 2}
{cmd:newsimpact [response news]}
[{cmd:,} 
{opt s:igma2(a)}
{opt r:ange(b)}
{opt nog:raph}]

{title:Description}

{p}{cmd:newsimpact} is for use after {cmd:arch}.
It plots the news impact curve, the response in the conditional variance, 
sigma^2(t),
to an innovation in the standardized error term, z(t-1).
When calculating the response in sigma^2(t) historical conditional variances 
(sigma^2(t-i), i > 0) are set to sigma^2 and historical error terms (z(t-i), i > 1)
are set to 1. The default value for sigma^2 is an estimate of the unconditional variance,
the mean of the estimated conditional variances. Finally error terms that enter in
the conditional variance formula are obtained as e(t) = sigma*z(t).

{p}Optionally saves the variables for the x axis (news) and y axis (response) of the graph.

{title:Options}

{synoptset 15}{...}
{synopthdr:option}
{synoptline}

{synopt:{opt s:igma2(a)}}Use sigma^2 = a instead of the default. The
default is to set sigma^2 to the mean of the estimated conditional variances.

{synopt:{opt r:ange(b)}}Plot the news impact for z(t-1) = -b to +b instead of
the default z(t-1) = -2 to +2.

{synopt:{opt nog:raph}}Suppress display news impact graph.

{synoptline}

{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse wpi1}{p_end}

{pstd}Fit GARCH(1,1) and plot news impact curve{p_end}
{phang2}{cmd:. arch D.ln_wpi, arch(1) garch(1)}{p_end}
{phang2}{cmd:. newsimpact}{p_end}

{pstd}Fit EGARCH(1,1) and plot news impact curve (yes, the curve is weird){p_end}
{phang2}{cmd:. arch D.ln_wpi, earch(1) egarch(1)}{p_end}
{phang2}{cmd:. newsimpact}{p_end}

{title:Author}

{pstd}Sune Karlsson, Örebro University, Sweden{p_end}
{pstd}sune.karlsson@oru.se{p_end}
