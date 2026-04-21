{smcl}
{* *! version 1.0.0 16 Mar 2026}{...}
{cmd:help ifete} 
{hline}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help ifete (if installed)" "help ifete"}{...}
{viewerjumpto "Syntax" "ifete##syntax"}{...}
{viewerjumpto "Description" "ifete##description"}{...}
{viewerjumpto "Required Settings" "ifete##required"}{...}
{viewerjumpto "Options" "ifete##options"}{...}
{viewerjumpto "Examples" "ifete##examples"}{...}
{viewerjumpto "Stored results" "ifete##results"}{...}
{viewerjumpto "Reference" "ifete##reference"}{...}
{viewerjumpto "Author" "ifete##author"}{...}

{title:Title}

{phang}
{bf:ifete} {hline 2} estimation and inference of treatment effects in panel data with interactive fixed effects

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:ifete} {depvar} [{indepvars}], 
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
{synopt:{opt rme:thod(criterion)}}method for estimating the number of factors{p_end}
{synopt:{opt rmin(#)}}minimum number of factors{p_end}
{synopt:{opt rmax(#)}}maximum number of factors{p_end}

{syntab:Reporting}
{synopt:{cmdab: cit:ype}({{bf:eq}|{bf:sy})}}type of reported confidence interval{p_end}
{synopt:{opt frame(framename)}}create a Stata frame storing generated variables.{p_end}
{synopt:{opt nofig:ure}}do not display figures{p_end}
{synopt:{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}])}save all produced graphs to the current path.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{helpb xtset} {it:panelvar} {it:timevar} must be used to declare a strongly panel dataset in the usual long form; see {manhelp xtset XT:xtset}.{p_end}
{p 4 6 2}{depvar} and {indepvars} must be numeric variables, and abbreviations are not allowed.{p_end}

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:ifete} is designed for estimation and inference of treatment effects in panel data models with interactive fixed effects. 
As a major extension of two-way fixed effects, interactive fixed effects provide a flexible way to construct counterfactual predictions for causal inference. 
The {cmd:ifete} command implements the tall-wide algorithm for efficient estimation of treatment effects (Bai and Ng, 2021, {it:Journal of the American Statistical Association}), 
while using residual-based wild bootstrap for valid inference (Li, Shen and Zhou, 2024, {it:Journal of Econometrics}). 
This command presents point estimates of treatment effects as well as confidence intervals and p-values for inference, while covariates and nonstationary trends are allowed. 
See Yan et al. (2026) for details. 

{marker required}{...}
{title:Required Settings}

{p 4 4 2}
The outcome variable {depvar} and treatment variable {it:treatvarname} must be specified. Covariates {indepvars} can be included to improve the efficiency of estimation. 
If {it:treatvarname} indicates staggered treatments (i.e., differential initial treatment timing for different units), 
{cmd:ifete} automatically identifies the number of pretreatment periods when all units are untreated as {it:T0} (the height of the wide block) and the number of control units as {it:N0} (the width of the tall block).

{phang}
{opt treatvar(treatvarname)} specifies a binary treatment variable indicating whether units are exposed to the treatment of interest in given periods. 
The treatment variable takes the value of 1 if the unit is treated in that period and 0 otherwise. 
The specification of the treatment variable allows {cmd:ifete} to distinguish between treated and control units, as well as pretreatment and posttreatment periods. 
This distinction is necessary for constructing the "wide block" and "tall block" matrices, which are fundamental components of the tall-wide algorithm for estimating treatment effects. 
The "wide block" matrix contains pretreatment observations for all units, while the "tall block" matrix contains observations for control units across all periods.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt r(#)} specifies the number of factors. {it:#} must be a positive integer that lies within the interval [1, min({it:T0} - 1, {it:N0} - 1)], 
where {it:T0} denotes the number of pretreatment periods when all units are untreated, and {it:N0} denotes the number of control units. 
If the option {opt r(#)} is not specified, {cmd:ifete} uses data-driven methods to estimate the number of factors through the options {opt rmethod(criterion)}, {opt rmin(#)} and {opt rmax(#)}.

{phang}
{opt iterate(#)} specifies the maximum number of iterations allowed in estimating the interactive fixed effects by the LSPC estimator (Bai, 2009) iterating between least squares (LS) and principal components (PC). 
The default is 1000.

{phang}
{opt tolerance(tol)} specifies the convergence tolerance threshold {it:tol} for estimating the interactive fixed effects by the LSPC estimator. 
Specifically, {cmd:ifete} calculates the L2 norm (Euclidean norm) of the difference between the coefficient estimates obtained in two successive iterations. 
The procedure stops if the L2 norm difference falls below the specified tolerance threshold {it:tol}. 
{it:tol} should be set to a small positive real number, which defaults to 0.0001.

{phang}
{cmdab:trend}({c -(}{bf:0}|{bf:1}{c )-}) specifies an indicator of nonstationary trends. 
{cmdab:trend}({bf:0}) indicates stationary data, while {cmdab:trend}({bf:1}) indicates nonstationary factors and/or covariates following the unit root process. 
The default is {cmdab:trend}({bf:0}).

{phang}
{opt bootstrap(#)} specifies the number of bootstrap samples used for constructing confidence intervals of treatment effects and the related {it:p}-values. 
{it:#} should be set to a positive large integer, which defaults to 500.

{phang}
{opth seed(int)} specifies the seed used by the random number generator for reproducible results, which defaults to 1.

{dlgtab:Optimization}

{p 4 4 2}
If the number of factors is not specified using the option {opt r(#)}, {cmd:ifete} provides the following methods to estimate the number of factors: 
leave-one-out cross validation ({bf:loo}) (Xu, 2017), 
twice {it:K}-fold cross validation ({bf:cv} or {bf:cv(}{it:K} {it:J}{bf:)}) (Wei and Chen, 2020), 
Bai and Ng's information criteria ({bf:pc1}, {bf:pc2}, {bf:pc3}, {bf:ic1}, {bf:ic2}, {bf:ic3}) (Bai and Ng, 2002), 
and Ahn and Horenstein's eigenvalue ratio ({bf:er}) and growth ratio ({bf:gr}) criteria (Ahn and Horenstein, 2013).

{phang}
{opt rmethod(criterion)} specifies the method used to determine the number of factors. 
{it:criterion} should be one of {bf:loo}, {bf:cv}, {bf:cv(}{it:K} {it:J}{bf:)}, {bf:pc1}, {bf:pc2}, {bf:pc3}, {bf:ic1}, {bf:ic2}, {bf:ic3}, {bf:er}, or {bf:gr}. 
The default is {bf:rmethod(loo)}.

{phang2}
{bf:loo} (default) specifies leave-one-out cross validation (Xu, 2017), which selects the number of factors by minimizing the mean squared prediction error.

{phang2}
{bf:cv} or {bf:cv(}{it:K} {it:J}{bf:)} specifies the twice {it:K}-fold cross validation (Wei and Chen, 2020) for selecting the number of factors. 
The tall block is split into {it:K} folds in the time dimension and {it:J} folds in the cross-sectional dimension. 
For each candidate number of factors, the method computes the summed squared prediction error over all held-out blocks and selects the value that minimizes this criterion. 
If {cmd:cv} is specified without arguments, the default is {it:K} = {it:T} and {it:J} = {it:N0}. 
{cmd:cv(}{it:K} {it:J}{cmd:)} may also be specified, where 1 <= {it:K} <= {it:T} and 1 <= {it:J} <= {it:N0}.

{phang2}
{bf:pc1}, {bf:pc2}, {bf:pc3}, {bf:ic1}, {bf:ic2} or {bf:ic3} specifies Bai and Ng's information criteria (Bai and Ng, 2002), 
which minimize the sum of squared residuals in addition to a penalty term that increases with the number of factors.

{phang2}
{bf:er} or {bf:gr} specifies Ahn and Horenstein's eigenvalue-based criteria (Ahn and Horenstein, 2013), 
which determine the number of factors by examining the ratio of adjacent eigenvalues, with {bf:er} relying on the eigenvalue ratio and {bf:gr} on the growth ratio.

{phang}
{opt rmin(#)} specifies the minimum number of factors considered by {opt rmethod(criterion)}, which defaults to 1. 
{it:#} must be a positive integer less than or equal to the maximum number of factors specified by {opt rmax(#)}.

{phang}
{opt rmax(#)} specifies the maximum number of factors considered by {opt rmethod(criterion)}, which defaults to 10. 
{it:#} must be a positive integer that lies within the interval [1, min({it:T0} - 1, {it:N0} - 1)], where {it:T0} denotes the number of pretreatment periods when all units are untreated, and {it:N0} denotes the number of control units. 
It is recommended to further increase {opt rmax(#)} if it turns out to be the same as the optimal number of factors chosen.

{dlgtab:Reporting}

{phang}
{cmdab: citype}({{bf:eq}|{bf:sy}}) specifies the type of reported confidence intervals of predicted outcomes and treatment effects. 
{cmdab: citype}({bf:eq}) corresponds to the equal tailed confidence interval, and {cmdab: citype}({bf:sy}) corresponds to the symmetric confidence interval. The default is {cmdab: citype}({bf:eq}).

{phang}
{opt frame(framename)} creates a Stata frame storing generated variables including counterfactual predictions, treatment effects, 90%, 95%, 99% confidence intervals of predicted outcomes and treatment effects, 
and {it:p}-values of treatment effects. The frame named {it:framename} is replaced if it already exists, or created if not.

{phang}
{opt nofigure} do not display figures. The default is to display all figures for estimation results.

{phang}
{cmdab:saveg:raph}({it:prefix}, [{cmdab:asis} {cmdab:replace}]) automatically and iteratively calls the {helpb graph save} to save all produced graphs to the current path, 
where {it: prefix} specifies the prefix added to {it: _graphname} to form a file name, 
that is, the graph named {it: graphname} is stored as {it: prefix_graphname}.gph. 
{cmdab:asis} and {cmdab:replace} are options passed to {helpb graph save}; for details, see {manhelp graph G-2: graph save}.
Note that this option only applies when {opt nofigure} is not specified. 

{marker examples}{...}
{title:Example 1: estimating the impact of economic integration between Hong Kong and mainland China in 2004q1 (Hsiao et al., 2012)}

{phang2}{cmd:. use growth2, clear}{p_end}
{phang2}{cmd:. xtset region time}{p_end}

{phang2}* Visualize the configuration of the treatment variable "ei" for economic integration in panel data ({bf:panelview} has been installed from SSC){p_end}
{phang2}{cmd:. panelview gdp ei, i(region) t(time) type(treat)}{p_end}

{phang2}* Implement factor-based estimation and create a Stata frame "growth_ei" storing generated variables including treatment effects and confidence intervals{p_end}
{phang2}{cmd:. ifete gdp, treatvar(ei) frame(growth_ei)}{p_end}

{phang2}* Change to the generated Stata frame "growth_ei" containing the results{p_end}
{phang2}{cmd:. frame change growth_ei}{p_end}
{phang2}{cmd:. describe, simple}{p_end}

{phang2}* Change back to the default Stata frame{p_end}
{phang2}{cmd:. frame change default}{p_end}

{title:Example 2: estimating the effect of California's tobacco control program (Abadie, Diamond, and Hainmueller 2010)}

{phang2}{cmd:. use smoking2, clear}{p_end}
{phang2}{cmd:. xtset state year}{p_end}

{phang2}* Visualize the treatment structure for California's tobacco control program{p_end}
{phang2}{cmd:. panelview cigsale ctcp, i(state) t(year) type(treat)}{p_end}

{phang2}* Implement factor-based estimation for a model with covariates and a nonstationary trend using eigenvalue ratio criterion ({bf:er}){p_end}
{phang2}{cmd:. ifete cigsale lnincome eduattain poverty, treatvar(ctcp) trend(1) rmethod(er)}{p_end}

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
{synopt:{cmd:e(mse)}}mean squared error of the fitted model {p_end}
{synopt:{cmd:e(rmse)}}root mean squared error of the fitted model {p_end}
{synopt:{cmd:e(r2)}}{it:R}-squared of the fitted model {p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(panelvar)}}name of panel variable{p_end}
{synopt:{cmd:e(timevar)}}name of time variable{p_end}
{synopt:{cmd:e(varlist)}}names of dependent variable and independent variables{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(trend)}}indicator for the presence of nonstationary trends{p_end}
{synopt:{cmd:e(cmd)}}{bf:ifete}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(seed)}}seed used by the random number generator for reproducible results{p_end}
{synopt:{cmd:e(frame)}}name of Stata frame storing generated variables{p_end}
{synopt:{cmd:e(graph)}}names of all produced graphs{p_end}
{synopt:{cmd:e(properties)}}{bf:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector of the model fitted{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the coefficient estimates{p_end}
{synopt:{cmd:e(Ftall)}}common factors matrix estimated from the tall block{p_end}
{synopt:{cmd:e(Ltall)}}factor loadings matrix estimated from the tall block{p_end}
{synopt:{cmd:e(Fwide)}}common factors matrix estimated from the wide block{p_end}
{synopt:{cmd:e(Lwide)}}factor loadings matrix estimated from the wide block{p_end}

{marker reference}{...}
{title:Reference}

{phang}
Bai, Jushan and Serena Ng. 2002. Determining the number of factors in approximate factor models. {it:Econometrica} 70(1): 191-221.

{phang}
Bai, Jushan. 2009. Panel data models with interactive fixed effects. {it:Econometrica} 77(4): 1229-1279.

{phang}
Ahn, Seung C. and Alex R. Horenstein. 2013. Eigenvalue ratio test for the number of factors. 
{it:Econometrica} 81(3): 1203-1227.

{phang}
Xu, Yiqing. 2017. Generalized synthetic control method: Causal inference with interactive fixed effects models. {it:Political Analysis} 25(1): 57–76.

{phang}
Wei, Jie, and Hui Chen. 2020. Determining the Number of Factors in Approximate Factor Models by Twice K-fold Cross Validation. {it:Economics Letters} 191: 109149.

{phang}
Bai, Jushan, and Serena Ng. 2021. Matrix completion, counterfactuals, and factor analysis of missing data. {it:Journal of the American Statistical Association} 116(536): 1746-1763.

{phang}
Li, Xingyu, Yan Shen, and Qiankun Zhou. 2024. Confidence Intervals of Treatment Effects in Panel Data Models with Interactive Fixed Effects. {it:Journal of Econometrics} 240(1): 105684.

{phang}
Yan, Guanpeng, Qiang Chen, Xingyu Li, Yan Shen and Qiankun Zhou. 2026. 
ifete: Estimation and inference of treatment effects via interactive fixed effects. {it:Working Paper}.

{marker author}{...}
{title:Author}

{pstd}
Guanpeng Yan, Shandong University of Finance and Economics{break}
guanpengyan@yeah.net{break}

{pstd}
Qiang Chen (corresponding author), Shandong University{break}
qiang2chen2@126.com{break}

{pstd}
Xingyu Li, Zhejiang University{break}
lixyecon@zju.edu.cn{break}

{pstd}
Yan Shen, Peking University{break}
yshen@phbs.pku.edu.cn{break}

{pstd}
Qiankun Zhou, Louisiana State University{break}
qzhou@lsu.edu{break}
