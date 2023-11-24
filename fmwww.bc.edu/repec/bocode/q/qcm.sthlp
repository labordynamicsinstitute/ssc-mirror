{smcl}
{* *! version 1.0.0 31 Oct 2023}{...}
{cmd:help qcm} 
{hline}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install qcm" "ssc install qcm"}{...}
{vieweralsosee "Help qcm (if installed)" "help qcm"}{...}
{viewerjumpto "Syntax" "qcm##syntax"}{...}
{viewerjumpto "Description" "qcm##description"}{...}
{viewerjumpto "Options" "qcm##options"}{...}
{viewerjumpto "Examples" "qcm##examples"}{...}
{viewerjumpto "Stored Results" "qcm##storedresults"}{...}
{viewerjumpto "Reference" "qcm##reference"}{...}
{viewerjumpto "Author" "qcm##author"}{...}

{title:Title}
{phang}
{bf:qcm} {hline 2} implementation of quantile control method (QCM) via Random Forest 

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:qcm} {depvar} [{indepvars}]
{cmd:,} 
{opt tru:nit(#)} 
{opt trp:eriod(#)}
[{it:options}]

{synoptset 60 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth cou:nit(numlist:numlist)}}control units to be used as the donor pool{p_end}
{synopt:{opth prep:eriod(numlist:numlist)}}pretreatment periods before the intervention occurred{p_end}
{synopt:{opth postp:eriod(numlist:numlist)}}posttreatment periods when and after the intervention occurred{p_end}

{syntab:Optimization}
{synopt:{opth nt:ree(int)}}number of trees to grow{p_end}
{synopt:{opth mt:ry(int)}}number of predictors randomly sampled as candidates at each split{p_end}
{synopt:{opth maxd:epth(int)}}maximum depth of trees{p_end}
{synopt:{opth minl:size(int)}}minimum number of observations required at each terminal node{p_end}
{synopt:{opth mins:size(int)}}minimum number of observations required to split an internal node{p_end}
{synopt:{opth seed(int)}}seed used by the random number generator{p_end}
{synopt:{opt fill(fil_method)}}method used to fill in missing values{p_end}

{syntab:Placebo Test}
{synopt:{cmdab: placebo}([{{bf:unit}|{opth unit(numlist)}} {opth period(numlist)} {opt cut:off(#_c)}])}in-space placebo test using fake treatment units and/or in-time placebo test using a fake treatment time{p_end}

{syntab:Reporting}
{synopt:{opt cil:evel(#_c)}}set confidence level; default is {cmd:cilevel(95)}{p_end}
{synopt:{opt cis:tyle}([{bf:1}|{bf:2}|{bf:3}])}style of the confidence interval shown in figures; default is {cmd:cistyle(1)}{p_end}
{synopt:{opt qt:ype(qdef)}}quantile definition to be transmitted to {cmd:mm_quantile()}; default is {cmd:qtype(10)}{p_end}
{synopt:{opt frame(framename)}}create a Stata frame storing dataset with generated variables in the wide form{p_end}
{synopt:{opt show(#_s)}}set the maximum number of bars to show in the bar charts in descending order{p_end}
{synopt:{opt noimp:ortance}}Do not show the variable importance. The default is to show the variable importance.{p_end}
{synopt:{opt nofig:ure}}Do not display figures. The default is to display all figures.{p_end}
{synopt:{cmdab:saveg:raph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}])}Save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a (strongly balanced) panel dataset before {cmd:qcm} is implemented; See {helpb xtset}.{p_end}
{p 4 6 2}
{depvar} and {indepvars} must be numeric variables, abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:qcm} implements quantile control method (QCM) via random forest (Chen, Xiao and Yao, 2023), which provides confidence intervals for treatment effects in panel data with a single treated unit using quantile random forest (Meinshausen, 2006). 
As a nonparametric ensemble learning, QCM is suitable for high-dimensional data, and robust to heteroskedasticity, autocorrelation and model misspecification. 
Simulations in Chen, Xiao and Yao (2023) show that for 95% nominal confidence level, the empirical coverage rate can reach above 90% if the number of pretreatment periods is 30 or larger. 
{cmd:qcm} also supports placebo tests using fake treatment units and/or fake treatment time as alternative methods for inference and robustness check.   

{p 4 4 2}
Note that {cmd:qcm} is written entirely in Stata and Mata codes, without referring to any external environments such as Python or Java. Additionally, {cmd:qcm} requires {cmd:moremata} to be installed, which is available on SSC.

{p 4 4 2}
{bf:Preprocessing of data}: A key assumption of QCM is that the data are stationary. For nonstationary data, it is strongly recommended to transform them into stationary data before applying QCM. For example, if the outcome variable is GDP with an exponential trend, it should be first transformed into the growth rate of GDP.  

{marker requird}{...}
{title:Required Settings}

{p 4 4 2}
{cmd:qcm} automatically reshapes the panel dataset from the long form to the wide form before implementation, such that {depvar} of the treated unit is transformed to the response, while {depvar} of the control units are transformed to predictors.  If {indepvars} are specified, {indepvars} of all units are transformed to predictors.

{phang}
{opt trunit(#)} the unit number of the treated unit (i.e., the unit affected by intervention) as given in the panel variable specified in {helpb xtset} {it:panelvar}. Note that only a single unit number can be specified.

{phang}
{opt trperoid(#)} the time period when the intervention occurred.  The time period refers to the time variable specified in {helpb xtset} {it:timevar}, and must be an integer (see examples below).  Note that only a single time period can be specified.

{marker options}{...}
{title:Options}

{dlgtab:Model}  

{phang} 
{opth counit:(numlist:numlist)} a list of unit numbers for the control units as {it:{help numlist:numlist}} given in the panel variable specified in {helpb xtset} {it:panelvar}.  The list of control units specified constitute what is known as the "donor pool". If no counit is specified, the donor pool defaults to all available units other than the treated unit. 

{phang} 
{opth preperiod:(numlist:numlist)} a list of pretreatment periods as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}.
If no {bf:preperiod} is specified, {bf:preperiod} defaults to the entire pre-intervention period, 
which ranges from the earliest time period available in the time variable to the period immediately prior to the intervention.

{phang} 
{opth postperiod:(numlist:numlist)} a list of posttreatment periods (when and after the intervention occurred) as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}. 
If no {bf:postperiod} is specified, {bf:postperiod} defaults to the entire post-intervention period, which ranges from the time period when the intervention occurred to the last time period available in the time variable.

{dlgtab:Optimization}  

{phang}
{opth ntree(int)} specifies the number of trees to grow, which defaults to 500.

{phang}
{opth mtry(int)} specifies the number of predictors randomly selected as candidates at each split, which defaults to (number of predictors)/3.

{phang}
{opth maxdepth(int)} specifies the maximum depth of trees. If not specified, the maximum depth is unlimited, and nodes are split until all terminal nodes contain less than {bf:minssize} observations.

{phang}
{opth minlsize(int)} specifies the minimum number of observations required at each terminal node, which defaluts to 5.

{phang}
{opth minssize(int)} specifies the minimum number of observations required to split an internal node, which defaluts to 10.

{phang}
{opth seed(int)} specifies the seed for reproducible results, which defaluts to 1.

{phang}
{opt fill(fil_method)} specifies the method to fill in missing values. If {bf:fill(mean)} is specified, missing values are filled in by sample means for each unit. If {bf:fill(linear)} is specified, then missing values are filled in linear interpolation for each unit. Note that these two methods for filling in missing values are rough, and only provided for convenience. If no {opt fill(fil_method)} is specified, then missing values are left unchanged.

{dlgtab:Placebo Test}  

{phang}
{cmdab: placebo}([{{bf:unit}|{opth unit(numlist)}} {opth period(numlist)} {opt cutoff(#_c)}]) specifies the types of placebo tests to be performed; otherwise, no placebo test will be implemented.

{phang2} 
{{bf:unit}|{opth unit(numlist)}} specifies in-space placebo test using fake treatment units in the donor pool, 
where {bf:unit} uses all fake treatment units and {opth unit(numlist)} uses a list of fake treatment units specified by {it:{help numlist:numlist}}.
These two options iteratively reassign the treatment to control units where no intervention actually occurred, 
and calculate the p-values of the treatment effects. Note that only one of {bf:unit} and {opth unit(numlist)} can be specified.

{phang2} 
{opth period:(numlist:numlist)} specifies placebo tests using fake treatment times. This option assigns the treatment to time periods before the intervention, when no treatment actually ocurred.

{phang2} 
{opt cutoff(#_c)} specifies a cutoff threshold that discards fake treatment units with pretreatment MSPE {it:#_c} times larger than that of the treated unit, where {it:#_c} must be a real number greater than or equal to 1. 
This option only applies when {bf:unit} or {opth unit(numlist)} is specified. If this option is not specified, then no fake treatment units are discarded.

{dlgtab:Reporting}

{phang}
{opt cilevel(#_c)} specifies {it:#_c} as the confidence level expressed as a percentage for calculating confidence intervals, where {it:#_c} must be an integer within the range [1, 99]. 
The default is {cmd: cilevel(95)}.

{phang}
{opt cistyle}([{bf:1}|{bf:2}|{bf:3}])} specifies the style for confidence intervals, where three distinct styles are available as denoted by {cmd:cistyle(1)}, {cmd:cistyle(2)}, and {cmd:cistyle(3)} respectively. The default is {cmd:cistyle(1)}.

{phang}
{opt qtype(qdef)} specifies {it:qdef} as the quantile definition to be transmitted to Mata command {cmd:mm_quantile()} of {helpb moremata},
where {it:qdef} must be an integer from 0 to 11. 
The default is {cmd:qtype(10)}, which uses the trimmed Harrell-Davis quantile estimator to compute sample quantiles (Akinshin, 2022), with the width parameter wd set as T0^(-1/2) and T0 being the number of pretreatment periods as suggested by Akinshin(2022). The trimmed Harrell-Davis quantile estimator is arguably the best approach currently available in the literature, which strikes a balance between efficiency and robustness. For details, see {helpb mf_mm_quantile:mm_quantile()}.

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables in the wide form. The frame named {it:framename} is replaced if existed, or created if not.

{phang} 
{opt show(#_s)} specifies the number of bars to show in all bar charts, where {it:#_s} correponds to bars with the largest {it:#_s} values. If this option is not specified, the default is to show all bars.

{phang}
{opt noimportance} Do not show the variable importance. The default is to show the variable importance.

{phang}
{opt nofigure} Do not display figures. The default is to display all figures.

{phang}
{cmdab:savegraph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path,
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph.
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}. 
Note that this option only applies when {opt nofigure} is not specified.

{marker examples}{...}
{title:Examples 1: estimating the economic impact of the 2004q1 economic integration of Hong Kong with mainland China (Hsiao et al.,2012)}

{phang2}{cmd:. use growth, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Show the unit number of Hong Kong and the treatment time{p_end}
{phang2}{cmd:. label list}{p_end}
{phang2}{cmd:. di tq(2004q1)}{p_end}

{phang2}* Implement quantile control method{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176)}{p_end}

{phang2}* Same as above, but uses a different style of confidence intervals{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176)} cistyle(2){p_end}

{phang2}* Same as above, but uses yet another different style of confidence intervals{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176)} cistyle(3){p_end}

{phang2}* Implement in-space placebo test with pretreatment MSPE 2 times smaller than or equal to that of the treated unit, and create a Stata frame "growth" storing generated variables in the wide form{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176) placebo(unit cut(2)) frame(growth)}{p_end}

{phang2}* Implement in-time placebo test with the fake treatment time 2002q1, and save all produced graphs using prefix "growth" to the current path{p_end}
{phang2}{cmd:. di tq(2002q1)}{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176) placebo(period(168)) savegraph(growth, replace)}{p_end}

{title:Examples 2: estimating the effect of carbon taxes on CO2 emissions in Sweden (Andersson, 2019)}

{phang2}{cmd:. use carbontaxgr, clear}{p_end}
{phang2}{cmd:. xtset country year}{p_end}

{phang2}* Show the unit number of Sweden{p_end}
{phang2}{cmd:. label list}{p_end}

{phang2}* Implement quantile control method, and only show up to 25 bars in bar plots{p_end}
{phang2}{cmd:. qcm CO2 GDP gas vehicles urban pop, tru(13) trp(1990) show(25)}{p_end}

{phang2}* Implement in-space placebo test with pretreatment MSPE 2 times smaller than or equal to that of the treated unit, and create a Stata frame "carbon" storing generated variables in the wide form{p_end}
{phang2}{cmd:. qcm CO2 GDP gas vehicles urban pop, tru(13) trp(1990) show(25) placebo(unit cut(2)) frame(carbon)}{p_end}

{phang2}* Implement in-time placebo test with the fake treatment time 1985, and save all produced graphs using prefix "carbon" to the current path{p_end}
{phang2}{cmd:. qcm CO2 GDP gas vehicles urban pop, tru(13) trp(1990) show(25) placebo(period(1985)) savegraph(carbon, replace)}{p_end}

{marker storedresults}{...}
{title:Stored results}

{pstd}
{cmd:qcm} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(G)}}number of units{p_end}
{synopt:{cmd:e(T)}}number of observations with the dataset in the wide form{p_end}
{synopt:{cmd:e(T0)}}number of observations in pretreatment periods with the dataset in the wide form{p_end}
{synopt:{cmd:e(T1)}}number of observations in posttreatment periods with the dataset in the wide form{p_end}
{synopt:{cmd:e(K)}}number of predictors with the dataset in the wide form{p_end}
{synopt:{cmd:e(mae)}}mean absolute error of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(mse)}}mean squared error of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(r2)}}R-squared of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(att)}}average treatment effect{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(varlist)}}names of dependent variable and independent variables{p_end}
{synopt:{cmd:e(depvar)}}name of the dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables (covariates){p_end}
{synopt:{cmd:e(response)}}name of response{p_end}
{synopt:{cmd:e(predictor)}}name of predictors{p_end}
{synopt:{cmd:e(unit_all)}}all units{p_end}
{synopt:{cmd:e(unit_tr)}}treated unit{p_end}
{synopt:{cmd:e(unit_ctrl)}}control units{p_end}
{synopt:{cmd:e(time_all)}}all periods{p_end}
{synopt:{cmd:e(time_tr)}}treatment period{p_end}
{synopt:{cmd:e(time_pre)}}pretreatment periods{p_end}
{synopt:{cmd:e(time_post)}}posttreatment periods{p_end}
{synopt:{cmd:e(ntree)}}number of trees to grow{p_end}
{synopt:{cmd:e(mtry)}}number of predictors randomly selected as candidates at each split{p_end}
{synopt:{cmd:e(maxdepth)}}maximum depth of trees{p_end}
{synopt:{cmd:e(minlsize)}}minimum number of observations required at each terminal node{p_end}
{synopt:{cmd:e(minssize)}}minimum number of observations required to split an internal node{p_end}
{synopt:{cmd:e(seed)}}seed for reproducible results{p_end}
{synopt:{cmd:e(frame)}}name of frame storing dataset with generated variables in the wide form{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(pred)}}coefficient vector of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(eff)}}variance-covariance matrix of the estimators of the optimal model fitted in pretreatment periods{p_end}
{synopt:{cmd:e(imp)}}matrix containing variable importance{p_end}
{synopt:{cmd:e(imp_U)}}matrix containing variable importance aggregated by units{p_end}
{synopt:{cmd:e(imp_V)}}matrix containing variable importance aggregated by variables{p_end}
{synopt:{cmd:e(pval)}}matrix containg treatment effects and the p-values of treatment effects in posttreatment periods{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Andersson, J. J. 2019. Carbon taxes and CO2 emissions: Sweden as a case study. {it:American Economic Journal: Economic Policy} 11(4): 1-30.

{phang}
Akinshin, A. 2022. Trimmed Harrell-Davis quantile estimator based on the highest density interval of the given width. {it: Communications in Statistics - Simulation and Computation}, DOI: 10.1080/03610918.2022.2050396

{phang}
Chen, Q., Xiao Z. and Yao Q. 2023, Quantile Control via Random Forest, {it: Journal of Econometrics}, revise and resubmit.

{phang}
Hsiao, C., Steve Ching, H., & Ki Wan, S. 2012. 
A panel data approach for program evaluation: measuring the benefits of political and economic integration of Hong Kong with mainland China. 
{it:Journal of Applied Econometrics} 27(5): 705-740.

{phang}
Meinshausen, N. 2006. Quantile regression forests. {it:Journal of Machine Learning Research} 7(2006): 983-999.

{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University of Finance and Economics, CN{break}
guanpengyan@yeah.net{break}

{pstd}
Qiang Chen (corresponding author), Shandong University, CN{break}
{browse "http://www.econometrics-stata.com":econometrics-stata.com}{break}
qiang2chen2@126.com{break}
