{smcl}
{* *! version 1.7.7 18jul2026}{...}
{viewerjumpto "Syntax" "prcoint##syntax"}{...}
{viewerjumpto "Description" "prcoint##description"}{...}
{viewerjumpto "Choosing among the tests" "prcoint##choice"}{...}
{viewerjumpto "Options" "prcoint##options"}{...}
{viewerjumpto "Examples" "prcoint##examples"}{...}
{viewerjumpto "GAUSS replication" "prcoint##replication"}{...}
{viewerjumpto "Stored results" "prcoint##results"}{...}
{viewerjumpto "References" "prcoint##references"}{...}
{title:Title}

{phang}
{bf:prcoint} {hline 2} Perron and Rodriguez (2016) residuals-based tests for
cointegration under endogeneity and serial correlation (GLS-detrended)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:prcoint} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 16 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(#)}}deterministic case: 1, 2, or 3; default is
{cmd:model(1)}{p_end}
{synopt:{opt cb:ar(#)}}quasi-differencing parameter; default is the optimal
value from Table 1{p_end}
{synopt:{opt max:lag(#)}}maximum lag of the ADF-type regression; default is
round(4*(T/100)^(1/4)){p_end}
{synopt:{opt min:lag(#)}}minimum lag of the ADF-type regression; default is
0{p_end}
{synoptline}
{p 4 6 2}
The data must be {cmd:tsset} and the estimation sample may not contain gaps.
Time-series operators are allowed.


{marker description}{...}
{title:Description}

{pstd}
{cmd:prcoint} computes the residuals-based tests for the null hypothesis of
no cointegration proposed by Perron and Rodriguez (2016).
The cointegrating equation relates the dependent variable y to m
integrated regressors x1, ..., xm.
The equation estimated under each choice of {opt model()} is

{p 8 12 2}{cmd:model(1)} (constant; non-trending regressors):  y(t) = constant + b1*x1(t) + ... + bm*xm(t) + u(t){p_end}
{p 8 12 2}{cmd:model(2)} (constant and trend in the equation):  y(t) = constant + d*t + b1*x1(t) + ... + bm*xm(t) + u(t){p_end}
{p 8 12 2}{cmd:model(3)} (constant; trending regressors):  y(t) = constant + b1*x1(t) + ... + bm*xm(t) + u(t){p_end}

{pstd}
where t = 1, ..., T, the coefficients b1, ..., bm form the
cointegrating vector, d is the coefficient of the linear time trend,
and u(t) is the error term.
Each regressor x1, ..., xm is assumed to be I(1), that is, to contain
a unit root.
Under the null hypothesis u(t) also has a unit root and the variables
are not cointegrated; under the alternative u(t) is stationary and the
variables are cointegrated.

{pstd}
The tests remain valid when the regressors are endogenous and when the
errors are serially correlated, and this is a central feature of the
approach.
The framework of Perron and Rodriguez (2016) allows the errors driving
the regressors to be correlated with the error term u(t)
(endogeneity, measured by the long-run correlation R2 in their
notation) and allows general serial correlation in the errors
(Section 2).
Under the null hypothesis, the limit distributions of all seven
statistics depend neither on R2 nor on any other nuisance parameter
(Section 6.1), so the critical values of Tables 2-4 apply whether or
not the regressors are endogenous.
Serial correlation is handled through the autoregressive spectral
density estimator of the long-run variance with BIC lag selection
(Section 4), and the optimal cbar values of Table 1 are calibrated at
R2 = 0.4, a typical degree of endogeneity in applied work
(Section 6.1).

{pstd}
The choice among the three cases depends on two questions: do the
series trend, and should the estimated equation itself contain a
trend?
Trending refers to the observed data: in {cmd:model(3)} the regressors
contain a linear trend and y(t) inherits that trend through the
combination b1*x1(t) + ... + bm*xm(t); in {cmd:model(1)} neither y(t)
nor the regressors trend.
If the series do not trend, use {cmd:model(1)}.
If the regressors trend (for example, macroeconomic aggregates that
grow over time), first consider {cmd:model(3)}: no trend term is put
in the equation, so the trends of the regressors must account for the
trend of y(t), and the error term u(t) is then free of any trend.
This is called deterministic cointegration and is the case of most
interest in practice.
If instead a trend term d*t is needed in the equation itself - that
is, y(t) drifts away from b1*x1(t) + ... + bm*xm(t) at a constant
rate, so that the relation between y and the regressors is trend
stationary - use
{cmd:model(2)}, which is called stochastic cointegration.
In short, {cmd:model(2)} puts the trend inside the equation, while
{cmd:model(3)} leaves the trend in the data and lets the regressors
absorb it.
{cmd:model(1)} and {cmd:model(3)} estimate the same equation; they
differ in the type of data they are meant for, which changes the
optimal cbar and the critical values.

{pstd}
Estimation proceeds in two steps.
First, the deterministic components are removed from the dependent
variable and from each regressor separately by local-to-unity GLS
detrending (Elliott, Rothenberg, and Stock 1996): each series is
quasi-differenced with alphabar = 1 + cbar/T, keeping the first
observation in levels, and regressed on the quasi-differenced
deterministics.
Second, the cointegrating regression of the detrended y(t) on the
detrended regressors is estimated by OLS without deterministic terms,
and the tests are constructed from its residuals.

{pstd}
The parameter cbar controls how the detrending is done.
Instead of estimating the constant (and trend) by ordinary least
squares on the levels, each series is first quasi-differenced: the
first observation is kept as it is, and for t = 2, ..., T the
transformation y(t) - alphabar*y(t-1) is applied, with
alphabar = 1 + cbar/T.
Because cbar is a negative number and T is the sample size, alphabar
is slightly below 1, so the transformation is close to taking first
differences.
The constant (and trend) are estimated from the transformed series and
then subtracted from the original series in levels.
The value of cbar sets where the detrending lies between two extremes:
cbar = 0 would detrend in first differences, and cbar = -T would
reproduce ordinary OLS detrending; the optimal values lie between the
two.
Perron and Rodriguez (2016, Table 1) derive the cbar that maximizes
the local power of the tests; it depends on the number of regressors
(m = 1, ..., 5) and on the deterministic case, and {cmd:prcoint} uses
this optimal value by default (for example, cbar = -22.25 for m = 3
with {cmd:model(1)}).
Changing cbar changes the detrended series and therefore all seven
statistics, and the critical values of Tables 2-4 assume the optimal
cbar.

{pstd}
Seven statistics are reported from the residuals of the cointegrating
regression: the M-tests MZ_rho, MSB, and MZ_t, the ADF t-statistic, the
Phillips Z_rho and Z_t statistics, and the feasible point-optimal statistic
MPT.
The autoregressive spectral density estimator at frequency zero is used for
the long-run variance, with the lag of the ADF-type regression selected by
BIC between {opt minlag()} and {opt maxlag()}.

{pstd}
When m is larger than 5, the cbar values of the m = 5 row of Table 1
are used, as in the original code.
Asymptotic critical values from Tables 2, 3, and 4 of Perron and Rodriguez
(2016) are reported at the 1, 5, and 10 percent levels, and the full set of
tabulated levels (1, 2.5, 5, 7.5, 10, 15, and 20 percent) is stored in
{cmd:r(cv)}.
The null hypothesis of no cointegration is rejected in the left tail:
MZ_rho, MZ_t, ADF, Z_rho, and Z_t reject when the statistic is more
negative than the critical value, and MSB and MPT (which take positive
values) reject when the statistic is smaller than the critical value.

{pstd}
The cointegrating vector, its conventional OLS standard errors, and
the implied deterministic coefficients of the level-form equation are
not displayed; they are stored in {cmd:r(beta)}, {cmd:r(se)},
{cmd:r(cons)}, and (with {cmd:model(2)}) {cmd:r(trend)}, and can be
listed with {cmd:matrix list r(beta)}.
The values in {cmd:r(cons)} and {cmd:r(trend)} come from the
first-stage GLS detrending and carry no standard errors.
If the regressors are endogenous or the error term is serially
correlated, the OLS standard errors are not valid for
inference on the cointegrating vector; use FMOLS or DOLS type
estimators in that case.

{pstd}
{cmd:prcoint} is a port of the official GAUSS and MATLAB code written by
Gabriel Rodriguez and Miguel Ataurima (Pontificia Universidad Catolica del
Peru, June 2016).


{marker choice}{...}
{title:Choosing among the tests}

{pstd}
All seven statistics test the same null hypothesis of no cointegration
and reject in the left tail.
Their local asymptotic power functions are very similar, so in regular
situations they lead to the same conclusion; the following differences
matter in practice.

{pstd}
MPT is the feasible point-optimal statistic in the spirit of Ng and
Perron (2001).
Perron and Rodriguez (2016) calibrate the optimal cbar values of Table 1
from this test because its power function is the closest to the Gaussian
local power envelope, which makes it a natural benchmark to report.

{pstd}
The M tests (MZ_rho, MSB, MZ_t) have far smaller size distortions than
the Z tests when the first differences of the data contain an important
negative moving-average component (Perron and Ng 1996; Ng and Perron
2001).
They are the safer choice when such serial correlation is suspected.

{pstd}
The Z tests (Z_rho, Z_t) of the Phillips and Ouliaris (1990) type and
the ADF test are the familiar classical statistics.
In the simulations of Perron and Rodriguez (2016) their GLS versions
have power very close to the M tests, and the local asymptotic power
functions are essentially the same unless the number of regressors is
very large, in which case ADF is slightly more powerful (Section 6.2).

{pstd}
When the initial value of the error term u(t) is very large, all GLS
detrended tests lose power and the OLS-based ADF test can become more
powerful (Section 7.1 of Perron and Rodriguez 2016).
If such an initial condition is suspected, an OLS-based residuals test
can be used alongside these tests as a union-of-rejections check, which
may entail mild liberal size distortions.

{pstd}
Because the power differences across the seven statistics are minor,
the authors report all seven jointly in their empirical application;
agreement across the statistics strengthens the conclusion.


{marker options}{...}
{title:Options}

{phang}
{opt model(#)} sets the type of deterministic components.
{cmd:model(1)} includes only a constant in the detrending regression and is
intended for the case where neither y nor the regressors trend
(px=0, py=0).
{cmd:model(2)} includes a constant and a linear time trend
(px=1, py=1).
{cmd:model(3)} includes only a constant but is intended for trending
regressors, that is, deterministic cointegration (px=1, py=0).
The default is {cmd:model(1)}.

{phang}
{opt cbar(#)} sets the quasi-differencing parameter used in the GLS
detrending, with alphabar = 1 + cbar/T.
It must be nonpositive.
The default is the optimal value from Table 1 of Perron and Rodriguez
(2016).

{phang}
{opt maxlag(#)} sets the maximum lag of the ADF-type regression used for
the autoregressive spectral density estimator and for the ADF test.
The default is round(4*(T/100)^(1/4)).

{phang}
{opt minlag(#)} sets the minimum lag.
The default is 0.
Setting {opt minlag()} equal to {opt maxlag()} fixes the lag at that
value and disables the BIC search.


{marker examples}{...}
{title:Examples}

{pstd}
Replication of the empirical application in the original GAUSS and MATLAB
code (Peruvian consumption, private investment, public investment, GDP, and
terms of trade; T = 95):

{phang}{cmd:. use https://www.eruygurakademi.com/datasets/prcoint/datos.dta, clear}{p_end}
{phang}{cmd:. prcoint y x1 x2 x3 x4, model(1)}{p_end}
{phang}{cmd:. prcoint y x1 x2 x3 x4, model(2)}{p_end}
{phang}{cmd:. prcoint y x1 x2 x3 x4, model(3)}{p_end}

{pstd}
Fixing the lag of the ADF-type regression at 2 (disables the BIC
search):

{phang}{cmd:. prcoint y x1 x2 x3 x4, model(1) minlag(2) maxlag(2)}{p_end}

{pstd}
Canada macro data:

{phang}{cmd:. use https://www.eruygurakademi.com/datasets/varvecm/Canada.dta, clear}{p_end}
{phang}{cmd:. tsset qdate}{p_end}

{phang}Constant and time trend, optimal cbar for m = 3:{p_end}
{phang}{cmd:. prcoint e prod rw U, model(2)}{p_end}

{pstd}
Supplying cbar and the maximum lag directly.
Here -22.25 is the Table 1 optimal value for m = 3 with model(1), so
this call reproduces the default detrending; any other cbar changes
the quasi-differencing, hence the detrended series and all seven
statistics, and the critical values of Tables 2-4 then no longer apply
exactly:

{phang}{cmd:. prcoint e prod rw U, model(1) cbar(-22.25) maxlag(6)}{p_end}


{marker replication}{...}
{title:GAUSS replication}

{pstd}
{cmd:prcoint} is a Stata/Mata port of the official GAUSS and MATLAB
replication code of Perron and Rodriguez (2016), written by Gabriel
Rodriguez and Miguel Ataurima (PUCP, June 2016) and distributed on
Pierre Perron's research page
({browse "https://blogs.bu.edu/perron/codes/"}, GLS-Cointegration.zip;
also mirrored at
{browse "https://eruygurakademi.com/datasets/prcoint/GLS-Cointegration.zip"}).
The {opt model()} option of {cmd:prcoint} corresponds to the det_comp
variable of the GAUSS code (1, 2, or 3), and both use the same
defaults for the lag search (BIC with kmin = 0 and
kmax = round(4*(T/100)^(1/4))) and the same Table 1 values for cbar,
so the two programs reproduce the same seven statistics, selected
lag, and cointegrating vector.

{pstd}
Ready-to-run replication files for both packages are provided at
{browse "https://www.eruygurakademi.com/datasets/prcoint/"}.
Each file runs the same three cases (model(1) to model(3), that is,
det_comp 1 to 3) on the authors' Peruvian data, loaded directly from
the web, so the Stata and GAUSS output can be compared side by side.

{dlgtab:Replicating in Stata}

{pstd}
The file prcoint_stata.do loads the data from the web and runs the
three cases.
Run it directly with:

{phang}{cmd:.} {stata "do https://www.eruygurakademi.com/datasets/prcoint/prcoint_stata.do"}{p_end}

{dlgtab:Replicating in GAUSS}

{pstd}
The program
{browse "https://www.eruygurakademi.com/datasets/prcoint/prcoint_gauss.gss":prcoint_gauss.gss}
reads the data directly from the web with loadd and runs the three
cases, so no manual download of the data is needed.
To run it:

{phang}1. Download prcoint_gauss.gss and open it in GAUSS.{p_end}
{phang}2. Select the entire program with Ctrl+A and press Run.{p_end}

{pstd}
GAUSS then prints, for each case, the seven statistics, the selected
lag, and the cointegrating vector beta_hat.
The statistics and the lag match the {cmd:prcoint} output, and
beta_hat matches {cmd:matrix list r(beta)} after the corresponding
{cmd:prcoint} call, to at least 12 decimal places on this data set.
The procedures inside prcoint_gauss.gss are the authors' original
GAUSS code, unchanged; the short driver at the top only loads the
data and loops over the three cases.
The authors' original MATLAB program from the same archive can be
used in the same way by setting det_comp to 1, 2, and 3 in turn.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:prcoint} stores the following in {cmd:r()}:

{synoptset 12 tabbed}{...}
{p2col 5 12 16 2: Scalars}{p_end}
{synopt:{cmd:r(mzrho)}}MZ_rho(GLS) statistic{p_end}
{synopt:{cmd:r(msb)}}MSB(GLS) statistic{p_end}
{synopt:{cmd:r(mzt)}}MZ_t(GLS) statistic{p_end}
{synopt:{cmd:r(adf)}}ADF(GLS) statistic{p_end}
{synopt:{cmd:r(zrho)}}Z_rho(GLS) statistic{p_end}
{synopt:{cmd:r(zt)}}Z_t(GLS) statistic{p_end}
{synopt:{cmd:r(mpt)}}MPT(GLS) statistic{p_end}
{synopt:{cmd:r(lag)}}lag selected by BIC{p_end}
{synopt:{cmd:r(maxlag)}}maximum lag{p_end}
{synopt:{cmd:r(minlag)}}minimum lag{p_end}
{synopt:{cmd:r(cbar)}}quasi-differencing parameter{p_end}
{synopt:{cmd:r(m)}}number of regressors{p_end}
{synopt:{cmd:r(model)}}deterministic case{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(cons)}}implied constant of the level-form cointegrating
equation{p_end}
{synopt:{cmd:r(trend)}}implied trend coefficient (with {cmd:model(2)}
only){p_end}

{synoptset 12 tabbed}{...}
{p2col 5 12 16 2: Matrices}{p_end}
{synopt:{cmd:r(cv)}}asymptotic critical values (rows: mzrho, msb, mzt, adf,
zrho, zt, mpt; columns: 1, 2.5, 5, 7.5, 10, 15, 20 percent){p_end}
{synopt:{cmd:r(beta)}}estimated cointegrating vector{p_end}
{synopt:{cmd:r(se)}}conventional OLS standard errors of the cointegrating
vector (see Description for validity conditions){p_end}


{marker references}{...}
{title:References}

{phang}
Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996.
Efficient tests for an autoregressive unit root.
{it:Econometrica} 64: 813-836.

{phang}
Ng, S., and P. Perron. 2001.
Lag length selection and the construction of unit root tests with good
size and power.
{it:Econometrica} 69: 1519-1554.

{phang}
Perron, P., and S. Ng. 1996.
Useful modifications to some unit root tests with dependent errors and
their local asymptotic properties.
{it:Review of Economic Studies} 63: 435-463.

{phang}
Perron, P., and G. Rodriguez. 2016.
Residuals-based tests for cointegration with generalized least-squares
detrended data.
{it:Econometrics Journal} 19: 84-111.

{phang}
Phillips, P. C. B., and S. Ouliaris. 1990.
Asymptotic properties of residual based tests for cointegration.
{it:Econometrica} 58: 165-193.

{phang}
Rodriguez, G., and M. Ataurima. 2016.
GAUSS and MATLAB code for the empirical application of Perron and
Rodriguez (2016).
Department of Economics, Pontificia Universidad Catolica del Peru.


{title:Author}

{pstd}
H. Ozan Eruygur{break}
AHBV University, Ankara, Turkiye.{break}
Department of Economics{break}
{browse "https://www.ozaneruygur.com"}{break}
eruygur@gmail.com

{pstd}
Eruygur Academy and Consulting{break}
{browse "https://www.eruygurakademi.com"}{break}
eruygurakademi@gmail.com

{pstd}
prcoint v1.7.7 - July 2026

{pstd}
The tests implemented here were proposed by Pierre Perron (Department of
Economics, Boston University) and Gabriel Rodriguez (Department of
Economics, Pontificia Universidad Catolica del Peru).
The Stata implementation is a port of the authors' GAUSS and MATLAB
replication code for the article.

{pstd}
Please cite as: Eruygur, H. O. 2026. prcoint: Stata module for Perron
and Rodriguez (2016) residuals-based tests for cointegration under
endogeneity and serial correlation (GLS-detrended). Statistical
Software Components, Boston College Department of Economics.
