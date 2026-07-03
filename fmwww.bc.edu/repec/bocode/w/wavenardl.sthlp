{smcl}
{* *! version 1.0.1  02jul2026}{...}
{vieweralsosee "wdenoise" "help wdenoise"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] tsset" "help tsset"}{...}
{vieweralsosee "[R] regress" "help regress"}{...}
{viewerjumpto "Syntax" "wavenardl##syntax"}{...}
{viewerjumpto "Description" "wavenardl##description"}{...}
{viewerjumpto "Options" "wavenardl##options"}{...}
{viewerjumpto "Methodology" "wavenardl##methodology"}{...}
{viewerjumpto "Examples" "wavenardl##examples"}{...}
{viewerjumpto "Stored results" "wavenardl##results"}{...}
{viewerjumpto "References" "wavenardl##references"}{...}
{viewerjumpto "Author" "wavenardl##author"}{...}

{title:Title}

{phang}
{bf:wavenardl} {hline 2} Wavelet-based Nonlinear ARDL (W-NARDL) model
(Jammazi, Lahiani & Nguyen 2015)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:wavenardl}
{it:depvar} [{it:controls}]
{ifin}{cmd:,}
{opth d:ecompose(varlist)}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth d:ecompose(varlist)}}variable(s) split into positive/negative
partial sums (required){p_end}
{synopt:{opt maxl:ag(#)}}maximum lag order in the grid search; default is
{cmd:maxlag(4)}{p_end}
{synopt:{opt ic(string)}}information criterion, {cmd:aic} or {cmd:bic};
default is {cmd:ic(bic)}{p_end}
{synopt:{opt trend}}include a linear trend (PSS case V); default is case III{p_end}

{syntab:Wavelet denoising}
{synopt:{opt lev:els(#)}}number of wavelet decomposition levels J; default is
floor(log2(N)){p_end}
{synopt:{opt thr:eshold(string)}}thresholding rule, {cmd:soft} or {cmd:hard};
default is {cmd:threshold(soft)}{p_end}
{synopt:{opt den:oise(string)}}which series to denoise: {cmd:all}, {cmd:dep},
{cmd:indep} or {cmd:none}; default is {cmd:denoise(all)}{p_end}
{synopt:{opt gen:erate(stub)}}save the denoised series as {it:stub}{cmd:_}{it:varname}{p_end}

{syntab:Reporting}
{synopt:{opt nocomp:are}}skip the benchmark NARDL on the raw series{p_end}
{synopt:{opt hor:izon(#)}}dynamic multiplier horizon; default is {cmd:horizon(20)}{p_end}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt nodi:ag}}suppress the diagnostic tests{p_end}
{synopt:{opt nodyn:mult}}suppress the dynamic multipliers{p_end}
{synopt:{opt not:able}}suppress the coefficient table{p_end}
{synopt:{opt nog:raph}}suppress all graphs{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The data must be {cmd:tsset} time series (not panel data).
The first variable of the main {it:varlist} is the dependent variable;
any remaining variables are non-decomposed (symmetric) controls.


{marker description}{...}
{title:Description}

{pstd}
{cmd:wavenardl} estimates the wavelet-based nonlinear autoregressive
distributed lag (W-NARDL) model of Jammazi, Lahiani & Nguyen (2015).
The procedure has three steps:

{phang2}1. Each selected series is denoised with the non-decimated Haar
"a trous" wavelet transform (HTW) of Murtagh, Starck & Renaud (2004),
thresholding the detail coefficients with the Donoho (1995) universal
threshold lambda = sigma*sqrt(2*ln(N)), where sigma is estimated by the
median absolute deviation (MAD) of the level-1 details.{p_end}

{phang2}2. A nonlinear ARDL model (Shin, Yu & Greenwood-Nimmo 2014) is
estimated on the denoised series. Each variable in {opt decompose()} is
split into positive and negative partial sums, and the lag orders are
selected by an exhaustive grid search minimizing the chosen information
criterion.{p_end}

{phang2}3. Unless {opt nocompare} is specified, a standard NARDL is
estimated on the raw series and the two models are compared (R-squared,
information criteria, log-likelihood, Durbin-Watson, bounds F-statistic),
replicating the comparison in Jammazi et al. (2015).{p_end}

{pstd}
The output includes the Pesaran, Shin & Smith (2001) bounds cointegration
test with asymptotic critical value bounds (cases III and V), Wald tests
for short-run and long-run asymmetry, long-run multipliers computed by the
delta method, dynamic (and cumulative) multipliers, and a full battery of
residual diagnostics with CUSUM and CUSUM-of-squares stability tests.

{pstd}
To denoise series without estimating the model, use the companion command
{helpb wdenoise}.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth decompose(varlist)} specifies the variable(s) decomposed into
positive and negative partial sums,
x+(t) = sum of max(dx,0) and x-(t) = sum of min(dx,0).
Required. The dependent variable may not appear here.

{phang}
{opt maxlag(#)} sets the maximum lag order for the dependent variable and
each regressor in the grid search. The search estimates every lag
combination, so the number of models grows quickly with the number of
regressors. Default is 4.

{phang}
{opt ic(string)} chooses the information criterion used to select the lag
orders: {cmd:aic} or {cmd:bic}. Default is {cmd:bic}, as in Jammazi et
al. (2015).

{phang}
{opt trend} adds a linear time trend to the model and uses the PSS case V
(unrestricted intercept, unrestricted trend) critical values for the
bounds test. Without it, case III (unrestricted intercept, no trend) is
used.

{dlgtab:Wavelet denoising}

{phang}
{opt levels(#)} sets the number of decomposition levels J of the Haar
"a trous" transform. The default (0) uses floor(log2(N)), as in the
original paper; values larger than floor(log2(N)) are capped.

{phang}
{opt threshold(string)} chooses {cmd:soft} thresholding
(sign(d)*max(|d|-lambda,0), the default) or {cmd:hard} thresholding
(d*1{c 123}|d|>=lambda{c 125}) of the wavelet detail coefficients.

{phang}
{opt denoise(string)} selects which series are denoised before
estimation: {cmd:all} (default) denoises the dependent variable, the
decomposed variables and the controls; {cmd:dep} only the dependent
variable; {cmd:indep} only the regressors; {cmd:none} estimates a plain
NARDL without any denoising (the comparison step is then skipped).

{phang}
{opt generate(stub)} saves each denoised series back into the dataset as
{it:stub}{cmd:_}{it:varname}.

{dlgtab:Reporting}

{phang}
{opt nocompare} suppresses the benchmark NARDL estimated on the raw
series and the comparison table.

{phang}
{opt horizon(#)} sets the horizon of the dynamic multiplier paths.
Default is 20.

{phang}
{opt level(#)} sets the confidence level for the long-run multiplier
confidence intervals. Default is {cmd:level(95)}.

{phang}
{opt nodiag}, {opt nodynmult}, {opt notable} and {opt nograph} suppress,
respectively, the diagnostic tests, the dynamic multipliers, the
coefficient table and all graph output.


{marker methodology}{...}
{title:Methodology}

{pstd}
The estimated unrestricted error-correction form is

{p 8 8 2}
D.y(t) = c + rho*y(t-1) + theta+*x+(t-1) + theta-*x-(t-1)
+ sum gamma_j*D.y(t-j) + sum [beta+_j*D.x+(t-j) + beta-_j*D.x-(t-j)]
+ delta*z terms + e(t)

{pstd}
estimated by OLS on the wavelet-denoised series. The long-run
multipliers are LR+ = -theta+/rho and LR- = -theta-/rho, with standard
errors by the delta method ({helpb nlcom}). Long-run symmetry is tested
with a Wald test of -theta+/rho = -theta-/rho ({helpb testnl}); short-run
additive symmetry tests the equality of the summed D.x+ and D.x-
coefficients. Cointegration is assessed with the F-test on the joint
significance of the lagged levels (F_PSS), the t-statistic on y(t-1)
(t_BDM), and the F-test on the lagged levels of the regressors, against
the asymptotic bounds of Pesaran, Shin & Smith (2001).


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}W-NARDL of investment on income, income decomposed{p_end}
{phang2}{cmd:. wavenardl ln_inv, decompose(ln_inc) maxlag(2)}{p_end}

{pstd}With a control, hard thresholding and a trend{p_end}
{phang2}{cmd:. wavenardl ln_inv ln_consump, decompose(ln_inc) maxlag(2) threshold(hard) trend}{p_end}

{pstd}Denoise only the regressors, save the denoised series, no graphs{p_end}
{phang2}{cmd:. wavenardl ln_inv, decompose(ln_inc) denoise(indep) generate(s) nograph}{p_end}

{pstd}Plain NARDL (no denoising){p_end}
{phang2}{cmd:. wavenardl ln_inv, decompose(ln_inc) denoise(none)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:wavenardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(best_p)}}selected lag of the dependent variable{p_end}
{synopt:{cmd:e(best_q_}{it:var}{cmd:)}}selected lag of each decomposed variable{p_end}
{synopt:{cmd:e(aic)}, {cmd:e(bic)}, {cmd:e(ll)}}information criteria and log-likelihood (W-NARDL){p_end}
{synopt:{cmd:e(r2)}, {cmd:e(r2_a)}}R-squared and adjusted R-squared (W-NARDL){p_end}
{synopt:{cmd:e(dw)}}Durbin-Watson statistic (W-NARDL){p_end}
{synopt:{cmd:e(F_pss)}}PSS bounds F-statistic{p_end}
{synopt:{cmd:e(t_bdm)}}t-statistic on the lagged dependent variable{p_end}
{synopt:{cmd:e(F_indep)}}F-statistic on the lagged independent levels{p_end}
{synopt:{cmd:e(k_lr)}}number of long-run forcing variables (k){p_end}
{synopt:{cmd:e(lr_pos_}{it:var}{cmd:)}, {cmd:e(lr_neg_}{it:var}{cmd:)}}long-run multipliers{p_end}
{synopt:{cmd:e(wald_sr_}{it:var}{cmd:)}, {cmd:e(wald_sr_p_}{it:var}{cmd:)}}short-run asymmetry Wald F and p-value{p_end}
{synopt:{cmd:e(wald_lr_}{it:var}{cmd:)}, {cmd:e(wald_lr_p_}{it:var}{cmd:)}}long-run asymmetry Wald chi2 and p-value{p_end}
{synopt:{cmd:e(J_}{it:var}{cmd:)}, {cmd:e(sigma_}{it:var}{cmd:)}, {cmd:e(lambda_}{it:var}{cmd:)}}wavelet levels, noise scale and threshold per denoised variable{p_end}
{synopt:{cmd:e(aic_raw)}, {cmd:e(bic_raw)}, {cmd:e(ll_raw)}, {cmd:e(r2_raw)}, {cmd:e(r2_a_raw)}, {cmd:e(dw_raw)}, {cmd:e(F_pss_raw)}}benchmark NARDL statistics (unless {opt nocompare}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:wavenardl}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(decompose)}}decomposed variable(s){p_end}
{synopt:{cmd:e(controls)}}control variable(s){p_end}
{synopt:{cmd:e(ic)}}information criterion{p_end}
{synopt:{cmd:e(threshold)}}thresholding rule{p_end}
{synopt:{cmd:e(denoise)}}denoising choice{p_end}
{synopt:{cmd:e(case)}}PSS case (3 or 5){p_end}
{synopt:{cmd:e(wavelet)}}{cmd:haar-a-trous}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}coefficients and variance matrix of the
W-NARDL regression{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Donoho, D. L. (1995). De-noising by soft-thresholding.
{it:IEEE Transactions on Information Theory}, 41, 613-627.

{phang}
Jammazi, R., Lahiani, A., & Nguyen, D. K. (2015). A wavelet-based
nonlinear ARDL model for assessing the exchange rate pass-through to
crude oil prices. {it:Journal of International Financial Markets,}
{it:Institutions and Money}, 34, 173-187.

{phang}
Murtagh, F., Starck, J. L., & Renaud, O. (2004). On neuro-wavelet
modeling. {it:Decision Support Systems}, 37, 475-484.

{phang}
Narayan, P. K. (2005). The saving and investment nexus for China:
evidence from cointegration tests. {it:Applied Economics}, 37, 1979-1990.

{phang}
Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). Bounds testing
approaches to the analysis of level relationships.
{it:Journal of Applied Econometrics}, 16, 289-326.

{phang}
Shin, Y., Yu, B., & Greenwood-Nimmo, M. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In
{it:Festschrift in Honor of Peter Schmidt}, 281-314. Springer.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Independent Researcher{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane":github.com/merwanroudane}

{pstd}
Please cite the package as:{break}
Roudane, M. (2026). wavenardl: Stata module for the wavelet-based
nonlinear ARDL model.
