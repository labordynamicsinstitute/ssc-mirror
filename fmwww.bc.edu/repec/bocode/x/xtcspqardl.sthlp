{smcl}
{* *! version 1.1.0  29aug2026}{...}
{vieweralsosee "xtcspqardl methods" "help xtcspqardl_methods"}{...}
{vieweralsosee "xtcspqardl postestimation" "help xtcspqardl_postestimation"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "xtqsh" "help xtqsh"}{...}
{vieweralsosee "xthst" "help xthst"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtcspqardl##syntax"}{...}
{viewerjumpto "Description" "xtcspqardl##description"}{...}
{viewerjumpto "Estimators" "xtcspqardl##estimators"}{...}
{viewerjumpto "Options" "xtcspqardl##options"}{...}
{viewerjumpto "Output" "xtcspqardl##output"}{...}
{viewerjumpto "Remarks" "xtcspqardl##remarks"}{...}
{viewerjumpto "Examples" "xtcspqardl##examples"}{...}
{viewerjumpto "Stored results" "xtcspqardl##results"}{...}
{viewerjumpto "References" "xtcspqardl##refs"}{...}
{viewerjumpto "Author" "xtcspqardl##author"}{...}

{title:Title}

{phang}
{bf:xtcspqardl} {hline 2} Cross-sectionally augmented panel quantile ARDL,
quantile CCE mean group and quantile CCE pooled estimation


{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:xtcspqardl}
{depvar} {indepvars}
{ifin}{cmd:,}
{opth tau(numlist)}
[{it:estimator}
{it:options}]

{pstd}
The data must be {helpb xtset} (or {helpb tsset}) as a panel.

{synoptset 26 tabbed}{...}
{synopthdr:estimator}
{synoptline}
{synopt :{opt qccemg}}quantile CCE mean group of Harding, Lamarche and
Pesaran (2018); {it:depvar} and {it:indepvars} are levels{p_end}
{synopt :{opt qccepmg}}the same unit-level estimates combined by the
inverse-variance (CCEP) weighting of Pesaran (2006){p_end}
{synopt :{opt ecm}}two-step CS-PQARDL of Ul-Durar et al. (2025): a pooled
level regression, then a differenced regression on the lagged residual;
{it:depvar} and {it:indepvars} are levels{p_end}
{synopt :{it:(default)}}one-step CS-PQARDL conditional ECM; {it:depvar} and
{it:indepvars} are the differences and {opt lr()} carries the levels{p_end}
{synoptline}

{synoptset 26 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab :Model}
{synopt :{opth tau(numlist)}}quantiles to estimate; required{p_end}
{synopt :{opth lr(varlist)}}level (long-run) block for the one-step
CS-PQARDL, lagged dependent level first{p_end}
{synopt :{opth csa(varlist)}}variables whose cross-sectional averages
augment the equation; see {help xtcspqardl##csa:below} for the defaults{p_end}
{synopt :{opt cr_lags(#)}}number of lags of the cross-sectional averages,
pT; default is {cmd:floor(T^(1/3))}{p_end}
{synopt :{opt p(#)}}extra lags of the dependent variable in the one-step
form; default {cmd:p(1)}{p_end}
{synopt :{opt q(numlist)}}lags of each short-run regressor, one number or
one per regressor; default {cmd:q(1)}{p_end}

{syntab :Inference}
{synopt :{opt unitvce(iid|robust)}}variance estimator inside each unit-level
{helpb qreg}; default {cmd:iid}{p_end}
{synopt :{opt reps(#)}}bootstrap replications for the step-1 pooled
regression under {opt ecm}; default {cmd:100}, {cmd:reps(0)} uses the
asymptotic variance{p_end}
{synopt :{opt seed(#)}}random-number seed for that bootstrap{p_end}
{synopt :{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt :{opt mint(#)}}minimum usable time-series length per unit; default
is the number of regressors plus five{p_end}
{synopt :{opt nocd}}skip the Pesaran CD diagnostics (faster on large N){p_end}

{syntab :Reporting}
{synopt :{opt srtable}}display the short-run dynamics table{p_end}
{synopt :{opt showcsa}}display the cross-sectional-average coefficients{p_end}
{synopt :{opt unittable}}display the unit-level persistence / adjustment
coefficients{p_end}
{synopt :{opt full}}run the inter-quantile analysis after estimation{p_end}
{synopt :{opt graph}}draw the publication figures{p_end}
{synopt :{opt graphopts(str)}}options passed to {helpb xtcspqardl_graph}{p_end}
{synopt :{opt scheme(str)}}graph scheme{p_end}
{synopt :{opt notable}}suppress all tables{p_end}
{synopt :{opt showindividual}}report each unit as it is estimated{p_end}
{synoptline}


{marker description}{title:Description}

{pstd}
{cmd:xtcspqardl} estimates dynamic panel quantile regressions for
heterogeneous panels in which the units share unobserved common factors.
Each cross-sectional unit is fitted separately by quantile regression
after the equation has been augmented with cross-sectional averages of
the dependent variable and the regressors, following the common
correlated effects (CCE) idea of Pesaran (2006); the unit-level estimates
are then combined.

{pstd}
The augmentation makes the estimator robust to cross-sectional
dependence, the unit-by-unit fitting makes it robust to slope
heterogeneity, and the quantile objective makes it robust to outliers and
lets the effect of a regressor differ across the conditional
distribution of the response.


{marker estimators}{title:Estimators}

{dlgtab:qccemg}

{pstd}
The quantile CCE mean group (QMG) estimator of Harding, Lamarche and
Pesaran (2018).  For each unit {it:i} and quantile {it:tau},

{p 12 12 2}
Q(y_it | .) = a_i + lambda_i y_i,t-1 + x_it'beta_i
+ sum_{l=0..pT} zbar_t-l' delta_il,

{pstd}
with zbar_t = (ybar_t, xbar_t')'.  The reported coefficients are the
simple averages over units, and the variance is the nonparametric
mean-group one.  Long-run effects are theta = beta/(1-lambda), the
plug-in form the paper defines, with a delta-method standard error.

{dlgtab:qccepmg}

{pstd}
The same unit-level quantile estimates, combined with weights equal to
the inverse of each unit's estimated variance matrix, which is the
quantile analogue of the CCE pooled estimator of Pesaran (2006).  The
reported variance is the heterogeneity-robust sandwich; the
homogeneity-only variance is also stored.  Pooling is more efficient
when the slopes are close to homogeneous, so read it together with the
GJMO slope-homogeneity statistic in the diagnostics block.

{dlgtab:default (one-step CS-PQARDL)}

{pstd}
A conditional error-correction model estimated in one step.  Put the
differences in the varlist and the levels in {opt lr()}:

{p 12 12 2}
Dy_it = phi_i y_i,t-1 + xi_i'x_i,t-1 + short-run terms
+ cross-sectional averages.

{pstd}
Long-run coefficients are theta = -xi/phi, again with a delta-method
standard error that includes the covariance between numerator and
denominator.

{dlgtab:ecm (two-step CS-PQARDL)}

{pstd}
The procedure of Ul-Durar et al. (2025).  Step 1 fits their equation (2),
a pooled panel quantile regression of the level dependent variable on the
level regressors and the cross-sectional averages, and keeps the
residual.  Step 2 fits their equation (3) unit by unit, regressing the
differences on the differences and the lagged step-1 residual, and
averages over units.  Put the levels in the varlist; {opt lr()} is not
used.

{pstd}
Because the two steps are separate regressions, the joint covariance
posted in {cmd:e(V)} treats the long-run and short-run blocks as
independent.  Do not use {helpb test} across the two blocks in this mode;
use the one-step form if you need that.


{marker options}{title:Options}

{marker csa}{...}
{phang}
{opth csa(varlist)} names the variables whose cross-sectional averages
enter the equation.  The defaults follow the source papers: for
{opt qccemg}, {opt qccepmg} and {opt ecm} it is the varlist itself, which
is in levels; for the one-step CS-PQARDL it is the {bf:base variables of}
{opt lr()}, i.e. the levels, because the common factors live in the level
relation.  Time-series operators in {opt csa()} are stripped, so
{cmd:csa(L.y x1)} and {cmd:csa(y x1)} give the same averaging set; the
lag structure is controlled by {opt cr_lags()}.

{phang}
{opt cr_lags(#)} sets pT.  Harding, Lamarche and Pesaran require
pT^3/T {c 174} 0, and use pT = 4 in their application; the default here is
floor(T^(1/3)), the Chudik-Pesaran (2015) rate.  More lags absorb more
persistent factor dynamics but cost degrees of freedom in every unit.

{phang}
{opt unitvce(iid|robust)} chooses the variance estimator inside each
unit-level {helpb qreg}.  It does not change the reported mean-group
standard errors, which are nonparametric, but it does change the pooling
weights under {opt qccepmg} and the GJMO homogeneity statistic.  Setting
{cmd:robust} makes it the Powell (1986) kernel sandwich that Galvao et al.
use.

{phang}
{opt level(#)} is honoured everywhere: the coefficient tables, the
inter-quantile analysis and the confidence bands in the figures.


{marker output}{title:Interpreting the output}

{pstd}
{bf:Coefficient tables.}  One block per quantile.  The standard errors are
the nonparametric mean-group ones, sqrt(Vv/N) with
Vv = (1/(N-1)) sum_i (b_i - b)(b_i - b)', which is the estimator Harding,
Lamarche and Pesaran give in their section 2.3 for the heterogeneous case.
Significance stars are ***/**/* at 1/5/10 per cent.

{pstd}
{bf:Half-life} solves lambda^h = 1/2 exactly, h = ln(0.5)/ln(lambda), and
carries a delta-method standard error.  It is reported only when the
persistence parameter lies strictly between zero and one.

{pstd}
{bf:ECT} is the speed of adjustment.  Convergence to the long-run
relation requires it to lie in (-2, 0); a value outside that range is
flagged with {cmd:!}.

{pstd}
{bf:Pseudo R1} is the Koenker-Machado (1999) goodness of fit for the
quantile objective, pooled over the units used.

{pstd}
{bf:Wald} tests that the slope coefficients at that quantile are jointly
zero.

{pstd}
{bf:CD} is the Pesaran (2004) cross-sectional-dependence statistic,
reported on the residuals without and with the cross-sectional averages.
The informative quantity is the {it:fall} in |CD|: it shows that the
augmentation absorbed the common factors.  With the averages included the
statistic is biased slightly negative by construction, because the
augmented residuals sum to approximately zero across units at each date.

{pstd}
{bf:GJMO D} is the standardized Swamy slope-homogeneity statistic of
Galvao, Juhl, Montes-Rojas and Olmo (2017), the quantile-regression
counterpart of the familiar mean-regression test:

{p 8 8 2}
S(tau) = sum_i (b_i - b_MD)' Var(b_i)^-1 (b_i - b_MD),{break}
D(tau) = sqrt(n) [ S/n - k ] / sqrt(2k)  ~  N(0,1),

{pstd}
with b_MD the minimum-distance (inverse-variance weighted) estimator.
The test is one sided: the alternative is over-dispersion of the b_i, so
large positive values reject homogeneity and favour the mean group over
pooling.  The chi-squared form, S ~ chi2((n-1)k) for large T and fixed n,
is printed under the table and stored in {cmd:e(diagnostics)}.

{pstd}
Note that this is {it:not} the Pesaran-Yamagata (2008) statistic: their
bias adjustment is derived from the finite-T moments of the least-squares
Swamy statistic and does not carry over to the quantile case, so it is
not applied.  Setting {opt unitvce(robust)} makes Var(b_i) the Powell
(1986) kernel sandwich used by Galvao et al.  For the test on its own,
with that variance estimator and a HAC option for serially dependent
data, use {helpb xtqsh} (Roudane, SSC).

{pstd}
The distinction matters when comparing packages: {helpb xthst}
(Bersvendsen and Ditzen, SSC) reports the Pesaran-Yamagata Delta and
adjusted Delta for the {bf:conditional mean}, whereas {helpb xtqsh} and
the statistic reported here are their {bf:quantile} counterpart.  The two
answer different questions and their numbers are not comparable.


{marker remarks}{title:Remarks and practical guidance}

{phang}
{bf:Sample-size regime.}  The asymptotics need both N and T large, and
Theorem 4 of Harding, Lamarche and Pesaran requires T to grow faster than
N.  With a short T the persistence parameter is biased towards zero (the
usual dynamic-quantile bias), and because the long-run effect divides by
(1-lambda) that bias is amplified there.  Treat long-run estimates from
panels with T below roughly 50 as indicative.

{phang}
{bf:Rank condition.}  The number of cross-sectional averages must be at
least as large as the number of unobserved factors; with px regressors and
one dependent variable the augmentation spans px+1 directions per lag.

{phang}
{bf:Units that are dropped.}  A unit is skipped at a quantile when it is
too short, when the quantile regression fails, or when a {it:parameter of
interest} was dropped for collinearity.  That last check matters:
{helpb qreg} keeps a collinear regressor in {cmd:e(b)} with a coefficient
of exactly zero, and averaging that zero into the mean group would bias
the estimate towards zero.  The header reports the counts.  Cross-sectional
averages that are dropped for collinearity do not disqualify a unit, but
they do attenuate the reported CSA averages, and the header says so.

{phang}
{bf:Reading the homogeneity test.}  The GJMO statistic is derived for
T {c 174} infinity, and in this command it is computed on unit-level
regressions that also carry the lagged dependent variable and (1+pT)
times (1+px) cross-sectional averages.  With a short T that leaves few
residual degrees of freedom per unit, the unit variance matrices are
estimated too small and the statistic is biased upwards, so the test
over-rejects homogeneity.  On the shipped homogeneous-slope design with
N = 30 the standardized statistic falls from 5.05 at T = 60, to 1.84 at
T = 150, to 0.92 at T = 400, against a null mean of zero.  Read a
rejection at short T with that in mind, lower {opt cr_lags()} to free
degrees of freedom, and when the homogeneity question is itself the
object of interest use the standalone {helpb xtqsh}, whose static
specification spends far fewer parameters per unit.

{phang}
{bf:Choosing between the estimators.}  Use {opt qccemg} when the interest
is in the average distributional effect and the slopes are heterogeneous.
Use {opt qccepmg} when the GJMO statistic does not reject homogeneity.  Use the one-step CS-PQARDL when the variables are I(1) and
you want a single well-specified equation; use {opt ecm} when you want to
reproduce the two-step procedure of Ul-Durar et al. exactly.

{phang}
{bf:Speed.}  The command runs one quantile regression per unit and
quantile, and a second one for the CD diagnostic.  On large panels use
{opt nocd}, and under {opt ecm} lower {opt reps()}.


{marker examples}{title:Examples}

{pstd}Set up a panel{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Quantile CCE mean group at three quantiles{p_end}
{phang2}{cmd:. xtcspqardl invest mvalue kstock, tau(0.25 0.5 0.75) qccemg}{p_end}

{pstd}The pooled counterpart{p_end}
{phang2}{cmd:. xtcspqardl invest mvalue kstock, tau(0.5) qccepmg}{p_end}

{pstd}One-step CS-PQARDL: differences in the varlist, levels in lr(){p_end}
{phang2}{cmd:. gen dinv = D.invest}{p_end}
{phang2}{cmd:. gen dmv  = D.mvalue}{p_end}
{phang2}{cmd:. gen dks  = D.kstock}{p_end}
{phang2}{cmd:. xtcspqardl dinv dmv dks, lr(L.invest L.mvalue L.kstock) tau(0.5) srtable}{p_end}

{pstd}Two-step CS-PQARDL as in Ul-Durar et al. (2025){p_end}
{phang2}{cmd:. xtcspqardl invest mvalue kstock, tau(0.25 0.5 0.75) ecm reps(200) seed(1) unittable}{p_end}

{pstd}Everything: tables, inter-quantile analysis and figures{p_end}
{phang2}{cmd:. xtcspqardl invest mvalue kstock, tau(0.1 0.25 0.5 0.75 0.9) qccemg full graph}{p_end}

{pstd}Postestimation{p_end}
{phang2}{cmd:. test [q050]mvalue = [q025]mvalue}{p_end}
{phang2}{cmd:. lincom [lr075]mvalue - [lr025]mvalue}{p_end}


{marker results}{title:Stored results}

{pstd}{cmd:xtcspqardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of units in the sample{p_end}
{synopt:{cmd:e(N_used)}}units entering the mean group{p_end}
{synopt:{cmd:e(n_short)}}units dropped for a short time series{p_end}
{synopt:{cmd:e(n_failed)}}unit-quantile fits that failed{p_end}
{synopt:{cmd:e(n_omitted)}}unit-quantiles dropped for collinearity in a
parameter of interest{p_end}
{synopt:{cmd:e(k)}}number of regressors{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(cr_lags)}}pT{p_end}
{synopt:{cmd:e(avg_T)}}average time-series length{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(pooled)}}1 if the inverse-variance pooling was used{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtcspqardl}{p_end}
{synopt:{cmd:e(estimator)}}{cmd:qccemg}, {cmd:qccepmg}, {cmd:cspqardl} or
{cmd:cspqardl_ecm}{p_end}
{synopt:{cmd:e(tau)}}the quantiles{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}regressors{p_end}
{synopt:{cmd:e(lrvars)}}level block{p_end}
{synopt:{cmd:e(csabase)}}variables that were averaged{p_end}
{synopt:{cmd:e(csa_labels)}}labels of the CSA terms{p_end}
{synopt:{cmd:e(coefnames)}}names in the short-run block{p_end}
{synopt:{cmd:e(lrnames)}}names in the long-run block{p_end}
{synopt:{cmd:e(srnames)}}names in the short-run dynamics block{p_end}
{synopt:{cmd:e(ivar)}}, {cmd:e(tvar)}panel and time variables{p_end}
{synopt:{cmd:e(unitvce)}}unit-level variance estimator{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}stacked short-run and long-run coefficients
and their joint covariance, with one equation per quantile
({cmd:q025}, {cmd:lr025}, ...){p_end}
{synopt:{cmd:e(b_sr)}, {cmd:e(V_sr)}}short-run block only{p_end}
{synopt:{cmd:e(b_lr)}, {cmd:e(V_lr)}}long-run block only{p_end}
{synopt:{cmd:e(sr_b)}, {cmd:e(sr_V)}}short-run dynamics block{p_end}
{synopt:{cmd:e(csa_b)}, {cmd:e(csa_V)}}cross-sectional-average
coefficients{p_end}
{synopt:{cmd:e(halflife)}, {cmd:e(halflife_se)}}half-life by quantile{p_end}
{synopt:{cmd:e(diagnostics)}}pseudo R1, Wald, CD before and after
augmentation, and the Galvao et al. (2017) slope-homogeneity tests, one
row per quantile{p_end}
{synopt:{cmd:e(unit_b)}}unit-level estimates{p_end}
{synopt:{cmd:e(unit_ok)}}unit-by-quantile usability flags{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}estimation sample{p_end}


{marker refs}{title:References}

{phang}
Chudik, A., and M. H. Pesaran. 2015. Common correlated effects estimation
of heterogeneous dynamic panel data models with weakly exogenous
regressors. {it:Journal of Econometrics} 188: 393-420.

{phang}
Harding, M., C. Lamarche, and M. H. Pesaran. 2018. Common correlated
effects estimation of heterogeneous dynamic panel quantile regression
models. USC-INET Working Paper 18-11.

{phang}
Koenker, R., and J. A. F. Machado. 1999. Goodness of fit and related
inference processes for quantile regression.
{it:Journal of the American Statistical Association} 94: 1296-1310.

{phang}
Pesaran, M. H. 2004. General diagnostic tests for cross section dependence
in panels. Cambridge Working Papers in Economics 0435.

{phang}
Pesaran, M. H. 2006. Estimation and inference in large heterogeneous
panels with a multifactor error structure. {it:Econometrica} 74: 967-1012.

{phang}
Pesaran, M. H., and R. Smith. 1995. Estimating long-run relationships from
dynamic heterogeneous panels. {it:Journal of Econometrics} 68: 79-113.

{phang}
Galvao, A. F., T. Juhl, G. Montes-Rojas, and J. Olmo. 2017. Testing slope
homogeneity in quantile regression panel data with an application to the
cross-section of stock returns.
{it:Journal of Financial Econometrics} 16: 211-243.

{phang}
Powell, J. L. 1986. Censored regression quantiles.
{it:Journal of Econometrics} 32: 143-155.

{phang}
Ul-Durar, S., Y. Bakkar, N. Arshed, S. Naveed, and B. Zhang. 2025. FinTech
and economic readiness: institutional navigation amid climate risks.
{it:Research in International Business and Finance} 73: 102543.


{marker author}{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
See {help xtcspqardl_methods:{bf:help xtcspqardl methods}} for the
equation-by-equation map, and
{help xtcspqardl_postestimation:{bf:help xtcspqardl postestimation}} for
what you can do after estimation.
