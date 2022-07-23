{smcl}
{* *! version 1.0.0 19July2022}{...}
{cmd: help pariv}
{hline}

{title:Title}

{phang} {hi:pariv} {hline 2} Nearly collinear robust instrumental-variables regression {p_end}
 
{title:Syntax}

{phang} {cmd:pariv} {depvar} ({help varlist:endovars} = {help varlist:excludedinst}) [{help varlist:includedinst}] {ifin} {weight} [{cmd:,} {it:options}] {p_end}

{title:Options}

    {opt nocons:tant}                 suppress constant term
    {opth absorb(varname)}            fixed effects for {help varlist:varname}
    {opt small}                      Stata's finite sample adjustment of standard errors and degrees of freedom adjustments of p-values
    {opt robust}                     heteroskedasticity robust conventional standard errors 
    {opth cluster(varname)}           clustered conventional standard errors
    {opth reps(#)}                    number of permutations of data and variable order; default is 0
    {opth seed(#)}                    set random-number seed to #, default is 1

{phang} 
{p_end}

{title:Description}

{phang}
{cmd:pariv} fits a partitioned 2SLS regression of {depvar} on {help varlist:endovars}, {help varlist:includedinst} and (if specified) fixed effects for 
{help varlist:varname} using {help varlist:excludedinst} (as well as {help varlist:includedinst} and any fixed effects) as instruments for {help varlist:endovars}.  
The partitioned regression is more robust to near collinearity among the instruments than the procedures used by Stata commands such as {cmd:ivregress}.  For details, see:
{p_end}

{pmore} Young, Alwyn. 
{it:Nearly Collinear Robust Procedures for 2SLS Estimation.}
{p_end}

{phang} {cmd:pariv} reports the maximum R2 found in regressing any one instrument on the others.  In other Stata 2SLS commands, maximum R2 Values in excess of .99999 
may generate substantive sensitivity to econometrically irrelevant procedures such as the reordering of the data and variables.  {cmd:pariv} is much less
sensitive to near collinearity, but to check that reported results are robust to this issue, the user can call for {opth reps(#)} > 0 random 
permutations of data and variable order.  {cmd:pariv} will report the min to max range of the coefficient and standard errors estimates of the partitioned
2SLS regression across these permutations.  If the minimum and maximum are the same, the user can be confident that the reported results are not sensitive to near collinearity.  
If the user does not provide a random number {hi:seed}, the seed is set to 1. Regardless, the seed is restored to its pre-program value on termination.


{title:Stored results}

{phang} {cmd:pariv} stores the following matrices in {cmd:e()}: {p_end}

{cmd:e(Res)}    Results table in matrix form.
{cmd:e(ResB)}   Coefficient estimates for each random permutation of data and variable order.
{cmd:e(ResSE)}  Standard error estimates for each random permutation of data and variable order.
{cmd:e(R2max)}  Maximum R2 found in regressing one instrument on the others.

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}

