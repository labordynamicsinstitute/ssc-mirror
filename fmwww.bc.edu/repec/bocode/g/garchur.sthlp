{smcl}
{* *! garchur.sthlp  v1.1.0  February 2026}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax"         "garchur##syntax"}{...}
{viewerjumpto "Description"    "garchur##description"}{...}
{viewerjumpto "Options"        "garchur##options"}{...}
{viewerjumpto "Examples"       "garchur##examples"}{...}
{viewerjumpto "Stored results" "garchur##results"}{...}
{viewerjumpto "References"     "garchur##references"}{...}
{viewerjumpto "Author"         "garchur##author"}{...}

{title:Title}

{phang}
{bf:garchur} {hline 2} GARCH-Based Unit Root Test with Trend and Structural Breaks

{title:Syntax}{marker syntax}

{p 8 17 2}
{cmdab:garchur} {varname} [{it:if}] [{it:in}] [{cmd:,}
{it:{help garchur##options:options}}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt break:s(#)}}number of structural breaks; default {cmd:breaks(2)}{p_end}
{synopt:{opt model(string)}}{bf:ct} (constant+trend, default) or {bf:c} (constant only){p_end}
{synopt:{opt trim(#)}}trimming proportion for break search; default {cmd:trim(0.15)}{p_end}
{syntab:Output}
{synopt:{opt nop:rint}}suppress printed output{p_end}
{synopt:{opt gr:aph}}display 3-panel diagnostic graph{p_end}
{synopt:{opt savegraph(filename)}}save graph to file (.png, .pdf, .eps, ...){p_end}
{synoptline}
{p2colreset}{...}

{title:Description}{marker description}

{pstd}
{cmd:garchur} implements the trend-GARCH(1,1) unit root test with endogenous
structural breaks proposed by {help garchur##NL2015:Narayan and Liu (2015)}.
The model is:

{pmore2}
{bf:Mean equation:}{p_end}
{pmore2}
y_t = a_0 + a_1*t + rho*y_(t-1) + Sum(gamma_j * DU_jt) + e_t{p_end}

{pmore2}
{bf:Variance equation (GARCH(1,1)):}{p_end}
{pmore2}
h_t = kappa + alpha*e^2_(t-1) + beta*h_(t-1){p_end}

{pstd}
where DU_jt = 1 for t >= TB_j (structural break dummy) and e_t is conditionally
normal with variance h_t. The null hypothesis is H_0: rho = 1 (unit root)
against H_1: rho < 1 (stationary).

{pstd}
{ul:Break-date estimation}: Break dates are found sequentially by maximising the
absolute t-statistic of each break dummy (Narayan and Liu, 2015, eq. 3-4;
Narayan and Popp, 2010). Supports up to three endogenous breaks.

{pstd}
{ul:Estimation procedure}: (1) OLS to obtain initial residuals; (2) GARCH(1,1)
maximum likelihood via direct grid search over (kappa, alpha, beta) using
standardised residuals for numerical stability; (3) weighted least squares (WLS)
re-estimation of the mean equation with weights 1/sqrt(h_t).

{pstd}
{ul:Critical values}: Interpolated from Table III of Narayan and Liu (2015),
based on 50,000 Monte Carlo replications. Accounts for sample size T and GARCH
persistence (alpha+beta).

{pstd}
{ul:Auxiliary variables}: After estimation, {cmd:garchur} creates
{bf:_garchur_ht} (conditional variance h_t) and {bf:_garchur_sr}
(standardised residuals e_t/sqrt(h_t)) in the dataset for
further analysis or custom graphing.

{title:Options}{marker options}

{dlgtab:Model}

{phang}
{opt breaks(#)} specifies the number of endogenous structural breaks.
Default is 2 (recommended). Maximum is 3.

{phang}
{opt model(string)} specifies the deterministic component.
{bf:ct} includes a constant and linear time trend (default).
{bf:c} includes only a constant.

{phang}
{opt trim(#)} sets the trimming proportion at each end of the sample when
searching for break dates. Default is 0.15 (15%). Allowable range: [0.05, 0.30].

{dlgtab:Output}

{phang}
{opt noprint} suppresses the displayed output table.

{phang}
{opt graph} produces a 3-panel diagnostic graph: (A) time series with OLS
trend overlay and vertical break-date lines; (B) estimated conditional variance
h_t; (C) standardised residuals e_t/sqrt(h_t) with +/-2 reference lines.

{phang}
{opt savegraph(filename)} saves the combined graph to {it:filename}.
The format is determined by the file extension (.png, .pdf, .eps, .svg, etc.).

{title:Examples}{marker examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. sysuse sp500, clear}{p_end}
{phang2}{cmd:. tsset date}{p_end}

{pstd}Basic test (constant + trend, 2 structural breaks):{p_end}
{phang2}{cmd:. garchur close}{p_end}

{pstd}Display 3-panel diagnostic graph:{p_end}
{phang2}{cmd:. garchur close, graph}{p_end}

{pstd}Save graph to PNG:{p_end}
{phang2}{cmd:. garchur close, graph savegraph("result.png")}{p_end}

{pstd}Constant-only model, 3 structural breaks:{p_end}
{phang2}{cmd:. garchur close, model(c) breaks(3)}{p_end}

{pstd}Suppress output and retrieve stored results:{p_end}
{phang2}{cmd:. garchur close, noprint}{p_end}
{phang2}{cmd:. display r(stat)    // t-statistic}{p_end}
{phang2}{cmd:. display r(cv5)     // 5% critical value}{p_end}
{phang2}{cmd:. display r(TB1)     // first break date}{p_end}

{title:Stored results}{marker results}

{pstd}
{cmd:garchur} stores the following in {cmd:r()}:

{synoptset 22 tabbed}
{syntab:Scalars}
{synopt:{cmd:r(N)}}observations in mean equation{p_end}
{synopt:{cmd:r(stat)}}t-statistic for H_0: rho = 1{p_end}
{synopt:{cmd:r(rho)}}estimated AR coefficient rho{p_end}
{synopt:{cmd:r(alpha)}}GARCH alpha (ARCH effect){p_end}
{synopt:{cmd:r(beta)}}GARCH beta (volatility persistence){p_end}
{synopt:{cmd:r(kappa)}}GARCH kappa (intercept){p_end}
{synopt:{cmd:r(ab)}}alpha+beta (sum; GARCH persistence){p_end}
{synopt:{cmd:r(halflife)}}half-life of shocks ln(0.5)/ln(alpha+beta){p_end}
{synopt:{cmd:r(loglik)}}log-likelihood at GARCH estimates{p_end}
{synopt:{cmd:r(cv1)}}1% critical value (Table III interpolation){p_end}
{synopt:{cmd:r(cv5)}}5% critical value{p_end}
{synopt:{cmd:r(cv10)}}10% critical value{p_end}
{synopt:{cmd:r(breaks)}}number of structural breaks{p_end}
{synopt:{cmd:r(TB1)}}first break date (Stata time value){p_end}
{synopt:{cmd:r(TB2)}}second break date (if breaks >= 2){p_end}
{synopt:{cmd:r(TB3)}}third break date (if breaks = 3){p_end}
{synoptline}
{syntab:Macros}
{synopt:{cmd:r(varname)}}variable tested{p_end}
{synopt:{cmd:r(model)}}model specification (ct or c){p_end}
{synopt:{cmd:r(decision)}}test decision string{p_end}
{synopt:{cmd:r(cmd)}}{cmd:garchur}{p_end}
{synoptline}

{title:References}{marker references}

{phang}
{marker NL2015}
Narayan, P.K. and Liu, R. (2015).
A unit root model for trending time-series energy variables.
{it:Energy Economics}.
DOI: {browse "https://doi.org/10.1016/j.eneco.2014.11.021":10.1016/j.eneco.2014.11.021}

{phang}
Narayan, P.K. and Popp, S. (2010).
A new unit root test with two structural breaks in level and slope at unknown time.
{it:Journal of Applied Statistics}, 37, 1425–1438.

{phang}
Narayan, P.K. and Liu, R. (2011).
Are shocks to commodity prices persistent?
{it:Applied Energy}, 88, 409–416.

{phang}
Cook, S. (2008).
Maximum likelihood unit root testing in the presence of GARCH.
{it:Communications in Statistics — Simulation and Computing}, 37, 756–765.

{title:Author}{marker author}

{pstd}
Support: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
Please cite as:{break}
Roudane, M. (2026). {it:garchur: Stata module implementing the Trend-GARCH unit root test with structural breaks} (v1.1.0). Statistical Software Components, Boston College Department of Economics.

{title:Also see}

{psee}
{helpb garchur_graph} for the graph module documentation.
{p_end}
