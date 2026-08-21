{smcl}
{* *! version 2.0.0 16Aug2026}{...} 
{* *! version 1.1.0 03Mar2013}{...} 
{* *! version 1.0.0 11Feb2013}{...}

{title:Title}

{p2colset 5 14 15 2}{...}
{p2col:{hi:rtmci} {hline 2}} Regression to the mean effects with confidence intervals{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}
Using data in memory{p_end}

{p 8 14 2}
{cmd:rtmci}
{it:pretest posttest}
{ifin}
{cmd:,}
{opt cut:off(#)}
[
{opt per:iod(#)}
{cmd:vce(vcetype)}
{opt lev:el(#)}
{opt fig:ure}
]

{pstd}
{it:pretest} is the pre-test variable, {it:posttest} is the post-test variable, and
{opt cutoff(#)} is the cutoff value on the pre-test variable.{p_end}


{pstd}
Immediate form of {it:rtmci}{p_end}

{p 8 14 2}
{cmd:rtmcii}
{it:mean_pre sd_pre cut-off rho}
[{cmd:,}
{opt per:iod(#)}
{opt n(#)}
{cmd:vce(vcetype)}
{opt lev:el(#)}
{opt fig:ure}
]

{pstd}
In the immediate version, {it:mean_pre} is the pre-test mean, {it:sd_pre} is its standard
deviation, {it:cut-off} is the cutoff value, and {it:rho} is the correlation between the
pre-test and post-test variables.{p_end}



{synoptset 23 tabbed}{...}
{synopthdr:rtmci and rtmcii}
{synoptline}
{syntab:Main}
{synopt :{opt cut:off(#)}}cutoff value on the pre-test variable; {cmd:required for {cmd:rtmci} only}{p_end}
{synopt :{opt per:iod(#)}}number of periods represented by the pre-test measurement; default {cmd:period(1)}{p_end}
{synopt :{opt n(#)}}{cmd:rtmcii} only; meaning depends on {cmd:vce()} -- see {help rtmci##options:Options}; default {cmd:n(1000)}{p_end}

{syntab:SE/Robust}
{synopt :{cmd:vce(}{it:vcetype}{cmd:)}}may be {opt r:obust} (the default for {cmd:rtmci}), {opt nor:mal} (the default for {cmd:rtmcii})
 or {opt boot:strap}{p_end}

{synopt: {cmd:bootstrap options}}{p_end}
{synopt :{cmd:seed(}{it:#}{cmd:)}}sets the random-number seed to {it:#}{p_end}
{synopt :{cmd:reps(}{it:#}{cmd:)}}specifies the number of replications to be performed {p_end}
{synopt :{opt si:ze(#)}}draws samples of size {it:#}{p_end}
{synopt :{help prefix_saving_option:{bf:saving(}{it:filename}{bf:, ...)}}}saves results to {it:filename}{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{cmdab:fig:ure}}produces a plot of the expected pre- and post-test means and confidence intervals for values 
above and below the cutoff {p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:rtmci} calculates the regression to the mean effect for a variable that is generally measured 
at two points in time (i.e., "pre-test" and "post-test"), based on a defined cutoff value on the "pre-test" measure, and 
estimates confidence intervals using either robust or bootstrapped standard errors. If only summary level statistics are 
available (e.g., as published in a journal article), the user may consider using {help rtmcii}, an immediate form of {cmd:rtmci}.{p_end}



{marker options}{...}
{title:Options}

{dlgtab:Main}

{p 4 8 2}
{opt cutoff(#)} {cmd:Required for rtmci}. It specifies the cutoff value on the pre-test variable used to
define the "above cutoff" and "below cutoff" subgroups.

{p 4 8 2}
{cmd:periods(}{it:#}{cmd:)} defines the number of periods that the {it:pre-test}
variable represents; default is {cmd:per(1)}.

{p 4 8 2}
{opt n(#)} {cmd:For rtmcii only}. It means different things depending on {cmd:vce()}. With
{cmd:vce(bootstrap)} it is the size of the dataset simulated by {helpb corr2data} to match the
supplied summary statistics. With {cmd:vce(normal)} it is used
directly as the sample size underlying the supplied summary statistics, and must reflect the
actual N of the source data. If this not specified correctly, the CI width will be wrong even though the
point estimates are unaffected.

{dlgtab:SE/Robust}

{phang}
{opt vce(vcetype)} specifies the type of standard error reported, which
includes ({cmd:normal} - the default for {cmd:rtmcii}) derived from asymptotic theory,
({cmd:robust} - the default for {cmd:rtmci}) which is robust to a type of misspecification, 
and the ({cmd:bootstrap}) method.

{phang2}
{cmd:vce(robust)}, the default for {cmd:rtmci}, builds the covariance empirically from
observation-level residuals ("sandwich"/influence-function covariance) and applies a small-sample 
correction (N/(N-4)). This robust standard error tracks the bootstrap closely on both normal and non-normal data.

{phang2}
{cmd:vce(normal)}, the default for {cmd:rtmcii}, uses the classical bivariate-normal-theory 
delta-method formula. If the source data are meaningfully non-normal and available,
it is better to run {cmd:rtmci} on the raw data rather than {cmd:rtmcii} on summary statistics.

{phang2}
{cmd:vce(bootstrap)} computes bootstrapped standard errors and confidence intervals. 

{phang3}
{opt seed(#)} sets the random-number seed to {it:#}. Specifying this option 
is equivalent to typing {cmd:. set seed} {it:#} before calling {cmd:rtmci} or {cmd:rtmcii}; default is {cmd:seed(1234)}.

{phang3}
{opt reps(#)} specifies the number of replications to be performed; default
is {cmd:reps(1000)}.
	
{phang3}
{opt size(#)} sets the number of observations drawn at each replication; default is {help _N}.

{phang3}
{help prefix_saving_option:{bf:saving(}{it:filename}{bf:, ...)}}
saves the bootstrapped results of the simulations to {it:filename}. See
{it:{help prefix_saving_option}} for details about {it:suboptions}.

{dlgtab:Reporting}

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. The
default is {cmd:level(95)} or as set by {helpb set level}.

{phang}
{opt figure} plots the expected pre-test and post-test values, with confidence intervals, above
and below the cutoff.



{title:Examples}

{dlgtab:rtmci}

{pstd}Setup{p_end}
{phang2}{cmd:. use RTM_example.dta}{p_end}

{pstd}With robust standard errors{p_end}
{phang2}{cmd:. rtmci pretest posttest, cutoff(75)}{p_end}

{pstd}With bootstrapped standard errors{p_end}
{phang2}{cmd:. rtmci pretest posttest, cutoff(75) vce(boot) reps(2000) seed(4321) figure}{p_end}


{dlgtab:rtmcii}

{pstd}Data from Linden (2007), Figure 2. {cmd:n()} here is the real sample size behind the
summary statistics, since {cmd:vce(normal)} is the default.{p_end}
{phang2}{cmd:. rtmcii 53.12 8.27 44.25 0.742, n(118)}{p_end}

{pstd}Same data, bootstrap CI for comparison.{p_end}
{phang2}{cmd:. rtmcii 53.12 8.27 44.25 0.742, n(118) bootstrap reps(2000) seed(4321)}{p_end}

{dlgtab:by()}

{phang2}{cmd:. bys treat: rtmci pretest posttest, cutoff(75)}{p_end}


{marker results}{title:Stored results}

{pstd}
{cmd:rtmci} and {cmd:rtmcii} store the following in {cmd:e()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations ({cmd:rtmci}) or assumed N ({cmd:rtmcii}, {cmd:vce(normal)}){p_end}
{synopt:{cmd:e(k)}}cutoff value{p_end}
{synopt:{cmd:e(m)}}number of periods{p_end}
{synopt:{cmd:e(rho)}}supplied correlation ({cmd:rtmcii} only){p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:rtmci} or {cmd:rtmcii}{p_end}
{synopt:{cmd:e(vce)}}{cmd:robust} or {cmd:bootstrap} ({cmd:rtmci}); {cmd:normal} or {cmd:bootstrap} ({cmd:rtmcii}){p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust}, {cmd:Normal}, or {cmd:Bootstrap}{p_end}
{p2colreset}{...}

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}
{p2colreset}{...}



{title:References}

{p 4 8 2}
Davis CE. The effect of regression to the mean in epidemiologic and clinical studies.
{it:American Journal of Epidemiology} 1976;104:493-498.{p_end}

{p 4 8 2}
Galton F. Regression towards mediocrity in hereditary stature. {it:Journal of the Anthropological
Institute} 1886;15:246-263.{p_end}

{p 4 8 2}
Gardner MJ, Hardy JA. Some effects of within person variability in epidemiological studies.
{it:Journal of Chronic Disease} 1973;26:781-795.{p_end}

{p 4 8 2}
Linden A. Estimating the effect of regression to the mean in health management programs.
{it:Disease Management & Health Outcomes} 2007;15(1):7-12.{p_end}

{p 4 8 2}
Linden A. Assessing regression to the mean effects in health care initiatives. {it:BMC Medical
Research Methodology} 2013;13(119):1-7.{p_end}

{p 4 8 2}
Stigler SM. Regression towards the mean, historically considered. {it:Statistical Methods in
Medical Research} 1997;6(2):103-14.{p_end}

{p 4 8 2}
Yudkin PL, Stratton IM. How to deal with regression to the mean in intervention studies.
{it:Lancet} 1996;347:241-243.{p_end}


{marker citation}{title:Citation of {cmd:rtmci}}

{p 4 8 2}{cmd:rtmci} is not an official Stata command. It is a free contribution to the research
community, like a paper. Please cite it as such:{p_end}

{p 4 8 2}
Linden, Ariel (2013). RTMCI: Stata module for estimating regression to the mean effects with confidence intervals. 
Statistical Software Components S457757, Boston College Department of Economics. {p_end}



{title:Authors}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb corr2data}, {helpb bootstrap}, {helpb nlcom}{p_end}
