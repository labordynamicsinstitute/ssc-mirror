{smcl}
{* *! version 1.0.0 08 Mar 2024}{...}
{cmd:help xtteifeci} 
{hline}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help xtteifeci (if installed)" "help xtteifeci"}{...}
{viewerjumpto "Syntax" "xtteifeci##syntax"}{...}
{viewerjumpto "Description" "xtteifeci##description"}{...}
{viewerjumpto "Required Settings" "xtteifeci##requird"}{...}
{viewerjumpto "Options" "xtteifeci##options"}{...}
{viewerjumpto "Examples" "xtteifeci##examples"}{...}
{viewerjumpto "Stored results" "xtteifeci##results"}{...}
{viewerjumpto "Reference" "xtteifeci##reference"}{...}
{viewerjumpto "Author" "xtteifeci##author"}{...}

{title:Title}

{phang}
{bf:xtteifeci} {hline 2} implemention of estimation and inference of treatment effects through a factor-based approach.

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:xtteifeci} {depvar} [{indepvars}], 
{opt tr:eatvar(treatvarname)} 
[{it:options}]

{synoptset 60 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt r(#)}}number of factors{p_end}
{synopt:{opt iter:ate(#)}}maximum number of iterations{p_end}
{synopt:{opth tol:erance(float)}}tolerance criterion for convergence{p_end}
{synopt:{cmdab: trend}({{bf:0}|{bf:1})}}indicator of nonstationary trend{p_end}
{synopt:{opt boots:trap(#)}}number of bootstrap samples{p_end}
{synopt:{opth seed(int)}}seed used by the random number generator{p_end}

{syntab:Optimization}
{synopt:{opt rme:thod}({{bf:bn}|{bf:abc}})}method for calculating the number of factors{p_end}
{synopt:{opt rmax(#)}}maximum number of factors{p_end}

{syntab:Reporting}
{synopt:{cmdab: citype}({{bf:eq}|{bf:sy})}}type of reported confidence interval{p_end}
{synopt:{opt frame(framename)}}create a Stata frame storing generated variables.{p_end}
{synopt:{opt nofig:ure}}do not display figures.{p_end}
{synopt:{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}])}save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a strongly panel dataset in the usual long form; see {manhelp xtset XT:xtset}.{p_end}
{p 4 6 2}{depvar} and {indepvars} must be numeric variables, and abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:xtteifeci} is designed for estimation and inference of treatment effects and provide nonparamametric confidence
intervals for panel data models with interactive fixed effects as proposed by Li et al. (2024), 
which augments the works of Gobillon and Magnac (2016), Xu (2017), and Bai and Ng (2021). 
{cmd:xtteifeci} supports statistical inference through reporting confidence intervals and {it: p}-values, 
applicable to models with diverse specifications, including those with or without covariates and/or nonstationary trends. For a detailed guidence to the usage of {cmd:xtteifeci}, see Yan et al. (2024).

{marker requird}{...}
{title:Required Settings}

{p 4 4 2}
To implement a factor-based approach, the outome variable {depvar} and the treatment variable {it:treatvarname} must be inputted to {cmd:xtteifeci}. 
Appending covariates {indepvars} to model is dispensable but conducive to the prediction of counterfactual outcome and the estimation of treatment effects. 
If {it:treatvarname} signifies staggered treatments, i.e., multiple units undergo intervention at various periods, 
{cmd:xtteifeci} automatically identifies the number of periods without treatment across all units as the height of "wide block" and recognizes the number of control units as the width of "tall block".

{phang} 
{opt treatvar(treatvarname)} specifies a dummy variable indicating whether a unit is treated in a particular period.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang} 
{opt r(#)} specifies the number of factors that used for factor-based estimation of treatment effects, 
where {it:#} is an {it:{help data_types:int}} that falls within the range [1, min({it:T_0}, {it:G_0})], {it:T_0} is the number of periods without treatment across all units, and {it:G_0} is the number of control units. 
If {opt r(#)} is not specified, 
{cmd:xtteifeci} automatically determines the number of factors by the options {opt rmethod}({{bf:bn}|{bf:abc}}) and {opt rmax(#)}.

{phang} 
{opt iterate(#)} specifies the maximum number of iterations allowed in factor-based estimation. 
For the model with covariates, {cmd:xtteifeci} terminates iterations when the coefficient estimation reaches {it:#} loops to prevent an infinite loop in case the estimator does not converge. 
{it:#} is set to a large positive {it:{help data_types:int}}, which defaults to 1000.

{phang} 
{opth tolerance(tol)} specifies the tolerance criterion in interactive fixed effect estimation.
For the model with covariates, {cmd:xtteifeci} terminates iterations when the L2 norm difference of the estimator between two consecutive iterations is less than the specified threshold {it:tol}.
{it:tol} is set to a small positive {it:{help data_types:float}}, which defaults to 0.0001.

{phang}
{cmdab: trend}({{bf:0}|{bf:1}}) specifies an indicator of nonstationary trend.
{cmdab: trend}({bf:0}) and {cmdab: trend}({bf:1}) correspond to stationary and nonstationary trend, respectively.
For the model with nonstationary trend, {cmd:xtteifeci} implement modified asymptotic principal component analysis or continuously-updated estimatation, 
which can be viewed as a generalisation of asymptotic principal component analysis or interactive fixed effect estimation, respectively.
If neither {cmdab: trend}({bf:0}) nor {cmdab: citype}({bf:1}) is specified, the default is {cmdab: trend}({bf:0}).

{phang}
{opt bootstrap(#)} specifies the number of bootstrap samples for factor-based estimation of treatment effects. 
{cmd:xtteifeci} employs a residual-based resampling scheme to generate {it:#} bootstrap samples for constructing confidence intervals of treatment effects. 
{it:#} is set to a large positive {it:{help data_types:int}}, which defaults to 500.

{phang}
{opth seed(int)} specifies the seed used by the random number generator for reproducible results, which defaults to 1. 

{dlgtab:Optimization}

{p 4 4 2}
If {opt r(#)} is not specified, {cmd:xtteifeci} determines the number of factors for model using BN method (proposed by Bai and Ng (2002)) or ABC method (proposed by Alessi et al. (2010)), 
corresponding to the option {opt rme:thod}({bf:bn}) or {opt rme:thod}({bf:abc}), respectively.

{phang}
{opt rmethod}({{bf:bn}|{bf:abc}}) specifies the method to determine the number of factors for the model of factor-based approach, 
with {cmdab: rmethod}({bf:bn}) for BN method (proposed by Bai and Ng (2002)) or {cmdab: rmethod}({bf:abc}) for ABC method (proposed by Alessi et al. (2010)). 
If neither {cmdab: rmethod}({bf:bn}) nor {cmdab: rmethod}({bf:abc}) is specified, the default is set to {cmdab: rmethod}({bf:bn}).

{phang}
{opt rmax(#)} specifies the maximum number of factors limited in ABC method or BN method, which defaults to 8.

{dlgtab:Reporting}

{phang}
{cmdab: citype}({{bf:eq}|{bf:sy}}) specifies the type of reported confidence interval of predicted outcomes and treatment effects. 
{cmdab: citype}({bf:eq}) corresponds to the equal tailed confidence interval, and {cmdab: citype}({bf:sy}) corresponds to the symmetric confidence interval. 
If neither {cmdab: citype}({bf:eq}) nor {cmdab: citype}({bf:sy}) is specified, the default is set to {cmdab: citype}({bf:eq}).

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables including counterfactual predictions, treatment effects, 
90%, 95%, 99% confidence intervals of predicted outcomes and treatment effects, 
and {it:p}-values of treatment effects. 
The frame named {it:framename} is replaced if it already exists, or created if not.

{phang}
{opt nofigure} do not display figures. The default is to display all figures for estimation results.

{phang}
{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path, 
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, 
that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph. 
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}.
Note that this option only applies when {opt nofigure} is not specified. 

{marker examples}{...}
{title:Example 1: estimating the impact of political integration of Hong Kong with mainland China in 1997q3 (Hsiao et al., 2012)}

{phang2}{cmd:. use growth2, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Visualize the configuration of the treatment variable "pi" for political integration in panel data ({bf:panelview} has been installed from SSC){p_end}
{phang2}{cmd:. panelview gdp pi, i(region) t(time) type(treat)}{p_end}

{phang2}* Implement factor-based estimation upon the condition of no missing values in "pi"{p_end}
{phang2}{cmd:. xtteifeci gdp if !missing(pi), treatvar(pi)}{p_end}

{phang2}* Implement factor-based estimation with the reporting of symmetric confidence intervals{p_end}
{phang2}{cmd:. xtteifeci gdp if !missing(pi), treatvar(pi) citype(sy)}{p_end}

{title:Example 2: estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)}

{phang2}{cmd:. use growth2, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Visualize the configuration of the treatment variable "ei" for economic integration in panel data ({bf:panelview} has been installed from SSC){p_end}
{phang2}{cmd:. panelview gdp ei, i(region) t(time) type(treat)}{p_end}

{phang2}* Implement factor-based estimation and create a Stata frame "growth_ei" storing generated variables{p_end}
{phang2}{cmd:. xtteifeci gdp, treatvar(ei) frame(growth_ei)}{p_end}

{phang2}* Change to the generated Stata frame "growth_ei" {p_end}
{phang2}{cmd:. frame change growth_ei}{p_end}

{phang2}* Change back to the default Stata frame {p_end}
{phang2}{cmd:. frame change default}{p_end}

{title:Example 3: estimating the effect of California's tobacco control program (Abadie, Diamond, and Hainmueller 2010)}

{phang2}{cmd:. use smoking2, clear}{p_end}
{phang2}{cmd:. xtset state year}{p_end}

{phang2}* Visualize the configuration of the treatment variable "ctcp" for California's tobacco control program (CTCP) in panel data ({bf:panelview} has been installed from SSC){p_end}
{phang2}{cmd:. panelview cigsale ctcp, i(region) t(time) type(treat)}{p_end}

{phang2}* Implement factor-based estimation for the model with covariates, a nonstationary trend and the number of factors calculated by ABC method{p_end}
{phang2}{cmd:. xtteifeci cigsale lnincome eduattain poverty, treatvar(ctcp) rmethod(abc) trend(1)}{p_end}

{phang2}* List the names and values of the macros, scalars and matrix stored in e(){p_end}
{phang2}{cmd:. ereturn list}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rcm} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations on which coefficient estimation was performed{p_end}
{synopt:{cmd:e(df_r)}}number of degrees of freedom used with {it:t} statistics of coefficient estimation{p_end}
{synopt:{cmd:e(r)}}number of factors{p_end}
{synopt:{cmd:e(T)}}number of periods{p_end}
{synopt:{cmd:e(T0)}}number of periods without treatment across all units{p_end}
{synopt:{cmd:e(T1)}}number of periods with treatment across at least one unit{p_end}
{synopt:{cmd:e(G)}}number of units{p_end}
{synopt:{cmd:e(G0)}}number of control units{p_end}
{synopt:{cmd:e(G1)}}number of treated units{p_end}
{synopt:{cmd:e(mse)}}mean squared error of the model fitted{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error of the model fitted{p_end}
{synopt:{cmd:e(r2)}}{it:R}-squared of the model fitted {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(varlist)}}names of dependent variable and independent variables{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(trend)}}indicator of nonstationary trend{p_end}
{synopt:{cmd:e(cmd)}}{bf:xtteifeci}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(seed)}}seed used by the random number generator for reproducible results{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing generated variables{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}
{synopt:{cmd:e(properties)}}{bf:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the model fitted{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the coefficient estimators of the model fitted{p_end}
{synopt:{cmd:e(Ftall)}}common factors matrix estimated from "tall block"{p_end}
{synopt:{cmd:e(Ltall)}}factor loadings matrix estimated from "tall block"{p_end}
{synopt:{cmd:e(Fwide)}}common factors matrix estimated from "wide block"{p_end}
{synopt:{cmd:e(Lwide)}}factor loadings matrix estimated from "wide block"{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Bai, Jushan and Serena Ng. 2002. Determining the number of factors in approximate factor models. Econometrica 70(1): 191-221.

{phang}
Bai, Jushan. 2003. Inferential theory for factor models of large dimensions. {it:Econometrica} 71(1): 135-171.

{phang}
Bai, Jushan. 2009. Panel data models with interactive fixed effects. {it:Econometrica} 77(4): 1229-1279.

{phang}
Alessi, Lucia, Matteo Barigozzi and Marco Capasso. 2010. Improved penalization for determining the number of factors in approximate factor models. 
{it:Statistics & Probability Letters} 80(23-24): 1806-1813.

{phang}
Gobillon, Laurent, and Thierry Magnac. 2016. Regional policy evaluation: Interactive fixed effects and synthetic controls. 
{it:Review of Economics and Statistics} 98(3): 535–551.

{phang}
Xu, Yiqing. 2017. Generalized synthetic control method: Causal inference with interactive fixed effects models. {it:Political Analysis} 25(1): 57–76.

{phang}
Bai, Jushan, and Serena Ng. 2021. Matrix completion, counterfactuals, and factor analysis of missing data. {it:Journal of the American Statistical Association} 116(536): 1746-1763.

{phang}
Li, Xingyu, Yan Shen, and Qiankun Zhou. 2024. Confidence Intervals of Treatment Effects in Panel Data Models with Interactive Fixed Effects. {it:Journal of Econometrics} 240(1): 105684.

{phang}
Yan, Guanpeng, Li, Xingyu, Yan Shen, and Qiankun Zhou. 2024. 
xtteifeci: A command for estimation and inference of treatment effects through a factor-based approach. {it:Working Paper}.


{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University of Finance and Economics{break}
guanpengyan@yeah.net{break}

{pstd}
Xingyu Li, Peking University{break}
x.y@pku.edu.cn{break}

{pstd}
Yan Shen, Peking University{break}
yshen@phbs.pku.edu.cn{break}

{pstd}
Qiankun Zhou (corresponding author), Louisiana State University{break}
qzhou@lsu.edu{break}
