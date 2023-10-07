{smcl}
{* *! version 2.1.0 5 Oct 2023}{...}
{cmd:help synth2} 
{hline}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install synth2" "net describe synth2, from(http://fmwww.bc.edu/RePEc/bocode/r)"}{...}
{vieweralsosee "Help synth2 (if installed)" "help synth2"}{...}
{viewerjumpto "Syntax" "synth2##syntax"}{...}
{viewerjumpto "Description" "synth2##description"}{...}
{viewerjumpto "Required Settings" "synth2##requird"}{...}
{viewerjumpto "Options" "synth2##options"}{...}
{viewerjumpto "Examples" "synth2##examples"}{...}
{viewerjumpto "Stored results" "synth2##results"}{...}
{viewerjumpto "Reference" "synth2##reference"}{...}
{viewerjumpto "Author" "synth2##author"}{...}

{title:Title}

{phang}
{bf:synth2} {hline 2}  Implementation of synthetic control method (SCM) with placebo tests, robustness test and visualization

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:synth2} {depvar} {indepvars}, 
{opt tru:nit(#)} 
{opt trp:eriod(#)}
[{it:options}]

{synoptset 70 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth cou:nit(numlist:numlist)}}control units to be used as the donor pool{p_end}
{synopt:{opth prep:eriod(numlist:numlist)}}pretreatment periods before the intervention occurred{p_end}
{synopt:{opth postp:eriod(numlist:numlist)}}posttreatment periods when and after the intervention occurred{p_end}
{synopt:{opth xp:eriod(numlist:numlist)}}periods over which the covariates specified in {indepvars} are averaged{p_end}
{synopt:{opth mspep:eriod(numlist:numlist)}}periods over which the mean squared prediction error (MSPE) should be minimized{p_end}
{synopt:{cmdab: nested}}fully nested optimization procedure that searches among all (diagonal) positive semidefinite V-matrices and sets of W-weights{p_end}
{synopt:{cmdab: allopt}}gaining fully robust results if nested is specified{p_end}
{synopt:{opth cus:tomV(numlist)}}supply custom V-Weights which determines the predictive power of the variable for the outcome over the pretreatment periods{p_end}

{syntab:Optimization}
{synopt:{opth margin(real)}}margin for constraint violation tolerance{p_end}
{synopt:{opt maxiter(#)}}maximum number of iterations{p_end}
{synopt:{opt sigf(#)}}precision (number of significant figures){p_end}
{synopt:{opt bound(#)}}clipping bound for the variables{p_end}

{syntab:Placebo Tests}
{synopt:{cmdab: placebo}([{{bf:unit}|{opth unit(numlist)}} {opth period(numlist)} {opt cut:off(#_c)} {opt show(#_s)}])}in-space placebo test using fake treatment units and/or in-time placebo test using a fake treatment time{p_end}

{syntab:Robustness Test}
{synopt:{cmdab: loo}}Robustness test that excludes one unit in the donor pool with nonzero weight{p_end}

{syntab:Reporting}
{synopt:{opt frame(framename)}}create a Stata frame storing dataset with generated variables including counterfactual predictions, treatment effects, 
and results from placebo tests and/or robustness test if implemented{p_end}
{synopt:{opt symbol(symboltype)}}change the symbol type of generated variables in Stata frame{p_end}
{synopt:{opt nofig:ure}}Do not display figures. The default is to display all figures.{p_end}
{synopt:{cmdab:saveg:raph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}])}Save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a balanced panel dataset in the usual long form; see {manhelp xtset XT:xtset}. {p_end}
{p 4 6 2}{depvar} and {indepvars} must be numeric variables, and abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
As a wrapper program for {helpb synth} implementing synthetic control method (SCM), {cmd:synth2} provides convenient utilities to automate in-space placebo test using fake treatment units, 
in-time placebo test using a fake treatment time, and leave-one-out robustness test that excludes one control unit with nonzero weight at a time. 
{cmd:synth2} produces a series of graphs for visualization along the way. 
The command {helpb synth} (available from Statistical Software Components) is required. 
See Yan and Chen (2023) for more details.

{marker requird}{...}
{title:Required Settings}

{phang}
{opt trunit(#)} the unit number of the treated unit (i.e., the unit affected by the intervention) as given in the panel variable specified in {helpb xtset} {it:panelvar}. 
Note that only a single unit number can be specified.

{phang}
{opt trperoid(#)} the time period when the intervention occurred.
The time period refers to the time variable specified in {helpb xtset} {it:timevar}, and must be an integer (see examples below).
Note that only a single time period can be specified.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang} 
{opth counit:(numlist:numlist)} a list of unit numbers for the control units as {it:{help numlist:numlist}} given in the panel variable specified in {helpb xtset} {it:panelvar}. 
The list of control units specified constitute what is known as the "donor pool". If no {bf:counit} is specified, 
the donor pool defaults to all available units other than the treated unit. 
The  previous option {opth ctrlunit:(numlist:numlist)} is deprecated, but continues to work just like the current option {opth counit:(numlist:numlist)}.  

{phang} 
{opth preperiod:(numlist:numlist)} a list of pretreatment periods as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}.
If no {bf:preperiod} is specified, {bf:preperiod} defaults to the entire pre-intervention period, 
which ranges from the earliest time period available in the time variable to the period immediately prior to the intervention.

{phang} 
{opth postperiod:(numlist:numlist)} a list of posttreatment periods (when and after the intervention occurred) as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}. 
If no {bf:postperiod} is specified, {bf:postperiod} defaults to the entire post-intervention period, 
which ranges from the time period when the intervention occurred to the latest time period available in the time variable.

{phang} 
{opth xperiod:(numlist:numlist)} a list of periods as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}, over which the covariates specified in {indepvars} are averaged. 

{phang} 
{opth mspeperiod:(numlist:numlist)} a list of pretreatment periods as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}, 
over which the mean squared prediction error (MSPE) should be minimized. 

{phang}
{cmd:nested} if {cmd:nested} is specified, {cmd: synth2} embarks on a fully nested optimization procedure, 
which achieves better accuracy than the default algorithm at the expense of additional computing time. 
For details, see {helpb synth}. 

{phang}
{cmd: allopt} if {cmd:nested} is specified, the user can also specify {cmd: allopt} if she or he is willing to trade-off even more computing time in order to gain fully robust results. 
{cmd: allopt} provides a robustness check by running the nested optimization three times using three different starting points, 
and returns the best result. 
For details, see {helpb synth}.

{phang}
{opth customV:(numlist:numlist)} a list of custom V-weights as {it:{help numlist:numlist}} appearing in the same order as the covariates listed in {indepvars} to replace the data-driven V-weights.
For details, see {helpb synth}.


{dlgtab:Optimization}

{p 4 4 2}
The constrained quadratic optimization routine is based on an algorithm that uses the interior point method to solve the constrained quadratic programming problem (see Vanderbei 1999 for more details on the interior point method).  
It is implemented via a C++ plugin and has the following tuning parameters:

{phang}
{opt margin(real)} margin for constraint violation tolerance. The default is 5 percent (i.e., 0.05). 

{phang}
{opt maxiter(#)} maximum number of iterations. The default is 1000.

{phang}
{opt sigf(#)} precision (nnumber of significant figures). The default is 7.

{phang}
{opt bound(#)} clipping bound for the variables. The default is 10.

{p 4 4 2}
If nested is specified, a nested optimization will be performed using the constrained quadratic programming routine and Stata's ml optimizer. 
By default, {cmd: synth2}  uses the maximize default settings. 
The user may tune the maximize settings depending on his application (e.g., like {cmd: synth2} ... , iterate(20)).

{dlgtab:Placebo Tests}  

{phang}
{cmdab: placebo}([{{bf:unit}|{opth unit(numlist)}} {opth period(numlist)} {opt cutoff(#_c)} {opt show(#_s)}]) specifies the types of placebo tests to be performed; otherwise, no placebo test will be implemented.

{phang2} 
{{bf:unit}|{opth unit(numlist)}} specifies the in-space placebo test using fake treatment units in the donor pool, 
where {bf:unit} uses all fake treatment units and {opth unit(numlist)} uses a list of fake treatment units specified by {it:{help numlist:numlist}}.
These two options iteratively reassign the treatment to control units where no intervention actually occurred, 
and calculate the p-values of the treatment effects. Note that only one of {bf:unit} and {opth unit(numlist)} can be specified.

{phang2} 
{opth period:(numlist:numlist)} specifies the in-time placebo test using fake treatment times (more than one fake treatment time can be specified). 
This option reassigns the treatment to time periods previous to the intervention, when no treatment actually occurred.

{phang2} 
{opt cutoff(#_c)} specifies a cutoff threshold that discards fake treatment units with pretreatment MSPE {it:#_c} times larger than that of the treated unit, 
where {it:#_c} must be a real number greater than or equal to 1. 
This option only applies when {bf:unit} or {opth unit(numlist)} is specified. 
If this option is not specified, then no fake treatment units are discarded.

{phang2} 
{opt show(#_s)} specifies the number of units to show in the post/pre MSPE graph, which correponds to units with the largest {it:#_s} ratios of posttreatment MSPE to pretreatment MSPE.
This option only applies when {bf:unit} or {opth unit(numlist)} is specified. 
If this option is not specified, the default is to show post/pre MSPE ratios for all units.

{dlgtab:Robustness Test}  

{phang}
{cmdab: loo} specifies the leave-one-out robustness test that excludes one control unit with a nonzero weight at a time.  
{bf:synth2} iteratively re-estimates the model omitting one unit in each iteration that receives a positive weight. 
By excluding a unit receiving a positive weight goodness of fit is sacrificed, but this sensitivity check can evaluate to what extent results are driven by any particular control unit.

{dlgtab:Reporting}  

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables in the wide form including counterfactual predictions, 
treatment effects, and results from placebo tests and/or robustness test if implemented. The frame named {it:framename} is replaced if it already exists, or created if not.

{phang}
{opt symbol(symboltype)} specifies {it:signtype} as the symbol type for generated variables in Stata frame {it:framename}. 
{it:signtype} can be set to either 1 (default) or 2, correponding to the symbols "·" or "_", respectively.

{phang}
{opt nofigure} Do not display figures. The default is to display all figures from the estimation results, 
placebo tests and robustness test if available.

{phang}
{cmdab:savegraph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path,
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph.
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}. 
Note that this option only applies when {opt nofigure} is not specified.

{marker examples}{...}
{title:Example: estimating the effect of California's tobacco control program (Abadie, Diamond, and Hainmueller 2010)}

{phang2}{cmd:. use smoking, clear}{p_end}
{phang2}{cmd:. xtset state year}{p_end}

{phang2}* Replicate results in Abadie, Diamond, and Hainmueller (2010){p_end}
{phang2}{cmd:. synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested allopt} {p_end}

{phang2}* Implement in-space placebo test using fake treatment units with pretreatment MSPE 2 times smaller than or equal to that of the treated unit{p_end}
{phang2}* For illustration, we drop the "allopt" option to save time. The "allopt" option is recommended for the most accurate results if time permits{p_end}
{phang2}* To assure convergence, we change the default option "sigf(7)" (7 significant figures) to "sigf(6)". {p_end}
{phang2}{cmd:. synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested placebo(unit cut(2))  sigf(6)}{p_end}

{phang2}* Implement in-time placebo test using the fake treatment time 1985 and dropping the covariate cigsale(1988) {p_end}
{phang2}{cmd:. synth2 cigsale lnincome age15to24 retprice beer cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1984) nested placebo(period(1985))} {p_end}

{phang2}* Implement leave-one-out robustness test, create a Stata frame "california" storing generated variables, 
and save all produced graphs to the current path{p_end}
{phang2}{cmd:. synth2 cigsale lnincome age15to24 retprice beer cigsale(1988) cigsale(1980) cigsale(1975), trunit(3) trperiod(1989) xperiod(1980(1)1988) nested loo frame(california) savegraph(california, replace)}{p_end}

{phang2}* Combine all produced graphs{p_end}
{phang2}{cmd:. graph combine `e(graph)', cols(2) altshrink} {p_end}

{phang2}* Change to the generated Stata frame "california" {p_end}
{phang2}{cmd:. frame change california}{p_end}

{phang2}* Change back to the default Stata frame {p_end}
{phang2}{cmd:. frame change default}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:synth2} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(T0)}}number of pretreatment periods{p_end}
{synopt:{cmd:e(T1)}}number of posttreatment periods{p_end}
{synopt:{cmd:e(K)}}number of covariates{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error of the model fitted in the pretreatment period{p_end}
{synopt:{cmd:e(r2)}}R-squared of the model fitted over the oosttreatment period{p_end}
{synopt:{cmd:e(att)}}average treatment effect{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(panelvar)}}name of the panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of the time variable{p_end}
{synopt:{cmd:e(varlist)}}names of the dependent variable and independent variables{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables (covariates){p_end}
{synopt:{cmd:e(unit_all)}}all units{p_end}
{synopt:{cmd:e(unit_tr)}}treatment unit{p_end}
{synopt:{cmd:e(unit_ctrl)}}control units{p_end}
{synopt:{cmd:e(time_all)}}entire periods{p_end}
{synopt:{cmd:e(time_tr)}}treatment period{p_end}
{synopt:{cmd:e(time_pre)}}pretreatment periods{p_end}
{synopt:{cmd:e(time_post)}}posttreatment periods{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing generated variables{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(V_wt)}}diagonal matrix {bf:V} containing the optimal covariate weights in the diagonal{p_end}
{synopt:{cmd:e(U_wt)}}vector {bf:w} that contains the optimal unit weights{p_end}
{synopt:{cmd:e(bal)}}matrix containing sample averages for the treated unit, 
synthetic control unit and control units{p_end}
{synopt:{cmd:e(mspe)}}matrix containing pretreatment MSPE, posttreatment MSPE, ratios of posttreatment MSPE to pretreatment MSPE, and ratios of pretreatment MSPE of control units to that of the treated unit{p_end}
{synopt:{cmd:e(pval)}}matrix containing estimated treatment effects and p-values from placebo tests using fake treatment units{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2015. Comparative Politics and the Synthetic Control Method. 
{it:American Journal of Political Science} 59(2): 495-510.

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2011. SYNTH: Stata module to implement Synthetic Control Methods for Comparative Case Studies. 
{it:Statistical Software Components}, Boston College Department of Economics.

{phang}
Abadie, A., A. Diamond, and J. Hainmueller. 2010. Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association} 105(490): 493-505.

{phang}
Abadie, A. and Gardeazabal, J. 2003. Economic Costs of Conflict: A Case Study of the Basque Country. 
{it:American Economic Review} 93(1): 113-132.

{phang}
{browse "https://journals.sagepub.com/doi/abs/10.1177/1536867X231195278": Yan, G. and Chen, Q. 2023. synth2: Synthetic Control Method with Placebo Tests, Robustness Test and Visualization. {it:The Stata Journal} 23(3): 597-624.}

{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University, CN{break}
guanpengyan@yeah.net{break}

{pstd}
Qiang Chen, Shandong University, CN{break}
qiang2chen2@126.com{break}
{browse "http://www.econometrics-stata.com":www.econometrics-stata.com}{break}

{marker alsosee}{...}
{title:Also see}

{phang}Help: {help synth} (SSC), {help allsynth} (SSC, if installed), {help synth_runner} (SSC, if installed), and {help scul}(SSC, if installed).{p_end}

