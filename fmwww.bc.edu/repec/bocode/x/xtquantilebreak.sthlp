{smcl}
{* *! version 1.0.0  xtquantilebreak}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "xtquantilebreak##syntax"}{...}
{viewerjumpto "Description" "xtquantilebreak##description"}{...}
{viewerjumpto "Options" "xtquantilebreak##options"}{...}
{viewerjumpto "Methodology" "xtquantilebreak##method"}{...}
{viewerjumpto "Output" "xtquantilebreak##output"}{...}
{viewerjumpto "Examples" "xtquantilebreak##examples"}{...}
{viewerjumpto "Stored results" "xtquantilebreak##results"}{...}
{viewerjumpto "References" "xtquantilebreak##references"}{...}
{hi:help xtquantilebreak}{right:version 1.0.0}
{hline}

{title:Title}

{phang}
{bf:xtquantilebreak} {hline 2} Shrinkage quantile regression for panel data with
multiple structural breaks

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:xtquantilebreak} {depvar} {indepvars} {ifin}
[{cmd:,} {it:options}]

{pstd}
The data must be {bf:xtset} and form a strongly balanced panel before estimation.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt q:uantiles(numlist)}}quantile levels to estimate; default
{cmd:quantiles(0.25 0.5 0.75)}{p_end}
{synopt :{opt nocons:tant}}suppress the (break-varying) intercept{p_end}

{syntab:Penalization}
{synopt :{opt l2:ambda(numlist)}}grid of fused-lasso penalties searched by the
information criterion; default is a log-spaced grid{p_end}
{synopt :{opt l1:ambda(real)}}penalty on the individual effects; default
{cmd:lambda1(0.05)}{p_end}
{synopt :{opt k:appa(real)}}adaptive-weight exponent {it:{&kappa}}; default
{cmd:kappa(1)}{p_end}
{synopt :{opt r:constant(real)}}constant {it:r} in the IC penalty term; default
{cmd:rconstant(0.5)}{p_end}

{syntab:Numerical}
{synopt :{opt maxi:ter(integer)}}maximum block-coordinate-descent iterations;
default {cmd:maxiter(15)}{p_end}
{synopt :{opt tol:erance(real)}}convergence tolerance; default {cmd:tolerance(1e-4)}{p_end}

{syntab:Reporting}
{synopt :{opt nograph}}suppress graphical output{p_end}
{synopt :{opt heat:map}}add a break-intensity heatmap to the graphical output{p_end}
{synopt :{opt l:evel(#)}}confidence level for the plotted band; default
{cmd:level(95)}{p_end}
{synoptline}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtquantilebreak} estimates the panel quantile regression model of
{help xtquantilebreak##references:Zhang, Zhu, Feng and He (2022)}, in which the
slope coefficients are allowed to change at an unknown number of structural
breaks whose locations are determined by the data. For each requested quantile
level {it:{&tau}} the model is

{p 12 12 2}{it:Q}{subscript:{&tau}}({it:y}{subscript:it} | {it:x}{subscript:it}, {it:{&alpha}}{subscript:i}) = {it:{&alpha}}{subscript:i} + {it:x}{subscript:it}{c '}{it:{&beta}}{subscript:t,{&tau}}

{pstd}
where {it:{&alpha}}{subscript:i} are individual effects (shared across quantiles)
and {it:{&beta}}{subscript:t,{&tau}} are time-varying, quantile-specific slopes.
Breaks occur at periods where {it:{&beta}}{subscript:t,{&tau}} differs from
{it:{&beta}}{subscript:t-1,{&tau}}. The number and location of the breaks are
estimated jointly with the coefficients through an adaptive fused-lasso penalty,
and may differ across quantile levels. The covariate dimension {it:p} is
permitted to grow with the sample size.

{pstd}
Estimation proceeds in two stages. A penalized fit selects the break pattern; a
{help xtquantilebreak##references:post-lasso} unpenalized quantile regression is
then run on each detected regime to remove shrinkage bias and to obtain the
reported coefficients and standard errors.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt quantiles(numlist)} supplies the quantile levels, each strictly between 0
and 1, in increasing order. The break pattern is estimated separately for each
level. Default is {cmd:quantiles(0.25 0.5 0.75)}.

{phang}
{opt noconstant} omits the intercept. By default a break-varying intercept is
included as the first coefficient ({cmd:_cons}).

{dlgtab:Penalization}

{phang}
{opt lambda2(numlist)} is the grid of fused-lasso tuning parameters. The value
minimizing the information criterion (see {it:Methodology}) is selected and
reported. A finer or wider grid increases computation but may improve break
recovery. Default is {cmd:lambda2(0.005 0.01 0.025 0.05 0.1 0.25 0.5 1)}.

{phang}
{opt lambda1(real)} penalizes the magnitude of the individual effects, stabilizing
their estimation. Default is {cmd:lambda1(0.05)}.

{phang}
{opt kappa(real)} is the exponent {it:{&kappa}} of the adaptive weights
{it:{&omega}}{subscript:t} = ||{it:{&beta}}{subscript:t} - {it:{&beta}}{subscript:t-1}||{c -(}1{c )-}{c -(}-{it:{&kappa}}{c )-},
computed from a preliminary unpenalized fit. Larger {it:{&kappa}} sharpens the
adaptive penalty. Default is {cmd:kappa(1)}.

{phang}
{opt rconstant(real)} is the constant {it:r} scaling the IC complexity penalty
{it:{&rho}} = {it:r}{&middot}ln(min(N,T))/min(N,T). Default is {cmd:rconstant(0.5)}.

{dlgtab:Numerical}

{phang}
{opt maxiter(integer)} caps the number of outer block-coordinate-descent
iterations (alternating between slopes and individual effects). Default 15.

{phang}
{opt tolerance(real)} sets the relative-change convergence threshold on the
individual effects. Default 1e-4.

{dlgtab:Reporting}

{phang}
{opt nograph} suppresses all graphical output.

{phang}
{opt heatmap} requests an additional break-intensity heatmap.

{phang}
{opt level(#)} sets the confidence level of the plotted coefficient band; the band
is drawn only when a single quantile is requested. Default is {cmd:level(95)}.

{marker method}{...}
{title:Methodology}

{pstd}
The estimator minimizes the check-loss objective summed over quantiles, subject
to an L1 penalty on the individual effects and an adaptive fused-lasso penalty on
the first differences {it:{&theta}}{subscript:t,{&tau}} = {it:{&beta}}{subscript:t,{&tau}} - {it:{&beta}}{subscript:t-1,{&tau}}.
Reparameterizing in {it:{&theta}} turns break detection into a sparsity problem:
a break occurs wherever ||{it:{&theta}}{subscript:t,{&tau}}|| {c 0~=} 0, and the
coefficients are recovered as the cumulative sum of {it:{&theta}}.

{pstd}
Because Mata has no native linear-programming quantile solver, the check loss is
optimized by a Hunter-Lange majorize-minimize scheme (iteratively reweighted
least squares), the fused-L1 penalty is handled by local quadratic approximation,
and the slope blocks and individual effects are updated by block coordinate
descent. The individual-effects update is the exact penalized weighted median over
the candidate kink points.

{pstd}
The fused-lasso penalty {it:{&lambda}}{subscript:2} is chosen to minimize

{p 12 12 2}{cmd:IC(}{it:{&lambda}}{cmd:)} = ln({it:{&sigma}}{c {-}}{sup:2}) + {it:{&rho}}{&middot}{&Sigma}{subscript:k}({it:m}{c {-}}{subscript:k} + 1)

{pstd}
where {it:m}{c {-}}{subscript:k} is the number of breaks at quantile {it:k},
{it:{&sigma}}{c {-}}{sup:2} is the mean post-lasso check loss, and
{it:{&rho}} = {it:r}{&middot}ln(min(N,T))/min(N,T).

{pstd}
Standard errors are obtained from a Powell kernel sandwich estimator computed on
each regime sub-sample.

{marker output}{...}
{title:Output}

{pstd}
The displayed table follows the layout of Table 6 of Zhang et al. (2022): for each
quantile level the estimated regimes are listed as rows giving the time range
({it:start}-{it:end}) and one column of coefficient estimates per regressor, with
significance stars. Two graphs are produced by default: per-regressor coefficient
step paths with break markers across quantiles, and a map of break timing by
quantile.

{marker examples}{...}
{title:Examples}

{pstd}Set up the panel and estimate at the default quartiles:{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtquantilebreak y x1 x2 x3}{p_end}

{pstd}A single median fit with a 90% coefficient band:{p_end}
{phang2}{cmd:. xtquantilebreak y x1 x2, quantiles(0.5) level(90)}{p_end}

{pstd}Five quantile levels with a custom penalty grid and stronger adaptive weights:{p_end}
{phang2}{cmd:. xtquantilebreak y x1 x2 x3, quantiles(0.1 0.25 0.5 0.75 0.9) ///}{p_end}
{phang2}{cmd:      lambda2(0.01 0.05 0.1 0.5 1 2) kappa(2)}{p_end}

{pstd}No intercept and suppressed graphs:{p_end}
{phang2}{cmd:. xtquantilebreak y x1 x2, noconstant nograph}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtquantilebreak} stores the following in {cmd:e()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of cross-sections{p_end}
{synopt:{cmd:e(T)}}number of time periods{p_end}
{synopt:{cmd:e(p)}}number of regressors{p_end}
{synopt:{cmd:e(K)}}number of quantile levels{p_end}
{synopt:{cmd:e(nbreaks)}}total number of detected breaks{p_end}
{synopt:{cmd:e(lambda2)}}selected fused-lasso penalty{p_end}
{synopt:{cmd:e(lambda1)}}individual-effects penalty{p_end}
{synopt:{cmd:e(kappa)}}adaptive-weight exponent{p_end}
{synopt:{cmd:e(ic)}}minimized information criterion{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtquantilebreak}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of regressors{p_end}
{synopt:{cmd:e(quantiles)}}requested quantile levels{p_end}
{synopt:{cmd:e(coefnames)}}coefficient names{p_end}
{synopt:{cmd:e(title)}}title for output{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(reginfo)}}regime index map (quantile, regime, start, end){p_end}
{synopt:{cmd:e(coef)}}regime-specific coefficients{p_end}
{synopt:{cmd:e(se)}}regime-specific standard errors{p_end}
{synopt:{cmd:e(betapath)}}full T-by-(K*pp) coefficient paths{p_end}
{synopt:{cmd:e(breaks)}}K-by-T break indicator matrix{p_end}
{synopt:{cmd:e(alpha)}}estimated individual effects{p_end}
{synopt:{cmd:e(ic_path)}}IC value at each grid point{p_end}
{synopt:{cmd:e(lambda_grid)}}fused-lasso penalty grid{p_end}

{marker references}{...}
{title:References}

{phang}
Zhang, Y., Zhu, Y., Feng, S., and He, X. 2022. Shrinkage quantile regression for
panel data with multiple structural breaks. {it:Canadian Journal of Statistics}
50(3): 820-851.

{phang}
Hunter, D. R., and Lange, K. 2000. Quantile regression via an MM algorithm.
{it:Journal of Computational and Graphical Statistics} 9(1): 60-77.

{phang}
Powell, J. L. 1991. Estimation of monotonic regression models under quantile
restrictions. In {it:Nonparametric and Semiparametric Methods in Econometrics and
Statistics}, eds. W. A. Barnett, J. Powell, and G. Tauchen. Cambridge University
Press.
