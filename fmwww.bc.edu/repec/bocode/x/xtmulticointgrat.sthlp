{smcl}
{* *! version 1.0.0  22may2026}{...}
{cmd:help xtmulticointgrat}{right: ({browse "https://www.stata.com":Stata})}
{hline}

{title:Title}

{phang}
{bf:xtmulticointgrat} {hline 2} Panel multicointegration testing with cross-section
independence or approximate common factors

{title:Package contents}

{p 4 6 2}
The {bf:xtmulticointgrat} library implements the panel multicointegration
test of Berenguer-Rico & Carrion-i-Silvestre (2006), Oxford Bulletin of
Economics and Statistics 68 (Supplement), 721-744.  Components:

{p 8 12 2}
{help xtmulticointgrat##syntax:xtmulticointgrat} {hline 2} main: estimation and
testing for panel multicointegration.{p_end}
{p 8 12 2}
{helpb xtmulticointgrat_graph} {hline 2} publication-quality diagnostic graphs.{p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{cmd:xtmulticointgrat} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {it:options}]

{p 4 6 2}
The panel must be {bf:xtset} and {bf:balanced} (each unit must have the same
number of time observations within the {it:if/in} sample).

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Specification}
{synopt :{opt tr:end(spec)}}deterministics: {bf:none}, {bf:c}, {bf:ct}, {bf:ctt}
(default: {bf:c}){p_end}
{synopt :{opt app:roach(name)}}{bf:auto} (default), {bf:indep}, or {bf:factors}{p_end}
{synopt :{opt fac:tors}}shortcut for {bf:approach(factors)}{p_end}

{syntab :Factor model (common-factor branch)}
{synopt :{opt r:max(#)}}maximum number of common factors (default 6){p_end}
{synopt :{opt ic(name)}}factor-number IC: {bf:ic1}, {bf:ic2} (default), {bf:ic3},
{bf:bic3}{p_end}

{syntab :ADF lag selection}
{synopt :{opt pmax(#)}}maximum lag for ADF augmentation (default 5){p_end}
{synopt :{opt lagsel(crit)}}{bf:tsig} (default, Ng-Perron 1995), {bf:aic}, {bf:bic},
{bf:hqic}, {bf:fixed}{p_end}
{synopt :{opt lags(#)}}fixed lag when {bf:lagsel(fixed)} (default 0){p_end}

{syntab :Reporting}
{synopt :{opt l:evel(#)}}confidence level; default 95{p_end}
{synopt :{opt gr:aph}}call {help xtmulticointgrat_graph} after estimation{p_end}
{synopt :{opt grsave(filename)}}export the diagnostic graph to a file{p_end}
{synopt :{opt notab:le}}suppress result tables{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtmulticointgrat} tests for {it:multicointegration} - a "second layer" of
long-run equilibrium - in a balanced panel of {it:N} cross-sectional units
observed over {it:T} periods.  A standard cointegrating relationship is

{p 8 8 2}
{bf:y_i,t = c_t α_i + x_i,t β_i + ϑ_i,t}{p_end}

{pstd}
with {it:ϑ_i,t} I(0).  Multicointegration arises when the cumulated equilibrium
error {it:S_i,t} = Σ {it:ϑ_i,j} is itself cointegrated with the original I(1)
flows, that is

{p 8 8 2}
{bf:y_i,t = m_t μ_i + S_i,t γ_i + u_i,t}{p_end}

{pstd}
with {it:u_i,t} I(0).  The classical Granger-Lee (1989) production / sales /
inventory example is the canonical illustration.  When at least two cross-sectional
units share common stochastic trends, the test must be modified to account for
cross-section dependence; Berenguer-Rico & Carrion-i-Silvestre (2006) adapt the
Bai-Ng (2004) PANIC framework for this purpose.

{pstd}
{cmd:xtmulticointgrat} offers two testing branches.

{phang2}
{bf:Branch A - cross-section independent ({cmd:approach(indep)})}{p_end}
{pmore}
Computes Pedroni-style between-dimension panel statistics from the one-step
Engsted-Gonzalo-Haldrup (1997) multicointegration regression and standardizes
them using the Monte-Carlo moments {it:Θ_1, Ψ_1, Θ_2, Ψ_2} reported in Tables
1 and 2 of the paper.  Returns:

{p 8 16 2}{bf:Z_ρ_NT}{p_end}
{p 16 16 2}between-dimension normalized-bias statistic{p_end}
{p 8 16 2}{bf:Z_t_NT}{p_end}
{p 16 16 2}between-dimension t-ratio statistic{p_end}
{p 8 16 2}{bf:Z_ρ_NT^std, Z_t_NT^std}{p_end}
{p 16 16 2}standardized to converge to N(0,1) under the null of no
multicointegration{p_end}

{phang2}
{bf:Branch B - common factors ({cmd:approach(factors)}, default)}{p_end}
{pmore}
Implements the Granger-Lee (1989) two-step regression and the PANIC procedure
of Bai-Ng (2004) on the stage-2 residual {it:u_i,t}:

{p 12 16 2}1. Stage 1: {it:y_i,t = c_t α_i + x_i,t β_i + ϑ_i,t} → OLS residual,
cumulate to {it:S_i,t}.{p_end}
{p 12 16 2}2. Stage 2: {it:y_i,t = m_t μ_i + S_i,t γ_i + u_i,t} → OLS residual
{it:u_i,t}.{p_end}
{p 12 16 2}3. PCA on Δ{it:u_i,t} (demeaned) yields common factors {it:F̂_t} and
loadings {it:π̂_i}; the number of factors is chosen by a Bai-Ng panel
information criterion.{p_end}
{p 12 16 2}4. Idiosyncratic component {it:ê_i,t} (recovered by cumulation) is
tested for a unit root by pooling individual ADF t-statistics, standardized
with Table 3 moments.{p_end}
{p 12 16 2}5. Common factors are tested individually with ADF (acting as a
simplified MQ_c test); the number {it:q̂} of non-stationary factors is
returned.{p_end}

{pmore}
The overall conclusion combines the two pieces.  {it:Multicointegration
exists} if ρ_i < 1 for all i (idiosyncratic ADF rejects unit root) and
{it:C(1)} has zero rank (no non-stationary common stochastic trend).  Cross-
multicointegration appears as a mild case in which the idiosyncratic component
is stationary but some common stochastic trends remain.

{marker options}{...}
{title:Options}

{phang}
{opt trend(spec)} controls the deterministic component of the regressions:
{bf:none} (no deterministics), {bf:c} (constant), {bf:ct} (constant + linear
trend), {bf:ctt} (constant + linear + quadratic trend).  Default: {bf:c}.

{phang}
{opt approach(name)} selects the testing branch:
{bf:indep} for the cross-section independent case (Pedroni-style pooling),
{bf:factors} for the common-factor case (PANIC), {bf:auto} (default) selects
{bf:factors}.

{phang}
{opt factors} is a synonym for {opt approach(factors)}.

{phang}
{opt rmax(#)} maximum number of common factors to consider when selecting the
factor count by panel BIC.  Default 6.

{phang}
{opt ic(name)} information criterion for selecting the number of common factors:
{bf:ic1}, {bf:ic2}, {bf:ic3} of Bai-Ng (2002), or {bf:bic3}.  Default {bf:ic2}.

{phang}
{opt pmax(#)} maximum lag of the ADF augmentation for both idiosyncratic and
factor tests.  Default 5.

{phang}
{opt lagsel(crit)} criterion for selecting the ADF lag length:
{bf:tsig} (Ng & Perron 1995 sequential t-rule, default), {bf:aic}, {bf:bic},
{bf:hqic}, {bf:fixed}.

{phang}
{opt graph} produces a publication-style diagnostic dashboard immediately after
the test.  See {helpb xtmulticointgrat_graph} for layout options.

{marker results}{...}
{title:Stored results}

{phang}{bf:r()} scalars (common to both branches){p_end}
{synoptset 22 tabbed}{...}
{synopt :{cmd:r(N)}}number of panels actually used{p_end}
{synopt :{cmd:r(T)}}number of time observations per panel{p_end}
{synopt :{cmd:r(m1)}}number of I(1) flow regressors per panel{p_end}

{phang}{bf:r()} scalars - independent branch{p_end}
{synopt :{cmd:r(Z_rho)}}raw pooled normalized-bias statistic{p_end}
{synopt :{cmd:r(Z_t)}}raw pooled t-ratio statistic{p_end}
{synopt :{cmd:r(Z_rho_std)}}standardized N(0,1) version{p_end}
{synopt :{cmd:r(Z_t_std)}}standardized N(0,1) version{p_end}
{synopt :{cmd:r(p_rho)}, {cmd:r(p_t)}}asymptotic p-values (lower tail){p_end}
{synopt :{cmd:r(Theta1)/Psi1/Theta2/Psi2)}}moments used for standardization{p_end}

{phang}{bf:r()} scalars - factor branch{p_end}
{synopt :{cmd:r(r)}}estimated number of common factors r̂{p_end}
{synopt :{cmd:r(q_nonstat)}}estimated number of non-stationary common factors q̂{p_end}
{synopt :{cmd:r(Z_idio)}}raw pooled idiosyncratic ADF{p_end}
{synopt :{cmd:r(Z_idio_std)}}standardized N(0,1){p_end}
{synopt :{cmd:r(p_idio)}}asymptotic p-value{p_end}
{synopt :{cmd:r(Theta_e)/Psi_e)}}Table-3 moments{p_end}

{phang}{bf:r()} matrices{p_end}
{synopt :{cmd:r(adf_indiv)}}per-i ADF results: (ρ̂_i, t_ρ̂_i, Σφ̂_i, lag) [indep]{p_end}
{synopt :{cmd:r(adf_idio)}}same but for idiosyncratic component [factors]{p_end}
{synopt :{cmd:r(mq_factors)}}ADF on each estimated factor{p_end}
{synopt :{cmd:r(loadings)}}factor loadings Λ̂ (N x r̂){p_end}

{phang}{bf:r()} macros{p_end}
{synopt :{cmd:r(cmd)}}{bf:xtmulticointgrat}{p_end}
{synopt :{cmd:r(approach)}}{bf:indep} or {bf:factors}{p_end}
{synopt :{cmd:r(trend)}}deterministic specification{p_end}
{synopt :{cmd:r(depvar)}}flow y variable{p_end}
{synopt :{cmd:r(indep)}}flow x variables{p_end}

{phang}{bf:Permanent variables added to the data} (factor branch only){p_end}
{synopt :{cmd:_xtmcg_S_i}}stage-1 cumulated residual S_i,t{p_end}
{synopt :{cmd:_xtmcg_u_i}}stage-2 residual u_i,t{p_end}
{synopt :{cmd:_xtmcg_e_i}}idiosyncratic component e_i,t{p_end}
{synopt :{cmd:_xtmcg_F1, _xtmcg_F2, ...}}estimated common factors{p_end}

{marker examples}{...}
{title:Examples}

{phang}{bf:1.  Production / sales / inventories panel (Granger-Lee 1989 style)}{p_end}
{p 8 16 2}{stata "xtset industry month"}{p_end}
{p 8 16 2}{stata "xtmulticointgrat sales production, trend(c)"}{p_end}
{p 8 16 2}{stata "xtmulticointgrat_graph, layout(default) save(fig1.png)"}{p_end}

{phang}{bf:2.  Strong cross-section dependence  --  use the common-factor approach}{p_end}
{p 8 16 2}{stata "xtmulticointgrat sales production, factors trend(ct) rmax(6) ic(ic2)"}{p_end}

{phang}{bf:3.  Independent panels (small N, Pedroni-style pooling)}{p_end}
{p 8 16 2}{stata "xtmulticointgrat y x, approach(indep) trend(c) pmax(5) lagsel(tsig)"}{p_end}

{phang}{bf:4.  Use BIC for ADF lag selection and a quadratic trend}{p_end}
{p 8 16 2}{stata "xtmulticointgrat y x, factors trend(ctt) lagsel(bic) pmax(8)"}{p_end}

{phang}{bf:5.  Multiple flow regressors}{p_end}
{p 8 16 2}{stata "xtmulticointgrat consumption income wealth, factors trend(ct)"}{p_end}

{marker remarks}{...}
{title:Remarks and limitations}

{pstd}
1. The panel must be {bf:balanced} under the {it:if/in} sample.  Unbalanced panels
must be rectangularised first (e.g. with {bf:xtbalance}).

{pstd}
2. The asymptotic theory assumes (T → ∞ then N → ∞)_seq.  Practical experience
in the paper suggests T = 100 with N up to 40-50 gives correct size for the
independent branch; the common-factor branch needs T larger than about 100.

{pstd}
3. The factor-component ADF/MQ test implemented here is a simplified version of
the full Bai-Ng (2004) MQ procedure: it applies an ADF unit-root test to each
estimated factor separately (with the same deterministics as the second-stage
regression).  Users seeking the exact MQ_f / MQ_c statistics with formal lag
order selection should run them externally on the saved {cmd:_xtmcg_F*}
variables.

{pstd}
4. Coefficients of the second-stage regression are computed but not reported
because the limit distribution depends on nuisance parameters (Engsted et al
1997).  Inference focuses on the residual unit-root tests.

{marker refs}{...}
{title:References}

{phang}
Bai, J. and Ng, S. (2002). "Determining the number of factors in approximate
factor models." {it:Econometrica} 70, 191-221.{p_end}

{phang}
Bai, J. and Ng, S. (2004). "A PANIC attack on unit roots and cointegration."
{it:Econometrica} 72, 1127-1177.{p_end}

{phang}
Banerjee, A. and Carrion-i-Silvestre, J.Ll. (2006). "Cointegration in Panel
Data with Breaks and Cross-section Dependence." {it:ECB Working Paper} 591.{p_end}

{phang}
{bf:Berenguer-Rico, V. and Carrion-i-Silvestre, J.Ll. (2006). "Testing for
Multicointegration in Panel Data with Common Factors." {it:Oxford Bulletin of
Economics and Statistics} 68 (Supplement), 721-744.}{p_end}

{phang}
Engsted, T., Gonzalo, J. and Haldrup, N. (1997). "Testing for
multicointegration." {it:Economics Letters} 56, 259-266.{p_end}

{phang}
Granger, C.W.J. and Lee, T.-H. (1989). "Investigation of production, sales and
inventory relationships using multicointegration and non-symmetric error
correction models." {it:Journal of Applied Econometrics} 4, S145-S159.{p_end}

{phang}
Haldrup, N. (1994). "The asymptotics of single-equation cointegration
regressions with I(1) and I(2) variables." {it:Journal of Econometrics} 63,
153-181.{p_end}

{phang}
Ng, S. and Perron, P. (1995). "Unit root tests in ARMA models with data
dependent methods for the selection of the truncation lag."
{it:Journal of the American Statistical Association} 90, 268-281.{p_end}

{phang}
Pedroni, P. (2004). "Panel cointegration: asymptotic and finite sample
properties of pooled time series tests with an application to the PPP
hypothesis." {it:Econometric Theory} 20, 597-625.{p_end}

{marker author}{...}
{title:Author}

{phang}
{bf:Dr Merwan Roudane}{p_end}
{phang}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}
{phang}
{bf:xtmulticointgrat} v1.0.0 - 22 May 2026.  Bug reports and suggestions welcome.

{title:Also see}

{psee}Online:  {helpb xtmulticointgrat_graph}, {helpb multicoint}, {helpb xtpedroni},
{helpb xtbreakcoint}, {helpb xtcointtest}{p_end}
