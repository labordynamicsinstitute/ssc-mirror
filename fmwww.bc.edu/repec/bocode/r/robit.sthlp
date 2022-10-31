{smcl}
{hline}
help for {cmd:robit}{right:(Roger Newson, Milena Falcaro)}
{hline}


{title:Robit regression}

{p 8 21 2}
{cmd:robit} {depvar} [{indepvars}] {ifin} {weight}, {opt df:reedom(#)} [
{break}
{opt nocons:tant}
{opth off:set(varname)}
{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}
{opt asis}
{cmd:vce(}{it:{help glm##vcetype:vcetype}}{cmd:)}
{opt le:vel(#)}
{opt nohead:er}
{opt notable}
{opt col:linear}
{opt coefl:egend}
{opt dif:ficult}
{opth from:(maximize##init_specs:init_specs)}
]

{pstd}
where {depvar} is a dependent variable which must be binary.

{synoptset 27 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt df:reedom(#)}}specify degrees of freedom for robit model{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}
{synopt :{opth off:set(varname:varname_o)}}include {it:varname_o} in model with coefficient constrained to 1{p_end}
{synopt:{cmdab:const:raints(}{it:{help estimation options##constraints():constraints}}{cmd:)}}apply specified linear constraints{p_end}
{synopt :{opt asis}}retain perfect predictor variables{p_end}
{synopt :{cmd:vce(}{it:{help glm##vcetype:vcetype}}{cmd:)}}{it:vcetype} may be {opt oim},
   {opt r:obust}, {opt cl:uster} {it:clustvar}, {opt boot:strap}, or 
   {opt jack:knife}{p_end}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt :{opt nohead:er}}do not print header lines{p_end}
{synopt :{opt notable}}do not print table of coefficients{p_end}
{synopt:{opt col:linear}}keep collinear variables{p_end}
{synopt :{opt coefl:egend}}display legend instead of statistics{p_end}
{synopt:{opt dif:ficult}}use a different stepping algorithm in nonconcave
	regions{p_end}
{synopt:{opth from:(maximize##init_specs:init_specs)}}initial values for the coefficients{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt dfreedom(#)} is required.{p_end}

{p 4 6 2}{opt fweight}s, {opt aweight}s, {opt iweight}s, and {opt pweight}s
are allowed; see {help weight}.{p_end}
{p 4 6 2}
{cmd:robit} has all the features available after estimation for {helpb glm},
such as the {helpb predict} command to compute predicted values for the dependent variable.
See {manhelp glm_postestimation R:glm postestimation} for features available
after estimation.
{p_end}


{title:Description}

{pstd}
{cmd:robit} fits a robit regression model,
with a number of degrees of freedom specified by the user.
This command requires the {help ssc:SSC} package {helpb xlink} in order to work.


{title:Options}

{phang}
{opt dfreedom(#)} specifies the degrees of freedom for the robit model to be fitted.
It must be specified, as an integer between 1 and 10.

{phang}
{opt noconstant} suppresses the constant term (intercept) in the model.

{phang}
{opt offset(varname)} specifies that {it:varname} be included in the model as an offset,
with the coefficient constrained to be 1.

{phang}
{cmd:constraints(}{it:{help numlist}}{c |}{it:matname}{cmd:)}
specifies the linear constraints to be applied during estimation.
The default is to perform unconstrained estimation.
See {helpb estimation options:[R] Estimation options}.

{phang}
{opt asis} forces retention of perfect predictor variables and their
associated, perfectly predicted observations,
and may produce instabilities in
maximization; see {manhelp probit R}.

{phang}
{opt vce(vcetype)} specifies the type of standard error reported.
Possible types include those
that are derived from asymptotic theory ({cmd:oim}, {cmd:opg}), 
those robust to some kinds of misspecification ({cmd:robust}),
or that allow for intragroup correlation ({cmd:cluster} {it:clustvar}),
and those from bootstrap or jackknife methods  ({cmd:bootstrap}, {cmd:jackknife});
see {helpb vce_option:[R] {it:vce_option}}.
{p_end}

{phang}
{opt level(#)} specifies the confidence level, set to 95 if absent.
See {helpb estimation options##level():[R] Estimation options}.

{phang}
{opt noheader} suppresses the header information from the output.
The coefficient table is still displayed.

{phang}
{opt notable} suppresses the table of coefficients from the output.
The header information is still displayed.

{phang}
{opt collinear} specifies that the estimation command not omit collinear
variables.  This option is seldom used because collinear variables make a
model unidentified.  However, you can add constraints to a model that will
identify it even with collinear variables.  For example, if variables {cmd:x1}
and {cmd:x2} are collinear, but you constrain the coefficient on {cmd:x2} to
be a multiple of the coefficient on {cmd:x1}, then your model is identified
even with collinear variables.  In such cases, you specify {cmd:collinear} so
that both {cmd:x1} and {cmd:x2} are retained in the model.

{phang}
{opt coeflegend} instructs Stata not to show the coefficient results but to display instead
the legend of the coefficients and how they should be specified in an expression.

{phang}
{opt difficult} specifies that the likelihood function is likely to be
difficult to maximize because of nonconcave regions.
There is no guarantee that {opt difficult} will
work better than the default; sometimes it is better and sometimes it is
worse.  You should use the {opt difficult} option only when the default stepper
declares convergence and the last iteration is "not concave" or when the
default stepper is repeatedly issuing "not concave" messages and producing only
tiny improvements in the log likelihood.
See {helpb maximize:[R] Maximize}.

{phang}
{opt from()} specifies initial values for the regression coefficients.
See {helpb maximize:[R] Maximize}.


{title:Remarks}

{pstd}
{cmd:robit} works by calling the {helpb glm} command with a binomial distribution function
({cmd:family(binomial 1)}),
and a robit link function from the {help ssc:SSC} package {helpb xlink}.
These link functions have names of the form {cmd:robit}{it:k},
where {it:k} is an integer from 1 to 10 specifying the degrees of freedom.

{pstd}
The choice of degrees of freedom (df) for robit models still seems to be an open question.
For example, 4 df was recommended by
{help robit##robit_kang2007:Kang and Shaffer (2007)}
and mentioned in Chapter 15 of
{help robit##robit_gelmanetal2020:Gelman, Hill, and Vehtari (2020)}.
1 df was mentioned by
{help robit##robit_ridgeway2007:Ridgeway (2007)}.
7 df was recommended by
{help robit##robit_liu2004:Liu (2004)}
as being similar to the logit link function,
but less influenced by outlying values.
9 df was mentioned by
{help robit##robit_mudholkar1978:Mudholkar and George (1978)}
as having a similar kurtosis to the logit link function.
In general, robit link functions with fewer degrees of freedom
are influenced less by outliers than robit link functions with more degrees of freedom.
In the limit, as {it:k} tends to infinity,
the robit link function with {it:k} degrees of freedom
becomes the probit link function.

{pstd}
{cmd:robit} saves in {cmd:e()} the results saved by the {helpb glm} command,
but also 1 extra result, {cmd:e(depvarsum)},
containing the sum of the dependent variable specified in {cmd:e(depvar)},
limited to the estimation sample specified in {cmd:e(sample)}.

{pstd}
{cmd:robit} is designed to be flexible and easy to use.
Users who want to fit robit models with the full power of {helpb glm}
should use {helpb glm}, with a robit link option from {helpb xlink}.
For example, {cmd:robit y x1 x2, df(4)}
is equivalent to {cmd:glm y x1 x2, family(binomial) link(robit4)}.
The use of {helpb glm} in place of {cmd:robit}
may be advantageous when, for instance,
the specification of nonstandard {help maximize:maximization options}
(see [R] Maximize)
or {help estimation options:display options}
(see [R] Estimation options)
is needed. 


{title:Examples}

{pstd}
Set-up:

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. describe, full}{p_end}

{pstd}
Fit a robit model with 7 degrees of freedom:

{phang2}{cmd:. robit foreign mpg weight, dfreedom(7) vce(robust)}{p_end}

{pstd}
Compute and summarize predicted probabilities of non-US car origin
(i.e. foreign = 1) from the fitted robit model:

{phang2}{cmd:. predict pforeign}{p_end}
{phang2}{cmd:. summ pforeign, detail}{p_end}

{pstd}
Fit a robit model with 4 degrees of freedom instead:

{phang2}{cmd:. robit foreign mpg weight, dfreedom(4) vce(robust)}{p_end}

{pstd}
This is equivalent to the following {helpb glm} command:

{phang2}{cmd:. glm foreign mpg weight, link(robit4) family(binomial) vce(robust)}{p_end}


{marker robit_references}{...}
{title:References}

{phang}
{marker robit_gelmanetal2020}{...}
Gelman, A., Hill, J., and Vehtari, A.
2020.
{it:Regression and Other Stories.}
Cambridge, UK: Cambridge University Press.

{phang}
{marker robit_kang2007}{...}
Kang, J. D. Y. and Schafer, J. L.  2007.
Demystifying double robustness:
A comparison of alternative strategies forestimating a population mean from incomplete data.
{it:Statistical Science} {bf:22}: 523-539.

{phang}
{marker robit_liu2004}{...}
Liu, C. H.
2004.
Robit Regression: A Simple Robust Alternative to Logistic and Probit Regression.
Chapter 21 of:
Gelman, A. and Meng, X-L.
2004.
{it:Applied Bayesian Modeling and Causal Inference from Incomplete-Data Perspectives:}
{it:An Essential Journey with Donald Rubin's Statistical Family.}
Chichester, UK: John Wiley & Sons Ltd.
Download from {browse "https://onlinelibrary.wiley.com/doi/10.1002/0470090456.ch21":the Wiley Online website}.

{phang}
{marker robit_mudholkar1978}{...}
Mudholkar, G. S. and George, E. O.
1978.
A remark on the shape of the logistic distribution.
{it:Biometrika} {bf:65}: 667-668.

{phang}
{marker robit_ridgeway2007}{...}
Ridgeway, G. and McCaffrey, D. F.  2007.
Comment: Demystifying double robustness:
A comparison of alternative strategies for estimating a population mean from incomplete data.
{it:Statistical Science} {bf:22}: 540-543.


{title:Authors}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}{break}

{pstd}
Milena Falcaro, King's College London, UK.{break}
Email: {browse "mailto:milena.falcaro@kcl.ac.uk":milena.falcaro@kcl.ac.uk}


{title:Saved results}

{pstd}
{cmd:robit} saves in {cmd:e()} all results saved by {helpb glm},
and also the following:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(depvarsum)}}sum of dependent variable in estimation sample{p_end}
{p2colreset}{...}


{title:Also see}

{psee}
Manual:  {manlink R glm}
{p_end}

{psee}
{space 2}Help:  {manhelp glm R}{break}
help for {helpb xlink} if installed
{p_end}
