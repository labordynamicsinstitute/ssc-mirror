{smcl}
{* *! version 2.0.0  03may2026}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:pocoint} {hline 2}}Phillips-Ouliaris cointegration test{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmd:pocoint} {varlist} {ifin} [{cmd:,} {it:options}]


{phang}
{varlist} contains 2 to 13 numeric time-series variables.  The first
variable is the dependent variable in the cointegrating regression; the
remaining variables are the regressors.  The data must be {cmd:tsset} as
a pure time series (no panel).{p_end}


{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt test(string)}}choose the test statistic:
{cmd:Za}, {cmd:Zt}, {cmd:Pu}, or {cmd:Pz}; default is {cmd:Zt}{p_end}
{synopt :}defaults across implementations: {cmd:pocoint} = {cmd:Zt};
Python {bf:arch} = {cmd:Zt}; R {bf:urca::ca.po} = {cmd:Pu}; R
{bf:tseries::po.test} reports {cmd:Za} only; EViews reports both
{cmd:Za} and {cmd:Zt} side-by-side{p_end}
{synopt :{opt tr:end(string)}}deterministic terms in the cointegrating
regression: {cmd:n} (none), {cmd:c} (constant, default),
{cmd:ct} (constant + trend), or {cmd:ctt} (constant + trend + trend^2){p_end}
{synopt :{opt k:ernel(string)}}long-run-variance kernel:
{cmd:bartlett} (default), {cmd:parzen}, or {cmd:quadratic-spectral}
(synonym {cmd:qs}){p_end}
{synopt :{opt l:ags(#)}}user-specified kernel bandwidth (truncation lag); overrides {cmd:auto}, {cmd:lshort}, and {cmd:llong}{p_end}
{synopt :{opt auto}}data-driven bandwidth via the Andrews/Newey-West rule
(matches Python {bf:arch}'s default){p_end}
{synopt :{opt lsh:ort}}use the short bandwidth {bf:trunc((n-1)/100)} (default){p_end}
{synopt :{opt llong}}use the long bandwidth {bf:trunc((n-1)/30)}{p_end}
{synopt :{opt res:id(name)}}save the cointegrating-regression residuals
in a new variable {it:name}{p_end}
{synopt :{opt ts:eries}}force backwards-compatible mode that
reproduces R's {bf:tseries::po.test} exactly: only {cmd:Za} with
{cmd:trend(c)} or {cmd:trend(n)}; Bartlett kernel only; p-value via
R's built-in tabulated grid{p_end}
{synopt :{opt ur:ca}}force backwards-compatible mode that reproduces R's
{bf:urca::ca.po} exactly: only {cmd:Pu} and {cmd:Pz}, Bartlett kernel,
{cmd:trend(n)}, {cmd:trend(c)}, or {cmd:trend(ct)}; up to 6 variables;
fixed urca critical-value table; no p-value{p_end}
{synopt :{opt ev:iews}}force backwards-compatible mode that reproduces
the EViews default Phillips-Ouliaris output: both {cmd:Z(alpha)} and
{cmd:Z(t)} are computed; Bartlett kernel; Newey-West fixed bandwidth
{bf:trunc(4*(T/100)^(2/9))}; demeaned cointegrating regression; no
d.f. adjustment; no other option may be specified{p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:pocoint} computes the four Phillips-Ouliaris (1990) residual-based
tests of the null hypothesis of no cointegration:

{phang}-{space 2}{cmd:Za}: Phillips Z(alpha) coefficient test{p_end}
{phang}-{space 2}{cmd:Zt}: Phillips Z(t) t-ratio test (default){p_end}
{phang}-{space 2}{cmd:Pu}: variance ratio test introduced in the paper{p_end}
{phang}-{space 2}{cmd:Pz}: multivariate trace test (invariant to the
normalization of the cointegrating regression){p_end}

{pstd}
The first stage runs a static OLS cointegrating regression of the first
variable on the remaining variables (and the chosen deterministic
terms).  The residual-based statistic is then constructed from a
Bartlett-kernel long-run-variance estimator with the truncation lag
controlled by {cmd:lags()}, {cmd:lshort}, or {cmd:llong}.

{pstd}
Critical values at the 1%, 5%, and 10% levels and asymptotic p-values
are obtained from a response-surface fit (Hansen-Haug type), simulated
by Kevin Sheppard for the Python {bf:arch} package, with up to 25
million Monte Carlo replications per cell.  The same response surface
allows up to 13 variables in the cointegrating regression.

{pstd}
The {cmd:tseries} option reproduces the older R routine
{bf:tseries::po.test} (A. Trapletti) exactly to within machine
precision.  In that mode only {cmd:Za} with {cmd:trend(c)} or
{cmd:trend(n)} is computed.  The p-value is obtained by linear
interpolation on R's built-in critical-value table (returning one of
0.01, 0.025, 0.05, 0.075, 0.10, 0.125, 0.15 for statistics outside the
table boundaries) with R's "smaller/greater than printed p-value"
warning.

{pstd}
The {cmd:urca} option reproduces the R routine {bf:urca::ca.po}
(B. Pfaff) exactly.  Only {cmd:Pu} and {cmd:Pz} are available with
{cmd:trend(n)}, {cmd:trend(c)}, or {cmd:trend(ct)}, the bandwidth is
fixed to urca's {cmd:lshort}/{cmd:llong} formulas, and critical values
come from urca's internal table; no p-value is reported.  Note that
urca's {cmd:Pz} uses a different moment matrix from the
{bf:arch}/Hansen-Haug formulation, so the two implementations
intentionally produce different statistics.

{pstd}
The {cmd:eviews} option reproduces the EViews default
Phillips-Ouliaris output exactly.  Both {cmd:Za} and {cmd:Zt} are
reported in a single table, with Bartlett kernel, Newey-West fixed
bandwidth {bf:trunc(4*(T/100)^(2/9))}, demeaned cointegrating
regression, and no degrees-of-freedom adjustment.  No other option
may be specified in this mode.  Test statistics agree with EViews to
machine precision; p-values use the Hansen-Haug response surface
(EViews itself reports MacKinnon (1996) p-values, which differ
slightly).


{title:Options}

{phang}
{opt test(string)} selects which Phillips-Ouliaris statistic to
compute: {cmd:Zt} (default), {cmd:Za}, {cmd:Pu}, or {cmd:Pz}.
The {cmd:Z}-tests are lower-tail (reject if statistic is below the
critical value).  The {cmd:P}-tests are upper-tail (reject if statistic
is above the critical value).

{phang}
{opt trend(string)} controls the deterministic terms included in the
cointegrating regression and in the residual-based step.  The four
choices and their {bf:arch} equivalents are: {cmd:n}/{cmd:none},
{cmd:c}/{cmd:constant}, {cmd:ct}, and {cmd:ctt}.  Different trend
choices have different asymptotic distributions, and {cmd:pocoint}
selects the matching response-surface coefficients automatically.

{phang}
{opt kernel(string)} selects the kernel used to estimate the long-run
variance of the residual-based AR(1) innovations.  All
Phillips-Ouliaris statistics depend on a HAC long-run-variance
estimate; different kernels give different finite-sample size and
power but converge to the same asymptotic distribution.  Choices
are {cmd:bartlett} (default; the original Newey-West kernel), {cmd:parzen}
(smoother weights, lower bias), and {cmd:quadratic-spectral} (or its
synonym {cmd:qs}; optimal in a mean-squared-error sense for many
data-generating processes).  Python {bf:arch}, R {bf:tseries}, and R
{bf:urca} all use Bartlett by default.

{phang}
{opt lags(#)} fixes the kernel truncation lag (the bandwidth) at a
user-supplied value.  The bandwidth controls how many sample
autocovariances enter the long-run-variance estimate: {cmd:lags(0)}
gives the White covariance with no autocovariance correction (the
test statistic then reduces to a simple Phillips Z(alpha)/Z(t)),
while larger values capture more serial correlation but increase
finite-sample variance.  {cmd:lags()} overrides {cmd:auto},
{cmd:lshort}, and {cmd:llong}.

{phang}
{opt auto} requests an automatic data-driven bandwidth via the
Andrews (1991) / Newey-West (1994) plug-in rule.  This is the
default behaviour in Python {bf:arch}, and using {cmd:auto} together
with {cmd:kernel(bartlett)} reproduces arch's default to machine
precision.  The chosen bandwidth depends on the kernel and on a
preliminary AR(1) fit to the residual-based innovations; it is
displayed in the output along with the rule used.

{phang}
{opt lshort} (default) sets the truncation lag to the simple
short-bandwidth rule {bf:trunc((n-1)/100)} (Schwert (1989), used by
R {bf:tseries::po.test}).  The lag grows slowly with the sample size
and is appropriate for residuals with mild serial correlation.

{phang}
{opt llong} sets the truncation lag to the long-bandwidth rule
{bf:trunc((n-1)/30)} (also from Schwert (1989) and used by R
{bf:tseries::po.test} when {cmd:lshort=FALSE}).  Use this when the
data show strong persistence or large negative moving-average
components, since a longer window captures more of the spectral mass
near the origin.

{phang}
{opt resid(name)} saves the residuals from the cointegrating
regression as a new variable {it:name}.  These are the OLS residuals
{it:u_t} from the first-stage long-run regression of the dependent
variable on the regressors and deterministic terms.  Useful for
post-estimation work such as plotting (e.g. {cmd:tsline name}),
running an additional unit-root test on the residuals
(e.g. {cmd:dfuller name}), or supplying the error-correction term to a
subsequent VECM step.

{phang}
{opt tseries} forces the backwards-compatible mode that mirrors
{bf:tseries::po.test} from R.  Only {cmd:Za} with {cmd:trend(c)} is
computed, with the older Newey-West correction (slightly different
from the {bf:arch}/Hansen-Haug formulation).  In this mode no asymptotic
p-value is reported; only the test statistic and the original
Phillips-Ouliaris (1990) Tables Ia/Ib critical values would apply.

{phang}
{opt urca} forces the backwards-compatible mode that mirrors R's
{bf:urca::ca.po}.  Supports {cmd:Pu} and {cmd:Pz} with
{cmd:trend(n)}, {cmd:trend(c)}, or {cmd:trend(ct)} only, up to 6
variables.  The bandwidth defaults to {bf:trunc(4*((n-1)/100)^0.25)}
({cmd:lshort}) or {bf:trunc(12*((n-1)/100)^0.25)} ({cmd:llong}).
Critical values come from the fixed table embedded in urca.  The
{cmd:Pz} formulation in urca uses {bf:M_zz} computed from raw lagged
levels (without prior trend demeaning) and therefore differs from the
{bf:arch}/Hansen-Haug formulation that follows the article's remark
(f) on p. 173.  No asymptotic p-value is reported.

{phang}
{opt eviews} forces the backwards-compatible mode that reproduces the
EViews default Phillips-Ouliaris cointegration test.  Both
{cmd:Z(alpha)} and {cmd:Z(t)} are computed and reported in the same
table.  All settings are fixed to the EViews defaults and no other
option ({cmd:test()}, {cmd:trend()}, {cmd:kernel()}, {cmd:lags()},
{cmd:auto}, {cmd:lshort}, {cmd:llong}, {cmd:resid()}) may be
specified: Bartlett kernel, Newey-West fixed bandwidth
{bf:trunc(4*(T/100)^(2/9))}, demeaned cointegrating regression
({cmd:trend(c)}), no degrees-of-freedom adjustment for the long-run
variance.  The algorithm uses the bias-corrected autoregressive
coefficient {bf:rho* - 1 = (rho - 1) - T_eff*lambda/sum(u^2_lag)}
together with the EViews convention {bf:T_eff = T - 1} (the number of
residuals after the AR(1) regression on the cointegrating
residuals).  This differs from {cmd:pocoint}'s default formula, which
follows Phillips and Ouliaris (1990) and uses the original sample
size {bf:T} as the normalization factor (see Examples below for the
algorithmic difference).  Critical values and p-values come from the
Hansen-Haug response surface; EViews itself reports MacKinnon (1996)
p-values.  Test statistics agree with EViews to machine precision;
p-values may differ slightly because of the different response
surface.


{title:Stored results}

{pstd}
{cmd:pocoint} stores different results in {cmd:r()} depending on which
mode is used.  All four modes share {cmd:r(statistic)}, {cmd:r(n)},
{cmd:r(lag)}, and {cmd:r(method)}.

{pstd}
{bf:Default mode} (Hansen-Haug response surface):

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(statistic)}}test statistic{p_end}
{synopt:{cmd:r(p)}}asymptotic p-value (Hansen-Haug response surface){p_end}
{synopt:{cmd:r(cv_1pct)}}1% critical value{p_end}
{synopt:{cmd:r(cv_5pct)}}5% critical value{p_end}
{synopt:{cmd:r(cv_10pct)}}10% critical value{p_end}
{synopt:{cmd:r(minN)}}smallest N used to fit the response surface{p_end}
{synopt:{cmd:r(lag)}}kernel truncation lag (bandwidth) used{p_end}
{synopt:{cmd:r(n)}}effective sample size{p_end}
{synopt:{cmd:r(nvars)}}number of variables in the cointegrating regression{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}"Phillips-Ouliaris (1990) cointegration test"{p_end}
{synopt:{cmd:r(test)}}test type used: Za / Zt / Pu / Pz{p_end}
{synopt:{cmd:r(trend)}}deterministic specification: n / c / ct / ctt{p_end}
{synopt:{cmd:r(kernel)}}kernel used: bartlett / parzen / quadratic-spectral{p_end}
{synopt:{cmd:r(bw_method)}}bandwidth selection method (e.g. "lshort", "auto: Andrews/Newey-West"){p_end}
{synopt:{cmd:r(depvar)}}dependent variable in the cointegrating regression{p_end}
{synopt:{cmd:r(indeps)}}regressors in the cointegrating regression{p_end}

{pstd}
{bf:tseries mode} ({cmd:tseries} option):

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(statistic)}}Z(alpha) statistic{p_end}
{synopt:{cmd:r(p)}}p-value from R's tabulated grid (one of 0.01, 0.025, 0.05, 0.075, 0.10, 0.125, 0.15){p_end}
{synopt:{cmd:r(alpha)}}OLS estimate of the AR(1) coefficient on the residuals{p_end}
{synopt:{cmd:r(lag)}}Bartlett bandwidth used{p_end}
{synopt:{cmd:r(n)}}effective sample size{p_end}
{synopt:{cmd:r(tseries)}}1 (mode flag){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}"Phillips-Ouliaris (tseries::po.test compatible)"{p_end}
{synopt:{cmd:r(trend)}}deterministic specification: n or c{p_end}

{pstd}
{bf:urca mode} ({cmd:urca} option):

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(statistic)}}test statistic (Pu or Pz){p_end}
{synopt:{cmd:r(cv_1pct)}}1% critical value (urca's internal table){p_end}
{synopt:{cmd:r(cv_5pct)}}5% critical value{p_end}
{synopt:{cmd:r(cv_10pct)}}10% critical value{p_end}
{synopt:{cmd:r(lag)}}Bartlett bandwidth used{p_end}
{synopt:{cmd:r(n)}}effective sample size{p_end}
{synopt:{cmd:r(nvars)}}number of variables in the cointegrating regression{p_end}
{synopt:{cmd:r(urca)}}1 (mode flag){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}"Phillips-Ouliaris (urca::ca.po compatible)"{p_end}
{synopt:{cmd:r(test)}}test type used: Pu or Pz{p_end}
{synopt:{cmd:r(trend)}}deterministic specification: n / c / ct{p_end}

{pstd}
{bf:eviews mode} ({cmd:eviews} option):

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(z)}}Z(alpha) test statistic{p_end}
{synopt:{cmd:r(tau)}}Z(t) test statistic{p_end}
{synopt:{cmd:r(p_z)}}p-value for Z(alpha) (Hansen-Haug response surface){p_end}
{synopt:{cmd:r(p_tau)}}p-value for Z(t) (Hansen-Haug response surface){p_end}
{synopt:{cmd:r(rho)}}OLS estimate of the AR(1) coefficient{p_end}
{synopt:{cmd:r(rho_star)}}bias-corrected AR(1) coefficient{p_end}
{synopt:{cmd:r(rho_se)}}standard error of the bias-corrected coefficient{p_end}
{synopt:{cmd:r(sigma2)}}residual variance (no d.f. adjustment){p_end}
{synopt:{cmd:r(omega2)}}long-run residual variance{p_end}
{synopt:{cmd:r(lambda)}}one-sided long-run residual autocovariance{p_end}
{synopt:{cmd:r(lag)}}Newey-West fixed bandwidth{p_end}
{synopt:{cmd:r(n)}}effective sample size{p_end}
{synopt:{cmd:r(nvars)}}number of variables in the cointegrating regression{p_end}
{synopt:{cmd:r(eviews)}}1 (mode flag){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(method)}}"Phillips-Ouliaris (EViews compatible)"{p_end}
{synopt:{cmd:r(kernel)}}"bartlett"{p_end}
{synopt:{cmd:r(trend)}}"c"{p_end}


{title:Examples}

{pstd}
The standard Z(t) demeaned test (the default, matching Python {bf:arch}):{p_end}

{phang2}{cmd:. webuse lutkepohl2}{p_end}
{phang2}{cmd:. pocoint consump inc}{p_end}

{pstd}
All four Phillips-Ouliaris tests with a constant + linear trend in the
cointegrating regression:{p_end}

{phang2}{cmd:. pocoint consump inc, test(Za) trend(ct)}{p_end}
{phang2}{cmd:. pocoint consump inc, test(Zt) trend(ct)}{p_end}
{phang2}{cmd:. pocoint consump inc, test(Pu) trend(ct)}{p_end}
{phang2}{cmd:. pocoint consump inc, test(Pz) trend(ct)}{p_end}

{pstd}
A test with a manual bandwidth of 6 and the multivariate-trace
statistic Pz:{p_end}

{phang2}{cmd:. pocoint consump inc, test(Pz) trend(c) lags(6)}{p_end}

{pstd}
Use a Parzen kernel with the Andrews/Newey-West data-driven bandwidth
(matches Python {bf:arch}'s default behaviour):{p_end}

{phang2}{cmd:. pocoint consump inc, kernel(parzen) auto}{p_end}

{pstd}
Quadratic-spectral kernel with auto bandwidth:{p_end}

{phang2}{cmd:. pocoint consump inc, kernel(qs) auto}{p_end}

{pstd}
Save the cointegrating-regression residuals for further inspection
(e.g. for use as the error-correction term in a VECM step):{p_end}

{phang2}{cmd:. pocoint consump inc, test(Za) trend(c) resid(uhat)}{p_end}
{phang2}{cmd:. tsline uhat}{p_end}
{phang2}{cmd:. dfuller uhat, noconstant}{p_end}

{pstd}
Backwards-compatible mode reproducing R {bf:tseries::po.test}:{p_end}

{phang2}{cmd:. pocoint consump inc, tseries}{p_end}

{pstd}
Backwards-compatible mode reproducing R {bf:urca::ca.po}:{p_end}

{phang2}{cmd:. pocoint consump inc, urca test(Pu) trend(c)}{p_end}
{phang2}{cmd:. pocoint consump inc, urca test(Pz) trend(ct) llong}{p_end}

{pstd}
Backwards-compatible mode reproducing the EViews default
Phillips-Ouliaris output (both Z(alpha) and Z(t) reported in one
table; no other option is allowed):{p_end}

{phang2}{cmd:. pocoint consump inc, eviews}{p_end}


{title:Examples adapted from other softwares}

{pstd}
Each source package (R {bf:tseries}, R {bf:urca}, Python {bf:arch}) ships
its own example data set.  We have re-saved each one as a Stata-ready
file and a CSV.  The Stata files are loaded directly from the web with
{cmd:use} (no manual download required):

{p2colset 8 60 60 2}{...}
{p2col :{bf:tseries_example_no_cointegration.dta}}1001-obs bivariate random walk{p_end}
{p2col :{bf:tseries_example_cointegrated.dta}}1001-obs cointegrated pair y = 2 - 3*x + N(0,5^2){p_end}
{p2col :{bf:urca_ecb_example.dta}}quarterly Euro-area data: real M3, real GDP, long bond rate{p_end}
{p2col :{bf:arch_crude_example.dta}}393 monthly Brent and WTI log crude-oil prices, 1987m5-2020m1{p_end}
{p2colreset}{...}

{pstd}
Equivalent CSVs are available at the same URL by replacing
{cmd:.dta} with {cmd:.csv} (load with {cmd:import delimited}).  The
ECB example is also provided as an EViews workfile at
{cmd:https://www.eruygurakademi.com/datasets/urca_ecb_example.wf1}.

{dlgtab:R: tseries::po.test (A. Trapletti)}

{pstd}
Bivariate random-walk example (no cointegration), 1001 observations.
R and Stata both read the same data from the web (R as CSV, Stata as
DTA), so the test statistics agree to machine precision:{p_end}

{phang2}{it:R}{p_end}
{phang2}{cmd:    install.packages("tseries")   # only once}{p_end}
{phang2}{cmd:    library(tseries)}{p_end}
{phang2}{cmd:    d <- read.csv("https://www.eruygurakademi.com/datasets/tseries_example_no_cointegration.csv")}{p_end}
{phang2}{cmd:    po.test(ts(cbind(d$x1, d$x2)))}{p_end}

{pstd}
Stata equivalent:{p_end}

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/tseries_example_no_cointegration.dta, clear}{p_end}
{phang2}{cmd:. pocoint x1 x2, tseries}{p_end}

{pstd}
Cointegrated case (1001 observations, y = 2 - 3*x + N(0,5^2)):{p_end}

{phang2}{it:R}{p_end}
{phang2}{cmd:    library(tseries)}{p_end}
{phang2}{cmd:    d <- read.csv("https://www.eruygurakademi.com/datasets/tseries_example_cointegrated.csv")}{p_end}
{phang2}{cmd:    po.test(ts(cbind(d$x, d$y)))}{p_end}

{pstd}
Stata equivalent:{p_end}

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/tseries_example_cointegrated.dta, clear}{p_end}
{phang2}{cmd:. pocoint x y, tseries}{p_end}

{pstd}
Same data with the modern arch-style test (continuous p-value via the
Hansen-Haug response surface):{p_end}

{phang2}{cmd:. pocoint x y, test(Za) trend(c)}{p_end}
{phang2}{cmd:. pocoint x y, test(Pz) trend(c) auto}{p_end}

{dlgtab:R: urca::ca.po (B. Pfaff)}

{pstd}
Quarterly Euro-area data (1997Q3 to 2003Q4, 26 observations): real M3,
real GDP, and the long bond rate.  R reads the CSV; Stata reads the
DTA (already {cmd:tsset} on quarterly variable {bf:quarter}):{p_end}

{phang2}{it:R}{p_end}
{phang2}{cmd:    install.packages("urca")   # only once}{p_end}
{phang2}{cmd:    library(urca)}{p_end}
{phang2}{cmd:    d <- read.csv("https://www.eruygurakademi.com/datasets/urca_ecb_example.csv")}{p_end}
{phang2}{cmd:    summary(ca.po(cbind(d$m3_real, d$gdp_real, d$rl), type="Pz"))}{p_end}

{pstd}
Stata equivalent:{p_end}

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/urca_ecb_example.dta, clear}{p_end}
{phang2}{cmd:. pocoint m3_real gdp_real rl, urca test(Pz) trend(n)}{p_end}

{pstd}
The same multivariate-trace test using the article's own Hansen-Haug
formulation (which differs from urca's; see the {bf:urca} option
above):{p_end}

{phang2}{cmd:. pocoint m3_real gdp_real rl, test(Pz) trend(n)}{p_end}
{phang2}{cmd:. pocoint m3_real gdp_real rl, test(Pz) trend(n) auto}{p_end}

{dlgtab:Python: arch.unitroot.cointegration.phillips_ouliaris (K. Sheppard)}

{pstd}
Monthly WTI and Brent log crude-oil prices, 1987m5 to 2020m1, 393
observations.  Python reads the CSV; Stata reads the DTA (already
{cmd:tsset} on monthly variable {bf:month}):{p_end}

{phang2}{it:Python}{p_end}
{phang2}{cmd:    # pip install arch pandas      # only once, in your shell}{p_end}
{phang2}{cmd:    import numpy as np, pandas as pd}{p_end}
{phang2}{cmd:    from arch.unitroot.cointegration import phillips_ouliaris}{p_end}
{phang2}{cmd:    d = pd.read_csv("https://www.eruygurakademi.com/datasets/arch_crude_example.csv")}{p_end}
{phang2}{cmd:    phillips_ouliaris(d["WTI"], d[["Brent"]], trend="c", test_type="Zt")}{p_end}
{phang2}{cmd:    phillips_ouliaris(d["WTI"], d[["Brent"]], trend="c", test_type="Pz")}{p_end}

{pstd}
Stata equivalent.  With the {cmd:auto} option {cmd:pocoint}
reproduces arch's default behaviour to machine precision (data-driven
bandwidth via the Andrews/Newey-West rule):{p_end}

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/arch_crude_example.dta, clear}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Zt) trend(c) auto}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Za) trend(c) auto}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Pu) trend(c) auto}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Pz) trend(c) auto}{p_end}

{pstd}
arch defaults to the Bartlett kernel.  Try the other two:{p_end}

{phang2}{cmd:. pocoint WTI Brent, test(Zt) trend(c) kernel(parzen) auto}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Zt) trend(c) kernel(qs) auto}{p_end}

{pstd}
With {cmd:pocoint}'s own fixed-bandwidth default ({bf:lshort}) the
statistics are close to arch's defaults but not identical, because
arch picks an automatic data-driven bandwidth:{p_end}

{phang2}{cmd:. pocoint WTI Brent, test(Zt) trend(c)}{p_end}
{phang2}{cmd:. pocoint WTI Brent, test(Pz) trend(c) llong}{p_end}


{dlgtab:EViews: Phillips-Ouliaris cointegration test}

{pstd}
The {cmd:eviews} option reproduces the EViews default
Phillips-Ouliaris output to machine precision.  Using the same Euro-area
ECB data set as the urca example (1997Q3-2003Q4, 26 observations),
the EViews dialog (Group -> View -> Cointegration Test, Test method =
Phillips-Ouliaris, Trend specification = Constant (Level), HAC Options
= Bartlett kernel + Newey-West Fixed bandwidth, d.f. adjustment off)
gives:{p_end}

{phang2}{it:EViews output (excerpt)}{p_end}
{phang2}{cmd:    Dependent     tau-statistic     z-statistic}{p_end}
{phang2}{cmd:    GDP_REAL         -2.380265        -6.749947}{p_end}
{phang2}{cmd:    M3_REAL          -1.927034        -6.393164}{p_end}
{phang2}{cmd:    RL               -2.930983       -11.513503}{p_end}

{pstd}
The matching EViews workfile is available at the same URL with the
{cmd:.wf1} extension:{p_end}

{phang2}{cmd:    https://www.eruygurakademi.com/datasets/urca_ecb_example.wf1}{p_end}

{pstd}
Stata equivalent:{p_end}

{phang2}{cmd:. use https://www.eruygurakademi.com/datasets/urca_ecb_example.dta, clear}{p_end}
{phang2}{cmd:. pocoint gdp_real m3_real rl, eviews}{p_end}
{phang2}{cmd:. pocoint m3_real gdp_real rl, eviews}{p_end}
{phang2}{cmd:. pocoint rl m3_real gdp_real, eviews}{p_end}

{pstd}
The {cmd:eviews} mode also prints the intermediate quantities shown in
the EViews "Intermediate Results" panel (Rho - 1, bias-corrected
Rho* - 1, Rho* S.E., residual variance, long-run residual variance,
long-run residual autocovariance), all of which agree with EViews to
machine precision.  Note that these test statistics differ from the
{cmd:Za} and {cmd:Zt} produced by {cmd:pocoint}'s default mode (which
follows the original Phillips-Ouliaris (1990) formula and uses the
sample size {bf:T} as the normalization factor): EViews uses
{bf:T_eff = T - 1}, the number of AR(1) residuals.  Use {cmd:eviews}
when reproducing EViews output and the default mode (with {cmd:auto})
when reproducing Python {bf:arch}.


{title:References}

{pstd}
Phillips, P. C. B., and S. Ouliaris.  1990.  Asymptotic Properties of
Residual Based Tests for Cointegration.  {it:Econometrica} 58: 165-193.

{pstd}
Hansen, B. E.  1992.  Efficient estimation and testing of cointegrating
vectors in the presence of deterministic trends.  {it:Journal of
Econometrics} 53: 87-121.

{pstd}
Sheppard, K.  {bf:arch}: Autoregressive Conditional Heteroskedasticity,
unit-root and cointegration tests for Python.

{pstd}
Trapletti, A.  {bf:tseries}: Time Series Analysis and Computational
Finance.  R package, function {bf:po.test}.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com":https://www.ozaneruygur.com}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting (Eruygur Akademi ve Danismanlik), Ankara, Turkiye.{break}
{browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}{break}
eruygurakademi@gmail.com

{pstd}
pocoint v3.2.0 - May 2026

{title:Please cite as:}

{pstd}
Eruygur, H. O. 2026. {bf:pocoint}: Phillips-Ouliaris cointegration test.
Stata package version 3.2.0.  Available from: {browse "https://www.eruygurakademi.com":https://www.eruygurakademi.com}

{pstd}
Critical-value and p-value tables embedded in this package are
sourced from K. Sheppard's {bf:arch} Python package and reflect very
large Monte Carlo simulations of the Hansen-Haug response surface.
