{smcl}
{* *! version 3.0.0 July 2023}{...}
{cmd: help randcmdci}
{hline}

{title:Title}

{phang} {hi:randcmdci} {hline 2} Randomization-t p-values and confidence intervals for OLS regression coefficients that are asymptotically robust to departures from the sharp null. {p_end}
 
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
    {opth reps(#)}                    integer number of attempted randomization iterations, default is 999.
    {opth calc1(string)}              execute stata command after each treatment randomization.
    {opth calc2(string)}              execute stata command after each treatment randomization.
	...
    {opth calc20(string)}             execute stata command after each treatment randomization.
    {opth null1(string)}              test a particular null
    {opth null2(string)}              test a particular null
	...
    {opth null10(string)}             test a particular null
    {opth max(varlist)}               calculate the maximum p-value for each treatment effect in varlist across all possible nulls for other {hi:testvars}.
    {opth maxlevel(#)}                the intensity of the search used to find such maxima, default is 100, but higher values should be used to confirm results.
    {opth maxcoef(#)}                 maximum bound on the null for other treatment effects based upon deviation from estimated values.
    {opth maxwald(#)}                 maximum bound on the null for other treatment effects based upon conventional wald statistic.


{phang} {hi:cmd} must be Stata's {cmd:regress} or {cmd:areg} command.

{phang} 
{hi:treatvars} indicates the base treatment variables that are permuted/rerandomized on each iteration and is not optional. 
{hi:treatvars} cannot vary within groups identified by {hi:groupvar}.  
Observations for which {hi:treatvars} are missing are dropped.
{hi:testvars} indicates the treatment based measures within {indepvars} in the estimating equation whose effects are tested.
{hi:testvars} may differ from {hi:treatvars} when, for example, {hi:treatvars} are interacted with participant characteristics in the estimating equation (see example 2 below).
{p_end}

{phang}
To update treatment measures that involve interactions with participant characteristics, up to 20 post-treatment permutation calculations ({hi:calc}) are allowed and are executed in numerical order.  
Permutation of treatment and post-permutation calculations are based on the regression sample alone.
{p_end}

{phang}
In addition to providing p-values and confidence intervals for individual coefficients, the program also allows the user to call for the testing of up to 10 specific nulls ({hi:null}).
Numeric values, separated by commas, must be listed for each parameter in {hi:testvars} (see example 6 below).  For equations with multiple treatment measures this is a test
of a joint null.
{p_end}

{phang}
In equations with multiple {hi:testvars}, {cmd:randcmdci} reports baseline confidence intervals and p-values for individual treatment effects setting the nulls on
other treatment effects equal to estimated values.  The program also allows the user to call for p-values that do not depend upon the nulls for other treatment
effects by calculating the maximum p-value for each individual treatment effect across all possible nulls for other (untested) treatment effects.  As this is time
consuming, such maxima are only calculated for the treatment effects requested in {hi:max(varlist)}.  {hi: maxlevel(#)} modifies the intensity of
the search for maxima and either {hi: maxcoef(#)} or {hi: maxwald(#)} may be used to put bounds on the nulls considered (further detail below).
{p_end}

{phang}
If the user does not provide a random number {hi:seed}, the seed is set to 1 (to ensure replicability, provided the data has not been reordered, on subsequent runs). The seed is restored to its pre-program value on termination.
{p_end}

{title:Description}

{phang} {cmd:randcmdci} computes randomization confidence intervals and p-values for experiments where permutations of {hi:treatvars}, 
possibly stratified and/or by groups of observations, are valid counterfactual experimental outcomes. 
Randomization inference of all forms is exact in finite samples when the sharp null is true (i.e. the treatment effect is the same for each and every observation).
When the sharp null is not true and coefficients estimate the average of heterogeneous treatment effects, 
randomization inference based upon studentized test statistics, the randomization-t, has the same asymptotic validity as the clustered/robust covariance estimate provided
(1) treatment is iid (by group if grouping); (2) covariates interacted with treatment are included separately as regressors in their own right; 
(3) treatment, regressors and errors have sufficiently high moments; 
(4) the maximum number of observations within which treatment, regressors or errors are correlated is bounded;
(5) if stratifying, the first and second moments of treatment are asymptotically identical across strata.  For details, see:
{p_end}

{pmore} Young, Alwyn. 
{it:Asymptotically Robust Permutation-Based Randomization Confidence Intervals for Parametric OLS Regression.}
{p_end}

{phang} {cmd:randcmdci} begins by reporting the conventional Stata estimation results so that the user may confirm the estimating equation is correct.  
The sample is automatically restricted to observations for which {hi:treatvars} are non-missing, but additional sample qualifiers and estimation options are allowed.  
{cmd:randcmdci} then rerandomizes (i.e. permutes) {hi: treatvars}, following any strata and grouping specified by the user, within the regression sample and performs optional {hi:calc1} ... {hi:calc20} (see examples below).  
This sampling from the distribution of potential treatment outcomes is used to construct confidence intervals whose probability of covering the true parameter value 
is either exact in finite samples (when the sharp null is true) or otherwise asymptotically accurate (when it is not).

{phang} When the regression contains multiple treatment measures ({hi:testvars}), randomization confidence intervals for each coefficient depend upon the null for others, 
although this characteristic vanishes asymptotically.  In such cases, {cmd:randcmdci} calculates the confidence interval and p-value for each individual treatment effect under the null
that other treatment effects equal their estimated values, as asymptotically those estimated values typically converge to the true parameters.  This attempts to mimic the (impractical) exact 
test that sets the nulls on untested measures equal to their true values, but because estimated values are not equal to true parameter values will not necessarily be exact in finite samples.
However, to provide a conservative test that is guaranteed to control size at the desired level if treatment effects are sharp, {cmd:randcmdci} allows the user to call for the calculation of the maximum p-value 
for each individual treatment effect across all possible nulls for untested treatment measures. For details on these issues, see the paper above.

{phang} In the case of equations with k = 2 treatment effects, the maximum p-value for each treatment effect across all possible nulls for the other can be calculated analytically.  In the case
of equations with k = 3 treatment effects, calculating the maximum p-value for each individual treatment effect across all possible nulls for the others can be reduced to searching on the bounded space [0,pi].  {cmd:randcmdci} implements a 
{hi:maxlevel(#)} grid search on this space.  In the case of equations with k > 3 treatment effects, finding the maximum can be reduced to searching on the bounded space [0,pi]^(k-2).  {cmd:randcmdci}
implements {hi:maxlevel(#)} Nelder-Mead simplex/amoeba searches on this space, taking the maximum of them all. The program uses a baseline {hi:maxlevel(#)} of 100 to speed execution.  
Before reporting final results, the user should call for a more intensive search for a maximum, e.g. setting maxlevel to 10000 for k = 3 and 1000 for k > 3.

{phang} In calculating the maximum p-value of a treatment effect of zero for individual treatment effects across possible nulls for untested treatment measures, some extreme values for other
treatment measures may be considered implausible.  The user may use either {hi:maxcoef(#)} or {hi:maxwald(#)} to limit the space of possible nulls for other treatment measures across which the maximum p-value 
of a treatment effect of zero for an individual treatment effect is calculated (see example 7 below).

{title:Examples}


{p} Example 1: One treatment variable, with estimation options.

{phang} randcmdci areg outcome treatment covariates [if] [in] [weights], absorb(absorb) robust treatvars(treatment) testvars(treatment)


{p} Example 2: Treatment variables include interactions with participant characteristics which are not part of treatment and have to be recalculated after treatment is rerandomized.

{phang} randcmdci reg outcome treatment treatage covariates, treatvars(treatment) testvars(treatment treatage) calc1(replace treatage = treatment*age)


{p} Example 3: Interactions between treatment measures can be coded with {hi:calc} or without.

{phang} randcmdci reg outcome treat1 treat2 treat12 covariates, treatvars(treat1 treat2) testvars(treat1 treat2 treat12) calc1(replace treat12 = treat1*treat2)

{phang} randcmdci reg outcome treat1 treat2 treat12 covariates, treatvars(treat1 treat2 treat12) testvars(treat1 treat2 treat12)

{phang} Comment: Since treat12 is the product of randomized treatment variables, and does not involve interaction with non-randomized participant characteristics, reallocating pairs of (treat1,treat2) to participants 
and then calculating treat12 is equivalent to reallocating triplets of (treat1,treat2,treat12) across participants. {p_end}


{p} Example 4: Treatment is stratified and applied in groups.

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village)

{phang} Comment: treat1 and treat2 cannot vary within {hi:groupvar}.  The pair (treat1, treat2) is rerandomized across villages (within strata) with common values applied to everyone in each village. 


{p} Example 5: Testing of specific joint nulls.  In example 4, we want to test the joint null that treat1 = 1.5 and treat2 = 1, 
as well as the joint null that treat1 = 2 and treat2 = 1:

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village) null1(1.5,1) null2(2,1)

{phang} Comment: Numeric values, separated by commas, for the average effect of each variable in {hi:testvars} must be given.  Results report the p-value for the joint test
of both treatment effects at the values given.


{p} Example 6: Maximum p-values across all possible nulls for untested treatment meausures.  In example 4, we want to know the maximum p-value of a treatment effect treat1 = 0 across all possible nulls for
treat2 and the maximum pvalue of a treatment effect treat2 = 0 across all possible nulls for treat1.  This test is guaranteed to have size less than nominal level (e.g. .05) if treatment
effects are sharp.

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village) max(treat1 treat2)

{phang} Comment: Since these calculations are time consuming, it is possible to call for maximum p-values for only a subset of {hi:testvars}, e.g. max(treat1) or max(treat2).  


{p} Example 7: The user wants to limit the range of nulls considered for untested treatment measures in calculating maximum p-values for individual treatment measures.

{phang} randcmdci areg outcome treat1 treat2 treat12 covariates, absorb(village) cluster(village) treatvars(treat1 treat2 treat12) testvars(treat1 treat2 treat12) strata(strata) groupvar(village) max(treat1) maxcoef(5)

{phang} local c = sqrt(invchi2tail(2,1e-10))

{phang} randcmdci areg outcome treat1 treat2 covariates, absorb(village) cluster(village) treatvars(treat1 treat2) testvars(treat1 treat2) strata(strata) groupvar(village) max(treat1 treat2) maxwald(`c')

{phang} Comment: Either maxcoef(#) or maxwald(#) may be called, but not both.  

{phang} When the user selects maxcoef, the range of nulls on untested measures considered is limited to those where the
sum of squared deviations of those treatment measures from estimated values is less that #^2, i.e. restricts the null to lie within a sphere of radius # around the regression point estimates.  In the
example above, in calculating the maximum p-value for treat1 the sum of squared deviations of the nulls for treat2 and treat12 from estimated values must be less than 25, while in calculating the
maximum p-value for treat2 the sum of squared deviations of the nulls for treat1 and treat12 from estimated values must be less than 25. 

{phang} When the user selects maxwald, the wald statistic for the deviation of the nulls on untested measures from estimated values is limited to less than #^2. In the example above, the user
selects a bound such that the p-value of the conventional test of the null for untested measures must be greater than or equal to 10^(-10).  This is the default bound when neither
maxcoef or maxwald is specfied by the user.

{title:Reported results}

{phang} In comparing potential outcomes, randomization inference always produces "ties", as the original experimental outcome (at a minimum) must be considered a tie with itself.  
P-values are randomly distributed between minimum and maximum values determined by these ties and this randomization (correctly) determines the boundaries of the confidence interval (see the paper referenced above).
If (1) the number of potential experimental outcomes is large so that there are no ties beyond that of the original experimental outcome and (2) the number of iterations plus 1 times the nominal coverage probability equals an integer, 
ties play no role in determining the boundaries of the confidence interval or the significance of coefficients at the given nominal level.  
The default number of 999 iterations meets the second of these conditions for the .01, .05, and .10 levels (.99, .95 and .90 confidence intervals).

{phang} Randomization confidence intervals may be unbounded (especially when the number of ties is large) and non-convex. 
Unbounded upper or lower bounds to confidence intervals are indicated using Stata's symbol for missing ({hi:.}).  
If the confidence interval is not-convex this fact is reported to the user, along with the convex cover of the disjoint confidence regions.  

{phang} Only "successful" iterations, where coefficients and covariance estimates are both identified, are used in calculating p-values and confidence intervals, 
as the reporting of the original experimental result was conditional on the allocation of treatment producing these.  {p_end}

{phang} {cmd:randcmdci} stores the following matrices in {cmd:e()}: {p_end}

{cmd:e(HB)}    Confidence intervals & p-values under the null that other treatment effects equal their estimated value.
{cmd:e(JTest)} P-values for joint tests, if requested.
{cmd:e(Pmax)}  Maximum p-values for tests of individual zero treatment effects across possible nulls for other treatment effects, if requested.

{title:Author}
	
{phang} Alwyn Young, London School of Economics, a.young@lse.ac.uk. {p_end}

