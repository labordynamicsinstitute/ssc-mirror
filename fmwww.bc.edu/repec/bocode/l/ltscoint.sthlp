{smcl}
{* *! version 1.0.0  17sep2026}{...}
{vieweralsosee "ltscoint methods" "help ltscoint_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{vieweralsosee "ardl (if installed)" "help ardl"}{...}
{vieweralsosee "robreg (if installed)" "help robreg"}{...}
{viewerjumpto "Syntax" "ltscoint##syntax"}{...}
{viewerjumpto "Description" "ltscoint##description"}{...}
{viewerjumpto "Options" "ltscoint##options"}{...}
{viewerjumpto "Interpreting the output" "ltscoint##output"}{...}
{viewerjumpto "Remarks and practical guidance" "ltscoint##remarks"}{...}
{viewerjumpto "Examples" "ltscoint##examples"}{...}
{viewerjumpto "Stored results" "ltscoint##results"}{...}
{viewerjumpto "References" "ltscoint##references"}{...}
{viewerjumpto "Author" "ltscoint##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:ltscoint} {hline 2}}Least Trimmed Squares estimation of a cointegrated ADL with outliers
(Berenguer-Rico and Nielsen, 2026){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}Estimation{p_end}

{p 8 16 2}
{cmd:ltscoint} {it:depvar} {it:zvars} {ifin} [{cmd:,} {it:options}]

{pstd}Determining the number of good observations {it:h} (profile over {it:h}, paper's Table 7){p_end}

{p 8 16 2}
{cmd:ltscoint hsearch} {it:depvar} {it:zvars} {ifin} [{cmd:,} {it:hsearch_options}]

{pstd}Postestimation graphics and data plot{p_end}

{p 8 16 2}
{cmd:ltscoint graph} [{cmd:,} {opt name(stub)}]

{p 8 16 2}
{cmd:ltscoint dataplot} {it:depvar} {it:zvars} {ifin} [{cmd:,} {opt name(stub)} {opt kappa(numlist)}]

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opt lags(#)}}lag length {it:k} of the ADL in levels; the equilibrium-correction form has {it:k}-1 lagged differences; default {cmd:lags(2)}{p_end}
{synopt:{opt trend}}include a restricted linear trend, eq. (2.3); default is the restricted constant of eq. (2.1){p_end}

{syntab:Number of good observations}
{synopt:{opt h(#)}}number of good observations {it:h} (paper's notation){p_end}
{synopt:{opt nout(#)}}number of outliers {it:T}-{it:h}; alternative to {opt h()}{p_end}
{synopt:{opt hsel(cumulant|ic)}}when neither {opt h()} nor {opt nout()} is given, choose {it:h} by minimising the cumulant statistic {it:T_h} (default) or the information criterion {it:IC_h}{p_end}
{synopt:{opt hmin(#)}}lower bound of the search; default floor(2{it:T}/3)+1 (boundedness, eq. 4.8){p_end}
{synopt:{opt hmax(#)}}upper bound of the search; default {it:T}{p_end}
{synopt:{opt force}}allow {it:h} <= 2{it:T}/3 (outside the boundedness region; not recommended){p_end}

{syntab:Algorithm}
{synopt:{opt nsamp(#)}}number of random elemental starts in FAST-LTS; default 500{p_end}
{synopt:{opt csteps(#)}}concentration steps per start; default 2{p_end}
{synopt:{opt nkeep(#)}}number of best starts iterated to convergence; default 10{p_end}
{synopt:{opt seed(#)}}random-number seed for the elemental starts{p_end}
{synopt:{opt exact}}enumerate all C({it:T},{it:T}-{it:h}) subsets (small samples only; cap 3 million subsets){p_end}

{syntab:Inference}
{synopt:{opt sigma(df|h|n)}}divisor of the residual sum of squares for sigma{c 94}2: {it:h}-{it:K} (default), {it:h} (eq. 2.4), or {it:T}-{it:K}{p_end}
{synopt:{opt slts}}report SLTS standard errors (oracle variance divided by varsigma{c 94}4) and post them in {cmd:e(V)}{p_end}
{synopt:{opt kappa0(numlist)}}hypothesised values of the cointegrating coefficients; prints z-tests{p_end}
{synopt:{opt wetest}}weak-exogeneity regressions for every variable in {it:zvars}{p_end}
{synopt:{opt level(#)}}confidence level for the single-column table; default {cmd:level(95)}{p_end}
{synopt:{opt notests}}suppress the tests for no cointegration{p_end}

{syntab:Reporting}
{synopt:{opt nools}}suppress the full-sample OLS comparison column{p_end}
{synopt:{opt noheader}}suppress the header{p_end}
{synopt:{opt gen:erate(newvar)}}save the good/outlier indicator (1 = retained, 0 = outlier){p_end}
{synopt:{opt gr:aph}}draw the four-panel mis-specification graphics (paper's Figures 3-4){p_end}
{synopt:{opt name(stub)}}name stub for the graphs; default {cmd:ltscoint}{p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{synopthdr:hsearch_options}
{synoptline}
{synopt:{opt lags(#)} {opt trend}}as above{p_end}
{synopt:{opt hmin(#)} {opt hmax(#)}}range of {it:h}; defaults as above{p_end}
{synopt:{opt nsamp(#)} {opt csteps(#)} {opt nkeep(#)} {opt seed(#)} {opt exact}}algorithm, as above{p_end}
{synopt:{opt gr:aph}}four-panel profile plot: {it:T_h}, {it:IC_h}, alpha-hat({it:h}), kappa-hat({it:h}){p_end}
{synopt:{opt nooutliers}}do not list the identified outliers for each {it:h}{p_end}
{synoptline}

{pstd}The data must be {helpb tsset} as a single time series. Time-series operators are allowed in {it:depvar} and {it:zvars}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:ltscoint} estimates the autoregressive distributed lag (ADL) regression in equilibrium-correction form

{p 12 12 2}
D.y_t = omega' D.z_t + alpha (y_t-1 - kappa' z_t-1 - nu) + sum_j gamma_j' D.x_t-j + sigma eps_t,
{p_end}

{pstd}
where x_t = (y_t, z_t')', by {bf:Least Trimmed Squares (LTS)}: it finds the {it:h}-subsample with the smallest
residual sum of squares and applies OLS to it (Rousseeuw 1984). The remaining {it:T}-{it:h} observations are
declared outliers. Berenguer-Rico and Nielsen (2026) show that when the good errors are normal, the outlier errors
are more extreme than the good ones, and the proportion of outliers vanishes, the LTS estimator has the
{bf:oracle property}: it has the same asymptotic distribution as OLS applied infeasibly to the true good
observations. Hence the usual cointegration inference transfers to the LTS-selected sample:
standard-normal inference on the cointegrating vector under weak exogeneity (Johansen 1992), the
Harbo-Johansen-Nielsen-Rahbek (1998) likelihood-ratio test and the Ericsson-MacKinnon (2002) t-test of no
cointegration, and normal inference on lag length.

{pstd}
The command reports, side by side, full-sample OLS and LTS: the coefficient table with significance stars;
sigma, log-likelihood, {it:T} and {it:h}; PcGive-style mis-specification tests on the retained observations
(F_ar(1-2), F_arch(1), Doornik-Hansen chi{c 94}2_normal(2), F_hetero, and the cumulant statistic {it:T_h});
the long-run coefficients kappa = -psi/alpha and nu with delta-method standard errors; the LR and ECM-t tests
of no cointegration with asymptotic critical values and (for LR) Gamma-approximation p-values; optional
weak-exogeneity regressions; and the list of identified outliers. {cmd:ltscoint hsearch} reproduces the paper's
Table 7, profiling the cumulant normality statistic {it:T_h} over {it:h}. The {opt graph} option draws the
paper's mis-specification graphics (actual/fitted with outliers marked, scaled residuals with the
(2 log {it:h}){c 94}1/2 bound, residual correlogram, QQ plot).

{pstd}
LTS is computed with the FAST-LTS concentration-step algorithm of Rousseeuw and Van Driessen (2006), or by exact
enumeration in small samples ({opt exact}). The estimates coincide with the raw (unreweighted) LTS fit of R's
{cmd:robustbase::ltsReg}, the implementation used by the authors, and with Ben Jann's {cmd:robreg lts}. See
{helpb ltscoint_methods:help ltscoint methods} for the step-by-step map from code to equations.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt lags(#)} sets {it:k}, the lag length of the ADL in levels. The regressor vector of eq. (2.2) is
(D.z_t', y_t-1, z_t-1', D.x_t-1', ..., D.x_t-k+1', 1)', so {cmd:lags(1)} has no lagged differences and
{cmd:lags(2)} (the default and the paper's empirical choice) has one.

{phang}
{opt trend} adds the restricted linear trend of eq. (2.3): the trend enters the equilibrium-correction term,
-alpha nu_l t, and the constant mu_c is unrestricted. Without {opt trend} the constant is restricted,
-alpha nu_c, and vanishes under the null of no cointegration.

{dlgtab:Number of good observations}

{phang}
{opt h(#)} and {opt nout(#)} fix the number of good observations or of outliers. The theory (Theorem 2,
eq. 4.8) requires {it:h} > 2{it:T}/3 for boundedness; the command errors otherwise unless {opt force} is
given. The asymptotic expansion (Theorem 3, eq. 4.12) needs {it:T}-{it:h} = o(sqrt({it:T})/log {it:T});
a note is printed when {it:T}-{it:h} > sqrt({it:T}), where the paper's simulations show inference can
deteriorate, especially with concentrated outliers and slow adjustment.

{phang}
{opt hsel(cumulant|ic)}, {opt hmin(#)}, {opt hmax(#)}. When {it:h} is not given the command profiles LTS
over {it:h} = {it:hmin},...,{it:hmax} and selects the minimiser of the cumulant normality statistic
{it:T_h} = {it:h} k3{c 94}2/6 + {it:h} k4{c 94}2/24 computed on the {it:h} retained residuals
(Berenguer-Rico, Johansen and Nielsen 2023, eq. 6.2; used in the paper's Table 7), or of the information
criterion {it:IC_h} = log(sigma_h{c 94}2) + 2 log log({it:T}) ({it:T}-{it:h})/{it:T} (their eq. 6.1).
The profile is stored in {cmd:e(hprofile)}. Both methods have incomplete theory; see Remarks.

{dlgtab:Algorithm}

{phang}
{opt nsamp(#)}, {opt csteps(#)}, {opt nkeep(#)}, {opt seed(#)} control FAST-LTS: {it:nsamp} random
elemental subsets of size {it:K} are drawn, each is refined by {it:csteps} concentration steps, the
{it:nkeep} best are iterated to convergence, and the smallest residual sum of squares wins. The full-sample
OLS fit is always included as a start. Results are reproducible given {opt seed()}.

{phang}
{opt exact} enumerates every subset of {it:T}-{it:h} outliers. It is the global optimum by construction and is
the reference for checking FAST-LTS in small samples; it refuses more than 3 million subsets.

{dlgtab:Inference}

{phang}
{opt sigma(df|h|n)}. The paper's eq. (2.4) divides by {it:h}; the empirical section (7.2) reports the
OLS-with-impulse-dummies regression whose divisor is {it:h}-{it:K}; the supplement's simulations use
{it:T}-{it:K}. The default {cmd:sigma(df)} = {it:h}-{it:K} matches the reported empirical results and
{helpb regress}. The choice rescales {cmd:e(V)} and the t-statistics.

{phang}
{opt slts} reports the "standard LTS" variance customary in robust statistics, obtained under an
uncontaminated normal model: the oracle variance divided by varsigma{c 94}4 with
varsigma{c 94}2 = {lambda - 2 c phi(c)}/lambda, c = Phi{c 94}-1((1+lambda)/2), lambda = {it:h}/{it:T}
(Berenguer-Rico and Nielsen 2026, Econometric Theory, eq. 2.4). It is always stored in {cmd:e(V_slts)};
with {opt slts} it is also posted as {cmd:e(V)}. The paper argues that under its LTS model no such correction
is needed.

{phang}
{opt kappa0(numlist)} gives hypothesised values of kappa, one per variable in {it:zvars}, and prints the
z-statistics (kappa-hat - kappa0)/se; with {opt wetest} the same values define the equilibrium-correction
term of the weak-exogeneity regressions. Standard-normal inference on kappa is valid under weak exogeneity
(Johansen 1992).

{phang}
{opt wetest} regresses D.z_j on (y - kappa'z)_t-1, the lagged differences, the deterministic terms and the
LTS impulse dummies; a significant coefficient rejects weak exogeneity of z_j.

{dlgtab:Reporting}

{phang}
{opt generate(newvar)} stores the retained/outlier indicator. {opt graph} and {opt name()} draw and name the
graphics. {cmd:ltscoint graph} redraws them after estimation from {cmd:e()}.


{marker output}{...}
{title:Interpreting the output}

{phang2}{bf:Header.} Sample, {it:T}, {it:h}, {it:T}-{it:h}, model form, algorithm, and the breakdown bound
2{it:T}/3.{p_end}

{phang2}{bf:Coefficient table.} Left block: full-sample OLS. Right block: LTS, i.e. OLS on the {it:h}
retained observations, with oracle standard errors (Theorem 3), t-statistics and stars. Rows are grouped
as contemporaneous D.z, levels (y_t-1, z_t-1: the equilibrium-correction part), lagged differences, and
deterministic terms. alpha is the coefficient on L.{it:depvar}; psi_j the coefficient on L.z_j.{p_end}

{phang2}{bf:sigma, log-likelihood, T (h).} The LTS log-likelihood is that of the impulse-dummy regression on
all {it:T} observations, as in the paper's (7.2), so that LR statistics are comparable across models.{p_end}

{phang2}{bf:Mis-specification tests.} F_ar(1-2): Godfrey (1978) F-form LM test for residual autocorrelation
of orders 1-2; F_arch(1): Engle (1982); chi{c 94}2_normal(2): Doornik and Hansen (2008); F_hetero: White
(1980) without cross-products; {it:T_h}: the cumulant statistic on the retained residuals. All are computed
on the retained observations (equivalently, on the dummy-augmented regression). Small p-values reject.{p_end}

{phang2}{bf:Long-run relation.} kappa_j = -psi_j/alpha and nu = -mu/alpha (constant case) or
nu = -coef(t)/alpha (trend case) with delta-method standard errors; z against N(0,1). With {opt kappa0()}
a test line follows.{p_end}

{phang2}{bf:Tests for no cointegration.} LR = {it:T} log(RSS_r/RSS_u) where the restricted model drops
y_t-1, z_t-1 and the restricted deterministic term; critical values and Gamma-approximation p-values are those
of Doornik (2003, Tables 12-13), which replace Harbo et al. (1998) Tables 3 and 2 (case H_c and H_l,
p1-r = 1, p2 = number of weakly exogenous variables, up to 6). ECM t = alpha-hat/se; finite-sample 1/5/10%
critical values from the Ericsson-MacKinnon (2002) response surfaces with adjusted sample size {it:h}-{it:K}.
Reject no cointegration when LR exceeds its critical value or t is below (more negative than) its critical
value.{p_end}

{phang2}{bf:Outliers.} The {it:T}-{it:h} time indices excluded by LTS, in time order.{p_end}


{marker remarks}{...}
{title:Remarks and practical guidance}

{phang}
{bf:Choosing h.} The theory takes {it:h} as known. In practice run {cmd:ltscoint hsearch} and look for a
stable minimum of {it:T_h} with a nested sequence of outliers as {it:T}-{it:h} grows (paper's Table 7). A
value of {it:h} = {it:T} with a huge {it:T_h} says the full sample is far from normal. Keep {it:T}-{it:h}
of the order sqrt({it:T})/2 unless the data clearly demand more; the paper's simulations show good size
control for {it:T}-{it:h} = sqrt({it:T})/2 and deterioration for 2 sqrt({it:T}) with concentrated outliers.
The {it:IC_h} criterion's 2 log log({it:T}) penalty grows very slowly and often selects the search boundary
in small samples; it is reported for completeness. Neither method has a complete asymptotic theory when
outliers are present.

{phang}
{bf:Outliers that cumulate into breaks.} Consecutive same-signed outliers in z_t act as a level shift. The
paper's Table 5 shows that under no cointegration this invalidates the standard LR limit (a break theory such
as Kurita and Nielsen 2019 is needed) even though LTS still matches the infeasible OLS. Look at panel (b) of
the graphics: a run of outliers of one sign is the warning.

{phang}
{bf:Weak exogeneity.} All ADL inference presumes it. Use {opt wetest}; if rejected, a systems (VAR) method
is required and the paper suggests an MCD-type systems LTS as future work.

{phang}
{bf:What the command does not do.} It does not provide inference that accounts for the estimation of {it:h};
it does not implement the truncation-corrected normality tests of Berenguer-Rico and Nielsen (2026,
Econometrics and Statistics), which are the formally valid normality diagnostics after outlier removal;
it does not model breaks. These are documented limitations, not approximations.

{phang}
{bf:Reproducing the paper.} With the UK data shipped ({cmd:ltscoint_ukcons.dta}, ONS CRXX/CRYJ,
30 June 2026 release) and {cmd:nout(5) trend lags(2)}, the command identifies the paper's outliers
2009, 2020, 2021, 2022, 2023 and reproduces sigma = 0.0123, kappa = 1.05 (0.23), the LR statistic near 6
and the {it:T_h} value 0.67 at {it:h} = 62. Coefficient values differ in the third decimal because the
paper used the Q3-2024 ONS vintage.


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. use ltscoint_ukcons}{p_end}
{phang2}{cmd:. tsset year}{p_end}

{pstd}Data plot (paper's Figure 2){p_end}
{phang2}{cmd:. ltscoint dataplot c y if year<=2023, kappa(1)}{p_end}

{pstd}Determine h (paper's Table 7){p_end}
{phang2}{cmd:. ltscoint hsearch c y if year<=2023, trend lags(2) seed(1) graph}{p_end}

{pstd}LTS with 5 outliers, homogeneity test kappa = 1, weak exogeneity, graphics (paper's eqs 7.1-7.3, Figures 3-4){p_end}
{phang2}{cmd:. ltscoint c y if year<=2023, nout(5) trend lags(2) seed(1) kappa0(1) wetest graph generate(good)}{p_end}

{pstd}Data-driven h, SLTS standard errors, exact enumeration on a short sample{p_end}
{phang2}{cmd:. ltscoint c y if year<=2023, trend lags(2)}{p_end}
{phang2}{cmd:. ltscoint c y if year<=2023, nout(5) trend lags(2) slts}{p_end}
{phang2}{cmd:. ltscoint c y if year>=1990 & year<=2021, nout(2) trend lags(2) exact}{p_end}

{pstd}Monte Carlo on the paper's DGP: see {cmd:ltscoint_example.do} (net get ltscoint).{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:ltscoint} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of regression observations {it:T}{p_end}
{synopt:{cmd:e(h)}}number of good observations{p_end}
{synopt:{cmd:e(nout)}}number of outliers {it:T}-{it:h}{p_end}
{synopt:{cmd:e(lambda)}}{it:h}/{it:T}{p_end}
{synopt:{cmd:e(K)}}number of regressors including the constant{p_end}
{synopt:{cmd:e(lags)}}lag length {it:k}{p_end}
{synopt:{cmd:e(rss)}}residual sum of squares on the retained observations{p_end}
{synopt:{cmd:e(sigma)}, {cmd:e(sigma2)}}LTS scale (see {opt sigma()}){p_end}
{synopt:{cmd:e(ll)}}log-likelihood of the dummy-augmented regression{p_end}
{synopt:{cmd:e(sigma_ols)}, {cmd:e(ll_ols)}, {cmd:e(rss_ols)}}full-sample OLS counterparts{p_end}
{synopt:{cmd:e(alpha)}, {cmd:e(se_alpha)}}adjustment coefficient and its standard error{p_end}
{synopt:{cmd:e(varsigma2)}}SLTS consistency factor varsigma{c 94}2{p_end}
{synopt:{cmd:e(T_h)}}cumulant statistic on the retained residuals{p_end}
{synopt:{cmd:e(LR)}, {cmd:e(LR_p)}}LR test of no cointegration and Gamma-approximation p-value{p_end}
{synopt:{cmd:e(LR_ols)}, {cmd:e(LR_p_ols)}}full-sample OLS counterparts{p_end}
{synopt:{cmd:e(t_alpha)}, {cmd:e(t_alpha_ols)}}ECM t statistics{p_end}
{synopt:{cmd:e(tmin)}, {cmd:e(tmax)}}first and last time index of the sample{p_end}
{synopt:{cmd:e(searched)}, {cmd:e(hmin)}, {cmd:e(hmax)}}whether and over what range {it:h} was searched{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ltscoint}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(zvars)}, {cmd:e(xnames)}}variables{p_end}
{synopt:{cmd:e(outyears)}}time indices of the outliers{p_end}
{synopt:{cmd:e(timevar)}, {cmd:e(trend)}, {cmd:e(sigma_opt)}, {cmd:e(vce)}, {cmd:e(hsel)}, {cmd:e(algorithm)}}settings{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}LTS coefficients and (oracle or SLTS) variance{p_end}
{synopt:{cmd:e(V_slts)}}SLTS variance{p_end}
{synopt:{cmd:e(b_ols)}, {cmd:e(V_ols)}}full-sample OLS{p_end}
{synopt:{cmd:e(kappa)}, {cmd:e(kappa_ols)}}long-run coefficients: kappa, se, z, p (last row: nu){p_end}
{synopt:{cmd:e(misspec)}, {cmd:e(misspec_ols)}}stat, df1, df2, p for F_ar12, F_arch1, chi2_norm, F_hetero, T_h{p_end}
{synopt:{cmd:e(LR_cv)}}50, 80, 90, 95, 97.5, 99% asymptotic quantiles of the LR test{p_end}
{synopt:{cmd:e(t_alpha_cv)}}1, 5, 10% critical values of the ECM t test{p_end}
{synopt:{cmd:e(outliers)}}time indices of the outliers{p_end}
{synopt:{cmd:e(hprofile)}}h, T-h, T_h, IC_h, rss, sigma, alpha for each h (when searched){p_end}
{synopt:{cmd:e(wetest)}}coef, se, t, p of the weak-exogeneity regressions{p_end}

{pstd}{cmd:ltscoint hsearch} stores {cmd:r(hprofile)} (h, nout, T_h, IC_h, rss, sigma, alpha, psi1),
{cmd:r(h_T)}, {cmd:r(h_IC)}, {cmd:r(N)}, {cmd:r(hmin)}, {cmd:r(hmax)}.


{marker references}{...}
{title:References}

{phang}Berenguer-Rico, V. and B. Nielsen (2026). Least Trimmed Squares: Cointegration and outliers.
{it:Oxford Bulletin of Economics and Statistics} 88, 690-711. {browse "https://doi.org/10.1111/obes.70077"}{p_end}
{phang}Berenguer-Rico, V. and B. Nielsen (2026). Least Trimmed Squares: Nuisance parameter free asymptotics.
{it:Econometric Theory} 42, 336-374. {browse "https://doi.org/10.1017/S0266466624000343"}{p_end}
{phang}Berenguer-Rico, V., S. Johansen and B. Nielsen (2023). A model where the Least Trimmed Squares estimator is
maximum likelihood. {it:Journal of the Royal Statistical Society Series B} 85, 886-912.
{browse "https://doi.org/10.1093/jrsssb/qkad028"}{p_end}
{phang}Berenguer-Rico, V. and B. Nielsen (2026). Normality testing after outlier removal.
{it:Econometrics and Statistics} 38, 74-97. {browse "https://doi.org/10.1016/j.ecosta.2023.06.001"}{p_end}
{phang}Doornik, J. A. (1998). Approximations to the asymptotic distributions of cointegration tests.
{it:Journal of Economic Surveys} 12, 573-593. {browse "https://doi.org/10.1111/1467-6419.00068"}{p_end}
{phang}Doornik, J. A. (2003). Asymptotic tables for cointegration tests based on the Gamma-distribution
approximation. Nuffield College, Oxford.{p_end}
{phang}Doornik, J. A. and H. Hansen (2008). An omnibus test for univariate and multivariate normality.
{it:Oxford Bulletin of Economics and Statistics} 70, 927-939. {browse "https://doi.org/10.1111/j.1468-0084.2008.00537.x"}{p_end}
{phang}Ericsson, N. R. and J. G. MacKinnon (2002). Distributions of error correction tests for cointegration.
{it:Econometrics Journal} 5, 285-318. {browse "https://doi.org/10.1111/1368-423X.00085"}{p_end}
{phang}Harbo, I., S. Johansen, B. Nielsen and A. Rahbek (1998). Asymptotic inference on cointegrating rank in
partial systems. {it:Journal of Business & Economic Statistics} 16, 388-399.
{browse "https://doi.org/10.1080/07350015.1998.10524779"}{p_end}
{phang}Johansen, S. (1992). Cointegration in partial systems and the efficiency of single-equation analysis.
{it:Journal of Econometrics} 52, 389-402. {browse "https://doi.org/10.1016/0304-4076(92)90019-N"}{p_end}
{phang}Kurita, T. and B. Nielsen (2019). Partial cointegrated vector autoregressive models with structural
breaks in deterministic terms. {it:Econometrics} 7, 42. {browse "https://doi.org/10.3390/econometrics7040042"}{p_end}
{phang}Rousseeuw, P. J. (1984). Least median of squares regression. {it:Journal of the American Statistical
Association} 79, 871-880. {browse "https://doi.org/10.1080/01621459.1984.10477105"}{p_end}
{phang}Rousseeuw, P. J. and K. Van Driessen (2006). Computing LTS regression for large data sets.
{it:Data Mining and Knowledge Discovery} 12, 29-45. {browse "https://doi.org/10.1007/s10618-005-0024-4"}{p_end}


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}{p_end}

{pstd}Please cite the paper of Berenguer-Rico and Nielsen (2026) when using this command.{p_end}
