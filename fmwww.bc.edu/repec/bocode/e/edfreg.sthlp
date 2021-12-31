{smcl}
{* *! version 1.0.0 15December2015}{...}
{cmd: help edfreg}
{hline}

{title:Title}

{phang} {hi:edfreg} {hline 2} Corrections for statistical inference with robust and clustered covariance matrices. {p_end}
 
{title:Syntax}

{phang} {cmd:edfreg} {depvar} {indepvars} {ifin} {weight} [{cmd:,} {it:options}] {p_end}

{title:Options}

    {opt robust}              Robust estimate of covariance. 
    {opth cluster(varname)}    Clustered estimate of covariance. 
    {opth select(varlist)}     Calculates corrections only for the specified subset of regressors, reducing execution time.
    {opth absorb(varname)}     Fixed effects for the categories defined by varname (must be subsets of {opt cluster} if used with that option).
    {opt nocons:tant}          Suppress constant term.

Either {opt robust} or {opt cluster} must be specified. Supports aweights and pweights.

{title:Description}

{phang} {cmd:edfreg} computes bias adjusted standard errors and effective degrees of freedom corrections for robust and clustered covariance matrices.  
Depending upon the interaction between the hypothesis test and regression leverage these covariance estimates may place weight on a subset of residuals.
{cmd:edfreg} calculates the bias and variance of the covariance estimate in the case of iid normal errors and uses these to adjust the standard error and degrees of freedom for each estimated coefficient.
This has been found to improve the accuracy of statistical inference in cases with normal iid and non-normal non-iid errors.  See:{p_end}

{pmore} Young, Alwyn. 
{browse "http://personal.lse.ac.uk/YoungA/Improved.pdf": {it:Improved, Nearly Exact, Statistical Inference with Robust and Clustered Covariance Matrices using Effective Degrees of Freedom Corrections.}}
{p_end}

{phang} {cmd:edfreg} first reports the robust or clustered regression and then calculates and reports corrections. {p_end}

{title:Stored results}

{phang} {cmd:edfreg} stores the following in {cmd:e()}: {p_end}

{pmore} {title:Matrices}

{pmore} {cmd:e(edf)}   coefficient, bias adjusted standard error, effective degrees of freedom, t-stat, p-value, 95% confidence interval. {p_end}

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}

