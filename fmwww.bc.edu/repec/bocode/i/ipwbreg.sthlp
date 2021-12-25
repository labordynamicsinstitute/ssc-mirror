{smcl}
{hline}
help for {cmd:ipwbreg}{right:(Roger Newson)}
{hline}

{title:Inverse propensity weights from Bernoulli regression}

{p 8 21 2}
{cmd:ipwbreg} {depvar}
[{indepvars}]
{weight}
{ifin}
[,
  {cmd:no}{opt stab:fact}
  {break}
  {opth pro:bability(newvar)}
  {opth xb(newvar)}
  {opth ipw:eight(newvar)}
  {break}
  {opth atet:weight(newvar)}
  {opth atec:weight(newvar)}
  {opth ovw:eight(newvar)}  
  {break}
  {help glm:{it:glm_options}}
]

{pstd}
where {it:glm_options} are options for {helpb glm},
other than the {cmd:asis} and {cmd:family()} options.

{pstd}
{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see
{help weight}.
They are interpreted as weights of the same kinds with {helpb glm}.


{title:Description}

{pstd}
{cmd:ipwbreg} fits a Bernoulli generalized linear regression model for a binary dependent variable
in a list of independent variables,
and then outputs a list of inverse propensity weight variables.
These propensity weight variables may be used to estimate propensity-adjusted effects
of the binary treatment on an outcome variable.
{cmd:ipwbreg} requires the {helpb xlink} package,
if it is used with the extra link functions for {cmd:glm}
supplied in {helpb xlink}.


{title:Options}

{phang}
{opt nostabfact} specifies that the stabilization factors {cmd:a_0} and {cmd:a_1} are set to 1.
If {cmd:nostabfact} is not specified,
then {cmd:a_0} is set to the proportion of observations in the estimation sample
in which the dependent binary variable {depvar} is 0,
and {cmd:a_1} is set to the proportion of ovservations in the estimation sample
in which the dependent variable is 1.
These proportions are weighted by the {weight} expression,
if weights are present.
For an explanation of the role of stabilization factors in weighting methods,
see
{help ipwbreg##ipwbreg_methform:Methods and formulas} below.

{phang}
{opth probability(newvar)}, {opth xb(newvar)}, {opth ipweight(newvar)},
{opth atetweight(newvar)}, {opth atecweight(newvar)}, and {opth ovweight(newvar)}
specify the names of optional generated output variables,
containing, respectively, the predicted probabilities, the predicted link funcions,
the inverse-propensity weights for estimating the average treatment effect,
the inverse-propensity weights for estimating the average treatment effects in the treated,
the inverse-propensity weights for estimating the average treatment effects in the controls (untreated),
and the propensity overlap weights,
respectively.
Inverse probability weights can be used as inverse treatment probability weights
for estimation of the average treatment effects for the whole sample, the treated, or the untreated,
if the outcome is a treatment indicator,
or as inverse completeness probability weights for the subsample with outcome 1,
if the outcome is a completeness indicator.


{marker ipwbreg_methform}{...}
{title:Methods and formulas}

{pstd}
The Bernoulli regression model is fitted using a {helpb glm} command of the form

{phang2}{cmd:glm} {depvar} [{indepvars}] {ifin} {weight} , {cmd:family(bernoulli) asis}  {it:glm_options}{p_end}

{pstd}
where {it:glm_options} are options for {helpb glm},
other than the {cmd:asis} and {cmd:family()} options.
The default link function is {cmd:link(logit)}.

{pstd}
We define {cmd:a_0} and {cmd:a_1} as stabilization factors for the binary values 0 and 1,
respectively.
These are both equal to 1 if the option {cmd:nostabfact} is specified,
and otherwise are equal to the weighted proportions of observations, in the estimation sample,
vith outcomes 0 and 1, respectively.
We might view the outcome variable as a treatment indicator.
The inverse propensity weights are designed to standardise the estimation sample directly
to a fantasy population,
with a proportion of positive outcomes (or treated individuals)
equal to 0.5 if {cmd:nostabfact} is specified,
or as in the estimation sample otherwise,
and in which the treatment propensity output by the {cmd:probability()} option
is uncorrelated with the treatment received.
We denote the Bernoulli outcome variable as {cmd:y}.

{pstd}
The inverse propensity weight variable generated by the {cmd:ipweight()} option is equal to

{pstd}
{cmd:y*a_1/probability + (1-y)*a_0/(1-probability)}

{pstd}
The inverse propensity weight variable generated by the {cmd:atetweight()} option is equal to

{pstd}
{cmd:y*a_1 + (1-y)*a_0*probability/(1-probability)}

{pstd}
and is used to estimate the average treatment effect in the treated (ATET).

{pstd}
The inverse propensity weight variable generated by the {cmd:atecweight()} option is equal to

{pstd}
{cmd:y*a_1*(1-probability)/probability + (1-y)*a_0}

{pstd}
and is used to estimate the average treatment effect in the controls (ATEC).

{pstd}
The inverse propensity weight variable generated by the {cmd:ovweight()} option is equal to

{pstd}
{cmd:y*(1-probability) + (1-y)*probability}

{pstd}
and is known as the overlap weight.
Overlap weights are recommended in
{help ipwbreg##ipwbreg_zeng2021:Zeng {it:et al.} (2021)}.

{pstd}
A long list of {cmd:link()} options is available,
corresponding to the many link functions compatible with a Bernoulli regression.
The default is {cmd:link(logit)}, which is the canonical link for the Bernoulli variance function.
Other examples are {cmd:link(log)} and {cmd:link(probit)}.
Alternative link functions are available if the user has installed the {help ssc:SSC} package {helpb xlink}.
One example is {cmd:link(robit7)},
implying a robit link with 7 degrees of freedom,
which is similar to a logit link,
but which is thought by some to be less prone to producing extremely high weights.
The robit link is recommended in
{help ipwbreg##ipwbreg_liu2004:Liu (2004)}.


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

{phang2}{cmd:. ipwbreg smoke age lwt ib1.race ptl ib0.ht, prob(myprob) ipw(myipw) atet(myatet) atec(myatec) ovweight(myovw) eform}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. summ myprob, de}{p_end}
{phang2}{cmd:. summ myipw, de}{p_end}
{phang2}{cmd:. summ myatet, de}{p_end}
{phang2}{cmd:. summ myatec, de}{p_end}
{phang2}{cmd:. summ myovw, de}{p_end}

{pstd}
Use the {help ssc:SSC} package {helpb somersd}, without weights,
to measure power of smoking propensity to predict smoking in our sample:

{phang2}{cmd:. somersd smoke myprob, transf(z) tdist}{p_end}

{pstd}
Use the {help ssc:SSC} packages {helpb somersd} and {helpb haif} to do the balance checks and variance inflation checks, respectively,
for the primary propensity score and the various inverse propensity weights:

{phang2}{cmd:. somersd smoke myprob [pwei=myipw], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(myipw)}{p_end}
{phang2}{cmd:. somersd smoke myprob [pwei=myatet], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(myatet)}{p_end}
{phang2}{cmd:. somersd smoke myprob [pwei=myatec], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(myatec)}{p_end}
{phang2}{cmd:. somersd smoke myprob [pwei=myovw], transf(z) tdist}{p_end}
{phang2}{cmd:. haif ib0.smoke, pweight(myovw)}{p_end}

{pstd}
Estimate the maternal smoking effect on birth weight using inverse propensity weights:

{phang2}{cmd:. regress bwt smoke [pwei=myipw]}{p_end}

{pstd}
This effect is adjusted for the covariates in the propensity model.
It compares mean birthweight if all mothers smoked
with mean birthweight if no mothers smoked.

{pstd}
The packages {helpb somersd} and {helpb haif} are downloadable from {help ssc:SSC}.
Their use in evaluating the costs and benefits of propensity weights is described in
{help ipwbreg##ipwbreg_newson2017:Newson (2017)}.


{title:Saved results}

{pstd}
{cmd:ipwbreg} saves in {cmd:e()} the estimation results from the {helpb glm} command
used to fit the binary regression model,
plus the following:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(stabfac0)}}stabilization factor {cmd:a_0}{p_end}
{synopt:{cmd:e(stabfac1)}}stabilization factor {cmd:a_1}{p_end}
{p2colreset}{...}


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{marker ipwbreg_references}{...}
{title:References}

{phang}
{marker ipwbreg_liu2004}{...}
Liu, C. H. 2004.
Robit Regression: A Simple Robust Alternative to Logistic and Probit Regression.
Chapter 21 of:
Gelman, A. and Meng, Xiao-Li. 2004.
{it:Applied Bayesian Modeling and Causal Inference from Incomplete-Data Perspectives: An Essential Journey with Donald Rubin's Statistical Family.}
Chichester, UK: John Wiley & Sons Ltd.
Download from {browse "https://onlinelibrary.wiley.com/doi/10.1002/0470090456.ch21":the Wiley Online website}.

{phang}
{marker ipwbreg_newson2017}{...}
Newson, R. B.  2017.  Ridit splines with applications to propensity weighting.
Presented at {browse "https://ideas.repec.org/p/boc/usug17/01.html":the 23rd UK Stata Users' Group Meeting, 7-8 September, 2017}.

{phang}
{marker ipwbreg_zeng2021}{...}
Zeng, S. X., Li, F., Wang, R. and Li, F.
Propensity score weighting for covariate adjustment in randomized clinical trials.
{it:Statistics in Medicine} 021; 40: 842-858.


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[R] glm}
{p_end}
{p 4 13 2}
On-line: help for {helpb glm}
{break} help for {helpb somersd}, {helpb haif} if installed
{p_end}