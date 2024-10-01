{smcl}
{* *! Version 1.0.0 09 August 2017}{...}

{title:Title}

{p2colset 5 35 37 2}{...}
{p2col :{helpb nehurdle postestimation} {hline 4}}Postestimation tools 
for nehurdle{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
The following postestimation commands are available after {cmd:nehurdle}:

{synoptset 17 notes}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt:{helpb contrast}}contrasts and ANOVA-style joint tests of estimates{p_end}
{synopt:{helpb estat ic}}Akaike's and Schwarz's Bayesian information criteria
	(AIC and BIC){p_end}
{synopt:{helpb estat summarize}}summary statistics for the estimation sample{p_end}
{synopt:{helpb estat vce}}variance-covariance matrix of the estimators (VCE){p_end}
{synopt:{help svy estat: {bf:estat} (svy)}}postestimation statistics for survey
	data{p_end}
{synopt:{helpb estimates}}cataloging estimation results{p_end}
{synopt:{helpb lincom}}point estimates, standard errors, testing, and inference
	for linear combinations of coefficients{p_end}
{p2coldent:(1) {helpb lrtest}}likelihood-ratio test{p_end}
{synopt:{helpb margins}}marginal means, predictive margins, marginal effects,
	and average marginal effects{p_end}
{synopt:{helpb marginsplot}}graph the results from margins (profile plots,
	interaction plots, etc.){p_end}
{p2coldent:(1) {helpb nehtests}}Wald tests of joint significance of all the estimated
	equations, and the overall joint significance test{p_end}
{synopt:{helpb nlcom}}point estimates, standard errors, testing, and inference
	for nonlinear combinations of coefficients{p_end}
{synopt:{helpb nehurdle postestimation##predict:predict}}predictions,
	residuals, influence statistics, and other diagnostic measures{p_end}
{synopt:{helpb predictnl}}point estimates, standard errors, testing, and
	inference for generalized predictions{p_end}
{synopt:{helpb pwcompare}}pairwise comparisons of estimates{p_end}
{synopt:{helpb suest}}seemingly unrelated estimation{p_end}
{synopt:{helpb test}}Wald tests of simple and composite linear hypotheses{p_end}
{synopt:{helpb testnl}}Wald tests of nonlinear hypotheses{p_end}
{synoptline}
{p2colreset}{...}
{phang}
(1) {cmd:lrtest} and {cmd:nehtests} are not appropriate with {cmd:svy} estimation results.
{p_end}


{marker predict}{...}
{title:Syntax for predict}

{phang}
General syntax
{p_end}

{p 8 16 2}
{cmd:predict} {dtype} {newvar} {ifin} [{cmd:,} {it:statistic}]
{p_end}

{phang}
Syntax for scores
{p_end}

{p 8 16 2}
{cmd:predict} {dtype} {c -(}{it:stub*}{c |}{it:{help newvar:newvarlist}}{c )-}
{ifin}
{cmd:,} {opt sc:ores}
{p_end}

{pstd} The following lists the different statistics available with {cmd:predict},
in alphabetical order. Some will be available only with certain estimators. See
{helpb nehurdle_postestimation##options_predict:Options for Predict} for clarification
on which statistic is available with what estimator(s).

{synoptset 21 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{synopt :{opt alp:ha}}dispersion parameter{p_end}
{synopt :{opt lam:bda}}prediction of coefficient on inverse mills ratio
	(covariance of the errors across equations){p_end}

{synopt :{opt prc:en(a)}}probability that the observed variable takes on value
{it:a}{p_end}
{synopt :{opt prc:en(a,b)}}probability that the observed variable falls in the
range between {it:a} and {it:b}{p_end}
{synopt :{opt prc:en(.,b)}}probability that the observed variable less (or equal)
to {it:b}{p_end}
{synopt :{opt prc:en(a,.)}}probability that the observed variable is greater (or
equal) to {it:a}{p_end}

{synopt :{opt prs:tar(a)}}probability that the latent variable takes on value
{it:a}{p_end}
{synopt :{opt prs:tar(a,b)}}probability that the latent variable falls in the
range between {it:a} and {it:b}{p_end}
{synopt :{opt prs:tar(.,b)}}probability that the latent variable less (or equal)
to {it:b}{p_end}
{synopt :{opt prs:tar(a,.)}}probability that the latent variable is greater (or
equal) to {it:a}{p_end}

{synopt :{opt prt:run(a)}}probability that the truncated variable takes on value
{it:a}{p_end}
{synopt :{opt prt:run(a,b)}}probability that the truncated variable falls in the
range between {it:a} and {it:b}{p_end}
{synopt :{opt prt:run(.,b)}}probability that the truncated variable less (or equal)
to {it:b}{p_end}
{synopt :{opt prt:run(a,.)}}probability that the truncated variable is greater (or
equal) to {it:a}{p_end}

{synopt :{opt ps:el}}probability of being observed (selected) Pr(y>0){p_end}

{synopt :{opt resc:en}}observed variable residuals{p_end}
{synopt :{opt ressel}}residuals of prediction of probability of being observed{p_end}
{synopt :{opt ress:tar}}latent variable residuals{p_end}
{synopt :{opt rest:run}}truncated variable residuals{p_end}
{synopt :{opt resv:al}}residuals of linear prediction for value equation{p_end}

{synopt :{opt selsig:ma}}selection standard deviation{p_end}
{synopt :{opt sig:cen}}observed variable standard deviation{p_end}
{synopt :{opt sig:ma}}value equation standard deviation{p_end}
{synopt :{opt sig:star}}latent variable standard deviation{p_end}
{synopt :{opt sig:trun}}truncated variable standard deviation{p_end}

{synopt :{opt v:cen}}observed variable variance{p_end}
{synopt :{opt v:star}}latent variable variance{p_end}
{synopt :{opt v:trun}}truncated variable variance{p_end}

{synopt :{opt xba:lpha}}natural logarithm of the dispersion parameter fitted
	values{p_end}
{synopt :{opt xbs:el}}selection equation fitted values{p_end}
{synopt :{opt xbsels:ig}}linear prediction for natural logarithm of the standard
	deviation of selection equation{p_end}
{synopt :{opt xbsig}}natural logarithm of the standard deviation of the value
	equation fitted values{p_end}
{synopt :{opt xbv:al}}value equation fitted values{p_end}

{synopt :{opt yc:en}}{it:E}(y), observed variable mean; the default{p_end}
{synopt :{opt ys:tar}}{it:E}(y*), latent variable mean{p_end}
{synopt :{opt yt:run}}{it:E}(y*|y*>0), truncated variable mean{p_end}
{synoptline}

{marker options_predict}{...}
{title:Options for predict}

{phang}
{opt alpha} calculates the value of the dispersion parameter. Only available
ater estimation of NB1 and NB2 Truncated Hurdle models.

{phang}
{opt lambda} calculates the prediction of what some people call the coefficient
on inverse mills ratio. It is a prediction of the covariance of the errors
of both equations (selection and value). It is calculated by multiplying the
prediction of the standard deviation of the selection equation times the
prediction of the standard deviation of the value equation times the estimate
of the correlation of the errors of both equations. Only available after
estimation of Type II Tobit models.

{phang}
{opt prcen(a)} calculates the probability that the observed variable equals {it:a},
Pr(y=a). Available after estimation of any model.

{pmore} {it:a} can be either a value, or a numeric variable.

{pmore}After estimation of Tobit, Normal Hurdle, and Type II Tobit models, the
only value {it:a} can take is 0, because that is where there is some mass. Any
other value will return an error, so it doesn't make sense to pass a variable
for this case in those models.

{phang}
{opt prcen(a,b)} calculates the probability that the observed variable falls in
range bounded by {it:a}, in the lower end, and {it:b}, in the upper end. Available
after estimation of any model.

{pmore} {it:a} and {it:b} can be either values, or numeric variables, or any
combination of those, i.e. one can be one type and the other the other.

{pmore}After estimation of models for continuous variables, the range is an open
one, so it calculates Pr(a<y<b).

{pmore}After estimation of models for count data (discrete variables), the range
is a closed one, so it calculates Pr(a<=y<=b)

{phang}
{opt prcen(.,b)} calculates the probability that the observed variable is less
(or equal) to {it:b}. Available after estimation of any model.

{pmore} {it:b} can be either a value, or a numeric variable.

{pmore}After estimation of models for continuous variables, it is the probability
that y is less than {it:b} Pr(y<b).

{pmore}After estimation of models for count data (discrete variables), it is the
probability of less or equal to {it:b}, Pr(y<=b).

{phang}
{opt prcen(a,.)} calculates the probability that the observed variable is greater
(or equal) to {it:a}. Available after estimation of any model.

{pmore} {it:a} can be either a value, or a numeric variable.

{pmore}After estimation of models for continuous variables, it is the probability
that y is greater than {it:a} Pr(y>a).

{pmore}After estimation of models for count data (discrete variables), it is the
probability of greater or equal to {it:a}, Pr(y>=a).

{phang}
{opt prstar(a)} calculates the probability that the latent variable equals
{it:a}, Pr(y*=a). Available after estimation of models for count data, only:
Poisson truncated hurdle, and NB1 and NB2 truncated hurdle.

{pmore} {it:a} can be either a value, or a numeric variable.

{phang}
{opt prstar(a,b)} calculates the probability that the latent variable falls in
range bounded by {it:a}, in the lower end, and {it:b}, in the upper end. Available
after estimation of any model.

{pmore} {it:a} and {it:b} can be either values, or numeric variables, or any
combination of those, i.e. one can be one type and the other the other.

{pmore}After estimation of models for continuous variables, the range is an open
one, so it calculates Pr(a<y*<b).

{pmore}After estimation of models for count data (discrete variables), the range
is a closed one, so it calculates Pr(a<=y*<=b)

{phang}
{opt prstar(.,b)} calculates the probability that the latent variable is less
(or equal) to {it:b}. Available after estimation of any model.

{pmore} {it:b} can be either a value, or a numeric variable.

{pmore}After estimation of models for continuous variables, it is the probability
that y is less than {it:b} Pr(y*<b).

{pmore}After estimation of models for count data (discrete variables), it is the
probability of less or equal to {it:b}, Pr(y*<=b).

{phang}
{opt prstar(a,.)} calculates the probability that the latent variable is greater
(or equal) to {it:a}. Available after estimation of any model.

{pmore} {it:a} can be either a value, or a numeric variable.

{pmore}After estimation of models for continuous variables, it is the probability
that y is greater than {it:a} Pr(y*>a).

{pmore}After estimation of models for count data (discrete variables), it is the
probability of greater or equal to {it:a}, Pr(y*>=a).

{phang}
{opt prtrun(a)} calculates the probability that the latent variable equals
{it:a}, Pr(y*=a|y*>0). Available after estimation of models for count data
only: Poisson truncated hurdle, and NB1 and NB2 truncated hurdle.

{pmore} {it:a} can be either a value, or a numeric variable.

{phang}
{opt prtrun(a,b)} calculates the probability that the truncated variable falls in
range bounded by {it:a}, in the lower end, and {it:b}, in the upper end.
Available after estimation of any model {it:{cmd: except}} the Lognormal
Hurdle,	because there is no possible truncation in that model.

{pmore} {it:a} and {it:b} can be either values, or numeric variables, or any
combination of those, i.e. one can be one type and the other the other.

{pmore}After estimation of models for continuous variables, the range is an open
one, so it calculates Pr(a<y*<b|y*>0).

{pmore}After estimation of models for count data (discrete variables), the range
is a closed one, so it calculates Pr(a<=y*<=b|y*>0)

{phang}
{opt prtrun(.,b)} calculates the probability that the latent variable is less
(or equal) to {it:b}.Available after estimation of any model {it:{cmd: except}}
the Lognormal Hurdle, because there is no possible truncation in that model.

{pmore} {it:b} can be either a value, or a numeric variable.

{pmore}After estimation of models for continuous variables, it is the probability
that y is less than {it:b} Pr(y*<b|y*>0).

{pmore}After estimation of models for count data (discrete variables), it is the
probability of less or equal to {it:b}, Pr(y*<=b|y*>0).

{phang}
{opt prtrun(a,.)} calculates the probability that the latent variable is greater
(or equal) to {it:a}. Available after estimation of any model {it:{cmd: except}}
the Lognormal Hurdle, because there is no possible truncation in that model.

{pmore}After estimation of models for continuous variables, it is the probability
that y is greater than {it:a} Pr(y*>a|y*>0).

{pmore} {it:a} can be either a value, or a numeric variable.

{pmore}After estimation of models for count data (discrete variables), it is the
probability of greater or equal to {it:a}, Pr(y*>=a|y*>0).

{phang}
{opt psel} calculates the probability of being observed (selected), i.e. Pr(y>0).
Available after estimation of any model.

{phang}
{opt rescen} calculates the residuals of the observed variable. That is y -
{it:E}(y), where {it:E}(y) is the observed variable mean you get with the
{opt ycen} statistic. Available after estimation of any model.
	
{phang}
{opt ressel} residuals of the prediction of probability of being observed. This
is calculated as the difference between the dummy variable that identifies
whether y > 0, and the probability of being observed from {opt psel}.
Available after estimation of any model.

{phang}
{opt resstar} calculates the residuals of the latent variable. That is y -
{it:E}(y*), where {it:E}(y*) is the latent variable mean you get with the
{opt ystar} statistic. Available after estimation of any model.

{phang}
{opt restrun} calculates the residuals of the truncated mean. That is y - 
{it:E}(y*|y*>0), where {it:E}(y*|y*>0) is the truncated variable mean you
get with the {opt ytrun} option. Available after estimation of any model.

{phang}
{opt resval} calculates the residuals against the linear prediction for value
equation that you would get with {opt xbval}. Available only after estimation
of models for continuous variables.
	
{pmore} After the esitmation of a lognormal specification, these residuals are
limited to those observations with a positive value of y, since ln(y) is
indeterminate for those observations where y = 0.

{phang}
{opt selsigma} calculates the standard deviation of the selection equation.
Available after estimation of models that model heteroskedasticity in the
selection equation.
	
{pmore}This is calculated by taking the exponential of the fitted values of the
natural logarithm of the selection standard deviation from {opt xbselsig}.

{phang}
{opt sigcen} calculates the standard deviation of the observed variable.
Available after estimation of any model.

{pmore}This is the square root of the variance of the observed variable from
{opt vcen}
	
{phang}
{opt sigma} calculates the tandard deviation of the value equation. Available
only after estimation of models for continuous variables.
	
{pmore}It is the exponential of the fitted values of the natural logarithm
of the standard deviation of the value equation from {opt xbsig}.

{phang}
{opt sigstar} calculates the standard deviation of the latent variable.
Available after estimation of any model.

{pmore}This is the square root of the variance of the observed variable from
{opt vstar}

{phang}
{opt sigtrun} calculates the standard deviation of the truncated variable.
Available after estimation of any model {it:{cmd: except}} the Lognormal
Hurdle,	because there is no possible truncation in that model.

{pmore}This is the square root of the variance of the observed variable from
{opt vtrun}

{phang}
{opt vcen} calculates the variance of the observed variable. Available after
estimation of any model.

{phang}
{opt vstar} calculates the variance of the latent variable. Available after
estimation of any model.

{phang}
{opt vtrun} calculates the variance of the truncated variable. Available after
estimation of any model {it:{cmd: except}} the Lognormal Hurdle,
because there is no possible truncation in that model.

{phang}
{opt xbalpha} calculates the fitted values for the natural log the dispersion
parameter. Only available ater estimation of NB1 and NB2 Truncated Hurdle models.

{phang}
{opt xbsel} calculates fitted values of the selection equation. Available after
estimation of any model {it:{cmd: except}} Tobit models, because the selection
process is not separate there.

{phang}
{opt xbselsig} calculates the fitted values of the natural logarithm of the
standard deviation of selection equation. Only available if you have modeled
heteroskedasticity in the selection equation. So not available after Tobit models.

{phang}
{opt xbsig} calculates the linear prediction for natural logarithm of the
standard deviation of the value equation. Available only after models for
continuous variables.

{pmore}For homoskedastic value equations, this will be equal to the coefficient
on /lnsigma. If you have modeled heteroskedasticity in the value equation, the
prediction will vary across observations.

{phang}
{opt xbval} calculates the fitted values of the value equation. Available after
estimation of any model.

{phang}
{opt ycen} calculates the observed variable mean. Available after estimation of
any model.

{pmore}This is the default statistic to be estimated, so it is the one that will
be calculated when you don't specify a statstic at all.

{phang}
{opt ystar} calculates the latent variable mean. Available after estimation of
any model.

{phang}
{opt ytrun} calculates the truncated variable mean. Available after
estimation of any model {it:{cmd: except}} the Lognormal Hurdle,
because there is no possible truncation in that model.

{title:Note When Using {helpb margins:margins}}.

{pstd}You will need to use the {opt force} option with {cmd:margins} when passing
variables to the different probabilities statistics that accept them, to avoid
an error from {cmd:Stata} about stochastic quantities other than {cmd:e(b)}.

{pstd}You will also need to use the {opt force} option with {cmd:margins} after
a Lognormal Tobit estimation, to avoid the same error.

{pstd}There is nothing wrong with the calculations of the different statistics
in those cases, but {cmd:margins} throws an error when the calculation of a
statistic imports values or variables outside those of the model.

{marker examples}{...}
{title:Examples}

{dlgtab:Models for Continuous Variables}

{pstd}Data Setup{p_end}
{phang2}. {stata "webuse womenwk, clear"}{p_end}
{phang2}. {stata "replace wage = 0 if missing(wage)"}{p_end}
{phang2}. {stata "global xvars i.married children educ age"}{p_end}

{pstd}Homoskedastic Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, tobit nolog"}{p_end}
{phang2}. {stata "margins, dydx(*)"} // AMEs on observed variable mean{p_end}
{phang2}. {stata "margins, dydx(*) predict(ytrun)"} // AMEs on truncated variable mean{p_end}

{pstd}Heteroskedastic Exponential Truncated Hurdle{p_end}
{phang2}. {stata "nehurdle wage $xvars, expon het($xvars) nolog"}{p_end}
{phang2}. {stata "margins, dydx(*) predict(ystar)"} // AMEs on latent variable mean{p_end}
{phang2}. {stata "margins, dydx(*) predict(sigma)"} // AMEs on the standard deviation of value equation{p_end}
{phang2}. {stata "predict rsel, rescen"} // Residuals of the observed variable.{p_end}

{pstd}Heteroskedastic Exponential Type II Tobit{p_end}
{phang2}. {stata "nehurdle wage $xvars, heckman expon het($xvars) nolog"}{p_end}
{phang2}. {stata "margins, dydx(*) predict(vcen)"} // AMEs on observed variable variance{p_end}
{phang2}. {stata "margins, predict(lambda)"} // Estimate of the coefficient on inverse-mills ratio{p_end}
{phang2}. {stata "margins, predict(prc(2,10))"} // Average probability the observed variable falls in (2,10){p_end}

{dlgtab:Models for Count Data}

{pstd}Data Setup{p_end}
{phang2}. {stata "use http://www.stata-press.com/data/mus2/mus220mepsdocvis, clear"}{p_end}
{phang2}. {stata global xvars i.private i.medicaid age educyr i.actlim totchr}{p_end}
{phang2}. {stata global shet income age totchr}{p_end}
{phang2}. {stata global ahet age totchr i.female}{p_end}

{pstd}Poisson Truncated Hurdle:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncp nolog"}{p_end}
{phang2}. {stata "margins, dydx(*) predict(sigtrun)"} // AMEs on truncated variable standard deviation{p_end}
{phang2}. {stata "margins, predict(prc(5))"} // Average probability that the observed variable equals 5{p_end}

{pstd}NB1 Truncated Hurdle with dispersion heterogeneity:{p_end}
{phang2}. {stata "nehurdle docvis $xvars, truncnb1 nolog het($ahet)"}{p_end}
{phang2}. {stata "margins, dydx(*) predict(alpha)"} // AMEs on the dispersion parameter{p_end}
{phang2}. {stata "margins, predict(alpha)"} // Average dispersion parameter{p_end}

{pstd}NB2 Truncated Hurdle:{p_end}
{phang2}. {stata nehurdle docvis $xvars, truncnb2 nolog}{p_end}
{phang2}. {stata "margins, dydx(*)"} // AMEs on observed variable mean{p_end}
{phang2}. {stata "margins, predict(prc(.,10))"} // Average probability the observed variable is less or equal to 10{p_end}
{phang2}. {stata "margins, predict(prc(11,.))"} // Average probability the observed variable is greater or equal to 11{p_end}

