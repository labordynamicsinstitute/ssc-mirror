{smcl}
{* 11feb2026}{...}
{cmd:help pnardl} {right:version 1.0.0}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:pnardl} {hline 2}}Panel Nonlinear ARDL (Panel NARDL) Estimation{p_end}
{p2colreset}{...}

{title:Version}

{pstd}
Version 1.0.0, 11 February 2026

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{pstd}
{bf:Based on:}

{pstd}
Shin, Y., Yu, B., and Greenwood-Nimmo, M. (2014). Modelling Asymmetric
Cointegration and Dynamic Multipliers in a Nonlinear ARDL Framework.
In: Sickles, R., Horrace, W. (eds) {it:Festschrift in Honor of Peter Schmidt}.
Springer, New York. pp. 281-314.

{pstd}
Salisu, A.A. and Isah, K.O. (2017). Revisiting the oil price and
stock market nexus: A nonlinear Panel ARDL approach.
{it:Economic Modelling} 66: 258-271.
{browse "https://doi.org/10.1016/j.econmod.2017.07.010":doi:10.1016/j.econmod.2017.07.010}

{pstd}
{bf:Requires:} {cmd:xtpmg} version 2.0.0 or later


{title:Syntax}

{p 8 16 2}{cmd:pnardl} {depvar} [{indepvars}] {ifin}{cmd:,}
{opth lr:(varlist)} {opth asym:metric(varlist)} [{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opth lr:(varlist)}}variables for the long-run cointegrating vector{p_end}
{synopt :{opth asym:metric(varlist)}}variables to decompose into positive and negative partial sums{p_end}

{syntab:Model}
{synopt :{opt pmg}}Pooled Mean Group estimator (default){p_end}
{synopt :{opt mg}}Mean Group estimator{p_end}
{synopt :{opt dfe}}Dynamic Fixed Effects estimator{p_end}
{synopt :{opth ec:(name)}}name for the error-correction term; default is {cmd:ECT}{p_end}
{synopt :{opt replace}}overwrite existing decomposed variables and EC term{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opth cl:uster(varname)}}clustered standard errors{p_end}
{synopt :{opth const:raints(numlist)}}apply constraints{p_end}
{synopt :{opt full}}display all panel regressions{p_end}

{syntab:Testing}
{synopt :{opt haus:man}}perform Hausman test (MG vs PMG){p_end}
{synopt :{opt noasym:test}}suppress asymmetry Wald tests{p_end}

{syntab:ML Options (PMG only)}
{synopt :{opt tech:nique(algorithm)}}ML maximization technique{p_end}
{synopt :{opt diff:icult}}alternative stepping algorithm{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:pnardl}; see {helpb tsset}.{p_end}


{title:Description}

{pstd}
{cmd:pnardl} implements the Panel Nonlinear ARDL (Panel NARDL) methodology for
estimating asymmetric long-run and short-run relationships in panel data. It
automates the complete Panel NARDL workflow:

{p 8 12 2}1. {bf:Decomposition:} Splits specified variables into positive and negative
cumulative partial sums for asymmetric effect analysis.{p_end}

{p 8 12 2}2. {bf:Estimation:} Estimates Pooled Mean Group (PMG), Mean Group (MG), or Dynamic
Fixed Effects (DFE) models via {cmd:xtpmg}.{p_end}

{p 8 12 2}3. {bf:Model Selection:} Optionally performs Hausman test to choose between
MG and PMG estimators.{p_end}

{p 8 12 2}4. {bf:Asymmetry Testing:} Performs Wald tests for both long-run and short-run
asymmetry for each decomposed variable.{p_end}

{pstd}
The methodology is based on Shin, Yu, and Greenwood-Nimmo (2014), who extended
the linear ARDL cointegration framework of Pesaran, Shin, and Smith (2001) to
allow for asymmetric effects. The Panel NARDL approach, as applied by
Salisu and Isah (2017), combines this nonlinear decomposition with the panel
estimators of Pesaran, Shin, and Smith (1999).


{title:Options}

{dlgtab:Required}

{phang}
{opth lr(varlist)} specifies the variables for the long-run cointegrating vector.
The first variable must be the lagged dependent variable. Variables listed in
{opt asymmetric()} will be automatically replaced with their positive and negative
partial sums in the long-run equation.

{phang}
{opth asymmetric(varlist)} specifies the variables to be decomposed into positive
and negative cumulative partial sums. For each variable {it:x}, two new variables
are created: {it:x_pos} (positive partial sum) and {it:x_neg} (negative partial sum).

{dlgtab:Model}

{phang}
{opt pmg}, {opt mg}, {opt dfe} select the estimation method. {opt pmg} (default) constrains
long-run coefficients to be homogeneous across panels. {opt mg} allows full heterogeneity.
{opt dfe} constrains all parameters except intercepts.

{phang}
{opt hausman} performs a Hausman test comparing MG and PMG estimates to guide model selection.
Significant test results favor MG; insignificant results favor PMG.

{phang}
{opt noasymtest} suppresses the automatic Wald tests for long-run and short-run asymmetry.

{phang}
{opt replace} overwrites existing decomposed variables ({it:x_pos}, {it:x_neg}) and
the error-correction term in the dataset.


{title:Methodology}

{pstd}
The Panel NARDL model extends the standard panel ARDL framework by decomposing
an independent variable x into positive and negative cumulative partial sums:

{p 8 12 2}x_pos(t) = sum(j=1 to t) max(delta_x(j), 0){p_end}
{p 8 12 2}x_neg(t) = sum(j=1 to t) min(delta_x(j), 0){p_end}

{pstd}
These partial sums replace the original variable in the ARDL specification,
allowing distinct long-run and short-run coefficients for positive and negative
changes. The error-correction model becomes:

{p 8 12 2}d.y(it) = phi(i) * [y(it-1) - beta_pos * x_pos(it) - beta_neg * x_neg(it)]
+ gamma_pos * d.x_pos(it) + gamma_neg * d.x_neg(it) + e(it){p_end}

{pstd}
{bf:Long-run asymmetry:} H0: beta_pos = beta_neg (tested via Wald test){p_end}
{pstd}
{bf:Short-run asymmetry:} H0: gamma_pos = gamma_neg (tested via Wald test){p_end}

{pstd}
See Salisu and Isah (2017) for a complete application of this methodology to
the oil price-stock market nexus, demonstrating how positive and negative oil
price shocks have asymmetric effects across both developed and developing
economies.


{title:Stored Results}

{pstd}
{cmd:pnardl} stores all {cmd:xtpmg} results in {cmd:e()}, plus:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:pnardl}{p_end}
{synopt:{cmd:e(model)}}estimation model ({cmd:PMG}, {cmd:MG}, or {cmd:DFE}){p_end}
{synopt:{cmd:e(asymmetric)}}names of asymmetrically decomposed variables{p_end}
{synopt:{cmd:e(pos_vars)}}names of positive partial sum variables{p_end}
{synopt:{cmd:e(neg_vars)}}names of negative partial sum variables{p_end}


{title:Examples}

{pstd}
{bf:Basic Panel NARDL estimation (PMG, default):}

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) replace}{p_end}

{pstd}
{bf:Mean Group estimator with Hausman test:}

{phang2}{cmd:. pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) mg hausman replace}{p_end}

{pstd}
{bf:Multiple asymmetric variables:}

{phang2}{cmd:. pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1 x2) replace}{p_end}

{pstd}
{bf:Suppress asymmetry tests:}

{phang2}{cmd:. pnardl d.y d.x1 d.x2, lr(l.y x1 x2) asymmetric(x1) noasymtest replace}{p_end}

{pstd}
{bf:Application (Salisu and Isah, 2017):}

{phang2}{cmd:. * Oil price-stock market nexus}{p_end}
{phang2}{cmd:. pnardl d.stock d.oil d.controls, lr(l.stock oil controls) asymmetric(oil) pmg hausman replace}{p_end}


{title:References}

{phang}
Salisu, A.A. and Isah, K.O. 2017.
Revisiting the oil price and stock market nexus: A nonlinear Panel ARDL approach.
{it:Economic Modelling} 66: 258-271.
{browse "https://doi.org/10.1016/j.econmod.2017.07.010":doi:10.1016/j.econmod.2017.07.010}

{phang}
Shin, Y., Yu, B. and Greenwood-Nimmo, M. 2014.
Modelling Asymmetric Cointegration and Dynamic Multipliers in a Nonlinear
ARDL Framework. In: Sickles, R., Horrace, W. (eds) {it:Festschrift in Honor of Peter Schmidt}.
Springer, New York. pp. 281-314.

{phang}
Pesaran, M.H., Shin, Y. and Smith, R.P. 1999.
Pooled mean group estimation of dynamic heterogeneous panels.
{it:Journal of the American Statistical Association} 94: 621-634.

{phang}
Pesaran, M.H., Shin, Y. and Smith, R.J. 2001.
Bounds testing approaches to the analysis of level relationships.
{it:Journal of Applied Econometrics} 16: 289-326.

{phang}
Blackburne, E.F. III and M.W. Frank. 2007.
Estimation of nonstationary heterogeneous panels.
{it:Stata Journal} 7(2): 197-208.


{title:Author}

{pstd}
Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}


{title:Also see}

{psee}
{helpb xtpmg}, {helpb xtreg}, {helpb tsset}, {helpb hausman}
{p_end}
