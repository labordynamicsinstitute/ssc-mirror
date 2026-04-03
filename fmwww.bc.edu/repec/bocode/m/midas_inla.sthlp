{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas inla}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas inla} {hline 2} Bayesian estimation via Integrated Nested Laplace Approximation

{title:Syntax}

{p 8 18 2}
{cmd:midas inla}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:rpath(}{it:path}{cmd:)}
[{cmd:workdir(}{it:path}{cmd:)}
{cmd:id(}{it:varname}{cmd:)}
{cmd:covmatrix(}{it:structure}{cmd:)}
{cmd:approximation(}{it:method}{cmd:)}
{cmd:integration(}{it:strategy}{cmd:)}
{cmd:nip(}{it:#}{cmd:)}
{cmd:stable}
{cmd:manual}
{cmd:showcode}
{cmd:hpd}
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
{cmd:midas inla} fits the bivariate random-effects model using the
R-INLA package via a Stata-R interface. INLA provides fast approximate
Bayesian inference, particularly suited to models with Gaussian latent
fields. R and the R-INLA package must be installed.

{title:Key options}

{phang}
{cmd:rpath(}{it:path}{cmd:)} path to the R executable (e.g.,
{cmd:C:/Program Files/R/R-4.3.0/bin/Rscript.exe}). Required.

{phang}
{cmd:workdir(}{it:path}{cmd:)} working directory for temporary R files.
Defaults to the Stata personal ado directory.

{phang}
{cmd:covmatrix(}{it:structure}{cmd:)} covariance prior structure.
Same options as {helpb midas mh}.

{phang}
{cmd:approximation(}{it:method}{cmd:)} INLA approximation strategy:
{cmd:gaussian} (default), {cmd:laplace}, or {cmd:simplified.laplace}.

{phang}
{cmd:integration(}{it:strategy}{cmd:)} integration strategy:
{cmd:eb} (empirical Bayes, default), {cmd:ccd}, {cmd:grid}, or {cmd:gh}.

{phang}
{cmd:nip(}{it:#}{cmd:)} number of integration points. Default 20.

{phang}
{cmd:stable} uses INLA's numerically stable mode.

{phang}
{cmd:manual} calls R-INLA manually rather than using the automatic interface.

{phang}
{cmd:showcode} displays the generated R code.

{title:Example}

{phang2}{cmd:. midas inla tp fp fn tn, id(author) rpath("C:/R/bin/Rscript.exe") covmatrix(cholesky)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas mh}, {helpb midas hmc}
