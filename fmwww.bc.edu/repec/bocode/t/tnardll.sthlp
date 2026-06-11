{smcl}
{* *! version 1.0.0  03jun2026}{...}
{vieweralsosee "tnardllmult" "help tnardllmult"}{...}
{vieweralsosee "tnardlldiag" "help tnardlldiag"}{...}
{vieweralsosee "twostep_nardl" "help twostep_nardl"}{...}
{vieweralsosee "qnardl" "help qnardl"}{...}
{vieweralsosee "tsset" "help tsset"}{...}
{viewerjumpto "Syntax" "tnardll##syntax"}{...}
{viewerjumpto "Description" "tnardll##description"}{...}
{viewerjumpto "Options" "tnardll##options"}{...}
{viewerjumpto "Model" "tnardll##model"}{...}
{viewerjumpto "Inference" "tnardll##inference"}{...}
{viewerjumpto "Postestimation" "tnardll##postestimation"}{...}
{viewerjumpto "Examples" "tnardll##examples"}{...}
{viewerjumpto "Stored results" "tnardll##results"}{...}
{viewerjumpto "References" "tnardll##refs"}{...}
{title:Title}

{phang}
{bf:tnardll} {hline 2} Threshold (Nonlinear) Autoregressive Distributed Lag model

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:tnardll} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{pstd}
{it:depvar} and {it:indepvars} may contain time-series operators, but normally
you supply the levels and {cmd:tnardll} forms the differences and partial sums
internally. The data must be {helpb tsset} as a pure time series (no panel).

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt thr:eshold(varname)}}variable whose first differences are decomposed
around the threshold(s); default is the {bf:first} regressor{p_end}
{synopt:{opt l:ags(p q)}}ARDL lag orders {it:p} (autoregressive) and {it:q}
(distributed lag); default {cmd:lags(1 1)}{p_end}
{synopt:{opt reg:imes(#)}}fix the number of regimes {it:S} in {cmd:{1,2,3}};
{cmd:0} (default) selects {it:S} by information criterion{p_end}
{synopt:{opt maxr:eg(#)}}maximum {it:S} searched when {cmd:regimes(0)}; default {cmd:3}{p_end}
{synopt:{opt ic(criterion)}}criterion for choosing {it:S}: {cmd:aic}, {cmd:sic}
(default), {cmd:hqic}, {cmd:paic}, {cmd:psic}, {cmd:phqic}{p_end}

{syntab:Threshold search}
{synopt:{opt tr:im(#)}}trimming fraction for the threshold grid; default {cmd:0.15}{p_end}
{synopt:{opt gr:id(#)}}number of grid points for each threshold; default {cmd:50}{p_end}

{syntab:Inference}
{synopt:{opt qlr}}perform the QLR threshold-existence test with bootstrap p-value{p_end}
{synopt:{opt b:reps(#)}}bootstrap replications for {cmd:qlr}; default {cmd:499}{p_end}
{synopt:{opt seed(#)}}random-number seed for the bootstrap{p_end}
{synopt:{opt r:obust}}heteroskedasticity-robust (HC1) standard errors{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt nocons:tant}}suppress the constant term{p_end}
{synopt:{opt tr:end}}include a linear time trend{p_end}
{synopt:{opt nod:ots}}suppress bootstrap progress dots{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:tnardll} estimates the Threshold ARDL (TARDL) model of Cho, Greenwood-Nimmo
and Shin (2020c, 2020d), surveyed in Cho, Greenwood-Nimmo and Shin (2021). The
TARDL model generalises the Nonlinear ARDL (NARDL) of Shin, Yu and
Greenwood-Nimmo (2014) by decomposing the {bf:first differences} of one
regressor into regime-specific partial-sum processes around one or more
{bf:unknown} threshold values, rather than the known value of zero used by
NARDL. This admits {it:size} (momentum) asymmetry in addition to {it:sign}
asymmetry.

{pstd}
For a single threshold (S=2) and the chosen threshold variable x with first
difference {bf:D.x}, the partial sums are

{p 8 8 2}{bf:Dx_t^(1)} = {bf:Dx_t} if {bf:Dx_t} {c <=} tau, else 0{p_end}
{p 8 8 2}{bf:Dx_t^(2)} = {bf:Dx_t} if {bf:Dx_t} > tau, else 0{p_end}
{p 8 8 2}{bf:x_t^(s)} = running sum of {bf:Dx_t^(s)}{p_end}

{pstd}
and the unrestricted conditional error-correction model is estimated:

{p 8 8 2}
D.y_t = c + rho*y_(t-1) + SUM_s theta^(s)*x_(t-1)^(s)
 + SUM_j phi_j*D.y_(t-j) + SUM_s SUM_j pi_j^(s)*D.x_(t-j)^(s)
 + (other regressors in levels and differences) + e_t{p_end}

{pstd}
The long-run (cointegrating) coefficients are recovered as
beta^(s) = -theta^(s)/rho with delta-method standard errors. The threshold(s)
tau are estimated by {bf:profile (concentrated) least squares}: for each
candidate threshold on a trimmed grid of the empirical distribution of
{bf:D.x}, the model is estimated by OLS and the threshold minimising the
residual sum of squares is selected. With {cmd:regimes(0)} the number of
regimes is chosen by an information criterion over S in {1,2,3}.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt threshold(varname)} names the regressor whose first differences are
decomposed around the threshold(s). It must be one of {it:indepvars}. By default
the first regressor is used. All other regressors enter the model linearly (in
one lagged level and in current and lagged differences).

{phang}
{opt lags(p q)} sets the underlying ARDL(p,q) orders. {it:p} governs the number
of lagged differences of the dependent variable (p-1 of them) and {it:q} the
number of lagged differences of the regressors (0..q-1). A single number sets
both. Default is {cmd:lags(1 1)}.

{phang}
{opt regimes(#)} fixes the number of regimes S (1, 2 or 3). S=1 is the linear
ARDL; S=2 is one threshold; S=3 is two ordered thresholds. {cmd:regimes(0)}
(the default) selects S by the criterion in {opt ic()}.

{phang}
{opt ic(criterion)} chooses the information criterion used to select S. The six
criteria are the Akaike ({cmd:aic}), Schwarz ({cmd:sic}), Hannan-Quinn
({cmd:hqic}) and the Pitarakis (2006) modified versions {cmd:paic}, {cmd:psic},
{cmd:phqic} which exclude the threshold parameters from the penalty term. Cho et
al. (2020d) find {cmd:sic} performs well without a drift in the regressor and
{cmd:psic} in small samples with a drift.

{dlgtab:Threshold search}

{phang}
{opt trim(#)} discards the lowest and highest {it:#} proportion of the empirical
distribution of {bf:D.x} when forming the threshold grid, ensuring each regime
contains enough observations. Default {cmd:0.15}.

{phang}
{opt grid(#)} sets the number of candidate threshold values. For two thresholds
(S=3) all ordered pairs from the grid are searched, so large values can be slow.

{dlgtab:Inference}

{phang}
{opt qlr} computes the quasi-likelihood ratio statistic
QLR = T(1 - SSR_alt/SSR_null) testing the linear ARDL (S=1) null against the
S=2 TARDL alternative, with a p-value from a fixed-regressor wild (Rademacher)
bootstrap. The asymptotic null distribution is non-pivotal (the threshold is
unidentified under the null: the Davies, 1977/1987 problem), which is why a
bootstrap is used. See {help tnardll##inference:Inference} below.

{phang}
{opt robust} reports heteroskedasticity-robust (HC1) standard errors for all
short-run and long-run coefficients and the asymmetry tests.

{marker model}{...}
{title:The model and what is reported}

{pstd}
{cmd:tnardll} reports, in order:

{p 6 8 2}1. {bf:Long-run coefficients} beta^(s) = -theta^(s)/rho for each regime
of the threshold variable and beta for each other regressor, with delta-method
standard errors, z-statistics and confidence intervals.{p_end}
{p 6 8 2}2. {bf:Short-run / ECM coefficients}: the speed of adjustment rho (the
coefficient {bf:ec} on y_(t-1)), the autoregressive terms, and the regime-specific
short-run terms.{p_end}
{p 6 8 2}3. {bf:Tests}: long-run regime equality (H0: beta^(s) equal across
regimes), short-run regime equality (H0: summed short-run coefficients equal),
the optional QLR threshold-existence test, and the Pesaran-Shin-Smith (2001)
bounds F- and t-statistics for the null of no levels relationship. When the
{cmd:ardl} package (Kripfganz and Schneider) is installed, {cmd:tnardll} also
prints the Kripfganz-Schneider (2020) asymptotic I(0)/I(1) critical bounds at
the 10/5/1% levels (obtained from their surface-regression {cmd:ardlbounds})
and a cointegration verdict at 5%. The deterministic case is mapped from the
model: {bf:1} (no constant), {bf:3} (unrestricted constant, the default) or
{bf:5} (unrestricted constant and trend), and k is the number of long-run
forcing terms (S regimes plus any other level regressors). Because the
threshold partial sums are non-standard regressors, treat these bounds as an
approximate reference.{p_end}
{p 6 8 2}4. The {bf:information-criterion table} over S=1,2,3.{p_end}

{marker inference}{...}
{title:Inference -- important note}

{pstd}
The original TARDL papers (Cho, Greenwood-Nimmo and Shin, 2020c,d) are
unpublished working papers. The survey (Cho, Greenwood-Nimmo and Shin, 2021)
states that the null limit distribution of the QLR statistic is a sum of two
{it:separable} functionals of two Gaussian processes (provided an intercept is
included) and is approximated by combining Hansen's (1996) weighted bootstrap
with a chi-squared distribution. The survey does not give the explicit
functionals or the exact bootstrap algorithm. {cmd:tnardll} therefore reports a
{bf:fixed-regressor wild bootstrap} p-value for the QLR statistic. This is a
standard and valid device for threshold tests with an unidentified nuisance
parameter; you should treat the QLR p-value as bootstrap-based rather than from
a published critical-value table, and you are encouraged to check empirical size
by simulation for your design. Always estimate the intercept (do not use
{opt noconstant} with {opt qlr}): the separability of the limit functionals
relies on it.

{marker postestimation}{...}
{title:Postestimation}

{pstd}
The following postestimation tools are available after {cmd:tnardll}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Command}{p_end}
{synopt:{helpb tnardll##predict:predict}}linear prediction of {cmd:D.}{it:depvar} ({cmd:xb}) or residuals{p_end}
{synopt:{helpb tnardllmult}}cumulative dynamic multipliers, with optional plot{p_end}
{synopt:{helpb tnardlldiag}}residual diagnostics (serial correlation, ARCH,
heteroskedasticity, normality, functional form){p_end}
{p2colreset}{...}

{marker predict}{...}
{pstd}{ul:Syntax for predict}{p_end}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: statistic}{p_end}
{synopt:{opt xb}}linear prediction of {cmd:D.}{it:depvar} from the fitted ECM (the default){p_end}
{synopt:{opt res:iduals}}residuals, {cmd:D.}{it:depvar} minus the linear prediction{p_end}
{p2colreset}{...}

{pstd}
Predictions are produced over the estimation sample; the rows lost to
differencing and lagging are returned as missing.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse air2, clear}{p_end}
{phang2}{cmd:. tsset time}{p_end}

{pstd}Single-threshold TARDL of log air on a regressor, ARDL(2,2){p_end}
{phang2}{cmd:. tnardll lnair x, lags(2 2) regimes(2)}{p_end}

{pstd}Let the SIC choose the number of regimes and run the QLR test{p_end}
{phang2}{cmd:. tnardll y x z, lags(2 1) ic(sic) qlr breps(499) seed(123)}{p_end}

{pstd}Threshold on the second regressor, robust SEs{p_end}
{phang2}{cmd:. tnardll y x z, threshold(z) lags(1 1) robust}{p_end}

{pstd}Cumulative dynamic multipliers and asymmetry plot{p_end}
{phang2}{cmd:. tnardll y x, lags(2 2) regimes(2)}{p_end}
{phang2}{cmd:. tnardllmult, horizon(36) graph}{p_end}

{pstd}Predict the fitted differences and residuals, then run diagnostics{p_end}
{phang2}{cmd:. predict double dyhat, xb}{p_end}
{phang2}{cmd:. predict double ehat, residuals}{p_end}
{phang2}{cmd:. tnardlldiag, bglags(4) archlags(4) resetpow(3)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:tnardll} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}
{synopt:{cmd:e(S)}}number of regimes{p_end}
{synopt:{cmd:e(nthr)}}number of thresholds (S-1){p_end}
{synopt:{cmd:e(p)}, {cmd:e(q)}}ARDL lag orders{p_end}
{synopt:{cmd:e(rho)}}speed of adjustment{p_end}
{synopt:{cmd:e(ssr)}, {cmd:e(rmse)}}residual sum of squares; root MSE{p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_a)}}R-squared; adjusted R-squared{p_end}
{synopt:{cmd:e(lr_asym_chi2)}, {cmd:e(lr_asym_p)}}long-run asymmetry test{p_end}
{synopt:{cmd:e(sr_asym_chi2)}, {cmd:e(sr_asym_p)}}short-run asymmetry test{p_end}
{synopt:{cmd:e(qlr)}, {cmd:e(qlr_p)}}QLR statistic and bootstrap p-value{p_end}
{synopt:{cmd:e(Fpss)}, {cmd:e(tBDM)}, {cmd:e(pss_k)}}PSS bounds F, t and #regressors{p_end}
{synopt:{cmd:e(pss_case)}}deterministic case (1, 3 or 5) for the bounds test{p_end}
{synopt:{cmd:e(cons)}, {cmd:e(trend)}}constant / trend indicator flags{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:tnardll}{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(thrvar)}, {cmd:e(othervars)}}variable lists{p_end}
{synopt:{cmd:e(ic)}, {cmd:e(vce)}}criterion and SE type{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}full coefficient vector and covariance{p_end}
{synopt:{cmd:e(lr_b)}, {cmd:e(lr_V)}}long-run coefficients and covariance{p_end}
{synopt:{cmd:e(thresholds)}}estimated threshold(s){p_end}
{synopt:{cmd:e(ictable)}}information criteria over S{p_end}
{synopt:{cmd:e(profile)}}threshold SSR profile (S=2){p_end}
{synopt:{cmd:e(theta)}, {cmd:e(phi)}, {cmd:e(pimat)}}pieces used by {cmd:tnardllmult}{p_end}
{synopt:{cmd:e(F_critval)}, {cmd:e(t_critval)}}Kripfganz-Schneider (2020) I(0)/I(1) bounds (if {cmd:ardl} installed){p_end}

{marker refs}{...}
{title:References}

{phang}
Cho, J.S., M.J. Greenwood-Nimmo and Y. Shin. 2021. Recent Developments of the
Autoregressive Distributed Lag Modelling Framework. {it:Journal of Economic
Surveys} (and working-paper versions).

{phang}
Cho, J.S., M.J. Greenwood-Nimmo and Y. Shin. 2020c. Testing for the Threshold
Autoregressive Distributed Lag Model. Mimeo, University of York.

{phang}
Cho, J.S., M.J. Greenwood-Nimmo and Y. Shin. 2020d. The Threshold Autoregressive
Distributed Lag Model. Mimeo, University of York.

{phang}
Davies, R.B. 1977, 1987. Hypothesis Testing when a Nuisance Parameter is Present
only under the Alternative. {it:Biometrika} 64: 247-254; 74: 33-43.

{phang}
Hansen, B.E. 1996. Inference when a Nuisance Parameter is not Identified under
the Null Hypothesis. {it:Econometrica} 64: 413-430.

{phang}
Pesaran, M.H., Y. Shin and R.J. Smith. 2001. Bounds Testing Approaches to the
Analysis of Level Relationships. {it:Journal of Applied Econometrics} 16: 289-326.

{phang}
Pitarakis, J.-Y. 2006. Model Selection Uncertainty and Detection of Threshold
Effects. {it:Studies in Nonlinear Dynamics and Econometrics} 10: 1-30.

{phang}
Shin, Y., B. Yu and M.J. Greenwood-Nimmo. 2014. Modelling Asymmetric
Cointegration and Dynamic Multipliers in a Nonlinear ARDL Framework. In
{it:Festschrift in Honor of Peter Schmidt}, 281-314. Springer.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{marker alsosee}{...}
{title:Also see}

{psee}
Postestimation:  {helpb tnardllmult} (cumulative dynamic multipliers)  {c |}
{helpb tnardlldiag} (residual diagnostics)
{p_end}

{psee}
Related:  {helpb tsset}{p_end}
