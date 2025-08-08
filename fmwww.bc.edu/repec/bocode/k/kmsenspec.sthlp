{smcl}
{hline}
help for {cmd:kmsenspec}{right:(Roger Newson)}
{hline}

{title:Estimate sensitivity, specificity, and positive and negative predictive values from Kaplan-Meier survival probabilities}

{p 8 21 2}
{cmd:kmsenspec} {varname} {ifin} ,
  {opth t:ime(#)} 

{pstd}
where {varname} is the name of a binary variable indicating a positive test result.


{title:Description}

{pstd}
{cmd:kmsenspec} is intended for use in a survival time dataset set up by {helpb stset}.
It inputs a binary variable  indicating a positive test result,
and estimates positive and negative predictive values from Kaplan-Meier survival probabilities
at a time specified by the user in positive and negative observations,
and then estimates the sensitivity and specificity of the test using the Bayes theorem,
with delta-Greenwood variances estimated from the Greenwood standard errors
of the positive and negative predictive values.
The estimation results are estimates of the sensitivity, specificity,
negative predictive value, and positive predictive value,
with a covariance matrix for the untransformed estimates.
Alternatively, {cmd:kmsenspec} can be used with the {help ssc:SSC} packages {helpb parmest} and {helpb esetran}
to compute delta-Greenwood confidence intervals using a variety of Normalizing transforms.
The {cmd:kmsenspec} package uses the {help ssc:SSC} package {helpb kmest},
which must be installed in order for {cmd:kmsenspec} to work.


{title:Options}

{phang}
{opth time(#)} must be present. It specifies a survival time, at which the positive and negative predictive values are estimated
from the Kaplan-Meir survival functions for test-positive and test-negative subjects, respectively.
Note that the time is assumed to be given in the units specified by the {cmd:scale()} option of {helpb stset}.


{title:Methods and formulas}

{pstd}
The {varname} supplied by the user must belong to a binary variable indicating a positive test result,
with values 0 for a negative result and 1 for a positive result.
The positive predictive value at time {it:t}
is defined as

{pstd}
{cmd:PPV(t) = 1-S(t|testpos)}

{pstd}
where {cmd:S(t|testpos)} is the survival function at time {cmd:t} of a lifetime starting with a positive test result.
And the negative predictive value at time {cmd:t}
is defined as

{pstd}
{cmd:NPV(t) = S(t|testneg)}

{pstd}
where {cmd:S(t|testneg)} is the survival function at time {cmd:t}
of a lifetime starting with a negative test result.

{pstd}
The sensitivity at time {cmd:t}
is the estimated probability that an observation tested positive at baseline time 0,
given that it failed by time {cmd:t}.
It is estimated using the Bayes theorem as

{pstd}
{cmd:sens(t) = Ntestpos*PPV(t)/(Ntestpos^PPV(t) + Ntestneg*(1-NPV(t)))}

{pstd}
where {cmd:Ntestpos} is the number of observations that tested positive at baseline and
{cmd:Ntestneg} is the number of observations that tested negative at baseline.

{pstd}
And the specificity at time {cmd:t}
is the estimated probability that an observation tested negative at baseline time 0,
given that it did not fail by time {cmd:t}.
It is estimated using the Bayes theorem as

{pstd}
{cmd:spec(t) = Ntestneg*NPV(t)/(Ntestpos*(1-PPV(t)) + Ntestneg*NPV(t))}

{pstd}
The covariance matrix {cmd:Cov_B}
for {cmd:sens(t)}, {cmd:spec(t)}, {cmd:PPV(t)}, and {cmd:NPV(t)}
is estimated using a delta-Greenwood method.
The diagonal covariance matrix {cmd:Cov_A} of {cmd:PPV(t)} and {cmd:NPV(t)}
is estimated using the Greenwood variances of {cmd:PPV(t)}  and {cmd:NPV(t)}.
And the covariance matrix {cmd:Cov_B}
is estimated as

{pstd}
{cmd:Cov_B = D*Cov_A*D'}

{pstd}
where {cmd:D} is the estimated matrix of derivatives of
{cmd:sens(t)}, {cmd:spec(t)}, {cmd:PPV(t)}, and {cmd:NPV(t)}
with respect to {cmd:PPV(t)} and {cmd:NPV(t)}.
These derivatives are explained in the manual {cmd:kmsenspec.pdf} for {cmd:kmsenspec},
distributed with the {cmd:kmsenspec} package as an ancillary file.

{pstd}
The covariance matrix {cmd:Cov_B} is for the untransformed parameters,
and may lead to confidence intervals with lower bounds less than 0
or upper bounds greater than 1.
More realistic confidence limits can probably be generated
using a Normalizing and variance-stabilizing transformation,
such as the log or the logit.
This can be done using the {help ssc:SSC} packages
{helpb parmest} and {helpb esetran}.


{title:Examples}

{pstd}
These examples use the {cmd:cancer} dataset,
which the user can download using the {helpb webuse} command,
and which has already been set up as survival time data,
using the {helpb stset} command.
We start by defining a variable {cmd:placebo},
indicating that a patient is allocated to the placebo.
This variable might be expected to act as a positive predictor
that a patient will be dead by a specified time.

{pstd}
Set-up

{phang2}{cmd:. webuse cancer, clear}{p_end}
{phang2}{cmd:. describe, full}{p_end}
{phang2}{cmd:. stset}{p_end}
{phang2}{cmd:. gene byte placebo=drug==1}{p_end}
{phang2}{cmd:. lab var placebo "Placebo indicator"}{p_end}
{phang2}{cmd:. tab placebo drug, miss}{p_end}

{pstd}
Simple examples

{phang2}{cmd:. kmsenspec placebo, time(10)}{p_end}
{phang2}{cmd:. kmsenspec placebo, time(30)}{p_end}
{phang2}{cmd:. kmsenspec placebo, time(50)}{p_end}

{pstd}
The following advanced example uses the {help ssc:SSC} package {helpb esetran},
together with the {helpb parmest} and {helpb parmcip} modules
of the {help ssc:SSC} package {helpb parmest},
to generate an output dataset (or resultsset),
with 1 observation per estimated parameter
and data on asymmetric confidence intervals generated using the log transform.

{phang2}{cmd:. kmsenspec placebo, time(10)}{p_end}
{phang2}{cmd:. parmest, fast}{p_end}
{phang2}{cmd:. esetran estimate stderr, transf(log)}{p_end}
{phang2}{cmd:. parmcip, replace}{p_end}
{phang2}{cmd:. foreach Y of var estimate min* max* {c -(}}{p_end}
{phang2}{cmd:.   replace `Y'=exp(`Y')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. list, abbr(32)}{p_end}


{title:Saved results}

{pstd}
{cmd:kmsenspec} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}Number of observations{p_end}
{synopt:{cmd:e(Ntestpos)}}Number of observations testing positive{p_end}
{synopt:{cmd:e(Ntestneg)}}Number of observations testing negative{p_end}
{synopt:{cmd:e(time)}}{cmd:time()} option{p_end}


{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(predict)}}program called by {cmd:predict} ({cmd:kmsenspec_p}){p_end}
{synopt:{cmd:e(cmd)}}{cmd:kmsenspec}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(properties)}}{cmd:b V}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}
{synopt:{cmd:e(D)}}matrix of derivatives of {cmd:sens(t)}, {cmd:spec(t)}, {cmd:PPV(t)}, and {cmd:NPV(t)} with respect to {cmd:PPV(t)} and {cmd:NPV(t)}{p_end}

{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{p2colreset}{...}


{title:Author}

{pstd}
Roger Newson, Queen Mary University of London, UK.{break}
Email: {browse "mailto:r.newsn@qmul.ac.uk":r.newsn@qmul.ac.uk}


{title:Also see}

{p 4 13 2}
{bind: }Manual: {hi:[ST] sts}, {hi:[ST] stset}
{p_end}
{p 4 13 2}
On-line: help for {helpb sts}, {helpb stset}
{break}
         help for {helpb kmest}, {helpb senspec} if installed
{p_end}
