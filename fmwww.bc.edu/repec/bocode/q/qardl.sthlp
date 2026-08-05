{smcl}
{* *! version 1.2.0  04aug2026}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{viewerjumpto "Syntax" "qardl##syntax"}{...}
{viewerjumpto "Description" "qardl##description"}{...}
{viewerjumpto "Options" "qardl##options"}{...}
{viewerjumpto "Remarks" "qardl##remarks"}{...}
{viewerjumpto "Examples" "qardl##examples"}{...}
{viewerjumpto "Output interpretation" "qardl##interpretation"}{...}
{viewerjumpto "Stored results" "qardl##results"}{...}
{viewerjumpto "Methods and formulas" "qardl##methods"}{...}
{viewerjumpto "Companion commands" "qardl##companion"}{...}
{viewerjumpto "The qardl suite" "qardl##suite"}{...}
{viewerjumpto "Changes in version 1.2.0" "qardl##version"}{...}
{viewerjumpto "References" "qardl##references"}{...}
{viewerjumpto "Author" "qardl##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:qardl} {hline 2}}Quantile Autoregressive Distributed-Lag (QARDL) Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qardl}
{depvar}
{indepvars}
{ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tau(numlist)}}quantile levels; {ul:required}; values in (0,1){p_end}
{synopt:{opt p(#)}}autoregressive lag order for {depvar}; default 0 = automatic{p_end}
{synopt:{opt q(#)}}distributed lag order for {indepvars}; default = automatic{p_end}
{synopt:{opt qvec(numlist)}}per-regressor distributed-lag orders, one per {indepvar}{p_end}
{synopt:{opt ecm}}estimate QARDL-ECM (Error Correction Model) form{p_end}
{synopt:{opt ecmt:ype(type)}}ECM parameterisation: {cmd:cho}, {cmd:twostep} or {cmd:both}{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:Lag selection}
{synopt:{opt crit:erion(ic)}}{cmd:aic}, {cmd:bic}, {cmd:hq}, {cmd:hqc} or {cmd:gets}; default {cmd:bic}{p_end}
{synopt:{opt pmin(#)}}minimum p for the search; default is {cmd:pmin(1)}{p_end}
{synopt:{opt pmax(#)}}maximum p for the search; default is {cmd:pmax(8)}{p_end}
{synopt:{opt qmin(#)}}minimum q for the search; default is {cmd:qmin(0)}{p_end}
{synopt:{opt qmax(#)}}maximum q for the search; default is {cmd:qmax(8)}{p_end}
{synopt:{opt getsp:val(#)}}GETS significance threshold; default is {cmd:getspval(0.1)}{p_end}

{syntab:Covariance}
{synopt:{opt cov:ariance(vce)}}{cmd:iid}, {cmd:robust} or {cmd:hac}; default {cmd:iid}{p_end}
{synopt:{opt hac:lags(#)}}HAC bandwidth; 0 = automatic Newey-West{p_end}

{syntab:Rolling estimation}
{synopt:{opt rolling(#)}}rolling window size; 0 = auto (10% of sample){p_end}
{synopt:{opt window(#)}}alias for {opt rolling()}{p_end}

{syntab:Simulation}
{synopt:{opt simulate(# [#])}}Monte Carlo with {it:reps} [and {it:nobs}]{p_end}

{syntab:Testing}
{synopt:{opt sym:metry}}Wald tests of H0: b(tau) = b(1-tau){p_end}
{synopt:{opt wald:test(spec)}}Wald tests on chosen parameter blocks{p_end}

{syntab:Output}
{synopt:{opt graph}}produce quantile process graphs{p_end}
{synopt:{opt notable}}suppress coefficient tables{p_end}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}

{pstd}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:qardl} estimates the Quantile Autoregressive Distributed-Lag (QARDL) model
proposed by {help qardl##CKS2015:Cho, Kim & Shin (2015)}.  The QARDL model extends 
the traditional {help qardl##PS1998:Pesaran & Shin (1998)} ARDL cointegration 
framework into a quantile regression setting, enabling researchers to examine how 
the relationship between an I(1) dependent variable and I(1) regressors varies 
across different quantiles of the conditional distribution.

{pstd}
{cmd:qardl} provides the following estimation results for each specified quantile:

{p2colset 9 30 32 2}{...}
{p2col:{bf:beta(tau)}}long-run cointegrating parameters{p_end}
{p2col:{bf:phi(tau)}}short-run autoregressive (AR) parameters{p_end}
{p2col:{bf:gamma(tau)}}short-run impact (distributed lag) parameters{p_end}
{p2colreset}{...}

{pstd}
Along with their asymptotic covariance matrices and Wald tests for parameter 
constancy across quantiles.

{pstd}
The key advantage of QARDL over standard ARDL is the ability to detect 
{bf:asymmetric} and {bf:heterogeneous} long-run and short-run dynamics.
For example, the speed of adjustment or the long-run equilibrium may differ
between bull and bear markets (upper vs. lower quantiles).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt tau(numlist)} specifies the quantile levels at which to estimate the model.
Values must be strictly between 0 and 1. Multiple quantiles can be specified for 
across-quantile testing. At least two quantiles are needed for Wald tests of
parameter constancy. Common choices:

{p 12 16 2}
{cmd:tau(0.25 0.5 0.75)} for quartile analysis{break}
{cmd:tau(0.1 0.25 0.5 0.75 0.9)} for comprehensive coverage{break}
{cmd:tau(0.1(0.1)0.9)} for a fine grid of 9 quantiles

{phang}
{opt p(#)} specifies the autoregressive lag order for the dependent variable
(p >= 1).  Left at its default of 0, p is chosen automatically over
{opt pmin()}-{opt pmax()} by the criterion in {opt criterion()}, and the full
information-criterion grid is displayed with the optimal pair highlighted.

{phang}
{opt q(#)} specifies the distributed lag order for the independent variables
(q >= 0).  Omitted, q is chosen automatically over {opt qmin()}-{opt qmax()}.
{cmd:q(0)} is a valid fixed order: it drops the lagged-difference terms so the
model contains only the levels of {indepvars} and the p lags of {depvar}.
This matches {cmd:q = 0} support in the GAUSS QARDL 3.1.1 library.

{pstd}
{bf:Note.} p and q are selected jointly, so fixing one and leaving the other
automatic searches only over the free order.

{phang}
{opt qvec(numlist)} gives each regressor its own distributed-lag order, in the
order the regressors appear in {indepvars}.  This is {cmd:qardlX} in GAUSS
QARDL 3.1.1.  It requires an explicit {opt p()} and cannot be combined with
{opt q()}, {opt ecm}, {opt rolling()} or {opt simulate()}.  A constant vector
such as {cmd:qvec(2 2)} is silently treated as {cmd:q(2)}.

{pstd}
Because the Cho-Kim-Shin iid covariance formulas are written for a single
scalar q and do not generalise to a heterogeneous lag structure, {opt qvec()}
always uses the quantile-regression sandwich; specifying
{cmd:covariance(iid)} with it switches to {cmd:robust} with a note.  GAUSS
{cmd:qardlX} defaults to {cmd:cov_type = "robust"} for the same reason.

{dlgtab:Lag selection}

{phang}
{opt criterion(ic)} selects the information criterion used for automatic lag
selection.  {cmd:bic} (default), {cmd:aic}, {cmd:hq} and {cmd:hqc} are
supported, matching the criteria available in {cmd:icmean}/{cmd:pqSelect} in
GAUSS QARDL 3.1.1.  With n the effective sample size, s2 the residual variance
and m the number of estimated coefficients:

{p 12 16 2}
{cmd:aic} = n*ln(s2) + 2*m{break}
{cmd:bic} = n*ln(s2) + m*ln(n){break}
{cmd:hq}, {cmd:hqc} = n*ln(s2) + 2*m*ln(ln(n))

{phang}
{opt pmin(#)}, {opt pmax(#)}, {opt qmin(#)}, {opt qmax(#)} bound the lag search
grid.  The defaults {cmd:pmin(1)}, {cmd:pmax(8)}, {cmd:qmin(0)}, {cmd:qmax(8)}
match the GAUSS 3.1.1 defaults.

{phang}
{opt criterion(gets)} instead runs the hierarchical general-to-specific search
of GAUSS 3.1.1.  It starts at {opt pmax()}/{opt qmax()} and repeatedly drops
whichever boundary lag is least significant, until the highest retained AR lag
and the highest retained distributed lag are both significant at
{opt getspval()}.  No information-criterion grid is produced in this mode.

{phang}
{opt getspval(#)} sets the GETS retention threshold; the default 0.1 matches
the GAUSS default.

{pstd}
{bf:Change from version 1.1.0.}  The search bounds were {cmd:pmax(7)} and
{cmd:qmax(7)} and q started at 1.  Selected orders may therefore differ from
earlier runs.  To reproduce version 1.1.0 output exactly, specify
{cmd:pmax(7) qmax(7) qmin(1)}.

{dlgtab:Covariance}

{phang}
{opt covariance(vce)} chooses the asymptotic covariance estimator.

{p 12 16 2}
{cmd:iid} (default) uses the Cho-Kim-Shin (2015) covariance formulas.  This is
the estimator the published results and the author demos are based on.{break}
{cmd:robust} uses a heteroskedasticity-robust quantile-regression sandwich.{break}
{cmd:hac} uses a Newey-West/Bartlett HAC quantile-regression sandwich, which is
appropriate when the quantile scores are serially correlated.

{pstd}
{cmd:robust} and {cmd:hac} correspond to {cmd:qardlRobust} and {cmd:qardlHAC}
in GAUSS QARDL 3.1.1.  Because the Cho-Kim-Shin iid covariance formulas are not
defined for q = 0, {cmd:q(0)} always uses the sandwich estimator, again as in
GAUSS.

{phang}
{opt haclags(#)} sets the HAC bandwidth and requires {cmd:covariance(hac)}.
The default 0 selects the automatic bandwidth trunc(4*(n/100)^(2/9)), matching
{cmd:_qardlAutomaticHACLags()} in GAUSS.

{dlgtab:Error correction}

{phang}
{opt ecm} requests the QARDL Error Correction Model (ECM) form, reported in
addition to the standard beta, phi, and gamma.

{phang}
{opt ecmtype(type)} selects the ECM parameterisation.  The two are different
objects, not competing estimates of the same thing.

{p 12 16 2}
{cmd:cho} (default) reproduces Cho's MATLAB {cmd:qardlecm.m} and reports
{bf:phi*(tau)}, the cumulative AR coefficients of the ECM parameterisation, and
{bf:theta(tau)}, the ECM impact coefficients of the differenced regressors.
This is the parameterisation shipped in versions 1.0.0 and 1.1.0 and requires
q >= 1.{break}
{cmd:twostep} reproduces {cmd:qardlECM()} from GAUSS QARDL 3.1.1: the long-run
vector beta_LR is estimated by OLS in step one, the error-correction term
ECT(-1) = y(-1) - x(-1)'beta_LR is formed from it, and step two runs a quantile
regression of d.y on [1, ECT(-1), d.y lags, d.x lags], reporting the intercept
{bf:alpha(tau)} and the speed of adjustment {bf:rho(tau)} with a half-life
column.{break}
{cmd:both} reports both parameterisations.

{pstd}
Specifying {opt ecmtype()} implies {opt ecm}.

{dlgtab:Rolling estimation}

{phang}
{opt rolling(#)} activates rolling-window QARDL estimation with the specified
window size. This produces time-varying parameter estimates and Wald test
statistics, useful for structural break analysis. If set to 0, the window
size is automatically chosen as max(10% of sample, p+q+k+10).

{pstd}
{bf:Change from version 1.1.0.}  The rolling Wald matrices
{cmd:e(rolling_wald_beta)}, {cmd:e(rolling_wald_phi)} and
{cmd:e(rolling_wald_gamma)} were allocated but never filled, so they were
returned as matrices of zeros.  They now hold the per-window constancy Wald
statistic, its p-value and its degrees of freedom in columns 1, 2 and 3.  Any
graph or table built on the old zeros will change.  Windows in which estimation
fails are stored as missing rather than silently skipped, and the count of such
windows is reported.

{dlgtab:Simulation}

{phang}
{opt simulate(# [#])} runs a Monte Carlo simulation to evaluate finite-sample 
properties of the Wald tests. The first number is the number of replications; 
the second (optional) is the sample size per replication (default = actual 
sample size). Reports empirical rejection rates at 10%, 5%, and 1% levels.

{dlgtab:Testing}

{phang}
{opt symmetry} adds Wald tests of quantile symmetry, H0: b(tau) = b(1-tau),
applied to beta, phi and gamma over every symmetric pair present in
{opt tau()}.  This is {cmd:wtestsym()} from GAUSS QARDL 3.1.1.  With no
symmetric pair in the grid the test is reported as unavailable rather than
computed on nothing; supply e.g. {cmd:tau(0.1 0.25 0.5 0.75 0.9)}.

{phang}
{opt waldtest(spec)} runs Wald tests on chosen parameter blocks.  {it:spec} is

{p 12 16 2}
{it:blocks} [{cmd:,} {opt r(matname)} {opt rr(matname)}]

{pstd}
where {it:blocks} is any combination of {cmd:beta}, {cmd:phi} and {cmd:gamma}.
Without {opt r()} the null is cross-quantile constancy,
H0: b(tau_i) = b(tau_{i+1}).  With {opt r()} the null is the general linear
restriction H0: R*b = r, where {opt r()} names the restriction matrix R and
{opt rr()} the (optional) right-hand-side vector, defaulting to zero.  These
correspond to {cmd:wtestlrb}, {cmd:wtestsrp} and {cmd:wtestsrg} in GAUSS.

{pstd}
The across-quantile constancy tests ({cmd:wtestconst}) are always reported
whether or not {opt waldtest()} is given.

{pstd}
{bf:Change from version 1.1.0.}  {opt waldtest()} was accepted but had no
effect: its parser was an empty placeholder, so the option silently did
nothing.  It is now implemented.  Degrees of freedom are also now
rank(R*V*R') rather than rows(R), matching {cmd:_qardlWaldInvAndRank()} in
GAUSS 3.1.1; the two differ when restrictions are redundant.

{dlgtab:Output}

{phang}
{opt graph} produces quantile process plots showing parameter estimates and 
confidence bands across quantiles. For rolling estimation, also produces 
time-varying plots.

{phang}
{opt notable} suppresses the coefficient display tables while still performing 
estimation and storing all results.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Data requirements.} The variables must be time series. Ensure data is 
{cmd:tsset} before using {cmd:qardl}. The QARDL framework is designed for 
cointegrated I(1) variables, but it does not test for unit roots or 
cointegration rank — users should determine the integration order of their 
variables beforehand.

{pstd}
{bf:Lag selection.} When {opt p()} and {opt q()} are not specified, the BIC 
criterion selects the optimal lag orders via OLS (at the conditional mean).
The selected orders are then used for quantile regression at all specified 
tau values.

{pstd}
{bf:Parameter ordering.} The parameter vectors (beta, phi, gamma) are stored 
in {bf:quantile-first} order. For example, with 2 independent variables and 
3 quantiles, the beta vector is ordered as:

{p 12 12 2}
beta = (beta_x1(tau1), beta_x2(tau1), beta_x1(tau2), beta_x2(tau2), beta_x1(tau3), beta_x2(tau3))'

{pstd}
Similarly, with p=2 lags and 3 quantiles:

{p 12 12 2}
phi = (phi_1(tau1), phi_2(tau1), phi_1(tau2), phi_2(tau2), phi_1(tau3), phi_2(tau3))'

{pstd}
This matches the ordering used in the original GAUSS implementation by Cho, Kim & Shin.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}{bf:Example 1: Basic QARDL with fixed lags}{p_end}
    {hline}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Estimate QARDL(2,1) at three key quantiles{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1)}{p_end}

{pstd}This produces three output tables:{p_end}
{p 8 8 2}
1. {bf:Long-run parameters (beta):} Equilibrium relationship at each quantile.
   Different beta values across quantiles indicate asymmetric long-run effects.{break}
2. {bf:Short-run AR parameters (phi):} How past {depvar} values affect the current 
   level at each quantile. Labeled as L1.dln_inv, L2.dln_inv.{break}
3. {bf:Short-run impact parameters (gamma):} Contemporaneous effect of x-variables 
   at each quantile.

{pstd}Plus a Wald test table checking if parameters are constant across quantiles.

    {hline}
{pstd}{bf:Example 2: Automatic BIC lag selection}{p_end}
    {hline}

{pstd}Let the BIC choose optimal p and q (p over 1-8, q over 0-8){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9)}{p_end}

{pstd}For a narrower search range:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) pmax(4) qmax(4)}{p_end}

{pstd}With a different criterion, and excluding q = 0 from the grid:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) criterion(aic) qmin(1)}{p_end}

{pstd}Fix p and let the criterion choose q only:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2)}{p_end}

{pstd}Reproduce version 1.1.0 lag selection exactly:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) pmax(7) qmax(7) qmin(1)}{p_end}

    {hline}
{pstd}{bf:Example 2b: Robust and HAC covariance}{p_end}
    {hline}

{pstd}Heteroskedasticity-robust quantile-regression sandwich ({cmd:qardlRobust}){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) covariance(robust)}{p_end}

{pstd}Newey-West HAC with the automatic bandwidth ({cmd:qardlHAC}){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) covariance(hac)}{p_end}

{pstd}HAC with a fixed bandwidth of 4 lags{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) covariance(hac) haclags(4)}{p_end}

{pstd}A pure quantile autoregression with levels of x and no lagged differences{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(0)}{p_end}

    {hline}
{pstd}{bf:Example 2c: Symmetry and custom Wald tests}{p_end}
    {hline}

{pstd}Test H0: b(tau) = b(1-tau) on a symmetric quantile grid{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) p(2) q(1) symmetry}{p_end}

{pstd}Constancy tests on selected parameter blocks{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) waldtest(beta gamma)}{p_end}

{pstd}A custom restriction, here H0: beta_1(0.25) = beta_1(0.75) with k = 2, s = 3{p_end}
{phang2}{cmd:. matrix R = (1,0,0,0,-1,0)}{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) waldtest(beta, r(R))}{p_end}

{pstd}The same test as postestimation{p_end}
{phang2}{cmd:. _qardl_waldtest, type(beta) r(R)}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(gamma) null(symmetry)}{p_end}

    {hline}
{pstd}{bf:Example 3: QARDL-ECM estimation}{p_end}
    {hline}

{pstd}Estimate the Error Correction form — useful when the ECM term (speed of 
adjustment) is of interest{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecm}{p_end}

{pstd}This additionally reports:{p_end}
{p 8 8 2}
{bf:phi*(tau):} Cumulative AR parameters in the ECM parameterization.{break}
{bf:theta(tau):} Impact coefficients of dx in the ECM form.{break}
Plus ECM-specific Wald tests for constancy of phi* and theta.

{pstd}The GAUSS 3.1.1 two-step ECM instead, reporting alpha(tau), the speed of
adjustment rho(tau) with half-lives, and the step-one OLS long-run vector{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecmtype(twostep)}{p_end}

{pstd}Both parameterisations side by side{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecmtype(both)}{p_end}

{pstd}The two answer different questions, so neither supersedes the other: the
Cho form describes the short-run dynamics, the two-step form gives the
error-correction speed directly.{p_end}

    {hline}
{pstd}{bf:Example 4: Fine quantile grid with graphs}{p_end}
    {hline}

{pstd}Estimate at 9 quantiles and plot the quantile process{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.1(0.1)0.9) p(1) q(1) graph}{p_end}

    {hline}
{pstd}{bf:Example 5: Rolling window estimation}{p_end}
    {hline}

{pstd}Time-varying QARDL with a 60-observation rolling window{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(1) q(1) rolling(60)}{p_end}

{pstd}Auto window size (10% of sample){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.5) p(1) q(1) rolling(0)}{p_end}

    {hline}
{pstd}{bf:Example 6: Monte Carlo simulation}{p_end}
    {hline}

{pstd}Evaluate Wald test size with 500 replications and n=500{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.25 0.5 0.75) p(1) q(1) simulate(500 500)}{p_end}

    {hline}
{pstd}{bf:Example 7: Post-estimation access to stored results}{p_end}
    {hline}

{pstd}Run estimation and access results{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1)}{p_end}

{pstd}View stored beta coefficients{p_end}
{phang2}{cmd:. matrix list e(beta)}{p_end}

{pstd}View beta covariance matrix{p_end}
{phang2}{cmd:. matrix list e(beta_cov)}{p_end}

{pstd}View raw quantile regression coefficients{p_end}
{phang2}{cmd:. matrix list e(bt_raw)}{p_end}

{pstd}Access specific elements{p_end}
{phang2}{cmd:. display "Beta for x1 at tau=0.25: " e(beta)[1,1]}{p_end}
{phang2}{cmd:. display "Optimal p = " e(p) " , q = " e(q)}{p_end}
{phang2}{cmd:. display "Number of quantiles = " e(ntau)}{p_end}

    {hline}
{pstd}{bf:Example 8: Reproducing the Cho, Kim & Shin demo}{p_end}
    {hline}

{pstd}
The original GAUSS demo uses data with 2 independent variables, 
selects p via BIC (gets p=2, overridden to p=3 in the demo), q=1, 
and estimates at 9 quantiles (tau = 0.1, 0.2, ..., 0.9).
To replicate with {cmd:qardl}:

{phang2}{cmd:. * Load your data (e.g., from the GAUSS qardl_data.dat)}{p_end}
{phang2}{cmd:. * Assuming variables are y, x1, x2}{p_end}
{phang2}{cmd:. qardl y x1 x2, tau(0.1(0.1)0.9) p(3) q(1)}{p_end}

{pstd}The output should match the GAUSS demo results:{p_end}
{p 8 8 2}
{bf:Phi} (with p=3): L1.y (≈0.26), L2.y (≈-0.007), L3.y (≈-0.002) at each quantile{break}
{bf:Beta}: x1 (≈6.665), x2 (≈6.667) at each quantile{break}
{bf:Gamma}: x1 (≈4.99), x2 (≈4.99) at each quantile

    {hline}
{pstd}{bf:Example 9: Generate example data with known DGP}{p_end}
    {hline}

{pstd}Generate data from the Cho, Kim & Shin (2015) DGP for testing{p_end}
{phang2}{cmd:. qardl_makedata, n(500) seed(12345)}{p_end}

{pstd}Estimate and compare to known true values (beta = 6.6667){p_end}
{phang2}{cmd:. qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(2)}{p_end}

    {hline}
{pstd}{bf:Example 10: Post-estimation Wald tests}{p_end}
    {hline}

{pstd}After estimation, run individual Wald tests{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(1) q(1)}{p_end}

{pstd}Test beta constancy (quantile cointegration){p_end}
{phang2}{cmd:. _qardl_waldtest, type(beta) tau(0.25 0.5 0.75)}{p_end}

{pstd}Test phi constancy (short-run AR asymmetry){p_end}
{phang2}{cmd:. _qardl_waldtest, type(phi) tau(0.25 0.5 0.75)}{p_end}

{pstd}Test gamma constancy (short-run impact asymmetry){p_end}
{phang2}{cmd:. _qardl_waldtest, type(gamma) tau(0.25 0.5 0.75)}{p_end}

{pstd}For ECM: test phi* and theta constancy{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecm}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(phi_ecm) tau(0.25 0.5 0.75)}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(theta) tau(0.25 0.5 0.75)}{p_end}

    {hline}
{pstd}{bf:Example 11: Rolling estimation with graphs}{p_end}
    {hline}

{pstd}Combine rolling window estimation with visualizations{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) p(1) q(1) rolling(60) graph}{p_end}

{pstd}This produces:{p_end}
{p 8 8 2}
1. Quantile process plots for beta, phi, gamma with 95% confidence bands{break}
2. Combined panel of all parameter plots{break}
3. Rolling window plots of beta at the median quantile{break}
4. Rolling Wald statistic plot with 5% critical value line

    {hline}
{pstd}{bf:Example 12: Advanced asymmetry analysis}{p_end}
    {hline}

{pstd}After estimation, run the full asymmetry diagnostic suite{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) p(1) q(1)}{p_end}
{phang2}{cmd:. qardl_analysis}{p_end}

{pstd}This produces:{p_end}
{p 8 8 2}
1. Asymmetry summary tables for beta and gamma (min, max, ratio, index, Wald){break}
2. Coefficient heatmap across quantiles{break}
3. Pairwise quantile equality test matrix{break}
4. Fan charts showing all variables on a single plot{break}
5. Asymmetry ratio bar chart (max/min for each variable){break}
6. Tail divergence plot with confidence intervals{break}
7. Quantile gradient plot showing where asymmetry is concentrated{break}
8. Combined dashboard panel

{pstd}For tables only (no graphs):{p_end}
{phang2}{cmd:. qardl_analysis, nograph}{p_end}

{pstd}For graphs only (no tables):{p_end}
{phang2}{cmd:. qardl_analysis, nosummary}{p_end}

    {hline}
{pstd}{bf:Example 13: Automatic lag order selection with BIC grid}{p_end}
    {hline}

{pstd}Let the BIC criterion select optimal (p,q) and display the full grid{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9)}{p_end}

{pstd}This displays a table of BIC values for all combinations p=1,...,7 and q=1,...,7,
with the optimal pair marked by {cmd:*}. You can limit the search range:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.5 0.9) pmax(4) qmax(4)}{p_end}

{pstd}The BIC grid follows {help qardl##CKS2015:Cho et al. (2015)} and
the original MATLAB/GAUSS {cmd:pqorder()} function. It computes
BIC = n*ln(mean(u^2)) + k*ln(n) for each (p,q) via OLS at the conditional
mean, then selects the combination with smallest BIC value.{p_end}


{marker interpretation}{...}
{title:Output interpretation}

{pstd}
{bf:Output tables.} The {cmd:qardl} output displays three main coefficient 
tables, each organized by quantile. Within each quantile block, all 
lags/variables are listed:

{col 5}{hline 66}
{col 5}Long-Run Parameters: {it:beta}(tau)
{col 5}{hline 66}
{col 7}Variable    Quantile     Estimate    Std.Err.     t-stat    p-value
{col 5}{hline 66}
{col 5}{hline 4}{it: tau = 0.25}{hline 48}
{col 7}x1            0.25       6.6646      0.5184      12.856     0.0000
{col 7}x2            0.25       6.6669      0.1954      34.114     0.0000
{col 5}{hline 4}{it: tau = 0.50}{hline 48}
{col 7}x1            0.50       6.6660      0.4900      13.604     0.0000
{col 7}x2            0.50       6.6667      0.1847      36.085     0.0000
{col 5}{hline 66}

{pstd}
{bf:Interpreting beta (long-run parameters).} The long-run equilibrium 
relationship at quantile tau is:

{p 8 8 2}
y = alpha(tau) + beta_1(tau)*x1 + beta_2(tau)*x2

{pstd}
If beta varies across quantiles, the long-run relationship is {bf:asymmetric}: 
the equilibrium impact of x differs depending on whether y is in the upper or 
lower tail of its distribution.

{pstd}
{bf:Interpreting phi (short-run AR parameters).} phi_i(tau) captures the 
persistence of the dependent variable at quantile tau. The sum of all phi 
coefficients indicates the total short-run persistence. If the sum is close to 1,
shocks are highly persistent at that quantile.

{pstd}
{bf:Interpreting gamma (short-run impact parameters).} gamma_j(tau) measures the 
immediate impact of x on y at quantile tau. If gamma varies across quantiles, the 
short-run response is asymmetric.

{pstd}
{bf:Interpreting the Wald test.} The Wald test for constancy tests:

{p 8 8 2}
H0: parameter(tau_i) = parameter(tau_{i+1}) for all adjacent quantile pairs.

{pstd}
{bf:Rejection} (p < 0.05) means the parameter varies significantly across 
quantiles — evidence of {bf:quantile heterogeneity}. This is the key result 
of the QARDL approach: if the standard ARDL (conditional mean) misses these 
quantile differences, it provides an incomplete picture.

{pstd}
{bf:Interpreting ECM parameters.} With the {opt ecm} option:

{p 8 8 2}
{bf:phi*(tau):} Cumulative autoregressive parameters after reparameterization. 
These correspond to the coefficients of the differenced lagged dependent 
variable in the ECM form.{break}
{bf:theta(tau):} The short-run impact coefficients in the ECM form, 
combining the contemporaneous and lagged effects of dx.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:qardl} stores the following in {cmd:e()}:

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_eff)}}effective estimation sample after lag truncation{p_end}
{synopt:{cmd:e(p)}}autoregressive lag order{p_end}
{synopt:{cmd:e(q)}}distributed lag order{p_end}
{synopt:{cmd:e(k)}}number of independent variables{p_end}
{synopt:{cmd:e(ntau)}}number of quantile levels{p_end}
{synopt:{cmd:e(haclags)}}HAC bandwidth actually used (0 if not HAC){p_end}
{synopt:{cmd:e(scale_beta)}}normalisation divisor for the beta covariance{p_end}
{synopt:{cmd:e(scale_short)}}normalisation divisor for the phi/gamma covariance{p_end}

{pstd}
{cmd:e(beta_cov)} is stored on the scale of the underlying asymptotic formulas,
so standard errors are

{p 12 16 2}
se(beta) = sqrt( diag(e(beta_cov)) / e(scale_beta) ){break}
se(phi)  = sqrt( diag(e(phi_cov))  / e(scale_short) ){break}
se(gamma)= sqrt( diag(e(gamma_cov))/ e(scale_short) )

{pstd}
Under {cmd:covariance(iid)} with q >= 1 these divisors are (n-1)^2 and (n-1)
respectively, matching {cmd:_qardlLevelsSE()} in GAUSS QARDL 3.1.1.  Under
{cmd:robust}, {cmd:hac} or {cmd:q(0)} the stored matrices are ordinary
covariance estimates and both divisors are 1.  Always divide by the stored
scalars rather than hardcoding (n-1).

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Matrices}{p_end}
{synopt:{cmd:e(tau)}}(ntau x 1) vector of quantile levels{p_end}
{synopt:{cmd:e(beta)}}(k*ntau x 1) long-run parameters{p_end}
{synopt:{cmd:e(beta_cov)}}(k*ntau x k*ntau) covariance of beta{p_end}
{synopt:{cmd:e(phi)}}(p*ntau x 1) short-run AR parameters{p_end}
{synopt:{cmd:e(phi_cov)}}(p*ntau x p*ntau) covariance of phi{p_end}
{synopt:{cmd:e(gamma)}}(k*ntau x 1) short-run impact parameters{p_end}
{synopt:{cmd:e(gamma_cov)}}(k*ntau x k*ntau) covariance of gamma{p_end}
{synopt:{cmd:e(alpha)}}(ntau x 1) intercept alpha(tau) of the levels equation{p_end}
{synopt:{cmd:e(rho)}}(ntau x 1) implied rho(tau) = sum phi(tau) - 1{p_end}
{synopt:{cmd:e(bt_raw)}}(ncols x ntau) raw quantile regression coefficients{p_end}
{synopt:{cmd:e(fh)}}(ntau x 1) kernel density estimates{p_end}

{pstd}
With {cmd:ecm} and {cmd:ecmtype(cho)} or {cmd:ecmtype(both)}, additionally:

{synoptset 30 tabbed}{...}
{synopt:{cmd:e(phi_ecm)}}((p-1)*ntau x 1) ECM cumulative AR parameters{p_end}
{synopt:{cmd:e(phi_ecm_cov)}}covariance of phi_ecm{p_end}
{synopt:{cmd:e(theta)}}(q*k*ntau x 1) ECM impact parameters{p_end}
{synopt:{cmd:e(theta_cov)}}covariance of theta{p_end}

{pstd}
With {cmd:ecm} and {cmd:ecmtype(twostep)} or {cmd:ecmtype(both)}, additionally:

{synoptset 30 tabbed}{...}
{synopt:{cmd:e(beta_lr)}}(k x 1) step-one OLS long-run coefficients{p_end}
{synopt:{cmd:e(ecm_alpha)}}(ntau x 1) ECM intercept alpha(tau){p_end}
{synopt:{cmd:e(ecm_alpha_cov)}}(ntau x ntau) covariance of alpha(tau){p_end}
{synopt:{cmd:e(ecm_rho)}}(ntau x 1) speed of adjustment rho(tau){p_end}
{synopt:{cmd:e(ecm_rho_cov)}}(ntau x ntau) covariance of rho(tau){p_end}
{synopt:{cmd:e(rho_ols)}}step-one OLS speed of adjustment{p_end}
{synopt:{cmd:e(N_ecm)}}observations in the step-two ECM regression{p_end}

{pstd}
The two-step covariances are ordinary covariance estimates and need no
rescaling.

{pstd}
With {cmd:rolling()} option, additionally:

{synoptset 30 tabbed}{...}
{synopt:{cmd:e(rolling_beta)}}(nwindows x k*ntau) time-varying beta{p_end}
{synopt:{cmd:e(rolling_phi)}}(nwindows x p*ntau) time-varying phi{p_end}
{synopt:{cmd:e(rolling_gamma)}}(nwindows x k*ntau) time-varying gamma{p_end}
{synopt:{cmd:e(rolling_beta_se)}}(nwindows x k*ntau) time-varying beta SEs{p_end}
{synopt:{cmd:e(rolling_phi_se)}}(nwindows x p*ntau) time-varying phi SEs{p_end}
{synopt:{cmd:e(rolling_gamma_se)}}(nwindows x k*ntau) time-varying gamma SEs{p_end}
{synopt:{cmd:e(rolling_wald_beta)}}(nwindows x 3) beta constancy Wald, p, df{p_end}
{synopt:{cmd:e(rolling_wald_phi)}}(nwindows x 3) phi constancy Wald, p, df{p_end}
{synopt:{cmd:e(rolling_wald_gamma)}}(nwindows x 3) gamma constancy Wald, p, df{p_end}
{synopt:{cmd:e(rolling_window)}}rolling window size{p_end}

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qardl}{p_end}
{synopt:{cmd:e(model)}}{cmd:qardl} or {cmd:qardl-ecm}{p_end}
{synopt:{cmd:e(covariance)}}{cmd:iid}, {cmd:robust} or {cmd:hac}{p_end}
{synopt:{cmd:e(criterion)}}lag-selection criterion{p_end}
{synopt:{cmd:e(ecmtype)}}{cmd:cho}, {cmd:twostep} or {cmd:both} (ECM only){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(title)}}estimation title{p_end}
{synopt:{cmd:e(author)}}Dr Merwan Roudane{p_end}
{synopt:{cmd:e(email)}}merwanroudane920@gmail.com{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Notation.}  Let y_t be the dependent variable, x_t = (x_1t,...,x_kt)' a
k-vector of I(1) regressors, t = 1,...,n.  Let tau denote a quantile level
in (0,1) and s the number of specified quantiles.{p_end}


    {hline}
{pstd}{bf:1. QARDL(p,q) Model} (Cho et al., 2015, eq. 1){p_end}
    {hline}

{pstd}
The conditional quantile function is:{p_end}

{col 7}Q_y(tau | F_t-1) = alpha(tau)
{col 28}+ SUM_j=0^q-1  delta_j(tau)' * Dx_t-j
{col 28}+ gamma(tau)' * x_t
{col 28}+ SUM_i=1^p  phi_i(tau) * y_t-i

{pstd}
where Dx_t-j = x_t-j - x_t-j-1 are first differences.{p_end}

{pstd}Parameters:{p_end}
{phang2}- {bf:alpha(tau)}: intercept at quantile tau{p_end}
{phang2}- {bf:delta_j(tau)}: (k x 1) response to the j-th lagged difference{p_end}
{phang2}- {bf:gamma(tau)}: (k x 1) coefficient on the level of x_t{p_end}
{phang2}- {bf:phi_i(tau)}: autoregressive coefficient on y_t-i{p_end}

{pstd}
Estimation is by quantile regression (IRLS algorithm initialized with OLS).{p_end}


    {hline}
{pstd}{bf:2. Long-Run Parameters: beta(tau)} (Cho et al., 2015, eq. 4){p_end}
    {hline}

{pstd}The long-run cointegrating coefficient at quantile tau:{p_end}

{col 7}beta(tau) = gamma(tau) / (1 - SUM_i  phi_i(tau))

{pstd}
If constant across quantiles, beta(tau) = beta for all tau, recovering the
standard Pesaran and Shin (1998) ARDL result.{p_end}

{pstd}Covariance (Theorem 1):{p_end}

{col 7}V_beta = Omega (kron) M^-1

{pstd}where (kron) denotes the Kronecker product.{p_end}

{pstd}{bf:Omega} is (s x s) with element:{p_end}

{col 7}Omega(j,i) = [min(tau_j, tau_i) - tau_j*tau_i] * b(tau_j) * b(tau_i)

{pstd}
where b(tau) = 1 / [(1 - SUM phi_i(tau)) * f(tau)] and f(tau) is the
conditional density of the regression error.{p_end}

{pstd}{bf:M} is the (k x k) data-dependent matrix:{p_end}

{col 7}M = [X'X - X'W * inv(W'W) * W'X] / (n-q)^2

{pstd}
where X = x_q+1:n (level regressors) and W = (1, barw) (constant and
cumulated lagged differences).{p_end}

{pstd} {p_end}
    {hline}
{pstd}{bf:3. Conditional Density Estimation}{p_end}
    {hline}

{pstd}The density f(tau) is estimated nonparametrically:{p_end}

{col 7}f_hat(tau) = (1/n) * SUM_t  phi(-u_t / h_B) / h_B

{pstd}
where phi(.) is the standard normal density and h_B is the Bofinger (1975)
bandwidth:{p_end}

{col 7}h_B = [4.5 * phi(z_tau)^4 / (n * (2*z_tau^2 + 1)^2)]^(1/5)

{pstd}
with z_tau = Phi^-1(tau).  This follows the original MATLAB and GAUSS codes.{p_end}


    {hline}
{pstd}{bf:4. Short-Run AR Parameters: phi(tau)} (Theorem 2){p_end}
    {hline}

{pstd}
phi(tau) = (phi_1(tau),...,phi_p(tau))' are from the quantile regression.
Joint covariance across quantiles (nuisance parameter approach):{p_end}

{col 7}V_phi: block (j,i) = c(tau_j, tau_i) * Psi(j,i)

{pstd}where:{p_end}

{col 7}c(tau_j, tau_i) = [min(tau_j,tau_i) - tau_j*tau_i] / [f(tau_j)*f(tau_i)]

{col 7}Psi(j,i) = inv(L_jj) * L_ji * inv(L_ii)

{pstd}
L is the (s*p x s*p) matrix of auxiliary regression residual products from
regressions of each lagged y_t-l on (1, x, Dx-lags).{p_end}


    {hline}
{pstd}{bf:5. Short-Run Impact Parameters: gamma(tau)} (Corollary 1){p_end}
    {hline}

{pstd}
gamma(tau) are the level coefficients on x_t.  Covariance by delta method:{p_end}

{col 7}V_gamma = Lambda * V_phi * Lambda'

{pstd}
Lambda is (k*s x s*p) block-diagonal with Lambda_j = beta(tau_j) * iota_p'.{p_end}


    {hline}
{pstd}{bf:6. Wald Tests for Parameter Constancy} (Section 3){p_end}
    {hline}

{pstd}Tests whether parameters are constant across quantiles:{p_end}

{col 7}H0: param(tau_1) = param(tau_2) = ... = param(tau_s)

{pstd}Implemented via (s-1) pairwise equality restrictions R*param = 0.{p_end}

{pstd}Wald statistics:{p_end}

{col 7}W_beta  = (n-1)^2 * (R*b)' * inv[R * V_beta  * R'] * (R*b)
{col 7}W_phi   = (n-1)   * (R*p)' * inv[R * V_phi   * R'] * (R*p)
{col 7}W_gamma = (n-1)   * (R*g)' * inv[R * V_gamma * R'] * (R*g)

{pstd}
Under H0: W ~ chi2(df) with df = (s-1)*d.  W_beta uses (n-1)^2 because
V_beta contains (n-q)^-2 from M; W_phi and W_gamma use (n-1).{p_end}

{pstd}
{bf:Rejection} (p < 0.05) = quantile heterogeneity = evidence of
{bf:quantile cointegration}.{p_end}

    {hline}
{pstd}{bf:7. ECM Speed of Adjustment: rho(tau)}{p_end}
    {hline}

{pstd}
The error correction coefficient at each quantile is:{p_end}

{col 7}rho(tau) = SUM phi_i(tau) - 1

{pstd}
Negative rho(tau) implies convergence to equilibrium.
The SE is computed via the delta method from the phi covariance.{p_end}


    {hline}
{pstd}{bf:8. Pairwise Equality Tests (by variable)}{p_end}
    {hline}

{pstd}
Variable-specific pairwise tests for each (tau_i, tau_j) pair:{p_end}

{col 7}W_v = scale * [param_v(tau_i) - param_v(tau_j)]^2 / Var(diff)

{pstd}
where Var(diff) = V_ii + V_jj - 2*V_ij, and scale = (n-1)^2 for beta,
(n-1) for gamma. Under H0, W_v ~ chi2(1).{p_end}


    {hline}
{pstd}{bf:9. BIC Lag Selection} (p. 290){p_end}
    {hline}

{col 7}BIC(p,q) = n * ln(mean(u_hat^2)) + k_total * ln(n)

{pstd}
u_hat = OLS residuals, k_total = 1 + q*k + k + p.  Grid search over
p = 1,...,pmax and q = 1,...,qmax (default 7 each).{p_end}


{marker suite}{...}
{title:The qardl suite}

{pstd}
Version 1.2.0 ports the rest of the QARDL family from GAUSS QARDL 3.1.1.
Each command below is documented in its own file header; all of them are
post-estimation except {cmd:qardl_full}.

{synoptset 22 tabbed}{...}
{synopt:{helpb qardl_full}}the whole applied sequence in one call: lag
selection, QARDL, QARDL-ECM and residual diagnostics.  This is
{cmd:qardlFull} in GAUSS, minus its bounds-test step (see below), and is the
recommended entry point for applied work{p_end}
{synopt:{helpb qardl_qirf}}quantile impulse responses to a permanent or
temporary unit shock, with optional block-bootstrap bands and panel graphs
({cmd:qirf}, {cmd:blockBootstrapQIRF}, {cmd:plotQIRF}){p_end}
{synopt:{helpb qardl_boot}}block-bootstrap percentile confidence intervals for
beta, gamma and phi, or for the two-step ECM alpha and rho.  Moving, circular
and stationary resampling ({cmd:blockBootstrapQARDL*}){p_end}
{synopt:{helpb qardl_diag}}residual diagnostics per quantile: Ljung-Box,
Breusch-Godfrey, Breusch-Pagan, ARCH LM, Jarque-Bera, RESET, CUSUM and CUSUMSQ
({cmd:ardlResidualDiagnostics}){p_end}
{synopt:{helpb qardl_forecast}}recursive dynamic forecasts, optionally along a
supplied future regressor path ({cmd:forecastQARDL}){p_end}
{synopt:{helpb qardl_export}}write the coefficient tables to CSV, LaTeX or
Markdown ({cmd:saveQARDLResults}, {cmd:saveARDLLaTeX}, {cmd:saveARDLMarkdown}){p_end}
{synopt:{cmd:predict}}fitted values or residuals; takes {opt tau(#)} for one
quantile or a stub such as {cmd:predict fit*} for all of them
({cmd:predictQARDL}){p_end}
{synoptline}

{pstd}
A typical applied session:

{phang2}{cmd:. qardl_full y x1 x2, tau(0.1 0.25 0.5 0.75 0.9) symmetry}{p_end}
{phang2}{cmd:. qardl_qirf, horizon(24) bootstrap reps(499) graph}{p_end}
{phang2}{cmd:. qardl_boot, reps(999) method(circular)}{p_end}
{phang2}{cmd:. qardl_export using results.tex, format(latex) ci replace}{p_end}

{pstd}
{bf:Why there is no bounds test in this package.}  The Pesaran-Shin-Smith
bounds test is a {ul:conditional-mean} procedure: it estimates an unrestricted
error-correction model by OLS and forms an F-test on the lagged level terms.
No quantile enters the computation, so running it after a QARDL fit returns
the same number whatever {opt tau()} was used.  It tests whether a long-run
relation exists {it:on average}, not at any particular quantile.

{pstd}
GAUSS QARDL 3.1.1 ships it and {cmd:qardlFull} calls it, but its own
documentation is explicit that this is a compatibility statistic:
{cmd:docs/guides/BOUNDS_TESTING_SUPPORT.md} records that {cmd:qardlFull}
"reports the same compatibility ARDL Case III bounds statistic on the
underlying levels data" and that "quantile-specific bounds variants remain
outside the current public API".  Its {cmd:ardlbounds.src} contains no
reference to tau at all.

{pstd}
Shipping a mean-based cointegration test inside a package named {cmd:qardl}
invites it to be reported as evidence of cointegration at each quantile, which
it is not, so it is deliberately excluded.  If you need the bounds test as a
pre-test, run it with a dedicated ARDL command, cite it as a conditional-mean
result, and keep it separate from the quantile findings.

{pstd}
For quantile-by-quantile evidence on the long-run relation, use the speed of
adjustment rho(tau) from {opt ecmtype(twostep)}, which is estimated separately
at each quantile.  Note that under the null of no cointegration an ECM t-ratio
does not have a standard normal distribution, so the normal p-values printed
beside rho(tau) support inference on the adjustment speed {it:given}
cointegration, not a test {it:of} it.  No formal quantile cointegration test
is implemented here or in GAUSS 3.1.1; see Xiao (2009, Journal of
Econometrics) for the standard reference.

{pstd}
{bf:Per-regressor lag orders.}  {opt qvec()} gives each regressor its own
distributed-lag order, as {cmd:qardlX} does in GAUSS.  Because the
Cho-Kim-Shin iid covariance formulas are written for a single scalar q and do
not generalise to a heterogeneous lag structure, this path always uses the
quantile-regression sandwich; {cmd:qardlX} in GAUSS defaults to
{cmd:cov_type = "robust"} for the same reason.  The ECM, rolling and Monte
Carlo paths require a scalar {opt q()}.

{pstd}
{bf:GETS lag selection.}  {cmd:criterion(gets)} starts at
{opt pmax()}/{opt qmax()} and drops whichever boundary lag is least
significant until the highest retained lag of both blocks is significant at
{opt getspval()}.  No information-criterion grid is produced in this mode.


{marker companion}{...}
{title:Companion commands}

{pstd}
The {cmd:qardl} package includes the following companion commands:

{synoptset 25 tabbed}{...}
{synopt:{cmd:qardl_analysis}}advanced post-estimation analysis: quantile
   cointegration summary table (per-variable Wald tests with QC verdict),
   asymmetry diagnostics (min/max/ratio/index), coefficient heatmap,
   pairwise equality tests, fan charts, asymmetry ratio bars, tail
   divergence, gradient plots, ECM speed-of-adjustment bar chart, pairwise
   p-value dot plots (beta & gamma), and two combined dashboards;
   options: {opt nosummary} {opt nograph} {opt nopairwise}{p_end}
{synopt:{cmd:qardl_makedata}}generate example data from the Cho, Kim & Shin (2015)
   DGP with known true parameter values for validation{p_end}
{synopt:{cmd:_qardl_waldtest}}post-estimation Wald test for individual parameter
   types (beta, phi, gamma, phi_ecm, theta); returns r(wald), r(df), r(pval){p_end}
{synopt:{cmd:qardl_graph}}standalone graphing command (called automatically with
   {opt graph} option, but can be called separately after estimation){p_end}

{pstd}
Usage examples:

{phang2}{cmd:. qardl_analysis}{p_end}
{phang2}{cmd:. qardl_analysis, nograph}{p_end}
{phang2}{cmd:. qardl_makedata, n(1000) seed(42)}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(beta) tau(0.25 0.5 0.75)}{p_end}


{marker version}{...}
{title:Changes in version 1.2.0}

{pstd}
Version 1.2.0 aligns {cmd:qardl} with the GAUSS QARDL 3.1.1 library.  Two of
the changes below alter numbers reported by earlier versions.

{pstd}
{bf:Exact quantile regression solver.}  Versions 1.0.0 and 1.1.0 solved each
quantile regression by iteratively reweighted least squares, capped at 200
iterations.  On QARDL designs that solver reached the cap or stalled at a
non-optimal point often enough to move coefficients by up to 0.05 and long-run
beta by up to 0.014, non-deterministically.  It is replaced by the
Frisch-Newton primal-dual interior-point method of Portnoy and Koenker (1997),
the same class of solver behind GAUSS {cmd:quantileFit()} and the MATLAB
{cmd:linprog()} call in {cmd:qregressMatlab.m}.  Against the exact linear
program it reproduces the optimum to within 3e-8 across all tested designs, in
11 to 15 iterations.  Estimates from earlier versions will change slightly;
the new values are the correct ones.

{pstd}
{bf:Rolling Wald statistics.}  {cmd:e(rolling_wald_beta)},
{cmd:e(rolling_wald_phi)} and {cmd:e(rolling_wald_gamma)} were previously
returned as matrices of zeros.  They now contain real statistics.  See
{opt rolling()}.

{pstd}
{bf:waldtest() implemented.}  The option previously had no effect.  See
{opt waldtest()}.

{pstd}
{bf:Wald degrees of freedom.}  Now rank(R*V*R') rather than rows(R).  The
restriction machinery also errors on a dimension mismatch instead of silently
trimming R, and no longer takes the absolute value of the statistic.

{pstd}
{bf:Lag search defaults.}  {cmd:pmax()} and {cmd:qmax()} default to 8 rather
than 7, and the q grid starts at 0.  See {opt pmin()}.

{pstd}
{bf:New options.}  {opt covariance()}, {opt haclags()}, {opt criterion()}
(now including {cmd:gets}), {opt getspval()}, {opt pmin()}, {opt qmin()},
{opt qvec()}, {opt symmetry}, {opt ecmtype()}, and support for {cmd:q(0)}.

{pstd}
{bf:New commands.}  The rest of the QARDL family from GAUSS 3.1.1 is now
available: {helpb qardl_full}, {helpb qardl_qirf}, {helpb qardl_boot},
{helpb qardl_diag}, {helpb qardl_forecast}, {helpb qardl_export}, and
{cmd:predict}.  See {help qardl##suite:The qardl suite}.  The Pesaran-Shin-Smith
bounds test is deliberately {ul:not} included; see the note in that section.

{pstd}
{bf:Rolling ECM.}  With {opt rolling()} and {opt ecmtype(twostep)} or
{opt ecmtype(both)}, {cmd:e(rolling_ecm_alpha)} and {cmd:e(rolling_ecm_rho)}
hold the per-window two-step ECM estimates ({cmd:rollingQardlECM} in GAUSS).

{pstd}
{bf:ECM theta standard errors corrected.}  Versions 1.0.0 and 1.1.0 divided the
theta covariance by (n-1) while the matching Wald test used (n-2), following
Cho's {cmd:wtesttheta.m}.  The standard errors now use (n-2) as well, so the
reported t-ratios are consistent with the reported Wald statistic.

{pstd}
{bf:ECM theta labels corrected.}  The row labels of the theta table ran
lag-major while the coefficients are stored variable-major, so with more than
one regressor and q > 1 the labels did not match the numbers.  The estimates
themselves were always correct.

{pstd}
{bf:RESET conditioning.}  {helpb qardl_diag} standardises the fitted values
before forming the squared and cubed terms of the Ramsey RESET auxiliary
regression.  The span of [1, f, f^2, f^3] is invariant to an affine
transformation of f, so the statistic is unchanged in exact arithmetic, but
the raw form is severely ill-conditioned when the fitted values are large:
with f of order 1e3 the design reaches a condition number near 4e9, Stata's
{cmd:rank()} reports a rank deficiency that is not there, and the statistic
collapses to exactly zero.  Standardising brings the condition number to
about 5.  GAUSS forms the powers on the raw fitted values, so a RESET row of
exactly zero in a GAUSS log is this same numerical artifact.

{pstd}
{bf:Deviation from GAUSS 3.1.1.}  In GAUSS, {cmd:wtestsym()} scales the gamma
and phi statistics by (n-1)^2 while their covariances are stored on the (n-1)
scale, which inflates those two statistics by a factor of (n-1).  Its own
documentation and {cmd:wtestconst()} use (n-1) for gamma and phi.
{cmd:qardl} applies the consistent (n-1) scaling.  Likewise, GAUSS applies the
(n-1) Wald scalings under robust and HAC covariance even though
{cmd:_qardlLevelsSE()} does not rescale those covariances; {cmd:qardl} uses no
rescaling throughout the robust and HAC paths.  Under the default
{cmd:covariance(iid)} the two implementations agree.


{marker references}{...}
{title:References}

{marker CKS2015}{...}
{phang}
Cho, J. S., Kim, T., & Shin, Y. (2015). 
Quantile cointegration in the autoregressive distributed-lag modeling framework.
{it:Journal of Econometrics}, 188(2), 281-300.
{browse "https://doi.org/10.1016/j.jeconom.2015.05.003"}

{marker PS1998}{...}
{phang}
Pesaran, M. H., & Shin, Y. (1998). 
An autoregressive distributed-lag modelling approach to cointegration analysis.
{it:Econometric Society Monographs}, 31, 371-413.

{phang}
Xiao, Z. (2009). 
Quantile cointegrating regression.
{it:Journal of Econometrics}, 150(2), 248-260.

{phang}
Koenker, R., & Bassett, G. (1978).
Regression quantiles.
{it:Econometrica}, 46(1), 33-50.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
{cmd:qardl} v1.1.0 — February 2026

{pstd}
The GAUSS and MATLAB implementations were developed by Jin Seo Cho, Tae-hwan Kim 
& Yongcheol Shin. This Stata implementation was translated and extended by 
Dr Merwan Roudane.

{pstd}
Please cite this package as:{break}
Roudane, M. (2026). {cmd:qardl}: Stata module for Quantile Autoregressive 
Distributed-Lag estimation. Based on Cho, Kim & Shin (2015).
{p_end}
