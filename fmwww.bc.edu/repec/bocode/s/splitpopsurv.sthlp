{smcl}
{* *! version 1.0.0  22sep2026}{...}
{viewerjumpto "Syntax" "splitpopsurv##syntax"}{...}
{viewerjumpto "Description" "splitpopsurv##description"}{...}
{viewerjumpto "Options" "splitpopsurv##options"}{...}
{viewerjumpto "The model" "splitpopsurv##model"}{...}
{viewerjumpto "A correction to the original ml template" "splitpopsurv##correction"}{...}
{viewerjumpto "Stored results" "splitpopsurv##stored"}{...}
{viewerjumpto "predict" "splitpopsurv##predict"}{...}
{viewerjumpto "Examples" "splitpopsurv##examples"}{...}
{viewerjumpto "Author" "splitpopsurv##author"}{...}
{viewerjumpto "References" "splitpopsurv##references"}{...}
{title:Title}

{phang}
{bf:splitpopsurv} {hline 2} Split-population (cure / mover-stayer) survival models


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:splitpopsurv}
{it:timevar} [{it:indepvars}] {ifin}{cmd:,}
{cmdab:fail:ure(}{it:varname}{cmd:)}
{cmdab:cure(}{it:varlist}{cmd:)}
{cmdab:dist:ribution(}{it:distname}{cmd:)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt fail:ure(varname)}}0/1 event indicator: 1 = event observed, 0 = censored{p_end}
{synopt:{opt cure(varlist)}}covariates for the P_regression equation (the cure/stayer probability){p_end}
{synopt:{opt dist:ribution(distname)}}baseline timing distribution for "movers": {cmd:loglogistic}, {cmd:weibull}, {cmd:lognormal}, {cmd:gamma}, or {cmd:ggamma}{p_end}

{syntab:Optional}
{synopt:{opt gr:oup(varname)}}0/1 indicator that flips which side of the P_regression logit is used for {it:p} (see {help splitpopsurv##model:The model}); default is a constant of 1{p_end}
{synopt:{opt noconstant}}suppress the constant in the H_regression equation{p_end}
{synopt:{opt tech:nique(algorithm)}}optimization technique passed to {helpb ml}; default is {cmd:bfgs}{p_end}
{synopt:{opt iter:ate(#)}}maximum iterations; default is {cmd:iterate(300)}{p_end}
{synopt:{opt nol:og}}suppress the iteration log{p_end}
{synopt:{opt dif:ficult}}use the {helpb ml}{cmd: difficult} step algorithm{p_end}
{synopt:{opt lev:el(#)}}confidence level; default is {cmd:level(95)}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
{it:indepvars} may contain factor variables; see {help fvvarlist}.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:splitpopsurv} fits a split-population (also called a "cure" or
"mover-stayer") survival model by maximum likelihood. It combines an
accelerated failure-time regression for event timing among "movers" (the
{it:H_regression} equation, on {it:timevar} and {it:indepvars}) with a
logistic regression on the probability of belonging to a structurally
immune "stayer" population (the {it:P_regression} equation, on
{cmd:cure()}). Five baseline distributions are available for the timing
part; see {help splitpopsurv##model:The model} below.

{pstd}
{cmd:splitpopsurv} is a translation into a proper Stata command of a
widely-circulated set of {helpb ml} programs (variously named {cmd:SphLog},
{cmd:SphWieb}, {cmd:SphNom}, {cmd:SphGam}, {cmd:SphGGam}) implementing the
split-population survival models of Schmidt and Witte (1989) and the
mover-stayer accelerated failure-time models of Yamaguchi (1992, 1998). It
fixes a log-likelihood error present in that original template; see
{help splitpopsurv##correction:A correction to the original ml template}.

{pstd}
An R package implementing the same corrected models, with a fuller written
derivation of the correction, is available as a companion at
{browse "https://github.com/nobifukuda/splitpopsurv":github.com/nobifukuda/splitpopsurv}
(R) and {browse "https://github.com/nobifukuda/splitpopsurv-stata":github.com/nobifukuda/splitpopsurv-stata}
(this Stata package).


{marker options}{...}
{title:Options}

{phang}
{opt failure(varname)} specifies the 0/1 event indicator: 1 if the
event (failure) was observed, 0 if the observation is censored. Required.

{phang}
{opt cure(varlist)} specifies the covariates entering the P_regression
(cure/stayer probability) equation. Required. May be an empty option,
{cmd:cure()}, to fit an intercept-only cure probability.

{phang}
{opt distribution(distname)} chooses the baseline timing distribution for
movers. {it:distname} is one of {cmd:loglogistic}, {cmd:weibull},
{cmd:lognormal}, {cmd:gamma}, or {cmd:ggamma} (generalized gamma); short
forms {cmd:ll}, {cmd:weib}, {cmd:lnorm}, and {cmd:gengamma} are also
accepted. Required.

{phang}
{opt group(varname)} is a 0/1 indicator that flips which side of the
P_regression logistic curve is used for the cure probability {it:p}: when
{it:varname}{cmd:==1}, {it:p} = invlogit(P_regression index); when
{it:varname}{cmd:==0}, {it:p} = 1 {char 45} invlogit(P_regression index).
This mirrors the original template's {cmd:$ML_y3} handling and matters
only if your data genuinely distinguishes two such groups. If omitted,
{cmd:splitpopsurv} uses a constant of 1 for every observation, so {it:p} =
invlogit(P_regression index) throughout (the ordinary case).

{phang}
{opt noconstant} suppresses the constant term in the H_regression equation
only. (The P_regression equation always keeps its own constant.)

{phang}
{opt technique(algorithm)}, {opt iterate(#)}, {opt nolog}, {opt difficult},
and {opt level(#)} are passed through to {helpb ml maximize}. The default
technique is {cmd:bfgs}, which was found in testing to converge more
reliably than Newton-Raphson for these models; see
{help splitpopsurv##correction:the correction note} for why the
{it:as-written original} log-likelihood can fail to converge at all.


{marker model}{...}
{title:The model}

{pstd}
Let {it:S}{sub:m}{cmd:(}{it:t}{cmd:)} and {it:f}{sub:m}{cmd:(}{it:t}{cmd:)}
be the survival and density functions for "movers" (susceptible
subjects), and {it:p} the probability of being a "stayer" (structurally
immune). The marginal (population) survival and density are

{p 8 8 2}{it:S}{cmd:(}{it:t}{cmd:)} = (1 {char 45} {it:p}) {it:S}{sub:m}{cmd:(}{it:t}{cmd:)} + {it:p}{p_end}
{p 8 8 2}{it:f}{cmd:(}{it:t}{cmd:)} = (1 {char 45} {it:p}) {it:f}{sub:m}{cmd:(}{it:t}{cmd:)}{p_end}

{pstd}
so that {it:S}{cmd:(}{it:t}{cmd:)} approaches {it:p} as {it:t} approaches
infinity: the surviving fraction. {it:p} follows a logistic regression on
{cmd:cure()} (the P_regression equation), and log({it:T}) for movers
follows an accelerated failure-time regression on {it:indepvars} (the
H_regression equation), with the error distribution set by
{cmd:distribution()}. For the generalized gamma, the error term follows
the extended log-gamma distribution of Prentice (1974), which nests the
Weibull (kappa=1), log-normal (kappa=0), and gamma (sigma=1) special
cases fit by the other four {cmd:distribution()} choices.

{pstd}
The log-likelihood contribution per subject {it:i} is

{p 8 8 2}{it:L}{sub:i} = {it:delta}{sub:i} log {it:f}{cmd:(}{it:t}{sub:i}{cmd:)} + (1 {char 45} {it:delta}{sub:i}) log {it:S}{cmd:(}{it:t}{sub:i}{cmd:)}{p_end}

{pstd}
where {it:delta}{sub:i} is {cmd:failure()}. This is the standard
hazard-based survival log-likelihood (Yamaguchi 1998, eq. 2{char 45}3).


{marker correction}{...}
{title:A correction to the original ml template}

{pstd}
The widely-circulated Stata {cmd:ml} template this command is based on
computes a quantity named {cmd:hz2}/{cmd:mhz} as
(1{char 45}{it:p})*hazard{sub:m}(t)*survival{sub:m}(t), then evaluates

{p 8 8 2}{cmd:lnf = $ML_y2*ln(hz2) + ln(sv2)}{p_end}

{pstd}
Algebraically, (1{char 45}{it:p})*hazard{sub:m}(t)*survival{sub:m}(t) is
the marginal {bf:density} {it:f}{cmd:(}{it:t}{cmd:)}, not the marginal
{bf:hazard} {it:h}{cmd:(}{it:t}{cmd:)} = {it:f}{cmd:(}{it:t}{cmd:)} /
{it:S}{cmd:(}{it:t}{cmd:)} (the template never divides by the marginal
survival). Plugged into {it:delta}*log(hazard) + log(survival) -- the
standard combined form -- using density in place of hazard double-counts
log {it:S}{cmd:(}{it:t}{sub:i}{cmd:)} for every observed event.

{pstd}
This was confirmed by simulation: fitting 20,000 observations from a
known-parameter split-population Weibull model, the as-written formula
converges to visibly biased estimates (or, with {cmd:ml}'s default
technique, sometimes fails to converge at all, {cmd:r(430)}), while the
corrected formula implemented in this command recovers the true
parameters closely. {cmd:splitpopsurv} implements the correction
throughout, written as {it:delta}*log({it:f}) + (1{char 45}{it:delta})*log({it:S})
-- which is also more numerically robust, since it never forms
hazard = density / survival and so cannot hit an "{it:Inf} times 0"
missing-value trap when survival underflows to exactly 0 in floating
point at extreme durations.


{marker stored}{...}
{title:Stored results}

{pstd}
{cmd:splitpopsurv} stores the following in {cmd:e()}, in addition to the
usual results from {helpb ml maximize}.

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:splitpopsurv}{p_end}
{synopt:{cmd:e(distribution)}}the fitted {cmd:distribution()} choice{p_end}
{synopt:{cmd:e(depvar)}}{it:timevar}{p_end}
{synopt:{cmd:e(failure)}}the {cmd:failure()} variable{p_end}
{synopt:{cmd:e(cure)}}the {cmd:cure()} varlist{p_end}
{synopt:{cmd:e(groupvar)}}the {cmd:group()} variable, if supplied{p_end}
{synopt:{cmd:e(predict)}}{cmd:splitpopsurv_p}{p_end}


{marker predict}{...}
{title:predict}

{p 8 17 2}
{cmd:predict} [{it:type}] {it:newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt su:rvival}}predicted marginal survival {it:S}{cmd:(}{it:t}{cmd:)}, evaluated at each observation's own {it:timevar}; the default{p_end}
{synopt:{opt pc:ure}}predicted cure (stayer) probability {it:p}{p_end}
{synopt:{opt xb}}the fitted H_regression linear predictor{p_end}
{synoptline}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse cancer, clear}{p_end}

{pstd}Weibull split-population model, cure probability depends on drug{p_end}
{phang2}{cmd:. splitpopsurv studytime age, failure(died) cure(i.drug) distribution(weibull)}{p_end}

{pstd}Predicted survival, cure probability, and linear index{p_end}
{phang2}{cmd:. predict S_hat}{p_end}
{phang2}{cmd:. predict p_hat, pcure}{p_end}
{phang2}{cmd:. predict xb_hat, xb}{p_end}

{pstd}Generalized gamma, with a slower but more careful optimizer{p_end}
{phang2}{cmd:. splitpopsurv studytime age, failure(died) cure(i.drug) distribution(ggamma) technique(nr) iterate(500)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Nobutaka Fukuda, Tohoku University{break}
{browse "mailto:nobutaka.fukuda@tohoku.ac.jp":nobutaka.fukuda@tohoku.ac.jp}


{marker references}{...}
{title:References}

{phang}
Prentice, R. L. 1974. A log gamma model and its maximum likelihood
estimation. {it:Biometrika} 61(3): 539{char 45}544.

{phang}
Schmidt, P., and A. D. Witte. 1989. Predicting criminal recidivism using
"split population" survival time models. {it:Journal of Econometrics}
40(1): 141{char 45}159.

{phang}
Yamaguchi, K. 1992. Accelerated failure-time regression models with a
regression model of surviving fraction: An application to the analysis of
"permanent employment" in Japan. {it:Journal of the American Statistical
Association} 87(418): 284{char 45}292.

{phang}
Yamaguchi, K., and L. R. Ferguson. 1995. The stopping and spacing of
childbirths and their birth-history predictors: Rational-choice theory
and event-history analysis. {it:American Sociological Review} 60(2):
272{char 45}298.

{phang}
Yamaguchi, K. 1998. Mover-stayer models for analyzing event nonoccurrence
and event timing with time-dependent covariates: An application to an
analysis of remarriage. {it:Sociological Methodology} 28(1): 327{char 45}361.
