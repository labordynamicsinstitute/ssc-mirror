{smcl}
{* * * 30 * * *}{hline}
{title:Multivariate ARDL Unit Root Test}
{title:Version 1.0.0 - September 9, 2026}
{hline}

{pstd}
{cmd:mvardlurt_multivariate} implements the multivariate ARDL unit root test
proposed by {it:Sam, McNown, Goh and Goh (2024)}. This test extends the 
standard ADF regression by including lagged levels of multiple covariates 
to improve power, especially when cointegration exists.

{pstd}
The test estimates the following model:

{p 8 12 2}
Δy_t = α + π*y_{t-1} + Σ_{i=1}^k δ_i*x_{i,t-1} 
       + Σ_{j=1}^{p-1} γ_j*Δy_{t-j} 
       + Σ_{i=1}^k Σ_{j=1}^{q_i-1} θ_{i,j}*Δx_{i,t-j} + ε_t

{pstd}
Two hypotheses are tested:
{break}
1. {cmd:H0: π = 0} (y has a unit root) - using t-test
{break}
2. {cmd:H0: δ_1 = δ_2 = ... = δ_k = 0} (no cointegration) - using F-test

{title:Syntax}

{p 8 12 2}
{cmd:mvardlurt_multivariate} {it:depvar} {it:indepvars} {ifin}
[ {it:{weight}} ]
[ {cmd:,} {cmdab:case(}{it:integer}{cmd:)}
{cmdab:maxlag:}({it:integer}{cmd:)}
{cmdab:reps:}({it:integer}{cmd:)}
{cmdab:ic:}({it:string}{cmd:)}
{cmdab:fixlag:}({it:numlist}{cmd:)}
{cmdab:level:}({it:cilevel}{cmd:)}
{cmdab:seed:}({it:integer}{cmd:)}
{cmd:nograph}
{cmd:diag}
{cmd:notable}
{cmd:noboot}
{cmd:savepath:}({it:string}{cmd:})
{cmd:nodisplay} ]

{title:Options}

{pstd}
{cmdab:case(}{it:#}{cmd:)} specifies the deterministic component:
{break}
{cmd:1} = no deterministic terms
{break}
{cmd:3} = intercept only (default)
{break}
{cmd:5} = intercept and trend

{pstd}
{cmdab:maxlag(}{it:#}{cmd:)} maximum lag length for lag selection.
Default is {cmd:10}.

{pstd}
{cmdab:reps(}{it:#}{cmd:)} number of bootstrap replications.
Default is {cmd:1000}. Minimum is {cmd:100}.

{pstd}
{cmdab:ic(}{it:string}{cmd:)} information criterion for lag selection:
{break}
{cmd:aic} = Akaike Information Criterion (default)
{break}
{cmd:bic} = Bayesian Information Criterion

{pstd}
{cmdab:fixlag(}{it:numlist}{cmd:)} manual lag specification.
First number is p (lags of Δy), subsequent numbers are q_i (lags of Δx_i).
{break}
Example: {cmd:fixlag(2 1 3)} sets p=2, q1=1, q2=3.

{pstd}
{cmdab:level(}{it:cilevel}{cmd:)} confidence level for critical values.
Default is {cmd:95}.

{pstd}
{cmdab:seed(}{it:#}{cmd:)} random seed for reproducibility.
Default is {cmd:12345}.

{pstd}
{cmd:nograph} suppresses graphical output.

{pstd}
{cmd:diag} displays diagnostic tests (serial correlation, heteroskedasticity, normality).

{pstd}
{cmd:notable} suppresses the AIC/BIC selection table.

{pstd}
{cmd:noboot} skips bootstrap and uses approximate critical values (MacKinnon, 1996).

{pstd}
{cmdab:savepath(}{it:string}{cmd:)} saves results to Excel file at specified path.

{pstd}
{cmd:nodisplay} suppresses all output (for programming use).

{title:Examples}

{pstd}
Load sample data and run the test:
{break}
{cmd:. webuse lutkepohl2, clear}
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) maxlag(4)}

{pstd}
With bootstrap and 500 replications:
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) maxlag(4) reps(500)}

{pstd}
Manual lag specification:
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) fixlag(2 1 1)}

{pstd}
Using BIC for lag selection:
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) ic(bic) maxlag(4)}

{pstd}
Skip bootstrap (quick test):
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) noboot}

{pstd}
Save results to Excel:
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) savepath("results.xlsx")}

{pstd}
With diagnostic tests:
{break}
{cmd:. mvardlurt_multivariate invest income consumption, case(3) diag}

{title:Results}

{pstd}
The command displays four tables:

{pstd}
{cmd:Table 1: Coefficient Summary}
{break}
Reports coefficients, standard errors, and t-statistics for all variables.

{pstd}
{cmd:Table 2: Hypothesis Tests}
{break}
Reports t-statistic (H0: π = 0) and F-statistic (H0: δ = 0) with p-values.

{pstd}
{cmd:Table 3: Critical Values}
{break}
Displays bootstrap or approximate critical values for significance levels.

{pstd}
{cmd:Table 4: Decision Framework}
{break}
Classifies results into four cases:

{p 8 12 2}
{cmd:Case I}:   Reject H0:π=0 and Reject H0:δ=0 → Cointegration
{cmd:Case II}:  Reject H0:π=0 and Accept H0:δ=0 → Degenerate case 1
{cmd:Case III}: Accept H0:π=0 and Reject H0:δ=0 → Degenerate case 2
{cmd:Case IV}:  Accept H0:π=0 and Accept H0:δ=0 → No cointegration

{title:Stored Results}

{pstd}
{cmd:mvardlurt_multivariate} stores the following in {cmd:e()}: 

{p 8 12 2}
{cmd:e(tstat)}       t-statistic for unit root test
{cmd:e(t_pvalue)}    p-value for t-statistic
{cmd:e(fstat)}       F-statistic for cointegration test
{cmd:e(fstat_p)}     p-value for F-statistic
{cmd:e(pi_coef)}     coefficient on lagged dependent variable
{cmd:e(pi_se)}       standard error of pi coefficient
{cmd:e(opt_p)}       optimal lag order for Δy
{cmd:e(case)}        case specification (1, 3, or 5)
{cmd:e(T)}           number of observations
{cmd:e(nobs)}        effective sample size
{cmd:e(r2)}          R-squared
{cmd:e(r2_a)}        adjusted R-squared
{cmd:e(aic)}         Akaike Information Criterion
{cmd:e(bic)}         Bayesian Information Criterion
{cmd:e(t_cv10)}      10% critical value for t-statistic
{cmd:e(t_cv05)}      5% critical value for t-statistic
{cmd:e(t_cv01)}      1% critical value for t-statistic
{cmd:e(f_cv10)}      10% critical value for F-statistic
{cmd:e(f_cv05)}      5% critical value for F-statistic
{cmd:e(f_cv01)}      1% critical value for F-statistic

{title:Author}

{pstd}
YUSUF TOYIN YUSUF
{break}
Kwara State University
{break}
Email: YUSUF.YUSUF@KWASU.EDU.NG

{pstd}
Copyright (c) 2026 YUSUF TOYIN YUSUF. All Rights Reserved.
Distributed under the MIT License.

{title:References}

{pstd}
Sam, C. Y., McNown, R., Goh, S. K., & Goh, K. L. (2024).
"A multivariate autoregressive distributed lag unit root test."
{it:Studies in Economics and Econometrics}, 1-17.

{pstd}
MacKinnon, J. G. (1996). "Numerical distribution functions for unit root 
and cointegration tests." {it:Journal of Applied Econometrics}, 11(6), 601-618.

{pstd}
Pesaran, M. H., Shin, Y., & Smith, R. J. (2001). "Bounds testing approaches 
to the analysis of level relationships." {it:Journal of Applied Econometrics}, 
16(3), 289-326.

{title:Also see}

{psee}
help dfuller, help pperron, help kpss, help vecrank, help ardl