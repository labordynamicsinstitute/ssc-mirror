{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "dnqr"                    "help dnqr"}{...}
{vieweralsosee "dnqr_plot"               "help dnqr_plot"}{...}
{vieweralsosee "dnqr_impulse"            "help dnqr_impulse"}{...}
{vieweralsosee "dnqr_simulate"           "help dnqr_simulate"}{...}
{vieweralsosee "dnqr_postestimation"     "help dnqr_postestimation"}{...}
{vieweralsosee "[R] qreg"                "help qreg"}{...}
{viewerjumpto "Syntax"            "nqar##syntax"}{...}
{viewerjumpto "Description"       "nqar##description"}{...}
{viewerjumpto "Options"           "nqar##options"}{...}
{viewerjumpto "Examples"          "nqar##examples"}{...}
{viewerjumpto "Stored results"    "nqar##results"}{...}
{viewerjumpto "References"        "nqar##references"}{...}
{viewerjumpto "Also see"          "nqar##alsosee"}{...}

{title:Title}

{p2colset 5 14 18 2}{...}
{p2col :{bf:nqar} {hline 2}}Network Quantile Autoregression (Zhu et al. 2019){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:nqar} {it:depvar} {ifin}{cmd:,}
{opth network(name)} [{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opth network(name)}}name of a Stata matrix (default) or Mata matrix that holds the N x N adjacency matrix W{p_end}
{synopt :{opt mata}}declare that {it:network()} refers to a Mata matrix instead of a Stata matrix{p_end}
{synopt :{opt rowstd}}row-standardise W (divide each row by its sum); recommended unless W is already row-stochastic{p_end}
{synopt :{opth q:uantile(numlist)}}quantile(s) at which to estimate; default {bf:0.5}{p_end}
{synopt :{opth z(varlist)}}time-invariant nodal covariates (constant within unit){p_end}
{synopt :{opth f:actors(varlist)}}time-varying common factors (constant within time){p_end}
{synopt :{opt pl:ags(#)}}number of lags of the common factors to include (default {bf:0}){p_end}

{syntab :Inference}
{synopt :{opt b:andwidth(HS|HB)}}Powell SE bandwidth: Hall-Sheather (default) or Bofinger{p_end}
{synopt :{opt bscale(#)}}multiplicative scale for the bandwidth (default {bf:1}); use 3 with HS or 0.6 with HB to match Koenker-Xiao (2006){p_end}
{synopt :{opt l:evel(#)}}confidence-interval level; default 95{p_end}

{syntab :Cosmetic}
{synopt :{opt t:itle(string)}}custom title to display above the table{p_end}
{synopt :{opt nota:ble}}suppress the textual table; useful inside loops{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nqar} estimates the Network Quantile Autoregression model of Zhu,
Wang, Wang and H{c a:}rdle (2019, {it:Journal of Econometrics}).  For each
quantile tau in (0,1) the conditional quantile of {it:depvar} given the
information set is

{phang2}
Q{sub:Y}(tau | F_t) = beta{sub:0}(tau) + Z'gamma(tau)
  + beta{sub:1}(tau) (1/n_i) sum_j a_{ij} Y_{j,t-1}
  + beta{sub:2}(tau) Y_{i,t-1}{p_end}

{pstd}
where {it:W} = {a_ij/n_i} is the row-standardised adjacency matrix, Z are
time-invariant nodal characteristics and beta{sub:1}, beta{sub:2}, gamma
are tau-specific coefficient functions.  Because only {it:lagged} network
terms appear on the right-hand side, the model is identified by standard
quantile regression and consistency follows from the usual conditions on
xtset panel data, with no need for instrumentation.  See {help dnqr:dnqr}
for the extended model that allows {it:contemporaneous} network
spillovers.

{pstd}
The estimator runs {cmd:qreg} once per quantile, retrieves the residuals,
and computes Powell (1986) sandwich standard errors using the
Hall-Sheather (1988) or Bofinger (1975) bandwidth following Koenker and
Xiao (2006).  Optional time-varying common factors F_t (with up to {opt plags(#)}
lags) are appended to the regressor list and treated as exogenous.


{marker options}{...}
{title:Options}

{phang}{opth network(name)} specifies the N x N adjacency or weights
matrix W.  By default {cmd:nqar} expects a Stata matrix; add option
{opt mata} when W lives in Mata.  W must have the same number of rows
as the number of distinct panel ids in the estimation sample.  Use
{opt rowstd} to row-standardise W on the fly.

{phang}{opt mata} indicates that {it:name} in {opt network()} refers to a
Mata matrix.  The matrix is read once with {cmd:st_matrix()}.

{phang}{opt rowstd} divides each row of W by its row sum (the
sociomatrix convention).  Recommended unless W is already row-stochastic.

{phang}{opth quantile(numlist)} sets the quantile grid; multiple values
are accepted, e.g. {cmd:quantile(0.1 0.25 0.5 0.75 0.9)}.  The default
is the median, {cmd:quantile(0.5)}.

{phang}{opth z(varlist)} adds time-invariant nodal covariates (the first
non-missing value within id is used).

{phang}{opth factors(varlist)} adds time-varying common factors (the
first non-missing value within each time period is used).  Combine with
{opt plags(#)} to include lags F_{t-1}, F_{t-2}, ....

{phang}{opt bandwidth(HS|HB)} sets the Powell-bandwidth family.  HS is
Hall-Sheather (1988) and HB is Bofinger (1975); see Koenker and Xiao
(2006) for guidance.

{phang}{opt bscale(#)} multiplies the chosen bandwidth.  Useful values
are 1 and 3 with HS or 0.6 with HB (Koenker-Xiao 2006).

{phang}{opt level(#)} sets the confidence-interval level.


{marker examples}{...}
{title:Examples}

{phang}{cmd}. * simulate a panel + adjacency matrix W{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(80) t(40) gamma1(0) gamma2(0.30) gamma3(0.30) z(2) factors(2) clear wname(W){p_end}

{phang}{cmd}. * fit the NQAR model at five quantiles{txt}{p_end}
{phang}{cmd}. nqar y, network(W) rowstd quantile(0.1 0.25 0.5 0.75 0.9) z(Z1 Z2) factors(F1 F2){p_end}

{phang}{cmd}. * plot the quantile process{txt}{p_end}
{phang}{cmd}. dnqr_plot WY_L1 Y_L1{p_end}

{phang}{cmd}. * tail-event impulse for the median quantile{txt}{p_end}
{phang}{cmd}. dnqr_impulse, network(W) rowstd horizon(8) quantile(0.5) shocknode(1) plot{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:nqar} stores the following in {cmd:e()}.

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(plags)}}number of lags of F{p_end}
{synopt:{cmd:e(level)}}CI level{p_end}
{synopt:{cmd:e(bscale)}}bandwidth scale{p_end}
{synopt:{cmd:e(netdens)}}network density{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:nqar}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(zvars)}}nodal covariates{p_end}
{synopt:{cmd:e(factors)}}common factors{p_end}
{synopt:{cmd:e(bandwidth)}}HS or HB{p_end}
{synopt:{cmd:e(panelvar)}}{help xtset} panel variable{p_end}
{synopt:{cmd:e(timevar)}}{help xtset} time variable{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(quantile)}}1 x q vector of quantiles{p_end}
{synopt:{cmd:e(b_q)}}coefficients, one column per quantile{p_end}
{synopt:{cmd:e(se_q)}}Powell standard errors{p_end}
{synopt:{cmd:e(t_q)}}z-statistics{p_end}
{synopt:{cmd:e(p_q)}}two-sided p-values{p_end}
{synopt:{cmd:e(lo_q)}}lower confidence limit{p_end}
{synopt:{cmd:e(hi_q)}}upper confidence limit{p_end}


{marker references}{...}
{title:References}

{phang}
Koenker, R., and Z. Xiao. 2006. Quantile autoregression. {it:Journal of
the American Statistical Association} 101: 980-990.

{phang}
Powell, J. L. 1986. Censored regression quantiles. {it:Journal of
Econometrics} 32: 143-155.

{phang}
Zhu, X., W. Wang, H. Wang, and W. K. H{c a:}rdle. 2019. Network quantile
autoregression. {it:Journal of Econometrics} 212(1): 345-358.


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
DNQR with contemporaneous network: {help dnqr}{break}
Postestimation: {help dnqr_postestimation}, {help dnqr_plot},
{help dnqr_impulse}{break}
Simulator: {help dnqr_simulate}{break}
Stata builtin: {help qreg}, {help xtset}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
