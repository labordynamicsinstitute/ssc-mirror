{smcl}
{* *! version 1.1.0  06may2026}{...}
{viewerjumpto "Syntax" "xtpanelcoint##syntax"}{...}
{viewerjumpto "Description" "xtpanelcoint##description"}{...}
{viewerjumpto "Estimators" "xtpanelcoint##estimators"}{...}
{viewerjumpto "Options" "xtpanelcoint##options"}{...}
{viewerjumpto "Stored results" "xtpanelcoint##stored"}{...}
{viewerjumpto "Visualization" "xtpanelcoint##plots"}{...}
{viewerjumpto "Examples" "xtpanelcoint##examples"}{...}
{viewerjumpto "References" "xtpanelcoint##references"}{...}
{viewerjumpto "Author" "xtpanelcoint##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{bf:xtpanelcoint} {hline 2}}Panel cointegration and multiple long-run
relations estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
{bf:Bivariate long-run coefficient estimators}

{p 8 17 2}
{cmd:xtpanelcoint} {it:estimator} {depvar} {indepvar} {ifin}
[{cmd:,} {it:options}]

{pstd}
where {it:estimator} is one of:  {bf:spmg}, {bf:breitung}, {bf:pdols},
or {bf:mgmw}

{pstd}
{bf:Mean Group Distributed Lag (IRF estimation)}

{p 8 17 2}
{cmd:xtpanelcoint mgdl} {depvar} {it:shockvar} {ifin}{cmd:,}
{cmdab:prod:uct(}{varname}{cmd:)} {cmdab:loc:ation(}{varname}{cmd:)}
[{it:mgdl_options}]

{pstd}
{bf:Pooled Minimum Eigenvalue (multiple long-run relations)}

{p 8 17 2}
{cmd:xtpanelcoint pme} {varlist} {ifin} [{cmd:,} {it:pme_options}]

{pstd}
{bf:Post-estimation visualization}

{p 8 17 2}
{cmd:xtpanelcoint plot} [{cmd:,} {it:plot_options}]


{synoptset 28 tabbed}{...}
{marker options}{...}
{synopthdr:Options}
{synoptline}

{syntab:{it:SPMG options}}
{synopt:{cmdab:l:ags(}{it:#}{cmd:)}}lag order for ARDL specification;
default is {bf:lags(2)}{p_end}
{synopt:{cmdab:max:iter(}{it:#}{cmd:)}}maximum iterations;
default is {bf:maxiter(500)}{p_end}
{synopt:{cmdab:prec:ision(}{it:#}{cmd:)}}convergence tolerance;
default is {bf:precision(1e-4)}{p_end}
{synopt:{cmdab:boot:strap(}{it:#}{cmd:)}}number of wild bootstrap
replications; default is {bf:bootstrap(0)} (off){p_end}
{synopt:{cmd:seed(}{it:#}{cmd:)}}random seed for bootstrap;
default is {bf:seed(1234)}{p_end}

{syntab:{it:Breitung options}}
{synopt:{cmdab:l:ags(}{it:#}{cmd:)}}lag order; default is {bf:lags(2)}{p_end}

{syntab:{it:PDOLS options}}
{synopt:{cmdab:leads:lags(}{it:#}{cmd:)}}number of leads and lags of
{cmd:D.}{it:x}; default is {bf:leadslags(4)}{p_end}

{syntab:{it:MGMW options}}
{synopt:{cmdab:sub:periods(}{it:#}{cmd:)}}number of sub-periods for temporal
aggregation; default is {bf:subperiods(5)}{p_end}

{syntab:{it:MGDL options}}
{synopt:{cmdab:prod:uct(}{varname}{cmd:)}}variable identifying product
groups; {bf:required}{p_end}
{synopt:{cmdab:loc:ation(}{varname}{cmd:)}}variable identifying location
groups; {bf:required}{p_end}
{synopt:{cmdab:hor:izon(}{it:#}{cmd:)}}IRF horizon;
default is {bf:horizon(4)}{p_end}
{synopt:{cmdab:aug:mented}}use augmented variance estimator for robust
inference{p_end}
{synopt:{cmdab:bonf:erroni}}apply Bonferroni correction for family-wise
error rate{p_end}

{syntab:{it:PME options}}
{synopt:{cmdab:sub:samples(}{it:#}{cmd:)}}number of sub-sample periods
(q {&ge} 2); default is {bf:subsamples(2)}{p_end}
{synopt:{cmdab:del:ta(}{it:#}{cmd:)}}thresholding exponent for rank
estimation; default is {bf:delta(0.25)}{p_end}
{synopt:{cmd:rank(}{it:#}{cmd:)}}fix the number of long-run relations
r{subscript:0} (bypasses automatic estimation){p_end}

{syntab:{it:Plot options}}
{synopt:{cmdab:ty:pe(}{it:string}{cmd:)}}plot type: {bf:coeff}, {bf:compare},
{bf:irf}, {bf:eigenvalue}, {bf:cumulative}{p_end}
{synopt:{cmdab:sav:ing(}{it:filename}{cmd:)}}save graph to file
(supports .png, .pdf, .eps){p_end}
{synopt:{cmdab:ti:tle(}{it:string}{cmd:)}}custom graph title{p_end}
{synopt:{cmdab:sub:title(}{it:string}{cmd:)}}custom graph subtitle{p_end}
{synopt:{cmdab:com:pare}}compare stored estimates (requires prior
{cmd:estimates store}){p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtpanelcoint} implements a suite of panel cointegration estimators for
long-run relations in heterogeneous panels where both N and T are large. The
package provides six estimators and publication-quality visualization tools.

{pstd}
The panel must be declared via {helpb xtset} and must be strongly balanced.
All estimators post results to {cmd:e()} and support {cmd:estimates store}.

{pstd}
This is the Stata implementation of the Python {bf:multicoint} library (v1.1.0),
which translates the original MATLAB replication code from the authors'
academic papers.


{marker estimators}{...}
{title:Estimators}

{dlgtab:SPMG â€” System Pooled Mean Group}

{pstd}
The SPMG estimator of Chudik, Pesaran & Smith (2023) maximizes the system
log-likelihood for the bivariate VECM:

{p 8 8 2}
{&Delta}w{subscript:it} = -{&phi}{subscript:i} {&beta}' w{subscript:i,t-1}
+ {&Upsilon}{subscript:i} q{subscript:it} + u{subscript:it}

{pstd}
where w{subscript:it} = (y{subscript:it}, x{subscript:it})',
{&beta} = (1, -{&theta})', and
{&phi}{subscript:i} = ({&phi}{subscript:yi}, {&phi}{subscript:xi})'.

{pstd}
Key properties:{break}
{space 3}{c -} Handles {bf:two-way long-run causality} between y and x{break}
{space 3}{c -} {bf:Robust to non-cointegrating units} ({&phi}{subscript:i} {&rarr} 0 contributes negligibly){break}
{space 3}{c -} {bf:Invariant to normalization}: {&theta}{subscript:y.x} {&middot} {&theta}{subscript:x.y} = 1{break}
{space 3}{c -} Optional {bf:wild bootstrap} confidence intervals

{dlgtab:Breitung â€” Two-Step Parametric}

{pstd}
The Breitung (2005) two-step estimator:{break}
{space 3}Step 1: Unit-by-unit Engle-Granger to get {&beta}{subscript:i}, {&alpha}{subscript:i}, {&Sigma}{subscript:i}{break}
{space 3}Step 2: Pooled regression on transformed variables z{superscript:+}{subscript:it}

{pstd}
Uses heteroskedasticity-robust standard errors. Non-iterative.

{dlgtab:PDOLS â€” Panel Dynamic OLS}

{pstd}
The Panel DOLS estimator of Mark & Sul (2003) augments the cointegrating
regression with leads and lags of {&Delta}x{subscript:it} to correct for
endogeneity. Heteroskedasticity-robust standard errors.

{dlgtab:MGMW â€” MÃ¼ller-Watson Mean Group}

{pstd}
The MGMW estimator uses temporal aggregation (sub-period averaging) to
estimate long-run coefficients. Robust to unknown forms of serial
correlation.

{dlgtab:MGDL â€” Mean Group Distributed Lag}

{pstd}
The MGDL estimator of Choi & Chudik (2024) estimates impulse response
functions of common observed shocks in large panels with a
product{times}location{times}time structure:{break}

{p 8 8 2}
x{subscript:ijt} = a{subscript:ij} + {&Sigma}{subscript:{&ell}=0}{superscript:h}
b{subscript:ij{&ell}} v{subscript:t-{&ell}} + controls + e{subscript:ijt}

{pstd}
Returns product-level IRFs, location effects c{subscript:j}, and cumulative
multipliers with optional Bonferroni-corrected confidence intervals.

{dlgtab:PME â€” Pooled Minimum Eigenvalue}

{pstd}
The PME estimator of Chudik, Pesaran & Smith (2025) estimates r{subscript:0}
long-run relations in panel data with m > 2 variables, using sub-sample
time averages and eigenvalue decomposition:{break}

{p 8 8 2}
Q{subscript:wÌ„wÌ„} = (nTq){superscript:-1} {&Sigma} {&Sigma}
(wÌ„{subscript:i{&ell}} - wÌ„{subscript:i.})(wÌ„{subscript:i{&ell}} - wÌ„{subscript:i.})'

{pstd}
The number of long-run relations is estimated by counting eigenvalues below
the threshold T{superscript:-{&delta}}. Identified coefficients and
asymptotic inference are provided.


{marker plots}{...}
{title:Visualization}

{pstd}
After estimation, call {cmd:xtpanelcoint plot} for publication-quality
graphs:

{pstd}
{bf:Coefficient plot} (SPMG, Breitung, PDOLS, MGMW):{break}
{space 3}{cmd:xtpanelcoint plot}{break}
{space 3}{cmd:xtpanelcoint plot, saving(fig_coeff.png)}

{pstd}
{bf:Multi-estimator comparison} (requires {cmd:estimates store}):

{p 8 8 2}
{cmd:xtpanelcoint spmg y x, lags(2)}{break}
{cmd:estimates store spmg}{break}
{cmd:xtpanelcoint breitung y x, lags(2)}{break}
{cmd:estimates store breitung}{break}
{cmd:xtpanelcoint plot, type(compare)}

{pstd}
{bf:IRF plot} (after MGDL estimation):{break}
{space 3}{cmd:xtpanelcoint plot, type(irf)}

{pstd}
{bf:Eigenvalue scree plot} (after PME estimation):{break}
{space 3}{cmd:xtpanelcoint plot, type(eigenvalue)}

{pstd}
{bf:Cumulative multiplier bar chart} (after MGDL estimation):{break}
{space 3}{cmd:xtpanelcoint plot, type(cumulative)}


{marker stored}{...}
{title:Stored results}

{pstd}
{bf:All bivariate estimators} (SPMG, Breitung, PDOLS, MGMW) store:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(theta)}}estimated long-run coefficient {&theta}{p_end}
{synopt:{cmd:e(se)}}asymptotic standard error{p_end}
{synopt:{cmd:e(t_ratio)}}t-ratio for H{subscript:0}: {&theta} = 1{p_end}
{synopt:{cmd:e(p_value)}}two-sided p-value{p_end}
{synopt:{cmd:e(ci95_lo)}}lower bound of 95% asymptotic CI{p_end}
{synopt:{cmd:e(ci95_hi)}}upper bound of 95% asymptotic CI{p_end}
{synopt:{cmd:e(boot_ci_lo)}}lower bound of 95% bootstrap CI (if computed){p_end}
{synopt:{cmd:e(boot_ci_hi)}}upper bound of 95% bootstrap CI (if computed){p_end}
{synopt:{cmd:e(N_g)}}number of panels (cross-sections){p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(lags)}}lag order used{p_end}
{synopt:{cmd:e(n_iter)}}number of iterations (iterative estimators){p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}xtpanelcoint{p_end}
{synopt:{cmd:e(estimator)}}estimator name{p_end}
{synopt:{cmd:e(estimator_type)}}estimator code (spmg, breitung, etc.){p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvar)}}independent variable name{p_end}

{pstd}
{bf:MGDL} additionally stores:

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(M_products)}}number of product groups{p_end}
{synopt:{cmd:e(N_locations)}}number of location groups{p_end}
{synopt:{cmd:e(horizon)}}IRF horizon{p_end}
{synopt:{cmd:e(cum_mult)}}M{times}1 matrix of cumulative multipliers{p_end}
{synopt:{cmd:e(cum_ci_lo)}}lower CI bounds{p_end}
{synopt:{cmd:e(cum_ci_hi)}}upper CI bounds{p_end}
{synopt:{cmd:e(product_irfs)}}M{times}(h+1) matrix of product-level IRFs{p_end}
{synopt:{cmd:e(location_irfs)}}N{times}(h+1) matrix of location effects c_j{p_end}
{synopt:{cmd:e(significant)}}M{times}1 significance indicator{p_end}

{pstd}
{bf:PME} additionally stores:

{synoptset 24 tabbed}{...}
{synopt:{cmd:e(r_hat)}}estimated number of long-run relations{p_end}
{synopt:{cmd:e(m_vars)}}number of variables{p_end}
{synopt:{cmd:e(eigenvalues)}}m{times}1 vector of eigenvalues (ascending){p_end}
{synopt:{cmd:e(Theta)}}(m-r){times}r matrix of identified coefficients{p_end}
{synopt:{cmd:e(Theta_se)}}standard errors of Theta{p_end}
{synopt:{cmd:e(Theta_t)}}t-ratios{p_end}
{synopt:{cmd:e(Theta_p)}}p-values{p_end}
{synopt:{cmd:e(Q_ww)}}m{times}m pooled covariance matrix{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Consumption-GDP great ratio (JST data)}

{pstd}
Replicates Chudik, Pesaran & Smith (2023) Table 4, Application 1.
Uses 13 countries with complete data from 1870-2016 (T=147).

{phang2}{cmd:. import excel "JSTdatasetR4.xlsx", sheet("Data") firstrow clear}{p_end}
{phang2}{cmd:. keep year iso rgdppc rconpc}{p_end}
{phang2}{cmd:. encode iso, gen(country_id)}{p_end}
{phang2}{cmd:. gen ln_con = ln(rconpc)}{p_end}
{phang2}{cmd:. gen ln_gdp = ln(rgdppc)}{p_end}
{phang2}{cmd:. xtset country_id year}{p_end}
{phang2}{cmd:. keep if ln_con != . & ln_gdp != .}{p_end}
{phang2}{cmd:. bysort country_id: gen _T = _N}{p_end}
{phang2}{cmd:. keep if _T == 147}{p_end}
{phang2}{cmd:. drop _T}{p_end}
{phang2}{cmd:. xtset country_id year}{p_end}

{pstd}
{bf:SPMG with wild bootstrap (recommended):}

{phang2}{cmd:. xtpanelcoint spmg ln_con ln_gdp, lags(2) bootstrap(500) seed(1234)}{p_end}
{phang2}  {it:theta = 0.902, SE = 0.007, Bootstrap 95% CI: [0.864, 0.940]}{p_end}
{phang2}  {it:H0: theta=1 rejected â€” consumption-GDP ratio is NOT a great ratio}{p_end}

{pstd}
{bf:Multi-estimator comparison:}

{phang2}{cmd:. xtpanelcoint spmg ln_con ln_gdp, lags(2)}{p_end}
{phang2}{cmd:. estimates store spmg}{p_end}
{phang2}{cmd:. xtpanelcoint breitung ln_con ln_gdp, lags(2)}{p_end}
{phang2}{cmd:. estimates store breitung}{p_end}
{phang2}{cmd:. xtpanelcoint pdols ln_con ln_gdp, leadslags(4)}{p_end}
{phang2}{cmd:. estimates store pdols}{p_end}
{phang2}{cmd:. xtpanelcoint mgmw ln_con ln_gdp, subperiods(5)}{p_end}
{phang2}{cmd:. estimates store mgmw}{p_end}
{phang2}{cmd:. xtpanelcoint plot, type(compare)}{p_end}

{pstd}
{bf:Example 2: Term structure â€” short rate / long rate}

{pstd}
Tests whether the term spread is stationary (4 countries, T=147).

{phang2}{cmd:. xtpanelcoint spmg short_r long_r, lags(2) bootstrap(500) seed(42)}{p_end}
{phang2}  {it:theta = 0.921, SE = 0.044, Bootstrap 95% CI: [0.748, 1.094]}{p_end}
{phang2}  {it:H0: theta=1 NOT rejected â€” term spread IS stationary}{p_end}

{pstd}
{bf:Example 3: PME with three variables (consumption, GDP, investment)}

{phang2}{cmd:. gen ln_inv = ln(iy * gdp)}{p_end}
{phang2}{cmd:. xtpanelcoint pme ln_con ln_gdp ln_inv, subsamples(3) delta(0.25)}{p_end}
{phang2}  {it:r_hat = 2 â€” two cointegrating relations among three variables}{p_end}
{phang2}  {it:Implies one common stochastic trend driving all three series}{p_end}
{phang2}{cmd:. xtpanelcoint plot, type(eigenvalue)}{p_end}

{pstd}
{bf:Example 4: MGDL impulse responses (product x location panel)}

{phang2}{cmd:. * Requires product x location x time panel structure}{p_end}
{phang2}{cmd:. xtset panel_id time}{p_end}
{phang2}{cmd:. xtpanelcoint mgdl dlnprice oilshock, product(product_id) location(city_id) horizon(6) augmented bonferroni}{p_end}
{phang2}{cmd:. xtpanelcoint plot, type(irf) saving(fig_irf.png)}{p_end}
{phang2}{cmd:. xtpanelcoint plot, type(cumulative) saving(fig_cum.png)}{p_end}

{pstd}
{bf:Example 5: Simulated DGP (theta = 1)}

{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. local N = 20}{p_end}
{phang2}{cmd:. local T = 100}{p_end}
{phang2}{cmd:. set obs `=`N'*`T''}{p_end}
{phang2}{cmd:. gen id = ceil(_n/`T')}{p_end}
{phang2}{cmd:. bysort id: gen time = _n}{p_end}
{phang2}{cmd:. xtset id time}{p_end}
{phang2}{cmd:. gen double x = 0}{p_end}
{phang2}{cmd:. gen double y = 0}{p_end}
{phang2}{cmd:. gen double u = 0}{p_end}
{phang2}{cmd:. bysort id (time): replace x = x[_n-1] + rnormal() if _n > 1}{p_end}
{phang2}{cmd:. bysort id (time): replace u = 0.5*u[_n-1] + rnormal()*0.5 if _n > 1}{p_end}
{phang2}{cmd:. replace y = x + u}{p_end}
{phang2}{cmd:. xtpanelcoint spmg y x, lags(2) bootstrap(200) seed(42)}{p_end}
{phang2}  {it:theta = 1.008, SE = 0.005, Bootstrap CI: [0.994, 1.022]}{p_end}
{phang2}  {it:H0: theta=1 not rejected â€” correctly recovers true theta=1}{p_end}


{marker references}{...}
{title:References}

{phang}
Breitung, J. (2005). A parametric approach to the estimation of cointegration
vectors in panel data. {it:Econometric Reviews} 24(2), 151{c -}173.
{p_end}

{phang}
Choi, C.-Y. & Chudik, A. (2024). Mean group distributed lag estimation of
impulse response functions in large panels. Federal Reserve Bank of Dallas,
Globalization Institute Working Paper 0423r1.
{p_end}

{phang}
Chudik, A., Pesaran, M.H. & Smith, R.P. (2023). Revisiting the great ratios
hypothesis. Federal Reserve Bank of Dallas, Globalization Institute Working
Paper 415.
{p_end}

{phang}
Chudik, A., Pesaran, M.H. & Smith, R.P. (2025). Estimation of multiple
long-run relations in panels. arXiv:2506.02135v3.
{p_end}

{phang}
Mark, N.C. & Sul, D. (2003). Cointegration vector estimation by panel DOLS
and long-run money demand. {it:Oxford Bulletin of Economics and Statistics}
65(5), 655{c -}680.
{p_end}

{phang}
Pesaran, M.H., Shin, Y. & Smith, R.P. (1999). Pooled mean group estimation
of dynamic heterogeneous panels. {it:Journal of the American Statistical
Association} 94(446), 621{c -}634.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane/multicointt"}{break}

{pstd}
Python version: {browse "https://pypi.org/project/multicoint/":multicoint} (PyPI)

{pstd}
Please cite as:{break}
Roudane, M. (2026). xtpanelcoint: Panel Cointegration and Multiple Long-Run
Relations Estimation for Stata. Statistical Software Components.


{title:Also see}

{psee}
Online: {helpb xtpmg}, {helpb xtset}, {helpb estimates}
{p_end}

