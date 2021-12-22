{smcl}
{* *! version 1.0 03 Jan 2019}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install mvtnorm" "ssc install MVTNORM"}{...}
{vieweralsosee "Help mvtnorm (if installed)" "help mvtnorm"}{...}
{viewerjumpto "Description" "mvtnorm##description"}{...}
{viewerjumpto "Remarks" "mvtnorm##remarks"}{...}
{viewerjumpto "Examples" "mvtnorm##examples"}{...}
{title:Title}
{phang}
{bf:mvtnorm} {hline 2} Module to work with the multivariate normal and multivariate t distributions, with and without variable truncation

{marker description}{...}
{title:Description}

{pstd}
{bf:mvtnorm} provides a set of rclass commands for working with the multivariate normal and multivariate t distributions, with and without truncation.
Specifically, commands are available to: (1)
evaluate probability density functions, (2)
generate random deviates, (3)
evaluate distribution functions, and (4)
compute equicoordinate quantiles.
{p_end}

{pstd}
The best place to start to learn about the available commands is the associated {it:Stata J} article, Grayling and Mander (2018), which contains examples on how to (1)
compare the probability density functions of multivariate normal and multivariate t distributions, (2)
compare the familywise error-rates provided by Bonferroni and Dunnett's multiple comparison corrections, (3)
visualise the value of orthont probabilities in the presence of truncation.
{p_end}

{pstd}
However, the available functionality is highly motivated by the established R package of the same name (Genz {it:et al}, 2018), and the R package {bf:tmvtnorm} (Wilhelm and Manjunath, 2015).
Thus, their associated texts, Genz and Bretz (2009) and Wilhelm and Manjunath (2010), will also likely contain useful background information.
{p_end}

{pstd}
Note that some equivalent functionality is present in Stata for the multivaraite normal distribution via the built-in commands {help lnmvnormalden}, {help drawnorm}, and {help mvnormalcv}.
See below for further details.
{p_end}

{pstd}
Finally, note that the file "mvtnorm_mata.do" contains a set of equivalent Mata functions, to allow utilisation in Stata to be bypassed if desired.
{p_end}

{title:Available commands}

{bf:Multivariate normal distribution}

{phang}
{help invmvnormal}: A command for computing equicoordinate quantiles of the multivariate normal distribution,
based on inversion of integrals evaluated using {help pmvnormal} or {help mvnormalcv} in combination with Brent's root-finding algorithm (Brent, 1973).
{p_end}

{phang}
{help mvnormalden}: A command for evaluating the probability density function of the multivariate normal distribution.
Provided only for completeness; in general {help lnmvnormalden} should be preferred.
{p_end}

{phang}
{help pmvnormal}: A command for evaluating the distribution function of the multivariate normal distribution.
For one- and two-dimensional multivariate normal distributions it makes use of the functionality provided by {help normal} and {help binormal} respectively.
For multivariate normal distributions of dimension three or more it utilises a Stata implementation of the algorithm given on page 50 of Genz and Bretz (2009):
a quasi-Monte Carlo integration algorithm over a randomised lattice after separation-of-variables has been performed.
In addition, it employs variable re-ordering in order to improve efficiency as suggested by Gibson {it:et al} (1994).
As of v1.7, {cmd:pmvnormal} is also vectorised, which will make it run to completion substantially faster than previous versions.
As of the release of Stata 15, the built in command {help mvnormalcv} is available that provides equivalent functionality via numerical quadrature.
The limitations of quadrature mean that {help pmvnormal} may well have smaller run-time for high-dimensional multivariate normal distributions (roughly of dimension greater than four).
However, for low-dimensional problems, {help mvnormalcv} should in general be preferred.
{p_end}

{phang}
{help rmvnormal}: A command for generating random deviates of the multivariate normal distribution.
Provided only for completeness; in general {help drawnorm} should be preferred.
{p_end}

{bf:Multivariate t distribution}

{phang}
{help invmvt}: A command for computing equicoordinate quantiles of the multivariate t distribution,
based on inversion of integrals evaluated using {help mvt} in combination with Brent's root-finding algorithm (Brent, 1973).
{p_end}

{phang}
{help mvtden}: A command for evaluating the probability density function of the multivariate t distribution.
{p_end}

{phang}
{help mvt}: A command for evaluating the distribution function of the multivariate t distribution.
For one-dimensional multivariate t distributions (i.e., univariate t distributions) it makes use of the functionality provided by {help t}. 
For multivariate t distributions of dimension two or more it utilises a Stata implementation of the algorithm given on page 50 of Genz and Bretz (2009):
a quasi-Monte Carlo integration algorithm over a randomised lattice after separation-of-variables has been performed.
In addition, it employs variable re-ordering in order to improve efficiency as suggested by Gibson {it:et al} (1994).
However, note that unlike {help pmvnormal}, {cmd:mvt} is not yet vectorised, which may make its run time long compared to the corresponding multivariate normal commands.
{p_end}

{phang}
{help rmvt}: A command for generating random deviates of the multivariate t distribution.
{p_end}

{bf:Truncated multivariate normal distribution}

{phang}
{help invtmvnormal}: A command for computing equicoordinate quantiles of the truncated multivariate normal distribution,
based on inversion of integrals evaluated using {help tmvnormal} in combination with Brent's root-finding algorithm (Brent, 1973).
{p_end}

{phang}
{help tmvnormalden}: A command for evaluating the probability density function of the truncated multivariate normal distribution.
{p_end}

{phang}
{help tmvnormal}: A command for evaluating the distribution function of the truncated multivariate normal distribution,
using the method of {help pmvnormal} or {help mvnormalcv} for evaluating the requisite multivariate normal distribution functions.
{p_end}

{phang}
{help rtmvnormal}: A command for generating random deviates of the truncated multivariate normal distribution, based on accept/reject sampling of the corresponding multivariate normal distribution.
{p_end}

{bf:Truncated multivariate t distribution}

{phang}
{help invtmvt}: A command for computing equicoordinate quantiles of the truncated multivariate t distribution,
based on inversion of integrals evaluated using {help tmvt} in combination with Brent's root-finding algorithm (Brent, 1973).
{p_end}

{phang}
{help tmvtden}: A command for evaluating the probability density function of the truncated multivariate t distribution.
{p_end}

{phang}
{help tmvt}: A command for evaluating the distribution function of the truncated multivariate t distribution, using the method of {help mvt} for evaluating the requisite multivariate t distribution functions.
{p_end}

{phang}
{help rtmvt}: A command for generating random deviates of the truncated multivariate t distribution, based on accept/reject sampling of the corresponding multivariate t distribution.
{p_end}

{title:Authors}
{p}

Dr Michael J Grayling
Population Health Sciences Institute, Newcastle University, UK
Email: {browse "michael.grayling@newcastle.ac.uk":michael.grayling@newcastle.ac.uk}

Prof Adrian P Mander
Centre for Trials Research, Cardiff University, Cardiff, UK

{title:References}

{phang}
Brent R (1973) {it:Algorithms for minimization without derivatives}. Prentice-Hall: New Jersey, US.

{phang}
Genz A, Bretz F (2009) {it:Computation of multivariate normal and t probabilities}. Lecture Notes in Statistics, Vol 195. Springer-Verlag: Heidelberg, Germany.

{phang}
Genz A, Bretz F, Miwa T, Mi X, Leisch F, Scheipl F, Hothorn T (2018). mvtnorm: Multivariate normal and t distributions. R package version 1.0-8. URL:{browse "http://CRAN.R-project.org/package=mvtnorm":http://CRAN.R-project.org/package=mvtnorm}.

{phang}
Gibson GJ, Glasbey CA, Elston DA (1994) Monte Carlo evaluation of multivariate normal integrals and sensitivity to variate ordering.
In {it:Advances in numerical methods and applications}, ed Dimov IT, Sendov B, Vassilevski PS, 120-6. River Edge: World Scientific Publishing.

{phang}
Grayling MJ, Mander AP (2018) {browse "https://www.stata-journal.com/article.html?article=st0542":Calculations involving the multivariate normal and multivariate t distributions with and without truncation}. {it:Stata J} {bf:18}(4){bf::}826-43.

{phang}
Kotz S, Nadarajah S (2004) {it:Multivariate t distributions and their applications}. Cambridge University Press: Cambridge, UK.

{phang}
Tong YL (2012) {it:The multivariate normal distribution}. Springer-Verlag: New York, US.

{phang}
Wilhelm S, Manjunath BG (2010) {browse "https://doi.org/10.32614/RJ-2010-005":tmvtnorm: A package for the truncated multivariate normal distribution}. {it: R J} {bf:2}(1){bf::}25-9.

{phang}
Wilhelm S, Manjunath BG (2015) tmvtnorm: Truncated multivariate normal and student t distribution. R package version 1.4-10. URL:{browse "https://cran.r-project.org/package=tmvtnorm":https://cran.r-project.org/package=tmvtnorm}.

