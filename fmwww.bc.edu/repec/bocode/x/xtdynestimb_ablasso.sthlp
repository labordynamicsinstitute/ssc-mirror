{smcl}
{* 10jun2026}{...}
{vieweralsosee "xtdynestimb" "help xtdynestimb"}{...}
{vieweralsosee "xtdynestimb dd" "help xtdynestimb_dd"}{...}
{vieweralsosee "xtdynestimb csdgmm" "help xtdynestimb_csdgmm"}{...}
{vieweralsosee "xtdynestimb postestimation" "help xtdynestimb_postestimation"}{...}
{viewerjumpto "Syntax" "xtdynestimb_ablasso##syntax"}{...}
{viewerjumpto "Description" "xtdynestimb_ablasso##description"}{...}
{viewerjumpto "Method" "xtdynestimb_ablasso##method"}{...}
{viewerjumpto "Options" "xtdynestimb_ablasso##options"}{...}
{viewerjumpto "Stored results" "xtdynestimb_ablasso##results"}{...}
{viewerjumpto "Examples" "xtdynestimb_ablasso##examples"}{...}
{viewerjumpto "References" "xtdynestimb_ablasso##references"}{...}
{viewerjumpto "Author" "xtdynestimb_ablasso##author"}{...}
{title:Title}

{phang}
{bf:xtdynestimb ablasso} {hline 2} Arellano-Bond LASSO estimator for dynamic
linear panel models (Chernozhukov, Fernandez-Val, Huang & Wang 2024)

{pstd}({it:part of} {helpb xtdynestimb}. See also {helpb xtdynestimb_dd:dd},
{helpb xtdynestimb_csdgmm:csdgmm},
{helpb xtdynestimb_postestimation:postestimation}.){p_end}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtdynestimb ablasso} {it:depvar} [{it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt l:ags(#)}}autoregressive order {it:p}; default {cmd:lags(1)}{p_end}

{syntab:Instrument selection}
{synopt:{opt lamb:da(#)}}LASSO penalty; default is a data-driven plug-in
({it:#} {cmd:< 0}){p_end}
{synopt:{opt c:ons(#)}}constant in the plug-in penalty; default {cmd:cons(1.1)}{p_end}

{syntab:Cross-fitting (AB-LASSO-SS)}
{synopt:{opt cross:fit}}turn on sample-splitting / cross-fitting{p_end}
{synopt:{opt kf:old(#)}}number of folds; default {cmd:kfold(2)}{p_end}
{synopt:{opt ns:plits(#)}}number of random splits to average over; default
{cmd:nsplits(1)}{p_end}
{synopt:{opt seed(#)}}random-number seed for reproducible splits{p_end}

{syntab:Reporting}
{synopt:{opt graph}}coefficient plot{p_end}
{synopt:{opt graphn:ame(name)}}name for the graph{p_end}
{synopt:{opt nota:ble}}suppress the output table{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdynestimb ablasso} implements the Arellano-Bond LASSO (AB-LASSO) estimator
of Chernozhukov, Fernandez-Val, Huang & Wang (2024) for dynamic linear panels in
which the time dimension {it:T} is {bf:moderately long}. When {it:T} is large the
number of Arellano-Bond moment conditions grows like {it:T}{c 94}2, and the
resulting overidentification biases the standard GMM estimator (the bias is of
order {it:T/N}). AB-LASSO removes this bias by selecting, period by period, only
the {bf:most informative} moment conditions.

{pstd}
This estimator is the long-{it:T} complement to {helpb xtdynestimb_dd:dd} and
{helpb xtdynestimb_csdgmm:csdgmm}, which target short panels.

{marker method}{...}
{title:Method}

{pstd}
The model is first-differenced and demeaned over the cross-section (to remove the
time effects). Then, for each period {it:t}:

{phang2}1. {bf:LASSO selection.} The differenced endogenous regressors
({it:Dy_i,t-1}, ..., {it:Dy_i,t-p}) are regressed by LASSO on the candidate
instruments (the lagged levels {it:y_i,1}, ..., {it:y_i,t-2}). The fitted values
are the estimated {it:optimal instruments}. Under weak time-series dependence the
effective number of selected instruments is very small relative to {it:N}.{p_end}

{phang2}2. {bf:Instrumental-variables estimation.} The parameters are estimated by
IV pooling the optimal instruments across all periods. The variance is
cluster-robust on the panel unit.{p_end}

{pstd}
With {cmd:crossfit} (the AB-LASSO-SS estimator), the cross-section is split into
folds; the LASSO is fit on the auxiliary folds and used to predict the held-out
fold, which removes the over-fitting bias from re-using the same observations for
selection and estimation. {cmd:nsplits()} averages over several random splits so
the estimate does not depend on an arbitrary partition; the reported variance
adds the between-split variance to the average within-split variance.

{pstd}
The LASSO penalty is, by default, the data-driven plug-in level (a
Belloni-Chen-Chernozhukov-Hansen-type rule); supply {cmd:lambda()} to fix it.

{marker options}{...}
{title:Options}

{phang}{opt lags(#)} sets the autoregressive order. The empirical illustration in
the source paper uses four lags; long panels typically support {cmd:lags(2)} or
more.{p_end}

{phang}{opt lambda(#)} fixes the LASSO penalty (on the standardized design). A
negative value (the default) requests the plug-in penalty; {opt cons(#)} scales
it.{p_end}

{phang}{opt crossfit}, {opt kfold(#)}, {opt nsplits(#)}, {opt seed(#)} control
the sample-splitting / cross-fitting. For a stable answer use, e.g.,
{cmd:crossfit kfold(5) nsplits(5) seed(...)}.{p_end}

{pstd}
{bf:Note.} AB-LASSO needs a reasonably long, (near-)balanced panel: each period's
candidate instrument set must be observed for enough units. Very short or heavily
unbalanced panels may yield too few usable periods.

{marker results}{...}
{title:Stored results}

{pstd}In addition to the common {helpb xtdynestimb##results:e()} results:{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(Tmax)}}maximum number of time periods{p_end}
{synopt:{cmd:e(n_selavg)}}average number of selected instruments per period{p_end}
{synopt:{cmd:e(lambda)}}LASSO penalty (negative = plug-in){p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(crossfit)}}cross-fitting configuration{p_end}
{synopt:{cmd:e(vce)}}cluster-robust (panel){p_end}

{marker examples}{...}
{title:Examples}

{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}

{pstd}Plain AB-LASSO{p_end}
{phang2}{cmd:. xtdynestimb ablasso n, lags(1)}{p_end}

{pstd}AB-LASSO-SS with 5-fold cross-fitting averaged over 5 splits{p_end}
{phang2}{cmd:. xtdynestimb ablasso n, lags(2) crossfit kfold(5) nsplits(5) seed(123) graph}{p_end}

{pstd}Compare with the (long-{it:T}-biased) Arellano-Bond estimator{p_end}
{phang2}{cmd:. xtdynestimb dd n, lags(2) variant(difference)}{p_end}
{phang2}{cmd:. xtdynestimb ablasso n, lags(2) crossfit kfold(5) seed(1)}{p_end}

{marker references}{...}
{title:References}

{phang}Chernozhukov, V., I. Fernandez-Val, C. Huang, and W. Wang. 2024.
Arellano-Bond LASSO estimator for dynamic linear panel models. cemmap working
paper CWP09/24.{p_end}

{phang}Belloni, A., D. Chen, V. Chernozhukov, and C. Hansen. 2012. Sparse models
and methods for optimal instruments with an application to eminent domain.
{it:Econometrica} 80: 2369-2429.{p_end}

{phang}Chernozhukov, V., et al. 2018. Double/debiased machine learning for
treatment and structural parameters. {it:Econometrics Journal} 21: C1-C68.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
