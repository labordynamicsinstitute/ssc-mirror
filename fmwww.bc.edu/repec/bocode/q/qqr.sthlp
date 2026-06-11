{smcl}
{* *! version 1.1.0  29may2026}{...}
{vieweralsosee "mqqr" "help mqqr"}{...}
{vieweralsosee "qqgcause" "help qqgcause"}{...}
{vieweralsosee "qqkrls" "help qqkrls"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqsurf3d" "help qqsurf3d"}{...}
{vieweralsosee "qqtest" "help qqtest"}{...}
{vieweralsosee "qqribbon" "help qqribbon"}{...}
{vieweralsosee "qqdiff" "help qqdiff"}{...}
{vieweralsosee "qqtable" "help qqtable"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{viewerjumpto "Syntax" "qqr##syntax"}{...}
{viewerjumpto "Description" "qqr##desc"}{...}
{viewerjumpto "Options" "qqr##opts"}{...}
{viewerjumpto "Methods" "qqr##meth"}{...}
{viewerjumpto "Inference workflow" "qqr##infer"}{...}
{viewerjumpto "Stored results" "qqr##saved"}{...}
{viewerjumpto "Saved dataset format" "qqr##fmt"}{...}
{viewerjumpto "Examples" "qqr##exa"}{...}
{viewerjumpto "References" "qqr##refs"}{...}
{title:Title}

{p 4 19 2}
{hi:qqr} {hline 2} Bivariate Quantile-on-Quantile Regression (Sim & Zhou 2015)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qqr} {it:depvar} {it:indepvar} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Grid & estimator}
{synopt:{opt tau(numlist)}}Y-quantile grid (default {bf:0.05(0.05)0.95}){p_end}
{synopt:{opt theta(numlist)}}X-quantile grid (default {bf:0.05(0.05)0.95}){p_end}
{synopt:{opt b:andwidth(#)}}kernel bandwidth (default: Silverman plug-in){p_end}
{synopt:{opt meth:od(string)}}{cmd:kernel} (default) or {cmd:subset}{p_end}

{syntab:Standard errors}
{synopt:{opt bootse}}use pointwise bootstrap SE (per cell){p_end}
{synopt:{opt nb:oot(#)}}bootstrap replications (default 200){p_end}

{syntab:Joint bootstrap & inference}
{synopt:{opt bci}}add joint-bootstrap pointwise CI columns ({bf:cilo cihi}){p_end}
{synopt:{opt bsave(filename)}}write the joint-bootstrap {it:draws} file for {help qqtest}/{help qqribbon}/{help qqdiff}{p_end}
{synopt:{opt lev:el(#)}}confidence level for {opt bci} (default {bf:c(level)}){p_end}

{syntab:Output}
{synopt:{opt sav:ing(filename)}}save long-format results .dta{p_end}
{synopt:{opt replace}}overwrite existing file(s){p_end}
{synopt:{opt nopro:gress}}suppress progress output{p_end}
{synoptline}


{marker desc}{...}
{title:Description}

{p 4 4 2}
{cmd:qqr} estimates a bivariate quantile-on-quantile regression following
{help qqr##refs:Sim & Zhou (2015)}.  For each pair (τ, θ) the procedure
fits a locally-weighted quantile regression{p_end}

{p 8 8 2}
{it:y = β₀(τ,θ) + β₁(τ,θ) (x − x_θ) + u}{p_end}

{p 4 4 2}
with kernel weights centred on the θ-quantile of {it:x}.  The slope
coefficient {it:β₁(τ,θ)} traces how the τ-quantile of {it:y} responds to
{it:x} when {it:x} is at its θ-quantile.  The result is an M×L surface that
generalises both standard quantile regression (one θ) and OLS (the mean).{p_end}


{marker opts}{...}
{title:Options}

{dlgtab:Grid & estimator}

{phang}
{opt tau(numlist)} and {opt theta(numlist)} give the response- and
predictor-quantile grids.  Finer grids give smoother surfaces but cost time.

{phang}
{opt bandwidth(#)} sets the kernel bandwidth on the empirical CDF of {it:x};
by default a Silverman plug-in is used.  {opt method(string)} selects the
estimator — see {help qqr##meth:Methods}.

{dlgtab:Standard errors}

{phang}
{opt bootse} replaces the analytic standard error of each cell with a
{it:pointwise} bootstrap SE (each cell resampled independently); {opt nboot(#)}
sets the number of replications.

{dlgtab:Joint bootstrap & inference}

{phang}
{opt bci} runs the {bf:joint bootstrap} — one resample index reused across the
{it:whole} grid per replication — and appends pointwise percentile CI columns
{bf:cilo} and {bf:cihi} to the saved results, at the {opt level()} confidence
level.

{phang}
{opt bsave(filename)} writes the full joint-bootstrap {it:draws} file in long
format ({bf:rep tau theta beta}: {bf:rep==0} is the point estimate, {bf:rep
1..B} the draws).  This file is the input to the inference and diagnostic
commands {help qqtest:qqtest}, {help qqribbon:qqribbon} and
{help qqdiff:qqdiff}.  Specifying {opt bsave()} implies the joint bootstrap
even without {opt bci}.

{phang}
{opt level(#)} sets the confidence level used by {opt bci} (default
{bf:c(level)}, usually 95).

{dlgtab:Output}

{phang}
{opt saving(filename)} writes the long-format results dataset (see
{help qqr##fmt:format} below); {opt replace} overwrites existing files;
{opt noprogress} silences the console output.


{marker meth}{...}
{title:Methods}

{p 4 8 2}{cmd:method(kernel)} — true Sim-Zhou local linear weighted QR using a
Gaussian kernel on the empirical CDF of {it:x}.  Recommended.{p_end}

{p 4 8 2}{cmd:method(subset)} — simplified variant: subset to {it:x ≤ x_θ} and
fit an unweighted quantile regression.  Faster, used in some applied papers.{p_end}


{marker infer}{...}
{title:Inference workflow}

{p 4 4 2}
For formal inference on the surface, estimate once with the joint bootstrap
and a draws file, then run the diagnostic commands against it:{p_end}

{phang2}{cmd:. qqr y x, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9) nboot(500) ///}{p_end}
{phang2}{cmd:.     bci bsave(draws.dta) saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqtest   using draws.dta, test(zero)}     {space 4}// is the surface non-zero?{p_end}
{phang2}{cmd:. qqtest   using draws.dta, test(symmetry)} {space 1}// tail-asymmetric?{p_end}
{phang2}{cmd:. qqribbon using draws.dta, theta(0.5) joint}{space 1}// CI ribbon slice{p_end}
{phang2}{cmd:. qqdiff   using draws.dta}                 {space 6}// asymmetry heatmap{p_end}


{marker saved}{...}
{title:Stored results}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations{p_end}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(method)}}estimator used{p_end}
{synopt:{cmd:r(depvar)}}response variable{p_end}
{synopt:{cmd:r(indvar)}}predictor variable{p_end}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:r(coef)}}M×L matrix of slope coefficients β₁(τ,θ){p_end}
{synopt:{cmd:r(se)}}M×L matrix of standard errors{p_end}
{synopt:{cmd:r(t)}}M×L matrix of t-statistics{p_end}
{synopt:{cmd:r(p)}}M×L matrix of p-values{p_end}
{synopt:{cmd:r(r2)}}M×L matrix of pseudo R²{p_end}
{synopt:{cmd:r(tau)}}τ grid (M×1){p_end}
{synopt:{cmd:r(theta)}}θ grid (L×1){p_end}


{marker fmt}{...}
{title:Saved dataset format}

{p 4 4 2}When {opt saving()} is used, a long-format .dta is written with
columns {bf:tau theta coef se t p r2} (plus {bf:cilo cihi} when {opt bci} is
specified).  This is the format consumed by {help qqheat:qqheat},
{help qqsurf:qqsurf}, {help qqsurf3d:qqsurf3d} and {help qqtable:qqtable}.{p_end}

{p 4 4 2}{opt bsave()} writes a separate {it:draws} file ({bf:rep tau theta
beta}) consumed by {help qqtest:qqtest}, {help qqribbon:qqribbon} and
{help qqdiff:qqdiff}.{p_end}


{marker exa}{...}
{title:Examples}

{p 4 4 2}{bf:Estimate and visualise}{p_end}
{phang2}{cmd:. qqr sp500 oil, saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqheat using qq.dta, value(coef) colormap(jet) sigmark}{p_end}
{phang2}{cmd:. qqsurf3d using qq.dta, value(coef) colormap(jet)}{p_end}

{p 4 4 2}{bf:Custom grid and the coefficient matrix}{p_end}
{phang2}{cmd:. qqr sp500 oil, tau(0.1(0.1)0.9) theta(0.1(0.1)0.9)}{p_end}
{phang2}{cmd:. matrix list r(coef)}{p_end}

{p 4 4 2}{bf:Joint bootstrap + formal tests}{p_end}
{phang2}{cmd:. qqr sp500 oil, nboot(500) bci bsave(draws.dta) saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqtest using draws.dta, test(zero)}{p_end}


{marker refs}{...}
{title:References}

{phang}Sim, N. and Zhou, H. (2015). Oil prices, US stock return, and the
dependence between their quantiles. {it:Journal of Banking & Finance} 55:1-12.{p_end}

{phang}Koenker, R. (2005). {it:Quantile Regression}. Cambridge University Press.{p_end}


{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help mqqr},  {help qqgcause},  {help qqkrls},  {help qqheat},
{help qqsurf3d},  {help qqtable},  {help qqtest},  {help qqribbon},
{help qqdiff},  {help qqr_package}{p_end}
