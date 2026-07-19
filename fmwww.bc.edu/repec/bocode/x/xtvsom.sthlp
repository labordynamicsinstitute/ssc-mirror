{smcl}
{* *! version 1.0.0  18jul2026}{...}
{vieweralsosee "xtoutliers" "help xtoutliers"}{...}
{vieweralsosee "xtvsom postestimation" "help xtvsom_postestimation"}{...}
{vieweralsosee "xtrobust" "help xtrobust"}{...}
{vieweralsosee "xtlossf" "help xtlossf"}{...}
{vieweralsosee "xtoutliers methods" "help xtoutliers_methods"}{...}
{viewerjumpto "Syntax" "xtvsom##syntax"}{...}
{viewerjumpto "Description" "xtvsom##description"}{...}
{viewerjumpto "Options" "xtvsom##options"}{...}
{viewerjumpto "Method" "xtvsom##method"}{...}
{viewerjumpto "Output" "xtvsom##output"}{...}
{viewerjumpto "Examples" "xtvsom##examples"}{...}
{viewerjumpto "Stored results" "xtvsom##results"}{...}
{viewerjumpto "References" "xtvsom##references"}{...}
{viewerjumpto "Author" "xtvsom##author"}{...}
{title:Title}

{phang}
{bf:xtvsom} {hline 2} Variance Shift Outlier Model (VSOM) for panel data

{marker syntax}{...}
{title:Syntax}

{pstd}Postestimation (after {cmd:xtreg,fe} / {cmd:regress} / {cmd:ivregress 2sls}):{p_end}

{p 8 15 2}
{cmd:xtvsom} {ifin} [{cmd:,} {it:options}]

{pstd}Standalone:{p_end}

{p 8 15 2}
{cmd:xtvsom} {depvar} {indepvars} {ifin}{cmd:,} {cmd:fe}|{cmd:ols} [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt fe}}fixed-effects (within) design; default when data are xtset{p_end}
{synopt:{opt ols}}pooled OLS design (constant included){p_end}
{synopt:{opt iv}}simultaneous / 2SLS design (postestimation after {cmd:ivregress 2sls}){p_end}

{syntab:Detection}
{synopt:{opt a:lpha(#)}}family-wise significance for the cutoff; default {cmd:alpha(0.05)}{p_end}
{synopt:{opt r:eps(#)}}parametric-bootstrap replications for the cutoff; default {cmd:reps(2000)}{p_end}
{synopt:{opt s:eed(#)}}random-number seed for the bootstrap{p_end}
{synopt:{opt cut:off(#)}}use a fixed cutoff instead of bootstrapping{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}
{synopt:{opt graph}}draw the four VSOM diagnostic figures{p_end}
{synopt:{opt name(string)}}stub for the graph names; default {cmd:name(xtvsom)}{p_end}
{synopt:{opt nolab:el}}show numeric panel codes instead of value labels{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtvsom} implements the Variance Shift Outlier Model (VSOM) of Gumedze
(2008) as adapted to panel data by Ismadyaliana, Setiawan and Purnomo (2024).
VSOM is a compromise between case deletion and robust estimation: rather than
dropping a suspected outlier, it {it:shifts} (inflates) that observation's
variance, which is algebraically equivalent to {it:down-weighting} it. The
command:{p_end}

{phang2}1. fits a null model (fixed-effects within, pooled OLS, or 2SLS);{p_end}
{phang2}2. forms the squared standardized residual {cmd:t}{c 94}{cmd:2} of each observation;{p_end}
{phang2}3. builds an empirical cutoff for {cmd:max t}{c 94}{cmd:2} by a parametric bootstrap under the null;{p_end}
{phang2}4. flags observations exceeding the cutoff;{p_end}
{phang2}5. estimates each flagged unit's variance-shift {cmd:{&psi}} and refits by feasible GLS (= WLS).{p_end}

{pstd}
Used as postestimation, {cmd:xtvsom} reuses the model in memory: fit
{helpb xtreg} with {cmd:fe}, or {helpb regress}, or {helpb ivregress} {cmd:2sls}
(the simultaneous case), then type {cmd:xtvsom}. The estimation sample and the
estimator are read from {cmd:e()}, and {cmd:e()} is restored on exit. See
{helpb xtvsom_postestimation:xtvsom postestimation}.{p_end}

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}{opt fe} uses the within (fixed-effects) design: {depvar} and
{indepvars} are demeaned by panel, no constant, and the leverage carries the
{cmd:1/T} mean-projection term of the LSDV hat matrix. This is the default when
the data are {helpb xtset} and no model is given in postestimation.{p_end}

{phang}{opt ols} uses the pooled design with a constant.{p_end}

{phang}{opt iv} treats the fit as a 2SLS structural equation. It is available
only as postestimation after {cmd:ivregress 2sls} (or {cmd:xtivreg}); the
first-stage fitted endogenous regressors are reconstructed from {cmd:e(instd)}
and {cmd:e(insts)}, and VSOM is applied to the second-stage residuals, exactly
as in the simultaneous-equation VSOM of the source paper. After
{cmd:xtivreg,fe} the fixed effects are absorbed (LSDV first stage plus a within
second stage), so the VSOM null slopes reproduce the {cmd:xtivreg,fe}
coefficients; after {cmd:ivregress 2sls} a pooled 2SLS design is used.{p_end}

{dlgtab:Detection}

{phang}{opt alpha(#)} sets the (family-wise) tail probability used to read the
cutoff off the bootstrap distribution of {cmd:max t}{c 94}{cmd:2}. Smaller
{cmd:alpha} flags fewer observations.{p_end}

{phang}{opt reps(#)} is the number of parametric-bootstrap replications used to
build the null distribution of {cmd:max t}{c 94}{cmd:2}. Larger is more stable.{p_end}

{phang}{opt cutoff(#)} bypasses the bootstrap and uses the supplied value as the
{cmd:t}{c 94}{cmd:2} cutoff (e.g. to reuse a previously computed threshold).{p_end}

{marker method}{...}
{title:Method}

{pstd}
Full derivations and the code{c 174}paper equation map are in
{helpb xtoutliers_methods:xtoutliers methods}. In brief, with squared
standardized residual {cmd:t}{c 94}{cmd:2}{sub:it} {cmd:= e}{sub:it}{cmd:{c 94}2 / [{&sigma}{c 94}2 (1-v}{sub:it}{cmd:)]},
the REML variance-shift estimate is{p_end}

{p 12 12 2}{cmd:{&psi}}{sub:it} {cmd:= (nT-p)(t}{c 94}{cmd:2-1) / [(nT-p-t}{c 94}{cmd:2)(1-v}{sub:it}{cmd:)]}{p_end}

{pstd}
and, because the shift matrix {cmd:P = D{&Psi}D'+I} is diagonal, the VSOM
generalized-least-squares refit reduces to weighted least squares with weights
{cmd:w}{sub:it}{cmd: = 1/(1+{&psi}}{sub:it}{cmd:)}. The reported VSOM residual is
{cmd:w}{sub:it}{cmd: {&times} r}{sub:it}, reproducing the residual shrinkage of
the source paper.{p_end}

{marker output}{...}
{title:Interpreting the output}

{phang}o {bf:cutoff} {c 45} the {cmd:t}{c 94}{cmd:2} threshold; observations
above it are outliers.{p_end}

{phang}o {bf:Coefficient comparison} {c 45} null vs VSOM slopes with standard
errors; signs should be stable and VSOM standard errors typically smaller.{p_end}

{phang}o {bf:SSR null / SSR VSOM} {c 45} the sum of squared residuals falls under
VSOM, confirming the outliers were accommodated.{p_end}

{phang}o {bf:Detected outliers} {c 45} per-unit {cmd:t}{c 94}{cmd:2}, {cmd:{&psi}},
and the null vs VSOM residuals.{p_end}

{phang}o {bf:graph} {c 45} four figures matching the source paper: (a) {cmd:t}{c 94}{cmd:2}
with the cutoff line; (b) residuals null vs VSOM; (c) the variance-shift
{cmd:{&psi}}; (d) the variance estimate {cmd:{&sigma}}{c 94}{cmd:2}.{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Fixed-effects postestimation with figures:{p_end}
{phang2}{cmd:. webuse nlswork}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xtvsom, alpha(0.05) reps(2000) seed(12345) graph}{p_end}

{pstd}Pooled OLS, standalone:{p_end}
{phang2}{cmd:. xtvsom ln_wage age tenure hours, ols}{p_end}

{pstd}Simultaneous (2SLS) VSOM:{p_end}
{phang2}{cmd:. ivregress 2sls y (w = z1 z2) x1 x2, fe}{p_end}
{phang2}{cmd:. xtvsom, iv graph}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtvsom} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{synopt:{cmd:r(p)}}number of model parameters{p_end}
{synopt:{cmd:r(nout)}}number of detected outliers{p_end}
{synopt:{cmd:r(cutoff)}}t{c 94}2 cutoff{p_end}
{synopt:{cmd:r(alpha)}}significance used{p_end}
{synopt:{cmd:r(sigma2)}}null-model variance{p_end}
{synopt:{cmd:r(sigma2v)}}VSOM variance{p_end}
{synopt:{cmd:r(ssr0)}}null SSR{p_end}
{synopt:{cmd:r(ssrv)}}VSOM SSR{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(model)}}model type (fe/ols/iv){p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(b_null)}}null coefficients{p_end}
{synopt:{cmd:r(V_null)}}null variance matrix{p_end}
{synopt:{cmd:r(b_vsom)}}VSOM coefficients{p_end}
{synopt:{cmd:r(V_vsom)}}VSOM variance matrix{p_end}
{synopt:{cmd:r(outliers)}}outlier table (obs, id, time, t{c 94}2, {&psi}, {&sigma}{c 94}2, resid0, residVSOM, weight){p_end}

{marker references}{...}
{title:References}

{phang}Gumedze, F.N. 2008. A Variance Shift Model for Outlier Detection and
Estimation in Linear and Linear Mixed Models. University of Cape Town.{p_end}

{phang}Ismadyaliana, S., Setiawan, and J.D.T. Purnomo. 2024. Panel data
modeling: Identifying and handling outliers with the VSOM approach.
{it:MethodsX} 13: 102900.{p_end}

{phang}Thompson, R. 1985. A note on restricted maximum likelihood estimation
with an alternative outlier model. {it:JRSS B} 47: 53{c 45}55.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
