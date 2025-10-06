
{smcl}
{* *! version 1.4, 30 Sep 2025}{...}
{cmd:help xtgls2}		Version 1.4, 30 Sep 2025, Manh Hoang Ba (hbmanh9492@gmail.com)
{hline}

{title:Title}

{p2colset 5 18 20 2}{...}
{pstd}{cmd:xtgls2} {hline 2} Estimating General GLS estimator for large N, small T panel data models. 
{p2colreset}{...}


{title:Syntax}

{p 12 8 2}{cmd:xtgls2} {depvar} [{indepvars}] {ifin} {cmd:,} {it:options}


{title:Description}

{pstd}{cmd:xtgls2} estimates General GLS estimator for large N, small T linear panel data models (Pooled, FE, FD), aiming to obtain (asymptotically) efficient estimators in the context of non-spherical idiosyncratic errors.{p_end}

{pstd}Specifically, in each estimator, the error covariance matrix is assumed to have a general form within panels, and identical across panels. For more details, see Kiefer (1980) and Wooldridge (2002, 2010).{p_end}

{pstd}{cmd:xtgls2} is appropriate for balanced panel data with N >> T and data must be {help xtset}.{p_end}

{p 4 8 2}The latest version of {cmd:xtgls2} can be found at the following link: {browse "https://github.com/ManhHB94/":https://github.com/ManhHB94/}{p_end}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt nocons:tant}}suppress constant term, required when {opt fe} or {opt fd} option is specified.{p_end}
{synopt :{opt ols}}use feasible pooled GLS estimator, default.{p_end}
{synopt :{opt fe}}use feasible fixed-effects GLS estimator.{p_end}
{synopt :{opt fd}}use feasible first-difference GLS estimator.{p_end}
{p2coldent:* {cmdab:c:ov(c)}}use heteroskedastic and correlated error structure within panels.{p_end}
{p2coldent:* {cmdab:c:ov(h)}}use heteroskedastic error structure within panels, this cannot be specified together with {opt fe} or {opt fd} option.{p_end}
{synopt :{cmd:igls}}use iterated GLS estimator instead of two-step GLS estimator.{p_end}

{syntab:SE}
{synopt :{cmdab:cl:uster(varname)}}use varname-clustered standard errors, required when {opt minus(#)} is specified.{p_end}
{synopt :{opt nmk}}normalize standard error by N-k instead of N.{p_end}
{synopt :{opt minus(#)}}controls the degrees of freedom adjustment factor in the robust, or cluster-robust variance calculation. Default value is {cmd:minus(0)}.{p_end}

{syntab:Reporting}
{synopt :{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}.{p_end}

{syntab:Optimization}
{synopt :{opt iter:ate(#)}}specifies the maximum number of iterations; default is {cmd:iterate(50)}.{p_end}
{synopt :{opt tol:erance(#)}}specifies the tolerance for the coefficient vector; default is {cmd:tolerance(1e-7)}.{p_end}
{synopt :{opt lo:g}}display the iteration log. This is default.{p_end}
{synopt :{opt nolo:g}}does not display the iteration log.{p_end}

{synoptline}
{p2colreset}{...}
{p 4 8 2}* You must specify either {cmd:cov(c)} or {cmd:cov(h)}.{p_end}

{title:Citation}
{p 4 8 2}{cmd:xtgls2} is not an official Stata command.
It is a free contribution to the research community.
Please cite it as such: {p_end}
{p 8 8 2}Manh Hoang Ba, 2025. "XTGLS2: Stata module to estimate GLS estimator for large N, small T panel data models," Statistical Software Components S459497, Boston College Department of Economics.{p_end}

{title:Postestimation}

{pstd}The following postestimation commands are available after {cmd:xtgls2}:

{synoptset 25 tabbed}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{p2coldent:* {bf:{help estat ic}}}Akaike's, consistent Akaike's, corrected Akaike's, and Schwarz's Bayesian information criteria (AIC, CAIC, AICc, and BIC,respectively){p_end}
{synopt :{bf:{help estimates}}}cataloging estimation results.{p_end}
{synopt :{bf:{help predict}}}predictions and their SEs.{p_end}
{synopt :{bf:{help test}}}Wald tests of simple and composite linear hypotheses.{p_end}
{synopt :{bf:{help testnl}}}Wald tests of nonlinear hypotheses.{p_end}
{p2coldent:* {bf:{help lrtest}}}likelihood-ratio test{p_end}
{synopt :{bf:{help lincom}}}point estimates, standard errors, testing, and inference for linear combinations of parameters.{p_end}
{synopt :{bf:{help nlcom}}}point estimates, standard errors, testing, and inference for nonlinear combinations of parameters.{p_end}
{synopt :{bf:{help margins}}}marginal means, predictive margins, marginal effects, and average marginal effects.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 8 2}* {cmd:estat ic} and {cmd:lrtest} are available only if {cmd:igls} is specified at estimation.{p_end}

{title:Examples}

{phang2} {stata . webuse abdata, clear}{p_end}

{phang2} {stata . keep if year > 1977 & year < 1983}{p_end}

{phang2} {stata `". xtgls2 n w k ys i.ind i.year , cov(c)"'}{p_end}

{phang2} {stata `". xtgls2 n w k ys i.year, c(c) fe nocons"'}{p_end}

{phang2} {stata `". xtgls2 n w k ys i.year, c(c) fe nocons cl(id)"'}{p_end}

{phang2} {stata `". xtgls2 n l(0/2).w k ys i.year, c(c) fd nocons"'}{p_end}

{phang2} {stata `". xtgls2 n l(0/2).w k ys i.year, c(c) fd nocons cl(id)"'}{p_end}


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


