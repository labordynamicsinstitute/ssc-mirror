{smcl}
{* *! version 1.0.0  08jul2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "totimpact postestimation" "help totimpact_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "totimpact##syntax"}{...}
{viewerjumpto "Description" "totimpact##description"}{...}
{viewerjumpto "Options" "totimpact##options"}{...}
{viewerjumpto "Methods and formulas" "totimpact##methods"}{...}
{viewerjumpto "Remarks" "totimpact##remarks"}{...}
{viewerjumpto "Stored results" "totimpact##results"}{...}
{viewerjumpto "Examples" "totimpact##examples"}{...}
{viewerjumpto "References" "totimpact##references"}{...}
{viewerjumpto "Author" "totimpact##author"}{...}
{title:Title}

{phang}
{bf:totimpact} {hline 2} Total impact effects in time series regressions
(Pesaran & Smith, 2014)


{marker syntax}{...}
{title:Syntax}

{pstd}
Standalone form{p_end}

{p 8 17 2}
{cmd:totimpact}
{it:{help varname:depvar}}
{it:{help varlist:indepvars}}
{ifin}
[{cmd:,} {it:options}]

{pstd}
Postestimation form (uses the {cmd:regress} results in memory){p_end}

{p 8 17 2}
{cmd:totimpact}
{ifin}
[{cmd:,} {it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opth focus(varlist)}}report only these regressors; default is all of
them{p_end}
{synopt :{opt level(#)}}confidence level for the total effect; default
{cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt :{opt gamma}}also display the co-movement matrix
{it:{help gamma:gamma_ji}} = cov(x_j,x_i)/var(x_i){p_end}
{synopt :{opt noheader}}suppress the results table (still stores {cmd:r()}){p_end}

{syntab:Graphs}
{synopt :{opt graph}}draw the full dashboard (compare + decompose + gamma){p_end}
{synopt :{opt plots(types)}}draw only the named plot(s); see
{it:{help totimpact##plots:plot types}} below{p_end}
{synopt :{opt name(name)}}name of the resulting graph in memory; default
{cmd:name(totimpact)}{p_end}
{synopt :{opt saving(filename)}}save the resulting graph to
{it:filename}{cmd:.gph}{p_end}
{synoptline}
{p2colreset}{...}

{marker plots}{...}
{pstd}
{it:types} in {opt plots()} is one or more of:{p_end}

{p2colset 9 24 26 2}{...}
{p2col :{opt compare}}direct coefficient vs total impact effect, with a
confidence spike on the total effect{p_end}
{p2col :{opt decompose}}each total effect split into its direct and indirect
parts (stacked bars){p_end}
{p2col :{opt gamma}}heatmap of the co-movement coefficients
{it:gamma_ji}{p_end}
{p2col :{opt all}}all three of the above, combined into one dashboard (this is
what bare {opt graph} does){p_end}
{p2colreset}{...}

{pstd}
{cmd:depvar} and {cmd:indepvars} must be continuous numeric variables. The
command may be used with {helpb tsset:time series} data; specify lagged or
differenced regressors as generated variables.


{marker description}{...}
{title:Description}

{pstd}
{cmd:totimpact} estimates the {it:total impact effect} of each regressor in a
linear time series regression, following Pesaran and Smith (2014). In an
experiment the inputs are made orthogonal, so the effect of one input is
unambiguous. In observational time series the regressors are realisations of
{it:correlated} stochastic processes that cannot be held fixed, and the
ordinary multiple-regression coefficient {it:beta_i} — the {it:ceteris paribus}
(other things equal) effect — is often not the quantity of interest.

{pstd}
The total impact effect {it:lambda_i} instead lets the other regressors adjust
as their historical correlation with the focus regressor dictates
({it:mutatis mutandis}, "other things changing as they must"). Because those
induced movements can outweigh the direct channel, {it:lambda_i} can differ in
magnitude from {it:beta_i} and even carry the {it:opposite sign}.
{cmd:totimpact} reports, for every regressor:

{p2colset 9 24 26 2}{...}
{p2col :{it:Direct}}the multiple-regression coefficient {it:beta_i}{p_end}
{p2col :{it:Indirect}}the induced part, {it:lambda_i} - {it:beta_i}{p_end}
{p2col :{it:Total}}the total impact effect {it:lambda_i}{p_end}
{p2col :{it:Std.Err.}}its standard error, built from the {it:full}-model error
variance{p_end}
{p2col :{it:t}, {it:P>|t|}}the corrected test of {it:lambda_i} = 0{p_end}
{p2colreset}{...}

{pstd}
and flags any regressor whose total effect reverses the sign of its
coefficient. See {it:{help totimpact##methods:Methods and formulas}} for the
exact estimator.

{pstd}
{cmd:totimpact} runs standalone, or as a postestimation command after
{cmd:regress}: typed with no {it:varlist} it reads the dependent variable, the
regressors and the estimation sample from the fit in memory. See
{helpb totimpact_postestimation:totimpact postestimation}.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth focus(varlist)} restricts the report to a subset of the regressors. The
{it:full} model is still fitted with every regressor — the corrected standard
errors require it (see {it:Methods}) — but only the listed variables appear in
the table, the returned {cmd:r(table)}, and any graph. The default is to report
every regressor. A variable listed in {opt focus()} that is not one of the
regressors is an error.

{phang}
{opt level(#)} sets the confidence level, as a percentage, for the confidence
interval of the total impact effect that is stored in {cmd:r(table)} and drawn
by the {opt compare} plot. The default is {cmd:level(95)} or as set by
{helpb set level}.

{dlgtab:Reporting}

{phang}
{opt gamma} additionally displays the matrix of co-movement coefficients
{it:gamma_ji} = cov(x_j,x_i)/var(x_i). Column {it:i} of this matrix shows how
every regressor moves, on average, with a one-unit shift in {it:x_i}; the
diagonal is 1. The total impact effect is the {it:beta}-weighted sum of a
column, {it:lambda_i} = sum_j {it:beta_j} {it:gamma_ji}, so the {opt gamma}
matrix shows exactly which regressors drive each indirect effect.

{phang}
{opt noheader} suppresses the printed table. The results are still computed and
stored in {cmd:r()}; use this when calling {cmd:totimpact} programmatically.

{dlgtab:Graphs}

{phang}
{opt graph} draws the full dashboard: the {opt compare}, {opt decompose} and
{opt gamma} plots combined into a single figure. It is a synonym for
{cmd:plots(all)}.

{phang}
{opt plots(types)} draws only the requested plot(s). {it:types} is one or more
of {opt compare}, {opt decompose}, {opt gamma}, or {opt all} (see the list
under {it:{help totimpact##plots:Syntax}}). When more than one plot is
requested they are combined into one figure; a single plot is drawn on its own.
All plots use built-in {helpb twoway} graphics — no third-party graph command
is required.

{phang}
{opt name(name)} sets the name under which the resulting graph is stored in
memory (see {helpb name_option}). The default is {cmd:name(totimpact)}, replaced
if it already exists.

{phang}
{opt saving(filename)} saves the resulting graph to disk as
{it:filename}{cmd:.gph}. Combine with {helpb graph export} to write a PNG, PDF
or other image format.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
Write the linear model as

{p 12 12 2}
{it:y_t} = {it:beta_0} + sum_j {it:beta_j} {it:x_jt} + {it:u_t},   t = 1,...,T,

{pstd}
with the classical assumptions ({it:u_t} independent and identically
distributed, mean zero, uncorrelated with the regressors). The total impact
effect of {it:x_it} is defined as the expected change in {it:y_t} that
accompanies an incremental change in {it:x_it} once the other regressors are
allowed to move with it:

{p 12 12 2}
{it:lambda_i} = sum_j {it:beta_j} {it:gamma_ji},   with {it:gamma_ii} = 1,

{pstd}
where {it:gamma_ji} = cov(x_j,x_i)/var(x_i) is the (population) regression slope
of {it:x_j} on {it:x_i}. This reduces to {it:beta_i} only when {it:x_it} is
orthogonal to every other regressor.

{pstd}
{bf:Point estimate.} Pesaran and Smith show (their equation 19) that the sample
total impact effect equals the ordinary least squares slope of the {it:simple}
regression of {it:y_t} on {it:x_it} alone:

{p 12 12 2}
lambda-hat_i = sum_t (y_t - ybar)(x_it - xbar_i) / sum_t (x_it - xbar_i){c 94}2.

{pstd}
Equivalently, with {c 83} the sample covariance matrix of the regressors and
{it:b} the vector of full-model coefficients, lambda-hat = diag({c 83}){c 94}-1
{c 83} {it:b}. The indirect effect is lambda-hat_i - {it:b_i}.

{pstd}
{bf:Standard error (the key point).} The point estimate comes from the simple
regression, but its standard error must {it:not}. The correct variance (their
equation 21) uses {it:omega}, the residual standard deviation of the {it:full}
multiple regression:

{p 12 12 2}
Var(lambda-hat_i) = {it:omega}{c 94}2 / sum_t (x_it - xbar_i){c 94}2,

{pstd}
with {it:omega}{c 94}2 estimated by the full-model residual sum of squares
divided by T - k - 1 (k = number of regressors). Inference uses Student's t with
T - k - 1 degrees of freedom.

{pstd}
Because the full model explains at least as much as the simple regression,
{it:omega} is never larger than the simple-regression residual standard
deviation {it:omega_i}. Hence the naive simple-regression {it:t} statistic
{it:understates} significance: the correct {it:t} is the naive one scaled up by
{it:omega_i}/{it:omega} >= 1. {cmd:totimpact} always reports the corrected
{it:t}; running {cmd:regress} {it:y} {it:x_i} on its own would give the same
point estimate but a too-small {it:t}.

{pstd}
The analysis treats {c 83} as constant over the sample. As Pesaran and Smith
note, this is an approximation when the covariance structure varies over time,
but it is adequate for checking the {it:sign} of an impact effect against prior
expectations — the paper's main purpose.


{marker remarks}{...}
{title:Remarks}

{pstd}
The distinction matters most when regressors are strongly correlated. If a
control variable {it:x_1} has a large positive effect and moves closely with the
focus variable {it:x_2}, then {it:x_2} can carry a negative coefficient in the
multiple regression yet a positive total impact — the "wrong sign" puzzle
discussed by Leamer (1975), McAleer et al. (1986) and Kennedy (2005). A sign
reversal is flagged in red beneath the table.

{pstd}
The procedure of orthogonalising the control variables with respect to the
focus variable, and reading the total effect from the focus variable alone, has
been criticised in other fields (for example Freckleton 2002) because it is a
biased and inconsistent estimator of {it:beta_i}. That criticism is correct if
the parameter of interest is {it:beta_i}; it is irrelevant when the parameter of
interest is {it:lambda_i}, as argued here.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:totimpact} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of regressors in the full model{p_end}
{synopt:{cmd:r(df)}}residual degrees of freedom, T - k - 1{p_end}
{synopt:{cmd:r(rmse)}}root mean squared error {it:omega} of the full model{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:totimpact}{p_end}
{synopt:{cmd:r(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:r(focus)}}the regressors reported (and returned in {cmd:r(table)}){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(table)}}reported regressors (rows) by
{it:direct}, {it:indirect}, {it:total}, {it:se}, {it:t}, {it:p}, {it:ll},
{it:ul} (columns){p_end}
{synopt:{cmd:r(direct)}}1 x k row vector of direct coefficients {it:beta}{p_end}
{synopt:{cmd:r(lambda)}}1 x k row vector of total impact effects
{it:lambda}{p_end}
{synopt:{cmd:r(gamma)}}k x k co-movement matrix {it:gamma_ji}{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup: two strongly correlated regressors, with a sign reversal.}
The coefficient on {cmd:x2} is negative, but its total impact is positive
because {cmd:x1} — which raises {cmd:y} — moves with {cmd:x2}.{p_end}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 200}{p_end}
{phang2}{cmd:. gen x1 = rnormal()}{p_end}
{phang2}{cmd:. gen x2 = 0.9*x1 + 0.4*rnormal()}{p_end}
{phang2}{cmd:. gen y  = 1.0*x1 - 0.2*x2 + rnormal()}{p_end}

{pstd}{bf:Basic use} — full table with the sign-reversal flag:{p_end}
{phang2}{cmd:. totimpact y x1 x2}{p_end}

{pstd}{bf:Focus} on one regressor at a 90% level:{p_end}
{phang2}{cmd:. totimpact y x1 x2, focus(x2) level(90)}{p_end}

{pstd}{bf:Co-movement matrix} alongside the table:{p_end}
{phang2}{cmd:. totimpact y x1 x2, gamma}{p_end}

{pstd}{bf:Graphs} — the full dashboard, then a single plot:{p_end}
{phang2}{cmd:. totimpact y x1 x2, graph}{p_end}
{phang2}{cmd:. totimpact y x1 x2, plots(compare)}{p_end}
{phang2}{cmd:. totimpact y x1 x2, plots(decompose gamma) name(mydash)}{p_end}

{pstd}{bf:Save} a graph and export it to PNG:{p_end}
{phang2}{cmd:. totimpact y x1 x2, graph saving(impact)}{p_end}
{phang2}{cmd:. graph export impact.png, replace width(1200)}{p_end}

{pstd}{bf:Postestimation} after {cmd:regress}:{p_end}
{phang2}{cmd:. regress y x1 x2}{p_end}
{phang2}{cmd:. totimpact, plots(compare)}{p_end}

{pstd}{bf:Programmatic} use — grab the total effects, print nothing:{p_end}
{phang2}{cmd:. totimpact y x1 x2, noheader}{p_end}
{phang2}{cmd:. matrix list r(lambda)}{p_end}


{marker references}{...}
{title:References}

{phang}
Freckleton, R. P. 2002. On the misuse of residuals in ecology: regression of
residuals vs. multiple regression. {it:Journal of Animal Ecology} 71(3):
542-545.

{phang}
Kennedy, P. E. 2005. Oh no! I got the wrong sign! What should I do?
{it:Journal of Economic Education} 36(1): 77-92.

{phang}
Leamer, E. E. 1975. A result on the sign of restricted least-squares estimates.
{it:Journal of Econometrics} 3(4): 387-390.

{phang}
McAleer, M., G. Fisher, and P. Volker. 1982. Separate misspecified regressions
and the U.S. long-run demand for money function. {it:Review of Economics and
Statistics} 64(4): 572-583.

{phang}
Pesaran, M. H., and R. P. Smith. 2014. Signs of impact effects in time series
regression models. {it:Economics Letters} 122(1): 150-153.
doi:10.1016/j.econlet.2013.11.015.


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane

{pstd}
Please report issues or suggestions by email.
