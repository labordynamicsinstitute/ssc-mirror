{smcl}
{* *! version 1.0.0 12jun2026}{...}
{vieweralsosee "mmqrtest scalepos" "help mmqrtest_scalepos"}{...}
{vieweralsosee "mmqrtest scalerel" "help mmqrtest_scalerel"}{...}
{vieweralsosee "mmqrtest spec" "help mmqrtest_spec"}{...}
{vieweralsosee "mmqrtest distfe" "help mmqrtest_distfe"}{...}
{vieweralsosee "mmqrtest canay" "help mmqrtest_canay"}{...}
{vieweralsosee "mmqrtest postestimation" "help mmqrtest_postestimation"}{...}
{vieweralsosee "mmqrtest guide (for researchers)" "help mmqrtest_guide"}{...}
{vieweralsosee "mmqreg" "help mmqreg"}{...}
{vieweralsosee "xtqreg" "help xtqreg"}{...}
{viewerjumpto "Syntax" "mmqrtest##syntax"}{...}
{viewerjumpto "Description" "mmqrtest##description"}{...}
{viewerjumpto "The model" "mmqrtest##model"}{...}
{viewerjumpto "The tests" "mmqrtest##tests"}{...}
{viewerjumpto "Options" "mmqrtest##options"}{...}
{viewerjumpto "Examples" "mmqrtest##examples"}{...}
{viewerjumpto "Stored results" "mmqrtest##results"}{...}
{viewerjumpto "References" "mmqrtest##references"}{...}
{viewerjumpto "Author" "mmqrtest##author"}{...}
{title:Title}

{phang}
{bf:mmqrtest} {hline 2} Specification and diagnostic tests for MM-QR
location-scale panel quantile models (Machado and Santos Silva 2019;
Canay 2011)


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mmqrtest} {it:subcommand} [{it:depvar} {it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 12 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{helpb mmqrtest_scalepos:scalepos}}positivity of the fitted scale
{it:sigma_it} = {it:delta_i} + {it:X'gamma}{p_end}
{synopt:{helpb mmqrtest_scalerel:scalerel}}Wald test of {it:gamma} = 0
(scale relevance; quantile-slope homogeneity){p_end}
{synopt:{helpb mmqrtest_spec:spec}}location-scale adequacy /
overidentification test{p_end}
{synopt:{helpb mmqrtest_distfe:distfe}}distributional fixed effects;
H0: {it:delta_i} homogeneous{p_end}
{synopt:{helpb mmqrtest_canay:canay}}Canay (2011) location-shift validity
(bootstrap Hausman-type contrast){p_end}
{synopt:{bf:all}}run the full battery and print a verdict summary{p_end}
{synopt:{helpb mmqrtest_guide:guide}}open the researcher's guide
(detailed interpretation of every test){p_end}
{synoptline}

{pstd}
All subcommands run either {bf:as postestimation} after {helpb mmqreg},
{helpb xtqreg} or {helpb qregfe} (omit {it:depvar} {it:indepvars}), or
{bf:standalone} by supplying the variable list; see
{helpb mmqrtest_postestimation:mmqrtest postestimation}.

{synoptset 22 tabbed}{...}
{synopthdr:common options}
{synoptline}
{synopt:{opt id(panelvar)}}panel identifier; default is taken from the
estimation results or {helpb xtset}{p_end}
{synopt:{opt q:uantile(numlist)}}quantiles in percent, e.g.
{cmd:quantile(25 50 75)}; default is the estimated quantiles or 25 50 75{p_end}
{synopt:{opt gr:aph}}draw the diagnostic graph(s){p_end}
{synopt:{opt name(string)}}name of the graph; for {bf:all} it is the
prefix of the five diagnostic graphs ({it:name}{cmd:_d1} ...
{it:name}{cmd:_d5}) and of the combined dashboard
({it:name}{cmd:_dash}){p_end}
{synopt:{opt noheader}}suppress the title box{p_end}
{synoptline}

{synoptset 22 tabbed}{...}
{synopthdr:subcommand-specific}
{synoptline}
{synopt:{opt aux(varlist)}}({bf:spec}) user-supplied auxiliary functions w(X){p_end}
{synopt:{opt r:eps(#)}}({bf:canay}, {bf:all}) bootstrap replications; default 200{p_end}
{synopt:{opt seed(#)}}({bf:canay}, {bf:all}) random-number seed{p_end}
{synopt:{opt pvar(varname)}}({bf:canay}) regressor shown in the comparison plot{p_end}
{synopt:{opt gen:erate(stub)}}({bf:scalepos}, {bf:distfe}) save fitted
objects as new variables{p_end}
{synopt:{opt nodots}}({bf:canay}, {bf:all}) suppress bootstrap dots{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:mmqrtest} provides the testing toolbox that Machado and Santos Silva
(2019) call for but do not develop.  Their method-of-moments quantile
regression (MM-QR) is built on a conditional location-scale model, and the
authors note that {it:"although we do not develop such tests here, it is}
{it:possible to test the assumption that the covariates only affect the}
{it:location and scale functions"} (sec. 1) and that such tests {it:"can be}
{it:constructed as tests for overidentifying restrictions, but it may be}
{it:possible to develop simpler regression-based procedures"} (sec. 7).
{cmd:mmqrtest} implements that program: every maintained assumption of the
MM-QR panel model is mapped to a computable diagnostic with a clear verdict,
publication-style tables, and optional graphs.

{pstd}
It is designed as the natural companion to {helpb mmqreg}: fit your model,
then type {cmd:mmqrtest all}.  Each table is printed in journal style with
explanatory notes beneath it; for a full discussion of what each test
means, when to run it, how to read every possible outcome, and ready-made
reporting language for papers, see the researcher's guide:
{helpb mmqrtest_guide:help mmqrtest_guide} (or type {cmd:mmqrtest guide}).


{marker model}{...}
{title:The model being tested}

{pstd}
MM-QR assumes the panel location-scale data generating process
(Machado and Santos Silva 2019, eq. 5)

{p 8 8 2}
{it:Y_it} = {it:alpha_i} + {it:X_it'beta} +
({it:delta_i} + {it:X_it'gamma}) {it:U_it},
{space 6} Pr({it:delta_i} + {it:X_it'gamma} > 0) = 1,

{pstd}
with {it:U_it} i.i.d., independent of {it:X}, E({it:U}) = 0, E(|{it:U}|) = 1.
The implied conditional quantiles are (eq. 6)

{p 8 8 2}
{it:Q_Y(tau|X_it)} = ({it:alpha_i} + {it:delta_i q(tau)}) + {it:X_it'beta}
+ {it:X_it'gamma q(tau)}.

{pstd}
Each maintained restriction is testable, and each {cmd:mmqrtest} subcommand
targets one of them.


{marker tests}{...}
{title:The tests at a glance}

{p2colset 5 22 24 2}{...}
{p2col:{helpb mmqrtest_scalepos:scalepos}}Is the fitted scale positive for
every observation, as eq. (5) requires?  A violation makes the standardized
residuals, and hence all MM-QR quantiles, unreliable.{p_end}
{p2col:{helpb mmqrtest_scalerel:scalerel}}H0: {it:gamma} = 0.  Under H0 the
quantile coefficients {it:beta(tau)} = {it:beta} + {it:q(tau)gamma} are the
same at every {it:tau} {hline 2} quantile regression adds nothing beyond a
location model.  Uses the analytic covariance of the scale coefficients
(Theorem 2).{p_end}
{p2col:{helpb mmqrtest_spec:spec}}H0: regressors act only through location
and scale, i.e. {it:U} independent of {it:X}.  Cluster-robust orthogonality
(overidentification) tests between functions of {it:U} and functions of
{it:X}, the regression-based procedure suggested in fn. 5 and sec. 7 of the
paper.{p_end}
{p2col:{helpb mmqrtest_distfe:distfe}}H0: {it:delta_i} = {it:delta} for all
{it:i}.  Under H0 the individual effects are pure location shifters; under
the alternative they are {it:distributional} fixed effects that move
dispersion and tails.{p_end}
{p2col:{helpb mmqrtest_canay:canay}}H0: Canay's (2011) location-shift
assumption holds.  Bootstrap Hausman-type contrast between the Canay
two-step and MM-QR coefficient paths (cf. Machado and Santos Silva 2019,
fn. 17).{p_end}
{p2col:{bf:all}}Runs the five tests in sequence and prints a one-screen
verdict summary; with {opt graph} also builds a combined dashboard.{p_end}
{p2colreset}{...}


{marker options}{...}
{title:Options}

{phang}
{opt id(panelvar)} supplies the panel identifier.  When omitted,
{cmd:mmqrtest} uses, in this order: the single variable in {cmd:e(fevlist)}
left by {cmd:mmqreg, absorb()}; the {helpb xtset} panel variable.

{phang}
{opt quantile(numlist)} sets the quantiles (in percent, each strictly
between 0 and 100).  When omitted, the quantiles of the estimation in
memory are reused; standalone, the default is {cmd:25 50 75}.

{phang}
{opt graph} requests the diagnostic graph of each subcommand.  Graphs use a
'Parula'-inspired palette and can be combined freely since each accepts
{opt name()}.

{pstd}
See the subcommand help files for the remaining options.


{marker examples}{...}
{title:Examples}

{pstd}Postestimation workflow (recommended){p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}
{phang2}{cmd:. mmqreg ln_wage tenure ttl_exp, absorb(idcode) quantile(25 50 75)}{p_end}
{phang2}{cmd:. mmqrtest all, reps(200) seed(12345) graph}{p_end}

{pstd}Single tests{p_end}
{phang2}{cmd:. mmqrtest scalepos, graph}{p_end}
{phang2}{cmd:. mmqrtest scalerel}{p_end}
{phang2}{cmd:. mmqrtest spec}{p_end}
{phang2}{cmd:. mmqrtest distfe, generate(fe) graph}{p_end}
{phang2}{cmd:. mmqrtest canay, reps(500) pvar(tenure) graph}{p_end}

{pstd}Standalone (no prior estimation){p_end}
{phang2}{cmd:. mmqrtest spec ln_wage tenure ttl_exp, id(idcode) quantile(10 50 90)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
Each subcommand returns its statistics in {cmd:r()}; see the subcommand
help files.  {cmd:mmqrtest all} returns:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(pctneg)}}percent of observations with non-positive scale{p_end}
{synopt:{cmd:r(nneg)}}number of such observations{p_end}
{synopt:{cmd:r(p_scalerel)}}p-value, scale relevance Wald test{p_end}
{synopt:{cmd:r(p_spec)}}p-value, location-scale specification test{p_end}
{synopt:{cmd:r(p_distfe)}}p-value, distributional fixed-effects test{p_end}
{synopt:{cmd:r(p_canay)}}p-value, Canay location-shift test{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(v_scalepos)}...{cmd:r(v_canay)}}verdict strings{p_end}


{marker references}{...}
{title:References}

{phang}
Canay, I. A. 2011.  A simple approach to quantile regression for panel
data.  {it:The Econometrics Journal} 14: 368-386.
{browse "https://doi.org/10.1111/j.1368-423X.2011.00349.x"}

{phang}
Dhaene, G., and K. Jochmans. 2015.  Split-panel jackknife estimation of
fixed-effect models.  {it:Review of Economic Studies} 82: 991-1030.
{browse "https://doi.org/10.1093/restud/rdv007"}

{phang}
Glejser, H. 1969.  A new test for heteroskedasticity.
{it:Journal of the American Statistical Association} 64: 316-323.
{browse "https://doi.org/10.1080/01621459.1969.10500976"}

{phang}
Hansen, L. P. 1982.  Large sample properties of generalized method of
moments estimators.  {it:Econometrica} 50: 1029-1054.
{browse "https://doi.org/10.2307/1912775"}

{phang}
Koenker, R. 2004.  Quantile regression for longitudinal data.
{it:Journal of Multivariate Analysis} 91: 74-89.
{browse "https://doi.org/10.1016/j.jmva.2004.05.006"}

{phang}
Machado, J. A. F., and J. M. C. Santos Silva. 2019.  Quantiles via moments.
{it:Journal of Econometrics} 213: 145-173.
{browse "https://doi.org/10.1016/j.jeconom.2019.04.009"}

{phang}
Newey, W. K. 1985.  Generalized method of moments specification testing.
{it:Journal of Econometrics} 29: 229-256.
{browse "https://doi.org/10.1016/0304-4076(85)90154-X"}


{marker author}{...}
{title:Author}

{pstd}
Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane"}{break}

{pstd}
{cmd:mmqrtest} is a companion to {helpb mmqreg} (Rios-Avila; Roudane) and
implements the testing agenda outlined in Machado and Santos Silva (2019).
