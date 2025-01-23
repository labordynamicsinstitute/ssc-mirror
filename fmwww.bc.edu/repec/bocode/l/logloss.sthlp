{smcl}
{* *! version 1.0.0 20jan2025}{...}

{title:Title}

{p2colset 5 16 17 2}{...}
{p2col:{hi:logloss} {hline 2}} Compute the log loss for binary outcome models {p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 14 2}
{cmd:logloss} {it:outcomevar} {it:forecastvar} {ifin} 


{phang}
{it:outcomevar} is a binary variable indicating the outcome of the experiment.

{phang}
{it:forecastvar} is the corresponding probability of a positive outcome and
must be between 0 and 1.

{phang}
{cmd:by} is allowed; see {help prefix}.




{title:Description}

{pstd}
{opt logloss} computes the log loss metric to assess the accuracy of a binary prediction model. The log loss metric 
is considered to be more sensitive than {helpb brier} in distinguishing between good and poor predictive models. The 
log loss ranges from 0 to infinity, where a lower score indicates better performance. A perfect model would have a 
log loss of 0, while a random model would have a log loss of around 0.693.
(see: {browse "https://www.dratings.com/log-loss-vs-brier-score/"}).




{title:Example}

{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. logit foreign price mpg weight length}{p_end}
{phang}{cmd:. predict predict, pr}{p_end}
{phang}{cmd:. logloss foreign predict}{p_end}
{phang}{cmd:. bys rep78: logloss foreign predict}{p_end}




{marker results}{...}
{title:Stored results}

{pstd}
{cmd:logloss} stores the following in {cmd:r()}:

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(logloss)}}computed log loss value{p_end}
{p2colreset}{...}




{marker citation}{title:Citation of {cmd:logloss}}

{p 4 8 2}{cmd:logloss} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{p 4 8 2}
Linden A. (2025). LOGLOSS: Stata module for computing the log loss metric for binary outcome models.



{title:Author}

{p 4 4 2}
Ariel Linden{break}
President, Linden Consulting Group, LLC{break}
alinden@lindenconsulting.org{break}



{title:Also see}

{p 4 8 2} Online: {helpb brier} {p_end}


