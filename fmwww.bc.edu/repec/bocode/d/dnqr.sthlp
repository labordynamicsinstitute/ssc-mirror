{smcl}
{* *! version 1.0.1  27may2026}{...}
{vieweralsosee "dnqrlib (package TOC)"   "help dnqrlib"}{...}
{vieweralsosee "nqar"                    "help nqar"}{...}
{vieweralsosee "dnqr_plot"               "help dnqr_plot"}{...}
{vieweralsosee "dnqr_impulse"            "help dnqr_impulse"}{...}
{vieweralsosee "dnqr_simulate"           "help dnqr_simulate"}{...}
{vieweralsosee "dnqr_postestimation"     "help dnqr_postestimation"}{...}
{vieweralsosee "[R] qreg"                "help qreg"}{...}
{viewerjumpto "Syntax"            "dnqr##syntax"}{...}
{viewerjumpto "Description"       "dnqr##description"}{...}
{viewerjumpto "Options"           "dnqr##options"}{...}
{viewerjumpto "Identification"    "dnqr##identification"}{...}
{viewerjumpto "Examples"          "dnqr##examples"}{...}
{viewerjumpto "Stored results"    "dnqr##results"}{...}
{viewerjumpto "References"        "dnqr##references"}{...}
{viewerjumpto "Also see"          "dnqr##alsosee"}{...}

{title:Title}

{p2colset 5 14 18 2}{...}
{p2col :{bf:dnqr} {hline 2}}Dynamic Network Quantile Regression (Xu et al. 2024){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:dnqr} {it:depvar} {ifin}{cmd:,}
{opth network(name)} [{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Main}
{synopt :{opth network(name)}}Stata or Mata matrix holding the N x N adjacency or weights matrix W{p_end}
{synopt :{opt mata}}declare that {it:network()} refers to a Mata matrix{p_end}
{synopt :{opt rowstd}}row-standardise W on the fly{p_end}
{synopt :{opth q:uantile(numlist)}}quantile grid; default {bf:0.5}{p_end}
{synopt :{opth z(varlist)}}time-invariant nodal covariates{p_end}
{synopt :{opth f:actors(varlist)}}time-varying common factors{p_end}
{synopt :{opt pl:ags(#)}}lags of F to include (default {bf:0}){p_end}

{syntab :IVQR settings}
{synopt :{opt iv:type(wy2|wy3|wy23)}}instrument set for the contemporaneous WY: {bf:wy2}=W{c 178}Y{sub:-1}, {bf:wy3}=W{c 179}Y{sub:-1}, {bf:wy23}=both (default){p_end}
{synopt :{opt gr:idpoints(#)}}half-grid length (one side); default {bf:41} => 83-point grid{p_end}
{synopt :{opt gridscale(#)}}grid radius in pilot-SE units; default {bf:4}{p_end}
{synopt :{opt grid(numlist)}}user-supplied alpha grid that overrides {opt gridpoints/gridscale}{p_end}

{syntab :Inference}
{synopt :{opt b:andwidth(HS|HB)}}Powell SE bandwidth (default {bf:HS}){p_end}
{synopt :{opt bscale(#)}}multiplicative scale for the bandwidth (default {bf:1}){p_end}
{synopt :{opt l:evel(#)}}confidence level; default 95{p_end}

{syntab :Cosmetic}
{synopt :{opt t:itle(string)}}custom title{p_end}
{synopt :{opt nota:ble}}suppress the table; useful in loops{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dnqr} estimates the Dynamic Network Quantile Regression model of
Xu, Wang, Shin and Zheng (2024).  For each quantile tau in (0,1) the
conditional quantile of {it:depvar} given the information set is

{phang2}
Q{sub:Y}(tau | F_t) = gamma{sub:0}(tau) + Z'alpha(tau)
  + gamma{sub:1}(tau) (1/n_i) sum_j a_{ij} Y_{j,t}
  + gamma{sub:2}(tau) (1/n_i) sum_j a_{ij} Y_{j,t-1}
  + gamma{sub:3}(tau) Y_{i,t-1}
  + sum_{k=0..p} F_{t-k}' beta_k(tau){p_end}

{pstd}
The {it:contemporaneous} network mean sum_j w_{ij} Y_{jt} is endogenous
under the simultaneous-spillover assumption.  Plugging it directly into
{help qreg} would produce an inconsistent estimator.  {cmd:dnqr} therefore
follows the instrumental variable quantile regression (IVQR) approach of
Chernozhukov and Hansen (2006) and estimates gamma{sub:1}(tau) by a
one-dimensional grid search: for each candidate alpha, the working
quantile regression of Y - alpha * W Y_t on (instruments, exogenous
regressors) is fit and the L{sub:2} norm of the instrument coefficients
is computed; alpha-hat is the minimiser.  Standard errors follow Powell
(1986) sandwich with Hall-Sheather or Bofinger bandwidth (Koenker-Xiao
2006).

{pstd}
The estimator works in Stata 13 and above and requires only the built-in
{help qreg:qreg}.  In particular, it does {it:not} depend on the official
{help ivqregress} command, which is available only from Stata 18 onward.


{marker options}{...}
{title:Options}

{phang}{opth network(name)} specifies the N x N adjacency or weights matrix.
By default {cmd:dnqr} expects a Stata matrix; add {opt mata} when W lives
in Mata.

{phang}{opt mata} declares that {it:name} in {opt network()} is a Mata
matrix.

{phang}{opt rowstd} row-standardises W.

{phang}{opth quantile(numlist)} sets the quantile grid.

{phang}{opth z(varlist)} adds nodal time-invariant covariates.

{phang}{opth factors(varlist)} adds time-varying common factors.

{phang}{opt plags(#)} number of lags of the common factors.

{phang}{opt ivtype(wy2|wy3|wy23)} chooses the instrument set:

{p 12 16 2}
{bf:wy2}   - the single instrument {it:W{sup:2}Y{sub:t-1}};{break}
{bf:wy3}   - the single instrument {it:W{sup:3}Y{sub:t-1}};{break}
{bf:wy23}  - both (over-identified; default).{p_end}

{phang}{opt gridpoints(#)} sets the {it:one-sided} grid length.  The
actual grid has 2*{it:#}+1 points centred at the pilot estimate.

{phang}{opt gridscale(#)} sets the grid radius in pilot-SE units;
larger values widen the search but slow estimation.

{phang}{opt grid(numlist)} overrides the default grid construction with
a user-supplied numlist (sorted automatically by the syntax parser).

{phang}{opt bandwidth(HS|HB)} Powell-bandwidth family.

{phang}{opt bscale(#)} bandwidth scaling.

{phang}{opt level(#)} confidence level.

{phang}{opt notable} suppresses the textual table; useful inside Monte
Carlo loops.


{marker identification}{...}
{title:Identification and the IVQR grid}

{pstd}
The contemporaneous spatial mean W Y_t is correlated with Y_t by
construction.  Following Su and Yang (2011) and the DNQR paper, valid
instruments are higher powers of W applied to the lagged response,
i.e. W{sup:2} Y_{t-1}, W{sup:3} Y_{t-1}, ..., which are correlated with
W Y_t through the reduced-form (I - gamma{sub:1} W){sup:-1} but
uncorrelated with the time-t innovation.  Over-identification (option
{bf:wy23}) is recommended in practice as it tightens the grid-search
minimum.

{pstd}
By default the grid is centred at the {it:pilot} qreg estimate of
gamma{sub:1} (i.e., qreg with the endogenous term included) and spans
{opt gridscale} pilot-SE units in each direction with {opt gridpoints}
nodes per side.  Override the entire grid with {opt grid(numlist)} when
you need a domain-specific search range, e.g. {cmd:grid(-0.05(0.005)0.55)}.


{marker examples}{...}
{title:Examples}

{phang}{cmd}. * 1. simulate a DGP with contemporaneous network effect{txt}{p_end}
{phang}{cmd}. dnqr_simulate, n(100) t(60) gamma1(0.30) gamma2(0.20) gamma3(0.30) z(2) factors(2) clear wname(W){p_end}

{phang}{cmd}. * 2. fit DNQR at five quantiles{txt}{p_end}
{phang}{cmd}. dnqr y, network(W) rowstd quantile(0.1 0.25 0.5 0.75 0.9) z(Z1 Z2) factors(F1 F2) ivtype(wy23){p_end}

{phang}{cmd}. * 3. quantile coefficient plot{txt}{p_end}
{phang}{cmd}. dnqr_plot WY WY_L1 Y_L1 Z1 Z2{p_end}

{phang}{cmd}. * 4. tail impulse at tau = 0.9{txt}{p_end}
{phang}{cmd}. dnqr_impulse, network(W) rowstd horizon(12) quantile(0.9) shocknode(1) plot{p_end}

{phang}{cmd}. * 5. user-supplied grid (e.g. to explore wider alpha range){txt}{p_end}
{phang}{cmd}. dnqr y, network(W) rowstd quantile(0.5) grid(-0.05(0.005)0.55){p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:dnqr} stores the following in {cmd:e()}.

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(plags)}}common-factor lags{p_end}
{synopt:{cmd:e(level)}}CI level{p_end}
{synopt:{cmd:e(bscale)}}bandwidth scale{p_end}
{synopt:{cmd:e(gridpts)}}grid points per side{p_end}
{synopt:{cmd:e(gridscale)}}grid radius{p_end}
{synopt:{cmd:e(netdens)}}network density{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:dnqr}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(zvars)}}nodal covariates{p_end}
{synopt:{cmd:e(factors)}}common factors{p_end}
{synopt:{cmd:e(bandwidth)}}HS or HB{p_end}
{synopt:{cmd:e(ivtype)}}wy2 / wy3 / wy23{p_end}
{synopt:{cmd:e(panelvar)}}{help xtset} panel variable{p_end}
{synopt:{cmd:e(timevar)}}{help xtset} time variable{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(quantile)}}1 x q quantile grid{p_end}
{synopt:{cmd:e(b_q)}}coefficients per quantile (rows = vars, cols = tau){p_end}
{synopt:{cmd:e(se_q)}}Powell standard errors{p_end}
{synopt:{cmd:e(t_q)}}z-statistics{p_end}
{synopt:{cmd:e(p_q)}}two-sided p-values{p_end}
{synopt:{cmd:e(lo_q)}}lower CI{p_end}
{synopt:{cmd:e(hi_q)}}upper CI{p_end}
{synopt:{cmd:e(alphahat)}}IVQR grid minimiser per tau{p_end}
{synopt:{cmd:e(gnorm)}}value of the IV norm at the minimiser{p_end}


{marker references}{...}
{title:References}

{phang}
Chernozhukov, V., and C. Hansen. 2006. Instrumental quantile regression
inference for structural and treatment effect models. {it:Journal of
Econometrics} 132: 491-525.

{phang}
Koenker, R., and Z. Xiao. 2006. Quantile autoregression. {it:Journal of
the American Statistical Association} 101: 980-990.

{phang}
Powell, J. L. 1986. Censored regression quantiles. {it:Journal of
Econometrics} 32: 143-155.

{phang}
Su, L., and Z. Yang. 2011. Instrumental variable quantile estimation of
spatial autoregressive models. Working Paper.

{phang}
Xu, X., W. Wang, Y. Shin, and C. Zheng. 2024. {it:Dynamic Network
Quantile Regression Model}. SSRN Working Paper 3690631.


{marker alsosee}{...}
{title:Also see}

{p 4 14 2}
Package TOC: {help dnqrlib}{break}
NQAR (lagged-network baseline): {help nqar}{break}
Postestimation: {help dnqr_postestimation}, {help dnqr_plot},
{help dnqr_impulse}{break}
Simulator: {help dnqr_simulate}{break}
Stata builtin: {help qreg}, {help xtset}{p_end}

{p 4 4 2}
{bf:Author:} Dr Merwan Roudane {c -}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
