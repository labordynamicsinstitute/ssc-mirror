{smcl}
{* version 1.00  20nov2009}{...}
{cmd:help midas bclust2bin}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas bclust2bin} {hline 2} Cluster adjustment of 2x2 diagnostic test data

{title:Syntax}

{p 8 18 2}
{cmd:midas bclust2bin}
{it:tp fp fn tn np}
[{varlist}]
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,}
{cmd:id(}{it:varlist}{cmd:)}
]

{title:Description}

{pstd}
{cmd:midas bclust2bin} adjusts 2x2 diagnostic test accuracy counts for
within-study clustering using the design effect (VIF) approach of
Donner and Klar (2000). It is used when studies report clustered data
(e.g., multiple lesions per patient) and inflated cell counts need to be
deflated to an effective sample size before meta-analysis.

{pstd}
The five required variables are, in order:

{p2colset 9 22 22 2}
{p2col:{it:tp}}true positives{p_end}
{p2col:{it:fp}}false positives{p_end}
{p2col:{it:fn}}false negatives{p_end}
{p2col:{it:tn}}true negatives{p_end}
{p2col:{it:np}}number of primary sampling units (clusters) per study{p_end}

{pstd}
The command computes the intraclass correlation coefficient (ICC) and
variance inflation factor (VIF) from the observed counts and cluster sizes,
then creates design-effect-adjusted variables {cmd:midas_tp}, {cmd:midas_fp},
{cmd:midas_fn}, and {cmd:midas_tn} which can be passed directly to the
{helpb midas} estimation commands.

{title:Options}

{phang}
{cmd:id(}{it:varlist}{cmd:)} specifies one or more study identifier variables.

{title:Saved results}

{pstd}
{cmd:midas bclust2bin} creates the following new variables in the dataset:

{p2colset 9 22 22 2}
{p2col:{cmd:midas_tp}}design-effect-adjusted true positives{p_end}
{p2col:{cmd:midas_fp}}design-effect-adjusted false positives{p_end}
{p2col:{cmd:midas_fn}}design-effect-adjusted false negatives{p_end}
{p2col:{cmd:midas_tn}}design-effect-adjusted true negatives{p_end}

{title:Example}

{phang2}{cmd:. midas bclust2bin tp fp fn tn np, id(author year)}{p_end}
{phang2}{cmd:. midas mle midas_tp midas_fp midas_fn midas_tn, id(author year)}{p_end}

{title:References}

{phang}
Donner A, Klar N. {it:Design and Analysis of Cluster Randomization Trials in Health Research.}
Arnold, London, 2000.

{title:Author}

{phang}Ben A. Dwamena, University of Michigan.{p_end}
{phang}bdwamena@umich.edu{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas con2bin}, {helpb midas ord2bin}, {helpb midas ipd2ad}
