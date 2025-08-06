{smcl}
{* *! version 1.1.0  05aug2025}{...}
{vieweralsosee "[U] weight" "help weight"}{...}
{vieweralsosee "[SVY] Survey" "help svy"}{...}
{viewerjumpto "Syntax" "wgtdistrim##syntax"}{...}
{viewerjumpto "Description" "wgtdistrim##description"}{...}
{viewerjumpto "Options" "wgtdistrim##options"}{...}
{viewerjumpto "Examples" "wgtdistrim##examples"}{...}
{viewerjumpto "References" "wgtdistrim##references"}{...}
{viewerjumpto "Citation" "wgtdistrim##citeas"}{...}
{viewerjumpto "Support" "wgtdistrim##support"}{...}
{...}

{p 0 18 2}
{cmd:wgtdistrim} {hline 2} Trim extreme sampling weights
{p_end}


{...}
{...}
{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:wgtdistrim}
{varname} 
{ifin}
{cmd:,} 
{cmdab:g:enerate(}[{help datatypes:{it:type}}] {newvar}{cmd:)}
{opt upper(#)}
[ {it:options} ]


{...}
{...}
{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {cmdab:g:enerate(}[{help datatypes:{it:type}}] {newvar}{cmd:)}}generate
{it:newvar} containing trimmed sampling weights
{p_end}
{p2coldent:* {opt up:per(#)}}trim large sampling weights 
with probability of occurence less than {it:#}
{p_end}
{synopt:{opt lo:wer(#)}}trim small sampling weights 
with probability of occurence less than {it:#};
default is {cmd:lower(0)}
{p_end}
{synopt:{opt iter:ate(#)}}perform maximum of {it:#} iterations; 
default is {cmd:iterate(10)}
{p_end}
{synopt:{opt tol:erance(#)}}tolerance for trimmed sampling weights; 
default is {cmd:tolerance(0)}
{p_end}
{synopt:{opt momvar:inace}}use method of moments estimator for variance
{p_end}
{synopt:{opt norm:alize}}normalize trimmed sampling weights 
to sum to number of observations
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 8 2}
* {opt generate()} and {opt upper()} are required.
{p_end}


{...}
{...}
{marker description}{...}
{title:Description}

{pstd}
{cmd:wgtdistrim} trims extreme sampling weights 
using the weight distribution approach suggested by Potter (1990).

{pstd}
The reciprocal of the sampling weights are assumed to follow a (scaled) 
{help ibeta:beta} distribution. 
The parameters of the beta distribution are estimated from the sampling weights 
and the trimming levels (cut-offs) are computed for the specified quantiles. 
Sampling weights that are more extreme than the specified quantiles 
are trimmed to these quantiles and the excess is distributed equally 
among the untrimmed sampling weights 
so that the sum of the trimmed sampling weights 
equals the sum of the untrimmed sampling weights. 
This process is repeated a specified number of times 
(or until the trimmed sampling weights do no longer change)
to otain the final trimmed sampling weights.


{...}
{...}
{marker options}{...}
{title:Options}

{phang}
{cmd:generate(}[{help datatypes:{it:type}}] {newvar}{cmd:)}
specifies the name and, optionally, the type of the new variable 
containing the trimmed sampling weights.
Option {opt generate()} is required.

{phang}
{opt upper(#)}
specifies the probability of occurrence 
of large sampling weights to be trimmed. 
Large sampling weights with probability of occurence 
less than {it:#}, where 0 < {it:#} < 1, are trimmed
to the 1-{it:#} quantile of the beta distribution.
Option {opt upper()} is required.

{phang}
{opt lower(#)}
specifies the probability of occurrence 
of small sampling weights to be trimmed. 
Small sampling weights with probability of occurence 
less than {it:#}, where 0 < {it:#} < 1, are trimmed
to the {it:#} quantile of the beta distribution.
Default is {cmd:lower(0)}.

{phang}
{opt iterate(#)}
specifies the maximum number of iterations, 
i.e., how often the trimming levels are computed. 
The default maximum number of iterations is 10.

{phang}
{opt tolerance(#)}
specifies the tolerance for trimmed sampling weights.
When the relative difference in sampling weights 
from one iteration to the next is less than or equal to {it:#}, 
convergence is achieved. 
Default is {cmd:tolerance(0)}.

{phang}
{opt momvariance}
specifies that the variance of the sampling weights 
is estimated using the method of moments estimator, dividing by {it:n}.  
This is the approach used by Potter (1990, p. 227). 
By default, the variance is estimated using {it:n}-1 as the divisor.

{phang}
{opt normalize}
specifies that the trimmed sampling weights be normalized 
to sum to the number of observations 
(with non-missing positive sampling weights).
The trimmed weights are normalized only once, after the last iteration.


{...}
{...}
{marker examples}{...}
{title:Examples}

{pstd}
Trim sampling weights only on the right tail of the beta distribution
if the probability of occurence is less than 0.01 (1 percent).

{phang2}
{cmd:. wgtdistrim pweight , generate(double pweight_trimmed) upper(.01)}
{p_end}

{pstd}
Trim sampling weights on the left and right tail of the beta distribution
if the probability of occurence is less than 0.01 (1 percent) on either tail. 

{phang2}
{cmd:. wgtdistrim pweight , generate(double pweight_trimmed) lower(.01) upper(.01)}
{p_end}

{pstd}
Same as above, but also normalize the trimmed sampling 
weights to sum to the number of observations.

{phang2}
{cmd:. wgtdistrim pweight , generate(double pweight_trimmed) lower(.01) upper(.01) normalize}
{p_end}


{...}
{...}
{marker references}{...}
{title:References}

{pstd}
Potter, F. J. 1990.{...}
A study of procedures to identify and trim extreme sampling weights.{...} 
Proceedings of the Survey Research Methods Section of the American Statistical Association,{...}
225--230.

{pstd}
Chen, Q., Elliott, M. R., Haziza, D., Yang, Y., Ghosh, M., Little, R. J. A., Sedransk, J., & Thompson, M. 2017.{...} 
Approaches to improving survey-weighted estimates.{...} 
Statistical Science, 32(2), 227--248.


{...}
{...}
{marker citeas}{...}
{title:Suggested citation}

{pstd}
Lang, S., & Klein, D. (2023). WGTDISTRIM: Stata module to trim extreme sampling weights. doi: {browse "https://doi.org/10.7802/2641":10.7802/2641}{break}
Available from {browse "https://github.com/se-lang/wgtdistrim/tree/main"}


{...}
{...}
{marker support}{...}
{title:Support}

{pstd}
{browse "mailto:contact@sebastianlang.eu":contact@sebastianlang.eu}{break}
{browse "mailto:klein.daniel.81@gmail.com":klein.daniel.81@gmail.com}{break}
{p_end}
