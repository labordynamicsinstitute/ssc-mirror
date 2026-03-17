{smcl}
{* *! version 1.0.0  15mar2026}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "[TS] irf" "help irf"}{...}
{viewerjumpto "Syntax" "ivlpirf2##syntax"}{...}
{viewerjumpto "Description" "ivlpirf2##description"}{...}
{viewerjumpto "Options" "ivlpirf2##options"}{...}
{viewerjumpto "Methods" "ivlpirf2##methods"}{...}
{viewerjumpto "Stored Results" "ivlpirf2##results"}{...}
{viewerjumpto "Examples" "ivlpirf2##examples"}{...}
{viewerjumpto "References" "ivlpirf2##references"}{...}
{viewerjumpto "Author" "ivlpirf2##author"}{...}

{title:Title}

{phang}
{bf:ivlpirf2} {hline 2} IV local-projection impulse-response functions with
panel data and Driscoll-Kraay inference


{marker syntax}{...}
{title:Syntax}

{phang}{ul:Time-series estimation:}{p_end}

{p 8 17 2}
{cmd:ivlpirf2}
{it:depvarlist}
{ifin}
{cmd:,} {cmd:endogenous(}{it:depvar} = {it:instruments}{cmd:)}
[{it:options}]

{phang}{ul:Panel-data estimation with Driscoll-Kraay:}{p_end}

{p 8 17 2}
{cmd:ivlpirf2}
{it:depvarlist}
{ifin}
{cmd:,} {cmd:endogenous(}{it:depvar} = {it:instruments}{cmd:)}
{cmd:vce(dkraay)} {cmd:fe}
[{it:options}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt endog:enous(depvar = varlist)}}endogenous impulse variable and instruments (required){p_end}
{synopt:{opt st:ep(#)}}maximum IRF horizon; default is {cmd:4}{p_end}
{synopt:{opt la:gs(numlist)}}control lag orders; default is {cmd:1 2}{p_end}
{synopt:{opt exog(varlist)}}additional exogenous controls{p_end}
{synopt:{opt vce(type)}}variance estimator: {bf:robust}, {bf:cluster} {it:clustvar}, {bf:hac nw} [{it:#}], or {bf:dkraay} [{it:#}]{p_end}
{synopt:{opt fe}}panel fixed effects{p_end}
{synopt:{opt cumul:ative}}report cumulative impulse responses{p_end}
{synopt:{opt nocons:tant}}suppress intercept{p_end}
{synopt:{opt gr:aph}}plot IRF with layered confidence bands{p_end}
{synopt:{opt le:vel(numlist)}}confidence levels; default is {cmd:68 90 95}{p_end}
{synopt:{opt first:stage}}report first-stage F-statistics for weak instruments{p_end}
{synopt:{opt method(string)}}estimation method: {bf:2sls} (default) or {bf:gmm}{p_end}
{synopt:{opt notable}}suppress output table{p_end}
{synopt:{opt ti:tle(string)}}custom graph title{p_end}
{synopt:{opt saving(string)}}save graph to file{p_end}
{synoptline}
{p 4 6 2}The data must be {cmd:tsset} or {cmd:xtset} before using {cmd:ivlpirf2}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ivlpirf2} estimates impulse-response functions (IRFs) using the local
projection (LP) method of {help ivlpirf2##jorda2005:Jordà (2005)} with
instrumental variables. Unlike traditional VAR-based IRFs, local projections
estimate each horizon's response directly via separate regressions, making
them robust to model misspecification.{p_end}

{pstd}
{bf:Key features:}{p_end}

{phang2}1. {bf:IV estimation} — Instruments an endogenous impulse variable
using external instruments via 2SLS.{p_end}
{phang2}2. {bf:Panel data support} — Works with {cmd:xtset} panel data,
including fixed effects ({cmd:fe}).{p_end}
{phang2}3. {bf:Driscoll-Kraay SEs} — Robust to heteroskedasticity, serial
correlation, and cross-sectional dependence via {cmd:vce(dkraay)}.{p_end}
{phang2}4. {bf:Publication-quality graphs} — Layered confidence bands
(68%, 90%, 95%) with shaded regions.{p_end}
{phang2}5. {bf:Weak-instrument diagnostics} — First-stage F-statistics
via {cmd:firststage}.{p_end}

{pstd}
{bf:Compatibility:} Requires Stata 14 or later. Works with both time-series
and panel data.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt endogenous(depvar = varlist)} specifies the endogenous impulse variable
and the instruments. Only one endogenous variable is allowed. Multiple
instruments may be specified.{p_end}

{phang}
{opt step(#)} sets the maximum IRF horizon. Default is {cmd:4}. For each
horizon h = 0, 1, ..., step, a separate regression is estimated.{p_end}

{phang}
{opt lags(numlist)} specifies lag orders for control variables. Default is
{cmd:1 2}. Controls include lags of all response variables and the
endogenous variable.{p_end}

{phang}
{opt exog(varlist)} specifies additional exogenous covariates to include
in all regressions.{p_end}

{phang}
{opt vce(type)} specifies the variance estimator:{p_end}

{p 12 12 2}
{bf:robust} {hline 2} (default) Heteroskedasticity-robust (Eicker-Huber-White).{p_end}
{p 12 12 2}
{bf:cluster} {it:clustvar} {hline 2} Cluster-robust at the level of {it:clustvar}.{p_end}
{p 12 12 2}
{bf:hac nw} [{it:#}] {hline 2} Newey-West HAC standard errors. Optional lag
truncation parameter.{p_end}
{p 12 12 2}
{bf:dkraay} [{it:#}] {hline 2} Driscoll-Kraay standard errors. Requires panel
data. Optional bandwidth parameter. Robust to heteroskedasticity, serial
correlation, and cross-sectional dependence.{p_end}

{phang}
{opt fe} includes panel fixed effects. Requires panel data ({cmd:xtset}).{p_end}

{phang}
{opt cumulative} reports cumulative impulse-response functions (sum of
responses from horizon 0 to h).{p_end}

{phang}
{opt graph} produces a publication-quality IRF plot with layered confidence
bands. Uses the cranberry color scheme with shaded regions for each
confidence level.{p_end}

{phang}
{opt level(numlist)} specifies the confidence levels for the graph. Default
is {cmd:68 90 95}, producing three layered bands. The innermost band is the
darkest.{p_end}

{phang}
{opt firststage} reports first-stage regression diagnostics for the
instruments, including the F-statistic on excluded instruments. An F < 10
suggests potential weak instruments (Stock and Yogo, 2005).{p_end}


{marker methods}{...}
{title:Methods and Formulas}

{dlgtab:Local Projections (Jordà, 2005)}

{pstd}
For each horizon h, the LP regression is:{p_end}

{p 8 8 2}
y_{t+h} = alpha_h + beta_h * x_t + Gamma_h' * W_t + u_{t+h}{p_end}

{pstd}
where y_{t+h} is the response variable at horizon h, x_t is the endogenous
impulse variable instrumented by z_t, and W_t contains lagged controls.
The collection of beta_h coefficients traces the IRF.{p_end}

{dlgtab:IV Estimation}

{pstd}
When x_t is endogenous, 2SLS is used: the first stage regresses x_t on
z_t and W_t; the second stage uses fitted values. For panel data with
{cmd:fe}, within-transformation is applied first.{p_end}

{dlgtab:Driscoll-Kraay Standard Errors}

{pstd}
For panel data with cross-sectional dependence (e.g., common shocks),
{help ivlpirf2##dk1998:Driscoll and Kraay (1998)} standard errors are
consistent under:{p_end}

{phang2}(a) heteroskedasticity{p_end}
{phang2}(b) arbitrary serial correlation{p_end}
{phang2}(c) cross-sectional dependence when T is moderate{p_end}

{pstd}
This is implemented via {cmd:xtscc} (Hoechle, 2007).{p_end}

{dlgtab:GMM Joint Estimation}

{pstd}
With {cmd:method(gmm)}, all horizons are estimated simultaneously using
Stata's {cmd:gmm} command. Controls are partialled out from the dependent
variables, the endogenous variable, and the instruments via OLS residuals.
The GMM moment conditions are:{p_end}

{p 8 8 2}
E[z_t * (y_{t+h,po} - beta_h * x_{t,po})] = 0 for h = 0, ..., H{p_end}

{pstd}
where the subscript {it:po} denotes partialled-out variables. This produces
a joint variance-covariance matrix across all horizons, accounting for
cross-horizon correlation. This is the same approach used by Stata 19's
built-in {cmd:ivlpirf}. See
{help ivlpirf2##pmw2021:Plagborg-Møller and Wolf (2021)} for theoretical
equivalence results.{p_end}


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:ivlpirf2} stores the following in {cmd:e()}:

{pstd}{bf:Scalars:}{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(step)}}maximum horizon{p_end}
{synopt:{cmd:e(k_impulses)}}number of impulse variables (always 1){p_end}
{synopt:{cmd:e(k_responses)}}number of response variables{p_end}
{synopt:{cmd:e(k_instruments)}}number of instruments{p_end}
{synopt:{cmd:e(k_controls)}}number of control variables{p_end}
{synopt:{cmd:e(cumul)}}1 if cumulative, 0 otherwise{p_end}

{pstd}{bf:Macros:}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ivlpirf2}{p_end}
{synopt:{cmd:e(impulse)}}impulse variable name{p_end}
{synopt:{cmd:e(responses)}}response variable names{p_end}
{synopt:{cmd:e(instruments)}}instrument variable names{p_end}
{synopt:{cmd:e(vce)}}VCE type{p_end}

{pstd}{bf:Matrices:}{p_end}
{synopt:{cmd:e(b)}}coefficient vector (IRF at each horizon){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(irf_b)}}(step+1) x k_resp matrix of IRF coefficients{p_end}
{synopt:{cmd:e(irf_se)}}(step+1) x k_resp matrix of standard errors{p_end}
{synopt:{cmd:e(irf_df)}}(step+1) x k_resp matrix of degrees of freedom{p_end}


{marker examples}{...}
{title:Examples}

{dlgtab:Example 1: Basic time-series IV-LP IRF}

{pstd}Setup:{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset}{p_end}

{pstd}Estimate IRF of investment and consumption to an income shock,
instrumented by its own lags:{p_end}
{phang2}{cmd:. ivlpirf2 dln_inv dln_consump, endogenous(dln_inc = L(2/4).dln_inc) step(8) graph}{p_end}

{dlgtab:Example 2: Panel data with Driscoll-Kraay inference}

{pstd}For panel data with common shocks:{p_end}
{phang2}{cmd:. xtset country year}{p_end}
{phang2}{cmd:. ivlpirf2 D.gdp, endogenous(shock = z_instrument) vce(dkraay) fe step(4) graph}{p_end}

{pstd}This produces an IRF with layered 68/90/95% confidence bands using
Driscoll-Kraay standard errors, which are robust to cross-sectional
dependence.{p_end}

{dlgtab:Example 3: Cumulative IRF with cluster SEs}

{phang2}{cmd:. ivlpirf2 dln_inv, endogenous(dln_inc = L(2/4).dln_inc) step(12) cumulative vce(cluster id) graph}{p_end}

{dlgtab:Example 4: Weak instrument diagnostics}

{phang2}{cmd:. ivlpirf2 dln_inv, endogenous(dln_inc = L(2/4).dln_inc) step(8) firststage}{p_end}

{pstd}If the first-stage F-statistic is below 10, the instruments may be
weak and the IV estimates unreliable.{p_end}

{dlgtab:Example 5: Custom confidence levels}

{phang2}{cmd:. ivlpirf2 dln_inv, endogenous(dln_inc = L(2/4).dln_inc) step(8) graph level(90 95)}{p_end}

{pstd}This plots only two confidence bands (90% and 95%).{p_end}


{marker references}{...}
{title:References}

{marker dk1998}{...}
{phang}
Driscoll, J.C. and A.C. Kraay. 1998.
Consistent covariance matrix estimation with spatially dependent panel data.
{it:Review of Economics and Statistics} 80(4): 549-560.{p_end}

{phang}
Hoechle, D. 2007.
Robust standard errors for panel regressions with cross-sectional dependence.
{it:Stata Journal} 7(3): 281-312.{p_end}

{phang}
Gertler, M. and P. Karadi. 2015.
Monetary policy surprises, credit costs, and economic activity.
{it:American Economic Journal: Macroeconomics} 7(1): 44-76.{p_end}

{marker jorda2005}{...}
{phang}
Jordà, Ò. 2005.
Estimation and inference of impulse responses by local projections.
{it:American Economic Review} 95(1): 161-182.{p_end}

{phang}
Jordà, Ò., S.R. Singh, and A.M. Taylor. 2020.
The long-run effects of monetary policy.
NBER Working Paper No. 26666.{p_end}

{phang}
Mertens, K. and M.O. Ravn. 2013.
The dynamic effects of personal and corporate income tax changes in the
United States.
{it:American Economic Review} 103(4): 1212-1247.{p_end}

{phang}
Montiel Olea, J.L. and M. Plagborg-Møller. 2021.
Local projection inference is simpler and more robust than you think.
{it:Econometrica} 89(4): 1789-1823.{p_end}

{phang}
Newey, W.K. and K.D. West. 1987.
A simple, positive semi-definite, heteroskedasticity and autocorrelation
consistent covariance matrix.
{it:Econometrica} 55(3): 703-708.{p_end}

{marker pmw2021}{...}
{phang}
Plagborg-Møller, M. and C.K. Wolf. 2021.
Local projections and VARs estimate the same impulse responses.
{it:Econometrica} 89(2): 955-980.{p_end}

{phang}
Ramey, V.A. 2016.
Macroeconomic shocks and their propagation.
In J.B. Taylor and H. Uhlig (eds.), {it:Handbook of Macroeconomics},
vol. 2A. Elsevier: 71-162.{p_end}

{phang}
Saadaoui, J. and W. Ginn. 2025.
Monetary policy reaction to geopolitical risks in unstable environments.
{it:Macroeconomic Dynamics}, forthcoming.{p_end}

{phang}
Saadaoui, J. and V. Mignon. 2024.
How do political tensions and geopolitical risks impact oil prices?
{it:Energy Economics} 129: 107219.{p_end}

{phang}
Barbier-Gauchard, A., J. Saadaoui, and J.-E. Sturm. 2025.
Geopolitical risks, political tensions and the European economy.
{it:European Journal of Political Economy}, forthcoming.{p_end}

{phang}
Stock, J.H. and M.W. Watson. 2018.
Identification and estimation of dynamic causal effects in macroeconomics
using external instruments.
{it:Economic Journal} 128(610): 917-948.{p_end}

{phang}
Stock, J.H. and M. Yogo. 2005.
Testing for weak instruments in linear IV regression.
In D.W.K. Andrews and J.H. Stock (eds.), {it:Identification and Inference
for Econometric Models}. Cambridge University Press: 80-108.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{p_end}

{pstd}
Email: merwanroudane920@gmail.com{p_end}

{pstd}
Please cite as:{p_end}
{phang2}Roudane, M. 2026. {cmd:ivlpirf2}: IV local-projection impulse-response
functions with panel data and Driscoll-Kraay inference. Stata package
version 1.0.0.{p_end}
{smcl}
