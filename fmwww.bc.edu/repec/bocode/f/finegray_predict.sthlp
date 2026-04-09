{smcl}
{* *! version 1.0.0  06apr2026}{...}
{vieweralsosee "finegray" "help finegray"}{...}
{vieweralsosee "finegray_phtest" "help finegray_phtest"}{...}
{vieweralsosee "[ST] stcrreg" "help stcrreg"}{...}
{vieweralsosee "[ST] stcox" "help stcox"}{...}
{viewerjumpto "Syntax" "finegray_predict##syntax"}{...}
{viewerjumpto "Description" "finegray_predict##description"}{...}
{viewerjumpto "Options" "finegray_predict##options"}{...}
{viewerjumpto "Examples" "finegray_predict##examples"}{...}
{viewerjumpto "Stored results" "finegray_predict##results"}{...}
{viewerjumpto "Author" "finegray_predict##author"}{...}
{title:Title}

{p2colset 5 28 30 2}{...}
{p2col:{cmd:finegray_predict} {hline 2}}Post-estimation predictions after finegray{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 28 2}
{cmd:finegray_predict}
{dtype}
{newvar}
{ifin}{cmd:,}
[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt xb}}linear predictor z'beta (default){p_end}
{synopt:{opt cif}}cumulative incidence function{p_end}
{synopt:{opt sch:oenfeld}}Schoenfeld residuals at cause-event times{p_end}
{synopt:{opth time:var(varname)}}use {it:varname} instead of {cmd:_t} for time{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:finegray_predict} generates predictions after {helpb finegray}. Three prediction types are available:

{phang2}
{bf:xb} (default) computes the linear predictor z'beta from the Fine-Gray model coefficient vector.

{phang2}
{bf:cif} computes the cumulative incidence function: CIF(t|z) = 1 - exp(-H0(t) * exp(z'beta)), where H0(t) is the baseline cumulative subdistribution hazard stored in {cmd:e(basehaz)}.

{phang2}
{bf:schoenfeld} computes Schoenfeld residuals at cause-event times. For a model with p covariates, this creates p variables: {it:newvar} for the first covariate, {it:newvar}{cmd:_2} through {it:newvar}{cmd:_}{it:p} for the rest. Residuals are missing for non-cause-event observations.

{pstd}
{cmd:finegray} must have been run before using {cmd:finegray_predict}. For models fit with factor variables or interactions, the current data must preserve the same factor-level support as the estimation sample. If a factor level has been dropped (e.g., by {cmd:drop if}), prediction will fail with an informative error.

{pstd}
{bf:Data requirements by prediction type:} {opt xb} predictions can be computed on any dataset containing the model covariates. {opt cif} predictions additionally require a time variable ({cmd:_t} or {opt timevar()}). {opt schoenfeld} residuals and {helpb finegray_phtest} require the original {cmd:stset} estimation data — specifically {cmd:_t}, {cmd:_d}, and a nonempty estimation sample ({cmd:e(sample)}). These commands will exit with an informative error if the estimation context is not present.


{marker options}{...}
{title:Options}

{phang}
{opt xb} computes the linear predictor z'beta. This is the default if neither {opt cif} nor {opt schoenfeld} is specified.

{phang}
{opt cif} computes the cumulative incidence function (CIF) at each observation's event time. The CIF is computed as 1 - exp(-H0(t) * exp(z'beta)) using the baseline cumulative subdistribution hazard from {cmd:e(basehaz)}.

{phang}
{opt sch:oenfeld} computes Schoenfeld residuals at cause-event times. For a model with {it:p} covariates, {it:p} variables are created: {it:newvar} contains residuals for the first covariate, and {it:newvar}{cmd:_2} through {it:newvar}{cmd:_}{it:p} contain residuals for the remaining covariates. Residuals are set to missing for observations that are not cause-of-interest events. {opt timevar()} has no effect when {opt schoenfeld} is specified; residuals are always computed at the original event times.

{phang}
{opth timevar(varname)} specifies a variable to use as the time axis instead of {cmd:_t}. This is useful for generating predictions at specific time points or when the data are not currently {cmd:stset}.

{pstd}
{bf:Note:} Factor-variable predictions are reconstructed on demand via {cmd:fvrevar}. The current data must contain the same factor levels as the estimation sample. Prediction on new data that lack a level present at estimation will exit with an informative error. If the persisted {cmd:_fg_*} design columns were dropped, {opt schoenfeld} residual labels still refer to the underlying factor term rather than an internal tempvar.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Setup}

{phang2}{cmd:. webuse hypoxia, clear}{p_end}
{phang2}{cmd:. gen byte status = failtype}{p_end}
{phang2}{cmd:. stset dftime, failure(dfcens==1) id(stnum)}{p_end}
{phang2}{cmd:. finegray ifp tumsize pelnode, compete(status) cause(1)}{p_end}

{pstd}
{bf:Linear predictor (default)}

{phang2}{cmd:. finegray_predict xb_hat}{p_end}

{pstd}
{bf:Cumulative incidence function}

{phang2}{cmd:. finegray_predict cif_hat, cif}{p_end}

{pstd}
{bf:CIF with explicit storage type}

{phang2}{cmd:. finegray_predict double cif_precise, cif}{p_end}
{phang2}{cmd:. summarize cif_precise}{p_end}

{pstd}
{bf:CIF at custom time points}

{phang2}{cmd:. gen double mytime = 5}{p_end}
{phang2}{cmd:. finegray_predict cif_at5, cif timevar(mytime)}{p_end}

{pstd}
{bf:Schoenfeld residuals}

{phang2}{cmd:. finegray_predict sch, schoenfeld}{p_end}
{phang2}{cmd:. list sch* in 1/5}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:finegray_predict} creates a new variable but does not store results in {cmd:r()} or {cmd:e()}. The new variable is labeled:

{phang2}{cmd:xb}: "Linear prediction (xb)"{p_end}
{phang2}{cmd:cif}: "CIF prediction"{p_end}
{phang2}{cmd:schoenfeld}: "Schoenfeld residual: {it:varname}" for each covariate{p_end}


{marker author}{...}
{title:Author}

{pstd}Timothy P Copeland, Karolinska Institutet{p_end}
{pstd}Version 1.0.0, 2026-04-06{p_end}

{pstd}Report bugs and suggestions at{break}
{browse "https://github.com/tpcopeland/Stata-Tools":https://github.com/tpcopeland/Stata-Tools}{p_end}


{title:Also see}

{psee}
Online: {helpb finegray}, {helpb finegray_phtest}, {helpb stcrreg}, {helpb stcox}, {helpb stset}

{hline}
