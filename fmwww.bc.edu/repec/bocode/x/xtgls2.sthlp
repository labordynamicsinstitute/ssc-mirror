
{smcl}
{* *! version 1.1, 09 Aug 2025}{...}
{cmd:help xtgls2}			Version 1.1, 09 Aug 2025, by Manh Hoang Ba
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{pstd}{cmd:xtgls2} {hline 2} Estimating General GLS estimator for large {cmd:N}, small {cmd:T} panel data models. 
{p2colreset}{...}


{title:Syntax}

{pstd}{cmd:xtgls2} {varlist} {ifin} [{cmd:,} {cmdab:nocon:stant} {cmd:ols} {cmd:fe} {cmd:fd} {cmdab:c:ov(c|h)} {cmdab:cl:uster(varname)} {cmd:nmk} {cmd:minus(}{it:num}{cmd:)}
{cmdab:l:evel(}{it:num}{cmd:)} {cmd:igls} {cmdab:iter:ate(}{it:num}{cmd:)} {cmdab:tol:erance(}{it:num}{cmd:)} {cmdab:nolo:g} {cmdab:lo:g}]


{title:Description}

{pstd}{cmd:xtgls2} estimates General GLS estimator for large {cmd:N}, small {cmd:T} linear panel data models (Pooled, FE, FD), aiming to obtain (asymptotically) efficient estimates in the context of non-spherical characteristic errors.

{pstd}Specifically, in each estimator, the error covariance matrix is assumed to have a general (or restricted) form within panels, and to be the same across panels. These assumptions can be relaxed, for example, there is no correlation between observations within panels. In the context of heteroscedastic errors across panels, panelvar-clustered standard errors (Arellano, 1987) can be used. For more details, see Kiefer (1980) and Wooldridge (2002, 2010).

{pstd}In summary, {cmd:xtgls2} allows researchers to control for heteroscedasticity across panels, over time periods, and general correlation within panels. {cmd:xtgls2} is appropriate for balanced panel data with {cmd:N >> T} and data must be {help xtset} before using this command.

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}

{synopt :{opt nocons:tant}}suppress constant term, required when {opt fe} or {opt fd} option is specified.{p_end}
{synopt :{opt ols}}use feasible pooled GLS estimator, default.{p_end}
{synopt :{opt fe}}use feasible fixed-effects GLS estimator.{p_end}
{synopt :{opt fd}}use feasible first-difference GLS estimator.{p_end}
{synopt :{cmdab:c:ov(c)}}use heteroskedastic and correlated error structure within panels.{p_end}
{synopt :{cmdab:c:ov(h)}}use heteroskedastic error structure within panels.{p_end}
{synopt :{cmd:igls}}use iterated GLS estimator instead of two-step GLS estimator.{p_end}

{syntab:SE}
{synopt :{cmdab:cl:uster(varname)}}use varname-clustered standard errors, required when {opt minus(#)} is specified.{p_end}
{synopt :{opt nmk}}normalize standard error by N-k instead of N.{p_end}
{synopt :{opt minus(#)}}controls the degrees of freedom adjustment factor in the robust, or cluster-robust variance calculation. Default value is {opt minus(0)}.{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}.{p_end}

{syntab:Optimization}
{synopt :{opt iter:ate(#)}}specifies the maximum number of iterations; default is {cmd:iterate(50)}.{p_end}
{synopt :{opt tol:erance(#)}}specifies the tolerance for the coefficient vector; default is {cmd:tolerance(1e-7)}.{p_end}
{synopt :{opt lo:g}}display the iteration log. This is default.{p_end}
{synopt :{opt nolo:g}}does not display the iteration log.{p_end}

{synoptline}
{p2colreset}{...}

{title:Postestimation}

{pstd}The following postestimation commands are available after {cmd:xtgls2}:

{synoptset 25 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{cmd:estimates}}cataloging estimation results.{p_end}
{synopt :{cmd:predict}}predictions and their SEs.{p_end}
{synopt :{cmd:test}}Wald tests of simple and composite linear hypotheses.{p_end}
{synopt :{cmd:testln}}Wald tests of nonlinear hypotheses.{p_end}
{synopt :{cmd:lincom}}point estimates, standard errors, testing, and inference for linear combinations of parameters.{p_end}
{synopt :{cmd:nlcom}}point estimates, standard errors, testing, and inference for nonlinear combinations of parameters.{p_end}
{synopt :{cmd:margins}}marginal means, predictive margins, marginal effects, and average marginal effects.{p_end}
{synoptline}
{p2colreset}{...}

{title:Examples}

{pstd}. webuse abdata, clear

{pstd}. xtbalance, range(1980 1984)

{pstd}. xtgls2 n w c.(k ys)##c.(k ys) i.ind i.year, cov(c)

{pstd}. xtgls2 n w c.(k ys)##c.(k ys) i.ind i.year, c(h) fe nocons

{pstd}. xtgls2 n w c.(k ys)##c.(k ys) i.ind i.year, c(h) fe nocons cl(id)

{pstd}. xtgls2 n l(1/2).w c.(k ys)##c.(k ys) i.ind i.year, c(c) fd nocons

{pstd}. xtgls2 n l(1/2).w c.(k ys)##c.(k ys) i.ind i.year, c(c) fd nocons cl(id)


{title:Acknowledgements}

{pstd} I would like to thank Gueorgui I. Kolev, who wrote the {cmd:xtglsr} command, I benefited a lot from his command when calculating clustered standard errors.

{title:References}

{pstd} Arellano, M. (1987). Computing robust standard errors for within-groups estimators. Oxford Bulletin of Economics & Statistics, 49(4).

{pstd} Kiefer, N. M. (1980). Estimation of fixed effect models for time series of cross-sections with arbitrary intertemporal covariance. Journal of econometrics, 14(2), 195-202.

{pstd} Kolev, G. I. (2021). XTGLSR: Stata module to calculate robust, or cluster-robust variance after xtgls (Statistical Software Components No. S458935). Boston College Department of Economics.

{pstd} Wooldridge, J. M. (2002). Econometric analysis of cross section and panel data MIT press. Cambridge, ma, 108(2), 245-254.

{pstd} Wooldridge, J. M. (2010). Econometric analysis of cross section and panel data. MIT press.

{title:Authors}

	Manh Hoang Ba, Eureka Uni Team, Vietnam
	hbmanh9492@gmail.com

{title:Also see}

{pstd}Online: help for {help xtgls}, {help xtglsr} {if installed}, {help xttest3} (if installed), {help xttest4} (if installed).


