{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas mh}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas mh} {hline 2} Bayesian estimation via Metropolis-Hastings MCMC

{title:Syntax}

{p 8 18 2}
{cmd:midas mh}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:id(}{it:varlist}{cmd:)}
{cmd:covariance(}{it:structure}{cmd:)}
[{cmd:chains(}{it:#}{cmd:)}
{cmd:mcsize(}{it:#}{cmd:)}
{cmd:burn(}{it:#}{cmd:)}
{cmd:thin(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}
{cmd:dots(}{it:#}{cmd:)}
{cmd:parallel}
{cmd:convergestats}
{cmd:muprior(}{it:string}{cmd:)}
{cmd:sigmaprior(}{it:string}{cmd:)}
{cmd:phiprior(}{it:string}{cmd:)}
{cmd:rhoprior(}{it:string}{cmd:)}
{cmd:lamdaprior(}{it:string}{cmd:)}
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
{cmd:midas mh} fits the bivariate random-effects model using a
Metropolis-Hastings MCMC sampler with user-specifiable prior distributions.
Seven covariance prior structures are available, ranging from the standard
inverse-Wishart to more flexible hierarchical priors.

{title:Covariance structures}

{p2colset 9 22 22 2}
{p2col:{cmd:iwishart}}inverse-Wishart (default){p_end}
{p2col:{cmd:cholesky}}Cholesky decomposition{p_end}
{p2col:{cmd:spherical}}spherical parameterisation{p_end}
{p2col:{cmd:cholefisher}}Cholesky with Fisher z correlation{p_end}
{p2col:{cmd:product}}product-normal{p_end}
{p2col:{cmd:sciwishart}}scaled inverse-Wishart{p_end}
{p2col:{cmd:hiwishart}}hierarchical inverse-Wishart{p_end}

{title:Key options}

{phang}
{cmd:chains(}{it:#}{cmd:)} number of MCMC chains. Default 4.

{phang}
{cmd:mcsize(}{it:#}{cmd:)} post-burn-in iterations per chain. Default 20000.

{phang}
{cmd:burn(}{it:#}{cmd:)} burn-in iterations. Default 20000.

{phang}
{cmd:thin(}{it:#}{cmd:)} thinning interval. Default 1.

{phang}
{cmd:seed(}{it:#}{cmd:)} random seed. Default 12345.

{phang}
{cmd:dots(}{it:#}{cmd:)} display a dot every {it:#} iterations. Default 10000.

{phang}
{cmd:parallel} runs chains in parallel using Stata's {cmd:parallel} package.

{phang}
{cmd:convergestats} displays Gelman-Rubin R-hat and effective sample size.

{phang}
{cmd:hpd} reports highest posterior density (HPD) intervals instead of equal-tail intervals.

{phang}
{cmd:muprior(}{it:string}{cmd:)} prior for the mean logit parameters.
Default {cmd:normal(0,100)}.

{phang}
{cmd:sigmaprior(}{it:string}{cmd:)} prior for standard deviations.
Default {cmd:cauchy(0,2.5)}.

{title:Example}

{phang2}{cmd:. midas mh tp fp fn tn, id(author) covariance(cholesky) chains(4) mcsize(10000) hpd}{p_end}
{phang2}{cmd:. midas bayesplot}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas hmc}, {helpb midas inla}, {helpb midas bayesplot}
