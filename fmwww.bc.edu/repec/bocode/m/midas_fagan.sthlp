{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas fagan}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas fagan} {hline 2} Fagan nomogram for clinical probability revision

{title:Syntax}

{p 8 18 2}
{cmd:midas fagan}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:pretestprob(}{it:numlist}{cmd:)}
[{cmd:lrplus(}{it:#}{cmd:)}
{cmd:lrminus(}{it:#}{cmd:)}
{cmd:usemodel}
{it:graph_options}]

{title:Description}

{pstd}
{cmd:midas fagan} displays a Fagan nomogram showing how the pre-test
probability of disease is revised to a post-test probability by the
positive and negative likelihood ratios from the bivariate meta-analysis.
Up to three pre-test probabilities may be specified simultaneously.

{title:Options}

{phang}
{cmd:pretestprob(}{it:numlist}{cmd:)} one to three pre-test probabilities
(proportions between 0 and 1). Required.

{phang}
{cmd:lrplus(}{it:#}{cmd:)} override the summary LR+ from the model.

{phang}
{cmd:lrminus(}{it:#}{cmd:)} override the summary LR- from the model.

{phang}
{cmd:usemodel} forces use of the model LR estimates even if overrides are supplied.

{title:Example}

{phang2}{cmd:. midas mle tp fp fn tn, id(author)}{p_end}
{phang2}{cmd:. midas fagan, pretestprob(0.10 0.30 0.50)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas lrmat}, {helpb midas condiplot}
