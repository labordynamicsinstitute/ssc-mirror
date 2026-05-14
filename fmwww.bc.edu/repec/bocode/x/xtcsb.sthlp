{smcl}
{* *! version 1.1.0 11may2026}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{vieweralsosee "xtcips" "help xtcips"}{...}
{vieweralsosee "xtcd" "help xtcd"}{...}
{viewerjumpto "Syntax" "xtcsb##syntax"}{...}
{viewerjumpto "Description" "xtcsb##description"}{...}
{viewerjumpto "Options" "xtcsb##options"}{...}
{viewerjumpto "Method" "xtcsb##method"}{...}
{viewerjumpto "Stored results" "xtcsb##stored"}{...}
{viewerjumpto "Examples" "xtcsb##examples"}{...}
{viewerjumpto "References" "xtcsb##refs"}{...}
{viewerjumpto "Author" "xtcsb##author"}{...}
{title:Title}

{phang}
{bf:xtcsb} {hline 2} Multifactor cross-sectionally augmented panel unit
root tests of {bf:CIPS*} and {bf:CSB} (Pesaran, Smith & Yamagata 2013)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtcsb} {it:depvar} [{it:addregs}] {ifin}
[{cmd:,}
{cmdab:maxl:ags(}{it:#}{cmd:)}
{cmdab:t:rend}
{cmdab:kr:egs(}{it:#}{cmd:)}
{cmdab:notab:le}
{cmdab:nog:raph}
{cmdab:l:evel(}{it:#}{cmd:)}
{cmdab:cipso:nly}
{cmdab:csbo:nly}
{cmdab:exp:ort(}{it:filename}{cmd:)}
{cmdab:sav:ing(}{it:filename}{cmd:)}]


{phang}
{cmd:xtcsb} requires the data to be {cmd:tsset} as a {bf:balanced} panel without gaps.

{phang}
{it:depvar} is the variable tested for a unit root. {it:addregs} is an
optional list of additional regressors {it:x_it} that share the same
unobserved common factors as {it:depvar}, used to augment the
cross-sectional projections. The rank condition requires {it:k} {bf:>=}
{it:m{sub:0}} {bf:-} 1 where {it:m{sub:0}} is the unknown number of
common factors.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtcsb} implements the two panel unit root tests proposed by Pesaran,
Smith & Yamagata (2013, {it:Journal of Econometrics} 175, 94-115) for
panels with a {bf:multifactor error structure}:

{phang2}
{bf:CIPS*}: a truncated average of cross-sectionally augmented
Dickey-Fuller (CADF) {it:t}-ratios. Generalises the test of Pesaran
(2007) by adding the cross-section averages of {it:k} additional
observable variables to handle {it:m{sub:0}} {bf:>=} 1 unobserved
factors.{p_end}

{phang2}
{bf:CSB}: a cross-sectionally augmented Sargan-Bhargava test based on
the partial sums of the residuals from an augmented first-difference
regression. CSB has typically higher power than CIPS for small to
moderate {it:T}.{p_end}

{pstd}
Both tests are left-tailed: H{sub:0} is rejected when the statistic is
smaller than the critical value.

{pstd}
Output includes a detailed table (specification block, panel test
results, individual unit statistics) and a 4-panel publication-quality
dashboard (CADF forest plot, CSB forest plot, kernel density and
CIPS-CSB scatter).


{marker options}{...}
{title:Options}

{phang}
{opt maxlags(#)} sets the lag-augmentation order p in the CADF and CSB
regressions. If unspecified, p_hat = floor[4(T/100)^{1/4}] is used,
following Pesaran et al. (2013, Section 4).

{phang}
{opt trend} adds a unit-specific linear trend (Case III). The default is
intercept only (Case II / model with constant).

{phang}
{opt kregs(#)} specifies the number of additional regressors to use.
It is overridden if {it:addregs} is supplied (k is then inferred from
the number of variables provided).

{phang}
{opt notable} suppresses the formatted display.

{phang}
{opt nograph} suppresses the 4-panel dashboard.

{phang}
{opt level(#)} confidence level for reporting (default 95).

{phang}
{opt cipsonly} reports CIPS* only (hides CSB).

{phang}
{opt csbonly} reports CSB only (hides CIPS*).

{phang}
{opt export(filename)} writes a tidy CSV of per-unit and panel results.

{phang}
{opt saving(filename)} saves the combined dashboard graph (any format
supported by {cmd:graph export}: .png, .pdf, .gph, .svg).


{marker method}{...}
{title:Method}

{pstd}
For each cross-sectional unit {it:i}, the CADF regression is
(PSY 2013, eq. 14 / 39):

{p 8 8 2}
{c |}{c |}delta y_{it} = a_i + b_i y_{i,t-1} + c'_i zbar_{t-1}
+ sum_{ell=0..p} h'_{i,ell} delta zbar_{t-ell}
+ sum_{ell=1..p} g_{i,ell} delta y_{i,t-ell} + (g_i*t) + e_{it}{c |}{c |}

{pstd}
where zbar_t = N^{-1} sum_j (y_{jt}, x'_{jt})'. The CIPS statistic is
the average of t-ratios on b_i. The truncated version CIPS* (eq. 30)
caps individual t-ratios at -K1 and +K2 (K1, K2 from Pesaran 2007
Table I).

{pstd}
For CSB, the augmented first-difference regression (PSY 2013, eq. 35)
omits the level term:

{p 8 8 2}
{c |}{c |}delta y_{it} = (a_i +) sum_{ell=0..p} h'_{i,ell} delta zbar_{t-ell}
+ sum_{ell=1..p} g_{i,ell} delta y_{i,t-ell} + e_{it}{c |}{c |}

{pstd}
and CSB_i = T^{-2} sum_t (sum_{j<=t} ehat_{ij})^2 / sigma_i^2.

{pstd}
Critical values are interpolated from Pesaran et al. (2013) Tables
B.1-B.4 (intercept) and B.2/B.4 (intercept + trend), with k-specific
shifts calibrated against the empirical-application anchor points in
Tables 4-5 of the paper.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:r(CIPS)}        truncated CIPS* statistic{break}
{cmd:r(CIPS_untrunc)} untruncated CIPS statistic{break}
{cmd:r(CSB)}         CSB statistic{break}
{cmd:r(N)}           number of panels{break}
{cmd:r(T)}           number of time periods{break}
{cmd:r(k)}           number of additional regressors{break}
{cmd:r(p)}           lag-augmentation order{break}
{cmd:r(cips_cv1/5/10)} CIPS 1/5/10% critical values{break}
{cmd:r(csb_cv1/5/10)}  CSB 1/5/10% critical values{break}
{cmd:r(trunc_n)}     number of truncated units{break}
{cmd:r(cips_decision)} decision text for CIPS{break}
{cmd:r(csb_decision)}  decision text for CSB{break}
{cmd:r(results)}     matrix of per-unit statistics
(columns: id, CADF_i, CADF_i*, CSB_i, p_lag, rej_cips, rej_csb)


{marker examples}{...}
{title:Examples}

{pstd}Setup a balanced panel:{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. tsset company year}{p_end}

{pstd}Basic test on {cmd:invest} with intercept, default lag:{p_end}
{phang2}{cmd:. xtcsb invest}{p_end}

{pstd}Test with intercept and trend, 2 augmentation lags, save graph:{p_end}
{phang2}{cmd:. xtcsb invest, trend maxlags(2) saving(dash.png)}{p_end}

{pstd}Test using {cmd:mvalue} and {cmd:kstock} as additional regressors
sharing the common factors of {cmd:invest}:{p_end}
{phang2}{cmd:. xtcsb invest mvalue kstock, trend}{p_end}

{pstd}Export tidy CSV of unit and panel results:{p_end}
{phang2}{cmd:. xtcsb invest mvalue, export(invest_csb.csv)}{p_end}

{pstd}Display only CSB (preferred for small T):{p_end}
{phang2}{cmd:. xtcsb invest, csbonly maxlags(1)}{p_end}


{marker refs}{...}
{title:References}

{phang}
Pesaran, M.H. 2007. A simple panel unit root test in the presence of
cross-section dependence. {it:Journal of Applied Econometrics} 22(2),
265-312.

{phang}
Pesaran, M.H., L.V. Smith, T. Yamagata. 2013. Panel unit root tests in
the presence of a multifactor error structure. {it:Journal of
Econometrics} 175, 94-115.
{browse "https://doi.org/10.1016/j.jeconom.2013.02.001":doi}

{phang}
Bai, J., S. Ng. 2010. Panel unit root tests with cross-section
dependence: a further investigation. {it:Econometric Theory} 26,
1088-1114.


{marker author}{...}
{title:Author}

{pstd}
{bf:Dr. Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}

{pstd}
Suggestions and bug reports are welcome.
