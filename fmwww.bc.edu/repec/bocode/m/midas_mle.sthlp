{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas mle}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas mle} {hline 2} Bivariate MLE via meqrlogit with Gaussian quadrature

{title:Syntax}

{p 8 18 2}
{cmd:midas mle}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:id(}{it:varlist}{cmd:)}
[{cmd:integration(}{it:method}{cmd:)}
{cmd:nip(}{it:#}{cmd:)}
{cmd:sortby(}{it:varlist}{cmd:)}
{cmd:level(}{it:#}{cmd:)}
{cmd:noheader}
{cmd:nocoefficients}
{cmd:nosummary}
{cmd:nofitstat}
{cmd:hetstats}
{cmd:hsroc}
{cmd:revman}]

{title:Description}

{pstd}
{cmd:midas mle} fits the bivariate random-effects model for diagnostic
test accuracy meta-analysis using maximum likelihood estimation via
Stata's {helpb meqrlogit} command with adaptive Gaussian quadrature.
It jointly models logit sensitivity and logit specificity with an
unstructured between-study covariance matrix.

{title:Options}

{phang}
{cmd:id(}{it:varlist}{cmd:)} study identifier variable(s). Required.

{phang}
{cmd:integration(}{it:method}{cmd:)} quadrature method:
{cmd:mvaghermite} (mean-variance adaptive GHQ, default),
{cmd:pcaghermite} (product-rule adaptive GHQ), or
{cmd:mcaghermite} (Monte Carlo adaptive GHQ).

{phang}
{cmd:nip(}{it:#}{cmd:)} number of integration points. Default 20.

{phang}
{cmd:sortby(}{it:varlist}{cmd:)} sort studies before estimation.

{phang}
{cmd:level(}{it:#}{cmd:)} confidence level. Default 95.

{phang}
{cmd:noheader} suppresses the estimation header.

{phang}
{cmd:nocoefficients} suppresses the coefficient table.

{phang}
{cmd:nosummary} suppresses the summary accuracy table.

{phang}
{cmd:nofitstat} suppresses fit statistics (AIC, BIC, log-likelihood).

{phang}
{cmd:hetstats} displays heterogeneity/inconsistency statistics (I-squared).

{phang}
{cmd:hsroc} displays derived HSROC model parameters (alpha, theta, beta).

{phang}
{cmd:revman} displays parameters formatted for import into RevMan.

{title:Example}

{phang2}{cmd:. midas mle tp fp fn tn, id(author year) hetstats hsroc}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas qrsim}, {helpb midas mh}, {helpb midas hmc}, {helpb midas inla}
