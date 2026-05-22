{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "mixi01" "help mixi01"}{...}
{vieweralsosee "mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "mixi01_fmiv"  "help mixi01_fmiv"}{...}
{vieweralsosee "mixi01_svar"  "help mixi01_svar"}{...}
{vieweralsosee "mixi01_vecm"  "help mixi01_vecm"}{...}
{vieweralsosee "mixi01_irf"   "help mixi01_irf"}{...}
{vieweralsosee "mixi01_test"  "help mixi01_test"}{...}
{viewerjumpto "Syntax"          "mixi01_acl##syntax"}{...}
{viewerjumpto "Description"     "mixi01_acl##description"}{...}
{viewerjumpto "Options"         "mixi01_acl##options"}{...}
{viewerjumpto "Remarks"         "mixi01_acl##remarks"}{...}
{viewerjumpto "Examples"        "mixi01_acl##examples"}{...}
{viewerjumpto "Stored results"  "mixi01_acl##stored"}{...}
{viewerjumpto "References"      "mixi01_acl##references"}{...}
{viewerjumpto "Author"          "mixi01_acl##author"}{...}
{viewerjumpto "Also see"        "mixi01_acl##alsosee"}{...}

{title:Title}

{p2colset 5 22 24 2}{...}
{p2col :{hi:mixi01_acl} {hline 2}}Augmented Cointegrating Linear (ACL) regression
with strongly correlated I(1) and I(0) regressors{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mixi01_acl} {it:depvar} {it:indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Integration classification}
{synopt :{opt i1(varlist)}}list of I(1) (nonstationary) regressors{p_end}
{synopt :{opt i0(varlist)}}list of I(0) (stationary) regressors{p_end}
{synopt :{opt i1vars(varlist)}}synonym for {opt i1()}{p_end}
{synopt :{opt i0vars(varlist)}}synonym for {opt i0()}{p_end}
{synopt :{opt auto}}auto-classify regressors with Augmented Dickey-Fuller pre-test{p_end}

{syntab:Deterministic terms}
{synopt :{opt nocons:tant}}suppress the intercept{p_end}
{synopt :{opt tr:end(#)}}include a polynomial trend of degree {it:#} (0, 1 or 2){p_end}

{syntab:Specification check (Peng-Dong, 2021, Section 5)}
{synopt :{opt coint:test}}after estimation, run an Augmented Dickey-Fuller
test on the residuals to confirm the ACL specification (residuals should be I(0)){p_end}
{synopt :{opt adfl:ags(#)}}number of lags in the residual ADF; default {cmd:adflags(4)}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01_acl} estimates the Augmented Cointegrating Linear (ACL) regression
model of Peng and Dong (2021),

{p 8 8 2}
{it:y_t} = {bf:β}{c '} {it:x_t} + {bf:α}{c '} {it:z_t} + {it:e_t},
{space 3}{it:t} = 1, ..., {it:n},

{pstd}
where {it:x_t} is a {it:d_1}-vector of {bf:I(1)} (unit-root) processes and
{it:z_t} is a {it:d_2}-vector of {bf:I(0)} (stationary) processes.  Crucially,
the two regressor blocks may be {it:strongly correlated} in the sense that they
share the same innovation sequence (Peng-Dong Assumption 2.2(b)).  This goes
beyond the weak-correlation setting of Dong and Linton (2018) and most prior
work on mixed-integration regression.

{pstd}
The estimator is plain OLS — no kernel-based long-run-covariance correction is
needed.  Peng and Dong's Theorem 1 shows that the OLS coefficients converge:

{p 8 12 2}
sqrt({it:n})({bf:α̂} - {bf:α}) {bf:→_D} N(0, σ²Σ^{-1}),
where Σ = E[{it:z_1} {it:z_1}{c '}], at the standard rate;

{p 8 12 2}
{it:n}({bf:β̂} - {bf:β}) {bf:→_D} [∫W W{c '}]^{-1} ∫W dV,
mixed-normal at the super-consistent rate.

{pstd}
Theorem 2 gives self-normalised central-limit theorems that the implementation
exploits for inference:

{p 8 12 2}
(Σ {it:z_t} {it:z_t}{c '})^{1/2} ({bf:α̂} - {bf:α}) {bf:→_D} N(0, σ²I);

{p 8 12 2}
(Σ {it:x_t} {it:x_t}{c '})^{1/2} ({bf:β̂} - {bf:β}) {bf:→_D} N(0, σ²I).

{pstd}
This means individual {it:z}-tests, joint Wald tests and confidence intervals
based on the standard sandwich {it:V} = σ̂² ({it:X}{c '}{it:X})^{-1} (with
σ̂² = (1/{it:n})∑{it:e_t}²) are asymptotically valid for both blocks, although
the {bf:β}-block intervals shrink at the super-consistent {it:n}-rate.

{pstd}
{cmd:mixi01_acl} complements {helpb mixi01_fmols} (Phillips-1995 FM-OLS):
both target the same data-generating process, but FM-OLS applies an explicit
kernel correction whereas ACL exploits joint convergence to argue that OLS
already suffices for valid inference.  Compare the two on your data and
choose the framework that better fits your maintained assumptions.


{marker options}{...}
{title:Options}

{dlgtab:Integration classification}

{phang}
{opt i1(varlist)} declares which regressors are {bf:I(1)} (nonstationary).
Aliased to {opt i1vars()}.

{phang}
{opt i0(varlist)} declares which regressors are {bf:I(0)} (stationary).
Aliased to {opt i0vars()}.

{phang}
{opt auto} runs an Augmented Dickey-Fuller (ADF) test on every regressor and
classifies a series as I(0) if the test rejects at 5% level, otherwise I(1).
Cannot be combined with explicit {opt i1()} or {opt i0()} lists.

{phang}
If neither classification list nor {opt auto} is supplied, all regressors are
treated as I(1).

{dlgtab:Deterministic terms}

{phang}
{opt noconstant} omits the intercept.

{phang}
{opt trend(#)} adds a polynomial deterministic trend:
{cmd:trend(1)} = linear, {cmd:trend(2)} = quadratic; default is {cmd:trend(0)}.

{dlgtab:Reporting}

{phang}
{opt level(#)} sets the confidence level for displayed intervals; default 95.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Inference.}  Standard errors reported by {cmd:mixi01_acl} are
sqrt(diag(σ̂² ({it:X}{c '}{it:X})^{-1})).  For a Wald test on the I(1) block
({bf:β}), Peng-Dong Theorem 2 implies

{p 8 12 2}
({bf:β̂} - {bf:β_0}){c '} (Σ {it:x_t} {it:x_t}{c '}) ({bf:β̂} - {bf:β_0}) / σ̂²
{bf:→_D} χ²({it:d_1}).

{pstd}
The matrix Σ {it:x_t} {it:x_t}{c '} is stored as {cmd:e(Sxx)} and Σ {it:z_t}
{it:z_t}{c '} as {cmd:e(Szz)}, so users wanting the exact self-normalised
test can construct it from {cmd:e()} directly.

{pstd}
{bf:Strong vs weak correlation.}  Peng-Dong allow {it:z_t} = ∑φ_j ε_{t-j} + η_t
with ε the same shocks driving the I(1) innovations.  Standard FM-OLS
(Phillips 1995) is also valid in this case but requires kernel/bandwidth
choices.  ACL is parameter-free.

{pstd}
{bf:Trend.}  If {opt trend(1)} or {opt trend(2)} is supplied, the trend terms
are appended after the I(0) block and treated as additional regressors in
({it:X}{c '}{it:X}).  Inference on trend coefficients uses the same V matrix.


{marker examples}{...}
{title:Examples}

{dlgtab:Mixed I(1)/I(0) ACL regression}

{phang2}{cmd:. mixi01_acl y x1 x2 z1, i1(x1 x2) i0(z1)}{p_end}

{dlgtab:Auto-classification by ADF}

{phang2}{cmd:. mixi01_acl y x1 x2 x3 x4, auto}{p_end}

{dlgtab:With linear trend}

{phang2}{cmd:. mixi01_acl y x1 x2 z1, i1(x1 x2) i0(z1) trend(1)}{p_end}

{dlgtab:Specification check via residual ADF (Peng-Dong Sec. 5)}

{phang2}{cmd:. mixi01_acl y x1 x2 z1, i1(x1 x2) i0(z1) cointtest adflags(4)}{p_end}

{dlgtab:Compare with FM-OLS}

{phang2}{cmd:. mixi01_acl   y x1 x2 z1, i1(x1 x2) i0(z1)}{p_end}
{phang2}{cmd:. mixi01_fmols y x1 x2 z1, i1(x1 x2) i0(z1) kernel(bartlett)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:mixi01_acl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt :{cmd:e(N)}}number of observations{p_end}
{synopt :{cmd:e(r2)}}R-squared{p_end}
{synopt :{cmd:e(r2_a)}}adjusted R-squared{p_end}
{synopt :{cmd:e(rmse)}}root MSE = sqrt(σ̂²){p_end}
{synopt :{cmd:e(sigma2)}}σ̂² = (1/{it:n})∑ê_t² (Peng-Dong Corollary 1){p_end}
{synopt :{cmd:e(n_i1)}}number of I(1) regressors{p_end}
{synopt :{cmd:e(n_i0)}}number of I(0) regressors{p_end}
{synopt :{cmd:e(trend)}}trend degree{p_end}
{synopt :{cmd:e(level)}}confidence level{p_end}
{synopt :{cmd:e(adf_resid_t)}}residual ADF statistic (only if {opt cointtest}){p_end}
{synopt :{cmd:e(adf_resid_p)}}p-value of residual ADF (only if {opt cointtest}){p_end}
{synopt :{cmd:e(adf_resid_lags)}}lag length used in residual ADF (only if {opt cointtest}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt :{cmd:e(cmd)}}{cmd:mixi01_acl}{p_end}
{synopt :{cmd:e(depvar)}}dependent variable name{p_end}
{synopt :{cmd:e(i1vars)}}I(1) regressor list{p_end}
{synopt :{cmd:e(i0vars)}}I(0) regressor list{p_end}
{synopt :{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt :{cmd:e(b)}}coefficient vector ({bf:β}, {bf:α}, deterministics){p_end}
{synopt :{cmd:e(V)}}variance-covariance = σ̂²({it:X}{c '}{it:X})^{-1}{p_end}
{synopt :{cmd:e(XX)}}{it:X}{c '}{it:X}{p_end}
{synopt :{cmd:e(Sxx)}}Σ {it:x_t} {it:x_t}{c '} (self-normalisation for {bf:β}){p_end}
{synopt :{cmd:e(Szz)}}Σ {it:z_t} {it:z_t}{c '} (self-normalisation for {bf:α}){p_end}
{synopt :{cmd:e(iorder)}}row vector of integration orders (1 = I(1), 0 = I(0)/det){p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt :{cmd:e(sample)}}marks the estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Peng, Z. and C. Dong (2021).  Augmented cointegrating linear models with
possibly strongly correlated stationary and nonstationary regressors.
{it:SSRN Working Paper} No. 3943779.
{p_end}

{phang}
Dong, C. and O. Linton (2018).  Additive nonparametric models with time
variable and both stationary and nonstationary regressors.
{it:Journal of Econometrics}, 207(1), 212–236.
{p_end}

{phang}
Park, J. Y. and P. C. B. Phillips (2001).  Nonlinear regressions with
integrated time series.  {it:Econometrica}, 69(1), 117–161.
{p_end}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}

{phang}
Wang, Q. (2015).  {it:Limit Theorems for Nonlinear Cointegrating Regression}.
World Scientific.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Department of Economics (Independent Researcher){break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}


{marker alsosee}{...}
{title:Also see}

{pstd}
Master help — {helpb mixi01}.
{p_end}

{pstd}
Sibling commands — {helpb mixi01_fmols}, {helpb mixi01_fmvar},
{helpb mixi01_fmiv}, {helpb mixi01_svar}, {helpb mixi01_vecm},
{helpb mixi01_irf}, {helpb mixi01_test}.
{p_end}
