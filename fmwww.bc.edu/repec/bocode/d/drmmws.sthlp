{smcl}
{* *! version 2.0.0 24May2026}{...}
{* *! version 1.0.0 06Jan2017}{...}

{title:Title}

{p2colset 5 15 19 2}{...}
{p2col:{hi:drmmws} {hline 2}} Doubly-robust marginal mean weighting through stratification  {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}


{p 8 12 2}
{cmd:drmmws}
{cmd:}{it:{help varname:outcome}} 
{cmd:}{it:{help varname:treatvar}}
{cmd:}[{it:{help varlist:indepvars}}] 
{ifin} 
[{cmd:,} {opt o:vars}({it:{help varlist:varlist}}) 
{opt p:vars}({it:{help varlist:varlist}}) 
{opt nstr:ata}({it:integer}) 
{opt f:amily}({it:{help glm##familyname:familyname}})
{opt l:ink}({it:{help glm##linkname:linkname}})
{opt att}
{opt med:ian}
{opt comm:on}
{opt boot:strap}
{opt nodots}
{opt seed}({it:integer})
{opt reps}({it:integer})
{opt level}({it:#}) ]


{p 4 4 2}
{it:treatvar} must be binary and coded 0 for the control group and 1 for the treatment group.

{synoptset 19 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt o:vars}{cmd:(}{it:{help varlist:varlist}}{cmd:)}} specifies the covariates in the outcome model {p_end}
{synopt:{opt p:vars}{cmd:(}{it:{help varlist:varlist}}{cmd:)}} specifies the covariates in the treatment assignment model (propensity score)  {p_end}
{synopt:{opt nstr:ata}{cmd:(}{it:integer}{cmd:)}} specifies the number of quantiles of the propensity score to generate; default is 5 {p_end}
{synopt :{opth f:amily(glm##familyname:familyname)}} distribution of the outcome variable; default is {cmd:family(gaussian)}{p_end}
{synopt :{opth l:ink(glm##linkname:linkname)}} link function; default is {cmd:link(identity)}{p_end}
{synopt:{opt att}} estimates average treatment effect on the treated; default is the average treatment effect in the population {p_end}
{synopt:{opt med:ian}} estimates median treatment effects. Can be combined with {cmd:att} to estimate the median treatment effect on the treated {p_end}
{synopt:{opt comm:on}} restricts the analysis to only those units within the region of common support {p_end}
{synopt:{opt boot:strap}} requests bootstrap standard errors. By default, standard errors are computed analytically using {cmd:margins} {p_end}
{synopt:{opt nodots}} suppresses display of the replication dots during bootstrap (only relevant with {cmd:bootstrap}) {p_end}
{synopt:{opt seed}{cmd:(}{it:integer}{cmd:)}} sets the random-number seed for the bootstrap procedure (only relevant with {cmd:bootstrap}) {p_end}
{synopt:{opt reps}{cmd:(}{it:integer}{cmd:)}} specifies the number of replications to be performed in the bootstrap procedure; default is 200 (only relevant with {cmd:bootstrap}) {p_end}
{synopt:{opt level}{cmd:(}{it:#}{cmd:)}} sets the confidence level; default is {cmd:c(level)} (usually 95) {p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it: ovars} and {it: pvars} may contain factor variables; see {help fvvarlists:fvvarlists}.{p_end}

{p 4 6 2}

{title:Description}

{pstd}
{opt drmmws} estimates doubly-robust effects of a binary treatment on an outcome, controlling for observed confounding variables (See Linden [2017a] for details of the method). 
{opt drmmws} uses weighted regression coefficients to compute averages (or medians) of each treatment group's predicted outcome distribution, with weights computed for each observation 
based on their actual treatment assignment and stratum (See Hong [2010, 2012], and Linden [2014]). The contrast of these averages (or medians) estimates the treatment effects. 
{opt drmmws} estimates the potential-outcome means (or medians) for each treatment group, and the average (or median) treatment effect (ATE, MTE), or the average (or median) 
treatment effect on the treated (ATT, MTT).

{pstd}
By default, standard errors are computed analytically using {cmd:margins} applied to each weighted GLM outcome model. The standard error of the treatment effect is then derived
using the delta method (square root of the sum of squared standard errors of the two potential outcome means). Results are displayed in the standard Stata coefficient table
with z-statistics, p-values, and confidence intervals.

{pstd}
Specifying the {opt bootstrap} option instead obtains standard errors, {it:p} values, and confidence intervals using a bootstrap procedure which incorporates estimation of both
the propensity score and outcome models.

{pstd}
{opt drmmws} requires the user-written program {help mmws} to be installed.


{title:Remarks}

{pstd}
 By default {opt drmmws} generates 5 quantiles of the propensity score (Rosenbaum & Rubin [1984] have shown that stratifying the propensity score into 5 quantiles 
can remove over 90% of the initial bias due to the covariates used to generate the propensity score). However, the user should consider identifying the optimal 
stratification solution for the specific data at hand. This can be accomplished by first running the user-written program {help pstrata} to determine how many quantiles
are necessary to achieve balance on the propensity score (Linden [2017b] found that {help pstrata} consistently achieved better covariate balance and reduced bias when compared
to 5 quantiles). Once the optimal number of quantiles has been determined, this value can be passed on to {opt drmmws} in the {opt nstrata()} option.

{pstd}
When {cmd:median} is specified without {cmd:bootstrap}, point estimates are displayed but standard errors are not available (quantile regression models do not support
{cmd:margins}). Use the {cmd:bootstrap} option to obtain standard errors for median treatment effects.



{title:Options}

{p 4 8 2}
{cmd:ovars(}{it:varlist}{cmd:)} specifies the covariates to be used in the outcome model. If no {it:ovars} are set, all the variables in {it:indepvars} are used. 

{p 4 8 2}
{cmd:pvars(}{it:varlist}{cmd:)} specifies the covariates to be used in the propensity score model. If no {it:pvars} are set, all the variables in {it:indepvars} are used. 

{p 4 8 2}
{cmd:nstrata(}{it:#}{cmd:)} specifies the number of quantiles of the propensity score to generate. The default is 5, however, the user should consider running {help pstrata} 
to determine the optimal number of quantiles for the given dataset.

{p 4 8 2}
{cmd:family(}{it:familyname}{cmd:)} uses the probability distribution of the generalized linear outcome model. See {help glm##familyname:familyname} for all available options.

{p 4 8 2}
{cmd:link(}{it:linkname}{cmd:)} is the link function of the generalized linear outcome model. See {help glm##linkname:linkname} for all available options.

{p 4 8 2}
{cmd:att} specifies that {opt drmmws} should estimate the average treatment effect on the treated (ATT). The default is to estimate the average treatment effect in the population (ATE).

{p 4 8 2}
{cmd:median} specifies that {opt drmmws} should estimate the median treatment effect (estimated using quantile regression). {opt median} can be combined with the {opt att} option to
estimate the median treatment effect on the treated (MTT). Note: standard errors are not available for median estimates without {cmd:bootstrap}.

{p 4 8 2}
{cmd:common} restricts the analysis to only those units within the region of common support. {opt drmmws} generates weights for those observations within the region of common 
	support, and gives a weight of zero to observations not on common support.  An indicator or dummy variable named _support is added to the dataset to identify the observations 
	on common support.

{p 4 8 2}
{cmd:bootstrap} requests that standard errors and confidence intervals be computed using a bootstrap procedure. Without this option, standard errors are derived analytically
using {cmd:margins}. The bootstrap incorporates uncertainty from both the propensity score and outcome model estimation steps.

{p 4 8 2}
{cmd:nodots} suppresses display of the replication dots that appear by default during bootstrap estimation. Only relevant when {cmd:bootstrap} is specified.

{p 4 8 2}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed for the bootstrap procedure. Only relevant when {cmd:bootstrap} is specified.
	
{p 4 8 2}
{cmd:reps(}{it:#}{cmd:)} specifies the number of bootstrap replications to be performed.  The default is 200.  A total of 50-200 replications are generally adequate for estimates of standard error
        and thus are adequate for normal-approximation confidence intervals; see Mooney and Duval [1993, 11].  Estimates of confidence intervals using the percentile or bias-corrected
        methods typically require 1,000 or more replications. Only relevant when {cmd:bootstrap} is specified.

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level as a percentage for confidence intervals. The default is {cmd:c(level)}, which is usually 95.


    
{title:Variables added to the dataset}

{pstd} {cmd:drmmws} generates several variables for the convenience of the user. These variables will be replaced automatically after each run, so rename them if you'd like to retain them:{p_end}

{p 5 15 15}{opt _strata} will be the result of the chosen option in {opt nstrata()}{p_end}

{p 5 17 15}{opt _support} is an indicator or dummy variable indicating whether an observation is on common support{p_end}

{p 5 17 15}{cmd:_mmws} is the weight generated by {cmd:drmmws}. The variable label will provide a brief description{p_end}
		
        

{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}

{pstd}Estimate the ATE of smoking on birthweight using margins-based standard errors (default){p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5)}

{pstd}Same model, but use bootstrap standard errors instead{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) bootstrap reps(500)}

{pstd}Assess the ATE as a percentage of the mean birthweight that would occur if no mothers smoke (works after default or bootstrap){p_end}
{phang2}{cmd:. nlcom _b[teffect] / _b[poms0]}

{pstd}Estimate the median treatment effect (point estimates only; use bootstrap for SEs){p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) median}

{pstd}Estimate median treatment effects with bootstrap standard errors{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) median bootstrap reps(1000)}

{pstd}Median treatment effects on the treated with common support and bootstrap SEs{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) att median common bootstrap reps(1000)}

{pstd}Get additional bootstrap confidence intervals (after bootstrap estimation){p_end}
{phang2}{cmd:. estat bootstrap, all}



{title:Saved results}

{pstd}
{cmd:drmmws} saves results in {cmd:e()}. Without the {cmd:bootstrap} option, the following are available:

{synoptset 25 tabbed}{...}
{p2col 5 25 29 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}sample size{p_end}

{p2col 5 25 29 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimated coefficients (poms1, poms0, teffect){p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}

{pstd}
With the {cmd:bootstrap} option, all standard {cmd:bootstrap} e() results are available; see {help bootstrap##saved_results:bootstrap saved results}.


{title:References}

{p 4 8 2}
Hong, G. 2010. Marginal mean weighting through stratification: adjustment for selection bias in multilevel data. 
{it:Journal of Educational and Behavioral Statistics} 35: 499-531.

{p 4 8 2}
Hong, G. 2012. Marginal mean weighting through stratification: a generalized method for evaluating multi-valued 
and multiple treatments with non-experimental data. {it:Psychological Methods} 17: 44-60.

{p 4 8 2}
Linden, A. 2014. Combining propensity score-based stratification and weighting to improve 
causal inference in the evaluation of health care interventions. {it:Journal of Evaluation in Clinical Practice} 20: 1065-1071.

{p 4 8 2}
Linden, A. 2017a. Improving casual inference with a doubly robust estimator that combines propensity score stratification and weighting. 
{it:Journal of Evaluation in Clinical Practice} DOI:10.1111/jep.12714

{p 4 8 2}
Linden, A. 2017b. A comparison of approaches for stratifying on the propensity score to reduce bias. 
{it:Journal of Evaluation in Clinical Practice} DOI:10.1111/jep.12701

{p 4 8 2}
Mooney, C. Z., and R. D. Duval. 1993. {browse "http://www.stata.com/bookstore/banasi.html":{it:Bootstrapping: A Nonparametric Approach to Statistical Inference}.}
Newbury Park, CA: Sage.

{p 4 8 2}
Rosenbaum P.R, and D. B. Rubin. 1984. Reducing bias in observational studies using subclassification on the propensity score. 
{it:Journal of the American Statistical Association} 79: 516-524.


{marker citation}{title:Citation of {cmd:drmmws}}

{p 4 8 2}{cmd:drmmws} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden, Ariel. 2017. 
drmmws: Stata module for implementing doubly-robust marginal mean weighting through stratification.{p_end}


{title:Author}

{p 4 4 2}
Ariel Linden{break}
alinden@lindenconsulting.org



{title:Acknowledgments} 

{p 4 4 2}
I wish to thank Chuck Huber for trouble-shooting an error in the bootstrap procedure, and to John Moran for beta-testing the program.{p_end}


{title:Also see}

{p 4 8 2}Online:  {helpb xtile}, {helpb glm}, {helpb margins}, {helpb teffects}, {helpb bootstrap}, {helpb mmws} (if installed), 
 {helpb pstrata} (if installed), {helpb covbal} (if installed) {p_end}


