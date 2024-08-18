{smcl}
{* *! version 2.0.0 22 Mar 2024}{...}
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
{synopt:{opt tol:erance(tol)}}tolerance criterion for convergence{p_end}
{synopt:{cmdab: trend}({{bf:0}|{bf:1})}}indicator of nonstationary trend{p_end}
{synopt:{opt boots:trap(#)}}number of bootstrap samples{p_end}
{synopt:{opth seed(int)}}seed used by the random number generator{p_end}

{syntab:Optimization}
{synopt:{opt rme:thod}({{bf:bn}|{bf:abc}})}method for calculating the number of factors{p_end}
{synopt:{opt rmax(#)}}maximum number of factors{p_end}

{syntab:Reporting}
{synopt:{cmdab: cit:ype}({{bf:eq}|{bf:sy})}}type of reported confidence interval{p_end}
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
To implement the factor-based approach, the outcome variable {depvar} and treatment variable {it:treatvarname} must be specified. 
Including covariates {indepvars} can improve the prediction of counterfactual outcomes and the estimation of treatment effects. 
If {it:treatvarname} indicates staggered treatments (i.e., multiple units receiving treatment at different time periods), 
{cmd:xtteifeci} automatically identifies the number of periods without treatment across all units as the height of "wide block" and the number of control units as the width of "tall block".

{phang} 
{opt treatvar(treatvarname)} specifies a binary treatment variable, denoted as {it: treatvarname}, 
which indicates whether units (e.g., individuals, firms, or countries) are exposed to the treatment of interest in given time periods. 
The treatment variable takes the value of 1 if the unit is treated in that period and 0 otherwise. 
The specification of the treatment variable allows {cmd:xtteifeci} to distinguish between treated and control units, as well as pretreatment and posttreatment periods. 
This distinction is necessary for constructing the "wide block" and "tall block" matrices, 
which are fundamental components of the factor-based approach to estimating treatment effects. 
The "wide block" matrix contains the pretreatment observations for all units, 
while the "tall block" matrix contains the observations for the control units across all time periods.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt r(#)} specifies the number of factors used in the factor-based estimation of treatment effects. 
{it:#} must be a positive integer that lies within the interval [1, min({it:T_0}, {it:G_0})], where {it:T_0} denotes the number of pretreatment periods across all units, and {it:G_0} denotes the number of control units. 
This setting is crucial as it significantly influences the estimation results.
Choosing an insufficient number of factors can lead to omitted variable bias because the model fails to capture important sources of unobserved heterogeneity and cross-sectional dependence. 
On the other hand, including too many factors can lead to overfitting, reduced efficiency, and potential instability in the estimates. 
When prior knowledge or theoretical justifications are available, explicitly specifying the number of factors using the option {opt r(#)} can be advantageous. 
If the option {it:#} is not specified, {cmd:xtteifeci} uses data-driven methods to automatically determine the optimal number of factors through the options {opt rmethod}({{bf:bn}|{bf:abc}}) and {opt rmax(#)}.

{phang} 
{opt iterate(#)} specifies the maximum number of iterations allowed in the interactive fixed effects estimation (IFEE) procedure, 
which strikes a balance between computational efficiency and the convergence of the estimator. 
In some cases, the iterative algorithm may oscillate or exhibit slow convergence, leading to an excessive number of iterations without reaching the desired level of precision. 
The option {opt iterate(#)} serves as a safeguard against infinite loops that may occur when the IFEE procedure fails to converge, ensuring that the estimation process terminates within a acceptable time. 
{it:#} should be set to a large positive integer, which defaults to 1000.

{phang} 
{opt tolerance(tol)} specifies the convergence tolerance threshold {it:tol} for the interactive fixed effects estimation (IFEE) procedure. 
Specifically, {cmd:xtteifeci} calculates the L2 norm (Euclidean norm) of the difference between the coefficient estimates obtained in two successive iterations.
 If L2 norm difference falls below the specified tolerance threshold {it:tol}, the IFEE procedure is considered to have converged, and the estimation process terminates. 
 {it:tol} should be set to a small positive real number, which defaults to 0.0001.

{phang}
{cmdab: trend}({{bf:0}|{bf:1}}) specifies an indicator of whether a nonstationary trend is present in the data generating process of the panel data model. 
If {cmdab: trend}({bf:0}) is specified, "{bf:0}" indicates that the data exhibits stationarity, 
and {cmd:xtteifeci} employs asymptotic principal component analysis (APCA) or interactive fixed effects estimation (IFEE) to estimate the factors, factor loadings, and coefficients (if any). 
If {cmdab: trend}({bf:1}) is specified, "{bf:1}" indicates that the data exhibits nonstationarity, 
and {cmd:xtteifeci} employs a modified APCA or continuously-updated (Cup) estimation, which can be viewed as a generalization of APCA or IFEE, respectively. 
The time series properties of the variables should be examined using tests such as unit root tests or cointegration tests to determine the appropriate specification of the trend option. 
If neither {cmdab: trend}({bf:0}) nor {cmdab: trend}({bf:1}) is specified, the default is {cmdab: trend}({bf:0}).

{phang}
{opt bootstrap(#)} specifies the number of bootstrap samples for constructing confidence intervals and {it: p}-values of the estimated treatment effects.  
{cmd:xtteifeci} employs a residual-based resampling scheme to generate {it:#} bootstrap samples, which involves obtaining the residuals by subtracting the estimated outcomes from the observed outcomes, 
resampling residuals with replacement to create bootstrap samples, and yielding a distribution of bootstrap estimates of the counterfactual outcomes and the treatment effects. 
{it:#} should be set to a positive large integer, which defaults to 500.

{phang}
{opth seed(int)} specifies the seed used by the random number generator for reproducible results, which defaults to 1. 

{dlgtab:Optimization}

{p 4 4 2}
If the number of factors is not specified using the option {opt r(#)}, {cmd:xtteifeci} employs data-driven information criteria to determine the optimal number of factors for the model. 
Two information criteria are available in {cmd:xtteifeci}: the Bai and Ng (BN) information criterion, proposed by Bai and Ng (2002), and the Alessi, Barigozzi, and Capasso (ABC) information criterion, proposed by Alessi et al. (2010).
These criteria are invoked using the option {opt rmethod}({{bf:bn}|{bf:abc}}), with {opt rmethod}({bf:bn}) corresponding to the BN criterion and {opt rmethod}({bf:abc}) corresponding to the ABC criterion.

{phang}
{opt rmethod}({{bf:bn}|{bf:abc}}) specifies the data-driven information criteria used to determine the optimal number of factors in the factor-based approach to causal inference. 
The BN information criterion, specified by {cmdab: rmethod}({bf:bn}), minimizes the sum of squared residuals while incorporating a penalty term that increases with the number of factors. 
{cmd:xtteifeci} selects the optimal number of factors by minimizing PC_1 over a range of potential factor numbers using the BN criterion. 
The ABC information criterion, specified by {cmdab: rmethod}({bf:abc}), extends the BN criterion by introducing a tuning parameter that controls the severity of the penalty term. 
This extension is designed to be more robust to the presence of cross-sectional and temporal dependence in panel data models. 
If neither {cmdab: rmethod}({bf:bn}) nor {cmdab: rmethod}({bf:abc})  is specified, the default is set to {cmdab: rmethod}({bf:bn}).

{phang}
{opt rmax(#)} specifies the maximum number of factors considered in ABC and BN information criteria, which defaults to 8. 
{it:#} must be a positive integer that lies within the interval [1, min({it:T_0}, {it:G_0})], 
where {it:T_0} denotes the number of pretreatment periods across all units, 
and {it:G_0} denotes the number of control units.

{dlgtab:Reporting}

{phang}
{cmdab: citype}({{bf:eq}|{bf:sy}}) specifies the type of reported confidence interval of predicted outcomes and treatment effects. 
{cmdab: citype}({bf:eq}) corresponds to the equal tailed confidence interval, and {cmdab: citype}({bf:sy}) corresponds to the symmetric confidence interval. 
If neither {cmdab: citype}({bf:eq}) nor {cmdab: citype}({bf:sy}) is specified, the default is set to {cmdab: citype}({bf:eq}).

{phang}
{cmdab: citype}({{bf:eq}|{bf:sy}}) specifies the type of confidence interval reported for the predicted outcomes and estimated treatment effects. 
Two types of confidence intervals are available: equal-tailed and symmetric confidence intervals. 
The equal-tailed confidence interval, specified by {cmdab: citype}({bf:eq}), 
is constructed such that the probability of the true treatment effect lying below the lower bound of the interval is equal to the probability of it lying above the upper bound. 
The symmetric confidence interval, specified by {cmdab: citype}({bf:sy}), 
is constructed by adding and subtracting a fixed margin of error from the estimate of the treatment effect. 
The equal-tailed confidence interval is generally recommended when the sample size is small (i.e., the number of pretreatment periods {it:T_0} <= 50 and the number of control units {it: G_0} <= 50), 
as it provides a more robust and conservative approach to interval estimation. 
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
{phang2}{cmd:. panelview cigsale ctcp, i(state) t(year) type(treat)}{p_end}

{phang2}* Implement factor-based estimation for the model with covariates, a nonstationary trend and the number of factors calculated by ABC information criterion{p_end}
{phang2}{cmd:. xtteifeci cigsale lnincome eduattain poverty, treatvar(ctcp) rmethod(abc) trend(1)}{p_end}

{phang2}* List the names and values of the macros, scalars and matrix stored in e(){p_end}
{phang2}{cmd:. ereturn list}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:rcm} stores the following in e():

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations used in coefficient estimation{p_end}
{synopt:{cmd:e(df_r)}}degrees of freedom for {it:t}-statistics of coefficient estimates{p_end}
{synopt:{cmd:e(r)}}number of factors{p_end}
{synopt:{cmd:e(T)}}total number of periods{p_end}
{synopt:{cmd:e(T0)}}number of pretreatment periods without treatment across all units{p_end}
{synopt:{cmd:e(T1)}}number of posttreatment periods with at least one treated unit{p_end}
{synopt:{cmd:e(G)}}total number of units{p_end}
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
{synopt:{cmd:e(trend)}}indicator for the presence of a nonstationary trend{p_end}
{synopt:{cmd:e(cmd)}}{bf:xtteifeci}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(seed)}}seed used by the random number generator for reproducible results{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing generated variables{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}
{synopt:{cmd:e(properties)}}{bf:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the model fitted{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the coefficient estimates{p_end}
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
Abadie, A., A. Diamond, and J. Hainmueller. 2010. Synthetic Control Methods for Comparative Case Studies: Estimating the Effect of California's Tobacco Control Program.
{it: Journal of the American Statistical Association} 105(490): 493-505.

{phang}
Hsiao, Cheng, H. Steve Ching, and Shui Ki Wan. 2012. A Panel Data Approach for Program Evaluation: Measuring the Benefits of Political and Economic Integration of Hong Kong with Mainland China. 
{it:Journal of Applied Econometrics} 27(5): 705-740.

{phang}
Gobillon, Laurent, and Thierry Magnac. 2016. Regional policy evaluation: Interactive fixed effects and synthetic controls. 
{it:Review of Economics and Statistics} 98(3): 535–551.

{phang}
Hsiao, Cheng, and Qiankun Zhou. 2019. Panel Parametric, Semiparametric, and Nonparametric Construction of Counterfactuals. 
{it:Journal of Applied Econometrics} 34(4): 463-481.

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
