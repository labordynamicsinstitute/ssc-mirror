{smcl}
{* *! cupfm.sthlp — Help file for cupfm v1.0.2  2026-04-18}{...}
{vieweralsosee "xtpmg"    "help xtpmg"}{...}
{vieweralsosee "xtpedroni" "help xtpedroni"}{...}
{viewerjumpto "Syntax"           "cupfm##syntax"}{...}
{viewerjumpto "Description"      "cupfm##description"}{...}
{viewerjumpto "Model & Notation" "cupfm##model"}{...}
{viewerjumpto "Assumptions"      "cupfm##assumptions"}{...}
{viewerjumpto "Estimators"       "cupfm##estimators"}{...}
{viewerjumpto "Options"          "cupfm##options"}{...}
{viewerjumpto "Cautions"         "cupfm##cautions"}{...}
{viewerjumpto "Stored results"   "cupfm##results"}{...}
{viewerjumpto "Post-estimation"  "cupfm##postestimation"}{...}
{viewerjumpto "Examples"         "cupfm##examples"}{...}
{viewerjumpto "References"       "cupfm##references"}{...}
{viewerjumpto "Author"           "cupfm##author"}{...}

{title:Title}

{phang}
{bf:cupfm} {hline 2} Panel Cointegration with Global Stochastic Trends
(CupFM, CupBC, Bai FM, LSDV estimators; Bai, Kao & Ng 2009; Bai & Kao 2005)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:cupfm}
{depvar} {indepvars}
{ifin}
[{cmd:,}
{it:options}]

{pstd}
{depvar} and all {indepvars} must be numeric variables.
Time-series operators (L., D., F.) are allowed.
Factor variables (i., c.) are {bf:not} supported.

{pstd}
The data must be declared as a panel with {helpb xtset} before calling {cmd:cupfm}.
A {bf:balanced} panel is required.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Factor model}
{synopt:{opt nf:actors(#)}}number of common factors r; default 0 = auto-select
  via Bai & Ng (2002) information criterion{p_end}
{synopt:{opt autor:max(#)}}maximum r considered in auto-selection; default 8{p_end}

{syntab:Long-run covariance}
{synopt:{opt bw:idth(#)}}Bartlett kernel bandwidth (lag truncation M); default 5{p_end}
{synopt:{opt ker:nel(kname)}}kernel function: {opt bartlett} (default) or {opt parzen}{p_end}

{syntab:Iteration control}
{synopt:{opt maxi:ter(#)}}maximum Cup iterations; default 20{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance on Omega_{u.x}; default 0.0001{p_end}

{syntab:Output control}
{synopt:{opt noic:summary}}suppress the factor structure diagnostics table{p_end}
{synopt:{opt noisily}}show verbose Mata iteration output{p_end}

{syntab:Visualization}
{synopt:{opt plot}}produce all three plots (coef, factors, loadings){p_end}
{synopt:{opt plotc:oef}}coefficient comparison forest plot only{p_end}
{synopt:{opt plotf:actors}}estimated common factors time-series plot only{p_end}
{synopt:{opt plotl:oadings}}factor loadings bar/scatter plot only{p_end}
{synopt:{opt saving(filename)}}base filename prefix for saved plots and exports
  (no extension; default = cupfm){p_end}

{syntab:Export}
{synopt:{opt ex:port(fmt)}}export results: {opt excel}, {opt latex}, {opt csv}, or {opt all}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:cupfm} estimates panel cointegration models in which cross-sectional
dependence arises from a small number of {bf:common global stochastic trends}.
It implements all five estimators in
{help cupfm##BKN2009:Bai, Kao & Ng (2009)} ({it:BKN}) and
{help cupfm##BK2005:Bai & Kao (2005)} ({it:BK}), and is translated directly
from the authors' official GAUSS source code ({bf:bkn}).

{pstd}
Standard panel cointegration estimators (LSDV, FMOLS, DOLS) are inconsistent
when cross-sectional dependence derives from I(1) common factors.
{cmd:cupfm} achieves {bf:sqrt(NT)-consistency} and {bf:asymptotic normality}
under the null of no spurious regression.

{pstd}
The primary estimator is {bf:CupFM} (BKN 2009, Theorem 3). All five estimators
are reported in the results table. Post-estimation, every set of coefficients
and t-statistics is accessible via {cmd:e(beta_*)} and {cmd:e(tstat_*)}.


{marker model}{...}
{title:Model, Notation, and Identification}

{pstd}
{bf:Panel cointegrating regression:}

{pmore}
y_it = {it:alpha}_i + {it:beta}'x_it + e_it,    i = 1,...,N; t = 1,...,T

{pstd}
{bf:Error decomposition (factor structure):}

{pmore}
e_it = {it:lambda}_i'F_t + u_it

{pstd}
{bf:Regressors:}

{pmore}
x_it = x_{it-1} + {it:v}_it       (I(1) random walk)

{pstd}
{bf:Common factors} (two cases):

{pmore}
F_t = F_{t-1} + eta_t    [BKN 2009: I(1) global stochastic trends]

{pmore}
F_t ~ I(0)               [BK 2005: stationary factors, but same corrections apply]

{pstd}
{bf:Notation:}

{phang2}y_it   {hline 2} dependent variable (must be I(1)){p_end}
{phang2}x_it   {hline 2} k×1 vector of I(1) regressors{p_end}
{phang2}F_t    {hline 2} r×1 vector of common factors (I(1) or I(0)){p_end}
{phang2}lambda_i {hline 2} r×1 vector of {bf:heterogeneous} factor loadings{p_end}
{phang2}u_it   {hline 2} idiosyncratic error (stationary, may be serially correlated){p_end}
{phang2}alpha_i {hline 2} unit-specific fixed effect (eliminated by demeaning){p_end}
{phang2}beta   {hline 2} k×1 vector of cointegrating coefficients (common across i){p_end}

{pstd}
{bf:Identification:} beta is assumed {bf:homogeneous} across units.
The model permits {bf:heterogeneous} factor loadings (lambda_i),
heterogeneous fixed effects (alpha_i), and heterogeneous autocovariance
structure of u_it.

{pstd}
{bf:Long-run covariance matrices:}

{pmore}
Omega = lim(1/T) * sum_s sum_t E[z_it z_is']

{pmore}
where z_it = (u_it, v_it')', partitioned as

{pmore}
Omega = [Omega_uu  Omega_uv]
        [Omega_vu  Omega_vv]

{pstd}
The FM and Cup corrections remove the endogeneity bias term
Delta = Omega_uv * Omega_vv^{-1} (conditional long-run covariance)
using the Bartlett kernel estimator of Omega with bandwidth M = {opt bandwidth()}.


{marker assumptions}{...}
{title:Assumptions}

{pstd}
{bf:A1. Panel data format}

{phang2}
Data must be in Stata long format with {helpb xtset} declared.
A {bf:balanced} panel is required: every unit must have exactly T observations,
ordered consecutively. {cmd:cupfm} checks this internally and exits with error
if the panel is unbalanced.

{pstd}
{bf:A2. Integration order of y and x}

{phang2}
All variables in {varlist} must be I(1). The cointegrating relationship
y_it = alpha_i + beta'x_it + e_it is assumed to hold in levels.
{cmd:cupfm} does {bf:not} test for cointegration — use {helpb xtpedroni}
or panel unit-root tests first.

{pstd}
{bf:A3. Common factor structure}

{phang2}
Cross-sectional dependence must arise from r common factors F_t.
The number r can be specified with {opt nfactors()} or auto-selected
(see {opt nfactors(0)}). Misspecifying r (too low) causes inconsistency;
too high wastes efficiency. Use {opt nfactors(0)} with {opt autormax()}
if r is unknown.

{pstd}
{bf:A4. Stationarity of idiosyncratic error u_it}

{phang2}
After removing the common factors, the idiosyncratic errors u_it must be
stationary (I(0)). They may be serially correlated and cross-sectionally
independent. This is the cointegration condition. The Bartlett kernel
{opt bandwidth()} controls the long-run variance estimate of u_it.

{pstd}
{bf:A5. Factor loadings}

{phang2}
Factor loadings lambda_i are assumed to be heterogeneous across i.
They are allowed to be random or fixed, as long as they are drawn from
a distribution with non-degenerate second moments:
(1/N) sum lambda_i lambda_i' -> Sigma_lambda > 0.

{pstd}
{bf:A6. Common beta (slope homogeneity)}

{phang2}
The cointegrating vector beta is assumed {bf:identical across all units}.
If slopes are heterogeneous, consider pooled mean-group approaches
({helpb xtpmg}). Testing slope homogeneity before using {cmd:cupfm}
is advisable (Pesaran & Yamagata 2008 delta-test).

{pstd}
{bf:A7. Panel dimensions}

{phang2}
Asymptotic theory requires N -> Inf and T -> Inf,
with T/N -> c (finite positive constant) — the "balanced" or "sequential"
limit. In practice, simulation studies show good performance for
N >= 10, T >= 20. Very small panels (N < 5, T < 15) may give
unreliable results.

{pstd}
{bf:A8. I(1) factors (BKN 2009) vs I(0) factors (BK 2005)}

{phang2}
BKN (2009) allows F_t to be I(1) {bf:or} I(0). When F_t ~ I(0),
the model reduces to a standard panel FM regression with
cross-sectional dependence; CupFM remains consistent in both cases.
LSDV is biased only when F_t is I(1).


{marker estimators}{...}
{title:Estimators}

{pstd}
{bf:LSDV} (Least-Squares Dummy Variable / within estimator)

{phang2}
The standard fixed-effects estimator. Eliminates alpha_i by within-unit
demeaning, then regresses demeaned y on demeaned x.
{bf:Biased and inconsistent} when F_t is I(1): the factor component
lambda_i'F_t is not removed by within-demeaning (BKN 2009 Prop. 1).
Included as baseline for comparison.

{pmore}
beta_LSDV = (sum_i X_i'M_F X_i)^{-1} sum_i X_i'M_F Y_i

{pmore}
where M_F is the within-unit annihilator and demeaning uses a pooled
common-mean estimator under the factor structure.

{pstd}
{bf:Bai FM} (Two-step Fully Modified)

{phang2}
Non-iterative FM estimator (BK 2005, Eq. 7-8).
Step 1: regress LSDV to get beta_0 and factor estimates F_hat, Lambda_hat.
Step 2: construct FM correction using Bartlett long-run covariance estimates
from residuals. Applied once (no iteration).
{bf:Consistent} but carries non-negligible finite-sample bias (MC Tables 1-4).

{pstd}
{bf:CupFM} (Continuously-Updated Fully Modified) — {bf:RECOMMENDED}

{phang2}
BKN (2009) Theorem 3, Eq. 16. The recommended estimator.
Iterates the Bai FM procedure:
beta^(j) -> residuals -> PCA -> Omega_hat -> FM correction -> beta^(j+1)
until |Omega_hat^(j) - Omega_hat^(j-1)| < {opt tolerance()} or {opt maxiter()} reached.

{phang2}
{bf:Asymptotically:} sqrt(NT)(beta_CupFM - beta) ->_d N(0, V)
where V = 6*Omega_{uu.x} / Sigma_xx (BKN 2009 Theorem 3).

{phang2}
Exhibits smallest bias in all BKN Monte Carlo experiments.
Convergence typically occurs within 5-10 iterations.

{pstd}
{bf:CupFM-bar} (CupFM with Z-bar instrument)

{phang2}
Variant of CupFM where the instrument matrix uses
Z_bar = x_bar - F_hat * delta_bar instead of X.
This alternative identification within the CupFM framework
may improve small-sample performance in some designs
(BKN 2009, Eq. 16 alternative). Reported as "CupFM-z" in output.

{pstd}
{bf:CupBC} (Continuously-Updated Bias-Corrected)

{phang2}
BKN (2009) Theorem 2. Iterates plain Cup LS (no FM transformation),
then applies the BC correction once at convergence.
BC uses the Bartlett estimate of Omega to subtract the bias term
Delta_{BC} = Omega_{uv} * Omega_{vv}^{-1}.
Performance similar to CupFM in MC studies.

{pstd}
{bf:Summary table:}

    {hline 60}
    Estimator   Correction   Iterates   Consistent if F_t~I(1)
    {hline 60}
    LSDV        none         no         NO
    Bai FM      FM (1-step)  no         yes
    CupFM       FM           yes        yes  (RECOMMENDED)
    CupFM-bar   FM (Z-bar)   yes        yes
    CupBC       BC           yes        yes
    {hline 60}


{marker options}{...}
{title:Options — Detailed Description}

{dlgtab:Factor model}

{phang}
{opt nfactors(#)} specifies the number of common factors r.

{pmore}
If 0 (default), r is selected automatically by minimizing the
Bai & Ng (2002) information criterion:

{pmore}
IC_1(k) = log V(k,F) + k * g(N,T)

{pmore}
where V(k,F) = (NT)^{-1} sum_i sum_t (e_it - lambda_i'F_t)^2 and
g(N,T) = (N+T)/(NT) * log(NT/(N+T)).

{pmore}
The criterion is evaluated for r = 0, 1, ..., {opt autormax()}.
r = 0 is allowed (no common factor structure).

{pmore}
If {opt nfactors()} > 0, the specified r is used directly; no IC computed.

{phang}
{opt autormax(#)} sets the maximum r to consider in auto-selection.
Default 8. Should be set <= min(N,T)/2 for reliable IC computation.
Ignored if {opt nfactors()} > 0.

{dlgtab:Long-run covariance}

{phang}
{opt bandwidth(#)} sets the Bartlett kernel lag truncation M.
The long-run covariance matrix is estimated as:

{pmore}
Omega_hat = (1/T) sum_{j=-(M)}^{M} w_j * sum_t z_t z_{t-j}'

{pmore}
where w_j = 1 - |j|/(M+1) (Bartlett weights), z_t = (u_hat_t, v_hat_t').
BKN (2009) Monte Carlo uses M = 5 and finds results stable.
Larger M reduces bias but increases variance of Omega_hat.
A common rule is M = floor(4*(T/100)^{2/9}).
Default 5.

{phang}
{opt kernel(kname)} selects the kernel function.

{pmore}
{opt bartlett} (default): w_j = 1 - |j|/(M+1). Positive semi-definite.
{opt parzen}: smoother taper. Both give consistent Omega_hat as M -> Inf.

{dlgtab:Iteration control}

{phang}
{opt maxiter(#)} sets the maximum number of Cup iterations.
Default 20 (matching the BKN GAUSS code). Convergence criterion: 
|Omega_{u.x}^(j) - Omega_{u.x}^(j-1)| < {opt tolerance()}.
If convergence is not achieved, {cmd:e(converged)} = 0 and a warning is printed.
Stored: {cmd:e(niter)} = actual iterations performed.

{phang}
{opt tolerance(#)} convergence threshold. Default 0.0001.
Applied to the conditional long-run variance Omega_{uu.x} = Omega_uu - Omega_uv * Omega_vv^{-1} * Omega_vu.
Tighter tolerances may require more iterations but give more precise estimates.

{dlgtab:Output control}

{phang}
{opt noicsummary} suppresses the "Factor Structure Diagnostics" table
(Bai-Ng IC values, factor loading column means, bandwidth).
Does {bf:not} suppress the estimation results table.

{phang}
{opt noisily} activates verbose Mata output: prints convergence progress,
Omega matrices, and intermediate factor estimates at each iteration.
Useful for debugging; not recommended for routine use.

{dlgtab:Visualization}

{phang}
{opt plot} generates all three publication-quality plots (equivalent
to specifying {opt plotcoef}, {opt plotfactors}, and {opt plotloadings} together).
Plots are exported as PNG (1200x700 pixels for coef/factors, 1000x700 for loadings).

{phang}
{opt plotcoef} produces a coefficient comparison forest plot for each regressor.
Shows the point estimates with 95% CI for all five estimators,
color-coded and overlaid for direct comparison.

{phang}
{opt plotfactors} produces a time-series plot of the estimated common factors
F_hat_1,...,F_hat_r, using r color-coded lines.

{phang}
{opt plotloadings} produces either (a) a bar chart of lambda_i1 across N units
if r=1, or (b) a scatter plot of lambda_i2 vs lambda_i1 (labelled by unit i)
if r>=2.

{phang}
{opt saving(filename)} sets the base filename prefix for saved PNG files and
spreadsheet/LaTeX exports. No extension should be included.
Default: "cupfm". Plot files will be named
{it:filename}_coef_{it:varname}.png, {it:filename}_factors.png, {it:filename}_loadings.png.

{dlgtab:Export}

{phang}
{opt export(fmt)} exports the estimation results table to an external file.

{pmore}
{opt excel} — writes an .xlsx file with formatted results tables
(requires Stata 14+ and the {cmd:putexcel} facility).

{pmore}
{opt latex} — writes a .tex file with booktabs-formatted table,
suitable for direct inclusion in LaTeX documents.

{pmore}
{opt csv} — writes a plain .csv file with all five estimators' results.

{pmore}
{opt all} — writes all three formats simultaneously.

{pmore}
Files are named {it:saving}_cupfm.xlsx, .tex, .csv.
If {opt saving()} is not specified, defaults to "cupfm_results".


{marker cautions}{...}
{title:Cautions and Important Notes}

{pstd}
{bf:C1. No cointegration pre-test}

{phang2}
{cmd:cupfm} assumes the variables are cointegrated. Spurious results will occur
if y and x are {bf:not} cointegrated. Always test for panel cointegration first
using {helpb xtpedroni} or Westerlund (2007) tests before using {cmd:cupfm}.

{pstd}
{bf:C2. LSDV is biased — do not use for inference}

{phang2}
The LSDV estimator is systematically biased upward/downward when F_t ~ I(1).
It is shown in the output table for reference only. Do not base conclusions on it.
Bias grows with r and the signal-to-noise ratio of F_t.

{pstd}
{bf:C3. Bandwidth choice affects all estimators}

{phang2}
All five estimators depend on the Bartlett estimate of Omega.
An inappropriate bandwidth M can cause inference distortions.
Check robustness by re-running with different {opt bandwidth()} values
(e.g., M = 3, 5, 8, 10). Results should be stable if the model is correctly specified.

{pstd}
{bf:C4. Factor number misspecification}

{phang2}
Underspecifying r (too few factors) leaves correlated residuals and produces
inconsistent estimates — worse than LSDV in finite samples.
Overspecifying r wastes degrees of freedom but is less harmful.
When in doubt, use {opt nfactors(0)} (auto-selection) or compare results
across adjacent values of r.

{pstd}
{bf:C5. Convergence and maxiter}

{phang2}
If {cmd:e(converged)} = 0, CupFM and CupBC reached {opt maxiter()} without
converging. This can happen with poorly conditioned data (near-singular Omega),
extreme serial correlation, or misspecified r.
Try increasing {opt maxiter()}, changing {opt bandwidth()}, or specifying r explicitly.
The printed "CupFM iterations" value shows how many steps were taken.

{pstd}
{bf:C6. Small N or small T}

{phang2}
Asymptotic normality requires both N and T -> Inf. With N < 10 or T < 20,
the distribution of t-statistics may be non-normal. Significance stars
(based on 1.96 and 2.576 critical values) should be interpreted cautiously.

{pstd}
{bf:C7. Balanced panel requirement}

{phang2}
An {bf:unbalanced} panel will produce an error. If your data has gaps,
consider: (a) filling gaps with interpolation, (b) using a balanced subsample,
or (c) using estimators designed for unbalanced panels.

{pstd}
{bf:C8. Slope homogeneity}

{phang2}
{cmd:cupfm} imposes a common beta across all i. If true slopes vary,
the "average" estimate from CupFM may mask economically important
heterogeneity. Pre-test with the Pesaran-Yamagata (2008) delta-test.

{pstd}
{bf:C9. The level option is fixed at 95%}

{phang2}
Confidence intervals and significance stars are based on a fixed 95% CI.
The option {cmd:level()} is reserved by Stata's eclass system and cannot
be passed to {cmd:cupfm}. All CIs use z_{0.975} = 1.960.

{pstd}
{bf:C10. Plot export in batch mode}

{phang2}
Graphical output (PNG plots) requires that Stata can access a display.
In server batch mode without a display, use {cmd:capture} around the
{cmd:cupfm} call with {opt plot}, or suppress plots and use {opt export()}
for tabular results instead.


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:cupfm} stores the following in {cmd:e()}.
The {bf:primary} result {cmd:e(b)} and {cmd:e(V)} correspond to {bf:CupFM}.

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: {bf:Scalars}}{p_end}
{synopt:{cmd:e(Nobs)}}total observations N*T{p_end}
{synopt:{cmd:e(Ng)}}number of cross-section units N{p_end}
{synopt:{cmd:e(Tperiods)}}number of time periods T{p_end}
{synopt:{cmd:e(nfactors)}}number of common factors r used in estimation{p_end}
{synopt:{cmd:e(bw)}}bandwidth parameter M{p_end}
{synopt:{cmd:e(maxiter)}}maximum iterations setting{p_end}
{synopt:{cmd:e(niter)}}actual CupFM iterations performed{p_end}
{synopt:{cmd:e(converged)}}1 = CupFM converged before maxiter; 0 = reached maxiter{p_end}
{synopt:{cmd:e(cvar_cupfm)}}conditional long-run variance Omega_{uu.x} at CupFM convergence{p_end}
{synopt:{cmd:e(cvar_cupbc)}}conditional long-run variance Omega_{uu.x} at CupBC convergence{p_end}
{synopt:{cmd:e(level)}}confidence level (always 95){p_end}

{p2col 5 24 26 2: {bf:Matrices}}{p_end}
{synopt:{cmd:e(b)}}1×k CupFM coefficient row vector (primary result){p_end}
{synopt:{cmd:e(V)}}k×k CupFM variance-covariance matrix (diagonal: se_j^2){p_end}
{synopt:{cmd:e(beta_lsdv)}}1×k LSDV coefficients{p_end}
{synopt:{cmd:e(beta_baifm)}}1×k Bai FM coefficients{p_end}
{synopt:{cmd:e(beta_cupfm)}}1×k CupFM coefficients{p_end}
{synopt:{cmd:e(beta_cupfm2)}}1×k CupFM-bar coefficients{p_end}
{synopt:{cmd:e(beta_cupbc)}}1×k CupBC coefficients{p_end}
{synopt:{cmd:e(tstat_lsdv)}}1×k LSDV t-statistics{p_end}
{synopt:{cmd:e(tstat_baifm)}}1×k Bai FM t-statistics{p_end}
{synopt:{cmd:e(tstat_cupfm)}}1×k CupFM t-statistics{p_end}
{synopt:{cmd:e(tstat_cupfm2)}}1×k CupFM-bar t-statistics{p_end}
{synopt:{cmd:e(tstat_cupbc)}}1×k CupBC t-statistics{p_end}
{synopt:{cmd:e(F_hat)}}T×r matrix of estimated common factors F_hat{p_end}
{synopt:{cmd:e(Lambda)}}N×r matrix of estimated factor loadings Lambda_hat{p_end}
{synopt:{cmd:e(Omega)}}(k+1)×(k+1) long-run covariance Omega_hat (CupFM){p_end}
{synopt:{cmd:e(Omega_bc)}}(k+1)×(k+1) long-run covariance Omega_hat (CupBC){p_end}
{synopt:{cmd:e(Aik)}}N×N rotation weight matrix a_ik{p_end}

{p2col 5 24 26 2: {bf:Strings}}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:cupfm}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed by the user{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(panelvar)}}panel unit variable (from xtset){p_end}
{synopt:{cmd:e(timevar)}}time variable (from xtset){p_end}
{synopt:{cmd:e(kernel)}}kernel used for long-run covariance{p_end}
{synopt:{cmd:e(estimator)}}{cmd:CupFM}{p_end}
{synopt:{cmd:e(papers)}}bibliographic references (BKN 2009, BK 2005){p_end}
{synopt:{cmd:e(vcetype)}}variance type description{p_end}
{p2colreset}{...}


{marker postestimation}{...}
{title:Post-Estimation}

{pstd}
After {cmd:cupfm}, all standard {cmd:e()}-retrieval commands work on the
primary CupFM result ({cmd:e(b)}, {cmd:e(V)}):

{phang2}{cmd:. matrix list e(b)}{p_end}
{phang2}{cmd:. matrix list e(V)}{p_end}
{phang2}{cmd:. ereturn list}{p_end}

{pstd}
To retrieve individual estimator results:

{phang2}{cmd:. matrix cupfm_coef = e(beta_cupfm)}{p_end}
{phang2}{cmd:. matrix cupbc_coef = e(beta_cupbc)}{p_end}
{phang2}{cmd:. matrix lsdv_coef  = e(beta_lsdv)}{p_end}

{pstd}
To extract the estimated common factors for further analysis:

{phang2}{cmd:. matrix F = e(F_hat)}{p_end}
{phang2}{cmd:. svmat F, names(factor)}{p_end}

{pstd}
To extract factor loadings:

{phang2}{cmd:. matrix L = e(Lambda)}{p_end}
{phang2}{cmd:. svmat L, names(lambda)}{p_end}

{pstd}
Standard errors (from {cmd:e(V)}) are constructed as:

{pmore}
se_j = |beta_j / t_j|

{pstd}
(back-computed from stored t-statistics). Confidence intervals:

{pmore}
CI_j = [beta_j +/- 1.960 * se_j]    (95% level, fixed)

{pstd}
{bf:Note:} {cmd:predict} is not supported after {cmd:cupfm}.
Residuals can be computed manually: {cmd:gen resid = y - e(b)[1,1]*x1 - ...}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic usage with auto-selected factors}

{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. cupfm y x1}{p_end}

{pstd}
{bf:Example 2: Specify 2 factors, bandwidth 10, max 30 iterations}

{phang2}{cmd:. cupfm y x1 x2, nfactors(2) bandwidth(10) maxiter(30)}{p_end}

{pstd}
{bf:Example 3: Auto-select r up to 5 factors, suppress IC table}

{phang2}{cmd:. cupfm y x1 x2, nfactors(0) autormax(5) noicsummary}{p_end}

{pstd}
{bf:Example 4: With all plots, save PNG and export to all formats}

{phang2}{cmd:. cupfm y x1 x2, nfactors(2) plot saving(myresults) export(all)}{p_end}

{pstd}
{bf:Example 5: Individual plots}

{phang2}{cmd:. cupfm y x1 x2, nfactors(2) plotcoef saving(coef_only)}{p_end}
{phang2}{cmd:. cupfm y x1 x2, nfactors(2) plotfactors saving(factors_only)}{p_end}

{pstd}
{bf:Example 6: Reproduce BKN (2009) Monte Carlo design}

{phang2}{cmd:. cupfm y x1, nfactors(1) bandwidth(5) maxiter(20)}{p_end}

{pstd}
{bf:Example 7: Post-estimation — access all coefficients}

{phang2}{cmd:. cupfm y x1 x2, nfactors(2)}{p_end}
{phang2}{cmd:. matrix list e(beta_cupfm)}{p_end}
{phang2}{cmd:. matrix list e(beta_lsdv)}{p_end}
{phang2}{cmd:. scalar bias = e(beta_cupfm)[1,1] - e(beta_lsdv)[1,1]}{p_end}
{phang2}{cmd:. di "Bias reduction (x1): " %8.4f bias}{p_end}

{pstd}
{bf:Example 8: Extract factors for external use}

{phang2}{cmd:. cupfm y x1, nfactors(2)}{p_end}
{phang2}{cmd:. matrix F = e(F_hat)}{p_end}
{phang2}{cmd:. svmat F, names(f)}{p_end}
{phang2}{cmd:. tsline f1 f2, legend(label(1 "Factor 1") label(2 "Factor 2"))}{p_end}

{pstd}
{bf:Example 9: Robustness check across bandwidths}

{phang2}{cmd:. foreach bw in 3 5 8 10 {c -(}}{p_end}
{phang2}{cmd:.   cupfm y x1, nfactors(2) bandwidth(`bw') noicsummary}{p_end}
{phang2}{cmd:.   di "BW=`bw': beta=" %6.4f e(beta_cupfm)[1,1]}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
{bf:Example 10: Parzen kernel}

{phang2}{cmd:. cupfm y x1 x2, nfactors(2) kernel(parzen) bandwidth(8)}{p_end}


{marker references}{...}
{title:References}

{marker BKN2009}{...}
{phang}
Bai, J., Kao, C. & Ng, S. (2009).
Panel cointegration with global stochastic trends.
{it:Journal of Econometrics}, 149(1), 82-99.
{browse "https://doi.org/10.1016/j.jeconom.2008.10.012"}
{p_end}

{marker BK2005}{...}
{phang}
Bai, J. & Kao, C. (2005).
On the estimation and inference of a panel cointegration model
with cross-sectional dependence.
CPR Working Paper No. 75, Syracuse University.
{browse "https://ssrn.com/abstract=1815227":SSRN-1815227}
{p_end}

{marker BN2002}{...}
{phang}
Bai, J. & Ng, S. (2002).
Determining the number of factors in approximate factor models.
{it:Econometrica}, 70(1), 191-221.
{browse "https://doi.org/10.1111/1468-0262.00273"}
{p_end}

{phang}
Phillips, P.C.B. & Hansen, B.E. (1990).
Statistical inference in instrumental variables regression with I(1) processes.
{it:Review of Economic Studies}, 57(1), 99-125.
{p_end}

{phang}
Phillips, P.C.B. & Moon, H.R. (1999).
Linear regression limit theory for nonstationary panel data.
{it:Econometrica}, 67(5), 1057-1111.
{p_end}

{phang}
Pesaran, M.H. & Yamagata, T. (2008).
Testing slope homogeneity in large panels.
{it:Journal of Econometrics}, 142(1), 50-93.
{p_end}

{phang}
Westerlund, J. (2007).
Testing for error correction in panel data.
{it:Oxford Bulletin of Economics and Statistics}, 69(6), 709-748.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Package: {stata "search cupfm":search cupfm}
{p_end}

{pstd}
{it:This package implements all five estimators exactly as coded in the official}
{it:GAUSS source code ({bf:bkn} folder) distributed by Bai, Kao & Ng (2009)}{break}
{it:and Bai & Kao (2005). Numerical results are verified against the GAUSS output.}
{p_end}

{pstd}
{it:Bug reports and suggestions: merwanroudane920@gmail.com}
{p_end}
