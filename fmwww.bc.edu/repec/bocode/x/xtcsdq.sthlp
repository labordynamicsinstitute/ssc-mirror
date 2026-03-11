{smcl}
{* *! version 1.3.0  07mar2026}{...}
{viewerjumpto "Syntax" "xtcsdq##syntax"}{...}
{viewerjumpto "Description" "xtcsdq##description"}{...}
{viewerjumpto "Options" "xtcsdq##options"}{...}
{viewerjumpto "Remarks" "xtcsdq##remarks"}{...}
{viewerjumpto "Practical workflow" "xtcsdq##workflow"}{...}
{viewerjumpto "Estimator compatibility" "xtcsdq##compatibility"}{...}
{viewerjumpto "Examples" "xtcsdq##examples"}{...}
{viewerjumpto "Stored results" "xtcsdq##stored"}{...}
{viewerjumpto "References" "xtcsdq##references"}{...}
{viewerjumpto "Authors" "xtcsdq##authors"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:xtcsdq} {hline 2}}Tests of no cross-sectional error dependence
in panel quantile regressions{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Mode 1} {hline 2} Internal estimation (runs QR internally, tests residuals):

{p 8 16 2}
{cmd:xtcsdq} {depvar} {indepvars} {ifin}{cmd:,}
{cmd:quantiles(}{it:numlist}{cmd:)}
[{it:options}]

{pstd}
{bf:Mode 2} {hline 2} User-supplied residuals (from any QR estimator):

{p 8 16 2}
{cmd:xtcsdq}{cmd:,}
{cmd:residuals(}{it:varlist}{cmd:)}
{cmd:quantiles(}{it:numlist}{cmd:)}
[{it:options}]

{pstd}
{bf:Mode 3} {hline 2} Post-estimation (reads model from last {cmd:e()} results):

{p 8 16 2}
{cmd:xtcsdq}{cmd:,}
{cmd:post}
{cmd:quantiles(}{it:numlist}{cmd:)}
[{it:options}]


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt q:uantiles(numlist)}}list of quantiles in (0,1) at which to test{p_end}
{synopt:{opt r:esiduals(varlist)}}(Mode 2) pre-computed QR residuals, one variable per quantile{p_end}
{synopt:{opt post}}(Mode 3) auto-generate residuals from last estimation command{p_end}
{synopt:{opt i:ndividual}}(Mode 1 only) estimate QR per unit instead of pooled FE{p_end}
{synopt:{opt b:andwidth(#)}}KDE bandwidth; default = 0.35*(NT)^(-0.2){p_end}
{synopt:{opt noc:orrection}}report only T_tau without finite-sample correction{p_end}
{synoptline}
{p 4 6 2}* {opt quantiles()} is required in all modes.{p_end}
{p 4 6 2}Panel data must be declared using {helpb xtset} before running {cmd:xtcsdq}.{p_end}
{p 4 6 2}The panel must be {bf:strongly balanced}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtcsdq} tests whether the {bf:residuals} of a panel quantile regression
exhibit cross-sectional dependence (CSD), based on
Demetrescu, Hosseinkouchack & Rodrigues (2023).

{pstd}
{bf:This is a residual-based diagnostic test.}
It examines pairwise correlations among the {it:quantile regression errors}
after fitting a QR model. The variables you supply define the model
specification — they are {bf:not} tested directly.

{dlgtab:Three modes}

{phang}
{bf:Mode 1} ({it:varlist}): The command estimates a panel QR internally
(pooled FE with unit dummies, or individual-unit), extracts residuals,
then tests them for CSD. {bf:The previous estimation command is irrelevant}
— Mode 1 always runs its own QR. Use this mode after {cmd:mmqreg} or when
you simply want a quick diagnostic.{p_end}

{phang}
{bf:Mode 2} ({opt residuals()}): You provide pre-computed QR residuals.
This is the most transparent mode: you control exactly which residuals
are tested. One variable per quantile.{p_end}

{phang}
{bf:Mode 3} ({opt post}): The command reads {cmd:e(depvar)} and
{cmd:e(indepvars)} from the previous estimation, re-runs per-panel QR
to generate residuals, then tests them.
Works after {cmd:xtpqardl}, {cmd:xtcspqardl}, {cmd:qreg}, {cmd:sqreg},
{cmd:bsqreg}, and any command storing {cmd:e(depvar)}.{p_end}

{dlgtab:Why residuals, not raw variables?}

{pstd}
Testing raw {it:y} or {it:x} for CSD just asks "are the series correlated?"
— the answer is usually {it:yes} with macroeconomic data.

{pstd}
The paper's test asks a different question: {bf:"after controlling for x,
is there remaining dependence in the errors?"} If yes, the model is
misspecified: unobserved common factors contaminate the error term.

{pstd}
{bf:Unlike OLS}, CSD in QR errors causes {bf:coefficient bias}
(not just inference distortion). This makes the CSD test essential
before interpreting panel QR results.

{pstd}
{bf:Decision rule:}

{p 8 12 2}
{bf:Fail to reject H0} (large p-value): No CSD → model is adequate.{p_end}

{p 8 12 2}
{bf:Reject H0} (small p-value): CSD → switch to factor-augmented estimator
({cmd:xtcspqardl} or {cmd:qregpd}).{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt quantiles(numlist)} specifies the quantile(s) at which to test.
Each value must be strictly between 0 and 1.
Example: {cmd:quantiles(0.1 0.25 0.5 0.75 0.9)}.

{dlgtab:Mode selection}

{phang}
{opt residuals(varlist)} activates {bf:Mode 2}. Each variable contains
QR residuals at the corresponding quantile. The number of variables must
equal the number of quantiles.

{phang}
{opt post} activates {bf:Mode 3}. The command reads {cmd:e(depvar)} and
{cmd:e(indepvars)} or {cmd:e(b)} column names from the last estimation.

{pmore}
{bf:Important:} The regressor list is saved {it:before} the internal QR loop,
so the previous estimation's {cmd:e()} is not overwritten.

{dlgtab:Estimation}

{phang}
{opt individual} (Mode 1 only) estimates a separate QR for each
cross-sectional unit (heterogeneous slopes), corresponding to Proposition 2.
The default is pooled fixed-effects QR with unit dummies (Proposition 1).

{pmore}
{bf:Minimum sample requirement:} Individual-unit QR requires
T >> k (number of regressors). With T=15 and k=4,
QR at extreme quantiles (0.25, 0.75) will fail. In this case,
use the default pooled mode or {opt nocorrection}.

{phang}
{opt bandwidth(#)} KDE bandwidth for estimating f(q_tau).
Default: 0.35*(NT)^(-0.2). Larger values smooth more.

{phang}
{opt nocorrection} suppresses the corrected statistic T~_tau
and reports only T_tau. {bf:Recommended when T < 50}, because the
finite-sample correction may overcorrect in small samples.


{marker remarks}{...}
{title:Remarks}

{dlgtab:Test statistics}

{pstd}
Let û denote the QR residuals. The uncorrected statistic is:

{p 8 8 2}
T_tau = [1/sqrt(N(N-1))] × Σ(T × ρ²_ij − 1)

{pstd}
where ρ_ij is the pairwise correlation between demeaned residuals of
units i and j. Under H0 (no CSD), T_tau →d N(0,1).

{pstd}
The corrected statistic adjusts for finite-sample bias:

{p 8 8 2}
T~_tau = T_tau − sqrt(N(N-1)/2T) − [τ(1−τ)/f²] × sqrt(N(N-1)/T)

{pstd}
When K > 1 quantiles are tested, the portmanteau statistic
M_K = (1/K) × Σ T_tau_k provides a joint test.

{dlgtab:Pooled vs individual}

{pstd}
{bf:Pooled FE} (default): Runs {cmd:qreg y x1 x2 i.id} on all N×T
observations together. Imposes {it:homogeneous slopes} across units,
with unit-specific intercepts (fixed effects). Corresponds to
{it:Proposition 1} in the paper.

{pstd}
{bf:Individual-unit} ({opt individual}): Runs {cmd:qreg y x1 x2} separately
for each unit. Allows {it:heterogeneous slopes}. Requires large T.
Corresponds to {it:Proposition 2}.

{pstd}
Post-estimation mode (Mode 3) uses per-panel QR, which is equivalent to
individual-unit estimation. Individual = External = Post (they all give
the same test statistic when the same regressors are used).

{dlgtab:Sample size guidance}

        {col 5}{bf:T range}          {col 25}{bf:Recommendation}
        {col 5}{hline 55}
        {col 5}T ≥ 100            {col 25}Use default (both T_tau and T~_tau)
        {col 5}50 ≤ T < 100       {col 25}Default OK; T~_tau slightly conservative
        {col 5}15 ≤ T < 50        {col 25}Use {cmd:nocorrection}; rely on T_tau only
        {col 5}T < 15             {col 25}Use pooled mode only; T too small for per-panel QR
        {col 5}{hline 55}


{marker workflow}{...}
{title:Practical workflow for researchers}

{pstd}
{bf:Step 1: Estimate your panel QR model.}{p_end}

{phang2}
{cmd:. xtpqardl y D.x1, lr(L.y x1) tau(0.25 0.50 0.75) pmg}{p_end}

{pstd}
{bf:Step 2: Test for CSD in the residuals.}{p_end}

{phang2}
{cmd:. xtcsdq, post quantiles(0.25 0.50 0.75)}{p_end}

{pstd}
{bf:Step 3: Interpret the result.}{p_end}

{p 8 12 2}
• If H0 is {bf:not rejected}: your model is fine.{p_end}

{p 8 12 2}
• If H0 is {bf:rejected}: switch to a CSD-robust estimator:{p_end}

{phang2}
{cmd:. xtcspqardl y D.x1, lr(L.y x1) tau(0.25 0.50 0.75) qccemg}{p_end}

{pstd}
{bf:Step 4: Verify the fix.}{p_end}

{phang2}
{cmd:. xtcsdq, post quantiles(0.25 0.50 0.75)}{p_end}

{pstd}
If CSD persists after {cmd:xtcspqardl}, increase cross-sectional
average lags: {cmd:cr_lags(5)}.


{marker compatibility}{...}
{title:Estimator compatibility}

{pstd}
{it:Residual extraction reference for panel QR commands:}

        {col 5}{bf:Command}           {col 28}{bf:Syntax to get residuals}              {col 68}{bf:Notes}
        {col 5}{hline 75}
        {col 5}{cmd:qreg}              {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:sqreg}             {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:bsqreg}            {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:xtqreg}            {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:qregpd}            {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:rifhdreg}          {col 28}{cmd:predict r, residuals}                {col 68}works directly
        {col 5}{cmd:mmqreg}            {col 28}use {cmd:xtcsdq} Mode 1                  {col 68}{bf:predict not supported}
        {col 5}{cmd:ivqreg}            {col 28}{cmd:gen r = y - xb}                     {col 68}manual computation
        {col 5}{cmd:xtpqardl}          {col 28}use {cmd:xtcsdq, post}                   {col 68}Mode 3
        {col 5}{cmd:xtcspqardl}        {col 28}use {cmd:xtcsdq, post}                   {col 68}Mode 3
        {col 5}{hline 75}

{dlgtab:Notes on mmqreg}

{pstd}
{cmd:mmqreg} (Rios-Avila, 2020) does not have its own {cmd:predict} program.
Stata's default {cmd:predict} does not work after it — neither {cmd:predict, res}
nor {cmd:predict, residuals}. This is because {cmd:mmqreg} estimates a
location-scale model with multiple equation names in {cmd:e(b)}.

{pstd}
{bf:Solution:} Use {cmd:xtcsdq} in Mode 1 (the command runs its own
pooled FE QR internally):

{phang2}
{cmd:. mmqreg y x1 x2, quantile(25 50 75) absorb(id)}{p_end}
{phang2}
{cmd:. xtcsdq y x1 x2, quantiles(0.25 0.50 0.75)}{p_end}

{pstd}
Note: Mode 1 runs its own {cmd:qreg y x1 x2 i.id} internally —
it does not use {cmd:mmqreg}'s results. The test statistic is
computed from the pooled FE QR residuals, not from {cmd:mmqreg}'s
location-scale residuals.

{dlgtab:Notes on post-estimation mode}

{pstd}
In Mode 3, {cmd:xtcsdq} re-runs per-panel {cmd:qreg} internally using
the regressors from the previous estimation. The test result is based
on these per-panel QR residuals, not on the original estimator's residuals.

{pstd}
This means: if you run {cmd:qreg}, {cmd:sqreg}, or {cmd:bsqreg} before
{cmd:xtcsdq, post} with the same regressors, you get {it:identical}
test statistics — because all three produce the same per-panel QR
residuals for testing.

{pstd}
The results {it:will} differ between pooled FE (Mode 1 default) and
per-panel (Mode 1 {opt individual}, Mode 3, Mode 2 with per-panel
residuals) because these are {it:different models}:

        {col 5}{bf:Method}                {col 35}{bf:Model}
        {col 5}{hline 60}
        {col 5}Mode 1 (default)          {col 35}Homogeneous slopes + FE dummies
        {col 5}Mode 1 ({opt individual})  {col 35}Heterogeneous slopes per unit
        {col 5}Mode 3 ({opt post})        {col 35}Per-panel QR (= heterogeneous)
        {col 5}{hline 60}

{pstd}
This is expected behavior: different models produce different residuals,
hence different test statistics. The CSD test is about the
{bf:model specification}, not the specific estimator.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}{bf:Example 1: Quick diagnostic after mmqreg (Mode 1)}{p_end}

{pstd}Estimate a location-scale QR, then run CSD test using Mode 1
(the command runs its own pooled FE QR for testing):{p_end}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. drop if missing(ln_wage, age, tenure, hours)}{p_end}
{phang2}{cmd:. bysort idcode: gen nobs = _N}{p_end}
{phang2}{cmd:. su nobs, meanonly}{p_end}
{phang2}{cmd:. keep if nobs == r(max)}{p_end}
{phang2}{cmd:. drop nobs}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. mmqreg ln_wage age tenure hours, quantile(25 50 75) absorb(idcode)}{p_end}
{phang2}{cmd:. xtcsdq ln_wage age tenure hours, quantiles(0.25 0.50 0.75)}{p_end}

    {hline}
{pstd}{bf:Example 2: After xtpqardl (Mode 3 post-estimation)}{p_end}

{pstd}Panel quantile ARDL → CSD diagnostic:{p_end}

{phang2}{cmd:. xtpqardl y D.x1, lr(L.y x1) tau(0.2 0.5 0.8) pmg}{p_end}
{phang2}{cmd:. xtcsdq, post quantiles(0.2 0.5 0.8)}{p_end}

    {hline}
{pstd}{bf:Example 3: After xtcspqardl (Mode 3 — verify CSD removed)}{p_end}

{phang2}{cmd:. xtcspqardl y D.x1, lr(L.y x1) tau(0.2 0.5 0.8) qccemg}{p_end}
{phang2}{cmd:. xtcsdq, post quantiles(0.2 0.5 0.8)}{p_end}

{pstd}If CSD persists, increase CSA lags: {cmd:xtcspqardl ..., cr_lags(5)}.{p_end}

    {hline}
{pstd}{bf:Example 4: After qreg (Mode 3)}{p_end}

{phang2}{cmd:. qreg y x1 x2, quantile(50)}{p_end}
{phang2}{cmd:. xtcsdq, post quantiles(0.25 0.50 0.75)}{p_end}

    {hline}
{pstd}{bf:Example 5: External residuals (Mode 2)}{p_end}

{pstd}Manual residual computation for full control:{p_end}

{phang2}{cmd:. qui qreg y x1 x2 i.id, quantile(50)}{p_end}
{phang2}{cmd:. predict r_50, residuals}{p_end}
{phang2}{cmd:. xtcsdq, residuals(r_50) quantiles(0.50)}{p_end}

    {hline}
{pstd}{bf:Example 6: Direct Mode 1 with options}{p_end}

{phang2}{cmd:. xtcsdq y x1 x2, quantiles(0.25 0.50 0.75)}{break}
{cmd:                                           }{it:/* pooled FE, default */}{p_end}

{phang2}{cmd:. xtcsdq y x1 x2, quantiles(0.50) individual}{break}
{cmd:                                           }{it:/* per-unit QR */}{p_end}

{phang2}{cmd:. xtcsdq y x1 x2, quantiles(0.25 0.50 0.75) nocorrection}{break}
{cmd:                                           }{it:/* T<50: skip T~_tau */}{p_end}

    {hline}
{pstd}{bf:Example 7: Full comparison across modes (simulated data)}{p_end}

{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 1000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/50)}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}
{phang2}{cmd:. xtset id t}{p_end}
{phang2}{cmd:. gen double x1 = rnormal()}{p_end}
{phang2}{cmd:. gen double x2 = rnormal()}{p_end}
{phang2}{cmd:. bysort t: gen double shock = rnormal() if _n==1}{p_end}
{phang2}{cmd:. bysort t: replace shock = shock[1]}{p_end}
{phang2}{cmd:. gen double y = 1 + x1 + 0.5*x2 + 0.3*shock + rnormal()}{p_end}

{phang2}{cmd:. * Mode 1: pooled FE}{p_end}
{phang2}{cmd:. xtcsdq y x1 x2, quantiles(0.25 0.50 0.75)}{p_end}

{phang2}{cmd:. * Mode 1: individual}{p_end}
{phang2}{cmd:. xtcsdq y x1 x2, quantiles(0.50) individual}{p_end}

{phang2}{cmd:. * Mode 3: post-estimation after qreg}{p_end}
{phang2}{cmd:. qreg y x1 x2, quantile(50)}{p_end}
{phang2}{cmd:. xtcsdq, post quantiles(0.50)}{p_end}

{pstd}
Expected: CSD is detected (DGP includes common shock 0.3*shock).
Pooled FE and individual give different T_tau because they use
different models (homogeneous vs heterogeneous slopes).{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtcsdq} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of cross-sectional units{p_end}
{synopt:{cmd:r(T)}}number of time periods{p_end}
{synopt:{cmd:r(K)}}number of quantiles{p_end}
{synopt:{cmd:r(bandwidth)}}KDE bandwidth used{p_end}
{synopt:{cmd:r(M_K)}}portmanteau M_K (if K > 1){p_end}
{synopt:{cmd:r(Mtilde_K)}}corrected portmanteau M~_K (if K > 1){p_end}
{synopt:{cmd:r(pval_M)}}p-value of M_K (if K > 1){p_end}
{synopt:{cmd:r(pval_Mc)}}p-value of M~_K (if K > 1){p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(T_tau)}}K × 1 vector of uncorrected test statistics{p_end}
{synopt:{cmd:r(Ttilde_tau)}}K × 1 vector of corrected statistics{p_end}
{synopt:{cmd:r(pval_T)}}K × 1 vector of p-values of T_tau{p_end}
{synopt:{cmd:r(pval_Ttilde)}}K × 1 vector of p-values of T~_tau{p_end}
{synopt:{cmd:r(fhat)}}K × 1 vector of KDE estimates f_hat{p_end}


{marker references}{...}
{title:References}

{phang}
Demetrescu, M., Hosseinkouchack, M., and Rodrigues, P. M. M. (2023).
Tests of no cross-sectional error dependence in panel quantile regressions.
{it:Ruhr Economic Papers}, No. 1041.{p_end}

{phang}
Pesaran, M. H. (2015).
Testing weak cross-sectional dependence in large panels.
{it:Econometric Reviews}, 34(6-10), 1089-1117.{p_end}

{phang}
Machado, J. A. F. and Santos Silva, J. M. C. (2019).
Quantiles via moments.
{it:Journal of Econometrics}, 213(1), 145-173.{p_end}

{phang}
Harding, M., Lamarche, C., and Pesaran, M. H. (2020).
Common correlated effects estimation of heterogeneous dynamic panel
quantile regression models.
{it:Journal of Applied Econometrics}, 35(3), 294-314.{p_end}

{phang}
Rios-Avila, F. (2020).
Recentered influence functions (RIFs) in Stata.
{it:Stata Journal}, 20(1), 51-94.{p_end}


{marker authors}{...}
{title:Authors}

{pstd}
{bf:Dr Merwan Roudane}{p_end}
{pstd}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite as:{p_end}
{phang2}
Roudane, M. (2026). XTCSDQ: Stata module for testing cross-sectional
error dependence in panel quantile regressions.
Available from SSC.{p_end}

{pstd}
Bug reports and suggestions are welcome.{p_end}


{title:Also see}

{p 4 14 2}
Online:
{helpb xtpqardl} (if installed),
{helpb xtcspqardl} (if installed),
{helpb mmqreg} (if installed),
{helpb xtqreg} (if installed),
{helpb qregpd} (if installed),
{helpb qreg},
{helpb xtset}
{p_end}
