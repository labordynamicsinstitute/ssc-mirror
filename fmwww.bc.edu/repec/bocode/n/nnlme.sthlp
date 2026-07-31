		{smcl}
{* *! version 1.0.0  7jul2026}{...}
{viewerdialog menl "dialog nnlme"}{...}
{vieweralsosee "[ME] nnlme" "mansection MEnnlme"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[ME] nnlme postestimation" "help nnlme postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[ME] me" "help me"}{...}
{vieweralsosee "[ME] meglm" "help meglm"}{...}
{vieweralsosee "[ME] mixed" "help mixed"}{...}
{vieweralsosee "[R] nl" "help nl"}{...}
{viewerjumpto "Syntax" "nnlme##syntax"}{...}
{viewerjumpto "Menu" "nnlme##menu"}{...}
{viewerjumpto "Description" "nnlme##description"}{...}
{viewerjumpto "Links to PDF documentation" "nnlme##linkspdf"}{...}
{viewerjumpto "Options" "nnlme##options"}{...}
{viewerjumpto "Examples" "nnlme##examples"}{...}
{viewerjumpto "Stored results" "nnlme##results"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:[ME] nnlme} {hline 2}}Nested Nonlinear Longitudinal Mixed-Effects regression{p_end}
{p2col:}({mansection ME nnlme:View complete PDF manual entry}){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{opt nnlme} {depvar} 
{ifin}
[{cmd:,} surv(varlist) time(time_variable) id(grouping_variable) [shape(varlist)] {it:{help nnlme##optstable:options}}]

		
{marker nnlmeexpr}{...}
{phang}
<{it:nnlme}> defines a program designed to implement a nested nonlinear regression following a standard exponentiated survival curve. When working correctly, the program isolates a latent curve along which there is an exogenous but unobserved acceleration in the negative direction in the rate of change over time. Because time is the main boundary defining parameter of interest, it is required for analysis to be feasible. 

{marker description}{...}
{title:Description}
{pstd}
The model contains has the option to differentiate factors predicing the placement of the latent curve as well as shape parameters that help to improve the underlying model by accounting for exogeneous factors that might influence the pattern of mean change over time. The underlying distribution of the outcome is assumed to be multivariate normal, while the latent curve is assumed to be followed by an acceleration only in the negative direction.

{pstd}
The model is implemented using {opt MENL} so there are an array of general options that may work with this program including, for example, random effects specifications. Different covariance structures are provided to model random effects and to model heteroskedasticity and correlations within lowest-level groups. 

{pstd}
See {manhelp menl ME:menl} for other available features during estimation.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{opt nnlme} stores the following in {opt e()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_nonmiss)}}number of nonmissing {it:depvar} observations, if
{cmd:tsmissing} is specified{p_end}
{synopt:{cmd:e(N_miss)}}number of missing {it:depvar} observations, if
{cmd:tsmissing} is specified{p_end}
{synopt:{cmd:e(N_ic)}}number of nonmissing {it:depvar} observations to be
used for BIC computation when {cmd:tsmissing} is specified{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_f)}}number of fixed-effects parameters{p_end}
{synopt:{cmd:e(k_r)}}number of random-effects parameters{p_end}
{synopt:{cmd:e(k_rs)}}number of variances{p_end}
{synopt:{cmd:e(k_rc)}}number of covariances{p_end}
{synopt:{cmd:e(k_res)}}number of within-group error parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations{p_end}
{synopt:{cmd:e(k_feq)}}number of fixed-effects equations{p_end}
{synopt:{cmd:e(k_req)}}number of random-effects equations{p_end}
{synopt:{cmd:e(k_reseq)}}number of within-group error equations{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_c)}}degrees of freedom for comparison test{p_end}
{synopt:{cmd:e(ll)}}linearization log (restricted) likelihood{p_end}
{synopt:{cmd:e(ll_c)}}log likelihood, comparison model{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(chi2_c)}}chi-squared for comparison test{p_end}
{synopt:{cmd:e(p)}}{it:p}-value for model test{p_end}
{synopt:{cmd:e(p_c)}}{it:p}-value for comparison test{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:menl}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivars)}}grouping variables{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(varlist)}}variables used in the specified equation{p_end}
{synopt:{cmd:e(key_N_ic)}}{cmd:nonmissing obs}, if {cmd:tsmissing} is
specified{p_end}
{synopt:{cmd:e(tsmissing)}}{cmd:tsmissing}, if specified{p_end}
{synopt:{cmd:e(tsorder)}}{cmd:tsorder()} specification{p_end}
{synopt:{cmd:e(eq_}{it:depvar}{cmd:)}}user-specified equation{p_end}
{synopt:{cmd:e(tsinit_}{it:depvar}{cmd:)}}{cmd:tsinit()} specification for
{cmd:L.{c -(}}{it:depvar}{cmd::{c )-}}{p_end}
{synopt:{cmd:e(expressions)}}names of defined expressions, {it:expr_1},
{it:expr_2}, ..., {it:expr_k}{p_end}
{synopt:{cmd:e(expr_}{it:expr_i}{cmd:)}}defined expression {it:expr_i},
i=1, ..., k{p_end}
{synopt:{cmd:e(tsinit_}{it:expr}{cmd:)}}{cmd:tsinit()} specification for
{cmd:L.{c -(}}{it:expr}{cmd::{c )-}}{p_end}
{synopt:{cmd:e(hierarchy)}}random-effects hierarchy structure,
{cmd:(}{it:path}{cmd::}{it:covtype}{cmd::}{it:REs}{cmd:) (}...{cmd:)}{p_end}
{synopt:{cmd:e(revars)}}names of random effects{p_end}
{synopt:{cmd:e(rstructlab)}}within-group error covariance output label{p_end}
{synopt:{cmd:e(timevar)}}within-group error covariance {cmd:t()} variable, if
specified{p_end}
{synopt:{cmd:e(indexvar)}}within-group error covariance {cmd:index()}
variable, if specified{p_end}
{synopt:{cmd:e(covbyvar)}}within-group error covariance {cmd:by()} variable,
if specified{p_end}
{synopt:{cmd:e(stratavar)}}within-group error variance {cmd:strata()}
variable, if specified{p_end}
{synopt:{cmd:e(corrbyvar)}}within-group error correlation {cmd:by()} variable,
if specified{p_end}
{synopt:{cmd:e(rescovopt)}}within-group error covariance option, if
{cmd:rescovariance()} specified{p_end}
{synopt:{cmd:e(resvaropt)}}within-group error variance option, if
{cmd:resvariance()} specified{p_end}
{synopt:{cmd:e(rescorropt)}}within-group error correlation option, if
{cmd:rescorrelation()} specified{p_end}
{synopt:{cmd:e(groupvar)}}lowest-level {cmd:group()} variable, if
specified{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald}; type of model chi-squared
test{p_end}
{synopt:{cmd:e(vce)}}{cmd:conventional}{p_end}
{synopt:{cmd:e(method)}}{cmd:MLE} or {cmd:REML}{p_end}
{synopt:{cmd:e(opt)}}type of optimization, {cmd:lbates}{p_end}
{synopt:{cmd:e(crittype)}}optimization criterion{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(estat_cmd)}}program used to implement {cmd:estat}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(marginsok)}}predictions allowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsnotok)}}predictions disallowed by {cmd:margins}{p_end}
{synopt:{cmd:e(marginsdefault)}}default {cmd:predict()} specification for
{cmd:margins}{p_end}
{synopt:{cmd:e(asbalanced)}}factor variables {cmd:fvset} as {cmd:asbalanced}{p_end}
{synopt:{cmd:e(asobserved)}}factor variables {cmd:fvset} as {cmd:asobserved}{p_end}

{p2col 5 23 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(Cns)}}factor-variable constraint matrix{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(V_modelbased)}}model-based variance{p_end}
{synopt:{cmd:e(b_sd)}}random-effects and within-group error estimates in the
standard deviation metric{p_end}
{synopt:{cmd:e(V_sd)}}VCE for parameters in the standard deviation
metric{p_end}
{synopt:{cmd:e(b_var)}}random-effects and within-group error estimates in the
variance metric{p_end}
{synopt:{cmd:e(V_var)}}VCE for parameters in the variance metric{p_end}
{synopt:{cmd:e(cov_}{it:#}{cmd:)}}random-effects covariance structure
at the hierarchical level k - {it:#} + 1 in a k-level model{p_end}
{synopt:{cmd:e(hierstats)}}group-size statistics for each hierarchy{p_end}

{p2col 5 23 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

INCLUDE help rtable
