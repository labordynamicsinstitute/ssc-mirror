{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas lrmat}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas lrmat} {hline 2} Likelihood ratio matrix and post-test probability table

{title:Syntax}

{p 8 18 2}
{cmd:midas lrmat}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,}
{cmd:level(}{it:#}{cmd:)}
{cmd:wgt}
{cmd:cc(}{it:#}{cmd:)}
{cmd:xrange(}{it:# #}{cmd:)}
{cmd:yrange(}{it:# #}{cmd:)}
{it:graph_options}]

{title:Description}

{pstd}
{cmd:midas lrmat} displays the positive and negative likelihood ratios
(LR+ and LR-) derived from the bivariate summary estimates, and produces a
likelihood ratio matrix plot showing post-test probabilities across a range
of pre-test probabilities.

{title:Options}

{phang}
{cmd:wgt} weights observations by study size when computing the display.

{phang}
{cmd:cc(}{it:#}{cmd:)} continuity correction for zero cells. Default {cmd:cc(0.5)}.

{phang}
{cmd:xrange(}{it:lo hi}{cmd:)} x-axis range for the matrix plot.

{phang}
{cmd:yrange(}{it:lo hi}{cmd:)} y-axis range for the matrix plot.

{title:Example}

{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas lrmat}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas fagan}, {helpb midas condiplot}
