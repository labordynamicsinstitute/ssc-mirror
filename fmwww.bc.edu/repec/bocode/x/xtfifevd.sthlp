{smcl}
{* *! version 1.0.0  27feb2026}{...}
{vieweralsosee "xtreg" "help xtreg"}{...}
{vieweralsosee "xthtaylor" "help xthtaylor"}{...}
{vieweralsosee "ivregress" "help ivregress"}{...}
{vieweralsosee "areg" "help areg"}{...}
{vieweralsosee "xtfifevd_graph" "help xtfifevd_graph"}{...}
{viewerjumpto "Syntax" "xtfifevd##syntax"}{...}
{viewerjumpto "Description" "xtfifevd##description"}{...}
{viewerjumpto "Estimators" "xtfifevd##estimators"}{...}
{viewerjumpto "Options" "xtfifevd##options"}{...}
{viewerjumpto "Econometric background" "xtfifevd##background"}{...}
{viewerjumpto "Variance estimation" "xtfifevd##variance"}{...}
{viewerjumpto "Comparison with other estimators" "xtfifevd##comparison"}{...}
{viewerjumpto "Examples" "xtfifevd##examples"}{...}
{viewerjumpto "Stored results" "xtfifevd##stored"}{...}
{viewerjumpto "References" "xtfifevd##references"}{...}
{viewerjumpto "Author" "xtfifevd##author"}{...}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col:{bf:xtfifevd} {hline 2}}Fixed Effects Filtered & Vector Decomposition 
    Estimation for Time-Invariant and Rarely Changing Variables 
    in Panel Data with Unit Fixed Effects{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}{bf:FEVD Estimator (default):}{p_end}

{p 8 17 2}
{cmd:xtfifevd}
{depvar} {it:xvarlist}
{ifin}
{cmd:,} {opt z:invariants(varlist)}
[{it:fevd_options}]

{pstd}{bf:FEF Estimator:}{p_end}

{p 8 17 2}
{cmd:xtfifevd}
{depvar} {it:xvarlist}
{ifin}
{cmd:,} {opt z:invariants(varlist)} {cmd:fef}
[{it:fef_options}]

{pstd}{bf:FEF-IV Estimator:}{p_end}

{p 8 17 2}
{cmd:xtfifevd}
{depvar} {it:xvarlist}
{ifin}
{cmd:,} {opt z:invariants(varlist)} {cmd:iv(}{varlist}{cmd:)}
[{it:fefiv_options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt z:invariants(varlist)}}time-invariant or rarely changing regressors
    whose coefficients are of interest{p_end}

{syntab:Estimator Selection}
{synopt:{opt fef}}use Fixed Effects Filtered (FEF) 2-step estimator
    (Pesaran & Zhou 2016); default is FEVD 3-stage{p_end}
{synopt:{opt iv(varlist)}}instruments for endogenous z-variables;
    implies FEF-IV estimation (Pesaran & Zhou 2016, Eq. 48){p_end}

{syntab:FEVD Options}
{synopt:{opt noi:ntercept2}}omit intercept in FEVD stage 2; reproduces 
    original Plumper-Troeger (2007, Eq. 5); {bf:NOT recommended}{p_end}
{synopt:{opt comp:are}}display comparison table of FEVD raw SEs vs 
    Pesaran-Zhou corrected SEs for time-invariant coefficients{p_end}

{syntab:Diagnostics}
{synopt:{opt bw:ratio}}report between/within standard deviation ratio 
    for each z-variable; high ratio suggests FEVD/FEF advantageous{p_end}

{syntab:SE/Robust}
{synopt:{opt r:obust}}report robust standard errors; labels output as
    {it:Robust Std. Err.} in estimation table (Pesaran-Zhou SEs are robust
    by construction; this option explicitly signals it for papers){p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt replace}}allow overwrite of stored estimation results{p_end}
{synoptline}
{p2colreset}{...}

{p 4 6 2}
Data must be declared as panel data using {cmd:xtset} {it:panelvar} {it:timevar}
before calling {cmd:xtfifevd}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtfifevd} estimates the coefficients of time-invariant and rarely 
changing variables in static panel data models with unit fixed effects.  
Standard fixed-effects (FE) estimation removes all time-invariant regressors 
via the within transformation, making their coefficients unidentifiable.  
{cmd:xtfifevd} solves this problem by implementing three related estimators:

{phang}
{bf:1. FEVD} (Fixed Effects Vector Decomposition): The three-stage procedure 
proposed by Plumper and Troeger (2007, {it:Political Analysis}). Stage 1 
estimates a fixed-effects model, Stage 2 decomposes the estimated unit 
effects into a part explained by the z-variables and an unexplained residual 
h_i, and Stage 3 re-estimates the full model by pooled OLS including h_i.  
{bf:Critical improvement}: This package replaces the inconsistent standard 
errors from stage-3 pooled OLS with the correct Pesaran-Zhou (2016) 
variance estimator.{p_end}

{phang}
{bf:2. FEF} (Fixed Effects Filtered): The two-step estimator of Pesaran and 
Zhou (2016, {it:Econometric Reviews}). Step 1 uses FE to estimate time-varying 
coefficients beta, Step 2 regresses the time-averaged FE residuals on the 
z-variables with an intercept. Pesaran and Zhou (2016, Proposition 3) prove 
that {bf:FEF and FEVD produce identical point estimates} when an intercept is 
included in FEVD Stage 2. The only difference is that FEF uses the correct 
variance estimator.{p_end}

{phang}
{bf:3. FEF-IV} (Fixed Effects Filtered - Instrumental Variables): An IV 
extension of FEF for the case where some or all time-invariant regressors 
are correlated with the unobserved individual effects. External instruments 
are specified via {opt iv()}, and estimation proceeds by 2SLS in the 
cross-section regression. For the traditional Hausman-Taylor approach, 
see Stata's built-in {helpb xthtaylor}.{p_end}

{pstd}
{bf:Why not use the original xtfevd?} The original {cmd:xtfevd} package 
has been removed from SSC. Moreover, Pesaran and Zhou (2016, Section 3.4) 
prove that the stage-3 pooled OLS standard errors used by the original FEVD 
are {bf:inconsistent}, leading to severe size distortions. In their Monte 
Carlo simulations, the FEVD rejection rate at the nominal 5% level ranges 
from {bf:91% to 100%}. This package always uses the correct variance 
estimator, ensuring valid inference.


{marker estimators}{...}
{title:Estimators}

{pstd}
{bf:The Panel Data Model:}

{p 8 8 2}
y_it = alpha + z_i' gamma + x_it' beta + eta_i + epsilon_it,
{space 4}i = 1,...,N;  t = 1,...,T

{pstd}
where y_it is the dependent variable, x_it is a k x 1 vector of time-varying 
regressors, z_i is an m x 1 vector of time-invariant (or rarely changing) 
regressors, eta_i are unobserved individual effects, and epsilon_it are 
idiosyncratic errors with E(epsilon_it | x_is) = 0 for all t,s.

{pstd}
The FE transformation removes both z_i and eta_i, so gamma cannot be 
estimated by {helpb xtreg:xtreg, fe}. The estimators in {cmd:xtfifevd} 
recover gamma using the structure of the FE residuals.

{pstd}
{bf:FEF Estimator} (Pesaran & Zhou 2016, Eq. 4-5):

{p 8 8 2}
Step 1: Compute the FE estimator beta_hat and the FE residuals
{space 4}u_hat_it = y_it - beta_hat' x_it
{space 4}Then average: u_bar_i = T^{-1} sum_t u_hat_it

{p 8 8 2}
Step 2: Regress u_bar_i on z_i {bf:with an intercept} to obtain
{space 4}gamma_hat_FEF = [sum (z_i - z_bar)(z_i - z_bar)']^{-1}
{space 16}* sum (z_i - z_bar)(u_bar_i - u_bar)
{space 4}alpha_hat_FEF = u_bar - gamma_hat' z_bar

{pstd}
{bf:FEVD Estimator} (Plumper & Troeger 2007, Eq. 4-7):

{p 8 8 2}
Stage 1: Same as FEF Step 1.

{p 8 8 2}
Stage 2: Regress u_hat_i on z_i (with or without intercept):
{space 4}u_hat_i = a + z_i' gamma + h_i
{space 4}h_i = unexplained part of unit effects.

{p 8 8 2}
Stage 3: Pooled OLS of y_it on x_it, z_i, and h_i:
{space 4}y_it = a + x_it' beta_tilde + z_i' gamma_tilde + delta * h_i + eps_it

{pstd}
{bf:Proposition 3} (Pesaran & Zhou 2016): When an intercept is included in 
Stage 2, gamma_tilde = gamma_hat_FEF (identical point estimates), 
beta_tilde = beta_hat_FE, and delta_tilde = 1, exactly.

{pstd}
{bf:Proposition 4}: Without an intercept in Stage 2 (the original Plumper-Troeger 
procedure), gamma_tilde is in general biased and inconsistent.

{pstd}
{bf:FEF-IV Estimator} (Pesaran & Zhou 2016, Eq. 48):

{p 8 8 2}
For endogenous z_i (correlated with eta_i), use instruments r_i:
{space 4}gamma_hat_FEF-IV = (Q_zr Q_rr^{-1} Q_zr')^{-1} Q_zr Q_rr^{-1} Q_r_ubar
{space 4}(standard 2SLS of u_bar_i on z_i using instruments r_i)

{pstd}
The instruments r_i must satisfy: (a) correlation with z_i (relevance), 
and (b) no correlation with eta_i (exogeneity). The number of instruments 
must be at least as large as the number of z-variables.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt zinvariants(varlist)} specifies the time-invariant or rarely changing 
regressors. These are the variables whose coefficients (gamma) cannot be 
estimated by standard FE. Time-invariant means z_it = z_i for all t 
(e.g., gender, ethnicity, geography). Rarely changing means the within 
variation is small relative to the between variation. Use the {opt bwratio} 
option to assess this.

{dlgtab:Estimator Selection}

{phang}
{opt fef} requests the FEF (Fixed Effects Filtered) estimator of Pesaran 
and Zhou (2016). This is a two-step procedure that produces identical point 
estimates to FEVD (when an intercept is in Stage 2) but presents results 
in a cleaner two-equation format. The default is FEVD 3-stage.

{phang}
{opt iv(varlist)} specifies external instruments for endogenous 
time-invariant regressors and triggers the FEF-IV estimator. The instruments 
must be: (i) correlated with the z-variables (first-stage relevance), and 
(ii) uncorrelated with the individual effects eta_i (exogeneity). The 
number of instruments must be >= the number of z-variables. If the z-variables 
are exogenous (uncorrelated with eta_i), the standard FEF estimator (without 
instruments) is consistent and more efficient.

{dlgtab:FEVD Options}

{phang}
{opt nointercept2} omits the intercept in the FEVD Stage 2 regression. This 
reproduces the {bf:original} procedure of Plumper and Troeger (2007, Eq. 5) 
exactly. However, Pesaran and Zhou (2016, Proposition 4) prove that this 
version is {bf:biased and inconsistent} unless 
alpha * E[(sum z_i z_i')^{-1} sum z_i] = 0, which fails in general.  
A warning is displayed. This option is provided for replication purposes only.

{phang}
{opt compare} displays a side-by-side comparison table for the 
time-invariant coefficients showing:
{p 12 12 2}(1) Point estimates (identical for FEVD and FEF){p_end}
{p 12 12 2}(2) FEVD raw SEs (from stage-3 pooled OLS — inconsistent){p_end}
{p 12 12 2}(3) Pesaran-Zhou corrected SEs (consistent){p_end}
{p 12 12 2}(4) t-statistics from both SEs{p_end}
{p 8 8 2}
This option vividly demonstrates the size distortion problem: the FEVD raw 
SEs are typically much smaller than the correct ones, leading to 
severely inflated t-statistics and false rejection of true null hypotheses.

{dlgtab:SE/Robust}

{phang}
{opt robust} reports robust standard errors.  The Pesaran-Zhou (2016)
variance estimator is robust by construction — it is consistent under
heteroskedasticity and serial correlation of epsilon_it and
heteroskedasticity of eta_i (Pesaran & Zhou 2016, p.7).  Specifying
{opt robust} labels the coefficient table header as
{it:Robust Std. Err.} (the convention that reviewers expect) and sets
{cmd:e(vce)} to {cmd:"robust"} and {cmd:e(vcetype)} to {cmd:"Robust"}.
When {opt robust} is not specified, the same Pesaran-Zhou standard errors
are still used because they are the only consistent ones; the header
reads {it:PZ Robust Std. Err.} and {cmd:e(vce)} = {cmd:"pesaran-zhou"}.

{dlgtab:Diagnostics}

{phang}
{opt bwratio} reports the between- to within-standard deviation ratio for 
each z-variable. This ratio measures how "time-invariant" a variable truly 
is:
{p 12 12 2}• Ratio = infinity: truly time-invariant (within SD = 0){p_end}
{p 12 12 2}• Ratio > 1.7: FEVD/FEF may improve over FE 
    (at corr(z,u) approx 0.3; see Plumper & Troeger 2007, Figures 2-4){p_end}
{p 12 12 2}• Ratio near 1: variable is nearly as variable within 
    as between panels; FE may be sufficient{p_end}
{p 12 12 2}• The threshold ratio increases with the correlation 
    between z and the unobserved effects{p_end}


{marker background}{...}
{title:Econometric background}

{pstd}
{bf:Why are time-invariant effects hard to estimate?}

{pstd}
In the standard panel model y_it = alpha_i + x_it'beta + epsilon_it, the 
within transformation y_it - y_bar_i eliminates both the individual effects 
alpha_i and any time-invariant regressors z_i. This is the price of 
consistency: by removing the individual effects (which may be correlated with 
x_it), FE also removes z_i.

{pstd}
Several approaches exist to recover gamma:

{p 8 12 2}
{bf:Random Effects (RE)}: Assumes eta_i uncorrelated with x_it AND z_i. 
This is often too restrictive, and the Hausman test frequently rejects 
this assumption.{p_end}

{p 8 12 2}
{bf:Hausman-Taylor (HT)}: Uses time-varying exogenous regressors as 
instruments for endogenous z_i. Requires correct partitioning of regressors 
into exogenous/endogenous groups and assumes homoskedastic, serially 
uncorrelated errors. See {helpb xthtaylor}.{p_end}

{p 8 12 2}
{bf:FEVD/FEF}: Uses the FE residuals to recover gamma. Requires z_i 
uncorrelated with eta_i (for FEF) or valid instruments (for FEF-IV). 
Allows heteroskedastic and serially correlated errors.{p_end}

{pstd}
{bf:Key identification assumption}: For FEF (without IV), z_i must be 
uncorrelated with the unobserved individual effects eta_i. If this 
assumption is violated, use FEF-IV with instruments, or use 
{helpb xthtaylor} instead.


{marker variance}{...}
{title:Variance estimation}

{pstd}
{bf:The size distortion problem in FEVD:}

{pstd}
The original FEVD procedure uses pooled OLS standard errors from Stage 3.  
Pesaran and Zhou (2016, Remark 4) show that these standard errors are 
{bf:inconsistent} because they ignore the generated regressor problem: h_i 
is estimated, not observed. Even under homoskedastic IID errors, the FEVD 
variance differs from the correct variance by the term 
(sigma^2/T) Q_zz^{-1} Q_z_xbar (Q_p - Q_xbar_xbar)^{-1} Q_xbar_z Q_zz^{-1}.  
This term is always positive semi-definite, meaning the FEVD SEs are 
{bf:too small}, leading to over-rejection of null hypotheses.

{pstd}
{bf:Pesaran-Zhou variance estimator (Eq. 17):}

{p 8 8 2}
Var_hat(gamma_hat) = N^{-1} Q_zz^{-1} [V_zz_hat + Q_zxbar (N * Var_hat(beta_hat)) Q_xbarz] Q_zz^{-1}

{pstd}
where:

{p 8 8 2}
Q_zz   = (1/N) sum_i (z_i - z_bar)(z_i - z_bar)'  {space 10}(Eq. 8)

{p 8 8 2}
Q_zxbar = (1/N) sum_i (z_i - z_bar)(x_bar_i - x_bar)'  {space 4}(Eq. 9)

{p 8 8 2}
V_zz_hat = (1/N) sum_i c_hat_i^2 (z_i - z_bar)(z_i - z_bar)'  {space 2}(Eq. 19)

{p 8 8 2}
c_hat_i = y_bar_i - y_bar - (x_bar_i - x_bar)' beta_hat
{space 8}- (z_i - z_bar)' gamma_hat  {space 20}(Eq. 20)

{p 8 8 2}
Var_hat(beta_hat) = HC sandwich from FE:  {space 10}(Eq. 18)
{space 4}(sum x'_i. x_i.)^{-1} (sum x'_i. e_i e'_i x_i.) (sum x'_i. x_i.)^{-1}

{pstd}
This variance estimator is {bf:consistent} under heteroskedasticity and 
serial correlation of epsilon_it, and heteroskedasticity of eta_i. V_zz_hat 
captures the variation in c_hat_i (the residual component attributable to 
heterogeneous eta_i and epsilon-bar_i), while the Q_zxbar term captures 
the estimation uncertainty from Stage 1.

{pstd}
{bf:FEF-IV variance estimator (Eq. 51):}

{p 8 8 2}
Var_hat(gamma_hat_IV) = N^{-1} H_zr [V_rr_hat + Q_rxbar (N * Var_hat(beta_hat)) Q_xbarr] H_zr'

{pstd}
where H_zr = (Q_zr Q_rr^{-1} Q_zr')^{-1} Q_zr Q_rr^{-1}, and V_rr_hat is 
the analogue of V_zz_hat using instrument residuals.


{marker comparison}{...}
{title:Comparison with other estimators}

{pstd}
The following table summarizes the assumptions and properties of the 
available estimators for time-invariant effects:

{col 5}{bf:Estimator}{col 22}{bf:z_i exogenous?}{col 40}{bf:Error assumptions}{col 62}{bf:Stata command}
{col 5}{hline 68}
{col 5}FE{col 22}N/A{col 40}General{col 62}{bf:xtreg, fe}
{col 5}RE{col 22}Required{col 40}General{col 62}{bf:xtreg, re}
{col 5}HT{col 22}Some endo.{col 40}IID{col 62}{bf:xthtaylor}
{col 5}FEVD/FEF{col 22}Required{col 40}Het. + serial corr.{col 62}{bf:xtfifevd}
{col 5}FEF-IV{col 22}Some endo.{col 40}Het. + serial corr.{col 62}{bf:xtfifevd, iv()}
{col 5}{hline 68}

{pstd}
{bf:When to use each:}

{p 8 12 2}
• Use {bf:FEF/FEVD} ({cmd:xtfifevd}) when: z_i is exogenous, errors may be 
heteroskedastic/serially correlated, and the b/w ratio is high.{p_end}

{p 8 12 2}
• Use {bf:FEF-IV} ({cmd:xtfifevd, iv()}) when: some z_i are endogenous and 
valid instruments are available.{p_end}

{p 8 12 2}
• Use {bf:Hausman-Taylor} ({helpb xthtaylor}) when: errors are IID and 
time-varying regressors serve as instruments.{p_end}

{p 8 12 2}
• Use {bf:RE} ({helpb xtreg:xtreg, re}) when: the Hausman test does not 
reject the hypothesis that eta_i is uncorrelated with all regressors.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}: Load Stata's built-in NLS panel data (National Longitudinal 
Survey of Young Women 14-26). This dataset contains time-invariant variables 
{cmd:race} and {cmd:birth_yr} which are dropped by standard FE.{p_end}

{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. describe ln_wage tenure hours ttl_exp race birth_yr}{p_end}

{pstd}{bf:Example 1}: Standard FE — race and birth_yr are dropped{p_end}

{phang2}{cmd:. xtreg ln_wage tenure hours ttl_exp, fe}{p_end}
{phang2}{cmd:. * Note: race and birth_yr do not appear — eliminated by FE}{p_end}

{pstd}{bf:Example 2}: FEVD recovers time-invariant coefficients{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. * gamma for race and birth_yr are now estimated}{p_end}

{pstd}{bf:Example 3}: FEF with robust standard errors (recommended for papers){p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) fef robust}{p_end}
{phang2}{cmd:. * Table header shows "Robust Std. Err."; e(vce) = "robust"}{p_end}

{pstd}{bf:Example 4}: Compare FEVD raw SEs vs Pesaran-Zhou corrected SEs{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) compare}{p_end}
{phang2}{cmd:. * The FEVD raw SEs are much smaller (inconsistent) — PZ SEs are correct}{p_end}

{pstd}{bf:Example 5}: Between/within variance ratio diagnostic{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) bwratio}{p_end}
{phang2}{cmd:. * race: B/W = Inf (truly time-invariant)}{p_end}
{phang2}{cmd:. * birth_yr: B/W = Inf (truly time-invariant)}{p_end}

{pstd}{bf:Example 6}: Post-estimation — access stored results{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. ereturn list}{p_end}
{phang2}{cmd:. matrix list e(gamma_fevd)}{p_end}
{phang2}{cmd:. matrix list e(V_gamma_pz)}{p_end}
{phang2}{cmd:. matrix list e(V_gamma_fevd_raw)}{p_end}

{pstd}{bf:Example 7}: Combined options{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) compare bwratio}{p_end}

{pstd}{bf:Example 8}: Reproduce original Plumper-Troeger without intercept 
(for replication — not recommended){p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr) nointercept2}{p_end}
{phang2}{cmd:. * Warning: results may be biased (Pesaran & Zhou 2016, Proposition 4)}{p_end}

{pstd}{bf:Example 9}: Post-estimation graphs{p_end}

{phang2}{cmd:. xtfifevd ln_wage tenure hours ttl_exp, zinv(race birth_yr)}{p_end}
{phang2}{cmd:. xtfifevd_graph}{p_end}
{phang2}{cmd:. xtfifevd_graph, secompare}{p_end}
{phang2}{cmd:. xtfifevd_graph, combined saving(fevd_results)}{p_end}
{phang2}{cmd:. * See {helpb xtfifevd_graph} for details}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:xtfifevd} stores the following in {cmd:e()}:

{synoptset 28 tabbed}{...}
{p2col 5 28 32 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of groups (panels){p_end}
{synopt:{cmd:e(T)}}time periods (rounded for unbalanced panels){p_end}
{synopt:{cmd:e(T_bar)}}average time periods (exact, for unbalanced panels){p_end}
{synopt:{cmd:e(k_x)}}number of time-varying regressors{p_end}
{synopt:{cmd:e(k_z)}}number of time-invariant regressors{p_end}
{synopt:{cmd:e(k_iv)}}number of instruments (FEF-IV only){p_end}
{synopt:{cmd:e(delta)}}FEVD stage-3 coefficient on h_i; should be 1.0 
    by Proposition 3 (FEVD only){p_end}
{synopt:{cmd:e(sigma2_e)}}estimated variance of idiosyncratic errors 
    (from FE){p_end}
{synopt:{cmd:e(sigma2_u)}}estimated variance of fixed effects 
    (from FE){p_end}

{p2col 5 28 32 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtfifevd}{p_end}
{synopt:{cmd:e(method)}}{cmd:FEVD}, {cmd:FEF}, or {cmd:FEF-IV}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(xvars)}}names of time-varying regressors{p_end}
{synopt:{cmd:e(zinvariants)}}names of time-invariant regressors{p_end}
{synopt:{cmd:e(instruments)}}names of instruments (FEF-IV only){p_end}
{synopt:{cmd:e(vce)}}{cmd:robust} or {cmd:pesaran-zhou}{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust} or {cmd:PZ Robust}{p_end}
{synopt:{cmd:e(ivar)}}panel variable{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}

{p2col 5 28 32 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}combined coefficient vector [beta_FE, gamma, alpha]{p_end}
{synopt:{cmd:e(V)}}combined variance-covariance matrix with corrected SEs{p_end}
{synopt:{cmd:e(beta_fe)}}FE estimates of time-varying coefficients (k_x x 1){p_end}
{synopt:{cmd:e(gamma_fevd)}}FEVD estimates of gamma (FEVD only){p_end}
{synopt:{cmd:e(gamma_fef)}}FEF estimates of gamma (FEF only){p_end}
{synopt:{cmd:e(gamma_fefiv)}}FEF-IV estimates of gamma (FEF-IV only){p_end}
{synopt:{cmd:e(V_gamma_pz)}}Pesaran-Zhou corrected variance of gamma 
    (k_z x k_z){p_end}
{synopt:{cmd:e(V_gamma_fevd_raw)}}uncorrected FEVD stage-3 variance of gamma 
    (FEVD only; for comparison){p_end}

{p2col 5 28 32 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Plumper, T. and V.E. Troeger. 2007.
{it:Efficient estimation of time-invariant and rarely changing variables in finite sample panel analyses with unit fixed effects.}
{it:Political Analysis} 15(2): 124-139.
{browse "https://doi.org/10.1093/pan/mpm002"}
{p_end}

{phang}
Pesaran, M.H. and Q. Zhou. 2016.
{it:Estimation of time-invariant effects in static panel data models.}
{it:Econometric Reviews}.
{browse "https://doi.org/10.1080/07474938.2016.1222225"}
{p_end}

{phang}
Greene, W. 2011.
{it:Fixed effects vector decomposition: A magical solution to the problem of time-invariant variables in fixed effects models?}
{it:Political Analysis} 19: 135-146.
{p_end}

{phang}
Breusch, T., M. Ward, H. Nguyen, and T. Kompas. 2011.
{it:On the fixed-effects vector decomposition.}
{it:Political Analysis} 19: 123-134.
{p_end}

{phang}
Hausman, J.A. and W. Taylor. 1981.
{it:Panel data and unobservable individual effects.}
{it:Econometrica} 49: 1377-1398.
{p_end}

{phang}
Plumper, T. and V.E. Troeger. 2011.
{it:Fixed-effects vector decomposition: Properties, reliability, and instruments.}
{it:Political Analysis} 19: 147-164.
{p_end}

{phang}
Amemiya, T. and T.E. MaCurdy. 1986.
{it:Instrumental-variable estimation of an error-components model.}
{it:Econometrica} 54: 869-880.
{p_end}


{marker requirements}{...}
{title:Requirements}

{pstd}
Stata 15.1 or later.{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
merwanroudane920@gmail.com{break}
Independent Researcher
{p_end}

{pstd}
Please cite this package as:{break}
Roudane, M. (2026). XTFIFEVD: Stata module for Fixed Effects Filtered and
Vector Decomposition estimation of time-invariant effects in panel data.
{p_end}
