{smcl}
{* *! version 1.0.0  18jul2026}{...}
{vieweralsosee "xtoutliers" "help xtoutliers"}{...}
{vieweralsosee "xtvsom" "help xtvsom"}{...}
{vieweralsosee "xtlossf" "help xtlossf"}{...}
{vieweralsosee "xtoutliers methods" "help xtoutliers_methods"}{...}
{viewerjumpto "Syntax" "xtrobust##syntax"}{...}
{viewerjumpto "Description" "xtrobust##description"}{...}
{viewerjumpto "Options" "xtrobust##options"}{...}
{viewerjumpto "Method" "xtrobust##method"}{...}
{viewerjumpto "Output" "xtrobust##output"}{...}
{viewerjumpto "Examples" "xtrobust##examples"}{...}
{viewerjumpto "Stored results" "xtrobust##results"}{...}
{viewerjumpto "References" "xtrobust##references"}{...}
{viewerjumpto "Author" "xtrobust##author"}{...}
{title:Title}

{phang}
{bf:xtrobust} {hline 2} Robust estimation of linear panel models (S-estimator and WLE)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtrobust} {depvar} {indepvars} {ifin}{cmd:,} {cmd:fe}|{cmd:re} [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model (one required)}
{synopt:{opt fe}}fixed-effects (within-transformed) robust fit{p_end}
{synopt:{opt re}}random-effects (quasi-demeaned) robust fit{p_end}

{syntab:Estimator}
{synopt:{opt m:ethod(s|wle|all)}}which robust estimator(s) to report; default {cmd:all}{p_end}
{synopt:{opt nsamp(#)}}elemental subsamples for fast-S; default {cmd:nsamp(200)}{p_end}
{synopt:{opt c:steps(#)}}concentration steps per fast-S subsample; default {cmd:csteps(2)}{p_end}
{synopt:{opt t:une(#)}}Tukey biweight tuning constant c; default {cmd:tune(1.547)}{p_end}
{synopt:{opt b:const(#)}}M-scale target K; default {cmd:bconst(0.199)}{p_end}
{synopt:{opt bw:idth(#)}}WLE kernel bandwidth, as a multiple of the robust scale; default {cmd:bwidth(0.5)}{p_end}
{synopt:{opt s:eed(#)}}random-number seed for fast-S{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt graph}}draw the weight and residual diagnostic figures{p_end}
{synopt:{opt name(string)}}stub for graph names; default {cmd:name(xtrobust)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtrobust} fits linear panel-data models robustly, resisting outliers that
would bias ordinary least squares. It implements the two estimators studied by
Jaseem and Mohammad (2024):{p_end}

{phang2}o the {bf:S-estimator} (Rousseeuw{c 45}Yohai), which minimises a robust
M-scale of the residuals using Tukey's biweight, with a 50% breakdown point;{p_end}

{phang2}o the {bf:Weighted Likelihood Estimator (WLE)} (Agostinelli{c 45}Markatou),
which down-weights observations whose residual density departs from the model
density, via a Pearson residual and a residual-adjustment function.{p_end}

{pstd}
For {cmd:fe}, the data are within-transformed (each observation minus its panel
mean, no constant). For {cmd:re}, the data are quasi-demeaned with the
Swamy{c 45}Arora weight {cmd:{&lambda}}{sub:i} obtained from a preliminary
{helpb xtreg}{cmd:, re}. The robust estimator is then applied to the transformed
data. OLS on the same transformed data is reported alongside for comparison.{p_end}

{marker options}{...}
{title:Options}

{phang}{opt method(s|wle|all)} chooses the estimator(s). All three columns
(OLS, S, WLE) are always shown; {cmd:method()} is retained for stored-result
labelling and future extension.{p_end}

{phang}{opt nsamp(#)} and {opt csteps(#)} control the fast-S resampling
algorithm: {cmd:nsamp} random elemental subsets, each refined by {cmd:csteps}
concentration (I-)steps, keeping the fit with the smallest M-scale, followed by
full IRLS convergence. Increase {cmd:nsamp} for a harder problem.{p_end}

{phang}{opt tune(#)} and {opt bconst(#)} are the biweight tuning constant and
the M-scale target. The defaults {cmd:c=1.547}, {cmd:K=0.199} give the 50%
breakdown, consistency-at-normal S-estimator of the source paper (note
{cmd:K = c}{c 94}{cmd:2/6 {&divide} 2}).{p_end}

{phang}{opt bwidth(#)} is the Gaussian kernel bandwidth of the WLE, expressed as
a multiple of the robust scale. Smaller values sharpen the density comparison
and down-weight more aggressively.{p_end}

{marker method}{...}
{title:Method}

{pstd}
See {helpb xtoutliers_methods:xtoutliers methods} for the equation map. The
biweight {cmd:{&rho}(u) = u}{c 94}{cmd:2/2 - u}{c 94}{cmd:4/(2c}{c 94}{cmd:2) + u}{c 94}{cmd:6/(6c}{c 94}{cmd:4)}
for {cmd:|u|{&le}c}; the S-estimator solves
{cmd:{&beta}{c 94}{cmd:} = argmin {&sigma}}{sub:S}, with {cmd:{&sigma}}{sub:S}
the M-scale defined by {cmd:mean {&rho}(r}{sub:i}{cmd:/{&sigma}) = K}. The WLE
weight is {cmd:w}{sub:i}{cmd: = min{c 123}1, [A({&delta}}{sub:i}{cmd:)+1]}{sub:+}{cmd:/({&delta}}{sub:i}{cmd:+1){c 125}}
with RAF {cmd:A({&delta}) = 2[({&delta}+1)}{c 94}{cmd:(1/2)-1]} and Pearson
residual {cmd:{&delta}}{sub:i}{cmd: = f*(r}{sub:i}{cmd:)/m*(r}{sub:i}{cmd:)-1}.{p_end}

{marker output}{...}
{title:Interpreting the output}

{phang}o {bf:OLS / S-est / WLE columns} {c 45} coefficients with standard errors
in parentheses; significance stars from the respective t/z. Compare the robust
columns with OLS to see the pull of outliers.{p_end}

{phang}o {bf:S-scale / WLE-scale} {c 45} the robust residual scale from each
estimator; much smaller than the OLS residual SD when outliers are present.{p_end}

{phang}o {bf:graph} {c 45} (a) S weights and (b) WLE weights by observation
(values near 0 are down-weighted outliers); (c){c 45}(d) residual-versus-fitted
plots for each estimator.{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse nlswork}{p_end}
{phang2}{cmd:. xtrobust ln_wage age tenure hours, fe method(all) seed(123) graph}{p_end}

{phang2}{cmd:. xtrobust ln_wage age tenure hours, re}{p_end}

{marker results}{...}
{title:Stored results}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(k)}}number of regressors{p_end}
{synopt:{cmd:r(scaleS)}}S-estimator M-scale{p_end}
{synopt:{cmd:r(scaleWLE)}}WLE residual scale{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(model)}}fe or re{p_end}
{synopt:{cmd:r(method)}}requested method{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(b_ols)}, {cmd:r(V_ols)}}OLS coefficients and variance{p_end}
{synopt:{cmd:r(b_s)}, {cmd:r(V_s)}}S-estimator coefficients and variance{p_end}
{synopt:{cmd:r(b_wle)}, {cmd:r(V_wle)}}WLE coefficients and variance{p_end}

{marker references}{...}
{title:References}

{phang}Jaseem, H.N., and L.A. Mohammad. 2024. Detecting Outliers and Using
Robust Methods in Linear Panel Data Model. {it:Al-Nahrain Journal of Science}
27(4): 40{c 45}46.{p_end}

{phang}Rousseeuw, P.J., and V.J. Yohai. 1984. Robust regression by means of
S-estimators. In {it:Robust and Nonlinear Time Series Analysis}. Springer.{p_end}

{phang}Agostinelli, C., and M. Markatou. 1998. A one-step robust estimator for
regression based on the weighted likelihood reweighting scheme.
{it:Statistics & Probability Letters} 37: 341{c 45}350.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
