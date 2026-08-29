{smcl}
{* *! version 2.0.0  28aug2026}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "ardlbounds" "help ardlbounds"}{...}
{vieweralsosee "newey" "help newey"}{...}
{viewerjumpto "Syntax" "aardl##syntax"}{...}
{viewerjumpto "Description" "aardl##description"}{...}
{viewerjumpto "Model" "aardl##model"}{...}
{viewerjumpto "Options" "aardl##options"}{...}
{viewerjumpto "The three tests" "aardl##threetests"}{...}
{viewerjumpto "Critical values" "aardl##cv"}{...}
{viewerjumpto "Bootstrap" "aardl##bootstrap"}{...}
{viewerjumpto "Size properties" "aardl##size"}{...}
{viewerjumpto "Fourier frequencies" "aardl##fourier"}{...}
{viewerjumpto "Diagnostics" "aardl##diagnostics"}{...}
{viewerjumpto "Stability" "aardl##stability"}{...}
{viewerjumpto "Dynamic multipliers" "aardl##multipliers"}{...}
{viewerjumpto "Graphs" "aardl##graphs"}{...}
{viewerjumpto "Postestimation" "aardl##post"}{...}
{viewerjumpto "Stored results" "aardl##results"}{...}
{viewerjumpto "Examples" "aardl##examples"}{...}
{viewerjumpto "References" "aardl##references"}{...}
{viewerjumpto "Author" "aardl##author"}{...}

{title:Title}

{phang}
{bf:aardl} {hline 2} Augmented ARDL cointegration analysis with Fourier terms,
bootstrap inference and asymmetric (NARDL) dynamics


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:aardl} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt ty:pe(string)}}model type; default {cmd:type(aardl)}{p_end}
{synopt:{opt dec:ompose(varlist)}}variables to decompose into positive and
negative partial sums; required for the NARDL types{p_end}
{synopt:{opt case(#)}}Pesaran-Shin-Smith case {bf:1}-{bf:5}; default {cmd:case(3)}{p_end}
{synopt:{opt maxl:ag(#)}}maximum lag order; default {cmd:maxlag(4)}{p_end}
{synopt:{opt ic(string)}}{cmd:aic}, {cmd:bic} (default) or {cmd:hqic}{p_end}
{synopt:{opt sear:ch(string)}}{cmd:full}, {cmd:sequential} or {cmd:auto} (default){p_end}

{syntab:Inference}
{synopt:{opt vce(string)}}{cmd:ols} (default), {cmd:robust}, or
{cmd:hac} (= {cmd:newey}){p_end}
{synopt:{opt lags(#)}}Newey-West bandwidth; default is the automatic rule{p_end}
{synopt:{opt reps(#)}}bootstrap replications; default {cmd:reps(999)}{p_end}
{synopt:{opt b:ootstrap(string)}}{cmd:bvz} (default) or {cmd:mcnown}{p_end}
{synopt:{opt xdgp(string)}}marginal process for x in the bootstrap:
{cmd:rw} (default) or {cmd:vecm}{p_end}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}

{syntab:Fourier}
{synopt:{opt maxk(#)}}maximum Fourier frequency; default {cmd:maxk(5)}{p_end}
{synopt:{opt kst:ep(#)}}Fourier grid increment; default {cmd:kstep(0.1)}{p_end}
{synopt:{opt kmo:de(string)}}{cmd:auto} (default), {cmd:integer} or
{cmd:fractional}{p_end}
{synopt:{opt nof:ourier}}suppress the Fourier terms even for a Fourier {cmd:type()}{p_end}

{syntab:Dynamics}
{synopt:{opt hor:izon(#)}}multiplier and persistence horizon; default {cmd:horizon(24)}{p_end}
{synopt:{opt ban:ds(#)}}draws for the multiplier confidence bands; default {cmd:bands(500)}{p_end}

{syntab:Reporting}
{synopt:{opt graphp:refix(string)}}prefix for all graph names{p_end}
{synopt:{opt nodi:ag}}suppress the diagnostic panels{p_end}
{synopt:{opt nostab:ility}}suppress CUSUM and CUSUMSQ{p_end}
{synopt:{opt nodyn:mult}}suppress the dynamic multipliers{p_end}
{synopt:{opt noadv:anced}}suppress the advanced analysis{p_end}
{synopt:{opt notab:le}}suppress the coefficient table{p_end}
{synopt:{opt nohe:ader}}suppress the header{p_end}
{synopt:{opt nograph}}suppress all graphs{p_end}
{synopt:{opt nobounds:graph}}suppress only the bounds graph{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}. {cmd:aardl} is a pure time-series
command; panels are refused.{p_end}
{p 4 6 2}The estimation sample must be contiguous (no internal gaps or
missing values); {cmd:aardl} stops with an error otherwise, because the
recursive bootstrap and the recursive residuals both require it.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:aardl} implements the augmented ARDL bounds test of Sam, McNown and Goh
(2019), which supplements the two Pesaran, Shin and Smith (2001) statistics
with a third test on the lagged levels of the independent variables. Only
when all three reject can cointegration be concluded; each of the other
outcomes identifies a specific degenerate case.

{pstd}
Eight model types combine that framework with three extensions: a Fourier
approximation to unknown smooth structural breaks (Yilanci, Bozoklu and Gorus
2020), a recursive null-imposed bootstrap (McNown, Sam and Goh 2018; Bertelli,
Vacca and Zoia 2022), and the asymmetric partial-sum decomposition of Shin, Yu
and Greenwood-Nimmo (2014).

{synoptset 14}{...}
{synopthdr:type()}
{synoptline}
{synopt:{cmd:aardl}}augmented ARDL, asymptotic bounds{p_end}
{synopt:{cmd:baardl}}augmented ARDL, bootstrap critical values{p_end}
{synopt:{cmd:faardl}}Fourier augmented ARDL, asymptotic bounds{p_end}
{synopt:{cmd:fbaardl}}Fourier augmented ARDL, bootstrap critical values{p_end}
{synopt:{cmd:nardl}}augmented NARDL, asymptotic bounds{p_end}
{synopt:{cmd:fanardl}}Fourier augmented NARDL, asymptotic bounds{p_end}
{synopt:{cmd:banardl}}augmented NARDL, bootstrap critical values{p_end}
{synopt:{cmd:fbanardl}}Fourier augmented NARDL, bootstrap critical values{p_end}
{synoptline}


{marker model}{...}
{title:The estimated model}

{pstd}
{cmd:aardl} estimates the conditional error-correction model

{p 8 8 2}
D.y(t) = c0 + c1*t + pi_yy*y(t-1) + sum_i pi_i*x_i(t-1)
+ sum_j psi_j*D.y(t-j) + sum_i sum_j om_ij*D.x_i(t-j)
+ g1*sin(2*pi*k*t/T) + g2*cos(2*pi*k*t/T) + u(t)

{pstd}
{opt case()} determines which deterministic terms enter and which are part of
the null hypothesis of the overall F test. This is a property of the
{it:estimated equation}, not merely of the critical-value table:

{synoptset 10 tabbed}{...}
{synopt:{bf:1}}no intercept, no trend; F tests only the lagged levels{p_end}
{synopt:{bf:2}}intercept estimated but restricted; F tests the lagged levels
{bf:and} the intercept, and the intercept appears among the long-run
coefficients{p_end}
{synopt:{bf:3}}unrestricted intercept, no trend (the default){p_end}
{synopt:{bf:4}}unrestricted intercept, restricted trend; F tests the lagged
levels {bf:and} the trend, and the trend appears among the long-run
coefficients{p_end}
{synopt:{bf:5}}unrestricted intercept, unrestricted trend{p_end}

{pstd}
The coefficient table is reported in error-correction form with three
equations: {bf:ADJ} (the speed of adjustment pi_yy), {bf:LR} (the long-run
coefficients -pi_i/pi_yy, with delta-method standard errors) and {bf:SR} (the
short-run coefficients as estimated).

{pstd}
{bf:Lag selection.} Every candidate ARDL(p,q1,...,qk) is estimated on the
{it:same} sample, namely the one implied by {opt maxlag()}, so the information
criteria are comparable across candidates. Reported AIC/BIC/HQIC refer to that
sample as well.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt type(string)} selects one of the eight models listed above.

{phang}{opt decompose(varlist)} lists the variables to split into positive and
negative partial sums, x+(t) = sum max(D.x,0) and x-(t) = sum min(D.x,0),
following Shin, Yu and Greenwood-Nimmo (2014). The partial sums are created as
{it:varname}{cmd:_pos} and {it:varname}{cmd:_neg} and are {bf:kept} after
estimation, because postestimation needs them. If variables of those names
already exist, {cmd:aardl} falls back to an {cmd:_aardl_} prefix and says so.
Independent variables that are not decomposed enter as controls.

{phang}{opt case(#)} see {help aardl##model:The estimated model}.

{phang}{opt maxlag(#)} sets the maximum lag order, 1 to 12. Note that
{opt maxlag()} costs observations: the fixed estimation sample starts
{it:maxlag}+2 periods in.

{phang}{opt ic(string)} is the criterion minimised in lag selection.

{phang}{opt search(string)} controls the lag search. {cmd:full} evaluates
every (p,q1,...,qk) combination, which is {it:maxlag} x ({it:maxlag}+1)^k
models. {cmd:sequential} chooses p with all q at their maximum, then sweeps
each q twice holding the others fixed. {cmd:auto} (the default) uses
{cmd:full} when that means 6000 models or fewer and {cmd:sequential}
otherwise, and reports which one it used.

{dlgtab:Inference}

{phang}{opt vce(string)} chooses the covariance estimator used for the
coefficient table, for the three bounds statistics, for the asymmetry Wald
tests, and inside the bootstrap. {cmd:ols} is conventional;
{cmd:robust} is Huber-White HC1; {cmd:hac} (equivalently {cmd:newey}) is
Newey-West. Point estimates are identical across the three; only the
covariance matrix changes. Use {cmd:vce(hac)} when the diagnostics flag
residual serial correlation or ARCH, which the bounds statistics are otherwise
sensitive to.

{phang}{opt lags(#)} is the Newey-West bandwidth. The default is
floor(4*(N/100)^(2/9)).

{phang}{opt reps(#)} is the number of bootstrap replications. Under
{cmd:bootstrap(bvz)} each replication simulates three series, one per null
hypothesis.

{phang}{opt bootstrap(string)} see {help aardl##bootstrap:Bootstrap} and
{help aardl##size:Size properties}.

{phang}{opt xdgp(string)} controls how the independent variables are generated
in the bootstrap. {cmd:rw} imposes the unit root, x*(t) = x*(t-1) + D.x*(t),
with D.x* a stationary VAR in differences; this is the default and is the
better calibrated of the two. {cmd:vecm} estimates the marginal VECM including
the x levels, exactly as printed in the two papers. See
{help aardl##size:Size properties} for the measured difference.

{dlgtab:Fourier}

{phang}{opt maxk(#)}, {opt kstep(#)} define the search grid
k = {it:kstep}, 2*{it:kstep}, ..., {it:maxk}. The default grid
k = 0.1, 0.2, ..., 5 is the one used by Yilanci, Bozoklu and Gorus (2020).

{phang}{opt kmode(string)} see {help aardl##fourier:Fourier frequencies}.

{dlgtab:Dynamics}

{phang}{opt horizon(#)} is the horizon of the dynamic multipliers and of the
persistence profile.

{phang}{opt bands(#)} is the number of parametric draws used for the
multiplier confidence bands. Set {cmd:bands(0)} to skip them.


{marker threetests}{...}
{title:The three tests}

{pstd}
Following Sam, McNown and Goh (2019):

{p2colset 8 22 24 2}{...}
{p2col:{bf:F_overall}}H0: pi_yy = 0 and pi_i = 0 for all i (plus the intercept
in Case 2, plus the trend in Case 4){p_end}
{p2col:{bf:t_DV}}H0: pi_yy = 0, the lagged level of the dependent variable{p_end}
{p2col:{bf:F_ind}}H0: pi_i = 0 for all i, the lagged levels of the independent
variables{p_end}

{pstd}
The F tests are upper-tail; {bf:t_DV} is lower-tail. The conclusion follows
Sam et al. (2019, pp. 2 and 14):

{p2colset 8 34 36 2}{...}
{p2col:all three reject}cointegration{p_end}
{p2col:F_overall and t_DV reject, F_ind does not}degenerate lagged
{it:independent} variable(s) case, which is degenerate case {bf:#1} of McNown
et al. (2018). The equation reduces to a generalised Dickey-Fuller regression
and {it:depvar} is I(0). No cointegration.{p_end}
{p2col:F_overall and F_ind reject, t_DV does not}degenerate lagged
{it:dependent} variable case, which is degenerate case {bf:#2} of McNown et
al. (2018). No cointegration.{p_end}
{p2col:anything else}no cointegration{p_end}

{pstd}
{cmd:e(coint_status)} takes the values {cmd:cointegrated},
{cmd:degenerate_indep}, {cmd:degenerate_dep} or {cmd:no_cointegration}.


{marker cv}{...}
{title:Critical values}

{pstd}
{bf:F_overall and t_DV.} With an asymptotic {cmd:type()}, the I(0)/I(1) bounds
come from {helpb ardlbounds} (Kripfganz and Schneider 2020), which must be
installed separately ({stata ssc install ardlbounds}). {cmd:aardl} reports the
bounds and the decision but does not invent a p-value.

{pstd}
{bf:F_ind.} The regression p-value for this statistic is {bf:not} valid under
I(1) regressors, so {cmd:aardl} does not report it. Instead the I(0)/I(1)
bounds are read from Tables 1, 2 and 3 of Sam, McNown and Goh (2019), which
are shipped with this package for Case I, Case III and Case V, k = 1 to 7, and
sample sizes 30 to 80 plus the asymptotic row. Cases II and IV are not
tabulated by Sam et al.; the adjacent tabulated case is used and the output
says so. For k > 7 no tabulated bounds exist and a bootstrap {cmd:type()} is
the only valid route.

{pstd}
Two printed entries in the source tables are inconsistent with their immediate
neighbours and are corrected in the shipped tables: Case III, p = 0.025,
N = 45, k = 3 (I(1) bound printed as 4.34, neighbours 5.92 and 5.87, set to
5.90) and Case V, p = 0.025, N = 30, k = 3 (I(0) bound printed as 3.17,
neighbours 3.58 and 3.57, set to 3.64).

{pstd}
{bf:Bootstrap types.} All three statistics get bootstrap critical values and
p-values from the simulated null distribution; no table is consulted.


{marker bootstrap}{...}
{title:Bootstrap}

{pstd}
Both methods impose the null, generate the pseudo-data {it:recursively}, and
re-estimate the unrestricted model on each replication.

{phang}{cmd:bootstrap(mcnown)} follows McNown, Sam and Goh (2018), Steps 1-8.
One restricted D.y equation (all lagged levels set to zero) supplies the
residuals for all three tests, as their Step 1 prescribes. The marginal D.x
equations are unrestricted and include y(t-1), as in their equation (12).

{phang}{cmd:bootstrap(bvz)} follows Bertelli, Vacca and Zoia (2022). Each
null hypothesis gets its {it:own} restricted D.y equation, their equations
(16), (17) and (18), so the F_overall, t_DV and F_ind null distributions are
each generated under the hypothesis actually being tested. The marginal VECM,
their equations (19)-(20), excludes y(t-1), imposing weak exogeneity of the
forcing variables.

{pstd}
Common to both: residuals are recentred and degrees-of-freedom rescaled
(McNown et al. Step 2; Bertelli et al. equations 21-22); the joint residual
vector (v_y, e_x) is resampled as a block so contemporaneous correlation is
preserved; the series are built as y*(t) = y*(t-1) + D.y*(t) and
x*(t) = x*(t-1) + D.x*(t) (McNown et al. Steps 4-5; Bertelli et al. equation
23); and the initial conditions are drawn as a contiguous block from the
original data (Bertelli et al. step 5b). Fourier terms and the trend are
deterministic and are held at their sample values in every replication, in
both the y equation and the marginal equations.

{pstd}
Critical values follow McNown et al. equations (15)-(16) and Bertelli et al.
equations (24)-(25): the upper-tail order statistic for the F tests and the
lower-tail order statistic for t_DV.

{pstd}
The whole engine runs in Mata and reproduces Stata's {helpb test} exactly on
the observed data.


{marker size}{...}
{title:Size properties of the bootstrap}

{pstd}
The engine was calibrated against the true finite-sample null distribution.
The reference distribution comes from 3000 Monte Carlo draws of three
{it:independent} random walks (so the null of no cointegration holds by
construction) with T = 150, an ARDL(1,0,0) specification, Case III and k = 2;
the empirical sizes come from 200 Monte Carlo replications with 199 bootstrap
replications each, at a nominal 5%.

{pstd}
{bf:5% critical values} (2000 bootstrap replications on one null dataset):

{p2colset 8 42 44 2}{...}
{p2col:{space 34}{bf:F_ov}{space 4}{bf:t_DV}{space 4}{bf:F_ind}}{p_end}
{p2col:true finite-sample}{space 5}4.93{space 4}-3.54{space 5}5.41{p_end}
{p2col:{cmd:bootstrap(mcnown) xdgp(rw)}}{space 5}4.88{space 4}-3.53{space 5}5.81{p_end}
{p2col:{cmd:bootstrap(bvz)    xdgp(rw)}}{space 5}4.97{space 4}-2.59{space 5}5.76{p_end}
{p2col:{cmd:bootstrap(mcnown) xdgp(vecm)}}{space 3}4.54{space 4}-3.16{space 5}5.17{p_end}
{p2col:{cmd:bootstrap(bvz)    xdgp(vecm)}}{space 3}4.41{space 4}-2.56{space 5}4.83{p_end}

{pstd}
{bf:Empirical size at nominal 5%} (Monte Carlo standard error about 0.02):

{p2colset 8 42 44 2}{...}
{p2col:{space 30}{bf:F_ov}{space 3}{bf:t_DV}{space 3}{bf:F_ind}{space 3}{bf:all three}}{p_end}
{p2col:{cmd:bootstrap(mcnown) xdgp(rw)}}{space 3}0.070{space 2}0.085{space 2}0.040{space 5}0.025{p_end}
{p2col:{cmd:bootstrap(bvz)    xdgp(rw)}}{space 3}0.090{space 2}0.155{space 2}0.115{space 5}0.075{p_end}
{p2col:{cmd:bootstrap(bvz)    xdgp(vecm)}}{space 1}0.110{space 2}0.130{space 2}0.145{space 5}0.085{p_end}

{pstd}
Two things follow. First, {opt xdgp(rw)} is better calibrated than
{opt xdgp(vecm)} for both methods, which is why it is the default: leaving the
x levels in the marginal equation gives the estimated coefficient on x(t-1) a
small negative bias, so the simulated x is slightly mean-reverting rather than
I(1) and the null distribution comes out too tight.

{pstd}
Second, the {bf:t_DV} test is noticeably over-sized under
{cmd:bootstrap(bvz)} and correctly sized under {cmd:bootstrap(mcnown)}. This is
not an implementation difference: the two run through the same engine and
differ only in the restricted equation used to generate D.y under the t null.
Bertelli et al. impose only a_yy = 0 (their equations 12 and 17), leaving the
estimated x levels in the generating equation, so the simulated y picks up a
cumulated I(1) component. McNown et al. instead apply the joint restriction to
all three tests, as their Step 1 states explicitly, and the simulated y is
exactly I(1). If the t_DV test is doing decisive work in your application, use
{cmd:bootstrap(mcnown)}, or read the joint three-test decision rather than the
individual tests, which is what the framework is for: the joint rejection rate
is conservative under both methods.

{pstd}
For reference, the asymptotic bounds are the right benchmark here because the
regressors are purely I(1): {helpb ardlbounds} gives 3.86/4.89 for F_overall
and -2.87/-3.55 for t_DV, and Sam et al. Table 2 gives 3.01/5.42 for F_ind.


{marker fourier}{...}
{title:Fourier frequencies}

{pstd}
Yilanci, Bozoklu and Gorus (2020), equations (6)-(8), add a single-frequency
Fourier term and choose k by minimum sum of squared residuals over the grid.
Christopoulos and Leon-Ledesma (2011) and Omay (2015) note that {bf:integer}
frequencies correspond to {bf:temporary} breaks while {bf:fractional}
frequencies correspond to {bf:permanent} breaks.

{pstd}
{cmd:aardl} therefore reports the minimum-SSR frequency three ways: over the
integer grid only, over the fractional grid only, and over the two combined,
so the break type implied by each is explicit. {opt kmode()} decides which one
is used in the estimated model:

{p2colset 8 24 26 2}{...}
{p2col:{cmd:kmode(auto)}}the overall minimum-SSR frequency (default){p_end}
{p2col:{cmd:kmode(integer)}}restrict to k = 1, 2, ..., forcing a temporary-break
interpretation{p_end}
{p2col:{cmd:kmode(fractional)}}restrict to non-integer k, forcing a
permanent-break interpretation{p_end}

{pstd}
{cmd:e(ktype)} records {cmd:integer} or {cmd:fractional} and
{cmd:e(breaktype)} records {cmd:temporary} or {cmd:permanent}. The joint
significance of sin and cos at the selected frequency is tested in the
advanced-analysis table; if they are jointly insignificant, a non-Fourier
{cmd:type()} is the better model.


{marker diagnostics}{...}
{title:Diagnostics}

{pstd}
Five panels, all computed on the OLS companion fit so that Stata's
{helpb estat} suite applies to the correct model and sample:

{p2colset 8 22 24 2}{...}
{p2col:{bf:A Normality}}Jarque-Bera, skewness, kurtosis, Shapiro-Wilk,
Shapiro-Francia{p_end}
{p2col:{bf:B Serial correlation}}Breusch-Godfrey LM at 1 to 4 lags (the proper
auxiliary regression, including the original regressors), Durbin's alternative
test, Ljung-Box Q(4), Q(8), Q(12){p_end}
{p2col:{bf:C Heteroskedasticity}}Breusch-Pagan/Cook-Weisberg, White's general
test, ARCH LM at 1, 2 and 4 lags{p_end}
{p2col:{bf:D Functional form}}Ramsey RESET{p_end}
{p2col:{bf:E Collinearity}}mean and maximum variance inflation factor{p_end}

{pstd}
The statistics and p-values are returned in {cmd:e(diagnostics)}.


{marker stability}{...}
{title:Parameter stability}

{pstd}
CUSUM and CUSUMSQ are computed from recursive residuals following Brown,
Durbin and Evans (1975):

{p 8 8 2}
w(t) = (y(t) - x(t)'b(t-1)) / sqrt(1 + x(t)'(X(t-1)'X(t-1))^(-1) x(t))

{pstd}
CUSUM(t) is the running sum of w scaled by its standard deviation, with bands
+/- a*[sqrt(N-k) + 2*(t-k)/sqrt(N-k)] and a = 0.850, 0.948, 1.143 at 10%, 5%
and 1%. CUSUMSQ(t) is the running sum of squared w normalised by the total,
with bands (t-k)/(N-k) +/- c0, where c0 uses the Kolmogorov-Smirnov
approximation Durbin (1969) derived for this statistic with m = (N-k)/2 - 1.

{pstd}
The table reports the largest amount by which each path leaves its band (zero
if it never does) and the value of the time variable at the first breach.
Stata's own {helpb estat sbcusum} is reported as a cross-check. Both paths are
plotted with their bands.


{marker multipliers}{...}
{title:Dynamic multipliers}

{pstd}
The cumulative multiplier of {it:depvar} with respect to a unit permanent
shock to x(m) is obtained by simulating the {it:estimated} error-correction
model forward, using all of its short-run dynamics:

{p 8 8 2}
D.y(h) = a*y(h-1) + pi(m)*x(m,h-1) + sum_j psi(j)*D.y(h-j)
+ sum_j om(m,j)*D.x(m,h-j)

{pstd}
with D.x(m,0) = 1 and zero thereafter. M(h) = y(h) converges to the long-run
coefficient -pi(m)/a. Confidence bands come from a parametric bootstrap,
b* ~ N(bhat,Vhat), recomputing the whole path per draw; {opt bands()} sets the
number of draws and {opt vce()} determines Vhat.

{pstd}
For the NARDL types the positive and negative paths are reported side by side
together with the asymmetry M+(h) - M-(h) and a confidence band on that
difference, which is the plot in Shin, Yu and Greenwood-Nimmo (2014).

{pstd}
The Wald asymmetry tests are H0: pi+ = pi- in the long run (equivalent to
equality of the long-run coefficients, since they share the denominator) and
H0: sum(om+) = sum(om-) in the short run, summed over {it:all} lagged
differences rather than the contemporaneous term alone.


{marker graphs}{...}
{title:Graphs}

{pstd}
Unless {opt nograph} is specified, {cmd:aardl} produces, with the prefix given
in {opt graphprefix()}:

{p2colset 8 22 24 2}{...}
{p2col:{it:p}{cmd:kstar}}SSR over the Fourier grid, integer points marked{p_end}
{p2col:{it:p}{cmd:fit}}actual vs fitted D.{it:depvar}{p_end}
{p2col:{it:p}{cmd:resid}}residuals with +/- 2 sigma bands{p_end}
{p2col:{it:p}{cmd:hist}}residual histogram with a fitted normal{p_end}
{p2col:{it:p}{cmd:qq}}normal quantile-quantile plot{p_end}
{p2col:{it:p}{cmd:ac} / {it:p}{cmd:pac}}residual autocorrelations{p_end}
{p2col:{it:p}{cmd:ect}}the error-correction term over time{p_end}
{p2col:{it:p}{cmd:cusum} / {it:p}{cmd:cusumsq}}CUSUM and CUSUMSQ with bands{p_end}
{p2col:{it:p}{cmd:dm_}{it:#}}cumulative multiplier per shock variable{p_end}
{p2col:{it:p}{cmd:asym_}{it:#}}asymmetric multipliers per decomposed variable{p_end}
{p2col:{it:p}{cmd:persistence}}persistence profile{p_end}
{p2col:{it:p}{cmd:bounds}}the three statistics against their critical values{p_end}
{p2col:{it:p}{cmd:bootFov}, {it:p}{cmd:boottDV}, {it:p}{cmd:bootFind}}bootstrap
null distributions with the observed statistic marked{p_end}
{p2col:{it:p}{cmd:dash}}a combined residual dashboard{p_end}


{marker post}{...}
{title:Postestimation}

{pstd}
{cmd:e(b)} holds the error-correction representation, so a plain linear
combination of it with the data is meaningless. {cmd:predict} therefore builds
everything from {cmd:e(b_ecm)}, the coefficient vector of the underlying
regression:

{p 8 15 2}
{cmd:predict} [{it:type}] {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 14 tabbed}{...}
{synopt:{opt xb}}fitted D.{it:depvar}; the default{p_end}
{synopt:{opt res:iduals}}D.{it:depvar} minus the fitted value{p_end}
{synopt:{opt ect}}the error-correction term{p_end}
{synopt:{opt lev:el}}fitted level, L.{it:depvar} plus the fitted difference{p_end}

{pstd}
{cmd:e(sample)} is set correctly, so {helpb test}, {helpb lincom} and
{helpb nlcom} all work on the EC representation. The OLS companion fit is left
stored under the name {cmd:_aardl_ols} and the inference fit under
{cmd:_aardl_inf}, so {helpb estat} diagnostics can be re-run by hand.

{pstd}
{cmd:aardl_advanced} re-runs the advanced analysis after estimation, optionally
with a different {opt horizon()}.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:aardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}observations used{p_end}
{synopt:{cmd:e(N_full)}}observations in the marked sample before lag loss{p_end}
{synopt:{cmd:e(df_m)}, {cmd:e(df_r)}}model and residual degrees of freedom{p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_a)}}R-squared, adjusted{p_end}
{synopt:{cmd:e(ll)}, {cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(hqic)}}fit criteria{p_end}
{synopt:{cmd:e(rmse)}, {cmd:e(mss)}, {cmd:e(rss)}, {cmd:e(F)}}fit statistics{p_end}
{synopt:{cmd:e(F_pss)}}the F_overall statistic{p_end}
{synopt:{cmd:e(t_pss)}}the t_DV statistic{p_end}
{synopt:{cmd:e(F_ind)}}the F_ind statistic{p_end}
{synopt:{cmd:e(Fov_bp)}, {cmd:e(tDV_bp)}, {cmd:e(Find_bp)}}bootstrap p-values{p_end}
{synopt:{cmd:e(Fov_cv5)}, {cmd:e(tDV_cv5)}, {cmd:e(Find_cv5)}}bootstrap 5% values{p_end}
{synopt:{cmd:e(case)}, {cmd:e(maxlag)}, {cmd:e(p)}}model configuration{p_end}
{synopt:{cmd:e(q_}{it:varname}{cmd:)}}selected lag order per regressor{p_end}
{synopt:{cmd:e(kstar)}}selected Fourier frequency (0 if none){p_end}
{synopt:{cmd:e(hlag)}}Newey-West bandwidth actually used{p_end}
{synopt:{cmd:e(ecm_coef)}}the speed of adjustment{p_end}
{synopt:{cmd:e(halflife)}, {cmd:e(domroot)}}half-life, dominant AR root{p_end}
{synopt:{cmd:e(nmodels)}}candidate models estimated in lag selection{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:aardl}{p_end}
{synopt:{cmd:e(cmdline)}}the command as typed{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(indepvars)}, {cmd:e(allx)}}variable lists{p_end}
{synopt:{cmd:e(ecmvars)}}right-hand side of the underlying regression{p_end}
{synopt:{cmd:e(fovterms)}, {cmd:e(findterms)}}the tested restrictions{p_end}
{synopt:{cmd:e(type)}, {cmd:e(ic)}, {cmd:e(search)}}model settings{p_end}
{synopt:{cmd:e(vce)}, {cmd:e(vcetype)}}covariance estimator{p_end}
{synopt:{cmd:e(coint_status)}}{cmd:cointegrated}, {cmd:degenerate_indep},
{cmd:degenerate_dep} or {cmd:no_cointegration}{p_end}
{synopt:{cmd:e(kmode)}, {cmd:e(ktype)}, {cmd:e(breaktype)}}Fourier settings{p_end}
{synopt:{cmd:e(cusum)}, {cmd:e(cusumsq)}}{cmd:STABLE} or {cmd:UNSTABLE}{p_end}
{synopt:{cmd:e(decompose)}, {cmd:e(decnames)}}NARDL variables{p_end}
{synopt:{cmd:e(predict)}}{cmd:aardl_p}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}EC representation (ADJ / LR / SR){p_end}
{synopt:{cmd:e(b_ecm)}, {cmd:e(V_ecm)}}the underlying regression{p_end}
{synopt:{cmd:e(bounds)}}the three statistics with their critical values{p_end}
{synopt:{cmd:e(diagnostics)}}diagnostic statistics and p-values{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Augmented ARDL, asymptotic bounds{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, maxlag(4) ic(aic)}{p_end}

{pstd}Case V, with a Newey-West covariance matrix{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, case(5) vce(hac)}{p_end}

{pstd}Bootstrap critical values, Bertelli et al. method{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(baardl) reps(999)}{p_end}

{pstd}McNown et al. bootstrap instead{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(baardl) bootstrap(mcnown)}{p_end}

{pstd}Fourier, with the frequency forced onto the integer grid{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(faardl) kmode(integer)}{p_end}

{pstd}Fourier, permanent-break interpretation{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(faardl) kmode(fractional) maxk(5)}{p_end}

{pstd}Asymmetric ARDL with bootstrap inference{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(banardl) decompose(ln_inc) reps(999)}{p_end}

{pstd}Fourier bootstrap NARDL, everything on{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, type(fbanardl) decompose(ln_inc) maxlag(3) reps(999) horizon(36)}{p_end}

{pstd}Fast exploratory run{p_end}
{phang2}{cmd:. aardl ln_inv ln_inc ln_consump, maxlag(2) nodiag nostability nodynmult noadvanced nograph}{p_end}

{pstd}Postestimation{p_end}
{phang2}{cmd:. predict double dyhat}{p_end}
{phang2}{cmd:. predict double ecterm, ect}{p_end}
{phang2}{cmd:. test [LR]}{p_end}
{phang2}{cmd:. aardl_advanced, horizon(48)}{p_end}


{marker references}{...}
{title:References}

{phang}
Bertelli, S., Vacca, G. and Zoia, M. 2022. Bootstrap cointegration tests in
ARDL models. {it:Economic Modelling} 116: 105987.
{browse "https://doi.org/10.1016/j.econmod.2022.105987"}

{phang}
Brown, R.L., Durbin, J. and Evans, J.M. 1975. Techniques for testing the
constancy of regression relationships over time. {it:Journal of the Royal
Statistical Society, Series B} 37: 149-192.

{phang}
Christopoulos, D.K. and Leon-Ledesma, M.A. 2011. International output
convergence, breaks, and asymmetric adjustment. {it:Studies in Nonlinear
Dynamics and Econometrics} 15(3).

{phang}
Durbin, J. 1969. Tests for serial correlation in regression analysis based on
the periodogram of least-squares residuals. {it:Biometrika} 56: 1-15.

{phang}
Kripfganz, S. and Schneider, D.C. 2020. Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction
models. {it:Oxford Bulletin of Economics and Statistics} 82: 1456-1481.
{browse "https://doi.org/10.1111/obes.12377"}

{phang}
McNown, R., Sam, C.Y. and Goh, S.K. 2018. Bootstrapping the autoregressive
distributed lag test for cointegration. {it:Applied Economics} 50: 1509-1521.
{browse "https://doi.org/10.1080/00036846.2017.1366643"}

{phang}
Newey, W.K. and West, K.D. 1987. A simple, positive semi-definite,
heteroskedasticity and autocorrelation consistent covariance matrix.
{it:Econometrica} 55: 703-708.
{browse "https://doi.org/10.2307/1913610"}

{phang}
Omay, T. 2015. Fractional frequency flexible Fourier form to approximate
smooth breaks in unit root testing. {it:Economics Letters} 134: 123-126.

{phang}
Pesaran, M.H., Shin, Y. and Smith, R.J. 2001. Bounds testing approaches to the
analysis of level relationships. {it:Journal of Applied Econometrics} 16:
289-326. {browse "https://doi.org/10.1002/jae.616"}

{phang}
Sam, C.Y., McNown, R. and Goh, S.K. 2019. An augmented autoregressive
distributed lag bounds test for cointegration. {it:Economic Modelling} 80:
130-141. {browse "https://doi.org/10.1016/j.econmod.2018.11.001"}

{phang}
Shin, Y., Yu, B. and Greenwood-Nimmo, M. 2014. Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In
{it:Festschrift in Honor of Peter Schmidt}, 281-314. New York: Springer.
{browse "https://doi.org/10.1007/978-1-4899-8008-3_9"}

{phang}
Yilanci, V., Bozoklu, S. and Gorus, M.S. 2020. Are BRICS countries pollution
havens? Evidence from a bootstrap ARDL bounds testing approach with a Fourier
function. {it:Sustainable Cities and Society} 60: 102244.
{browse "https://doi.org/10.1016/j.scs.2020.102244"}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Online: {helpb ardl}, {helpb ardlbounds}, {helpb newey}, {helpb estat sbcusum}
{p_end}
