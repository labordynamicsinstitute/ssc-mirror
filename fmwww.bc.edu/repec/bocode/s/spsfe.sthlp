{smcl}
{cmd:help spsfe}{right:also see:  {help spsfe postestimation}}
{hline}

{title:Title}

{p2colset 5 13 15 2}{...}
{p2col :{hi:spsfe} {hline 2}}Spatial stochastic frontier models with endogeneity in the style of {help spsfe##Kutlu2020:{bind:Kutlu et al. (2020)}} {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Estimation syntax

{p 8 17 2}
{cmd:spsfe} {depvar} {indepvars} {cmd:,} {cmd:uhet(}{it:varlist} [{cmd:,} {opt nocons:tant}]{cmd:)} [{it:options}]

{pstd}
Version syntax

{p 8 17 2}
{cmd:spsfe}{cmd:,} {opt ver:sion}

{pstd}
Replay syntax

{p 8 17 2}
{cmd:spsfe} [{cmd:,}  {cmdab:l:evel(}{help level##remarks:{it:#}}{cmd:)}]

{synoptset 31 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Data structure}


{synopt : {cmd: id({it:varname})}} defines the id variable for panel data structure. If this option is omitted, the dataset defaults to single-series time structure interpretation{p_end}


{synopt : {cmd: time({it:varname})}} specifies the time variable. Mandatory when working with panel data. If this option is omitted, the data structure defaults to cross-sectional analysis{p_end}

{syntab :Frontier}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opt cost}}fit cost frontier model; default is {cmd:production}{p_end}
{synopt :{cmd:wxvars({it:varlist})}}spatially lagged independent variables 
in the frontier function{p_end}

{syntab : Ancillary equations}
{synopt :{cmd:uhet(}{it:varlist} [{cmd:,} {opt nocons:tant}]{cmd:)}}
(required) specifies that the variance of the inefficiency component is heteroskedastic and must be explicitly modeled through covariates in {it:varlist}. These covariates directly characterize the factors driving inefficiency heterogeneity. The variance function includes a constant by default; specify {opt noconstant} to exclude it term{p_end}

{synopt :{cmd:vhet({it:varlist})}}
specify explanatory
variables for the idiosyncratic error variance function.{p_end}

{syntab :Spatial setting}
{synopt :{cmdab:wm:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)}}specify spatial weight matrix{p_end}

{synopt :{cmdab:wym:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)}}specify spatial weight matrix for 
spatial lag term{p_end}

{synopt :{cmdab:wxm:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)}}specify spatial weight matrix for 
spatial Durbin terms in the frontier{p_end}


{syntab :Regression}
{synopt :{cmdab:init:ial(}{it:{help matrix:matname}}{cmd:)}}specify initial values matrix{p_end}
{synopt :{cmdab:endv:ars(}{it:varlist}{cmd:)}}specify endogeneous variables{p_end}
{synopt :{cmd:iv(}{it:varlist}{cmd:)}}specify instrumental variables{p_end}
{synopt :{cmdab:leaveo:ut(}{it:varlist}{cmd:)}}specify included exogenous variables to be left out{p_end}
{synopt :{cmd:mlsearch(}{it:{help ml##model_options:search_options}}{cmd:)}}specify options for searching initial values{p_end}
{synopt :{opt delve}}delve into maximization problem to find initial values{p_end}
{synopt :{opt mlplot}}use ml plot to find better initial values{p_end}
{synopt :{cmd:mlmodel(}{it:{help ml##model_options:model_options}}{cmd:)}}control {cmd:ml model} options{p_end}
{synopt :{cmd:mlmax({it:{help ml##ml_maximize_options:maximize_options}})}}control {cmd:ml maximize} options{p_end}
{synopt :{opt delmissing}}delete the units with missing observations from spmatrix. Required if the data has missing value{p_end}

{syntab :Reporting}
{synopt :{cmd:nolog}}omit the display of the criterion function iteration log{p_end}
{synopt :{cmd:mex(}{it:varlist}{cmd:)}}is required for calculation of total, direct, and indirect marginal effects for the specified variables in the frontier function. Omit this option if marginal effects are not needed{p_end}
{synopt :{cmdab:mldis:play(}{it:{help ml##display_options:display_options}}{cmd:)}}control {cmd:ml display} options; seldom used{p_end}
{synopt :{cmd:te(}{it:{help newvar:effvar}}{cmd:)}}create efficiency variables{p_end}
{synopt :{opt genwxvars}}generates the spatial Durbin and spatial lag terms in the specified model. It is required for the postestimation of
(in)efficiency when spatial dependence is included{p_end}

{syntab :Other}
{synopt :{cmdab:constraints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
See {help spsfe postestimation} for
features available after estimation.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{opt spsfe} implements spatial stochastic frontier models that simultaneously address endogeneity in frontier/environmental variables and spatial spillovers using the methodology of {help spsfe##Kutlu2020:{bind:Kutlu et al. (2020)}}. It supports production/cost frontiers with spatial autoregressive (SAR) terms, endogenous regressors via a control function approach, and time-varying spatial weight matrices. The command provides spillover-adjusted efficiency estimates, decomposes marginal effects into direct/indirect components, and allows heteroskedasticity modeling for inefficiency. It generalizes the traditional stochastic frontier analysis by incorporating spatial dependence structures while correcting biases from endogenous covariates.


{marker options}{...}
{title:Options for the estimation syntax}

{dlgtab:Data structure}

{phang}
{cmd: id({it:varname})} specifies cross-sectional id variable. If this option is omitted, the dataset defaults to single-series.

{phang}
{cmd: time({it:varname})} specifies time variable. It must be specified for panel data. If not, the data is assumed to be cross-sectional. 

{dlgtab:Frontier}

{phang}
{cmd:noconstant} suppresses the constant term (intercept) in the frontier function.

{phang}
{cmd:cost} specifies that the model to be fit is a cost frontier model.  The
default is {cmd:production}.

{phang}
{cmd: wxvars({it:varlist})} specifies spatially lagged independent variables in the frontier function.


{dlgtab:Ancillary equations}

{phang}{cmd:uhet(}{it:varlist}[{cmd:,} {cmd:noconstant}]{cmd:)}
specifies that the technical inefficiency component is heteroskedastic,
with the variance expressed as a function of the covariates 
defined in {it:varlist}. Specifying {cmd:noconstant} suppresses 
the constant in this function.

{phang}{cmd:vhet(}{it:varlist}{cmd:)}
specifies that the idiosyncratic error component is heteroskedastic,
with the variance expressed as a function of the covariates defined in
{it:varlist}. 


{dlgtab:Spatial weight matrix}

{phang}
{cmdab:wm:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)} specifies that the spatial weight matrices. If specified, 
all spatial terms are assumed with the same weight matrices. 

{phang}
By default, weight matrices are {cmd:Sp objects}. Specifying {cmd:mata} declares weight matrices as Mata matrices. When a single weight matrix (W1) is specified, it assumes a time-constant structure.
For time-varying cases, weight matrices (W1 W2 ... WT) must be specified in chronological order.

{phang}
Alternatively, use {cmd:array} to declare weight matrices stored in a Mata array.
When the specified array contains a single matrix, time-constant weights are assumed.
Otherwise, array keys define temporal identifiers while array values contain time-specific weight matrices.

{phang}
The {cmd:dta} option supports (time-)sparse matrix specifications. 
The data can be entered either from a local file or from a data frame (with the prefix {cmd:frame:}). 
The variables id_i, id_j, and weight in the dta file are mandatory when using dta. 
Time-varing sparse matrices require .dta variables ordered as: time, id_i, id_j, weight - where id_i/id_j are fixed variable names.
For time-constant sparse matrices, the time variable is omitted.


{phang}
{cmdab:wym:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)} specifies that the spatial weight matrices 
for the Spatial lag of the independent variable. 

{phang}
{cmdab:wxm:at(}[{it:filename}] [W1 W2 ... WT][,mata array dta]{cmd:)} specifies that the spatial weight matrices 
for the Spatial Durbin terms in the frontier function. 



{phang}
{opt normalize(row|col|spectral|minmax)} specifies the normalized method of spatial weight matrixs. 
By default, the command would not normalization the spatial weight matrixs. normalize(row) is row normalisation;
normalize(col) is collumn normalisation; normalize(spectral) is spectral normalisation;
normalize(minmax) is minmax normalisation.


{dlgtab:Regression}

{phang}
{cmd:initial(}{it:{help matrix:matname}}{cmd:)} specifies that {it:matname} is
the initial value matrix.

{phang}
{cmd:endvars(}{it:varlist}{cmd:)} specifies  the variables  are to be treated as endogenous. If this option is not specified, all variables are 
assumed to be exogenous.

{phang}
{cmd:iv(}{it:varlist}{cmd:)} specifies that the variables in ivarlist 
are to be used as instrumental variables to handle endogeneity.

{phang}
{cmd:leaveout(}{it:varlist}{cmd:)} specifies that the variables are to be taken
out of the default iv list.

{phang}
{cmd:mlsearch(}{it:{help ml##model_options:search_options}}{cmd:)} specifies ml search options for searching initial values.

{phang}
{cmd:delve} provides a regression-based methodology to search for 
initial values. The default is to use {helpb ml search:ml search} with default options.

{phang}
{opt mlplot} specifes using ml plot to find better initial values.

{phang}
{cmd:mlmodel({it:{help ml##mlmode:model_options}})} controls the {cmd:ml}
{cmd:model} options; it is seldom used.

{phang}
{cmd:mlmax({it:{help ml##ml_max_descript:maximize_options}})} controls the
{cmd:ml max} options; it is seldom used.

{phang}
{opt delmissing} deletes the units with missing observations from spmatrix. It is required to state that the data has missing value.

{dlgtab:Reporting}

{phang}
{cmd:nolog} suppresses the display of the criterion function iteration log.

{phang}
{cmd:mex(}{it:varlist}{cmd:)} is required for calculation of total, direct, and indirect marginal effects for the specified variables in the frontier function. These effects are computed during estimation and stored in the following matrices returned by {cmd:e(totalmargins)}, {cmd:e(directmargins)}, and {cmd:e(indirectmargins)}. Computation of marginal effects requires additional processing time. Omit this option if marginal effects are not needed.

{phang}
{cmd:mldisplay({it:{help ml##mldisplay:display_options}})} controls the
{cmd:ml display} options; it is seldom used.

{phang}
{cmd:te(}{it:{help newvar:effvar}}{cmd:)} generates
the production or cost efficiency variable.

{phang}
{cmd:genwxvars} generates both spatial Durbin and spatial lag terms in the specified model. It automatically appends the {cmd:Wx\_} prefix to variables declared in {cmd:wxvars()}, and is required for post-estimation analyses when spatial dependence components are included in the model framework.



{marker optionsversion}{...}
{title:Options for the version and replay syntax}

{phang}
{cmd:version} displays the version of {cmd:spsfe} installed on Stata and the
program author information.  This option can be used only in version syntax.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence
intervals.  The default is {cmd:level(95)} or as set by {helpb set level}.
This option can be used in the replay syntax or in 
{cmd:mldisplay(}{it:{help ml##mldisplay:display_options}}{cmd:)}.

{marker optionsversion}{...}
{title:Other}

{phang}
{cmdab:constraints(}{it:{help estimation options##constraints():constraints}}{cmd:)}
specifies linear constraints for the estimated model.


    {marker examples}{...}
    {title:Examples}
    
        {title:SP-SF model with time-constant spatial weight matrix}
    
    {pstd}
    Setup{p_end}
    {phang2}{bf:. {stata "spmatrix use M1 using M1.stswm"}}{p_end}
    {phang2}{bf:. {stata "use spsfe1.dta"}}{p_end}
    
    {pstd}
    Stochastic Stoch. production model {p_end}
    {phang2}{bf:. {stata "spsfe y x, wxmat(M1) wxvars(x) uhet(z) noconstant id(id) time(t)"}}{p_end}
    
    
   
       {title:SP-SF model with endogeneous variables}

    {pstd}
    Setup{p_end}
    {phang2}{bf:. {stata "mata mata matuse w_ex1"}}{p_end}
    {phang2}{bf:. {stata "use spsfe2.dta"}}{p_end}

    {pstd}
    Stochastic Stoch. production model {p_end}
    {phang2}{bf:. {stata "spsfe y x, wmat(time_W,array) wxvars(x) uhet(z) noconstant endvars(x z) iv(q1 q2) id(id) time(t)"}}{p_end}

  

{marker results}{...} 
{title:Stored results}

{pstd}
{cmd:spsfe} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(k_eq)}}number of equations in {cmd:e(b)}{p_end}
{synopt:{cmd:e(k_eq_model)}}number of equations in overall model test{p_end}
{synopt:{cmd:e(k_dv)}}number of dependent variables{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}
{synopt:{cmd:e(chi2)}}chi-squared{p_end}
{synopt:{cmd:e(p)}}significance{p_end}
{synopt:{cmd:e(rank)}}rank of {cmd:e(V)}{p_end}
{synopt:{cmd:e(ic)}}number of iterations{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(converged)}}{cmd:1} if converged, {cmd:0} otherwise{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}command used for estimation{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(chi2type)}}{cmd:Wald} or {cmd:LR}; type of model chi-squared test{p_end}
{synopt:{cmd:e(vce)}}{it:oim}{p_end}
{synopt:{cmd:e(opt)}}type of optimization{p_end}
{synopt:{cmd:e(which)}}{cmd:max} or {cmd:min}; whether optimizer is to perform maximization or minimization{p_end}
{synopt:{cmd:e(ml_method)}}type of {cmd:ml} method{p_end}
{synopt:{cmd:e(user)}}name of likelihood-evaluator program{p_end}
{synopt:{cmd:e(technique)}}maximization technique{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}
{synopt:{cmd:e(predict)}}program used to implement {cmd:predict}{p_end}
{synopt:{cmd:e(cmdbase)}}base command{p_end}
{synopt:{cmd:e(function)}}production or cost{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(totalmargins)}}Total marginal effects (if {cmd:mex()} specified){p_end}
{synopt:{cmd:e(directmargins)}}Direct marginal effects (if {cmd:mex()} specified){p_end}
{synopt:{cmd:e(indirectmargins)}}Indirect marginal effects (if {cmd:mex()} specified){p_end}
{synopt:{cmd:e(ilog)}}iteration log (up to 20 iterations){p_end}
{synopt:{cmd:e(gradient)}}gradient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{marker acknowledgments}{...}
{title:Acknowledgments}

{pstd}
Kerui Du acknowledges financial support from the National Natural Science Foundation of China(Grant no. 72074184).



{marker disclaimer}{...}
{title:Disclaimer}

{pstd}
{cmd:spsfe} is not an official Stata command.  It is a third-party command
programmed as a free contribution
to the research society.  By choosing to download, install, and use the
{cmd:spsfe} package, users assume all the liability for any
{cmd:spsfe}-package-related risk.  If you encounter any problems with the
{cmd:spsfe} package, or if you have comments, suggestions, or questions, please
send an email to Kerui Du at 
{browse "mailto:kerrydu@xmu.edu.cn":kerrydu@xmu.edu.cn}.


{marker citation}{...}
{title:References}

{marker Kutlu2020}{...}
{phang}Kutlu, Levent, Kien C. Tran, and Mike G. Tsionas (2020).
 “A Spatial Stochastic Frontier Model with Endogenous Frontier and Environmental Variables.”  European Journal of Operational Research,
286, 1: 389–99. https://doi.org/10.1016/j.ejor.2020.03.020.




{marker author}{...}
{title:Author}

{pstd}
Kerui Du{break}
Xiamen University{break}
School of Management{break}
China{break}
{browse "kerrydu@xmu.edu.cn":kerrydu@xmu.edu.cn}{break}


{pstd}
Federica Galli{break}
University of Bologna{break}
Department of Statistical Sciences “Paolo Fortunati”{break}
Italy{break}
{browse "federica.galli14@unibo.it":federica.galli14@unibo.it}{break}

{pstd}
Luojia Wang{break}
Xiamen University{break}
School of Management{break}
China{break}
{browse "ljwang@stu.xmu.edu.cn":ljwang@stu.xmu.edu.cn}{break}


{marker see}{...}
{title:Also see}

{p 7 14 2}{manhelp frontier R}, 
{manhelp xtfrontier XT}{p_end} 
{p 7 14 2}{helpb spsfe_postestimation}, {helpb sfpanel}, {helpb sfkk},  {helpb nwxtregress} (if installed)
