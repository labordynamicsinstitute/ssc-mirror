{smcl}
{hline}
help for {cmd:srslogit}{right:(Roger Newson)}
{hline}

{title:Logit regression with secondary ridit splines}

{p 8 21 2}
{cmd:srslogit} {depvar}
[{indepvars}]
{weight}
{ifin}
[,
  {opth ppro:bability(newvar)}
  {opth pxb(newvar)}
  {opth pipw:eight(newvar)}
  {break}
  {opt nosrs:pline}
  {break}
  {opth pow:er(#)}
  {opth refp:ts(numlist)}
  {opth rid:it(newvar)}
  {break}
  {opth spro:b(newvar)}
  {opth sxb(newvar)}
  {opth sipw:eight(newvar)}
  {opth rrs:pline(prefix)}
  {break}
  {opt nocons:tant}
  {help glm:{it:glm_options}}
]

{pstd}
where {it:prefix} is a prefix for generated variables containing the {help bspline:ridit reference splimes},
and {it:glm_options} are options for {helpb glm},
other than the {cmd:noconstant}, {cmd:asis}, {cmd:family()}, and {cmd:link()} options.

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.
They are interpreted as weights of the same kinds with {helpb glm}.


{title:Description}

{pstd}
{cmd:srslogit} fits a primary logit model for a binary dependent variable
in a list of independent variables,
followed optionally by a secondary ridit spline model for the same binary dependent variable
in the ridit of the predicted dependent variable
from the primary logit model.
It optionally outputs variables created in this process,
including the predicted values (also known as propensity scores)
and inverse probability weights (also known as inverse propensity weights)
from the primary and secondary logit models.
These propensity weights may be used as treatment propensity weights
(if the dependent variable is a treatment indicator)
or as completeness-propensity weights
(if the dependent variable is a completeness indicator).
{cmd:srslogit} uses the {help ssc:SSC} packages {helpb wridit} and {helpb bspline},
which have to be installed in order for {cmd:srslogit} to run.


{title:Options}

{phang}
{opth pprobability(newvar)}, {opth pxb(newvar)}, and {opth pipweight(newvar)}
specify the names of optional generated output variables,
to contain the predicted probabilities, predicted odds, and inverse probability weights,
respectively,
of an outcome of 1 from the primary logit model.
The inverse probability weight corresponding to a perdicted probability {cmd:pprobability}
and an outcome value of 0 or 1
is {cmd:a_1/pprobability} if the outcome is 1,
and {cmd:a_0/(1-pprobability)} if the outcome is 0,
where {cmd:a_0} and {cmd:a_1} are stabilization factors,
equal to the overall probabilities that the outcome variable is 0 or 1,
respectively.
Inverse probability weights can be used as inverse treatment probability weights
for estimation of the average treatment effects for the whole sample,
if the outcome is a treatment indicator,
or as inverse completeness probability weights for the subsample with outcome 1,
if the outcome is a completeness indicator.

{phang}
{opt nosrspline} specifies that the secondary ridit spline will not be fitted.
If {cmd:nosrspline} is specified,
then the options {cmd:power()}, {cmd:refpts()},
{cmd:ridit()}, {cmd:sprobability()}, {cmd:sxb()}, {cmd:sipweight()},
and {cmd:rrspline()}
will be ignored.

{phang}
{opth power(#)} specifies the power (or degree) of the fitted secondary ridit spline.
The default is {cmd:power(3)}, specifying a cubic secondary ridit spline.

{phang}
{opth refpts(numlist)} specifies an ascending list of percentage ridits (between 0 and 100 inclusively)
to be used as reference points for the secondary ridit spline
in the ridit of the primary predictor.
The default is {cmd:refpts(0 25 50 75 100)},
specifying a spline with reference points at percents 0, 25, 50 75, and 100,
corresponding to percentiles 0 (the minimum), 25, 50, 75, and 100 (the maximum)
of the predicted proportion of individuals with outcome 1
from the primary logit model.

{phang}
{opth ridit(newvar)} specifies an optional generated output variable,
containing the ridits of the predicted probabilities from the primary logit model,
used for generating the ridit spline used to define the secondary ridit spline logit model.

{phang}
{opth sprobability(newvar)}, {opth sxb(newvar)}, and {opth sipweight(newvar)}
specify the names of optional generated output variables,
to contain the predicted probabilities, predicted odds, and inverse probability weights,
respectively,
of an outcome of 1 from the secondary ridit spline logit model.

{phang}
{opth rrspline(prefix)} specifies a prefix for the names Of optional generated outpu/t variables,
to contain the reference ridit spline basis used to fit the secondary ridit spline logit model.
If the user specifies {cmd:rrspline({it:prefix})},
then the generated reference ridit spline basis variables have names numbered {cmd:{it:prefix}_i},
for {cmd:i} from 1 to the number of reference points specified by the {cmd:refpts()} option.


{title:Methods and formulas}

{pstd}
{cmd:srslogit} works by first fitting a primary logit regression model,
fitted using {helpb glm},
with the outcome specified by the input {depvar}
and covariates specified by the input {indepvars},
and then computes the predicted probabilities, predicted odds, and inverse probability weights
for that primary model.
If {cmd:nosrspline} is not specified,
it then proceeds to the secondary ridit spline model.
To do this,
it first computes the percentage ridits of the predicted odds from the primary model
using the {help ssc:SSC} package {helpb wridit},
and then using the {helpb flexcurv} module of the {help ssc:SSC} package {helpb bspline}
to compute a reference spline basis in the percentage ridits,
with reference points on a percentage scale specified by the {cmd:refpts()} option.
This reference spline basis is then used as the covariates for a second {helpb glm} command,
with the {cmd:noconstant} option,
so that the parameters are the log odds of the outcome variable
at the reference percentage ridits specified by {cmd:refpts()}.
This second model is known as the secondary ridit spline model,
and is formulated to have the discriminating power of the primary logit model,
but to have better calibration when predicting the outcome from the ridit of the predicted odds.
{cmd:srslogit} then computes the predicted probabilities, predicted odds, and inverse probability weights
for the secondary model.
The computed variables are returned in new variables,
if the appropriate options are specified,
but otherwise live in {help tempvar:temporary variables},
which are discarded when {cmd:srslogit} completes execution.

{pstd}
The primary model is fitted using a {helpb glm} command of the form

{phang2}{cmd:glm} {depvar} [{indepvars}] {ifin} {weight} , {cmd:family(bernoulli) link(logit) asis} [ {cmd:noconstant} ] {it:glm_options}{p_end}

{pstd}
where {it:glm_options} are options for {helpb glm},
other than the {cmd:noconstant}, {cmd:asis}, {cmd:family()}, and {cmd:link()} options.

{pstd}
If {cmd:nosrspline} is not specified,
then the percentage ridits are calculated using a {helpb wridit} command of the form

{phang2}{cmd:wridit} {it:pxb}  {ifin} {weight}, {opt percent} {opt gene(ridit)}{p_end}

{pstd}
where {it:pxb} is an input variable containing the predicted log odds from the primary logistic model,
and {it:ridit} is an output variable to contain the percentage ridits of the primary predicted log odds.
The secondary ridit spline basis is then computed using a {helpb flexcurv} command of the form

{phang2}
{cmd:flexcurv} {it:rrsbasis} {ifin} , {opt xvar(ridit)} {opt refpts(refpts)} {opt power(power)}
  {cmd:krule(interpolate)}
  {cmd:include(0 100)}
  {opt generate(rrspline)} {cmd:type(double)} {cmd:labprefix("Percent@")}

{pstd}
where {it:rrsbasis} is the {it:newvarlist} specifying the names of the variables to be created as the ridit reference spline basis,
{it:ridit} is the variable containing the percentage ridits,
{it:refpts} is the {it:numlist} specified by the {cmd:refpts()} option,
{it:power} is the integer power specified by the {cmd:power()} option,
and {it:rrspline} is the prefix specified by the {cmd:rrspline()} option.
We can then fit the secondary ridit spline logit model using a {helpb glm} command of the form

{phang2}
{cmd:glm} {depvar} {it:rrsbasis} {ifin} {weight} , {cmd:family(bernoulli) link(logit) asis noconstant}
{it:glm_options}

{pstd}
which fits a logit model for the outcome with respect to the ridit reference spline basis,
whose parameters are the values of the secondary ridit spline at the reference percents
specified by {cmd:refpts()}.

{pstd}
More about reference splines and the {helpb bspline} package can be found in 
{help srslogit##srslogit_newson2012:Newson (2012)}
and {help srslogit##srslogit_newson2011:Newson (2011)}.
More about ridit splines, and their use in propensity weighting,
can be found in
{help srslogit##srslogit_newson2017:Newson (2017)}.


{title:Technical note}

{pstd}
The logit function is the canonical link function for the Bernoulli distributional family.
This implies that the log pseudolikelihood being maximized
is mathematically guaranteed to be concave,
implying that the maximization is guaranteed to converge,
if converging is defined to include converging to a parameter vector of log odds or odds ratios
including values of plus or minus infinity.
(That is to say, multiple local maxima are mathematically disallowed from existing.)
This in turn implies that, if the model seems not to be converging,
then we should be able to assume that it is really converging to a vector with at least one infinite value,
and that the predicted probabilities from the model will therefore be not vastly in error,
although some predicted values will be close to 0 or 1.
Therefore, we do not expect any major errors to be generated by using the current estimated parameter vector,
even though {helpb glm} reports that the model has not converged,
although the corresponding inverse probability weights
(also known as inverse propensity weights)
may occasionally be very large.
{cmd:srslogit} therefore does not fail when either the primary model or the secondary model
is reported as failing to converge (return code 430).
The use of a secondary ridit spline will probably minimize extreme inverse probability weights,
except when the inverse probability weights are failing to balance the covariates
included in the primary logit model.
This lack of balance will cause the inverse probability weighted Somers' {it:D}
of predicted probability or odds with respect to the Bernoulli outcome
to be clearly positive,
when measured using the {helpb somersd} package.
See {help srslogit##srslogit_newson2012:Newson (2017)}
for more about the use of {helpb somersd} to detect imbalance.


{title:Examples}

{pstd}
These examples use the {cmd:lbw} dataset,
downloadable using the command {helpb webuse}.
We create propensity scores for smoking,
indicated by the variable {cmd:smoke},
based on a list of variables that might predict smoking in a pregnant mother.

{pstd}
Set-up

{phang2}{cmd:. webuse lbw, clear}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. label list smoke}{p_end}
{phang2}{cmd:. tab smoke, m}{p_end}

{pstd}
Compute propensity scores and inverse probability weights from the primary and secondary logit models:

{phang2}{cmd:. srslogit smoke age lwt ib1.race ptl ib0.ht, pprob(priprop) pipw(priipw) sprob(secprop) sipw(secipw) eform}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. summ priprop, de}{p_end}
{phang2}{cmd:. summ priipw, de}{p_end}
{phang2}{cmd:. summ secprop, de}{p_end}
{phang2}{cmd:. summ secipw, de}{p_end}

{pstd}
Use the {help ssc:SSC} packages {helpb somersd} and {helpb haif} to do the balance checks and variance inflation checks, respectively,
for the primary propensity score and inverse probability weights:

{phang2}{cmd:. somersd smoke priprop, transf(z) tdist}{p_end}
{phang2}{cmd:. somersd smoke priprop [pwei=priipw], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(priipw)}{p_end}

{pstd}
Use the same {help ssc:SSC} packages
to do the balance checks and variance inflation checks, respectively,
for the secondary ridit spline propensity score and inverse probability weights:

{phang2}{cmd:. somersd smoke secprop, transf(z) tdist}{p_end}
{phang2}{cmd:. somersd smoke secprop [pwei=secipw], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(secipw)}{p_end}

{pstd}
We see from the unweighted {helpb somersd} commands
that the primary and secondary propensity scores
predict smoking equally well.
We see from the inverse propensity weighted {helpb somersd} commands
that the secondary propensity weights balance the association
slightly better than the primary propensity weights.
We see from the {helpb haif} commands
that the secondary propensity weights inflate the variance of a smoking effect on an outcome variable
less than the primary inverse propensity weights.
The secondary propensity weights might therefore be better ones to use
when estimating an effect of smoking on an outcome
(such as child birth weight).

{pstd}
The packages {helpb somersd} and {helpb haif} are downloadable from {help ssc:SSC}.
Their use in evaluating the costs and benefits of propensity weights is described in
{help srslogit##srslogit_newson2017:Newson (2017)}.
More about reference splines and the {helpb bspline} package can be found in 
{help srslogit##srslogit_newson2012:Newson (2012)}.

{pstd}
Estimate the maternal smoking effect on birth weight using secondary inverse propensity weights:

{phang2}{cmd:. regress bwt smoke [pwei=secipw]}{p_end}

{pstd}
This effect is adjusted for the covariates in the propensity model.
It compares mean birthweight if all mothers smoked
with mean birthweight if no mothers smoked.


{title:Saved results}

{pstd}
If the {cmd:nosrspline} option is not specified,
{cmd:stpp_est} saves in {cmd:e()} the estimation results from the {helpb glm} command
used to fit the secondary ridit spline logit regression model.
If the {cmd:nosrspline} option is specified,
{cmd:stpp_est} saves in {cmd:e()} the estimation results from the {helpb glm} command
used to fit the primary logit regression model.


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{marker srslogit_references}{...}
{title:References}

{phang}
{marker srslogit_newson2017}{...}
Newson, R. B.  2017.  Ridit splines with applications to propensity weighting.
Presented at {browse "https://ideas.repec.org/p/boc/usug17/01.html":the 23rd UK User Meeting, 7–8 September, 2017}.

{phang}
{marker srslogit_newson2012}{...}
Newson, R. B.  2012.
Sensible parameters for univariate and multivariate splines.
{it:The Stata Journal} 12(3): 479-504.
Download from {browse "https://journals.sagepub.com/doi/pdf/10.1177/1536867X1201200310":the {it:Stata Journal} website}.

{phang}
{marker srslogit_newson2011}{...}
Newson, R. B.  2011.  Sensible parameters for polynomials and other splines.
Presented at {browse "https://ideas.repec.org/p/boc/usug11/01.html":the 17th UK Stata User Meeting, 15-16 September, 2011}.


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[R] glm}
{p_end}
{p 4 13 2}
On-line: help for {helpb glm}
{break} help for {helpb wridit}, {helpb bspline} if installed
{p_end}
