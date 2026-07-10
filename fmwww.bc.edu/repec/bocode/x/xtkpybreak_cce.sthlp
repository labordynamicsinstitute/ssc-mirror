{smcl}
{* *! version 1.0.0  09jul2026}{...}
{vieweralsosee "xtkpybreak" "help xtkpybreak"}{...}
{vieweralsosee "xtkpybreak break" "help xtkpybreak_break"}{...}
{vieweralsosee "xtkpybreak postestimation" "help xtkpybreak_postestimation"}{...}
{vieweralsosee "xtcce" "help xtcce"}{...}
{viewerjumpto "Syntax" "xtkpybreak_cce##syntax"}{...}
{viewerjumpto "Description" "xtkpybreak_cce##description"}{...}
{viewerjumpto "Options" "xtkpybreak_cce##options"}{...}
{viewerjumpto "Stored results" "xtkpybreak_cce##results"}{...}
{viewerjumpto "Remarks" "xtkpybreak_cce##remarks"}{...}
{viewerjumpto "Examples" "xtkpybreak_cce##examples"}{...}
{viewerjumpto "Author" "xtkpybreak_cce##author"}{...}
{title:Title}

{phang}
{bf:xtkpybreak cce} {hline 2} Common Correlated Effects estimation valid under
non-stationary (I(1)) common factors (Kapetanios, Pesaran & Yamagata 2011)

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtkpybreak cce} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt :{opt proxy(yx|x)}}factor proxy: cross-section averages of
({it:depvar},{it:indepvars}) ({bf:yx}, the KPY/Pesaran default) or of the
regressors only ({bf:x}, the BFW proxy){p_end}
{synopt :{opt est:imator(mg|pooled)}}which estimator to post in {bf:e(b)};
default {bf:mg} (CCEMG). Both CCEMG and CCEP are always displayed and stored{p_end}
{synopt :{opt nocon:stant}}drop the intercept from the factor-proxy block, so the
proxy is the cross-section averages alone (strict Pesaran/BFW proxy){p_end}
{synopt :{opt l:evel(#)}}confidence level for the reported interval; default
{cmd:level(95)}{p_end}
{syntab:Graphs}
{synopt :{opt coefplot}}plot the heterogeneous per-panel slopes b(i) of the
first regressor with the CCEMG line and confidence band{p_end}
{synopt :{opt factorplot}}plot the cross-section-average factor proxies over
time{p_end}
{synopt :{opt name(stub)}}name stub for the saved graphs (default {bf:xtkpb}){p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtkpybreak cce} estimates the mean slope in a heterogeneous panel with an
unobserved multifactor error structure, allowing the factors to be I(1).
Following Pesaran (2006) and Kapetanios, Pesaran & Yamagata (2011), the
unobserved factors are proxied by cross-section averages of the observables,
which are added to each unit's regression. The command reports:

{phang2}o {bf:CCEMG} {hline 1} the Common Correlated Effects Mean-Group
estimator (KPY eq. 14), a simple average of the per-unit CCE estimators, with
standard errors from the cross-panel dispersion (KPY eq. 38);{p_end}

{phang2}o {bf:CCEP} {hline 1} the Common Correlated Effects Pooled estimator
(KPY eq. 20), with the sandwich variance of KPY eqs 42-44.{p_end}

{pstd}
A key result of KPY is that these estimators and, crucially, their variance
{it:estimators} are the same as in the stationary case: no Brownian-motion
functionals or re-tabulated critical values are needed. The procedure is valid
for any fixed number of factors and does not require estimating that number.

{pstd}
{bf:Requirements.} The data must be {helpb xtset} and the panel must be
{bf:balanced}. Time-series operators (e.g. {cmd:L.}, {cmd:D.}) are allowed in
{it:indepvars}.

{marker options}{...}
{title:Options}

{phang}
{opt proxy(yx|x)} selects the cross-section averages used to proxy the
unobserved factors. {bf:yx} (default) uses the averages of the dependent
variable and the regressors, as in Pesaran (2006) and KPY. {bf:x} uses the
averages of the regressors only, as in the simplification adopted by Baltagi,
Feng & Wang (2025); with {bf:x}, whether the factor loadings are correlated with
the regressor loadings does not affect the rank condition.

{phang}
{opt estimator(mg|pooled)} chooses which estimator is posted in {bf:e(b)}/{bf:e(V)}
for downstream {helpb test}/{helpb coefplot} use. Both estimators are always
displayed and are stored in {bf:e(b_mg)}, {bf:e(b_pooled)}, etc.

{phang}
{opt noconstant} removes the intercept from the projection block, so the
unobserved factors are proxied by the cross-section averages {it:only}. By
default an intercept (the KPY deterministic {it:D} term) is included in the
proxy block. Use {opt noconstant} for the strict Pesaran (2006) / BFW (2025)
eq. (9) proxy without a separate constant.

{phang}
{opt level(#)} sets the confidence level for the interval printed in the table.

{phang}
{opt coefplot} produces a caterpillar-style scatter of the per-panel slope
estimates b(i) for the first regressor, with the CCEMG estimate drawn as a
reference line and its {it:level}% band as dashed lines {hline 1} a quick view
of slope heterogeneity.

{phang}
{opt factorplot} plots the cross-section-average series that proxy the
unobserved I(1) factors, over the time dimension.

{phang}
{opt name(stub)} sets the stub for saved graph names: {it:stub}{bf:_coef} and
{it:stub}{bf:_factor}.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtkpybreak cce} stores the following in {cmd:e()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_g)}}number of panels (N){p_end}
{synopt:{cmd:e(Tbar)}}time periods per panel (T){p_end}
{synopt:{cmd:e(k)}}number of regressors{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtkpybreak}{p_end}
{synopt:{cmd:e(subcmd)}}{cmd:cce}{p_end}
{synopt:{cmd:e(estimator)}}posted estimator ({cmd:mg} or {cmd:pooled}){p_end}
{synopt:{cmd:e(proxy)}}{cmd:yx} or {cmd:x}{p_end}
{synopt:{cmd:e(depvar)}}dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}regressors{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}posted estimator and its variance{p_end}
{synopt:{cmd:e(b_mg)}, {cmd:e(se_mg)}, {cmd:e(V_mg)}}CCEMG estimates{p_end}
{synopt:{cmd:e(b_pooled)}, {cmd:e(se_pooled)}, {cmd:e(V_pooled)}}CCEP estimates{p_end}
{synopt:{cmd:e(b_i)}}k x N matrix of per-panel CCE slopes{p_end}
{synopt:{cmd:e(se_i)}}k x N matrix of per-panel standard errors (KPY eq. 49-50){p_end}

{marker remarks}{...}
{title:Remarks and interpretation}

{pstd}
{bf:Why CCE here.} When the errors share unobserved common factors, ignoring
them (a "naive" pooled or mean-group regression) gives inconsistent slopes and
badly sized tests. CCE augments each unit's regression with cross-section
averages, which span the factor space, and remains valid even when the factors
are I(1) (KPY 2011) {hline 1} with the {it:same} formulas as the stationary case,
so no unit-root pre-testing or Brownian-motion critical values are needed.

{pstd}
{bf:MG vs pooled.} The CCEMG estimator averages the per-unit slopes and is robust
to slope heterogeneity; the CCEP estimator pools and is more efficient when the
slopes are (near) homogeneous. Both are always displayed; pick which one lands in
{cmd:e(b)} with {opt estimator()}. The per-unit slopes are in {cmd:e(b_i)} and
can be plotted with {opt coefplot}.

{pstd}
{bf:Rate.} Individual slopes converge at root-T (not T) even though y and x are
I(1) and cointegrated, because after projecting off the factors the working
series are stationary (KPY Remark 6). The mean of the slopes converges at root-N.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Default CCE (both CCEMG and CCEP reported){p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock}{p_end}

{pstd}Regressor-only proxy; post the pooled estimator{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock, proxy(x) estimator(pooled)}{p_end}

{pstd}Strict Pesaran/BFW proxy without an intercept in the proxy block{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock, noconstant}{p_end}

{pstd}Slope-heterogeneity and factor-proxy graphs{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock, coefplot factorplot name(gr)}{p_end}

{pstd}Postestimation: Wald test and cross-model comparison{p_end}
{phang2}{cmd:. xtkpybreak cce invest mvalue kstock}{p_end}
{phang2}{cmd:. test mvalue kstock}{p_end}
{phang2}{cmd:. estimates store CCEMG}{p_end}
{phang2}{cmd:. matrix list e(b_i)}{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
