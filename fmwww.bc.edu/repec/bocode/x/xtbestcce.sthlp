{smcl}
{* *! version 1.0.0  2026-05-12}{...}
{vieweralsosee "[XT] xtreg" "help xtreg"}{...}
{vieweralsosee "xtdcce2"   "help xtdcce2"}{...}
{viewerjumpto "Syntax"      "xtbestcce##syntax"}{...}
{viewerjumpto "Description" "xtbestcce##description"}{...}
{viewerjumpto "Options"     "xtbestcce##options"}{...}
{viewerjumpto "Examples"    "xtbestcce##examples"}{...}
{viewerjumpto "Stored"      "xtbestcce##stored"}{...}
{viewerjumpto "References"  "xtbestcce##references"}{...}
{viewerjumpto "Author"      "xtbestcce##author"}{...}

{title:Title}

{phang}
{bf:xtbestcce} {hline 2} Bootstrap-Enhanced Common Correlated Effects for panel
data with {it:distinct} correlated factors


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:xtbestcce} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Estimator}
{synopt :{opt p:ooled}}CCEP estimator (pooled — eq. 2.4) {it:default}{p_end}
{synopt :{opt mg}}CCEMG estimator (mean-group — eq. 2.5){p_end}
{synopt :{opt fe}}include a column of ones in the cross-section averages
(equivalent to two-way fixed effects){p_end}
{synopt :{opt noconstant}}suppress the intercept in the regression{p_end}

{syntab :Cross-section averages}
{synopt :{opth cr:osssectional(varlist)}}variables whose CAs are used to proxy
the factors. Default: {it:depvar indepvars}.{p_end}
{synopt :{opt noybar}}exclude the depvar mean from the CAs (recommended under
distinct factors, see paper p.2).{p_end}
{synopt :{opt ic}}select the subset of CAs that minimises the Information
Criterion of eq. (3.1) — Margaritella-Westerlund / De Vos-Stauskas.{p_end}
{synopt :{opth ic_p:enalty(string)}}penalty for the IC. Choices: {bf:log}
(default; (N+T)/NT * log(min(N,T)^2)), {bf:sqrt}, {bf:nt}.{p_end}

{syntab :Inference (Algorithm 1 — CS bootstrap)}
{synopt :{opt b:ootstrap}}use the cross-section bootstrap of Algorithm 1 with
percentile CIs from eq. (2.8).{p_end}
{synopt :{opt r:eps(#)}}number of bootstrap replications (default 999;
min 99).{p_end}
{synopt :{opt s:eed(#)}}seed for reproducibility.{p_end}
{synopt :{opt l:evel(#)}}confidence level (default {cmd:level()}).{p_end}
{synopt :{opt bsave(name)}}save the B x k bootstrap draws as a matrix.{p_end}

{syntab :Display}
{synopt :{opt nice}}use the colourful table (boxed SMCL).{p_end}
{synopt :{opt notab:le}}suppress the table.{p_end}
{synopt :{opt p:lot}}coefficient plot with CIs.{p_end}
{synopt :{opt bootplot}}bootstrap-distribution panel (requires {opt b:ootstrap}).{p_end}
{synopt :{opt trace}}print bootstrap progress.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbestcce} implements the toolbox of
{browse "https://mpra.ub.uni-muenchen.de/120194/":Stauskas & De Vos (2024)},
which extends the Common Correlated Effects (CCE) framework of
{help xtdcce2:xtdcce2} (Ditzen, 2024) to settings where the dependent variable
and the regressors are driven by {it:distinct but correlated} sets of unobserved
factors.

{pstd}
The model is the multi-factor panel regression

{p 8 0 8}
y_it = β' x_it + γ_i' f_{y,t} + ε_it,    x_it = Γ_i' f_{x,t} + v_it

{pstd}
with {bf:cov(f_y, f_x) ≠ 0} and m_y ≥ 1. Pesaran's (2006) original CCE estimator
breaks down when m_y > 1 because the cross-section average ȳ can no longer
identify {it:m_y} factors. {cmd:xtbestcce} solves this in three ways:

{p 4 6 2}
1. Estimates β by CCEP or CCEMG using cross-section averages of the
{it:explanatory variables} only (or any selected subset), see eq. (2.4)-(2.5).

{p 4 6 2}
2. Selects the optimal subset of CAs through the Information Criterion of
eq. (3.1)-(3.2), which guarantees m_x = g asymptotically and restores
asymptotic normality (Theorems 1-2).

{p 4 6 2}
3. Performs inference via the Cross-Section bootstrap (Algorithm 1), which
replicates the non-standard bias h_2 and the variance component Ψ_f that the
analytical variance cannot identify (Theorems 2, 6).

{pstd}
Under heterogeneous slopes (CCEMG and CCEP with {help xtbestcce##rem3:Theorem 3}),
the estimators are √N-consistent and asymptotically normal regardless of
whether m_x = g or m_x < g; the user therefore need not discriminate
between the homogeneous and heterogeneous cases.


{marker options}{...}
{title:Options}

{phang}{opt pooled} / {opt mg} – Estimator choice. {bf:pooled} fits the CCEP
estimator of equation (2.4):

{p 12 0 8}
β̂_CCEP = ( Σ_i X_i' M_F̂x X_i )^{-1} Σ_i X_i' M_F̂x y_i

{phang}while {bf:mg} fits the CCEMG estimator of equation (2.5):

{p 12 0 8}
β̂_CCEMG = (1/N) Σ_i ( X_i' M_F̂x X_i )^{-1} X_i' M_F̂x y_i

{phang}{opt fe} – Adds a column of ones to F̂_x, which makes the routine
invariant to individual fixed effects (paper Section 2.1).

{phang}{opt crosssectional(varlist)} – The pool of variables whose cross-section
averages are candidates for F̂_x. With {opt ic} the IC selector picks the
optimal subset.

{phang}{opt ic} – Activates the Information Criterion selector (paper
Section 3.1). It enumerates every non-empty subset of the candidate CAs of size
≥ k and keeps the one minimising

{p 12 0 8}
IC(M_x) = log( det(Q̄_x̌) ) + g · k · p_NT

{phang}with Q̄_x̌ = (1/N) Σ T^{-1} X_i' M_{F̂_x} X_i and p_NT determined by
{opt ic_penalty()}. This is the practical implementation of eq. (3.1)-(3.2).

{phang}{opt bootstrap} – Activates the cross-section bootstrap of
Algorithm 1. For each of {opt reps()} replications the routine draws N units
with replacement, rebuilds the CAs in the bootstrap world, and re-estimates β.
The reported standard errors are the bootstrap-percentile sample standard
deviations and confidence intervals follow eq. (2.8).

{phang}{opt plot} / {opt bootplot} – Two graph styles. {opt plot} produces a
coefficient/CI dotplot; {opt bootplot} produces a multi-panel density plot of
the bootstrap distribution per coefficient.


{marker examples}{...}
{title:Examples}

{pstd}Setup: use a panel and {cmd:xtset} it.{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Plain CCEP (no bootstrap):{p_end}
{phang2}{cmd:. xtbestcce invest mvalue kstock, pooled fe}{p_end}

{pstd}Heterogeneous-slope CCEMG with IC-selected CAs:{p_end}
{phang2}{cmd:. xtbestcce invest mvalue kstock, mg ic crosssectional(invest mvalue kstock)}{p_end}

{pstd}Full toolbox (Stauskas-De Vos): CCEP + IC + CS bootstrap + nice table:{p_end}
{phang2}{cmd:. xtbestcce invest mvalue kstock, pooled fe ic bootstrap reps(999) seed(42) nice}{p_end}

{pstd}Coefficient plot and bootstrap density:{p_end}
{phang2}{cmd:. xtbestcce invest mvalue kstock, mg ic bootstrap reps(999) seed(42)}{p_end}
{phang2}{cmd:. xtbestcce_plot, kind(coef)}{p_end}
{phang2}{cmd:. xtbestcce_plot, kind(bdist)}{p_end}

{pstd}IC information after fit:{p_end}
{phang2}{cmd:. xtbestcce_plot, kind(ic)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
Scalars:
{p_end}
{synoptset 22 tabbed}{...}
{synopt:{cmd:e(N)}}number of NT observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels (N){p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(k)}}number of regressors{p_end}
{synopt:{cmd:e(g_ca)}}number of cross-section averages used (g){p_end}
{synopt:{cmd:e(ic_used)}}1 if IC selection was active{p_end}
{synopt:{cmd:e(fe)}}1 if fixed-effect column added{p_end}
{synopt:{cmd:e(bootstrap)}}1 if CS bootstrap was used{p_end}
{synopt:{cmd:e(reps)}}bootstrap replications{p_end}
{synopt:{cmd:e(level)}}CI level{p_end}

{pstd}Macros:{p_end}
{synopt:{cmd:e(cmd)}}{bf:xtbestcce}{p_end}
{synopt:{cmd:e(estimator)}}{bf:ccep} or {bf:ccemg}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}list of regressors{p_end}
{synopt:{cmd:e(Fxnames)}}cross-section averages used as factor proxy{p_end}
{synopt:{cmd:e(ic_pen)}}IC penalty kind{p_end}

{pstd}Matrices:{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance estimator (bootstrap if requested,
analytical eq. 2.6/2.7 otherwise){p_end}
{synopt:{cmd:e(V_boot)}}CS bootstrap variance (only with {opt b:ootstrap}){p_end}
{synopt:{cmd:e(bsamples)}}B x k matrix of bootstrap draws (only with
{opt b:ootstrap}){p_end}
{synopt:{cmd:e(selector)}}indices of CAs selected by the IC{p_end}


{marker references}{...}
{title:References}

{phang}
Stauskas, O. and De Vos, I. (2024). Handling Distinct Correlated Effects with
CCE. {it:MPRA Paper No. 120194}.
{browse "https://mpra.ub.uni-muenchen.de/120194/"}.

{phang}
De Vos, I. and Stauskas, O. (2024). Cross-section bootstrap for CCE
regressions. {it:Journal of Econometrics}, 240(1):105648.

{phang}
Pesaran, M.H. (2006). Estimation and inference in large heterogeneous panels
with a multifactor error structure. {it:Econometrica}, 74(4):967-1012.

{phang}
Margaritella, L. and Westerlund, J. (2023). Using information criteria to
select averages in CCE. {it:The Econometrics Journal}, utad009.

{phang}
Cui, G., Norkutė, M., Sarafidis, V. and Yamagata, T. (2022). Two-stage
instrumental variable estimation of linear panel data models with interactive
effects. {it:The Econometrics Journal}, 25(2):340-361.

{phang}
Ditzen, J. (2024). xtdcce2 — Stata module to estimate heterogeneous coefficient
panel data models with cross-sectional dependence.


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
{cmd:merwanroudane920@gmail.com}{break}

{pstd}
Bug reports and feature requests are welcome by email. Please cite the package
as:

{phang}
Roudane, M. (2026). {bf:xtbestcce}: Bootstrap-Enhanced CCE for distinct
correlated factors. Stata package, version 1.0.0.
{p_end}
