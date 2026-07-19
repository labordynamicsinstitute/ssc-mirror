{smcl}
{* *! version 1.0.0  18jul2026}{...}
{vieweralsosee "xtvsom" "help xtvsom"}{...}
{vieweralsosee "xtoutliers" "help xtoutliers"}{...}
{vieweralsosee "xtrobust" "help xtrobust"}{...}
{vieweralsosee "xtlossf" "help xtlossf"}{...}
{vieweralsosee "xtoutliers methods" "help xtoutliers_methods"}{...}
{viewerjumpto "Description" "xtvsom_postestimation##description"}{...}
{viewerjumpto "Supported estimators" "xtvsom_postestimation##support"}{...}
{viewerjumpto "What is reused" "xtvsom_postestimation##reuse"}{...}
{viewerjumpto "Examples" "xtvsom_postestimation##examples"}{...}
{viewerjumpto "Author" "xtvsom_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xtvsom postestimation} {hline 2} Using {cmd:xtvsom} after an estimation command

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtvsom} may be run immediately after a supported estimation command with an
empty variable list. It then reads the model from {cmd:e()} and applies the
Variance Shift Outlier Model to the observations that were in the estimation
sample.{p_end}

{marker support}{...}
{title:Supported estimators}

{synoptset 20 tabbed}{...}
{synopt:{helpb xtreg}}{cmd:fe} {c 45}{c 62} within (fixed-effects) VSOM design{p_end}
{synopt:{helpb regress}}pooled OLS VSOM design{p_end}
{synopt:{helpb areg}, {helpb reghdfe}}treated as fixed-effects{p_end}
{synopt:{helpb ivregress} {cmd:2sls}, {helpb xtivreg}}simultaneous / 2SLS VSOM design{p_end}
{synoptline}

{pstd}
Any other {cmd:e(cmd)} produces an informative error. If there are no estimation
results, run one of the above first, or call {cmd:xtvsom} standalone with an
explicit {depvar} {indepvars} and {cmd:fe} or {cmd:ols}.{p_end}

{marker reuse}{...}
{title:What is reused from e()}

{phang}o {bf:Estimation sample} {c 45} {cmd:e(sample)} defines the observations
VSOM operates on.{p_end}

{phang}o {bf:Dependent variable} {c 45} {cmd:e(depvar)}.{p_end}

{phang}o {bf:Regressors} {c 45} the column names of {cmd:e(b)} minus {cmd:_cons}.{p_end}

{phang}o {bf:Model} {c 45} {cmd:e(model)} distinguishes fixed effects; for
{cmd:ivregress}/{cmd:xtivreg}, {cmd:e(instd)} and {cmd:e(insts)} give the
endogenous regressors and instruments used to rebuild the second-stage design.{p_end}

{pstd}
{cmd:xtvsom} protects the caller's results: it holds {cmd:e()} on entry and
restores it on exit (even on error), so your original {helpb xtreg} results are
intact afterwards.{p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse nlswork}{p_end}
{phang2}{cmd:. xtreg ln_wage age tenure hours, fe}{p_end}
{phang2}{cmd:. xtvsom, graph}{p_end}
{phang2}{cmd:. estat summarize}   {it:(original xtreg results restored)}{p_end}

{phang2}{cmd:. ivregress 2sls y (w = z1 z2) x1 x2, fe}{p_end}
{phang2}{cmd:. xtvsom, iv}{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
