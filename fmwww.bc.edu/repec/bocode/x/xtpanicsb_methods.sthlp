{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpanicsb" "help xtpanicsb"}{...}
{vieweralsosee "xtpdroot (library)" "help xtpdroot"}{...}
{title:Title}

{phang}
{bf:xtpanicsb methods} {hline 2} Algorithm for the sharp-break PANIC MSB test

{title:Iterated break and factor estimation}

{pstd}
Working with the first differences {it:Dx}, the procedure iterates between break
estimation and factor extraction:{p_end}

{phang}1. {bf:Breaks.} For each unit the break dates are the global minimisers of
the residual sum of squares of a mean-shift model, computed by the Bai-Perron
(1998) {it:dynamic-programming} algorithm (the SSR of every admissible segment is
built recursively and the optimal {it:m}-break partition is found by recursion
over the number of breaks, subject to a minimum segment length {it:h} =
[{it:trim} x {it:T}]).{p_end}

{phang}2. {bf:Factors.} The break-adjusted differences are stacked and the common
factors are extracted by principal components; the number of factors is the
Bai-Ng (2002) panel-BIC minimiser. The idiosyncratic differences are the residual
after removing the common component and the break dummies.{p_end}

{phang}3. The common component is removed from {it:Dx} and steps 1-2 repeat until
the idiosyncratic variance changes by less than 0.001 (at most ten iterations).{p_end}

{pstd}
The idiosyncratic component {it:e_t} is the partial sum of the converged
idiosyncratic differences.

{title:The MSB statistic}

{pstd}
For each unit the modified Sargan-Bhargava statistic is{p_end}

{pmore}{bf:MSB} = {it:T}^{c -(}-2{c )-} ( sum_t {it:e_t}^2 ) / {it:s2},{p_end}

{pstd}
where {it:s2} is the Sul-Phillips-Choi prewhitened Bartlett long-run variance of
{it:e} (an AR({it:pbar}) prewhitening of the first differences). The {it:simplified}
statistic sums the regime-specific MSB contributions defined by the estimated
breaks, which is what enters the panel pooling.

{title:Panel pooling}

{pstd}
Each unit's simplified statistic is mapped to a p-value {it:pv_i} through the
finite-sample response surface of Bai and Carrion-i-Silvestre (a logistic function
of the statistic and of {it:T}/({it:number of breaks})). The panel statistics are{p_end}

{pmore}{bf:Pval-chi} = -2 sum_i ln({it:pv_i})  ~ chi2(2N),{p_end}
{pmore}{bf:Pval-normal} = ( -2 sum_i ln({it:pv_i}) - 2N ) / sqrt(4N)  ~ N(0,1).{p_end}

{pstd}
Because the response surface is very steep, the pooled p-value is sensitive to the
last one or two significant digits of the iterated idiosyncratic component; the
per-unit MSB statistics and break dates, by contrast, reproduce the source routine
to the last reported digit.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
