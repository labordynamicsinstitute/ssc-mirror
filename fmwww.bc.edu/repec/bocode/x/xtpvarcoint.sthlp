{smcl}
{* *! version 1.0.1  05apr2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "[TS] vec" "help vec"}{...}
{vieweralsosee "[TS] irf" "help irf"}{...}
{vieweralsosee "[XT] xtset" "help xtset"}{...}
{viewerjumpto "Syntax" "xtpvarcoint##syntax"}{...}
{viewerjumpto "Description" "xtpvarcoint##description"}{...}
{viewerjumpto "Subcommands" "xtpvarcoint##subcommands"}{...}
{viewerjumpto "Options" "xtpvarcoint##options"}{...}
{viewerjumpto "Examples" "xtpvarcoint##examples"}{...}
{viewerjumpto "Stored results" "xtpvarcoint##stored"}{...}
{viewerjumpto "References" "xtpvarcoint##references"}{...}
{viewerjumpto "Authors" "xtpvarcoint##authors"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtpvarcoint} {hline 2}}Panel VAR Modeling with Cointegration,
Structural Breaks, and Cross-Sectional Dependence{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
General syntax:

{p 8 16 2}
{cmd:xtpvarcoint} {it:subcommand} [{varlist}] [{cmd:,} {it:options}]


{pstd}
{bf:Subcommands:}

{synoptset 16 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt pcoint}}panel cointegration rank tests (Johansen, Breitung, SL, CAIN){p_end}
{synopt:{opt coint}}individual (time-series) cointegration rank tests{p_end}
{synopt:{opt pvar}}panel VAR estimation via Mean Group{p_end}
{synopt:{opt pvec}}panel VECM estimation via Pooled/Mean Group{p_end}
{synopt:{opt vecm}}individual VECM estimation (single unit){p_end}
{synopt:{opt pid}}panel SVAR identification{p_end}
{synopt:{opt speci}}specification tools (factor number, lag order){p_end}
{synopt:{opt irf}}impulse response functions (after pvar/pvec/vecm){p_end}
{synopt:{opt fevd}}forecast error variance decomposition (after pvar/pvec/vecm){p_end}
{synopt:{opt sboot}}bootstrap inference for IRF with confidence intervals{p_end}
{synopt:{opt plot}}publication-quality graphs (IRF, FEVD, eigenvalues){p_end}
{synoptline}


{marker subcommands}{...}
{title:Subcommand Syntax}

{pstd}
{bf:1. Panel Cointegration Tests (pcoint)}

{p 8 16 2}
{cmd:xtpvarcoint pcoint} {varlist} {cmd:,}
{opt me:thod(JO|BR|SL|CAIN)}
{opt la:gs(numlist)}
[{opt ty:pe(string)}
{opt nfa:ctors(#)}
{opt nit:er(#)}
{opt tbr:eak(numlist)}
{opt tsh:ift(numlist)}
{opt nse:ason(#)}]


{pstd}
{bf:2. Individual Cointegration Test (coint)}

{p 8 16 2}
{cmd:xtpvarcoint coint} {varlist} {cmd:,}
{opt la:gs(#)}
[{opt ty:pe(string)}
{opt me:thod(JO|SL)}
{opt tbr:eak(numlist)}
{opt tsh:ift(numlist)}
{opt nse:ason(#)}]


{pstd}
{bf:3. Panel VAR (pvar)}

{p 8 16 2}
{cmd:xtpvarcoint pvar} {varlist} {cmd:,}
{opt la:gs(numlist)}
[{opt ty:pe(const|trend|both|none)}
{opt nfa:ctors(#)}
{opt nit:er(#)}
{opt tsh:ift(numlist)}
{opt exog(varlist)}]


{pstd}
{bf:4. Panel VECM (pvec)}

{p 8 16 2}
{cmd:xtpvarcoint pvec} {varlist} {cmd:,}
{opt la:gs(numlist)}
{opt ra:nk(#)}
[{opt ty:pe(Case1|Case2|Case3|Case4|Case5)}
{opt po:ol(numlist)}
{opt nfa:ctors(#)}
{opt nit:er(#)}
{opt tbr:eak(numlist)}
{opt tsh:ift(numlist)}]


{pstd}
{bf:5. Individual VECM (vecm)}

{p 8 16 2}
{cmd:xtpvarcoint vecm} {varlist} {cmd:,}
{opt la:gs(#)}
[{opt ra:nk(#)}
{opt ty:pe(Case1|Case2|Case3|Case4|Case5)}
{opt exog(varlist)}
{opt exl:ags(#)}]


{pstd}
{bf:6. SVAR Identification (pid)}

{p 8 16 2}
{cmd:xtpvarcoint pid} {cmd:,}
[{opt me:thod(chol|grt|iv|dc|cvm)}
{opt com:bine(pool|group|indiv)}
{opt s2(string)}
{opt co:vu(string)}
{opt nfa:ctors(#)}
{opt nit:er(#)}
{opt ite:rmax(#)}
{opt ste:ptol(#)}
{opt ite:r2(#)}
{opt pit}]


{pstd}
{bf:7. Specification — Lag Order (speci var)}

{p 8 16 2}
{cmd:xtpvarcoint speci var} {varlist} {cmd:,}
{opt lag:set(numlist)}
[{opt br:eaks(#)}
{opt tr:im(real)}
{opt bre:aktype(string)}
{opt add:dummy}]


{pstd}
{bf:8. Specification — Factor Number (speci factors)}

{p 8 16 2}
{cmd:xtpvarcoint speci factors} {varlist} {cmd:,}
[{opt km:ax(#)}
{opt nit:er(#)}
{opt dif:ferenced}
{opt cen:tered}
{opt sca:led}
{opt nfa:ctors(#)}]


{pstd}
{bf:9. Impulse Response Functions (irf)}

{p 8 16 2}
{cmd:xtpvarcoint irf} {cmd:,}
[{opt ho:rizon(#)}
{opt ci(real)}
{opt boot(#)}
{opt blo:cksize(#)}
{opt cu:mulative}
{opt or:thogonal}]


{pstd}
{bf:10. Forecast Error Variance Decomposition (fevd)}

{p 8 16 2}
{cmd:xtpvarcoint fevd} {cmd:,}
[{opt ho:rizon(#)}]


{pstd}
{bf:11. Bootstrap Inference (sboot)}

{p 8 16 2}
{cmd:xtpvarcoint sboot} {cmd:,}
[{opt me:thod(pmb|mb|mg|normality)}
{opt nb:oot(#)}
{opt blo:cksize(#)}
{opt ci(real)}
{opt ho:rizon(#)}
{opt se:ed(#)}]


{pstd}
{bf:12. Publication-Quality Plots (plot)}

{p 8 16 2}
{cmd:xtpvarcoint plot} {cmd:,}
[{opt pl:ottype(irf|fevd|eigenvalues)}
{opt var:iable(numlist)}
{opt sh:ock(numlist)}
{opt sa:ving(string)}
{opt ti:tle(string)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpvarcoint} implements a comprehensive econometric toolkit for
vector autoregressive (VAR) modeling in heterogeneous panels. It
is a Stata port of the R package {bf:pvars} and provides:

{p 8 12 2}
{bf:Panel cointegration rank tests} based on the Johansen procedure
(Larsson et al. 2001), the Breitung (2005) two-step estimator, the
Saikkonen-Luetkepohl procedure (Arsova and Oersal 2018), and the
correlation-augmented inverse normal test robust to cross-sectional
dependence (Arsova and Oersal 2021).

{p 8 12 2}
{bf:Panel VAR/VECM estimation} using the mean-group (MG) and pooled
mean-group (PMG) estimators with optional Kilian (1998) bias correction
and factor-augmented specifications for cross-sectional dependence.

{p 8 12 2}
{bf:Panel SVAR identification} via Cholesky decomposition,
Blanchard-Quah long-run restrictions, proxy/IV variables, distance
covariance (DC), and Cramer-von Mises (CVM) independence criteria.

{p 8 12 2}
{bf:Specification tools} for determining the number of common factors
(Onatski 2010, Ahn and Horenstein 2013, Bai and Ng 2002) and the
optimal lag order based on AIC, HQC, SIC, and FPE criteria.

{p 8 12 2}
{bf:Impulse response functions}, {bf:forecast error variance
decomposition}, and {bf:bootstrap confidence intervals} via the
panel moving-block bootstrap.

{p 8 12 2}
{bf:Publication-quality plots} for IRFs with confidence bands,
FEVD stacked area charts, and companion matrix eigenvalue stability
diagrams.

{pstd}
The data must be {cmd:xtset} before calling {cmd:xtpvarcoint}.
Individual-specific lag orders are supported by specifying a
{it:numlist} in {opt lags()}.


{marker options}{...}
{title:Options}

{dlgtab:Panel Cointegration (pcoint, coint)}

{phang}
{opt method(JO|BR|SL|CAIN)} specifies the panel cointegration test
procedure: {bf:JO} for Johansen (Larsson et al. 2001), {bf:BR} for
Breitung (2005), {bf:SL} for Saikkonen-Luetkepohl (Arsova and
Oersal 2018), or {bf:CAIN} for the correlation-augmented inverse
normal test (Arsova and Oersal 2021). Default is {bf:JO}.

{phang}
{opt type(Case1|Case2|Case3|Case4|Case5|SL_mean|SL_trend)} specifies
the deterministic term in the cointegration model.
{bf:Case1}: no intercept, no trend.
{bf:Case2}: restricted intercept (intercept enters only through the
error-correction term).
{bf:Case3}: unrestricted intercept (default).
{bf:Case4}: restricted trend, unrestricted intercept.
{bf:Case5}: unrestricted intercept and trend.
{bf:SL_mean}: SL procedure with mean shift.
{bf:SL_trend}: SL procedure with trend (default for method SL).

{phang}
{opt lags(numlist)} specifies either a common lag order (single integer)
or individual-specific lag orders for each panel unit (one integer per
unit). Required for {bf:pcoint}, {bf:coint}, {bf:pvar}, {bf:pvec}, and
{bf:vecm}.

{phang}
{opt nfactors(#)} specifies the number of common factors for
factor-augmented (PANIC) analysis. Default is 0 (no factors).

{phang}
{opt niter(#)} specifies the number of iterations for factor estimation.
Default is 0.

{phang}
{opt tbreak(numlist)} specifies structural break dates (observation
indices) for trend-break dummies.

{phang}
{opt tshift(numlist)} specifies shift-break dates for level-shift dummies.

{phang}
{opt nseason(#)} specifies the number of seasons for seasonal dummy
variables. Default is 0 (no seasonal dummies).

{dlgtab:Panel VAR/VECM (pvar, pvec, vecm)}

{phang}
{opt type(const|trend|both|none)} specifies the deterministic terms for
VAR estimation. {bf:const}: constant only (default).
{bf:trend}: linear trend only. {bf:both}: constant and trend.
{bf:none}: no deterministic terms.

{phang}
{opt rank(#)} specifies the cointegration rank for VECM estimation.
Required for {bf:pvec}. Default is 0 for {bf:vecm} (unrestricted).

{phang}
{opt pool(numlist)} specifies which variable indices to pool using
the Breitung (2005) two-step estimator for homogeneous cointegrating
vectors. Omit for individual-specific vectors (MG estimator).

{phang}
{opt exog(varlist)} specifies exogenous variables to include in the
VAR/VECM.

{phang}
{opt exlags(#)} specifies the number of lags for exogenous variables.
Default is 0.

{dlgtab:SVAR Identification (pid)}

{phang}
{opt method(chol|grt|iv|dc|cvm)} specifies the SVAR identification
method: {bf:chol} for Cholesky (default), {bf:grt} for Blanchard-Quah
long-run restrictions, {bf:iv} for proxy/instrumental variables,
{bf:dc} for distance covariance ICA, or {bf:cvm} for Cramer-von Mises
ICA.

{phang}
{opt combine(pool|group|indiv)} specifies how individual structural
matrices are combined: {bf:pool} for pooled residuals (default),
{bf:group} for group-specific ICA, or {bf:indiv} for unit-specific
identification.

{phang}
{opt itermax(#)} specifies the maximum number of iterations for
ICA-based identification. Default is 500.

{phang}
{opt steptol(#)} specifies the step tolerance parameter for ICA
optimization. Default is 100.

{phang}
{opt iter2(#)} specifies the number of second-stage iterations. Default
is 75.

{dlgtab:Specification (speci)}

{phang}
{opt lagset(numlist)} specifies the candidate lag orders to evaluate.
Required for {bf:speci var}.

{phang}
{opt kmax(#)} specifies the maximum number of factors to consider.
Default is 20.

{phang}
{opt differenced} requests first-differencing of the data before
factor analysis.

{phang}
{opt centered} requests demeaning (centering) of the data before
factor analysis.

{phang}
{opt scaled} requests standardization (scaling to unit variance) before
factor analysis.

{phang}
{opt breaks(#)} specifies the maximum number of structural breaks for
lag/break selection. Default is 0.

{phang}
{opt trim(real)} specifies the trimming parameter for break detection.
Default is 0.15.

{dlgtab:IRF, FEVD, and Bootstrap (irf, fevd, sboot)}

{phang}
{opt horizon(#)} specifies the forecast horizon. Default is 20.

{phang}
{opt cumulative} requests cumulative impulse responses.

{phang}
{opt orthogonal} requests orthogonalized (Cholesky) impulse responses
instead of structural.

{phang}
{opt method(pmb|mb|mg|normality)} specifies the bootstrap method:
{bf:pmb} for panel moving-block (default), {bf:mb} for individual
moving-block, {bf:mg} for mean-group, or {bf:normality} for
residual bootstrap normality test.

{phang}
{opt nboot(#)} specifies the number of bootstrap replications. Default
is 500.

{phang}
{opt blocksize(#)} specifies the block size for moving-block bootstrap.
Default is ceil(T^(1/3)).

{phang}
{opt ci(real)} specifies the confidence level for bootstrap intervals.
Default is 0.95.

{phang}
{opt seed(#)} sets the random number seed for reproducibility.

{dlgtab:Plots (plot)}

{phang}
{opt plottype(irf|fevd|eigenvalues)} specifies the type of plot:
{bf:irf} for impulse response functions (default), {bf:fevd} for
forecast error variance decomposition, or {bf:eigenvalues} for
companion matrix eigenvalue stability plot.

{phang}
{opt variable(numlist)} specifies which response variables to plot
(by index). Default is all.

{phang}
{opt shock(numlist)} specifies which shocks to plot (by index). Default
is all.

{phang}
{opt saving(string)} specifies a filename to export the graph.

{phang}
{opt title(string)} specifies a custom graph title.


{marker examples}{...}
{title:Examples}

{pstd}{bf:Setup}{p_end}
{phang2}{cmd:. webuse grunfeld2, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}{bf:1. Lag Order Selection}{p_end}
{phang2}{cmd:. xtpvarcoint speci var invest mvalue kstock, lagset(1 2 3 4)}{p_end}

{pstd}{bf:2. Factor Number Determination}{p_end}
{phang2}{cmd:. xtpvarcoint speci factors invest mvalue kstock, kmax(5) differenced centered}{p_end}
{phang2}{cmd:. xtpvarcoint speci factors invest mvalue kstock, kmax(8) centered scaled nfactors(3)}{p_end}

{pstd}{bf:3. Panel Cointegration (Johansen)}{p_end}
{phang2}{cmd:. xtpvarcoint pcoint invest mvalue kstock, method(JO) lags(2) type(Case3)}{p_end}

{pstd}{bf:4. Panel Cointegration (CAIN — CSD-robust)}{p_end}
{phang2}{cmd:. xtpvarcoint pcoint invest mvalue kstock, method(CAIN) lags(2) type(Case3)}{p_end}

{pstd}{bf:5. Panel Cointegration with per-unit lags}{p_end}
{phang2}{cmd:. xtpvarcoint pcoint invest mvalue kstock, method(JO) lags(1 2 3 2 1 2 3 2 1 2) type(Case3)}{p_end}

{pstd}{bf:6. Individual Cointegration Test (single unit)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if company == 1}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xtpvarcoint coint invest mvalue kstock, lags(2) type(Case3) method(JO)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}{bf:7. Panel VAR Estimation (Mean Group)}{p_end}
{phang2}{cmd:. xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)}{p_end}

{pstd}{bf:8. Panel VECM Estimation (rank = 1)}{p_end}
{phang2}{cmd:. xtpvarcoint pvec invest mvalue kstock, lags(2) rank(1) type(Case3)}{p_end}

{pstd}{bf:9. Individual VECM}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if company == 1}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xtpvarcoint vecm invest mvalue kstock, lags(2) rank(1) type(Case3)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}{bf:10. Impulse Response Functions}{p_end}
{phang2}{cmd:. xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)}{p_end}
{phang2}{cmd:. xtpvarcoint irf, horizon(20)}{p_end}
{phang2}{cmd:. xtpvarcoint irf, horizon(15) cumulative}{p_end}

{pstd}{bf:11. Orthogonal IRFs (after VECM)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if company == 1}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xtpvarcoint vecm invest mvalue kstock, lags(2) rank(1) type(Case3)}{p_end}
{phang2}{cmd:. xtpvarcoint irf, horizon(10) orthogonal}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}{bf:12. Forecast Error Variance Decomposition}{p_end}
{phang2}{cmd:. xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)}{p_end}
{phang2}{cmd:. xtpvarcoint fevd, horizon(20)}{p_end}

{pstd}{bf:13. SVAR Identification}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if company == 1}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xtpvarcoint vecm invest mvalue kstock, lags(2) rank(1) type(Case3)}{p_end}
{phang2}{cmd:. xtpvarcoint pid, method(chol)}{p_end}
{phang2}{cmd:. xtpvarcoint pid, method(grt)}{p_end}
{phang2}{cmd:. xtpvarcoint pid, method(dc) combine(pool)}{p_end}
{phang2}{cmd:. xtpvarcoint pid, method(cvm) itermax(200) steptol(50)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}{bf:14. Bootstrap Inference}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. keep if company == 1}{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xtpvarcoint vecm invest mvalue kstock, lags(2) rank(1) type(Case3)}{p_end}
{phang2}{cmd:. xtpvarcoint sboot, method(pmb) nboot(500) horizon(20) ci(0.95) seed(12345)}{p_end}
{phang2}{cmd:. xtpvarcoint sboot, method(mb) nboot(500) blocksize(3) horizon(10) ci(0.90)}{p_end}
{phang2}{cmd:. restore}{p_end}

{pstd}{bf:15. Publication-Quality Plots}{p_end}
{phang2}{cmd:. xtpvarcoint pvar invest mvalue kstock, lags(2) type(const)}{p_end}
{phang2}{cmd:. xtpvarcoint irf, horizon(20)}{p_end}
{phang2}{cmd:. xtpvarcoint plot, plottype(irf) title("IRF Plot")}{p_end}
{phang2}{cmd:. xtpvarcoint plot, plottype(irf) saving(irf_plot.png)}{p_end}
{phang2}{cmd:. xtpvarcoint fevd, horizon(20)}{p_end}
{phang2}{cmd:. xtpvarcoint plot, plottype(fevd) title("FEVD Plot")}{p_end}
{phang2}{cmd:. xtpvarcoint plot, plottype(eigenvalues) title("Stability")}{p_end}

{pstd}{bf:16. Panel VECM with per-unit lags}{p_end}
{phang2}{cmd:. xtpvarcoint pvec invest mvalue kstock, lags(2 2 1 2 2 1 2 2 1 2) rank(1) type(Case3)}{p_end}


{marker stored}{...}
{title:Stored results}

{pstd}
Results are stored as global Stata matrices and scalars with the prefix
{bf:_xpvc_}. These persist across successive {cmd:xtpvarcoint} calls.

{dlgtab:pcoint — Panel Cointegration}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_N}}number of panel individuals{p_end}
{synopt:{cmd:_xpvc_K}}number of endogenous variables{p_end}
{synopt:{cmd:_xpvc_rho_eps}}estimated cross-sectional correlation (CAIN only){p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_LRbar}}standardized LR_bar panel test statistics (JO/BR/SL){p_end}
{synopt:{cmd:_xpvc_LRbar_pval}}p-values for LR_bar{p_end}
{synopt:{cmd:_xpvc_Choi_P}}Fisher (Choi P) combination statistics{p_end}
{synopt:{cmd:_xpvc_Choi_Pm}}modified Fisher (Choi Pm) statistics{p_end}
{synopt:{cmd:_xpvc_Choi_Z}}inverse normal (Choi Z) statistics{p_end}
{synopt:{cmd:_xpvc_CAIN}}CAIN test statistics (CAIN only){p_end}
{synopt:{cmd:_xpvc_CAIN_pval}}CAIN p-values{p_end}
{synopt:{cmd:_xpvc_indiv_TR}}K x N matrix of individual trace statistics{p_end}
{synopt:{cmd:_xpvc_indiv_pval}}K x N matrix of individual p-values{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(method)}}test method (JO, BR, SL, or CAIN){p_end}
{synopt:{cmd:r(type)}}deterministic specification{p_end}

{dlgtab:coint — Individual Cointegration}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_K}}number of variables{p_end}
{synopt:{cmd:_xpvc_T}}effective sample size{p_end}
{synopt:{cmd:_xpvc_p}}lag order{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_eigenvalues}}eigenvalues{p_end}
{synopt:{cmd:_xpvc_trace_stat}}trace test statistics{p_end}
{synopt:{cmd:_xpvc_trace_pval}}trace p-values{p_end}
{synopt:{cmd:_xpvc_maxeig_stat}}max-eigenvalue test statistics{p_end}
{synopt:{cmd:_xpvc_maxeig_pval}}max-eigenvalue p-values{p_end}
{synopt:{cmd:_xpvc_beta}}cointegrating vectors{p_end}

{dlgtab:pvar — Panel VAR}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_N}}number of panel individuals{p_end}
{synopt:{cmd:_xpvc_K}}number of endogenous variables{p_end}
{synopt:{cmd:_xpvc_max_p}}maximum lag order{p_end}
{synopt:{cmd:_xpvc_max_eigenmod}}maximum companion eigenvalue modulus{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_A}}mean-group VAR coefficient matrix [A_1, ..., A_p]{p_end}
{synopt:{cmd:_xpvc_A_var}}variance of individual coefficient matrices{p_end}

{dlgtab:pvec — Panel VECM}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_N}}number of panel individuals{p_end}
{synopt:{cmd:_xpvc_K}}number of endogenous variables{p_end}
{synopt:{cmd:_xpvc_r}}cointegration rank{p_end}
{synopt:{cmd:_xpvc_max_p}}maximum lag order{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_A}}mean-group VAR coefficient matrix (levels){p_end}
{synopt:{cmd:_xpvc_alpha}}mean-group loading matrix (K x r){p_end}
{synopt:{cmd:_xpvc_beta}}mean-group cointegrating vectors{p_end}
{synopt:{cmd:_xpvc_PI}}mean-group long-run impact PI = alpha*beta'{p_end}
{synopt:{cmd:_xpvc_GAMMA}}mean-group short-run coefficients{p_end}

{dlgtab:vecm — Individual VECM}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_K}}number of variables{p_end}
{synopt:{cmd:_xpvc_T}}effective sample size{p_end}
{synopt:{cmd:_xpvc_p}}lag order{p_end}
{synopt:{cmd:_xpvc_r}}cointegration rank{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_A}}VAR coefficients in levels{p_end}
{synopt:{cmd:_xpvc_alpha}}loading matrix{p_end}
{synopt:{cmd:_xpvc_beta}}cointegrating vectors{p_end}
{synopt:{cmd:_xpvc_PI}}long-run impact matrix{p_end}
{synopt:{cmd:_xpvc_GAMMA}}short-run coefficients{p_end}
{synopt:{cmd:_xpvc_OMEGA}}MLE residual covariance{p_end}
{synopt:{cmd:_xpvc_SIGMA}}OLS residual covariance{p_end}
{synopt:{cmd:_xpvc_eigenvalues}}Johansen eigenvalues{p_end}

{dlgtab:pid — SVAR Identification}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_B}}structural impact matrix B{p_end}

{p2col 5 26 30 2: Macros}{p_end}
{synopt:{cmd:r(pid_method)}}identification method used{p_end}
{synopt:{cmd:r(pid_combine)}}combination approach{p_end}

{dlgtab:irf — Impulse Response Functions}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_horizon}}forecast horizon{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_IRF}}(H+1) x K^2 IRF matrix{p_end}
{synopt:{cmd:_xpvc_IRF_cum}}(H+1) x K^2 cumulative IRF (if requested){p_end}

{dlgtab:fevd — Variance Decomposition}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_FEVD}}(H+1) x K^2 FEVD matrix{p_end}

{dlgtab:sboot — Bootstrap}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars}{p_end}
{synopt:{cmd:_xpvc_nboot}}number of bootstrap replications{p_end}
{synopt:{cmd:_xpvc_ci_level}}confidence level{p_end}
{synopt:{cmd:_xpvc_blocksize}}block size used{p_end}

{p2col 5 26 30 2: Matrices}{p_end}
{synopt:{cmd:_xpvc_IRF}}(H+1) x K^2 point estimate IRF{p_end}
{synopt:{cmd:_xpvc_IRF_lo}}(H+1) x K^2 lower CI bounds{p_end}
{synopt:{cmd:_xpvc_IRF_hi}}(H+1) x K^2 upper CI bounds{p_end}

{dlgtab:speci — Specification Tools}

{synoptset 26 tabbed}{...}
{p2col 5 26 30 2: Scalars (speci var)}{p_end}
{synopt:{cmd:_xpvc_p_aic}}optimal lag by AIC{p_end}
{synopt:{cmd:_xpvc_p_hqc}}optimal lag by HQC{p_end}
{synopt:{cmd:_xpvc_p_sic}}optimal lag by SIC{p_end}
{synopt:{cmd:_xpvc_p_fpe}}optimal lag by FPE{p_end}

{p2col 5 26 30 2: Matrices (speci var)}{p_end}
{synopt:{cmd:_xpvc_IC_table}}information criteria table{p_end}

{p2col 5 26 30 2: Scalars (speci factors)}{p_end}
{synopt:{cmd:_xpvc_r_ONC}}Onatski edge-distribution estimate{p_end}
{synopt:{cmd:_xpvc_r_ER}}Ahn-Horenstein eigenvalue ratio estimate{p_end}
{synopt:{cmd:_xpvc_r_GR}}Ahn-Horenstein growth ratio estimate{p_end}
{synopt:{cmd:_xpvc_r_IC1}}Bai-Ng IC(p1) estimate{p_end}
{synopt:{cmd:_xpvc_r_IC2}}Bai-Ng IC(p2) estimate{p_end}
{synopt:{cmd:_xpvc_r_IC3}}Bai-Ng IC(p3) estimate{p_end}

{p2col 5 26 30 2: Matrices (speci factors)}{p_end}
{synopt:{cmd:_xpvc_eigenvalues}}eigenvalues from SVD{p_end}
{synopt:{cmd:_xpvc_IC}}information criterion values{p_end}
{synopt:{cmd:_xpvc_Ft}}estimated factors (if nfactors > 0){p_end}
{synopt:{cmd:_xpvc_LAMBDA}}factor loadings (if nfactors > 0){p_end}


{marker references}{...}
{title:References}

{phang}
Ahn, S. and Horenstein, A. (2013). Eigenvalue ratio test for the
number of factors. {it:Econometrica}, 81, pp. 1203-1227.

{phang}
Arsova, A. and Oersal, D. (2018). Likelihood-based panel cointegration
test in the presence of a linear time trend and cross-sectional
dependence. {it:Econometric Theory}, 34, pp. 1033-1073.

{phang}
Arsova, A. and Oersal, D. (2021). A panel cointegration test under
cross-sectional dependence. {it:Econometrics and Statistics}, 17,
pp. 38-51.

{phang}
Bai, J. and Ng, S. (2002). Determining the number of factors in
approximate factor models. {it:Econometrica}, 70, pp. 191-221.

{phang}
Bai, J. and Ng, S. (2004). A PANIC attack on unit roots and
cointegration. {it:Econometrica}, 72, pp. 1127-1177.

{phang}
Blanchard, O. and Quah, D. (1989). The dynamic effects of aggregate
demand and supply disturbances. {it:American Economic Review}, 79,
pp. 655-673.

{phang}
Breitung, J. (2005). A parametric approach to the estimation of
cointegration vectors in panel data. {it:Econometric Reviews}, 24,
pp. 151-173.

{phang}
Doornik, J. (1998). Approximations to the asymptotic distribution
of cointegration tests. {it:Journal of Economic Surveys}, 12,
pp. 573-593.

{phang}
Johansen, S. (1995). {it:Likelihood-based Inference in Cointegrated}
{it:Vector Autoregressive Models}. Oxford University Press.

{phang}
Kilian, L. (1998). Small-sample confidence intervals for impulse
response functions. {it:Review of Economics and Statistics}, 80,
pp. 218-230.

{phang}
Larsson, R., Lyhagen, J., and Lothgren, M. (2001). Likelihood-based
cointegration tests in heterogeneous panels.
{it:The Econometrics Journal}, 4, pp. 109-142.

{phang}
Luetkepohl, H. (2005). {it:New Introduction to Multiple Time Series}
{it:Analysis}. Springer, 2nd ed.

{phang}
Onatski, A. (2010). Determining the number of factors from empirical
distribution of eigenvalues. {it:Review of Economics and Statistics},
92, pp. 1004-1016.

{phang}
Pesaran, M.H., Shin, Y., and Smith, R.J. (1999). Pooled mean group
estimation of dynamic heterogeneous panels.
{it:Journal of the American Statistical Association}, 94, pp. 621-634.

{phang}
Saikkonen, P. and Luetkepohl, H. (2000). Testing for the cointegrating
rank of a VAR process with structural shifts.
{it:Journal of Business and Economic Statistics}, 18, pp. 451-464.


{marker version_history}{...}
{title:Version history}

{pstd}
{bf:1.0.1} (05apr2026){break}
Fixed conformability error (r3200) in {bf:pvec} when using heterogeneous
per-unit lag orders. GAMMA matrices of varying dimensions are now
zero-padded to a common size before mean-group averaging.{break}
All 37 tests pass (0 failures).

{pstd}
{bf:1.0.0} (03apr2026){break}
Initial release. Port of the R package pvars.


{marker authors}{...}
{title:Authors}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}

{pstd}
Please cite as:{break}
Roudane, M. (2026). xtpvarcoint: Panel VAR modeling with cointegration,
structural breaks, and cross-sectional dependence.
Statistical Software Components, Boston College Department of Economics.
{p_end}
