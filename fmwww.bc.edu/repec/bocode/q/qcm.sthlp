{smcl}
{* *! version 2.0.1 13 Sep 2024}{...}
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

{synoptset 40 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth cou:nit(numlist:numlist)}}control units to be used as the donor pool{p_end}
{synopt:{opth prep:eriod(numlist:numlist)}}pretreatment periods before the intervention occurred{p_end}
{synopt:{opth postp:eriod(numlist:numlist)}}posttreatment periods when and after the intervention occurred{p_end}

{syntab:Optimization}
{synopt:{opth nt:rees(int)}}number of trees to grow{p_end}
{synopt:{opth mt:ry(int)}}number of candidate splitting variables randomly selected at each node{p_end}
{synopt:{opth maxd:epth(int)}}maximum depth of trees{p_end}
{synopt:{opth minl:size(int)}}minimum number of observations required at each terminal node{p_end}
{synopt:{opth mins:size(int)}}minimum number of observations required to split an internal node{p_end}
{synopt:{opt fill(fil_method)}}method used to fill in missing values{p_end}

{syntab:Reporting}
{synopt:{opt cil:evel(#_c)}}set confidence level; default is {cmd:cilevel(95)}{p_end}
{synopt:{opt cis:tyle}([{bf:1}|{bf:2}|{bf:3}])}style of the confidence interval shown in figures; default is {cmd:cistyle(1)}{p_end}
{synopt:{opt qt:ype(qdef)}}quantile definition to be transmitted to {cmd:mm_quantile()}; default is {cmd:qtype(10)}{p_end}
{synopt:{opt frame(framename)}}create a Stata frame storing dataset with generated variables in the wide form{p_end}
{synopt:{opt show(#_s)}}set the maximum number of bars to show in bar charts in descending order{p_end}
{synopt:{opt noimp:ortance}}suppress the display of variable importance{p_end}
{synopt:{opt nofig:ure}}suppress the display of figures{p_end}
{synopt:{cmdab:saveg:raph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}])}save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a (strongly balanced) panel dataset before {cmd:qcm} is implemented; See {helpb xtset}.{p_end}
{p 4 6 2}
{depvar} and {indepvars} must be numeric variables, abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:qcm} implements quantile control method (QCM) via random forest (Chen, Xiao and Yao, 2024), which constructs confidence intervals for treatment effects in panel data with a single treated unit using quantile random forest (QRF; Meinshausen, 2006). 
As a nonparametric ensemble machine learning method, QRF is robust to heteroskedasticity, autocorrelation and model misspecification, and easily accommodates high-dimensional data. 

{p 4 4 2}
Simulations in Chen, Xiao and Yao (2024) show that QCM confidence intervals enjoy excellent performance in finite samples. 
In particular, for 95% nominal confidence level, the empirical coverage rates of QCM confidence intervals can reach above or near 90% if the number of pretreatment periods is greater than or equal to 20, 
and the number of control units is greater than or equal to 10. 
Moreover, additional covariates can be used to help predict the counterfactual outcomes of the treated unit.  

{p 4 4 2}
Note that {cmd:qcm} is written entirely in Stata and Mata codes, without referring to any external environments such as Python or Java. Additionally, {cmd:qcm} requires {cmd:moremata} to be installed, which is available from SSC.

{p 4 4 2}
{bf:Preprocessing of data}: A key assumption of QCM is that the data (including the outcome variable and other covariates if available) are stationary. 
For nonstationary data, it is strongly recommended to transform them into stationary data before applying QCM. 
For example, if the outcome is difference stationary with a unit root, then one should use its difference as the outcome variable. 
As another example, if the outcome variable is GDP with an exponential trend, it should be first transformed into the growth rate of GDP.  

{marker requird}{...}
{title:Required Settings}

{p 4 4 2}
{cmd:qcm} automatically reshapes the panel dataset from the long form to the wide form before implementation, 
such that {depvar} of the treated unit is transformed to the response, while {depvar} of the control units are transformed to predictors. 
If {indepvars} are specified, {indepvars} of all units are transformed to predictors.

{phang}
{opt trunit(#)} specifies the identifier of the treated unit (i.e., the unit exposed to the treatment or intervention) as defined in the panel variable set by {helpb xtset} {it:panelvar}. 
Note that only a single unit number can be specified.

{phang}
{opt trperiod(#)} specifies the time period in which the treatment or intervention was initiated. 
The time period refers to the time variable specified in {helpb xtset} {it:timevar}, 
and must be an integer (see examples below). 
Note that only a single time period can be specified.

{marker options}{...}
{title:Options}

{dlgtab:Model}  

{phang} 
{opth counit:(numlist:numlist)} specifies a list of identifiers as {it:{help numlist:numlist}} for the control units, drawn from the panel variable defined in {helpb xtset} {it:panelvar}. 
The specified control units constitute what is known as the "donor pool". 
If {bf:counit()} is omitted, the donor pool defaults to all available units other than the treated unit.

{phang} 
{opth preperiod:(numlist:numlist)} specifies a list of identifiers as {it:{help numlist:numlist}} for the pretreatment periods, 
drawn from the time variable defined in {helpb xtset} {it:timevar}. 
If {bf:preperiod()} is omitted, 
it defaults to the entire pre-intervention time span, which ranges from the earliest time period available in the time variable to the period immediately prior to the intervention.

{phang} 
{opth postperiod:(numlist:numlist)} specifies a list of identifiers as {it:{help numlist:numlist}} for the posttreatment periods (when and after the intervention occurred), 
drawn from the time variable defined in {helpb xtset} {it:timevar}. 
If {bf:postperiod()} is omitted, it defaults to the entire post-intervention time span, 
which ranges from the time period when the intervention occurred to the last time period available in the time variable.

{dlgtab:Optimization}  

{phang}
{opth ntrees(int)} specifies the number of trees to grow, which defaults to 500.

{phang}
{opth mtry(int)} specifies the number of predictors randomly selected as candidate splitting variables at each node, which defaults to the integer part of (number of predictors)/3.

{phang}
{opth maxdepth(int)} specifies the maximum depth of trees. 
If not specified, the maximum depth is unlimited, and nodes are split until all terminal nodes contain fewer than {bf:minssize} observations.

{phang}
{opth minlsize(int)} specifies the minimum number of observations required at each terminal node, which defaults to 5.

{phang}
{opth minssize(int)} specifies the minimum number of observations required to split an internal node, which defaults to 10.

{phang}
{opt fill(fil_method)} specifies the method to fill in missing values. 
If {bf:fill(mean)} is specified, missing values are filled in by sample means for each unit. 
If {bf:fill(linear)} is specified, then missing values are filled in by linear interpolation for each unit. Note that these two methods for filling in missing values are rough and only provided for convenience. 
If {opt fill(fil_method)} is omitted, then missing values are left unchanged.

{dlgtab:Reporting}

{phang}
{opt cilevel(#_c)} specifies {it:#_c} as the confidence level expressed as a percentage, where {it:#_c} must be an integer within the range [1, 99]. 
The default is {cmd: cilevel(95)}.

{phang}
{opt cistyle}([{bf:1}|{bf:2}|{bf:3}])} specifies the style for confidence intervals, where three distinct styles are available as denoted by {cmd:cistyle(1)}, {cmd:cistyle(2)}, and {cmd:cistyle(3)} respectively. 
The default is {cmd:cistyle(1)}.

{phang}
{opt qtype(qdef)} specifies {it:qdef} as the quantile definition to be transmitted to Mata command {cmd:mm_quantile()} of {helpb moremata},
where {it:qdef} must be an integer from 0 to 11. 
The default is {cmd:qtype(10)}, which uses the trimmed Harrell-Davis quantile estimator to compute sample quantiles (Akinshin, 2024), 
with the width parameter wd set as T0^(-1/2) and T0 being the number of pretreatment periods as suggested by Akinshin(2024). 
The trimmed Harrell-Davis quantile estimator is arguably the best approach currently available in the literature, which strikes a balance between efficiency and robustness. For details, see {helpb mf_mm_quantile:mm_quantile()}.

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables (including predicted outcomes and predicted quantiles) in the wide form. 
The frame named {it:framename} is replaced if existed, and created if not.

{phang} 
{opt show(#_s)} specifies the number of bars to show in bar charts, where {it:#_s} correponds to bars with the largest {it:#_s} values. 
If this option is not specified, the default is to show all bars.

{phang}
{opt noimportance} suppresses the display of variable importance. The default is to show the variable importance.

{phang}
{opt nofigure} suppresses the display of figures. The default is to display all figures.

{phang}
{cmdab:savegraph}([{it:prefix}], [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} command to save all produced graphs to the current path, 
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, 
that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph. 
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}.
Note that this option only applies when {opt nofigure} is not specified. 


{marker examples}{...}
{title:Examples 1 (without covariate): economic integration of Hong Kong with mainland China (Hsiao et al.,2012)}

{phang2}{cmd:. use growth, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Show the unit number of Hong Kong and the treatment period{p_end}
{phang2}{cmd:. label list}{p_end}
{phang2}{cmd:. di tq(2004q1)}{p_end}

{phang2}* Implement quantile control method{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. qcm gdp, trunit(9) trperiod(176)}{p_end}

{phang2}* Same as above, but uses a different style of confidence intervals{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. qui qcm gdp, trunit(9) trperiod(176) cistyle(2)} {p_end}

{phang2}* Same as above, but uses yet another different style of confidence intervals, 
saves generated graphs with prefix "growth" (replacing existing files with the same names if necessary), 
and stores results in a new Stata frame named "growth"{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. qui qcm gdp, trunit(9) trperiod(176) cistyle(3) savegraph(growth, replace) frame(growth)} {p_end}

{phang2}* Switch to the "growth" frame, and describe the data{p_end}
{phang2}{cmd:. frame change growth}{p_end}
{phang2}{cmd:. describe}{p_end}

{phang2}* Switch back to the default frame{p_end}
{phang2}{cmd:. frame change default}{p_end}

{title:Examples 2 (with covariates): effect of carbon taxes in Sweden on CO2 emissions (Andersson, 2019)}

{phang2}{cmd:. use carbontaxgr, clear}{p_end}
{phang2}{cmd:. xtset country year}{p_end}

{phang2}* Show the unit number of Sweden{p_end}
{phang2}{cmd:. label list}{p_end}

{phang2}* Implement quantile control method, and only show up to 20 bars in bar plots{p_end}
{phang2}{cmd:. set seed 1}{p_end}
{phang2}{cmd:. qcm CO2 GDP gas vehicles urban pop, trunit(13) trperiod(1990) show(20)}{p_end}

{marker storedresults}{...}
{title:Stored results}

{pstd}
{cmd:qcm} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(G)}}number of units{p_end}
{synopt:{cmd:e(T)}}number of observations with the dataset in the wide form{p_end}
{synopt:{cmd:e(T0)}}number of observations in the pretreatment periods with the dataset in the wide form{p_end}
{synopt:{cmd:e(T1)}}number of observations in the posttreatment periods with the dataset in the wide form{p_end}
{synopt:{cmd:e(K)}}number of predictors with the dataset in the wide form{p_end}
{synopt:{cmd:e(mae)}}mean absolute errors of the optimal model fitted in the pretreatment periods{p_end}
{synopt:{cmd:e(mse)}}mean squared errors of the optimal model fitted in the pretreatment periods{p_end}
{synopt:{cmd:e(rmse)}}root mean squared errors of the optimal model fitted in the pretreatment periods{p_end}
{synopt:{cmd:e(r2)}}{it:R}-squared of the optimal model fitted in the pretreatment periods{p_end}
{synopt:{cmd:e(att)}}average treatment effect on the treated over the posttreatment periods{p_end}

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
{synopt:{cmd:e(ntrees)}}number of trees to grow{p_end}
{synopt:{cmd:e(mtry)}}number of predictors randomly selected as candidate splitting variables at each node{p_end}
{synopt:{cmd:e(maxdepth)}}maximum depth of trees{p_end}
{synopt:{cmd:e(minlsize)}}minimum number of observations required at each terminal node{p_end}
{synopt:{cmd:e(minssize)}}minimum number of observations required to split an internal node{p_end}
{synopt:{cmd:e(frame)}}name of frame storing dataset with generated variables in the wide form{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(pred)}}observed and predicted outcomes, and the confidence intervals of the latter in the posttreatment periods{p_end}
{synopt:{cmd:e(eff)}}treatment effects and confidence intervals in the posttreatment periods{p_end}
{synopt:{cmd:e(imp)}}matrix containing variable importance{p_end}
{synopt:{cmd:e(imp_U)}}matrix containing variable importance aggregated by units{p_end}
{synopt:{cmd:e(imp_V)}}matrix containing variable importance aggregated by variables{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Andersson, J. J. 2019. Carbon taxes and CO2 emissions: Sweden as a case study. {it:American Economic Journal: Economic Policy} 11(4): 1-30.

{phang}
Akinshin, A. 2024. Trimmed Harrell-Davis quantile estimator based on the highest density interval of the given width. {it: Communications in Statistics - Simulation and Computation}, DOI: 10.1080/03610918.2022.2050396

{phang}
Chen, Q., Xiao Z. and Yao Q. 2024, Quantile Control via Random Forest, {it: Journal of Econometrics}, 105789.

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

{pstd}
Zhijie Xiao, Boston College, USA{break}
xiaoz@bc.edu{break}
