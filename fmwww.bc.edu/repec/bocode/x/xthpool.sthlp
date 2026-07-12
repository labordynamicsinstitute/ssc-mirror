{smcl}
{* *! version 1.0.0  11jul2026}{...}
{vieweralsosee "xthpool methods" "help xthpool_methods"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtset" "help xtset"}{...}
{vieweralsosee "xtcointtest" "help xtcointtest"}{...}
{viewerjumpto "Syntax" "xthpool##syntax"}{...}
{viewerjumpto "Description" "xthpool##description"}{...}
{viewerjumpto "Options" "xthpool##options"}{...}
{viewerjumpto "Remarks" "xthpool##remarks"}{...}
{viewerjumpto "Interpreting output" "xthpool##interpret"}{...}
{viewerjumpto "Examples" "xthpool##examples"}{...}
{viewerjumpto "Stored results" "xthpool##results"}{...}
{viewerjumpto "References" "xthpool##references"}{...}
{viewerjumpto "Author" "xthpool##author"}{...}
{title:Title}

{phang}
{bf:xthpool} {hline 2} Hausman poolability test for cointegrated panels
(Westerlund and Hess 2011)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xthpool}
{it:depvar}
{it:indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt fact:ors(#)}}fix the number of common factors {it:r}; default is
selection by the Bai-Ng {it:IC1} criterion{p_end}
{synopt:{opt rmax(#)}}maximum number of factors searched by {it:IC1}; default
{cmd:rmax(5)}{p_end}
{synopt:{opt defact:or(varlist)}}observable common factors {it:g_t} driving the
regressors; the test uses the defactored regressors{p_end}
{synopt:{opt b:andwidth(#)}}Newey-West Bartlett bandwidth {it:M}; default is the
Newey-West rule {cmd:floor(4*(T/100)^(2/9))}{p_end}

{syntab:Test}
{synopt:{opt ac:onst(#)}}Gumbel scale constant {it:a_N}; default {cmd:aconst(2)}{p_end}
{synopt:{opt iter:ate}}run the iterative (sequential-drop) poolability scheme{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Graph}
{synopt:{opt graph}}plot the individual Hausman statistics against the rejection
threshold{p_end}
{synopt:{opt name(str)}}name for the graph{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}The panel must be {helpb xtset}, {bf:balanced} and have no gaps.
{it:depvar} and {it:indepvars} are the levels of the cointegrating regression;
they are assumed to be I(1) and cointegrated.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xthpool} implements the poolability test of Westerlund and Hess (2011,
{it:Journal of Applied Econometrics}). Consider the cointegrated panel

{p 8 8 2}{it:y_it} = {it:a_i} + {it:b_i} {it:x_it} + {it:e_it},{p_end}

{pstd}
where {it:b_i} is a unit-specific slope vector and the error {it:e_it} may
contain {it:r} common factors, so the cross-sectional units are dependent. The
test evaluates the null hypothesis of {bf:poolability}

{p 8 8 2}H0: {it:b_i} = {it:b} for all {it:i}{p_end}

{pstd}
against the heterogeneous alternative that at least one unit differs. It
compares an {bf:individual} and a {bf:pooled} bias-adjusted least-squares
estimator of the cointegrating slope, unit by unit, in a Hausman (1978) way, and
takes the {bf:maximum} of the individual Hausman statistics. After a Gumbel
normalization the statistic has a well-defined limiting distribution even when
{it:N} is of the same order as {it:T} — a regime where the seemingly-unrelated
Wald test of Mark, Ogaki and Sul (2005) is badly distorted.

{pstd}
Cross-sectional dependence in the error is handled by estimating the common
factors with principal components (Bai and Ng 2002, 2004). When the regressors
are themselves driven by {it:observable} common factors {it:g_t}, option
{cmd:defactor()} projects them out first (Corollary 1 of the paper).

{pstd}
See {helpb xthpool_methods:help xthpool methods} for the estimator, the
step-by-step mapping to the paper's equations, and the derivation.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt factors(#)} fixes the number of common factors {it:r} in the error at
{it:#}. With {cmd:factors(0)} no factors are removed (independent units). By
default {it:r} is estimated by the Bai-Ng {it:IC1} information criterion over
{cmd:0..rmax}.

{phang}
{opt rmax(#)} sets the largest number of factors considered by {it:IC1}. Default
is {cmd:rmax(5)}, as in the paper.

{phang}
{opt defactor(varlist)} lists the {bf:observable} common factors {it:g_t} that
also drive the regressors. Each regressor is projected on {it:g_t} unit by unit
and the projection residual (the "defactored" regressor) is used in the test.
{it:g_t} must be {bf:stationary}; test it for unit roots first (see Remarks).

{phang}
{opt bandwidth(#)} sets the Bartlett-kernel bandwidth {it:M} used for the
Newey-West long-run (co)variances. The default is the Newey-West rule
{cmd:floor(4*(T/100)^(2/9))}. Larger {it:M} guards against stronger serial
correlation at the cost of more noise.

{dlgtab:Test}

{phang}
{opt aconst(#)} is the Gumbel scale constant {it:a_N}. The paper shows
{cmd:aconst(2)} works well even for small {it:N} and it is the default.

{phang}
{opt iterate} applies the test sequentially: the maximizing unit is dropped
after a rejection and the test is recomputed, until two units remain. The
reported adjusted p-value keeps the overall significance level across steps (the
step-{it:j} critical value is the upper {it:alpha^j} Gumbel percentile).

{phang}
{opt level(#)} sets the confidence level; default {cmd:level(95)}.

{dlgtab:Graph}

{phang}
{opt graph} draws the sorted individual Hausman statistics with the 5% rejection
threshold overlaid. {opt name(str)} names the graph.

{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Sample size.} Theorem 1 requires {it:sqrt(N)/T} -> 0, i.e. {it:T} large
relative to {it:N} (in practice {it:T^2 > N}). The test is designed for exactly
the {it:N} ~ {it:T} regime that defeats SUR-Wald tests, but very small {it:T}
(below ~50) can leave the maximum statistic mildly liberal; prefer {it:T} of 100
or more when available.

{pstd}
{bf:Cointegration is assumed.} {cmd:xthpool} conditions on the regression being
cointegrated. Test that first (e.g. {helpb xtcointtest} or Westerlund's tests);
poolability is not meaningful for a spurious regression.

{pstd}
{bf:Defactoring.} Use {cmd:defactor()} when the regressors share observable
common shocks (e.g. a monetary model where relative money and output both
contain the U.S. aggregates). The factors in {it:g_t} must be {bf:distinct} from
those in the error and must be {bf:stationary}; otherwise the limiting
distribution is contaminated. If the common factors are unknown, estimate them
from the first-differenced regressors (Bai and Ng 2004) and pass the accumulated
projection residuals.

{pstd}
{bf:This is a test against a single violation.} Because it uses the maximum, the
test has power against even one non-poolable unit. The {cmd:iterate} scheme
identifies {it:which} units are not poolable, but its power falls at each step as
the corrected critical value grows.

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{cmd:H_max} is the largest individual Hausman statistic across units.
{cmd:Z_max} is its Gumbel normalization {cmd:(H_max - b_N)/a_N} with
{cmd:b_N = }{it:invchi2(m, 1-1/N)} and {it:m} the number of regressors. The
{cmd:Gumbel p-value} is {cmd:1 - exp(-exp(-Z_max))}: a small value rejects
poolability. The line "{cmd:Most extreme unit}" names the unit attaining the
maximum — the prime candidate for being non-poolable. Under {cmd:iterate}, "{cmd:p (raw)}"
is the one-step Gumbel p-value at that step and "{cmd:p (adj)}" is corrected to
maintain the overall level across the sequential drops.

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Test whether the investment slopes are poolable{p_end}
{phang2}{cmd:. xthpool invest mvalue kstock}{p_end}

{pstd}Fix one common factor and draw the diagnostic plot{p_end}
{phang2}{cmd:. xthpool invest mvalue kstock, factors(1) graph}{p_end}

{pstd}Sequentially identify the non-poolable units{p_end}
{phang2}{cmd:. xthpool invest mvalue kstock, iterate}{p_end}

{pstd}Regressors driven by an observable common factor {cmd:g}{p_end}
{phang2}{cmd:. xthpool y x, defactor(g)}{p_end}

{pstd}
A complete, self-contained demonstration with a simulated data-generating
process (size and power) ships as {bf:xthpool_example.do}.

{marker results}{...}
{title:Stored results}

{pstd}{cmd:xthpool} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(Hmax)}}maximum Hausman statistic{p_end}
{synopt:{cmd:r(Zmax)}}Gumbel-normalized statistic{p_end}
{synopt:{cmd:r(p)}}Gumbel p-value{p_end}
{synopt:{cmd:r(N)}}number of units{p_end}
{synopt:{cmd:r(T)}}time-series length{p_end}
{synopt:{cmd:r(m)}}number of regressors{p_end}
{synopt:{cmd:r(r)}}number of common factors used{p_end}
{synopt:{cmd:r(bw)}}Newey-West bandwidth{p_end}
{synopt:{cmd:r(aN)}}Gumbel scale constant{p_end}
{synopt:{cmd:r(imax)}}id of the maximizing (most extreme) unit{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xthpool}{p_end}
{synopt:{cmd:r(depvar)}}dependent variable{p_end}
{synopt:{cmd:r(indepvars)}}regressors{p_end}
{synopt:{cmd:r(ivar)}}panel variable{p_end}
{synopt:{cmd:r(tvar)}}time variable{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(Hi)}}individual Hausman statistics{p_end}
{synopt:{cmd:r(unit)}}corresponding unit ids{p_end}
{synopt:{cmd:r(bplus)}}unit ids and bias-adjusted individual slopes{p_end}
{synopt:{cmd:r(itertable)}}iteration table (with {cmd:iterate}){p_end}

{marker references}{...}
{title:References}

{phang}
Bai, J., and S. Ng. 2002. Determining the number of factors in approximate
factor models. {it:Econometrica} 70: 191-221.

{phang}
Bai, J., and S. Ng. 2004. A PANIC attack on unit roots and cointegration.
{it:Econometrica} 72: 1127-1177.

{phang}
Hausman, J. 1978. Specification tests in econometrics.
{it:Econometrica} 46: 1251-1271.

{phang}
Newey, W. K., and K. D. West. 1994. Automatic lag selection in covariance matrix
estimation. {it:Review of Economic Studies} 61: 631-653.

{phang}
Westerlund, J., and W. Hess. 2011. A new poolability test for cointegrated
panels. {it:Journal of Applied Econometrics} 26: 56-88.
{browse "https://doi.org/10.1002/jae.1143":doi:10.1002/jae.1143}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
