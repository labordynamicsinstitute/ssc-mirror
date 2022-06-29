{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:crhdreg} {hline 2} Executes estimation of high-dimensional regressions based on cluster-robust double/debiased machine learning.

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:crhdreg}
{it:depvar}
{it:indepvarlist1}
{it:indepvarlist2}
{ifin}
[{cmd:,} 
{bf:cluster1}({it:varname}) 
{bf:cluster2}({it:varname}) 
{bf:iv}({it:varname}) 
{bf:dimension}({it:real}) 
{bf:folds}({it:real}) 
{bf:resample}({it:real}) 
{bf:median}
{bf:alpha}({it:real}) 
{bf:tol}({it:real}) 
{bf:maxiter}({it:real})]

{marker description}{...}
{title:Description}

{phang}
{cmd:crhdreg} executes estimation of high-dimensional regression and high-dimensional IV regression with one-way or two-way cluster-robust standard errors based on
{browse "https://doi.org/10.1080/07350015.2021.1895815":Chiang, Kato, Ma and Sasaki (2022)}.
The high-dimensional regression estimation is executed by the (multiway) cluster-robust double/debiased machine learning with the high-dimensional nuisance parameters estimated via the elastic net (LASSO by default).

{marker options}{...}
{title:Options}

{phang}
{bf:cluster1({it:varname})} sets the variable to construct the first cluster dimension in one- or two-way clustering. 
Not calling this option leads to an execution of the high-dimensional regression or the high-dimensional IV regression without clustering.

{phang}
{bf:cluster2({it:varname})} sets the variable to construct the second cluster dimension in two-way clustering. 
If {bf:cluster1} is called but {bf:cluster2} is not called, then the command executes the high-dimensional regression or the high-dimensional IV regression with only one way of clustering based on the variable set with the {bf:cluster1} option.

{phang}
{bf:iv({it:varname})} sets the instrumental variable when the first variable in {it:indepvarlist1} is endogenous. 
Calling this option runs the high-dimensional IV regression, while not calling it leads to an execution of the high-dimensional regression.

{phang}
{bf:dimension({it:real})} sets the number of variables in {it:indepvarlist1}, the coefficients of which are to be displayed in the output table. 
The default value is {bf: dimension(1)}. 
It has to be a positive integer no larger than the total number of variables included in {it:indepvarlist1} and {it:indepvarlist2}.

{phang}
{bf:folds({it:real})} sets the number {bf:K} of folds for the cross fitting in the double/debiased machine learning. 
The default value is {bf: folds(5)} under no clustering or one-way clustering. 
The default value is {bf: folds(3)} under two-way clustering. It has to be a positive integer greater than 1.

{phang}
{bf:resample({it:real})} sets the number of resampling for a finite-sample adjustment of the double/debiased machine learning. 
The default value is {bf: resample(10)}. It has to be a positive integer.

{phang}
{bf:median} sets the indicator that the finite-sample adjustment uses the median of resampled estimates. 
Not calling this option leads to the use of the mean of reseampled estimates.

{phang}
{bf:alpha({it:real})} sets the penalty weight in the elastic net. 
The default value is {bf: alpha(1)}, and the elastic net is the LASSO (Least Absolute Shrinkage and Selection Operation). 
If this option is set to {bf: alpha(0)}, then the elastic net becomes the ridge regression.
It has to be a real number between 0 and 1.

{phang}
{bf:tol({it:real})} sets the tolerance as a stopping criterion in the numerical solution to the elastic net. 
The default value is {bf: tol(0.000001)}. It has to be strictly positive real number.

{phang}
{bf:maxiter({it:real})} sets the maximum number of iterations in the numerical solution to the elastic net. 
The default value is {bf: maxiter(1000)}. It has to be a natural number.

{marker usage}{...}
{title:Usage}

{phang}
Estimation of the partial effect of {bf:d} on {bf:y} controlling for 100 variables:
{p_end}

{phang}{cmd:. crhdreg y d x1 ... x100}{p_end}

{phang}
Cluster-robust standard error by the clustering variable {bf:g}:
{p_end}

{phang}{cmd:. crhdreg y d x1 ... x100, cluster1(g)}{p_end}

{phang}
Two-way cluster-robust standard error by the clustering variables {bf:g1, g2}:
{p_end}

{phang}{cmd:. crhdreg y d x1 ... x100, cluster1(g1) cluster2(g2)}{p_end}

{phang}
Instrumenting the endogenous variable {bf:d} by {bf:z}:
{p_end}

{phang}{cmd:. crhdreg y d x1 ... x100, iv(z)}{p_end}
{phang}{cmd:. crhdreg y d x1 ... x100, iv(z) cluster1(g)}{p_end}
{phang}{cmd:. crhdreg y d x1 ... x100, iv(z) cluster1(g1) cluster2(g2)}{p_end}

{phang}
Estimation of the partial effects of {bf:d1, d2, d3} on {bf:y} controlling for 100 variables:
{p_end}

{phang}{cmd:. crhdreg y d1 d2 d3 x1 ... x100, dimension(3)}{p_end}
{phang}{cmd:. crhdreg y d1 d2 d3 x1 ... x100, dimension(3) cluster1(g)}{p_end}
{phang}{cmd:. crhdreg y d1 d2 d3 x1 ... x100, dimension(3) cluster1(g1) cluster2(g2)}{p_end}

{phang}
Instrumenting the endogenous variable {bf:d1} by {bf:z}:
{p_end}

{phang}{cmd:. crhdreg y d1 d2 d3 x1 ... x100, dimension(3) iv(z)}{p_end}
{phang}{cmd:. crhdreg y d1 d2 d3 x1 ... x100, dimension(3) iv(z) cluster1(g)}{p_end}

{phang}
etc.
{p_end}

{marker example}{...}
{title:Examples}

{phang}
Estimation of the demand system in the differentiated product markets:
{p_end}

{phang}{cmd:. use "blp.dta"}{p_end}

{phang}
No clustering:
{p_end}

{phang}{cmd:. crhdreg share logprice hpwt* air*  mpd* space*, iv(sumotherhpwt)}{p_end}

{phang}
One-way clustering by market:
{p_end}

{phang}{cmd:. crhdreg share logprice hpwt* air*  mpd* space*, iv(sumotherhpwt) cluster1(market)}{p_end}

{phang}
One-way clustering by product model:
{p_end}

{phang}{cmd:. crhdreg share logprice hpwt* air*  mpd* space*, iv(sumotherhpwt) cluster1(model)}{p_end}

{phang}
Two-way clustering by market and product model:
{p_end}

{phang}{cmd:. crhdreg share logprice hpwt* air*  mpd* space*, iv(sumotherhpwt) cluster1(market) cluster2(model)}{p_end}

{marker stored}{...}
{title:Stored results}

{phang}
{bf:crhdreg} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(N)} {space 10}observations
{p_end}
{phang2}
{bf:e(ways)} {space 7}ways of clustering
{p_end}
{phang2}
{bf:e(G1)} {space 9}cluster size in the first cluster dimension
{p_end}
{phang2}
{bf:e(G2)} {space 9}cluster size in the second cluster dimension
{p_end}
{phang2}
{bf:e(dimD)} {space 7}number of {it:indepvarlist1}
{p_end}
{phang2}
{bf:e(dimX)} {space 7}number of {it:indepvarlist2}
{p_end}
{phang2}
{bf:e(K)} {space 10}number of folds for the cross fitting
{p_end}
{phang2}
{bf:e(alpha)} {space 6}penalty weight in the elastic net
{p_end}
{phang2}
{bf:e(fsa_n)} {space 6}number of resampling for a finite-sample adjustment
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(fsa_m)} {space 6}{bf:mean} or {bf:median} for a finite-sample adjustment
{p_end}
{phang2}
{bf:e(iv)} {space 9}instrumental variable
{p_end}
{phang2}
{bf:e(cluster1)} {space 3}clustering variable in the first cluter dimension
{p_end}
{phang2}
{bf:e(cluster2)} {space 3}clustering variable in the second cluter dimension
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:crhdreg}
{p_end}
{phang2}
{bf:e(properties)} {space 1}{bf:b V}
{p_end}

{phang}
Matrices
{p_end}
{phang2}
{bf:e(b)} {space 10}coefficient vector
{p_end}
{phang2}
{bf:e(V)} {space 10}variance-covariance matrix of the estimators
{p_end}

{phang}
Functions
{p_end}
{phang2}
{bf:e(sample)} {space 5}marks estimation sample
{p_end}

{title:Reference}

{p 4 8}Chiang, H.D., K. Kato, Y. Ma, and Y. Sasaki 2022. Multiway Cluster Robust Double/Debiased Machine Learning. {it:Journal of Business & Economic Statistics}, 40(3), pp. 1046-1056.
{browse "https://doi.org/10.1080/07350015.2021.1895815":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Harold D. Chiang, University of Wisconsin, Madison, WI.{p_end}
{p 4 8}Kengo Kato, Cornell University, Ithaca, NY.{p_end}
{p 4 8}Yukun Ma, Vanderbilt University, Nashville, TN.{p_end}
{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}
