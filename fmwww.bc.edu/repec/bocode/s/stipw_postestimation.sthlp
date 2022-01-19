{smcl}
{* *! version 1.0.0 05Jul2021}{...}
{vieweralsosee "stipw" "help stipw"}{...}
{vieweralsosee "streg" "help streg"}{...}
{vieweralsosee "streg postestimation" "help streg_postestimation"}{...}
{vieweralsosee "stpm2" "help stpm2"}{...}
{vieweralsosee "stpm2 postestimation" "help stpm2_postestimation"}{...}
{title:Title}

{p2colset 5 34 36 2}{...}
{p2col :{hi:stipw postestimation} {hline 2}}Post-estimation tools for stipw{p_end}
{p2colreset}{...}


{title:Description}

{pstd}
The following standard post-estimation commands are available for outcome models fitted with {cmd:streg}:

{synoptset 17 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
INCLUDE help post_estatic
INCLUDE help post_estatsum
INCLUDE help post_estatvce
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_nlcom
{p2col :{helpb streg postestimation##predict:predict}}predictions, residuals, influence statistics, and other diagnostic measures{p_end}
INCLUDE help post_predictnl
{p2col :{helpb stcurve}}plot the survivor, hazard, and cumulative hazard functions{p_end}
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}

{pstd}
The following standard post-estimation commands are available for outcome models fitted with {cmd:stpm2}:

{synoptset 17 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}

INCLUDE help post_adjust2
{p2col :{helpb estat##predict:estat}}post estimation statistics{p_end}
INCLUDE help post_estimates
INCLUDE help post_lincom
INCLUDE help post_nlcom
{p2col :{helpb stpm2 postestimation##predict:predict}}predictions, residuals etc{p_end}
INCLUDE help post_predictnl
INCLUDE help post_test
INCLUDE help post_testnl
{synoptline}
{p2colreset}{...}


{title:Examples}

{pstd}Setup{p_end}
{phang2}{stata "webuse brcancer"}{p_end}
{phang2}{stata "stset rectime, failure(censrec = 1)"}{p_end}

{pstd}Exposure of interest is {it: hormon}.{p_end}
{pstd}We wish to adjust for confounders {it: x1}, {it:x2}, {it:x3}, {it:x5}, {it:x6} and {it:x7}.{p_end}
{pstd}Perform an IPW analysis using {cmd: stipw}. Fit a weighted Weibull model{p_end}
{phang2}{stata "stipw (logit hormon x1 x2 x3 x5 x6 x7) , distribution(weibull)"}{p_end}
{phang2}{stata "predict h1, hazard"}{p_end}
{phang2}{stata "predict s1, surv"}{p_end}

{pstd}Perform an IPW analysis using {cmd: stipw}. Fit a weighted rp (Royston-Paramr) model{p_end}
{phang2}{stata "stipw (logit hormon x1 x2 x3 x5 x6 x7) , d(rp) df(3)"}{p_end}
{phang2}{stata "predict h2, hazard ci"}{p_end}
{phang2}{stata "predict s2, survival ci"}{p_end}

{pstd}Perform an IPW analysis using {cmd: stipw}. Fit a weighted rp model with time-dependent effects{p_end}
{phang2}{stata "stipw (logit hormon x1 x2 x3 x5 x6 x7) , d(rp) df(3) dftvc(2)"}{p_end}
{phang2}{stata "predict hr, hrnumerator(hormon 1) ci"}{p_end}
{phang2}{stata "predict survdiff, sdiff1(hormon 1) ci"}{p_end}
{phang2}{stata "predict hazarddiff, hdiff1(hormon 1) ci"}{p_end}
