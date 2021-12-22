{smcl}
{hline}
help for {cmd:robit}{right:(Roger Newson)}
{hline}

{title:Robit regression}

{p 8 21 2}
{cmd:robit} [ {depvar} [{indepvars}] ] {ifin} {weight} [, {opt dfro:bit(#)} {help glm:{it:glm_options}} ]

{pstd}
where {help glm:{it:glm_options}} is a list of options used by {helpb glm} other than {cmd:link()}.


{title:Description}

{pstd}
{cmd:robit} fits a robit regression model,
with a number of degrees of freedom specified by the user.
{cmd:robit} requires the {help ssc:SSC} package {helpb xlink} in order to work.


{title:Options}

{phang}
{opt dfrobit(#)} specifies the degrees of freedom for the robit model to be fitted.
It must be an integer between 1 and 8.
If not specified, then 7 is assumed.


{title:Remarks}

{pstd}
{cmd:robit} works by calling {helpb glm} with a robit link function
from the {help ssc:SSC} package {helpb xlink}.
These link functions have names of the form {cmd:robit}{it:k},
where {it:k} is an integer from 1 to 8.
The distribution family defaults to {cmd:family(bernoulli)},
specifying that the dependent variable is a binary indicator.
However, it may be set to other values,
such as {cmd:family(binomial #)}
if the dependent variable is a binomial total instead of a binary indicator.
If the variance function specified by {cmd:family()}
is not binomial or Bernoulli,
then {cmd:robit} runs, but gives a warning.

{pstd}
The {cmd:robit4} link function was recommended by
{help xlink##xlink_kang2007:Kang and Shaffer (2007)}.
The {cmd:robit7} link function was recommended by
{help xlink##xlink_liu2004:Liu (2004)}
as being similar to the logit link function,
but less influenced by outlying outcome values.
In general, robit link functions with fewer degrees of freedom
are influenced less by outliers than robit link functions with more degrees of freedom.
In the limit, as {it:k} tends to infinity,
the robit link function with {it:k} degrees of freedom
tends to the probit link function.

{pstd}
{cmd:robit} currently saves only 2 extra results, {cmd:e(depvarsum)} and {cmd:e(msum)},
containing the sum of the dependent variable specified in {cmd:e(depvar)}
and the sum of the binomial total specified in {cmd:e(m)},
respectively,
limited to the estimation sample specified in {cmd:e(sample)}.


{title:Examples}

{pstd}
Set-up:

{phang2}{cmd:.sysuse auto, clear}{p_end}
{phang2}{cmd:.describe, full}{p_end}

{pstd}
Estimate {it:t}-deviates per US pound of weight for probability of non-US origin
with the default 7 degrees of freedom:

{phang2}{cmd:.robit foreign weight, vce(robust)}{p_end}

{pstd}
Estimate {it:t}-deviates per US pound of weight for probability of non-US origin
with 4 and 1 degrees of freedom:

{phang2}{cmd:.robit foreign weight, dfrobit(4) vce(robust)}{p_end}

{phang2}{cmd:.robit foreign weight, dfrobit(1) vce(robust)}{p_end}


{marker xlink_references}{...}
{title:References}

{phang}
{marker xlink_kang2007}{...}
Kang, J. D. Y. and Schafer, J. L.  2007.
Demystifying double robustness:
A comparison of alternative strategies forestimating a population mean from incomplete data.
{it:Statistical Science} {bf:22}: 523-539.

{phang}
{marker xlink_liu2004}{...}
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


{title:Author}

{pstd}
Roger Newson, King's College London, UK.{break}
Email: {browse "mailto:roger.newson@kcl.ac.uk":roger.newson@kcl.ac.uk}


{title:Saved results}

{pstd}
{cmd:robit} saves in {cmd:e()} all results saved by {helpb glm},
and also the following:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(depvarsum)}}sum of dependent variable in estimation sample{p_end}
{synopt:{cmd:e(msum)}}sum of binomial trials {cmd:e(m)} in estimation sample{p_end}
{p2colreset}{...}


{title:Also see}

{psee}
Manual:  {manlink R glm}
{p_end}

{psee}
{space 2}Help:  {manhelp glm R}{break}
{helpb xlink} if installed
{p_end}
