{smcl}
{* *! version 1.0.0 15May2018}{...}
{cmd: help randcmdci}
{hline}

{title:Title}

{phang} {hi:randcmdci} {hline 2} Robust randomization-t p-values and confidence intervals for regression coefficients. {p_end}
 
{title:Syntax}

{phang} {cmd:randcmdci} {cmd:cmd} {depvar} {indepvars} {ifin} {weight}, {opth treatvars(varlist)}  {opth testvars(varlist)} [{cmd:,} {it:options}] {p_end}

{title:Options}

    {ul:Estimation and Conventional Standard Error} 

    {opt nocons:tant}                 suppress constant term.
    {opth absorb(varname)}            fixed effects for the categories defined by varname.
    {opt robust}                     robust conventional standard errors, the default.
    {opth cluster(varname)}           clustered conventional standard errors.


    {ul:Randomization Inference} 

    {opth strata(varlist)}            variables identifying randomization strata.
    {opth groupvar(varlist)}          variables identifying treatment groups.
    {opth seed(#)}                    set random-number seed to #, default is 1.
    {opth reps(#)}                    number of attempted randomization iterations; default is 999, minimum is 99.
    {opth calc1(string)}              execute stata command after each treatment randomization.
    {opth calc2(string)}              execute stata command after each treatment randomization.
	...
    {opth calc20(string)}             execute stata command after each treatment randomization.
    {opth test1(string)}              test a particular joint null.
    {opth test2(string)}              test a particular joint null.
	...
    {opth test10(string)}             test a particular joint null.


{phang} {hi:cmd} must be Stata's {cmd:regress} or {cmd:areg} command.

{phang} 
{hi:treatvars} indicates the base treatment variables that are randomized on each iteration and is not optional. 
{hi:treatvars} cannot vary within groups identified by {hi:groupvar}.  
Observations for which {hi:treatvars} are missing are dropped.
{hi:testvars} indicates the treatment based measures within {indepvars} in the estimating equation whose effects are tested.
{hi:testvars} may differ from {hi:treatvars} when, for example, {hi:treatvars} are interacted with participant characteristics in the estimating equation (see example 2 below).
{p_end}

{phang}
To update treatment measures that involve interactions with participant characteristics, up to twenty post-treatment calculations ({hi:calc}) are allowed and are executed in numerical order.  
Rerandomization and all such calculations are based on the regression sample alone.
{p_end}

{phang}
In addition to providing confidence intervals for individual coefficients, the program also allows the user to call for the testing of up to 10 specific joint nulls ({hi:test}).
Numeric values, separated by commas, must be listed for each parameter in {hi:testvars} (see example 5 below).
{p_end}

{phang}
If the user does not provide a random number {hi:seed}, the seed is set to 1 (to ensure replicability, provided the data has not been reordered, on subsequent runs). The seed is restored to its pre-program value on termination.
{p_end}

{title:Description}

{phang} {cmd:randcmdci} computes randomization confidence intervals and p-values that are asymptotically robust to deviations from the sharp null in favour of average treatment effects. 
Randomization inference of all forms is exact in finite samples when the sharp null is true (i.e. the treatment effect is the same for each and every observation).
When the sharp null is not true and coefficients estimate the average of heterogeneous treatment effects, 
randomization inference based upon studentized test statistics, the randomization-t, has the same asymptotic validity as the clustered/robust covariance estimate that is used provided
(1) treatment is iid (by group if grouping); (2) covariates interacted with treatment are included separately as regressors in their own right; 
(3) treatment, regressors and errors have sufficiently high moments; 
(4) the maximum number of observations within which treatment, regressors or errors are correlated is bounded.
For details, see:
{p_end}

{pmore} Young, Alwyn. 
{it:Asymptotially Robust Randomization Confidence Intervals for Parametric OLS Regression.}
{p_end}

{phang} {cmd:randcmdci} begins by reporting the conventional Stata estimation results so that the user may confirm the estimating equation is correct.  
The sample is automatically restricted to observations for which {hi:treatvars} are non-missing, but additional sample qualifiers and estimation options are allowed.  
{cmd:randcmdci} then rerandomizes {hi: treatvars}, following any strata and grouping specified by the user, within the regression sample and performs optional {hi:calc1} ... {hi:calc20} (see examples below).  
This sampling from the distribution of potential treatment outcomes is used to construct confidence intervals whose probability of covering the true parameter value 
is either exact in finite samples (when the sharp null is true) or otherwise asymptotically accurate (when it is not).

{phang} When the regression contains multiple treatment measures, randomization confidence intervals for each coefficient depend upon the null for others, 
although this characteristic vanishes asymptotically in the neighbourhood of the true parameter values.
When estimating multiple treatment effects, {cmd:randcmdci} calculates the confidence interval for each coefficient under the null that other treatment effects equal their estimated values,
as asymptotically these converge to the true parameters.
{cmd:randcmdci} also allows the user to call for joint tests of nulls that precisely specify, in the way the user wishes, the joint null being tested. {p_end}

{title:Examples}


{p} Example 1: One treatment variable, with estimation options.

{phang} randcmdci areg outcome treatment covariates [if] [in] [weights], absorb(absorb) robust treatvars(treatment) testvars(treatment)


{p} Example 2: Treatment variables include interactions with participant characteristics which are not part of treatment and have to be recalculated after treatment is rerandomized.

{phang} randcmdci reg outcome treatment treatage covariates, treatvars(treatment) testvars(treatment treatage) calc1(replace treatage = treatment*age)

{phang} Comment: Calculations could also be coded as calc1(drop treatage) calc2(generate treatage = treatment*age), but use of replace, where appropriate, is simpler.


{p} Example 3: Interactions between treatment measures can be coded with {hi:calc} or without.

{phang} randcmdci reg outcome treat1 treat2 treat12 covariates, treatvars(treat1 treat2) testvars(treat1 treat2 treat12) calc1(replace treat12 = treat1*treat2)

{phang} randcmdci reg outcome treat1 treat2 treat12 covariates, treatvars(treat1 treat2 treat12) testvars(treat1 treat2 treat12)

{phang} Comment: Since treat12 is the product of randomized treatment variables, and does not involve interaction with non-randomized participant characteristics, reallocating pairs of (treat1,treat2) to participants 
and then calculating treat12 is equivalent to reallocating triplets of (treat1,treat2,treat12) across participants. {p_end}


{p} Example 4: Treatment is stratified and applied in groups.

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village)

{phang} Comment: treat1 and treat2 cannot vary within {hi:groupvar}.  The pair (treat1, treat2) is rerandomized across villages (within strata) and applied to everyone in the village. 


{p} Example 5: Testing of specific joint nulls.  In example 4, we want to test the joint null that treat1 = 1.5 and treat2 = 1.0, 
as well as the joint null that treat1 = 2.0 and treat2 = 1.0:

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village) test1(1.5,1.0) test2(2.0,1.0)

{phang} Comment: Numeric values, separated by commas, for the average effect of each variable in {hi:testvars} must be given.


{title:Reported results}

{phang} In comparing potential outcomes, randomization inference always produces "ties", as the original experimental outcome (at a minimum) must be considered a tie with itself.  
P-values are randomly distributed between minimum and maximum values determined by these ties and this randomization (correctly) determines the boundaries of the confidence interval (see the paper referenced above).
If (1) the number of potential experimental outcomes is large so that there are no ties beyond that of the original experimental outcome and (2) the number of iterations plus 1 times the nominal coverage probability equals an integer, 
ties play no role in determining the boundaries of the confidence interval or the significance of coefficients at the given nominal level.  
The default number of 999 iterations meets the second of these conditions for the .01, .05, and .10 levels (.99, .95 and .90 confidence intervals).

{phang} Randomization confidence intervals may be unbounded (especially when the number of ties is large) and non-convex. 
Unbounded upper or lower bounds to confidence intervals are indicated using Stata's symbol for missing ({hi:.}).  
If the confidence interval is not-convex this fact is reported to the user, along with the convex cover of the disjoint confidence regions.  
In such cases, the probability of covering the true null is biased above the nominal value.

{phang} Only "successful" iterations, where coefficients and covariance estimates are both identified, are used in calculating p-values and confidence intervals, 
as the reporting of the original experimental result was conditional on the allocation of treatment producing these.  {p_end}

{phang} {cmd:randcmdci} stores the following matrices in {cmd:e()}: {p_end}

{cmd:e(HB)}    Confidence intervals & p-values under the null that other treatment effects equal their estimated value.
{cmd:e(JTest)} P-values for joint tests, if requested.

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}

