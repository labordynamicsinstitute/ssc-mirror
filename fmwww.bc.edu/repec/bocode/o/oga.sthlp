{smcl}
{* *! version 1.1.1}{...}
{title:Title}

{phang}
{bf:oga} {hline 2} Executes estimation and inference for high-dimensional regressions without imposing the sparsity restriction.

{marker syntax}{...}
{title:Syntax}

{p 4 17 2}
{cmd:oga}
{it:depvar}
{it:indepvarlist1}
{it:indepvarlist2}
{ifin}
[{cmd:,} 
{bf:dimension}({it:integer}) 
{bf:folds}({it:integer}) 
{bf:repdml}({it:integer}) 
{bf:cstar}({it:real})
{bf:cluster}({it:varname}) ]

{marker description}{...}
{title:Description}

{phang}
{cmd:oga} performs estimation and inference for high-dimensional regression models without imposing a sparsity assumption, based on the methodology of 
{browse "https://doi.org/10.1162/rest_a_01349":Cha, Chiang, and Sasaki}. 
The estimation procedure combines the orthogonal greedy algorithm (OGA), the high-dimensional Akaike information criterion (HDAIC), and double/debiased machine learning (DML).

{marker options}{...}
{title:Options}

{phang}
{bf:dimension({it:integer})} specifies the number of variables for {it:indepvarlist1} whose coefficients are to be displayed in the output table.
The default is {bf:dimension(1)}.
The value must be a positive integer no greater than the total number of variables in {it:indepvarlist1} and {it:indepvarlist2}.

{phang}
{bf:folds({it:integer})} sets the number {bf:K} of folds used for cross-fitting in the double/debiased machine learning (DML) procedure.
The default is {bf:folds(5)}.
The value must be an integer greater than 1.

{phang}
{bf:repdml({it:integer})} sets the number of resampling repetitions used for finite-sample adjustment in the double/debiased machine learning (DML) procedure.
The default is {bf:repdml(5)}.
The value must be a positive integer.

{phang}
{bf:cstar({it:real})} specifies the tuning parameter {bf:C*} for the high-dimensional Akaike information criterion (HDAIC).
The default is {bf:cstar(2)}.

{phang}
{bf:cluster({it:varname})} specifies the variable used to define clusters.
If this option is not specified, the command is executed without clustering.

{marker usage}{...}
{title:Usage Examples}

{phang}
Estimation of the partial effect of {bf:d} on {bf:y} controlling for 100 variables:
{p_end}

{phang}{cmd:. oga y d x1 ... x100}{p_end}

{phang}
Cluster-robust standard error by the clustering variable {bf:state}:
{p_end}

{phang}{cmd:. oga y d x1 ... x100, cluster1(state)}{p_end}

{phang}
Estimation of the partial effects of {bf:d1, d2, d3} on {bf:y} controlling for 100 variables:
{p_end}

{phang}{cmd:. oga y d1 d2 d3 x1 ... x100, dimension(3)}{p_end}

{phang}
etc.
{p_end}

{marker stored}{...}
{title:Stored results}

{phang}
{bf:oga} stores the following in {bf:e()}: 
{p_end}

{phang}
Scalars
{p_end}
{phang2}
{bf:e(N)} {space 10}observations
{p_end}
{phang2}
{bf:e(dimension)} {space 2}number of {it:indepvarlist1}
{p_end}
{phang2}
{bf:e(folds)} {space 6}number of folds for the cross fitting
{p_end}
{phang2}
{bf:e(repdml)} {space 5}number of resampling for DML
{p_end}
{phang2}
{bf:e(cstar)} {space 6}tuning parameter {bf: C*}
{p_end}

{phang}
Macros
{p_end}
{phang2}
{bf:e(cluster)} {space 4}clustering variable
{p_end}
{phang2}
{bf:e(cmd)} {space 8}{bf:oga}
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

{p 4 8}Cha, Jooyoung, Harold D. Chiang, and Yuya Sasaki. Inference in High-Dimensional Regression Models without the Exact or Lp Sparsity. {it:Review of Economics and Statistics}.
{browse "https://doi.org/10.1162/rest_a_01349":Link to Paper}.
{p_end}

{title:Authors}

{p 4 8}Jooyoung Cha, Vanderbilt University, Nashville, TN.{p_end}
{p 4 8}Harold D. Chiang, University of Wisconsin, Madison, WI.{p_end}
{p 4 8}Yuya Sasaki, Vanderbilt University, Nashville, TN.{p_end}
