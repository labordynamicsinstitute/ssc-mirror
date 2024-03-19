{smcl}
{* *! version 1.0  14Mar2024}{...}
{cmd:help orderalpha} 
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{phang}
{bf:stocdom} {hline 2} Bounds assuming stochastic dominance {p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmd:stocdom}
{it:{help varname:depvar}} {it:{help varname:treatvar}}  

{title:Description}

{pstd}
{cmd:stocdom} calculates bounds for treatment effects in randomized controlled trials in the presence of survey attrition, when stochastic dominance is assumed as in Zhang and Rubin (2003). In this context stochastic dominance implies that the outcomes of individuals that are always observed are higher than those that are observed contingent on treatment assignment. The command bounds the treatment effect for the always observed. 


{title:Examples}

{phang2}{cmd:. stocdom score treatment}{p_end}

{title:Saved results}

{synopt:{cmd:e(b)}}{it:1x2} vector of estimated treatment effect bounds{p_end}


{title:References}

{pstd}
Zhang, Junni L. and Donald B. Rubin (2003). Estimation of Causal Effects via Principal Stratification When Some Outcomes are Truncated by Death. Journal of Educational and Behavioral Statistics. Vol. 28, No. 4, pp. 353–368

{pstd}

{title:Author}

{psee}
Alejandro Ome{p_end}
{psee}
NORC at the University of Chicago{p_end}
{psee}
E-mail: ome-alejandro@norc.org
{p_end}


{title:Disclaimer}
 
{pstd} This software is provided "as is". No responsibility or liability for the correct functionality of the command is taken.
{p_end} 

