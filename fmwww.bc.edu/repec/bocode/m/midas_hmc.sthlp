{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas hmc}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas hmc} {hline 2} Bayesian estimation via Hamiltonian Monte Carlo (CmdStan)

{title:Syntax}

{p 8 18 2}
{cmd:midas hmc}
{it:tp fp fn tn}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
{cmd:,}
{cmd:id(}{it:varlist}{cmd:)}
{cmd:covariance(}{it:structure}{cmd:)}
{cmd:modelfile(}{it:filename}{cmd:)}
[{cmd:standir(}{it:path}{cmd:)}
{cmd:outputfile(}{it:filename}{cmd:)}
{cmd:chains(}{it:#}{cmd:)}
{cmd:warmup(}{it:#}{cmd:)}
{cmd:iter(}{it:#}{cmd:)}
{cmd:thin(}{it:#}{cmd:)}
{cmd:seed(}{it:#}{cmd:)}
{cmd:adaptdelta(}{it:#}{cmd:)}
{cmd:maxtreedepth(}{it:#}{cmd:)}
{cmd:threads(}{it:#}{cmd:)}
{cmd:threadsperchain(}{it:#}{cmd:)}
{cmd:variational}
{cmd:vialgorithm(}{it:string}{cmd:)}
{cmd:convergestats}
{cmd:showcode}
{cmd:log}
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
{cmd:midas hmc} fits the bivariate random-effects model using the
No-U-Turn Sampler (NUTS), a variant of Hamiltonian Monte Carlo, via
CmdStan. It provides superior mixing compared to {cmd:midas mh} for
complex posterior geometries.

{pstd}
CmdStan must be installed and the Stan model file must be provided.
See {browse "https://mc-stan.org/cmdstan":mc-stan.org/cmdstan} for installation.

{title:Key options}

{phang}
{cmd:covariance(}{it:structure}{cmd:)} covariance prior structure.
Same options as {helpb midas mh}. Required.

{phang}
{cmd:modelfile(}{it:filename}{cmd:)} path to the Stan {cmd:.stan} model file. Required.

{phang}
{cmd:standir(}{it:path}{cmd:)} CmdStan installation directory.

{phang}
{cmd:warmup(}{it:#}{cmd:)} warmup iterations per chain. Default 1000.

{phang}
{cmd:iter(}{it:#}{cmd:)} sampling iterations per chain. Default 2000.

{phang}
{cmd:adaptdelta(}{it:#}{cmd:)} target acceptance rate (0-1). Higher values
reduce divergences. Default 0.8.

{phang}
{cmd:maxtreedepth(}{it:#}{cmd:)} maximum tree depth for NUTS. Default 10.

{phang}
{cmd:threads(}{it:#}{cmd:)} total threads for within-chain parallelism.

{phang}
{cmd:variational} uses variational inference instead of MCMC.

{phang}
{cmd:showcode} displays the Stan model code.

{phang}
{cmd:log} displays the CmdStan sampling log.

{title:Example}

{phang2}{cmd:. midas hmc tp fp fn tn, id(author) covariance(cholesky) modelfile(bivar.stan) warmup(1000) iter(2000)}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas mh}, {helpb midas inla}, {helpb midas bayesplot}
