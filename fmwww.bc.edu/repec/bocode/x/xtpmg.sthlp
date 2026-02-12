{smcl}
{* 11feb2026}{...}
{cmd:help xtpmg} {right:version 2.0.0}
{hline}

{title:Title}

{p2colset 5 21 23 2}{...}
{p2col :{hi:xtpmg} {hline 2}}Pooled Mean-Group, Mean-Group, and
Dynamic Fixed Effects Models{p_end}
{p2colreset}{...}

{title:Version}

{pstd}
Version 2.0.0, 11 February 2026

{pstd}
{bf:Updated by:} Dr Merwan Roudane ({browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com})

{pstd}
{bf:Original authors:} Edward F. Blackburne III and Mark W. Frank, Sam Houston State University (2007)

{pstd}
{bf:What's new in version 2.0.0:}{p_end}
{p 8 12 2}- Fixed {err:r(110)} "invalid new variable name" error that occurred in Stata 15.1+{p_end}
{p 8 12 2}- Root cause: Stata's {cmd:_predict} update (Feb 2019) disallows output variable names matching estimation result names{p_end}
{p 8 12 2}- Solution: EC term is now predicted into a temporary variable, then copied to the requested name{p_end}
{p 8 12 2}- Default EC variable name changed from {cmd:__ec} to {cmd:ECT} for readability{p_end}
{p 8 12 2}- EC option parsing changed from {cmd:namelist} to {cmd:name} (single name only){p_end}
{p 8 12 2}- Improved error messages for duplicate EC variable names{p_end}
{p 8 12 2}- Minimum Stata version raised to 15.1{p_end}
{p 8 12 2}- Version number displayed in estimation output{p_end}


{title:Syntax}

{p 8 16 2}{cmd:xtpmg} {depvar} [{indepvars}] {ifin} [{cmd:,} {it:options}]


{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opth lr:(varlist)}}terms to be included in long-run cointegrating vector (Note the
difference in sign from Pesaran's specification){p_end}
{synopt :{opt nocons:tant}}suppresses constant term{p_end}
{synopt :{opth cl:uster(varname)}}adjust standard errors for intragroup
correlation{p_end}
{synopt :{opth ec:(name)}}name of newly created error-correction term; default is {cmd:ECT}{p_end}
{synopt :{opth const:raints(string)}}constraints to be applied to the model{p_end}
{synopt :{opt replace}}overwrite error correction term, if it exists{p_end}
{synopt :{opt full}}display all panel regressions for MG and PMG models{p_end}
{synopt :{opt pmg|mg|fe}}specifies the panel data specification. {opt pmg} estimates Pesaran's
Pooled Mean-Group Model, {opt mg} estimates the Mean-Group Model, and {opt fe} estimates
the Dynamic Fixed Effects Model. {opt pmg} is the default.{p_end}

{syntab:Maximum Likelihood Options}
{p 6 6 2} {it:Only valid with} {cmd:pmg}.{p_end}
{synopt :{opt tech:nique(algorithm)}}specifies the {cmd:ml} maximization technique{p_end}
{synopt :{opt diff:icult}}will use a different stepping algorithm in non-concave
regions of the likelihood see{p_end}
{p 6 6 2 }
See {helpb ml##model_options:ml model_options} for a description of available options.

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{synoptline}
{p2colreset}{...}
{p 4 6 2}
You must {cmd:tsset} your data before using {cmd:xtpmg}; see {helpb tsset}.{p_end}
{p 4 6 2}
{it:varlists} may contain time-series operators; see
{help tsvarlist}.{p_end}



{title:Description}

{pstd}
{cmd:xtpmg} aids in the estimation of large {it:N} and large {it:T} panel-data models where
nonstationarity may be a concern. In addition to the traditional dynamic fixed effects models,
{cmd:xtpmg} allows for the pooled mean group and mean group estimators. Consider the model

{p 4 12 2}d.y_it = {bind: phi*(y_(it-1)+beta*x_(it))} + {bind:d.y_(it-1)a_1}+... +
{bind:y_(it-p)a_p} +
{bind:d.x_(it)b_1}+...+{bind:d.x_(it-q)b_q} + e_(it) {space 4} i={(1,...,N}; {space 3} t={(1,...,T_i)},

where
{p 4 12 2}phi is the error correction speed of adjustment parameter to be estimated

{p 4 12 2} beta is a (k X 1) vector of parameters{p_end}

{p 4 12 2}a_1,...,a_p are p parameters to be estimated{p_end}

{p 4 12 2}x_(it) is a (1 X k) vector of covariates{p_end}

{p 4 12 2}b_1,...,b_q are q parameters to be estimated{p_end}

{p 4 12 2}and e_(it) is the error term. The assumed distribution of the error
term depends on the model estimated.{p_end}


{title:Options}

{dlgtab:Model}

{phang}
{opt constraints(constraints)}, {opt noconstant}; see {help estimation options}. (Note: Constraints are
applied post-estimation)

{phang}
{opth lr(varlist)} specifies the variables to be included in the cointegrating vector.
For identification purposes, the first listed variable will have its coefficient normalized to 1.

{phang}
{opth ec(name)} specifies the name of a new variable to be created in the dataset to hold the
error-correction term. The default is {cmd:ECT}.

{phang}
{opth cluster(varname)}; see
    {help estimation options##robust:estimation options}.

{phang}
{opt replace} replaces the error correction variable in memory, if it exists.

{phang}
{opt full} displays all panel estimation output (for the mean-group and pooled mean-group models).
 
{phang}
{cmd:pmg|mg|fe} selects the desired estimation procedure. {cmd:pmg} estimates the pooled mean-group
model where the long-run effects, beta, are constrained to be equal across all panels.
The short-run coefficients, including phi, are allowed
to differ across panels. {cmd:mg} estimates the mean-group model where the coefficients
of the model are calculated from the unweighted average of the unconstrained, fully
heterogeneous model. {cmd:fe} estimates
the dynamic fixed effects model where all parameters, except intercepts, are
constrained to be equal across panels.
{cmd:pmg} is the default.

{dlgtab:Maximum Likelihood Options}

{phang}
{opt technique(algorithm)} specifies {cmd:ml} optimization technique. 
See {helpb ml##model_options:ml model_options} 
for more information.
The {cmd:bhh} algorithm is not allowed.
This option is only valid with the
{cmd:pmg} model.

{phang}
{opt level(#)}; see {help estimation options##level():estimation options}.

{title:Bug Fix Details (Version 2.0.0)}

{pstd}
{bf:Problem:} Users running the legacy {cmd:xtpmg} (version 1.1.1, 2007) on Stata 15.1 or
newer encountered {err:r(110)} "invalid new variable name; variable name ... is in the 
list of predictors". This error was triggered by a February 2019 update to Stata's 
internal {cmd:_predict} command, which became stricter about output variable names 
matching names in estimation results.

{pstd}
{bf:Affected estimator:} Primarily the {cmd:mg} (Mean Group) estimator, where the 
{cmd:predict} command was called with {opt eq()} referencing the same name as the 
output variable.

{pstd}
{bf:Fix:} The EC prediction now uses a temporary variable as the output target, 
then copies the result to the user-specified (or default) EC variable name. This 
eliminates the name/equation conflict entirely.

{title:Examples}

{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) full}

{phang}{cmd:. xtpmg d.c d(1/2).y d.pi if year>1962, ec(ec) lr(l.c y pi) mg replace}

{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) fe}

{phang}{cmd:. cons def 1 [ec]y=.75}{p_end}
{phang}{cmd:. xtpmg d.c d.y d.pi, lr(l.c y pi) mg const(1) replace ec(ec)}

{title:Stored Results}

{pstd}
{cmd:xtpmg} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(n_g)}}number of groups{p_end}
{synopt:{cmd:e(g_min)}}minimum group size{p_end}
{synopt:{cmd:e(g_avg)}}average group size{p_end}
{synopt:{cmd:e(g_max)}}maximum group size{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(sigma)}}estimated sigma{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtpmg}{p_end}
{synopt:{cmd:e(model)}}estimation model ({cmd:pmg}, {cmd:mg}, or {cmd:fe}){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(ivar)}}name of panel variable{p_end}
{synopt:{cmd:e(tvar)}}name of time variable{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{synopt:{cmd:e(sig2_i)}}panel-specific variance estimates (PMG only){p_end}

{title:References}

{phang}
Blackburne, E.F. III and M.W. Frank. 2007. 
Estimation of nonstationary heterogeneous panels. 
{it:Stata Journal} 7(2): 197-208.

{phang}
Pesaran, M.H., Y. Shin, and R.P. Smith. 1999.
Pooled mean group estimation of dynamic heterogeneous panels.
{it:Journal of the American Statistical Association} 94: 621-634.

{phang}
Pesaran, M.H. and R. Smith. 1995.
Estimating long-run relationships from dynamic heterogeneous panels.
{it:Journal of Econometrics} 68: 79-113.

{title:Authors}

{pstd}
{bf:Version 2.0.0 update:}{p_end}
{pstd}Dr Merwan Roudane{p_end}
{pstd}{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{pstd}
{bf:Original version (1.1.1):}{p_end}
{pstd}Edward F. Blackburne III and Mark W. Frank{p_end}
{pstd}Sam Houston State University{p_end}

{title:Also see}

{psee}
Manual:  {bf:[XT] xt}

{psee}
{helpb xtdata}, {helpb xtdes},
{helpb xtreg}, {helpb xtsum},
{helpb xttab}; {helpb tsset}
{p_end}
