{smcl}
{* version 1.00  23mar2026}{...}
{cmd:help midas bayesplot}{right:also see: {helpb midas}}
{hline}

{title:Title}

{p 4 18 2}
{hi:midas bayesplot} {hline 2} MCMC diagnostic plots

{title:Syntax}

{p 8 18 2}
{cmd:midas bayesplot}

{title:Description}

{pstd}
{cmd:midas bayesplot} displays convergence diagnostic plots for the MCMC
chains from {cmd:midas mh} or {cmd:midas hmc}. Four panels are produced:

{phang2}(1) {bf:Trace plots} -- chain values by iteration for each parameter.{p_end}
{phang2}(2) {bf:Density plots} -- posterior density of each parameter.{p_end}
{phang2}(3) {bf:Autocorrelation plots} -- ACF of the chain to assess mixing.{p_end}
{phang2}(4) {bf:Running mean plots} -- cumulative mean convergence.{p_end}

{pstd}
Must follow {cmd:midas mh} or {cmd:midas hmc}. Not available after
{cmd:midas mle}, {cmd:midas qrsim}, or {cmd:midas inla}.

{title:Example}

{phang2}{cmd:. midas mh tp fp fn tn, id(author) covariance(cholesky) chains(4)}{p_end}
{phang2}{cmd:. midas bayesplot}{p_end}

{title:Also see}

{psee}
{helpb midas}, {helpb midas mh}, {helpb midas hmc}
