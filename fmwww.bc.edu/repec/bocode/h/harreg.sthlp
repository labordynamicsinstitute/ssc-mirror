{smcl}
{* *! version 1.0.0 15may2026}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "[TS] newey" "help newey"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "harwald" "help harwald"}{...}
{viewerjumpto "Syntax" "harreg##syntax"}{...}
{viewerjumpto "Description" "harreg##description"}{...}
{viewerjumpto "Options" "harreg##options"}{...}
{viewerjumpto "Remarks" "harreg##remarks"}{...}
{viewerjumpto "Examples" "harreg##examples"}{...}
{viewerjumpto "Stored results" "harreg##results"}{...}
{viewerjumpto "References" "harreg##refs"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col:{bf:harreg} {hline 2}}Time-series regression with HAR standard errors and fixed-b inference{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:harreg} {depvar} [{indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:HAR}
{synopt:{opt est:imator(type)}}LRV estimator: {cmd:ewc}, {cmd:ewp}, {cmd:nw}, or {cmd:qs}; default is {cmd:ewc}{p_end}
{synopt:{opt lags(#)}}sets the truncation parameter {it:S} for {cmd:nw} or {cmd:qs} (for {cmd:nw}, Bartlett weights are nonzero at lags 1 to {it:S}-1){p_end}
{synopt:{opt df(#)}}degrees of freedom parameter {it:nu} for {cmd:ewc}, {cmd:ewp}, or {cmd:qs}{p_end}

{syntab:Inference}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt critdraws(#)}}Monte Carlo draws for {cmd:nw}/{cmd:qs} critical values; default is 5000{p_end}
{synopt:{opt seed(#)}}random-number seed for simulations{p_end}

{syntab:Reporting}
{synopt:{opt nohe:ader}}suppress the table header{p_end}
{synopt:{opt notab:le}}suppress the coefficient table{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:harreg}; see {manhelp tsset TS}.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators (see {help tsvarlist})
and factor-variable notation (see {help fvvarlist}); for example,
{cmd:harreg y x i.region c.x##c.x}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:harreg} fits a time-series regression by OLS and reports
heteroskedasticity- and autocorrelation-robust (HAR) standard errors
based on fixed-{it:b} asymptotics, as recommended by
Lazarus, Lewis, Stock, and Watson (LLSW, 2018) and Lazarus, Lewis, and Stock (LLS, 2021).

{pstd}
The default estimator is the equal-weighted cosine (EWC) with
{it:nu} = floor(0.41*T^(2/3)), as recommended by LLSW (2018).
Alternative long-run variance (LRV) estimators include
equal-weighted periodogram (EWP),
Newey-West/Bartlett (NW), and
quadratic spectral (QS).

{pstd}
The default rules for the truncation parameter ({cmd:nw}, {cmd:qs}) and
degrees of freedom ({cmd:ewc}, {cmd:ewp}) are designed to optimize the
tradeoff between test size (controlling the probability of false rejection)
and size-adjusted power, following LLSW (2018).

{pstd}
For {cmd:ewc} and {cmd:ewp}, inference uses t({it:nu}) and F({it:m},{it:nu}-{it:m}+1)
reference distributions, where {it:m} is the number of restrictions tested.
For {cmd:nw} and {cmd:qs}, {cmd:harreg} simulates the fixed-{it:b} null distribution
to obtain p-values and critical values.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt noconstant} suppresses the constant term (intercept) in the model.

{dlgtab:HAR}

{phang}
{opt estimator(type)} specifies the long-run variance estimator.
{it:type} may be {cmd:ewc} (equal-weighted cosine, the default),
{cmd:ewp} (equal-weighted periodogram),
{cmd:nw} (Newey-West/Bartlett), or
{cmd:qs} (quadratic spectral).

{phang}
{opt lags(#)} specifies the truncation parameter {it:S} for the {cmd:nw} or {cmd:qs} kernel estimators.
The default for {cmd:nw} is {it:S} = ceil(1.3*sqrt(T)).
The default for {cmd:qs} is {it:S} = ceil(T/{it:nu}) where {it:nu} = floor(0.41*T^(2/3)).
These defaults are chosen to optimize the tradeoff between
test size and size-adjusted power, as derived in LLSW (2018) and LLS (2021).
If {opt lags()} is specified for orthonormal series estimators {cmd:ewc} or {cmd:ewp},
the option will be ignored and the default will be used.

{phang}
{opt df(#)} specifies the degrees of freedom parameter {it:nu} for the {cmd:ewc} or {cmd:ewp}
orthonormal series estimators.
The default is {it:nu} = floor(0.41*T^(2/3)), chosen to optimize the tradeoff
between test size and size-adjusted power following LLSW (2018, eq. (4)) and LLS (2021).
For {cmd:ewp}, {it:nu} is restricted to be even; any odd-number input will be
rounded down to the nearest even integer.
{opt df(#)} may also be specified for {cmd:qs}; if {opt lags()} is also specified,
{opt lags()} takes precedence, and otherwise {it:S} = ceil(T/{it:nu}).

{dlgtab:Inference}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for
confidence intervals.  The default is {cmd:level(95)} or as set by
{helpb set level}.

{phang}
{opt critdraws(#)} specifies the number of Monte Carlo draws used
to simulate fixed-{it:b} critical values when the estimator is {cmd:nw} or {cmd:qs}.
The default is 5000; the minimum is 1000.

{phang}
{opt seed(#)} specifies the random-number seed for simulations.
The default ensures reproducible critical values across runs.
Specify {cmd:seed(0)} to use a different random seed each time.

{dlgtab:Reporting}

{phang}
{opt noheader} suppresses the display of the header above the
coefficient table.

{phang}
{opt notable} suppresses the display of the coefficient table.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:harreg} requires the time variable to be regularly spaced with no gaps.

{pstd}
After {cmd:harreg}, you can use {helpb harwald} for joint Wald tests of
coefficients with fixed-{it:b} critical values.
{helpb predict} is available with options
{cmd:xb} (fitted values, the default) and {cmd:residuals}.

{pstd}
Use {helpb harwald} for coefficient tests: it applies the fixed-{it:b}
reference distribution that matches the estimator chosen at the
{cmd:harreg} call, whereas general post-estimation commands would
use a standard reference distribution.

{pstd}
{cmd:harreg} fits linear regression models by OLS; instrumental-variables
estimation is not supported.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. tsset}{p_end}

{pstd}Basic HAR regression using default EWC estimator{p_end}
{phang2}{cmd:. harreg dln_inv dln_inc dln_consump}{p_end}

{pstd}Newey-West estimator with truncation parameter {it:S} = 8{p_end}
{phang2}{cmd:. harreg dln_inv dln_inc dln_consump, estimator(nw) lags(8)}{p_end}

{pstd}EWP estimator with specified degrees of freedom{p_end}
{phang2}{cmd:. harreg dln_inv dln_inc dln_consump, estimator(ewp) df(20)}{p_end}

{pstd}Joint Wald test after estimation{p_end}
{phang2}{cmd:. harwald dln_inc dln_consump}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:harreg} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(mss)}}model sum of squares{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares{p_end}
{synopt:{cmd:e(tss)}}total sum of squares{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(bw)}}truncation parameter {it:S} ({cmd:nw}/{cmd:qs}) or degrees of freedom {it:nu} ({cmd:ewc}/{cmd:ewp}){p_end}
{synopt:{cmd:e(df_fb)}}fixed-{it:b} degrees of freedom{p_end}
{synopt:{cmd:e(cv_fb)}}fixed-{it:b} critical value at {cmd:e(level)}{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(F_fb)}}model F statistic (fixed-{it:b}){p_end}
{synopt:{cmd:e(p_fb)}}p-value for model F{p_end}
{synopt:{cmd:e(cvF_fb)}}critical value for model F at {cmd:e(level)}{p_end}
{synopt:{cmd:e(F)}}model F statistic ({cmd:regress}-style alias of {cmd:e(F_fb)}){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:harreg}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title for output{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(estimator)}}LRV estimator used{p_end}
{synopt:{cmd:e(vce)}}HAR sub-method ({cmd:har ewc}, {cmd:har nw}, etc.){p_end}
{synopt:{cmd:e(vcetype)}}{cmd:HAR}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of estimators{p_end}
{synopt:{cmd:e(se)}}standard errors{p_end}
{synopt:{cmd:e(t)}}t statistics{p_end}
{synopt:{cmd:e(p)}}p-values{p_end}
{synopt:{cmd:e(ci_lo)}}lower confidence bounds{p_end}
{synopt:{cmd:e(ci_hi)}}upper confidence bounds{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}


{marker refs}{...}
{title:References}

{phang}
Lazarus, E., D. J. Lewis, J. H. Stock, and M. W. Watson. 2018.
HAR inference: Recommendations for practice.
{it:Journal of Business & Economic Statistics} 36: 541-559.

{phang}
Lazarus, E., D. J. Lewis, and J. H. Stock. 2021.
The size-power tradeoff in HAR inference.
{it:Econometrica} 89: 2497-2516.

{phang}
Sun, Y. 2013.
A heteroskedasticity and autocorrelation robust F test using an orthonormal
series variance estimator.
{it:Econometrics Journal} 16: 1-26.

{phang}
Ye, X., and Y. Sun. 2018.
Heteroskedasticity- and autocorrelation-robust F and t tests in Stata.
{it:Stata Journal} 18: 951-980.


{title:Acknowledgements}

{pstd}
This command builds on the {cmd:har} command provided by Xiaoqing Ye and
Yixiao Sun and the {cmd:neweyfixedb} command provided by Tim Vogelsang.
We thank the authors of those commands.


{title:Authors}

{pstd}
Eben Lazarus, UC Berkeley{break}
lazarus@berkeley.edu
{p_end}

{pstd}
Daniel J. Lewis, University College London{break}
daniel.j.lewis@ucl.ac.uk
{p_end}
