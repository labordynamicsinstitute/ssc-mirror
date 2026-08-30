{smcl}
{* *! version 1.1.0  29aug2026}{...}
{vieweralsosee "xtcspqardl" "help xtcspqardl"}{...}
{vieweralsosee "xtcspqardl methods" "help xtcspqardl_methods"}{...}
{viewerjumpto "Syntax" "xtcspqardl_postestimation##syntax"}{...}
{viewerjumpto "Coefficient naming" "xtcspqardl_postestimation##naming"}{...}
{viewerjumpto "Tests" "xtcspqardl_postestimation##tests"}{...}
{viewerjumpto "Figures" "xtcspqardl_postestimation##graph"}{...}
{viewerjumpto "Inter-quantile analysis" "xtcspqardl_postestimation##adv"}{...}
{viewerjumpto "Exporting" "xtcspqardl_postestimation##export"}{...}

{title:Title}

{phang}
{bf:xtcspqardl postestimation} {hline 2} postestimation tools for
{helpb xtcspqardl}


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:xtcspqardl_graph} [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:_xtcspqardl_advanced} [{cmd:,} {opt level(#)}]

{pstd}
The standard estimation postestimation commands also work, because
{cmd:xtcspqardl} posts a full {cmd:e(b)} and {cmd:e(V)}:
{helpb test}, {helpb testnl}, {helpb lincom}, {helpb nlcom},
{helpb estimates store}, {helpb estimates table}, and the community
commands {cmd:coefplot} and {cmd:esttab}.


{marker naming}{title:Coefficient naming}

{pstd}
{cmd:e(b)} stacks the short-run and the long-run blocks and gives each
quantile its own equation.  A quantile tau becomes {cmd:q}{it:###} for the
short run and {cmd:lr}{it:###} for the long run, where {it:###} is
100*tau written with three digits.  So

{p 8 8 2}{cmd:[q025]x1}{space 4}beta_x1 at tau = 0.25{break}
{cmd:[q050]L.y}{space 3}lambda at tau = 0.50{break}
{cmd:[lr075]x1}{space 2}theta_x1 at tau = 0.75

{pstd}
In the CS-PQARDL forms the first short-run coefficient is called
{cmd:ECT} (one step) or {cmd:ECM(-1)} (two step).

{pstd}
The covariance {cmd:e(V)} is the {bf:joint} covariance of everything in
{cmd:e(b)}, including the cross-quantile blocks and the cross-covariance
between the short-run and long-run blocks, so contrasts across quantiles
and across horizons are correct out of the box.  The one exception is the
two-step {opt ecm} form, where the long-run and short-run blocks come from
different regressions and their cross-covariance is set to zero.


{marker tests}{title:Tests}

{pstd}Does the effect of x1 differ between the lower and upper quartile?{p_end}
{phang2}{cmd:. test [q075]x1 = [q025]x1}{p_end}

{pstd}Is the long-run effect constant across all three quantiles?{p_end}
{phang2}{cmd:. test [lr025]x1 = [lr050]x1 = [lr075]x1}{p_end}

{pstd}How large is the difference, with a confidence interval?{p_end}
{phang2}{cmd:. lincom [lr075]x1 - [lr025]x1}{p_end}

{pstd}Are all slopes zero at the median?{p_end}
{phang2}{cmd:. test [q050]}{p_end}

{pstd}A nonlinear function of the estimates{p_end}
{phang2}{cmd:. nlcom [lr050]x1 / [lr050]x2}{p_end}


{marker graph}{title:Figures}

{p 8 17 2}
{cmd:xtcspqardl_graph}
[{cmd:,}
{opt lev:el(#)}
{opt sch:eme(name)}
{opt name:stub(str)}
{opt which(str)}
{opt export(path)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt level(#)}}confidence level for the bands; defaults to the
level used at estimation{p_end}
{synopt :{opt scheme(name)}}graph scheme{p_end}
{synopt :{opt namestub(str)}}prefix for the graph names; default
{cmd:xtcspq}{p_end}
{synopt :{opt which(str)}}which figures to draw, any of {cmd:sr},
{cmd:lr}, {cmd:both}, {cmd:unit}, {cmd:hl}; default is all of them{p_end}
{synopt :{opt export(path)}}also write each figure to {it:path} as a PNG{p_end}
{synoptline}

{pstd}The figures are:

{p2colset 5 16 18 2}{...}
{p2col :{cmd:sr}}the short-run quantile process, one panel per
coefficient, with a pointwise band and a zero reference line{p_end}
{p2col :{cmd:lr}}the same for the long-run coefficients{p_end}
{p2col :{cmd:both}}short run and long run overlaid, one panel per
regressor; this is the layout of Figure 4.1 in Harding, Lamarche and
Pesaran (2018){p_end}
{p2col :{cmd:unit}}the unit-level persistence or speed-of-adjustment
coefficients, sorted, with the mean-group line and the relevant reference
line; this is Figure 3 of Ul-Durar et al. (2025){p_end}
{p2col :{cmd:hl}}the half-life across quantiles with its confidence
interval{p_end}
{p2colreset}{...}

{pstd}
The quantile-process figures need at least two quantiles.  Each panel is
also left in memory under its own name, so panels can be recombined with
{helpb graph combine}.


{marker adv}{title:Inter-quantile analysis}

{pstd}
{cmd:_xtcspqardl_advanced} (or the {opt full} option at estimation)
reports:

{p2colset 5 12 14 2}{...}
{p2col :A1, A2}every pairwise contrast b(tau2) - b(tau1), short run and
long run, with the correct variance
V(t2,t2) + V(t1,t1) - 2 V(t1,t2){p_end}
{p2col :A3, A4}for each coefficient, a joint chi-squared test that it is
constant across all requested quantiles{p_end}
{p2col :A5}the persistence and half-life profile with standard errors{p_end}
{p2colreset}{...}

{pstd}
Rejecting constancy is the formal justification for reporting a quantile
process rather than a single conditional-mean effect.


{marker export}{title:Exporting tables}

{pstd}
Because {cmd:e(b)} and {cmd:e(V)} are posted, the usual table pipelines
work:

{phang2}{cmd:. eststo m1: xtcspqardl y x1 x2, tau(0.25 0.5 0.75) qccemg notable}{p_end}
{phang2}{cmd:. esttab m1, se star(* 0.10 ** 0.05 *** 0.01) keep(q050: lr050:)}{p_end}
{phang2}{cmd:. coefplot m1, keep(lr*) xline(0)}{p_end}

{pstd}
The diagnostics are in {cmd:e(diagnostics)}, one row per quantile with
columns {cmd:r1}, {cmd:wald}, {cmd:wald_df}, {cmd:wald_p}, {cmd:cd},
{cmd:cd_p}, {cmd:gjmo_d}, {cmd:gjmo_d_p}, {cmd:cd0}, {cmd:cd0_p},
{cmd:gjmo_s}, {cmd:gjmo_s_df}, {cmd:gjmo_s_p}.  The {cmd:gjmo_*} columns
are the Galvao, Juhl, Montes-Rojas and Olmo (2017) slope-homogeneity
tests: {cmd:gjmo_d} is the standardized normal form and {cmd:gjmo_s} the
chi-squared Swamy form.  See {helpb xtqsh} for the standalone test.


{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
