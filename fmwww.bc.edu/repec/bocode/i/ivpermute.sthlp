{smcl}
{* *! version 1.0.0 15May2018}{...}
{cmd: help ivpermute}
{hline}

{title:Title}

{phang} {hi:ivpermute} {hline 2} Nearly collinear robust instrumental-variables regression {p_end}
 
{title:Syntax}

{phang} {cmd:ivpermute} {depvar} ({help varlist:endovars} = {help varlist:excludedinst}) [{help varlist:includedinst}] {ifin} {weight} [{cmd:,} {it:options}] {p_end}

{title:Options}

    {opt nocons:tant}                 suppress constant term
    {opt small}                      Stata's finite sample adjustment of standard errors and degrees of freedom adjustments of p-values
    {opt robust}                     robust conventional standard errors 
    {opth cluster(varname)}           clustered conventional standard errors
    {opth reps(#)}                    number of permutations of data and variable order; default is 10
    {opth seed(#)}                    set random-number seed to #, default is 1

{phang} 
If the user does not provide a random number {hi:seed}, the seed is set to 1 (to ensure replicability, provided the data and variable lists have not been reordered, on subsequent runs). 
Regardless, the seed is restored to its pre-program value on termination.
{p_end}

{title:Description}

{phang}
{cmd:ivpermute} fits a partitioned 2SLS regression of {depvar} on {help varlist:endovars} and {help varlist:includedinst} using 
{help varlist:excludedinst} (as well as {help varlist:includedinst}) as instruments for {help varlist:endovars}.  The partitioned regression is more robust to 
near collinearity among the instruments than the procedures used by Stata's command {cmd:ivregress}.  For details, see:
{p_end}

{pmore} Young, Alwyn. 
{it:Nearly Collinear Regressors and the Replicability and Robustness of 2SLS Results.}
{p_end}

{phang} {cmd:ivpermute} begins by calling Stata's {cmd:ivregress} command and reporting Stata's estimation results.  
Instruments that are flagged by Stata as perfectly collinear and dropped by {cmd:ivregress} are dropped from the subsequent partitioned regression as well.
{cmd:ivpermute} then calculates the coefficient and standard error estimates of the partitioned regression, the 
minimum to maximum range of these in {opth reps(#)} random permutations of the regression's data and variable order, and the maximum R2 found in regressing one instrument on the others.  

{phang} If the partitioned estimates and their minimum to maximum range all equal {cmd:ivregress}'s estimates, the user can be confident that these are not sensitive to data and variable order.  
If the partitioned regression estimates differ from {cmd:ivregress}, near collinearity may be affecting the accuracy of Stata's estimation using {cmd:ivregress}.  If the difference between the minimum and 
maximum range using the partitioned regression is not zero, the partitioned regression is not able to solve the sensitivity of results to data and variable order created by near collinearity 
and the user may want to reconsider the regression specification.  

{title:Stored results}

{phang} {cmd:ivpermute} stores the following matrices in {cmd:e()}: {p_end}

{cmd:e(Res)}    Results table in matrix form.
{cmd:e(ResB)}   Coefficient estimates for each random permutation of data and variable order.
{cmd:e(ResSE)}  Standard error estimates for each random permutation of data and variable order.
{cmd:e(R2max)}  Maximum R2 found in regressing one instrument on the others.

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}

