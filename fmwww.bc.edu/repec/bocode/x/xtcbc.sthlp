{smcl}
{* *! version 1.1.0  28mar2026}{...}
{cmd:help xtcbc} {right:version 1.1.0}
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:xtcbc} {hline 2}}Coefficient-by-Coefficient Breaks in Panel Data Models{p_end}
{p2colreset}{...}


{title:Version}

{pstd}
Version 1.1.0, 28 March 2026{p_end}

{pstd}
{bf:Author:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}){p_end}

{pstd}
Implements the CBCL estimator of Kaddoura (2025, {it:Journal of Econometrics}).{p_end}


{title:Syntax}

{p 8 16 2}{cmd:xtcbc} {depvar} {indepvars} {ifin} [{cmd:,} {it:options}]{p_end}


{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Penalty settings}
{synopt:{opt kap:pa(#)}}weight exponent for adaptive weights; default is {cmd:kappa(2)}{p_end}
{synopt:{opt ngr:id(#)}}number of lambda grid points; default is {cmd:ngrid(50)}{p_end}
{synopt:{opt cons:tant(#)}}BIC-type penalty constant c; default is {cmd:constant(0.05)}{p_end}

{syntab:Data transformation}
{synopt:{opt csd:emean}}cross-section demean data to partial out interactive effects{p_end}

{syntab:Reporting}
{synopt:{opt gr:aph}}produce coefficient path, IC, and break timeline graphs{p_end}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:xtset} your data before using {cmd:xtcbc}; see {helpb xtset}.{p_end}
{p 4 6 2}
The panel must be strongly balanced (no gaps).{p_end}


{title:Description}

{pstd}
{cmd:xtcbc} implements the {bf:Coefficient-by-Coefficient Lasso (CBCL)} break
estimator proposed by Kaddoura (2025). Unlike traditional structural break
methods that estimate {it:vector breaks} (where all parameters shift simultaneously),
{cmd:xtcbc} allows each coefficient to have its {it:own} number of breaks and
break dates.{p_end}

{pstd}
In a panel regression y_it = x'_it * beta_t + u_it, the vector-break approach
assumes all p components of beta_t change at the same dates. The CBC approach
relaxes this: the kth component beta_{k,t} can have m_k breaks, independently
for each k = 1, ..., p.{p_end}

{pstd}
The method is designed for panels with {bf:large N} and {bf:fixed or small T}.
Asymptotics rely on N -> infinity.{p_end}

{pstd}
{bf:Key features:}{p_end}
{p 8 12 2}1. {bf:Automatic break detection:} Simultaneously determines the number and location of breaks for each coefficient.{p_end}
{p 8 12 2}2. {bf:Adaptive penalization:} Uses L1 fused penalty with adaptive weights that are asymptotically oracle-equivalent.{p_end}
{p 8 12 2}3. {bf:Post-selection estimation:} Re-estimates coefficients in each regime using sub-regime OLS (Appendix B).{p_end}
{p 8 12 2}4. {bf:Information criterion:} Selects optimal lambda via a BIC-type IC (Theorem 1.4).{p_end}
{p 8 12 2}5. {bf:Fixed-effects handling:} Eliminates individual effects via first-period deviation.{p_end}


{title:Options}

{dlgtab:Penalty settings}

{phang}
{opt kappa(#)} specifies the exponent for adaptive weights:{p_end}

{p 8 12 2}w_{k,t} = |beta_dot_{k,t} - beta_dot_{k,t-1}|^(-kappa){p_end}

{pstd}
where beta_dot are the initial partialed-out OLS estimates. Larger kappa
puts stronger penalty on small differences. Default is {cmd:kappa(2)},
following Qian and Su (2016) and Kaddoura (2025).{p_end}

{phang}
{opt ngrid(#)} specifies the number of log-spaced grid points for lambda.
The algorithm evaluates the CBCL objective at each point and selects the
lambda minimizing the information criterion. Default is {cmd:ngrid(50)}.{p_end}

{phang}
{opt constant(#)} specifies the constant c in the BIC-type penalty:{p_end}

{p 8 12 2}phi = c * log(N) / sqrt(N){p_end}

{pstd}
Default is {cmd:constant(0.05)}. Results are not very sensitive to c
within a reasonable range (0.01 to 0.10).{p_end}

{dlgtab:Data transformation}

{phang}
{opt csdemean} cross-section demeans data before estimation. Removes
cross-sectional means from both dependent and independent variables at
each time period. Useful for models with interactive/common factor effects,
following Kaddoura and Westerlund (2023).{p_end}

{dlgtab:Reporting}

{phang}
{opt graph} produces three diagnostic graphs saved as PNG files:{p_end}

{p 8 12 2}1. {bf:xtcbc_coefficients.png:} Multi-panel graph showing coefficient paths beta_{k,t} over time. Dashed red lines mark detected break dates.{p_end}
{p 8 12 2}2. {bf:xtcbc_ic.png:} IC_1(lambda) vs log(lambda). Dashed red line marks optimal lambda*.{p_end}
{p 8 12 2}3. {bf:xtcbc_timeline.png:} Break timeline with coefficients on y-axis, time on x-axis.{p_end}

{phang}
{opt level(#)} specifies confidence level. Default is {cmd:level(95)}.{p_end}


{title:Methodology}

{pstd}
{bf:1. Data Generating Process}{p_end}

{pstd}
Consider the fixed-effects panel model:{p_end}

{p 8 12 2}y_it = xi_i + x'_it * beta_t + epsilon_it,  i = 1,...,N,  t = 1,...,T{p_end}

{pstd}
where xi_i are individual fixed effects. The kth component follows:{p_end}

{p 8 12 2}beta_{k,t} = alpha_{k,j}  for  T_{k,j-1} <= t < T_{k,j},  j = 1,...,m_k+1{p_end}

{pstd}
where m_k is the number of breaks for coefficient k. Each coefficient
is free to have a different m_k and different break dates.{p_end}


{pstd}
{bf:2. Fixed Effects Elimination}{p_end}

{pstd}
Fixed effects are eliminated via first-period deviation:{p_end}

{p 8 12 2}ytilde_it = y_it - y_i1 = x'_it * beta_t - x'_i1 * beta_1 + (eps_it - eps_i1){p_end}


{pstd}
{bf:3. Initial Estimates (Partialed-Out OLS, Eq 2.4)}{p_end}

{pstd}
For each k and t, the initial estimate beta_dot_{k,t} is obtained by
partialing out all other regressors:{p_end}

{p 8 12 2}beta_dot_{k,t} = [X'_{k,t} M_{-k,t} X_{k,t}]^(-1) * X'_{k,t} M_{-k,t} ytilde_t{p_end}

{pstd}
where M_A = I - A*(A'A)^(-1)*A' and X_{-k,t} includes all other regressors
at time t plus all first-period regressors.{p_end}


{pstd}
{bf:4. CBCL Objective Function (Eq 2.3)}{p_end}

{pstd}
The penalized estimates minimize:{p_end}

{p 8 12 2}L_lambda(beta) = (1/N) * SUM_i SUM_{t>=2} [ytilde_it - xbar'_it * beta]^2{p_end}
{p 8 12 2}{space 14}+ lambda * SUM_{t>=2} SUM_k w_{k,t} * |beta_{k,t} - beta_{k,t-1}|{p_end}

{pstd}
The L1 fused penalty encourages consecutive coefficients to be equal (fusing
them into regimes). Adaptive weights ensure true breaks are not over-penalized.
The estimator uses block coordinate descent with soft-thresholding and
bidirectional sweeps.{p_end}


{pstd}
{bf:5. Post-Selection Estimation (Eq 2.5, Appendix B)}{p_end}

{pstd}
After detecting breaks, the post-selection estimator computes regime-specific
coefficients using sub-regime OLS:{p_end}

{p 8 12 2}alpha_{k,j} = [X'_{k,r} M_{X_breve} X_{k,r}]^(-1) * X'_{k,r} M_{X_breve} ytilde_r{p_end}

{pstd}
where r = r_{k,j} is the jth regime and M_{X_breve} projects out block-diagonal
matrices of other coefficients' sub-regimes.{p_end}

{pstd}
{bf:Sub-regime construction:} For coefficient k in regime j, the other
coefficients ell != k may break at different dates. The estimator creates
sub-regime intersection sets r^(k,j)_{ell,c} = r_{k,j} INTERSECT ell's cth regime.
This builds block-diagonal regressor matrices X_breve_ell.{p_end}


{pstd}
{bf:6. Asymptotic Distribution (Theorem 1.3)}{p_end}

{p 8 12 2}sqrt(N) * O^(1/2) * (alpha_hat - alpha_0) -> N(0, Theta_0^{-1} * Sigma_0 * Theta_0^{-1}){p_end}

{pstd}
Standard errors come from the post-selection residual variance
and the cross-products of partialed-out regressors.{p_end}


{pstd}
{bf:7. Tuning Parameter Selection (Theorem 1.4)}{p_end}

{pstd}
Lambda is selected by minimizing a BIC-type information criterion:{p_end}

{p 8 12 2}IC_1(lambda) = sigma^2_hat(lambda) + phi * SUM_k [mhat_k(lambda) + 1]{p_end}

{pstd}
where:{p_end}
{p 8 12 2}- sigma^2_hat is the post-selection residual variance{p_end}
{p 8 12 2}- mhat_k(lambda) is the detected number of breaks for coefficient k{p_end}
{p 8 12 2}- phi = c * log(N) / sqrt(N) is the model complexity penalty{p_end}

{pstd}
By Theorem 1.4, minimizing IC_1 consistently selects the true number
of breaks as N -> infinity.{p_end}


{title:Output Tables}

{pstd}
{cmd:xtcbc} produces four publication-quality output tables:{p_end}

{p 8 12 2}1. {bf:Header:} Model specifications: dependent variable, regressors, panel dimensions (N, T), penalty settings (kappa, c), and optimal lambda.{p_end}
{p 8 12 2}2. {bf:Break Detection:} For each coefficient k, reports the number of breaks mhat_k and estimated break dates. Non-breaking coefficients marked {it:none}.{p_end}
{p 8 12 2}3. {bf:Post-Selection Estimates:} Regime-specific coefficients with standard errors, t-statistics, and significance stars (* p<0.10, ** p<0.05, *** p<0.01).{p_end}
{p 8 12 2}4. {bf:CBC Estimation Results (Table 6 format):} Paper-style table with "No breaks" column for stable coefficients and regime-specific columns for breaking coefficients.{p_end}


{title:Stored Results}

{pstd}
{cmd:xtcbc} stores the following in {cmd:e()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of cross-sectional units{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(p)}}number of regressors{p_end}
{synopt:{cmd:e(kappa)}}adaptive weight exponent{p_end}
{synopt:{cmd:e(ngrid)}}number of lambda grid points{p_end}
{synopt:{cmd:e(c_const)}}BIC penalty constant c{p_end}
{synopt:{cmd:e(opt_lambda)}}optimal tuning parameter lambda*{p_end}
{synopt:{cmd:e(total_breaks)}}total breaks across all coefficients{p_end}
{synopt:{cmd:e(nbreaks_k)}}breaks for coefficient k (k=1,...,p){p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(nbreaks)}}1 x p vector of break counts{p_end}
{synopt:{cmd:e(break_dates)}}max_breaks x p matrix of break dates{p_end}
{synopt:{cmd:e(alpha_info)}}n_alpha x 6 matrix: col 1=k, col 2=regime j, col 3=start, col 4=end, col 5=coef, col 6=SE{p_end}
{synopt:{cmd:e(beta_hat)}}T x p matrix of penalized estimates{p_end}
{synopt:{cmd:e(ic_values)}}ngrid x 1 vector of IC values{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtcbc}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(depvar)}}dependent variable name{p_end}
{synopt:{cmd:e(indepvars)}}independent variable names{p_end}
{synopt:{cmd:e(title)}}estimation title{p_end}


{title:Examples}

{pstd}{bf:Example 1: Basic usage}{p_end}
{phang}{cmd:. xtset id year}{p_end}
{phang}{cmd:. xtcbc gdp_growth invest trade inflation}{p_end}

{pstd}{bf:Example 2: With graphs and custom penalty}{p_end}
{phang}{cmd:. xtcbc gdp_growth invest trade inflation, graph kappa(2) ngrid(100) constant(0.05)}{p_end}

{pstd}{bf:Example 3: With cross-section demeaning}{p_end}
{phang}{cmd:. xtcbc gdp_growth invest trade inflation, csdemean graph}{p_end}

{pstd}{bf:Example 4: Simulated data with known break structure}{p_end}
{phang}{cmd:. set seed 12345}{p_end}
{phang}{cmd:. set obs 500}{p_end}
{phang}{cmd:. gen id = ceil(_n / 5)}{p_end}
{phang}{cmd:. gen time = mod(_n-1, 5) + 1}{p_end}
{phang}{cmd:. xtset id time}{p_end}
{phang}{cmd:. gen xi = 0}{p_end}
{phang}{cmd:. forvalues i = 1/100 {c -(}}{p_end}
{phang}{cmd:.   local xv = rnormal()}{p_end}
{phang}{cmd:.   qui replace xi = `xv' if id == `i'}{p_end}
{phang}{cmd:. {c )-}}{p_end}
{phang}{cmd:. gen x1 = 0.2*xi + rnormal()}{p_end}
{phang}{cmd:. gen x2 = 0.2*xi + rnormal()}{p_end}
{phang}{cmd:. gen y = xi + 1*x1 + cond(time<=3, 2, 5)*x2 + rnormal(0, 0.5)}{p_end}
{phang}{cmd:. drop xi}{p_end}
{phang}{cmd:. xtcbc y x1 x2, graph}{p_end}

{pstd}{bf:Example 5: Accessing stored results}{p_end}
{phang}{cmd:. xtcbc y x1 x2 x3}{p_end}
{phang}{cmd:. mat list e(nbreaks)}{p_end}
{phang}{cmd:. mat list e(alpha_info)}{p_end}
{phang}{cmd:. display "Optimal lambda = " e(opt_lambda)}{p_end}
{phang}{cmd:. display "Total breaks   = " e(total_breaks)}{p_end}
{phang}{cmd:. display "Breaks in x1   = " e(nbreaks_1)}{p_end}

{pstd}{bf:Example 6: Monte Carlo DGP from Section 4.1}{p_end}
{phang}{cmd:. * See xtcbc_demo.do for the full simulation}{p_end}
{phang}{cmd:. * p=6, T=5, N=200, true breaks = [2, 3, 0, 0, 0, 1]}{p_end}
{phang}{cmd:. do xtcbc_demo.do}{p_end}


{title:Remarks}

{pstd}
{bf:Comparison with vector-break estimators.}{p_end}

{pstd}
In classic structural break estimation (Bai and Perron 1998, Qian and Su 2016),
all coefficients share the same break dates ("vector break" assumption). When
some coefficients do not actually change at a detected break date, this
introduces unnecessary regime-splitting, reduces effective sample size, increases
variance, and can mask the significance of truly time-varying coefficients.{p_end}

{pstd}
The CBCL estimator resolves this by allowing each coefficient to break
independently. In the empirical application to U.S. county crime data
(Cornwell and Trumbull 1994), the vector-break estimator finds 2 breaks in
all sixteen coefficients, while the CBC estimator correctly finds breaks only
in three control variables, leaving the deterrence coefficients unbroken
(see paper Table 6).{p_end}


{pstd}
{bf:Choosing kappa.}{p_end}

{pstd}
The adaptive weight exponent kappa controls penalization: larger kappa means
stronger shrinkage of small differences, making the estimator more
conservative (fewer false breaks). The value kappa=2 is standard and is
recommended by both Qian and Su (2016) and Kaddoura (2025).{p_end}


{pstd}
{bf:Computational considerations.}{p_end}

{pstd}
Complexity: O(G * iter * T * p * N), where G = ngrid, iter = coordinate
descent iterations per lambda. For typical panels (N=100-500, T=5-20, p=3-8),
this takes seconds. For N > 1000, consider reducing ngrid.{p_end}


{pstd}
{bf:Balanced panels required.}{p_end}

{pstd}
The current implementation requires strongly balanced panels. Unbalanced panels
should be balanced before running {cmd:xtcbc}.{p_end}


{pstd}
{bf:Data requirements.}{p_end}

{pstd}
The algorithm requires T >= 3 and N >= p+1. Small T limits break detection.
The paper's Monte Carlo shows good performance for T=5 and N >= 100.{p_end}


{title:References}

{phang}
Kaddoura, Y. (2025). Estimating coefficient-by-coefficient breaks in panel
data models. {it:Journal of Econometrics}, 249, 106005.{p_end}

{phang}
Qian, J. and Su, L. (2016). Shrinkage estimation of common breaks in panel
data models via adaptive group fused lasso. {it:Journal of Econometrics},
191, 86-109.{p_end}

{phang}
Kaddoura, Y. and Westerlund, J. (2023). Estimation of panel data models
with random interactive effects and multiple structural breaks when T is
fixed. {it:Journal of Business & Economic Statistics}, 41, 778-790.{p_end}

{phang}
Bai, J. and Perron, P. (1998). Estimating and testing linear models with
multiple structural changes. {it:Econometrica}, 66, 47-78.{p_end}

{phang}
Bonhomme, S. and Manresa, E. (2015). Grouped patterns of heterogeneity in
panel data. {it:Econometrica}, 83, 1147-1184.{p_end}

{phang}
Cornwell, C. and Trumbull, W. N. (1994). Estimating the economic model of
crime with panel data. {it:Review of Economics and Statistics}, 76, 360-366.{p_end}


{title:Author}

{pstd}
Dr Merwan Roudane{p_end}
{pstd}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
Please cite as:{p_end}
{pstd}
Roudane, M. (2026). xtcbc: Stata module for coefficient-by-coefficient
breaks in panel data models.{p_end}


{title:Also see}

{psee}
{helpb xtpmg}, {helpb xtlmbreak}, {helpb xtset}, {helpb regress}
{p_end}
