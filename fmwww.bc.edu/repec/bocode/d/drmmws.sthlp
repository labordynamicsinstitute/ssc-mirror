{smcl}
{* *! version 3.0.0 27May2026}{...}
{* *! version 2.0.0 24May2026}{...}
{* *! version 1.0.0 06Jan2017}{...}

{title:Title}

{p2colset 5 15 17 2}{...}
{p2col:{hi:drmmws} {hline 2}} Doubly-robust marginal mean weighting through stratification{p_end}
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
{opt nstr:ata}({it:numlist})
{opt f:amily}({it:{help glm##familyname:familyname}})
{opt l:ink}({it:{help glm##linkname:linkname}})
{opt att}
{opt cont:rol}({it:# | label})
{opt med:ian}
{opt pom:eans}
{opt comm:on}
{opt boot:strap}
{opt nodots}
{opt seed}({it:integer})
{opt reps}({it:integer})
{opt lev:el}({it:#})
{opt coefl:egend} ]


{p 4 4 2}
For binary {it:treatvar}, the variable must be coded 0 (control) and 1 (treated).
For multivalued {it:treatvar}, values must be non-negative integers.

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt o:vars}{cmd:(}{it:{help varlist:varlist}}{cmd:)}}covariates in the outcome model{p_end}
{synopt:{opt p:vars}{cmd:(}{it:{help varlist:varlist}}{cmd:)}}covariates in the treatment assignment model{p_end}
{synopt:{opt nstr:ata}{cmd:(}{it:numlist}{cmd:)}}number of propensity score strata; default is {cmd:5}. For multivalued treatments, specify one 
value per treatment level or a single value applied to all levels{p_end}
{synopt:{opth f:amily(glm##familyname:familyname)}}distribution of the outcome variable; default is {cmd:family(gaussian)}{p_end}
{synopt:{opth l:ink(glm##linkname:linkname)}}link function; default is {cmd:link(identity)}{p_end}
{synopt:{opt att}}estimates average treatment effect on the treated (binary treatments only); default is the average treatment effect (ATE){p_end}
{synopt:{opt cont:rol}{cmd:(}{it:# | label}{cmd:)}}specifies the reference treatment level for multivalued treatments; default is the lowest level. May 
be specified as a numeric value or value label. Not allowed with {cmd:pomeans}{p_end}
{synopt:{opt med:ian}}estimates median treatment effects using quantile regression{p_end}
{synopt:{opt pom:eans}}displays potential outcome means for all treatment levels instead of treatment effects (multivalued treatments only){p_end}
{synopt:{opt comm:on}}restricts analysis to observations within the region of common support{p_end}
{synopt:{opt boot:strap}}requests bootstrap standard errors; default uses the delta method{p_end}
{synopt:{opt nodots}}suppresses bootstrap replication dots (only with {cmd:bootstrap}){p_end}
{synopt:{opt seed}{cmd:(}{it:#}{cmd:)}}sets the random-number seed for bootstrap{p_end}
{synopt:{opt reps}{cmd:(}{it:#}{cmd:)}}number of bootstrap replications; default is 200{p_end}
{synopt:{opt lev:el}{cmd:(}{it:#}{cmd:)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt coefl:egend}}display legend instead of statistics{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:ovars} and {it:pvars} may contain factor variables; see {help fvvarlists:fvvarlists}.{p_end}


{title:Description}

{pstd}
{opt drmmws} estimates doubly-robust treatment effects by combining propensity score stratification with weighted outcome regression, 
following the marginal mean weighting through stratification (MMWS) approach of Hong (2010, 2012) and Linden (2014, 2017a). It supports 
binary and multivalued (nominal) treatments, continuous and limited dependent variable outcomes, and a choice of analytic (delta-method) 
or bootstrap standard errors.

{pstd}
For {bf:binary treatments}, {opt drmmws} fits a logistic regression propensity score model, generates MMWS weights via {help mmws}, fits 
separate weighted GLM outcome models for each treatment arm, and computes potential outcome means (POMs) and the average treatment effect (ATE) 
or average treatment effect on the treated (ATT). Standard errors for the POMs are obtained using the delta method.

{pstd}
For {bf:multivalued treatments}, {opt drmmws} fits a multinomial logistic regression model to generate one propensity score per treatment 
level, passes these to {help mmws} with the {cmd:nominal} option, then fits a separate weighted GLM for each treatment level. By default, treatment 
effects for each non-reference level are displayed relative to the reference (control) level, along with the reference POM. Specifying {cmd:pomeans} 
instead displays all {it:K} potential outcome means.

{pstd}
The outcome model is a GLM with user-specified {cmd:family()} and {cmd:link()}. Fitted values are always returned on the {bf:response scale} 
(back-transformed through the inverse link), so treatment effects represent differences in predicted outcomes in the original units regardless 
of the link function chosen. For example, with {cmd:family(poisson) link(log)}, effects are differences in predicted counts; with {cmd:family(binomial) 
link(logit)}, effects are differences in predicted probabilities (risk differences).

{pstd}
Specifying {cmd:median} uses quantile regression ({help qreg}) at the 0.5 quantile instead of GLM to compute the average conditional median treatment 
effect. Standard errors are not available for median estimates without {cmd:bootstrap}.



{title:Remarks}

{pstd}
{bf:Propensity score stratification.} By default {opt drmmws} generates 5 quantiles of the propensity score. Rosenbaum and Rubin (1984) showed that 5 strata 
remove over 90% of bias due to observed covariates. The user-written program {help pstrata} can be used to determine the optimal number of strata for a 
given dataset (Linden 2017b), and the result passed to {opt nstrata()}.

{pstd}
For multivalued treatments, {opt nstrata()} accepts either a single value (applied to all treatment levels) or a space-separated list with one value per 
treatment level, e.g., {cmd:nstrata(5 7 8 10)} for a four-level treatment.

{pstd}
{bf:Outcome model and response scale.} All GLM families and links supported by Stata's {help glm} are accepted. Regardless of the link function, {cmd:predict} 
after {cmd:glm} returns fitted values on the response scale by default, so POMs and treatment effects are always expressed in the original outcome units. For 
binary outcomes, {cmd:family(binomial) link(logit)} is recommended for stability; {cmd:link(log)} with binomial fits a log-binomial model and may have convergence issues.

{pstd}
{bf:Median treatment effects.} When {cmd:median} is specified, {cmd:qreg} is used at q=0.5. Point estimates are the mean of the within-arm predicted median 
regression values. Standard errors require {cmd:bootstrap}.


{title:Options}

{p 4 8 2}
{cmd:ovars(}{it:varlist}{cmd:)} specifies covariates for the outcome model. Defaults to {it:indepvars} if not specified.

{p 4 8 2}
{cmd:pvars(}{it:varlist}{cmd:)} specifies covariates for the propensity score model. Defaults to {it:indepvars} if not specified.

{p 4 8 2}
{cmd:nstrata(}{it:numlist}{cmd:)} specifies the number of propensity score quantiles. Default is {cmd:nstrata(5)}. For multivalued treatments, 
provide one value per treatment level or a single value for all levels. Consider using {help pstrata} to determine the optimal number.

{p 4 8 2}
{cmd:family(}{it:familyname}{cmd:)} specifies the distributional family for the GLM outcome model. See {help glm##familyname:familyname} for 
options. Default is {cmd:gaussian}.

{p 4 8 2}
{cmd:link(}{it:linkname}{cmd:)} specifies the link function for the GLM outcome model. See {help glm##linkname:linkname} for options. Default 
is {cmd:identity}. Results are always returned on the response scale regardless of link.

{p 4 8 2}
{cmd:att} estimates the average treatment effect on the treated (ATT). Only available for binary treatments. 
Cannot be combined with multivalued treatments. The default is to compute the average treatment effect (ATE).

{p 4 8 2}
{cmd:control(}{it:# | label}{cmd:)} specifies the reference treatment level for multivalued treatments. Default is the lowest level 
(which is guaranteed to be 0 by {cmd:mmws} validation). May be specified as a numeric value or the value label associated with that 
level. Cannot be specified with {cmd:pomeans}.

{p 4 8 2}
{cmd:median} estimates median treatment effects using weighted quantile regression at q=0.5. Can be combined with {cmd:att} (binary only) to 
estimate the median treatment effect on the treated (MTT) or by default, the MTE. Standard errors are not available without {cmd:bootstrap}.

{p 4 8 2}
{cmd:pomeans} displays potential outcome means for all {it:K} treatment levels instead of treatment effects relative to the reference level. Only 
available for multivalued treatments. Cannot be combined with {cmd:control()}.

{p 4 8 2}
{cmd:common} restricts analysis to observations within the region of common support. Observations outside common support receive a weight of zero. An 
indicator variable {cmd:_support} is added to the dataset.

{p 4 8 2}
{cmd:bootstrap} requests bootstrap standard errors incorporating uncertainty from both the propensity score and outcome model steps. Without this 
option, standard errors are derived analytically using the delta method.

{p 4 8 2}
{cmd:nodots} suppresses the replication dots displayed during bootstrap estimation. Only relevant with {cmd:bootstrap}.

{p 4 8 2}
{cmd:seed(}{it:#}{cmd:)} sets the random-number seed for bootstrap. Only relevant with {cmd:bootstrap}.

{p 4 8 2}
{cmd:reps(}{it:#}{cmd:)} specifies bootstrap replications. Default is 200. At least 500-1,000 replications are recommended for reliable confidence 
intervals. Only relevant with {cmd:bootstrap}.

{p 4 8 2}
{cmd:level(}{it:#}{cmd:)} specifies the confidence level as a percentage. Default is {cmd:level(95)}.

{p 4 8 2}
{cmd:coeflegend} specifies that the legend of the coefficients and how to specify them in an expression be displayed
rather than displaying the statistics for the coefficients.


{title:Variables added to the dataset}

{pstd}{cmd:drmmws} generates the following variables, which are replaced automatically on each run:{p_end}

{p 5 17 15}{cmd:_strata} propensity score stratum indicator{p_end}
{p 5 17 15}{cmd:_support} indicator for observations on common support (with {cmd:common}){p_end}
{p 5 17 15}{cmd:_mmws} MMWS weight; variable label provides a brief description{p_end}


{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse cattaneo2, clear}

{pstd}{opt (1) Binary treatment:}{p_end}

{pstd}ATE of smoking on birthweight (delta-method SEs, default){p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5)}

{pstd}Same model with bootstrap SEs{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) bootstrap reps(500)}

{pstd}ATT with common support{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) att common}

{pstd}ATE expressed as a percentage of the control POM{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) coefl}

{pstd}ATE expressed as a percentage of the control POM (run {cmd:coeflegend} first to confirm names){p_end}
{phang2}{cmd:. nlcom _b[ATE:r1vs0.mbsmoke] / _b[POmean:0.mbsmoke]}

{pstd}Median treatment effect (point estimates only){p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) median}

{pstd}Median treatment effect with bootstrap SEs{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) median bootstrap reps(1000)}

{pstd}MTT (median treatment effect on the treated) with common support{p_end}
{phang2}{cmd:. drmmws bweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) att median common bootstrap reps(1000)}

{pstd}Binary outcome: risk differences using logistic GLM{p_end}
{phang2}{cmd:. drmmws lbweight mbsmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) family(binomial) link(logit)}

{pstd}{opt (2) Multivalued treatments:}{p_end}

{pstd}ATE of smoking intensity (4 levels) on birthweight — default output (treatment effects vs lowest level){p_end}
{phang2}{cmd:. drmmws bweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5)}

{pstd}Same model with bootstrap SEs{p_end}
{phang2}{cmd:. drmmws bweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) bootstrap reps(500)}

{pstd}Display all potential outcome means instead of treatment effects{p_end}
{phang2}{cmd:. drmmws bweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) pom}

{pstd}Specify different number of strata per treatment level{p_end}
{phang2}{cmd:. drmmws bweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5 7 8 10)}

{pstd}Median treatment effects for multivalued treatment, specifying coeflegend for post estimation {p_end}
{phang2}{cmd:. drmmws bweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) nstrata(5) median bootstrap reps(100) coefl}

{pstd}ATE expressed as a percentage of the control POM {p_end}
{phang2}{cmd:. nlcom _b[ATE:r1vs0.msmoke] / _b[POmean:0.msmoke]}

{pstd}Binary outcome with multivalued treatment: risk differences{p_end}
{phang2}{cmd:. drmmws lbweight msmoke, ovars(prenatal1 mmarried mage fbaby) pvars(mmarried c.mage##c.mage fbaby medu) family(binomial) link(logit) pom}



{title:Saved results}

{pstd}
{cmd:drmmws} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}estimated coefficients{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:drmmws}{p_end}
{synopt:{cmd:e(depvar)}}outcome variable name{p_end}
{synopt:{cmd:e(vcetype)}}{cmd:Robust} (delta-method), {cmd:Bootstrap}, or {cmd:Coefficient} (median without bootstrap){p_end}
{synopt:{cmd:e(title)}}estimation title{p_end}

{pstd}
With {cmd:bootstrap}, all standard bootstrap {cmd:e()} results are also available;
see {help bootstrap##saved_results:bootstrap saved results}.



{title:References}

{p 4 8 2}
Hong, G. 2010. Marginal mean weighting through stratification: adjustment for selection bias in multilevel data.
{it:Journal of Educational and Behavioral Statistics} 35: 499-531.

{p 4 8 2}
Hong, G. 2012. Marginal mean weighting through stratification: a generalized method for evaluating multivalued
and multiple treatments with non-experimental data. {it:Psychological Methods} 17: 44-60.

{p 4 8 2}
Linden, A. 2014. Combining propensity score-based stratification and weighting to improve
causal inference in the evaluation of health care interventions. {it:Journal of Evaluation in Clinical Practice} 20: 1065-1071.

{p 4 8 2}
Linden, A. 2017a. Improving causal inference with a doubly robust estimator that combines propensity score stratification and weighting.
{it:Journal of Evaluation in Clinical Practice} 23: 697-702.

{p 4 8 2}
Linden, A. 2017b. A comparison of approaches for stratifying on the propensity score to reduce bias.
{it:Journal of Evaluation in Clinical Practice} 23: 690-696.

{p 4 8 2}
Rosenbaum, P. R., and D. B. Rubin. 1984. Reducing bias in observational studies using subclassification on the propensity score.
{it:Journal of the American Statistical Association} 79: 516-524.


{marker citation}{title:Citation of {cmd:drmmws}}

{p 4 8 2}{cmd:drmmws} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such:{p_end}

{p 4 8 2}
Linden, Ariel. 2017.
drmmws: Stata module for doubly-robust marginal mean weighting through stratification. {p_end}


{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
{browse "mailto:alinden@lindenconsulting.org":alinden@lindenconsulting.org}{break}
{browse "http://www.lindenconsulting.org"}{p_end}


{title:Acknowledgments}

{p 4 4 2}
I wish to thank Chuck Huber for trouble-shooting an error in the bootstrap procedure, and to John Moran for beta-testing the program.{p_end}


{title:Also see}

{p 4 8 2}Online: {helpb xtile}, {helpb glm}, {helpb qreg}, {helpb mlogit}, {helpb margins}, {helpb teffects}, {helpb bootstrap},
{helpb mmws} (if installed), {helpb pstrata} (if installed), {helpb covbal} (if installed){p_end}

