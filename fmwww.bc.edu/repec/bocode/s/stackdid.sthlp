{smcl}
{* *! version 1.4.1 27aug2025}{...}
{viewerjumpto "Syntax" "stackdid##syntax"}{...}
{viewerjumpto "Description" "stackdid##description"}{...}
{viewerjumpto "Options" "stackdid##options"}{...}
{viewerjumpto "Remarks" "stackdid##remarks"}{...}
{viewerjumpto "Examples" "stackdid##examples"}{...}
{viewerjumpto "References" "stackdid##references"}{...}

{title:Title}

{phang}
{bf:stackdid} {hline 2} Stacked Difference-in-Differences Regression

{marker syntax}{...}
{title:Syntax}

{p 8 20 2}
{cmdab:stackdid}
[{depvar}]
[{indepvars}]
{ifin}
{weight}
[{cmd:,} {it:options}]

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Main}
{p2coldent:* {opth tr:eatment(varname)}}binary treatment indicator{p_end}
{p2coldent:* {opth gr:oup(varname)}}panelvar at which treatment occurs{p_end}
{synopt:{opth w:indow(numlist)}}window of time to consider relative to treatment{p_end}
{synopt:{opt nevertreat}}use only never-treated observations as controls; default
behavior is to use never-treated and not-yet-treated observations{p_end}
{synopt:{opth a:bsorb(varlist)}}fixed effects to be absorbed within cohort{p_end}
{synopt:{opt sw}}apply sample weights{p_end}
{synopt:{opt poisson}}estimate a Poisson regression instead of a linear regression{p_end}
{synopt:{opt nobuild}}do not build stacked data{p_end}
{synopt:{opt noreg:ress}}do not perform regression{p_end}

{syntab: Estimator-specific options}
{synopt:{bf:{help reghdfe##options:reghdfe}}}options for {cmd:reghdfe}{p_end}
{synopt:{bf:{help ppmlhdfe##options:ppmlhdfe}}}options for {cmd:ppmlhdfe} if 
{cmd:poisson} specified{p_end}

{syntab: Display}
{synopt:{opt nolog}}do not display build log{p_end}

{syntab: Saving}
{synopt:{opt clear}}replace data in memory with stacked data used in regression{p_end}
{synopt:{opt saving(filename, ...)}}save stacked data to {it:filename}{p_end}

{synoptline}
{p2coldent:* Starred options are required, unless {cmd:nobuild} is specified.}{p_end}
{p 4 6 2}{cmd:bootstrap} is allowed; see {help prefix}.{p_end}
{p 4 6 2}Weights are not allowed with {cmd:sw} or the {helpb bootstrap} prefix.{p_end}
{p2coldent:For allowed weights, see {it:estimator}'s help file.}{p_end}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:stackdid} performs a stacked difference-in-differences regression for 
staggered treatment settings, as described in Gormley and Matsa (2011, 2016).  
It offers three primary advantages compared to a standard 
difference-in-differences approach in such settings:{p_end}

{phang2}(1) not subject to earlier bias from dynamic effects{p_end}
{phang2}(2) can easily isolate a particular window of interest around each event{p_end}
{phang2}(3) can easily be extended into a triple-difference specification{p_end}

{pstd}This method generally requires restructuring the data in memory into "stacks"
of "cohorts" centered on treatment events.  {cmd:stackdid} will create these stacks 
and perform the specified regression.{p_end}

{pstd}See {help stackdid##remarks:Remarks} for more discussion and 
{help stackdid##examples:Examples} for a quick-start.{p_end}


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opth tr:eatment(varname)} is a binary (0,1) indicator that an observation is 
treated in a given period;  for example, if a group is treated only in 2004, 
{it:varname} equals 1 in 2004 and 0 otherwise for observations in that group.

{phang}
{opth gr:oup(varname)} is the panelvar at which treatment occurs.  This need not 
be the same panelvar as set in {cmd:xtset}; for example, if treatment is 
determined at the state-year level, specify {cmd:group(state)}, even if the data 
are at the firm-year level.

{phang}
{opth w:indow(numlist)} is the window of time (relative to treatment) to include 
in a stack.  For example, {cmd:window(-10 10)} specifies that a 2004 cohort 
consists of 1994-2013 data.  However, not all cohort observations in this window will 
necessarily enter the stack: first, a treated group exits the stack if its 
treatment status subsequently turns off again.  Second, a control group exits 
the stack if it becomes treated (or, if {cmd:nevertreat} is specified, such 
groups will not be controls in the first place).  See {help stackdid##remarks:Remarks}.

{phang}
{opt nevertreat} specifies that only never-treated groups be controls.  This reduces
the number of groups eligible to be used as controls, or has no effect.  If this 
is not specified, controls consist of never-treated groups {it:and} not-yet-treated 
groups.

{phang}
{opth absorb(varlist)} specifies fixed effects to be absorbed within cohorts.
This means fixed effects in {it:varlist} are interacted with the cohort identifier 
{bf:_cohort}.  If this option is omitted, {bf:_cohort} becomes the only fixed effect.  Factor variables are allowed in {it:varlist}.

{phang}
{opt sw} applies a sample weighting scheme. This adjusts for the repeated use of 
control units by weighting each observation by the inverse of its frequency in 
the stacked sample.

{phang}
{opt poisson} specifies that the model be estimated using a poisson regression 
instead of a linear regression.  Functionally, this changes the underlying 
estimation command from {cmd:reghdfe} to {cmd:ppmlhdfe}; see 
{it:estimator-specific options}.

{phang}
{opt nobuild} does not build stacked data and proceeds directly to estimation.  
This option assumes the data in memory are stacked data already built by {cmd:stackdid}.  
See {help stackdid##remarks:Remarks} for the intended use case.

{phang}
{opt noreg:ress} does not perform the estimation step.


{dlgtab:Estimator-specific options}

{pstd}
Linear regressions and Poisson regressions are allowed by {cmd:stackdid} thanks
to the excellent estimation commands {cmd:reghdfe} and {cmd:ppmlhdfe} contributed
by Sergio Correia et al.  Thus, {cmd:stackdid} "inherits" these commands' options;
see their help files for full documentation.{p_end}

{synoptset 22}{...}
{synopthdr:estimator}
{synoptline}
{synopt:{bf:{help reghdfe}}}linear regression with multiple fixed effects{p_end}
{synopt:{bf:{help ppmlhdfe}}}Poisson psuedo-likelihood regression with multiple fixed effects{p_end}
{synoptline}

{dlgtab:Display}

{phang}
{opt nolog} suppresses printing to console a build log.

{dlgtab:Saving}

{phang}
{opt clear} replaces the data in memory with the stacked data built by {cmd:stackdid} and used by {it:estimator}.  This option must be specified
if the post-estimation return function {cmd:e(sample)} is desired.  If {cmd:clear}
is not specified, the original data in memory are restored after estimation.

{phang}
{opt saving(filename [, replace])} saves the stacked cohorts built by {cmd:stackdid}
 and used by {it:estimator} to {it:filename}.
 
{phang2}{opt replace} permits {cmd:saving()} to overwite an existing dataset.{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
Treatment may be considered permanent or impermanent.  I will elaborate on that here.
In the case of Gormley & Matsa (2011), treatment is permanent, meaning it remains 
on once on.  For data like this, {cmd:stackdid} executes exactly as described in that paper.
In the case of Gormley & Matsa (2016), treatment is impermanent, meaning it may 
turn off after being on.  Once again, {cmd:stackdid} executes exactly as described in that paper,
and issues the notice "impermanent treatment detected".  There is no need to tell
{cmd:stackdid} what type the data are--it is automatically detected. 
Finally, in the most general case of impermanent treatment (where treatment may
turn on and off any number of times), {cmd:stackdid} executes in the style of the 
papers above, selecting valid pre and post observations for each treatment event.

{pstd}
{cmd:stackdid} has two primary features.  Options are provided to isolate either 
of these.  If both are turned off, {cmd:stackdid} does nothing.

{phang2}{space 4}{it:feature}{space 32}{it:optionally off}{p_end}
{phang2}{hline 57}{p_end}
{phang2}(1) build stacked data{space 21}{opt nobuild}{p_end}
{phang2}(2) perform specified regression{space 11}{opt noreg:ress}{p_end}
{phang2}{hline 57}{p_end}

{pstd}
Practictioners often build upon a baseline specification with increasingly strict
fixed effects and/or covariates.  {cmd:stackdid} will always create the same stacks
when the required options ({cmd:treatment()} and {cmd:group()}), {cmd:window()} and 
{cmd:nevertreat} are the same.  Thus, one can reduce redundant computation using the {cmd:clear} 
option in the first specification and the {cmd:nobuild} option in subsequent 
specifications.

{pstd}
{cmd:stackdid} requires the data to be a panel set by {cmd:xtset}. 
There is no requirement to be strongly balanced.


{marker examples}{...}
{title:Examples}

{pstd}
Generically, adapting specifications to stacked regressions can be as simple as 
replacing {cmd:reghdfe} (or {cmd:ppmlhdfe}) with {cmd:stackdid} and specifying the 
two required options, {opt tr:eatment()} and {opt gr:oup()}.

{phang2}{cmd: . reghdfe {space 1}{it:y x1 x2 x3}, absorb({it:w1#w2}) cluster({it:w1})}{p_end}
{phang2}{cmd: . {ul:stackdid} {it:y x1 x2 x3}, absorb({it:w1#w2}) cluster({it:w1}) {ul:tr({it:x1}) gr({it:g1})}}{p_end}

{pstd}
Specific examples are illustrated using simulated data.  In it, a balanced panel of 500 fictional firms 
({it:firm_id}) in 2000-2011 are divided into eleven groups 
({it:sector}) with three treatment events.  The outcome variable ({it:y}) has 
an autoregressive component persistent in continuous treatment, 
encouraging the application of {cmd:stackdid}.  The sample of firms is bisected
by binary characteristic {it:char}.  A window of three years before 
and after treatment events is to be specified.

{pstd}Load the example data and apply {cmd:xtset}{p_end}
{phang2}{cmd:. use https://raw.githubusercontent.com/jacobwtriplett/stackdid/main/stackdid_example}{p_end}
{phang2}{cmd:. xtset firm_id year}

{pstd}Basic usage{p_end}
{phang2}{cmd:. stackdid y treatXpost, tr(treatXpost) gr(sector) w(-3 3)}{p_end}

{pstd}Subsequent specifications{p_end}
{phang2}{cmd:. stackdid y treatXpost, tr(treatXpost) gr(sector) w(-3 3) clear}{p_end}
{phang2}{cmd:. stackdid y treatXpost, nobuild absorb(firm_id)}{p_end}

{pstd}Triple difference{p_end}
{phang2}{cmd:. stackdid y treatXpost treatXpostXchar, nobuild absorb(year#char)}{p_end}

{pstd}Suggested: visually decompose cohorts{p_end}
{phang2}{cmd:. table (sector) (year) (_cohort), statistic(firstnm treatXpost) nototal}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:stackdid} stores the following in {cmd:r()}:

{synoptset 23 tabbed}{...}
{p2col 5 23 26 2: Scalars}{p_end}
{synopt:{cmd:r(N_original)}}number of observations in original data{p_end}
{synopt:{cmd:r(N_stacked)}}number of observations in stacked data (also see {cmd:e(N)}){p_end}

{p2col 5 23 26 2: Macros}{p_end}
{synopt:{cmd:r(cmdline)}}command as typed{p_end}
{synopt:{cmd:r(regline)}}command fed to {it:estimator} (also see {cmd:e(cmdline)}){p_end}
{synopt:{cmd:r(treatment)}}treatment variable{p_end}
{synopt:{cmd:r(group)}}group variable{p_end}
{synopt:{cmd:r(window)}}window numlist{p_end}

{pstd}
See {it:estimator}'s help file for results stored in {cmd:e()}.


{title:Author}

{pstd}Jacob Triplett{p_end}
{pstd}The University of North Carolina{p_end}
{pstd}Kenan-Flagler Business School{p_end}
{pstd}jacob_triplett@kenan-flagler.unc.edu{p_end}


{title:Acknowledgments}

{pstd}I wish to thank Todd Gormley for the inspiration to develop this package,
and Todd Gormley and David Matsa for invaluable guidance during its development.{p_end}


{marker references}{...}
{title:References}

{phang}
Sergio Correia, Paulo Guimarães, Thomas Zylkin: "ppmlhdfe: Fast Poisson Estimation with High-Dimensional Fixed Effects", 2019; arXiv:1903.01690.

{phang}
Sergio Correia, 2014. "REGHDFE: Stata module to perform linear or instrumental-variable regression absorbing any number of high-dimensional fixed effects," Statistical Software Components S457874, Boston College Department of Economics, revised 21 Aug 2023.

{phang}
Todd A. Gormley, David A. Matsa, Growing Out of Trouble? Corporate Responses to Liability Risk, The Review of Financial Studies, Volume 24, Issue 8, August 2011, Pages 2781–2821, https://doi.org/10.1093/rfs/hhr011.{p_end}

{phang}
Todd A. Gormley, David A. Matsa,
Playing it safe? Managerial preferences, risk, and agency conflicts,
Journal of Financial Economics,
Volume 122, Issue 3,
2016,
Pages 431-455,
ISSN 0304-405X,
https://doi.org/10.1016/j.jfineco.2016.08.002.
{p_end}

{phang}
Todd A. Gormley, Manish Jha, and Meng Wang, The Politicization of Social Responsibility (March 11, 2024). Available at SSRN: https://ssrn.com/abstract=4558097{p_end}
