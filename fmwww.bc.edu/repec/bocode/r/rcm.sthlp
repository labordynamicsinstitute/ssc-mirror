{smcl}
{* *! version 2.0.0 01 Nov 2021}{...}
{cmd:help rcm} 
{hline}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install rcm" "net describe rcm, from(http://fmwww.bc.edu/RePEc/bocode/r)"}{...}
{vieweralsosee "Help rcm (if installed)" "help rcm"}{...}
{viewerjumpto "Syntax" "rcm##syntax"}{...}
{viewerjumpto "Description" "rcm##description"}{...}
{viewerjumpto "Required Settings" "rcm##requird"}{...}
{viewerjumpto "Options" "rcm##options"}{...}
{viewerjumpto "Examples" "rcm##examples"}{...}
{viewerjumpto "Stored results" "rcm##results"}{...}
{viewerjumpto "Reference" "rcm##reference"}{...}
{viewerjumpto "Author" "rcm##author"}{...}

{title:Title}
{phang}
{bf:rcm} {hline 2}  efficient implementation of regression control method (RCM), aka panel data approach (PDA) for program evaluation (Hsiao et al., 2012) 

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:rcm} {depvar} [{indepvars}], 
{opt tru:nit(#)} 
{opt trp:eriod(#)}
[{it:options}]

{synoptset 60 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth ctrlu:nit(numlist:numlist)}}control units to be used as the donor pool{p_end}
{synopt:{opth prep:eriod(numlist:numlist)}}pre-treatment periods before the intervention occurred{p_end}
{synopt:{opth postp:eriod(numlist:numlist)}}post-treatment periods when and after the intervention occurred{p_end}

{syntab:Optimization}
{synopt:{opt sc:ope(p_min p_max)}}range of the number of selected predictors{p_end}
{synopt:{opt me:thod(sel_method)}}method for selecting the suboptimal model{p_end}
{synopt:{opt cr:iterion(sel_criterion)}}criterion for selecting the optimal model{p_end}
{synopt:{opt es:timate(est_method)}}method for estimating post-selection coefficients{p_end}
{synopt:{cmd:grid(}{it:#_g} [{cmd:,} {opt ratio(#)} {opt min(#)}]{cmd:)}}set of possible lambdas with {it:#_g} grid points{p_end}
{synopt:{opt fold(#_k)}}{it:#_k} fold cross-validation{p_end}
{synopt:{opth seed(int)}}seed used by the random number generator{p_end}
{synopt:{opt fill(fil_method)}}method used to fill in missing values{p_end}

{syntab:Placebo Test}
{synopt:{cmdab: placebo}([{opth unit unit(numlist)} {opth period(numlist)} {opt cut:off(#_c)}])}placebo test using fake treatment unit and/or time{p_end}

{syntab:Reporting}
{synopt:{opt frame(framename)}}create a Stata frame storing generated variables in wide form including counterfactual predictions, treatment effects, and results from placebo tests if implemented{p_end}
{synopt:{opt nofig:ure}}Do not display figures. The default is to display all figures.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a panel dataset in the usual long form; see {manhelp xtset XT:xtset}. 
{cmd:rcm} automatically reshapes the panel dataset from long to wide form suitable for implementing regression control method.{p_end}
{p 4 6 2}{depvar} and {indepvars} must be numeric variables, and abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:rcm} efficently implements regression control method (RCM), aka panel data approach for program evaluation (Hsiao et al., 2012), 
which exploits cross-sectional correlation to construct counterfactual outcomes for a single treated unit by linear regression (OLS), lasso or post-lasso OLS. 
Available methods for model selection include best subset, lasso, forward stepwise and backward stepwise regression, while available selection criteria include AICc, AIC, BIC, MBIC and CV (cross-validation).
Covariates ({indepvars}) are allowed to further improve counterfactual prediction as proposed by Hsiao and Zhou (2019). 
The {cmd:rcm} command produces a series of graphs for visualization along the way. 
For statistical inference, both in-space placebo test using fake treatment units and in-time placebo test using a fake treatment time can be implemented. 
For a detailed guidence to the usage of {cmd:rcm}, you may refer to Yan and Chen (2021).

{marker requird}{...}
{title:Required Settings}

{p 4 4 2}
{cmd:rcm} automatically reshapes the panel dataset from long to wide form before implementation, 
where {depvar} of the treated unit is transformed to be the response and {depvar} of the control units are transformed to be predictors. 
If {indepvars} are specified, {indepvars} of all units are transformed to be predictors during this process.

{phang}
{opt trunit(#)} the unit number of the treated unit (i.e., the unit affected by intervention) as given in the panel variable specified in {helpb xtset} {it:panelvar}. Note that only a single unit number can be specified.

{phang}
{opt trperoid(#)} the time period when the intervention occurred.
The time period refers to the time variable specified in {helpb xtset} {it:timevar}, and must be an integer (see examples below).
Note that only a single time period can be specified.

{marker options}{...}
{title:Options}

{pstd}
The model selection consists of two steps that {bf:rcm} performs automatically.  Understanding the steps is helpful for specifying options. 

{pstd}
Step 1: Select the suboptimal models

{pmore}
{cmd:rcm} selects a series of suboptimal models, each contains a unique subset of predictors. 
The exact procedure for selecting the suboptimal model depends on the selection method specified by {opt method(sel_method)}. 
Available selection methods include best subset, lasso, forward stepwise and backward stepwise selections; see below for details. 

{pstd}
Step 2: Select the optimal model from the suboptimal models

{pmore}
{cmd:rcm} selects the optimal model from the suboptimal models by information criterion or cross-validation as specified by {opt criterion(sel_criterion)}. 
The allowable {it:sel_criterion} include {bf: aicc}, {bf: aic}, {bf: bic}, {bf: mbic} and {bf: cv} (only available for {bf:method(lasso)}). 
By default, there is no restriction on the number of predictors in selecting the optimal model, but the allowable number of predictors can be specified by {opt scope(p_min p_max)} to limit its range. 

{pstd}
After model selection, {cmd: rcm} use the optimal model for counterfactual prediction and estimation of treatment effects. 
{opt estimate(est_method)} specifies the method used to estimate the optimal model, and the allowable {it:sel_criterion} include {bf: ols} (such as OLS or post-lasso OLS) and {bf: lasso} (directly uses lasso for prediction); see details below.

{dlgtab:Model}

{phang} 
{opth ctrlunit:(numlist:numlist)} a list of unit numbers for the control units as {it:{help numlist:numlist}} given in the panel variable specified in {helpb xtset} {it:panelvar}. 
The list of control units specified constitute what is known as the "donor pool". If no {bf:ctrlunit} is specified, 
the donor pool defaults to all available units other than the treated unit.

{phang} 
{opth preperiod:(numlist:numlist)} a list of pre-treatment periods as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}.
If no {bf:preperiod} is specified, {bf:preperiod} defaults to the entire pre-intervention period, 
which ranges from the earliest time period available in the time variable to the period immediately prior to the intervention.

{phang} 
{opth postperiod:(numlist:numlist)} a list of post-treatment periods (when and after the intervention occurred) as {it:{help numlist:numlist}} given in the time variable specified in {helpb xtset} {it:timevar}. 
If no {bf:postperiod} is specified, {bf:postperiod} defaults to the entire post-intervention period, which ranges from the time period when the intervention occurred to the last time period available in the time variable.

{dlgtab:Optimization}

{phang}
{opt scope(p_min p_max)} specifies the allowable range for the number of predictors in the optimal model. {cmd:rcm} selects the optimal model from the suboptimal models containing {it:p_min} to {it:p_max} predictors.
{it:p_min} and {it:p_max} are two numbers that specify the lower and upper bounds of the number of predictors, and the defaults are 1 and the number of all predictors respectively. 
If there is no model with the number of predictors in the specified range, {it:p_min} and {it:p_max} are automatically changed to the default to expand the selection.

{phang}
{opt method(sel_method)} specifies the method used for selecting the suboptimal model.
{it:sel_method} may be {bf:best}(the default), {bf:lasso}, {bf:forward}, or {bf:backward}.

{phang2} 
{bf:best} (best subset regression) is the default, which considers different numbers of predictors in each iteration of OLS estimation,
and select the suboptimal model with the highest R-squared for each specified number of predictors. We use the "leaps and bounds" algorithm (Furnival and Wilson, 1974) to speed up the process of best subset selection.
Nevertheless, it may still be too time-consuming when there are many predictors, 
or more predictors than the number of pre-treatment periods. 
In that case, you may wish to try {bf:method(lasso)}(recommended), {bf:method(forward)}, or {bf:method(backward)}.
Alternatively, you may restrict {indepvars}, and/or the donor pool by the option {opth ctrlunit:(numlist:numlist)}. 

{phang2} 
{bf:lasso} (lasso regression) sets a grid for lambda (known as the tuning or penalty parameter), 
and fits the corresponding lasso regressions on that grid as the suboptimal models. Specifically, lambda iterates from lambda_{gmax} to lambda_{gmin}; see {manhelp lasso LASSO:lasso}.

{phang2} 
{bf:forward} (forward stepwise regression) starts with the smallest model, adds a predictor in each iteration of OLS estimation, 
and selects the model with the highest R-squared as the suboptimal model for each iteration. If {bf:method(best)} is feasible, then {bf:method(forward)} is NOT recommended. 

{phang2} 
{bf:backward} (backward stepwise regression) starts with the largest possible model, 
drops a predictor in each iteration of OLS estimation, and selects the model with the highest R-squared as the suboptimal model for each iteration. 
If {bf:method(best)} is feasible, then {bf:method(backward)} is NOT recommended. Note that {bf:method(backward)} is not applicable in the high-dimensional case, where the number of predictors exceeds the number of pre-treatment periods. 

{phang}
{opt criterion(sel_criterion)} specifies the criterion for selecting the optimal model from all suboptimal models, which may be{bf: aicc} (the default), {bf: aic}, {bf: bic}, {bf: mbic} or {bf: cv}.

{phang2} 
{bf:aicc} is the defalut, which specifies the corrected Akaike information criterion (AICc) as the criterion for selecting the optimal model; see Hsiao et al. (2012) for details.

{phang2}
{bf:aic} specifies Akaike information criterion (AIC) as the selection criterion.

{phang2} 
{bf:bic} specifies Bayesian information criterion (BIC) as the selection criterion. 

{phang2} 
{bf:mbic} specifies the modified Bayesian information criterion (MBIC) as the selection criterion; see Wang et al. (2009) and Shi and Huang (2021) for details. 

{phang2} 
{bf:cv} specifies cross-validation mean squared error (CVMSE) as the selection criterion.
Note that {bf:criterion(cv)} only applies to {bf:method(lasso)}, and the option {opt fold(#)} determines the the number of folds for cross-validation (see details below). 

{phang}
{opt estimate(est_method)} specifies the method used to estimate the optimal model for counterfactual prediction, which may be {bf:ols} (the default) or {bf: lasso}.

{phang2} 
{bf:ols} is the default, which estimates the optimal model either by OLS, or post-lasso OLS, whichever is applicable. The latter  corresponds to the combination of {bf:method(lasso)} and {bf:estimate(ols)}.

{phang2} 
{bf:lasso} directly uses lasso to estimate the optimal model for counterfactual prediction. Note that {bf:estimate(lasso)} only applies to {bf:method(lasso)}.

{phang}
{cmd:grid(}{it:#_g} [{cmd:,} {opt ratio(#)} {opt min(#)}]{cmd:)} is a rarely used option specifying the
set of possible lambdas with {it:#_g} grid points, where {opt ratio(#)} specifies lambda_{gmin}/lambda_{gmax}, and {opt min(#)} specifies lambda_{gmin}.
These parameters are transmitted to the Stata command {helpb lasso}; see {manhelp lasso LASSO:lasso} for details. 
Note that this option only applies to {bf:method(lasso)}.

{phang}
{opt fold(#_k)} specifies cross-validation with {it:#_k} folds, where {it:#_k} must be an integer >= 3 and <= T0 (the number of pre-treatment periods).  This option only applies to the combination of {bf:method(lasso)} and {bf:criterion(cv)}. 
The default is {bf:fold(}T0{bf:)}, which corresponds to leave-one-out cross-validation (LOOCV).

{phang}
{opth seed(int)} the seed used by the random number generator for reproducible results, which defaults to 1.
This option is only useful for {bf:criterion(cv)}.

{phang}
{opt fill(fil_method)} is a rarely used option that specifies the method to fill in missing values. 
If {bf:fill(mean)} is specified, missing values are replaced by sample means for each unit. 
If {bf:fill(linear)} is specified, then missing values are replaced by linear interpolation for each unit. 
Beware that these two methods for filling in missing values are rough, and only provided for convenience. If no {opt fill(fil_method)} is specified, then missing values are left unchanged.

{p 8 8 2}
Note that {cmd:rcm} generally allows for missing values in the pre-treatment periods, although it may be difficult to perform cross-validation for lasso.
However, if the selected predictors include missing values in the post-treatment periods, then there will be missing values in the counterfactual predictions and treatment effects as well.
{p_end}

{dlgtab:Placebo Test}  

{phang}
{cmdab: placebo}([{opth unit unit(numlist)} {opth period(numlist)} {opt cutoff(#_c)}]) specifies the types of placebo tests to be performed; otherwise, no placebo test will be implemented.

{phang2} 
{bf:unit} and {opth unit(numlist)} specifies placebo tests using fake treatment units in donor pool, 
where {bf:unit} uses all fake treatment units and {opth unit(numlist)} uses a list of fake treatment units specified by {it:{help numlist:numlist}}.
These two options iteratively assign the treatment to control units where no intervention actually occurred, 
and calculate the p-value of the treatment effect. Note that only one of {bf:unit} and {opth unit(numlist)} can be specified.

{phang2} 
{opth period:(numlist:numlist)} specifies placebo tests using fake treatment times. This option assigns the treatment to time periods previous to the intervention, when no treatment actually ocurred.

{phang2} 
{opt cutoff(#_c)} specifies a cutoff threshold that discards fake treatment units with pre-treatment MSPE {it:#_c} times larger than that of the treated unit, where {it:#_c} must be a real number greater than or equal to 1. 
This option only applies when {bf:unit} or {opth unit(numlist)} is specified. If this option is not specified, then no fake treatment units are discarded.

{dlgtab:Reporting}  

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables in wide form including counterfactual predictions, treatment effects, and results from placebo tests if implemented. The frame named {it:framename} is replaced if it already exists, or created if not.

{phang}
{opt nofigure} Do not display figures. The default is to display all figures for estimation results and placebo tests if available.

{marker examples}{...}
{title:Example 1: estimating the impact of political integration of Hong Kong with mainland China in 1997q3 (Hsiao et al., 2012)}

{phang2}{cmd:. use growth, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Show the unit number of Hong Kong and treatment periods{p_end}
{phang2}{cmd:. label list}{p_end}
{phang2}{cmd:. display tq(1997q3)}{p_end}
{phang2}{cmd:. display tq(2003q4)}{p_end}

{phang2}* Replicate results in Hsiao et al.(2012) with specified control units and designated post-treatment periods{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(150) ctrlunit(4 10 12 13 14 19 20 22 23 25) postperiod(150/175)}{p_end}

{phang2}* Use post-lasso OLS with LOOCV and all control units,
and create a Stata frame "growth_wide" storing generated variables in wide form including counterfactual predictions, treatment effects, and results from placebo tests if implemented{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(150) postperiod(150/175) method(lasso) criterion(cv) frame(growth_wide)}{p_end}

{phang2}* Change to the generated Stata frame "growth_wide" {p_end}
{phang2}{cmd:. frame change growth_wide}{p_end}

{phang2}* Change back to the default Stata frame {p_end}
{phang2}{cmd:. frame change default}{p_end}

{phang2}* Implement a placebo test using all fake treatment units in the donor pool{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(150) postperiod(150/175) method(lasso) criterion(cv) placebo(unit)}{p_end}

{title:Example 2: estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)}

{phang2}{cmd:. use growth, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Show the unit number of Hong Kong and the treatment period{p_end}
{phang2}{cmd:. label list}{p_end}
{phang2}{cmd:. display tq(2004q1)}{p_end}

{phang2}* Replicate results in Hsiao et al.(2012) with all control units{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(176) method(best)}{p_end}

{phang2}* Use post-lasso OLS with LOOCV, and create a Stata frame "growth_wide" storing generated variables in wide form{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(176) method(lasso) criterion(cv) frame(growth_wide)}{p_end}

{phang2}* Implement placebo tests using all fake treatment units in the donor pool, and fake treatment time 2002q1{p_end}
{phang2}{cmd:. display tq(2002q1)}{p_end}
{phang2}{cmd:. rcm gdp, trunit(9) trperiod(176) method(lasso) criterion(cv) placebo(unit period(168))}{p_end}

{title:Example 3: estimating the impact of German reunification in 1990 (Abadie et al., 2015)}

{phang2}{cmd:. use repgermany.dta, clear}{p_end}
{phang2}{cmd:. xtset country year}{p_end}

{phang2}* Show the unit number of West Germany{p_end}
{phang2}{cmd:. label list}{p_end}

{phang2}* Use post-lasso OLS with 10-fold cross-validation without covariates{p_end}
{phang2}{cmd:. rcm gdp, tru(17) trp(1990) me(lasso) cr(cv) fold(10)}{p_end}

{phang2}* Use three covariates as additional predictors{p_end}
{phang2}{cmd:. rcm gdp infrate trade industry, tru(17) trp(1990) me(lasso) cr(cv) fold(10)}{p_end}

{phang2}* Fill in missing values by sample means for each units, and implement placebo tests using the fake treatment units with pre-treatment MSPE 10 times smaller than or equal to that of the treated unit{p_end}
{phang2}{cmd:. rcm gdp infrate trade industry, tru(17) trp(1990) me(lasso) cr(cv) fold(10) fill(mean) placebo(unit cut(10))}{p_end}

{phang2}* Fill in missing values by sample means for each units, and implement a placebo test with fake treatment time 1980{p_end}
{phang2}{cmd:. rcm gdp infrate trade industry, tru(17) trp(1990) me(lasso) cr(cv) fold(10) fill(mean) placebo(period(1980))}{p_end}

{phang2}* Fill in missing values by linear interpolation for each units, and create a Stata frame "WestGermany_wide" storing generated variables in wide form{p_end}
{phang2}{cmd:. rcm gdp infrate trade industry, tru(17) trp(1990) me(lasso) cr(cv) fold(10) fill(linear) frame(WestGermany_wide)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rcm} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(T)}}number of observations in the dataset in wide form{p_end}
{synopt:{cmd:e(T0)}}number of observations in the pre-treatment periods with the dataset in wide form{p_end}
{synopt:{cmd:e(T1)}}number of observations in the post-treatment periods with the dataset in wide form{p_end}
{synopt:{cmd:e(K_preds_all)}}number of all predictors{p_end}
{synopt:{cmd:e(K_preds_sel)}}number of predictors selected for the optimal model{p_end}
{synopt:{cmd:e(aicc)}}AICc of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(aic)}}AIC of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(bic)}}BIC of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(mbic)}}MBIC of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(cvmse)}}CVMSE of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(mae)}}mean absolute error of the model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(mse)}}mean squared error of the model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error of the model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(r2)}}R-squared of the model fitted in the pre-treatment periods{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(panelvar)}}name of the panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of the time variable{p_end}
{synopt:{cmd:e(varlist)}}names of the dependent variable and independent variables{p_end}
{synopt:{cmd:e(respo)}}name of the response{p_end}
{synopt:{cmd:e(preds_all)}}names of all predictors{p_end}
{synopt:{cmd:e(preds_sel)}}names of the predictors selected for the optimal model{p_end}
{synopt:{cmd:e(unit_all)}}all units{p_end}
{synopt:{cmd:e(unit_tr)}}treatment unit{p_end}
{synopt:{cmd:e(unit_ctrl)}}control units{p_end}
{synopt:{cmd:e(time_all)}}entire periods{p_end}
{synopt:{cmd:e(time_tr)}}treatment period{p_end}
{synopt:{cmd:e(time_pre)}}pre-treatment periods{p_end}
{synopt:{cmd:e(time_post)}}post-treatment periods{p_end}
{synopt:{cmd:e(regcmd)}}{bf:regress}{p_end}
{synopt:{cmd:e(regcmdline)}}regression command of the optimal model{p_end}
{synopt:{cmd:e(scope)}}allowable range for the number of predictors to be selected{p_end}
{synopt:{cmd:e(method)}}method for selecting the suboptimal models{p_end}
{synopt:{cmd:e(criterion)}}criterion for selecting the optimal model from all suboptimal models{p_end}
{synopt:{cmd:e(estimate)}}method for estimating the optimal model for counterfactual predictions{p_end}
{synopt:{cmd:e(seed)}}seed used by the random number generator for reproducible results{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing generated variables in wide form{p_end}
{synopt:{cmd:e(properties)}}{bf:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the optimal model estimated in the pre-treatment periods{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the coefficient estimators of the optimal model fitted in the pre-treatment periods{p_end}
{synopt:{cmd:e(info)}}matrix containg information of the suboptimal models{p_end}
{synopt:{cmd:e(mspe)}}matrix containg pre-treatment MSPE, post-treatment MSPE, ratios of post-treatment MSPE to pre-treatment MSPE, and ratios of pre-treatment MSPE of control units to that of the treatment unit{p_end}
{synopt:{cmd:e(pval)}}matrix containg estimated "treatment effects" and p-values from placebo tests using fake treatment units{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Abadie, Alberto, Alexis Diamond, and Jens Hainmueller. 2015. Comparative Politics and the Synthetic Control Method. 
{it:American Journal of Political Science} 59(2): 495-510.

{phang}
Hsiao, Cheng, H. Steve Ching, and Shui Ki Wan. 2012. A Panel Data Approach for Program Evaluation: Measuring the Benefits of Political and Economic Integration of Hong Kong with Mainland China. 
{it:Journal of Applied Econometrics} 27(5): 705-740.

{phang}
Hsiao, Cheng, and Qiankun Zhou. 2019. Panel Parametric, Semiparametric, and Nonparametric Construction of Counterfactuals. 
{it:Journal of Applied Econometrics} 34(4): 463-481.

{phang}
Furnival, George M., and Robert W. Wilson, Jr. 1974. Regressions by Leaps and Bounds. 
{it:Technometrics} 16(4): 499-511.

{phang}
Shi, Zhentao and Jingyi Huang. 2021. Forward-selected panel data approach for program evaluation. 
{it:Journal of Econometrics} forthcoming.

{phang}
Wang, Hanseng, Bo Li and Chenlei Leng. 2009. Shrinkage tuning parameter selection with a diverging number of parameters. 
{it:Journal of Royal Statistical Society, Series B} 71(3): 671-683.

{phang}
Yan, Guanpeng, and Qiang Chen. 2022. rcm: A Stata Command for Regression Control Method. 
{it:Stata Journal} revise and resubmit.

{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University, CN{break}
guanpengyan@yeah.net{break}

{pstd}
Qiang Chen, Shandong University, CN{break}
{browse "http://www.econometrics-stata.com":www.econometrics-stata.com}{break}
qiang2chen2@126.com{break}


