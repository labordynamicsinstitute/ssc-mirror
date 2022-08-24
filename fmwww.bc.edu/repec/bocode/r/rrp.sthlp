{smcl}
{* *! version 1.0.0 08aug2022}{...}

{cmd:help rrp}
{hline}

{title:Title}

{p 8 20 2}
{hi:rrp} {hline 2} Rescaled Regression Prediction (RRP) using two samples{p_end}


{title:Syntax}

{p 8 17 2}
{cmd:rrp}
{indepvars}
{ifin}
{weight}{cmd:,}
{cmdab:impute(}{newvar}{cmd:)} 
{cmdab:proxies(}{varlist}{cmd:)} 
{cmdab:first(}{it:{help estimates_store:model}}{cmd:)} 
{cmdab:partialrsq()}
{cmdab:r:obust} 
{cmdab:cl:uster(}clustvar{cmd:)} 
 

{title:Description}

{pstd}{cmd:rrp} implements a Rescaled Regression Prediction (RRP) using two samples in two steps. 
First it creates a new variable, by imputing the dependent variable in the current sample, 
using the stored first-stage regression, fitted in the sample that contains the dependent variable 
and the proxies. The samples can be in different datasets or can be appended, indexed by a sample identifier.
The command requires the proxy variables in the two samples (first-stage regression and in {hi:proxies()}) 
to have the same name (order does not matter). The user needs to correctly input the partial R-squared (see example).
The command returns the results of the second-stage regression and creates the new imputed variable.


{title:Options}

{phang}
{cmdab:impute(}{newvar}{cmd:)} is used to select the name of the new imputed variable
{p_end}

{phang}
{cmdab:proxies(}{varlist}{cmd:)} specifies the variables, common at both datasets, used as proxies for imputing the dependent variable.
{p_end}

{phang}
{cmdab:first(}{it:{help estimates_store:model}}{cmd:)} specifies the first-stage regression in the dataset that contains the dependent variable.
{p_end}

{phang}
{cmdab:partialrsq(}{cmd:)} contains the partial R-squared. It can be a value or a stored scalar. 
{p_end}

{phang}
{cmdab:r:obust} is used to calculate standard errors that are robust to the presence of arbitrary heteroskedasticity.
{p_end}

{phang}
{cmdab:cl:uster(}clustvar{cmd:)} is used to calculate standard errors that are robust to both arbitrary heteroskedasticity and allow intra-group correlation.
{p_end}



{title:Example}

Design
{phang2}{cmd:. drop _all}{p_end}
{phang2}{cmd:. matrix C = (2, .5 \ .5, 2)}{p_end}
{phang2}{cmd:. mat A = cholesky(C)}{p_end}

{phang2}{cmd:. set obs 100}{p_end}
{phang2}{cmd:. gen sample = 1}{p_end}
{phang2}{cmd:. gen c1= invnorm(uniform())}{p_end}
{phang2}{cmd:. gen c2= invnorm(uniform())}{p_end}
{phang2}{cmd:. mat a1 = A[1,1...]}{p_end}
{phang2}{cmd:. matrix score x = a1 }{p_end}
{phang2}{cmd:. matrix a2 = A[2,1...]}{p_end}
{phang2}{cmd:. matrix score w = a2 }{p_end}
{phang2}{cmd:. gen y  = 1 +   1*x + .5*w + rnormal(0,4)}{p_end}
{phang2}{cmd:. gen zA = 1 + 0.5*y - .0*w + rnormal(0,2)}{p_end}
{phang2}{cmd:. gen zB = 1 + 0.3*y - .0*w + rnormal(0,2)}{p_end}

{phang2}{cmd:. set obs 300}{p_end}
{phang2}{cmd:. replace sample = 2 in 101/300}{p_end}
{phang2}{cmd:. replace c1= invnorm(uniform()) in 101/300}{p_end}
{phang2}{cmd:. replace c2= invnorm(uniform()) in 101/300}{p_end}
{phang2}{cmd:. mat a1 = A[1,1...]}{p_end}
{phang2}{cmd:. matrix score x = a1 in 101/300, replace }{p_end}
{phang2}{cmd:. matrix a2 = A[2,1...]}{p_end}
{phang2}{cmd:. matrix score w = a2 in 101/300, replace  }{p_end}
{phang2}{cmd:. replace y  = 1 +   1*x + .5*w + rnormal(0,4) in 101/300}{p_end}
{phang2}{cmd:. replace zA = 1 + 0.5*y - .0*w + rnormal(0,2) in 101/300}{p_end}
{phang2}{cmd:. replace zB = 1 + 0.3*y - .0*w + rnormal(0,2) in 101/300}{p_end}

{phang2}{cmd:. drop c1 c2 }{p_end}
{phang2}{cmd:. replace x=. if sample==1}{p_end}
{phang2}{cmd:. replace y=. if sample==2}{p_end}

First-stage regression and partial R-squared calculation
{phang2}{cmd:. reg  y w if sample==1}{p_end}
{phang2}{cmd:. scalar R2_A = e(r2)}{p_end}
{phang2}{cmd:. reg y zA zB w if sample==1}{p_end}
{phang2}{cmd:. est store stage1}{p_end}
{phang2}{cmd:. scalar R2_B = e(r2)}{p_end}
{phang2}{cmd:. scalar Rsq = (R2_B-R2_A)/(1-R2_A)}{p_end}

Imputation and second-stage estimation
{phang2}{cmd:. rrp x w   if sample==2, impute(yhat) proxies(zA zB) partialrsq(Rsq) first(stage1)}{p_end} 



{title:Saved results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(N_clust)}}number of clusters{p_end}
{synopt:{cmd:e(df_m)}}model degrees of freedom{p_end}
{synopt:{cmd:e(df_r)}}residual degrees of freedom{p_end}
{synopt:{cmd:e(F)}}F statistic{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(rmse)}}root mean squared error{p_end}
{synopt:{cmd:e(rank)}}rank of e(V){p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:rrp}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of imputed dependent variable{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(clustvar)}}name of cluster variable{p_end}
{synopt:{cmd:e(vcetype)}}title used to label Std. Err.{p_end}
{synopt:{cmd:e(vce)}}vcetype specified{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}



{title:Reference}
{phang}
Crossley, T.F., Levell, P., and Poupakis, S. (2022). Regression with an Imputed Dependent Variable, {it:Journal of Applied Econometrics} https://doi.org/10.1002/jae.2921.
{p_end}

{title:Author}

{pstd}Stavros Poupakis{p_end}
{pstd}University College London{p_end}
{pstd}s.poupakis@ucl.ac.uk{p_end}
