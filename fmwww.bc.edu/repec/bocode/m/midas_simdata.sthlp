{smcl}
{* version 1.0.0  24jan2020}{...}
{cmd:help midas simdata}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas simdata} {hline 2} Simulate a bivariate diagnostic test accuracy meta-analysis dataset

{title:Syntax}

{p 8 18 2}
{cmd:midas simdata}{cmd:,}
{cmd:n(}{it:#}{cmd:)}
{cmd:logits(}{it:# #}{cmd:)}
{cmd:varlogits(}{it:# #}{cmd:)}
[{it:options}]

{title:Description}

{pstd}
{cmd:midas simdata} generates a simulated dataset of 2x2 diagnostic test
accuracy tables suitable for use with {helpb midas} meta-analysis commands.
Studies are simulated under the bivariate random-effects model: logit(Se)
and logit(Sp) are drawn from a bivariate normal distribution with specified
means, variances, and correlation, then binomial counts are generated for
each study.

{pstd}
The simulated dataset contains variables {cmd:tp}, {cmd:fp}, {cmd:fn},
and {cmd:tn} saved to disk and loaded into memory.

{title:Required options}

{phang}
{cmd:n(}{it:#}{cmd:)} number of subjects per study (diseased and
non-diseased combined).

{phang}
{cmd:logits(}{it:ls lp}{cmd:)} expected logit sensitivity ({it:ls}) and
logit specificity ({it:lp}). For example, {cmd:logits(2.0 2.5)} corresponds
to mean sensitivity of invlogit(2.0) = 0.88 and specificity of
invlogit(2.5) = 0.92.

{phang}
{cmd:varlogits(}{it:vs vp}{cmd:)} between-study variance of logit
sensitivity ({it:vs}) and logit specificity ({it:vp}). Both must be
non-negative.

{title:Options}

{phang}
{cmd:studies(}{it:#}{cmd:)} number of studies to simulate. Default is {cmd:studies(10)}.

{phang}
{cmd:p(}{it:#}{cmd:)} prevalence of disease (proportion of subjects who are
diseased). Default is {cmd:p(0)}, which splits subjects equally between
diseased and non-diseased.

{phang}
{cmd:r(}{it:#}{cmd:)} ratio of non-diseased to diseased subjects within
each study. Default is {cmd:r(0.5)}.

{phang}
{cmd:corr(}{it:#}{cmd:)} correlation between logit(Se) and logit(Sp)
across studies. Range: -1 to 1. Default is {cmd:corr(0.5)}.

{phang}
{cmd:path(}{it:string}{cmd:)} directory path for the temporary data file
used during simulation. Defaults to the current working directory.

{title:Examples}

{pstd}Simulate 20 studies with moderate accuracy and heterogeneity:{p_end}
{phang2}{cmd:. midas simdata, n(100) studies(20) logits(2.0 2.5) varlogits(0.5 0.5)}{p_end}
{phang2}{cmd:. midas mle tp fp fn tn, id(study)}{p_end}

{pstd}Simulate with high correlation between Se and Sp:{p_end}
{phang2}{cmd:. midas simdata, n(200) studies(15) logits(1.5 2.0) varlogits(0.3 0.3) corr(0.8)}{p_end}

{title:Saved results}

{pstd}
The simulated dataset is saved to disk as {cmd:midastemp.dta} in the
specified path (or current directory), then loaded into memory with
variables:

{p2colset 9 18 18 2}
{p2col:{cmd:tp}}true positives{p_end}
{p2col:{cmd:fp}}false positives{p_end}
{p2col:{cmd:fn}}false negatives{p_end}
{p2col:{cmd:tn}}true negatives{p_end}

{title:Author}

{phang}Ben A. Dwamena, University of Michigan.{p_end}
{phang}bdwamena@umich.edu{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas con2bin}, {helpb midas ord2bin}
