{smcl}
{* *! version 1.0.0  2025-11-30}{...}
{title:Title}

{phang}{cmd:regoptwgt} {hline 2} Optimal population weighting for regressions and instrumental variables{p_end}

{marker syntax}{...}
{title:Syntax}

{phang}{cmd:regoptwgt} {it:depvar}
[{it:varlist1}]
[{cmd:(}{it:varlist2}{cmd:=}{it:varlist3}{cmd:)}]
{cmd:[w=}{it:weight_variable}{cmd:]}
{ifin} 
[{cmd:,} {it:options}]
{p_end}

{synoptset 20 tabbed}{...}
{marker table_options}{...}
{synopthdr}
{synoptline}
{synopt:{opt tech:nique}}maximization technique; see {help maximize##algorithm_spec}; default is {cmd:nr bhhh dfp bfgs}{p_end}
{synopt:{opt iter:ate(#)}}perform maximum of # iterations; default is {cmd:iterate(300)}{p_end}
{synopt:{opt cl:uster(varlist)}}cluster standard errors by {it:varlist}{p_end}
{synopt:{opt r:obust}}this option has no effect; errors are always robust{p_end}
{synopt:{opt jackknife}}estimate standard errors with a jackknife method; if used, only one cluster variable is allowed{p_end}
{synopt:{opt dif:ficult}}use a different stepping algorithm in nonconcave regions{p_end}
{synopt:{opt mlsearch(#)}}if # is nonnegative, perform {cmd:ml search, repeat(#)} before maximization; default is to not do this{p_end}
{synopt:{opt initnowgt}}unlike the default, do not initialize search at the parameter estimates for an unweighted regression{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:regoptwgt} estimates regression coefficients based on an optimal weighting that takes into account both
(1) variance in the error term that is correlated with the inverse of the weighting variable, and 
(2) variance in the error term that is independent of the weighting variable.
Estimates are calculated using limited information maximum likelihood.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:regoptwgt} uses similar syntax to commands {cmd:regress}, {cmd:ivregress 2sls} and other related commands.
It is therefore often possible to simply replace these commands with {cmd:regoptwgt} to get the optimally-weighted estimate.

{pstd}
{cmd:regoptwgt} estimates the equations requested, as well as extra parameters that measure the extent of heteroskedasticity correlated with the given weight.
{it:lnetasq} parameters measure the natural log of the estimated variance of the part of the error term that is correlated with the weight; {it:lnnusq} parameters measure the natural log of the estimated variance of the part of the error term that is NOT correlated with the weight.
{it:fncorr} parameters measure a monotonically increasing function of the correlation between the {it:lnetasq} and {it:lnnusq} parameters in each equation.
These parameters are described in more detail in the companion article, which will be released shortly.

{pstd}
{cmd:regoptwgt} works with any number of endogenous variables, but it is very slow if there are two or more right hand side endogenous variables.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{pmore}{cmd:. set seed 0}{p_end}
{pmore}{cmd:. clear}{p_end}
{pmore}{cmd:. set obs 100}{p_end}
{pmore}{cmd:. gen pop = 1/_n}{p_end}
{pmore}{cmd:. gen z = rnormal()}{p_end}
{pmore}{cmd:. gen xeta = rnormal()}{p_end}
{pmore}{cmd:. gen x = z + rnormal() + .1/sqrt(pop)*(xeta + rnormal())}{p_end}
{pmore}{cmd:. gen y = x + rnormal() + .1/sqrt(pop)*(xeta + rnormal())}{p_end}

{pstd}Simple regression{p_end}
{pmore}{cmd:. regoptwgt y z [w=pop]}{p_end}

{pstd}Instrumental variables regression{p_end}
{pmore}{cmd:. regoptwgt y (x=z) [w=pop]}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
The final step of {cmd:regoptwgt} is a maximum likelihood estimation, so the command inherits stored results from {helpb ml maximize}. This includes the following stored in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of parameters{p_end}
{synopt:{cmd:e(ll)}}log likelihood{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(depvar)}}names of dependent variables{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}coefficient vector{p_end}
{synopt:{cmd:e(V)}}variance-covariance matrix of the estimators{p_end}

{marker author}{...}
{title:Author}

{pstd}David J. Price{p_end}
{pstd}{browse "mailto:david.price@utoronto.ca":david.price@utoronto.ca}{p_end}
{pstd}{browse "https://davidjonathanprice.com":davidjonathanprice.com}{p_end}

{marker citation}{...}
{title:Citation}

{pstd}Please cite:{p_end}
{pstd}David J. Price (2025). Power Law Heteroskedasticity.{p_end}

{marker acknowledgment}{...}
{title:Acknowledgment}

{pstd}
Multiway clustering uses {helpb vcemway}.
{p_end}