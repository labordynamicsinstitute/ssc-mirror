{smcl}
{* *! version 1.0.1  28may2026}{...}
{viewerjumpto "Syntax"         "civreg##syntax"}{...}
{viewerjumpto "Description"    "civreg##description"}{...}
{viewerjumpto "Method"         "civreg##method"}{...}
{viewerjumpto "Options"        "civreg##options"}{...}
{viewerjumpto "Saved results"  "civreg##results"}{...}
{viewerjumpto "Examples"       "civreg##examples"}{...}
{viewerjumpto "References"     "civreg##references"}{...}
{viewerjumpto "Author"         "civreg##author"}{...}

{title:Title}

{p2colset 5 15 20 2}{...}
{p2col:{bf:civreg} {hline 2}}Coplanar/synthetic instrumental variables (CIV/SIV) regression{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:civreg} {it:depvar} [{it:exogvars}]
{cmd:(}{it:endogvars} {cmd:=} [{it:excluded_exogvars}]{cmd:)}
{ifin}
{cmd:,}
[{it:civ_options}]
[{it:ivreg2_options}]

{pstd}
Most options supported by {helpb ivreg2} may also be specified.

{synoptset 24 tabbed}{...}
{synopthdr:civ_options}
{synoptline}
{syntab:CIV/SIV construction}

{synopt:{opt fe}}specifies one-way (individual) fixed-effects estimator{p_end}
{synopt:{opt twfe}}specifies two-way (individual and time) fixed-effects estimator{p_end}
{synopt:{opt hete(#)}}criterion used to identify the optimal coplanar/synthetic instrument ({it:#} = 0, 1, or 2); default is {cmd:hete(0)}{p_end}
{synopt:{opt d(#)}}initial value of the nuisance parameter {it:d0}; default is {cmd:d(0.01)}{p_end}
{synopt:{opt delt(#)}}grid-search increment for {it:d0}; default is {cmd:delt(0.01)}{p_end}
{synopt:{opt dmax(#)}}upper bound (angle measured in degrees) for the search over {it:d0}; default is {cmd:dmax(70)}{p_end}
{synopt:{opt reps(#)}}bootstrap replications used to select optimal {it:d0}; default is {cmd:reps(50)}{p_end}
{synopt:{opt maxiter(#)}}maximum iterations for Halperin APM; default is {cmd:maxiter(50)}{p_end}
{synopt:{opt tol:erance(#)}}convergence tolerance for maximum absolute difference; default is {cmd:tolerance(1e-8)}{p_end}
{synopt:{opt nolog}}suppresses the Halperin APM iteration log{p_end}
{synopt:{opt rcode}}uses R programming language (via {cmd:rcall}) for random number generation to exactly reproduce R results{p_end}

{synoptline}
{p2colreset}{...}

{pstd}
{helpb civreg} passes most standard IV estimation options directly to
{helpb ivreg2}. See {helpb ivreg2} for estimation, variance-covariance,
and reporting options.

{pstd}
{helpb civreg} requires STATA version 11 or later, {helpb ivreg2}
version 2.1.15 or later, and relevant STATA packages. To install {helpb civreg}, type:

{phang2}. {stata `"ssc install civreg"'}{p_end}

{pstd}
The R programming language and {helpb rcall} package must be installed
when option {cmd:rcode} is specified. To install {helpb rcall}, type:

{phang2}. {stata `"net install github, from("https://haghish.github.io/github/")"'}{p_end}
{phang2}. {stata `"github install haghish/rcall, stable"'}{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:civreg} estimates linear models with endogenous regressors using the
Coplanar/Synthetic Instrumental Variables (CIV) method proposed by
Dzhumashev and Tursunalieva (2025).

{pstd}
Unlike conventional instrumental variables estimators, the CIV method
does not require external instruments. Instead, instruments are constructed
from the observed data using the geometric relationship among the dependent
variable, endogenous regressors, and structural disturbances.

{pstd}
The method is based on the result that the outcome variable, endogenous
regressor, and structural error lie on the same coplanar subspace in the
reduced-form representation of the model. A valid coplanar
instrument projected onto that subspace can be represented as

{p 12 12 2}
{it:s = x + k*d0*r}

{pstd}
where {it:x} is the endogenous regressor, {it:r} is orthogonal to {it:x}
within the regression plane, {it:d0} is a nuisance parameter, and
{it:k} depends on the sign of the covariance between the endogenous
regressor and the structural error.

{pstd}
The CIV estimator searches for the value of {it:d0} that satisfies the
Dual Tendency (DT) condition. Under the DT condition, a valid
coplanar instrument simultaneously satisfies:

{p 12 12 2}
1. orthogonality with the structural error; and

{p 12 12 2}
2. a restriction on the first-stage error process.

{pstd}
The identified coplanar instrument is then supplied to
{cmd:ivreg2} for standard IV/2SLS estimation.

{marker method}{...}
{title:Method}

{pstd}
Suppose the structural model is

{p 12 12 2}
{it:y = beta*x + u}

{pstd}
and the first-stage equation is

{p 12 12 2}
{it:x = gamma*z + e}

{pstd}
where {it:x} is endogenous because {it:cov(x,u) != 0}.

{pstd}
The CIV method constructs a coplanar instrument of the form

{p 12 12 2}
{it:s = x + k*d0*r}

{pstd}
where {it:r} is constructed as the component of the dependent variable
orthogonal to {it:x}. In practice, {it:r} is obtained from the projection
of {it:y} onto the orthogonal complement of {it:x}.

{pstd}
The nuisance parameter {it:d0} is selected using one of two DT criteria:

{phang}
{bf:Homoskedastic DT criterion} ({cmd:hete(0)}):
The algorithm searches for the value of {it:d0} that minimizes the
dependence between the coplanar instrument and the squared
first-stage residuals.

{phang}
{bf:Robust DT criterion} ({cmd:hete(1)} and {cmd:hete(2)}):
The algorithm compares the distribution of OLS and feasible GLS
first-stage residuals to identify the value of {it:d0} that minimizes
the difference in heteroskedasticity implied by misspecified
coplanar instruments.

{phang2}
{cmd:hete(1)} uses the parametric implementation proposed in the paper.

{phang2}
{cmd:hete(2)} uses the nonparametric implementation based on empirical
distribution functions and the Anderson-Darling statistic.

{pstd}
The implementation follows the bootstrap-based estimation strategy
proposed in Dzhumashev and Tursunalieva (2025).

{pstd}
The resulting coplanar instrument is treated as a generated
instrument and passed to {cmd:ivreg2} for final estimation.

{pstd}
When option {cmd:fe} or {cmd:twfe} is specified, the fixed-effects
transformation is applied before the CIV construction stage.

{pstd}
For {cmd:fe}, variables are transformed using the standard within
(time-demeaning) transformation at the individual level.

{pstd}
For {cmd:twfe}, variables are transformed using the Halperin alternating
projection method (APM), which iteratively removes individual and time
effects until convergence.

{pstd}
After the transformed variables are obtained, the coplanar
instrument construction procedure and final IV/2SLS estimation are
applied to the transformed data.

{marker options}{...}
{title:Options}

{dlgtab:SIV construction}

{phang}
{opt fe} requests the one-way fixed-effects estimator for panel data.
Before constructing the coplanar instrument, all variables are
transformed using the within transformation (time-demeaning at the
individual level).

{phang}
{opt twfe} requests the two-way fixed-effects estimator for panel data.
Before constructing the coplanar instrument, all variables are
transformed using the Halperin alternating projection method (APM) to
remove both individual and time fixed effects iteratively.

{phang}
{opt hete(#)} specifies the criterion used to identify the optimal
coplanar instrument.

{p2colset 12 22 25 2}{...}

{p2col:{cmd:hete(0)}}baseline DT criterion for approximately
homoskedastic errors.{p_end}

{p2col:{cmd:hete(1)}}robust DT criterion based on comparison between
OLS and feasible GLS residual distributions using parametric
approximations.{p_end}

{p2col:{cmd:hete(2)}}nonparametric robust DT criterion using empirical
distribution functions and the Anderson-Darling statistic.{p_end}

{p2colreset}{...}

{phang}
{opt d(#)} specifies the initial value of the nuisance parameter
{it:d0}.

{phang}
{opt delt(#)} specifies the increment used in the grid search over
{it:d0}.

{phang}
{opt dmax(#)} specifies the upper bound of the search region for
{it:d0}.

{phang}
{opt reps(#)} specifies the number of bootstrap replications used to
obtain the optimal {it:d0}.

{phang}
{opt maxiter(#)} specifies the maximum number of iterations used in the
Halperin APM algorithm when option {cmd:twfe} is specified.

{phang}
{opt tol:erance(#)} specifies the convergence tolerance for the maximum
absolute difference between successive APM iterations when option
{cmd:twfe} is specified.

{phang}
{opt nolog} suppresses the iteration log displayed by the Halperin APM
algorithm when option {cmd:twfe} is specified.

{phang}
{opt rcode} requests random number generation through R programming
language using {cmd:rcall}.

{title:Important notes}

{pstd}
{cmd:civreg} does not currently support factor-variable notation or
time-series operators directly inside the command syntax.

{pstd}
Users should generate transformed variables manually before estimation.

{phang2}{cmd:. generate Lx = L.x}{p_end}
{phang2}{cmd:. tabulate group, generate(g_)}{p_end}

{pstd}
Options {cmd:fe} and {cmd:twfe} require panel data declared by
{helpb xtset}. Both panel and time identifiers must be specified before
estimation.

{phang2}{cmd:. xtset} {it:panelvar timevar}{p_end}

{title:Install and update}

{pstd}
The latest version of {cmd:civreg} can be found at the following link: {browse "https://github.com/ManhHB94/":https://github.com/ManhHB94/}{p_end}

{pstd}To update the {cmd:civreg} package to the latest version, run either of the following commands{p_end}
{phang2}. {stata `"ado update civreg, update"'}{p_end}
{phang2}. {stata `"net install civreg, from("https://raw.githubusercontent.com/ManhHB94/civreg/main/") replace"'}{p_end}

{marker results}{...}
{title:Saved results}

{pstd}
{cmd:civreg} stores all standard estimation results returned by
{cmd:ivreg2} in {cmd:e()}.

{pstd}
In addition, the following are stored:

{synoptset 20 tabbed}{...}
{synopt:{cmd:e(fe_opt)}}fixed-effects specification: 0 = none, 1 = one-way FE, 2 = two-way FE{p_end}
{synopt:{cmd:e(rc)}}return code{p_end}
{synopt:{cmd:e(hete)}}heteroskedasticity criterion selected by {cmd:hete(#)}{p_end}
{synopt:{cmd:e(reps)}}number of bootstrap replications used{p_end}
{synopt:{cmd:e(rcode)}}whether results are reproduced exactly in R{p_end}
{synopt:{cmd:e(chk_sign)}}store information about the signs of cov(x,u){p_end}
{synopt:{cmd:e(cor_x_iv)}}correlation matrix corr(x,civ){p_end}
{synopt:{cmd:e(d0)}}matrix of parameter d0 (mean across bootstrap replications){p_end}

{title:Citation of civreg}

{phang}{helpb civreg} is not an official Stata command. It is a free contribution
to the research community, like a paper. Please cite it as such: {p_end}

{phang2}Manh Hoang-Ba, 2026. CIVREG: Stata module to perform coplanar/synthetic instrumental variables regression.
{browse "https://ideas.repec.org/c/boc/bocode/s459728.html":https://ideas.repec.org/c/boc/bocode/s459728.html}

{marker examples}{...}
{title:Examples}

{phang2}{it:Load mroz dataset:}{p_end}
{phang2}{stata ". webuse mroz, clear"}{p_end}

{phang2}{it:Model with one endogenous variable:}{p_end}
{phang2}{stata ". civreg hours (lwage = ) educ age kidslt6 kidsge6 nwifeinc, hete(0) reps(5)"}{p_end}

{phang2}{it:Model with two endogenous variables:}{p_end}
{phang2}{stata ". civreg hours (lwage educ = ) age kidslt6 kidsge6 nwifeinc, hete(1) reps(5)"}{p_end}

{phang2}{it:Reproducing the SIV column results of Table 2 in Dzhumashev and Tursunalieva (2025):}{p_end}
{phang2}{stata ". civreg hours (lwage = ) educ age kidslt6 kidsge6 nwifeinc , hete(0) reps(49) small rcode"}{p_end}

{phang2}{it:Load Arellano and Bond (1991) dataset:}{p_end}
{phang2}{stata ". webuse abdata, clear"}{p_end}

{phang2}{it:Fixed-effects CIV estimation:}{p_end}
{phang2}{stata ". civreg n (k = ) w ys, fe"}{p_end}

{phang2}{it:Two-way fixed-effects CIV estimation:}{p_end}
{phang2}{stata ". civreg n (k w = ) ys, twfe"}{p_end}

{marker references}{...}
{title:References}

{phang}
Baum, C.F., Schaffer, M.E., Stillman, S. 2010.
ivreg2: Stata module for extended instrumental variables/2SLS, GMM and AC/HAC, LIML and k-class regression.
{browse "http://ideas.repec.org/c/boc/bocode/s425401.html":http://ideas.repec.org/c/boc/bocode/s425401.html}

{phang}
Dzhumashev, R., Tursunalieva, A. 2025.  A synthetic instrumental variable method: Using the dual tendency condition for coplanar instruments. {browse "https://doi.org/10.48550/arXiv.2512.17301":https://doi.org/10.48550/arXiv.2512.17301}.

{phang}
Haghish, E.F. 2021.  Integrating R machine learning algorithms in Stata using rcall. UK Stata Conference 2021, StataCorp. 
{browse "https://www.stata.com/meeting/uk21/slides/UK21_Haghish.pdf":https://www.stata.com/meeting/uk21/slides/UK21_Haghish.pdf}

{marker author}{...}
{title:Author}

    Package implementation by Manh Hoang-Ba (hbmanh9492@gmail.com).

