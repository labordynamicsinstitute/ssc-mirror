{smcl}
{* *! version 1.0 09sep2013}{...}

{cmd:help kpredict}
{hline}

{title:Title}

{p 4 8 2} {hi:kpredict} {hline 2} Obtain fitted values, standard errors, etc. after {help krls} estimation{p_end}
   
{title:Syntax}

{p 4 8 2}
{cmdab:kpredict} {it:{help varname:newvar}}
[{cmd:,}
{it:options}]
{p_end}


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}

{syntab:Main}
{synopt:{opt fitted}}calculate predicted values (default functionality) {p_end}
{synopt:{opt se}}calculate standard errors of predicted values{p_end}
{synopt:{opt residuals}}calculate residuals{p_end}
{synoptline}

{title:Description}

{pstd}
{opt kpredict} is a post-estimation command used after running Kernel-based Regularized Least Squares ({help krls}), a machine learning method to fit multidimensional functions y = f(x)  for regression and classification problems without relying on linearity or additivity assumptions. KRLS finds the best fitting function by minimizing the squared loss of a Tikhonov regularization problem, 
using Gaussian kernels as radial basis functions. For further details see Hainmueller and Hazlett (2013). {p_end}


{title:Options}

{dlgtab:Main}

{phang}
{opt fitted} creates newvar containing predicted values for the dependent variable.

{phang}
{opt se} creates newvar containing standard errors of predicted values. 

{phang}
{opt residuals} creates newvar containing residuals. 


{title:Examples}

    Load example data
	{stata "use growthdata.dta":. use growthdata.dta}

    Basic syntax
	{stata " krls growth yearsschool assassinations":. krls growth yearsschool assassinations}
	{stata " kpredict myname_fitted":. kpredict myname_fitted}
	{stata " kpredict myname_se, se":. kpredict myname_se, se}
	{stata " kpredict myname_r, residuals":. kpredict myname_r, residuals}

