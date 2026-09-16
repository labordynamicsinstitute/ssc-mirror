{smcl}
{* *! tvtie 1.2.0 13sep2026}{...}
{vieweralsosee "tvtie postestimation" "help tvtie_postestimation"}{...}
{viewerjumpto "Syntax" "tvtie##syntax"}{...}
{viewerjumpto "Description" "tvtie##description"}{...}
{viewerjumpto "Options" "tvtie##options"}{...}
{viewerjumpto "Examples" "tvtie##examples"}{...}
{viewerjumpto "Stored results" "tvtie##results"}{...}
{viewerjumpto "Reference" "tvtie##reference"}{...}
{title:Title}

{p 4 8 2}
{cmd:tvtie} {hline 2} Time-varying true individual-effects stochastic frontier models

{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{cmd:tvtie} {depvar} [{indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Model}
{synopt:{opt uhet(varlist)}}covariates in the inefficiency scaling equation; abbreviation {cmd:u()}{p_end}

{synopt:{opt cost}}cost frontier; default is {cmd:production}{p_end}

{synopt:{opt production}}production frontier{p_end}

{synopt:{opt distribution(string)}}{cmd:hnormal} (default) or {cmd:tnormal}{p_end}

{synopt:{opt id(varname)}}numeric panel identifier; default from {cmd:xtset}{p_end}

{synopt:{opt time(varname)}}numeric time variable; default from {cmd:xtset}{p_end}

{syntab:Individual heterogeneity}
{synopt:{opt trend(#)}}individual time polynomial, degree 0 through 8; default 2{p_end}

{synopt:{opt heterogeneity(varlist)}}user-specified basis for individual effects{p_end}

{synopt:{opt nohetconstant}}omit the automatically added individual intercept{p_end}

{synopt:{opt nohet}}omit all individual heterogeneity{p_end}

{synopt:{opt noconstant}}omit a common frontier intercept when it is estimable{p_end}

{synopt:{opt dropshort}}exclude panels too short for the specified basis{p_end}

{syntab:Endogenous regressors}
{synopt:{opt endogenous(varlist)}}primitive endogenous variables; abbreviation {cmd:en()}{p_end}

{synopt:{opt instruments(varlist)}}excluded instruments; abbreviation {cmd:i()}{p_end}

{synopt:{opt endofunctions(varlist)}}manually generated endogenous functions;
abbreviation {cmd:endof()}{p_end}

{synopt:{opt rfvars(varlist)}}override the included reduced-form regressors{p_end}

{syntab:Inference and maximization}
{synopt:{opt vce(vcetype)}}{cmd:oim} (default), {cmd:robust}, or {cmd:cluster} {it:clustvar}{p_end}

{synopt:{opt starts(#)}}number of optimization starts, 1 through 100; default 8{p_end}

{synopt:{opt seed(#)}}seed for optimization starts; default 190119{p_end}

{synopt:{opt iterate(#)}}BFGS iteration limit per start; default 500{p_end}

{synopt:{opt tolerance(#)}}optimization tolerance; default 1e-7{p_end}

{synopt:{opt from(matname)}}initial row vector in the order of {cmd:e(b)}{p_end}

{synopt:{opt nolog}}suppress optimization progress{p_end}

{synopt:{opt level(#)}}confidence level; default {cmd:c(level)}{p_end}

{synoptline}

{p 4 4 2}
Use {cmd:xtset} or specify {cmd:id()}. A time variable is required for a
positive-degree time polynomial. Variables must be numeric. The frontier
accepts continuous factor notation, including {cmd:c.x##c.x} for {cmd:x}
and its square and {cmd:c.x##c.w} for two variables and their interaction.
Categorical factor notation, time-series operators, and weights are not
supported. Generate lags and custom scaling or heterogeneity basis terms
before estimation.

{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:tvtie} estimates the stochastic frontier model of Kutlu, Tran, and
Tsionas (2019). The model separates individual heterogeneity from one-sided
inefficiency. Individual effects may vary over time, with a distinct
coefficient vector for every panel. A within-panel orthogonal projection
removes these coefficients before maximum-likelihood estimation.

{p 8 8 2}
y_it = H_it alpha_i + X_it beta - s h_it u_i* + v_it,

{p 4 4 2}
where s=1 for production and s=-1 for cost. The nonnegative latent
inefficiency u_i* is shared within a panel. The default is half-normal;
{cmd:distribution(tnormal)} estimates the location of the underlying normal
distribution before truncation at zero. The scale satisfies
log(sigma_u^2 h_it^2) = phi_0 + U_it phi. Thus the coefficients in the
{cmd:usigma} equation describe the log squared scale. The intercept phi_0
normalizes h_it=exp(U_it phi/2) and sigma_u^2=exp(phi_0). Truncated-normal
models estimate {cmd:kappa}=mu/sigma_u; {cmd:estat components} reports mu.

{p 4 4 2}
The endogenous specification jointly estimates reduced-form equations for
the declared primitive endogenous variables and their covariance with the
frontier noise. Endogeneity may occur in frontier or scaling covariates.
After an endogenous fit, the output automatically reports a joint Wald
test that all {cmd:eta} coefficients equal zero. This test does not establish
instrument validity. See {help tvtie_postestimation} for first-stage
diagnostics, heterogeneity diagnostics, and efficiency predictions.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt uhet(varlist)} specifies U_it. A scale intercept is always estimated;
do not include a constant variable in this list. When individual intercepts
are absorbed, scaling must vary within panels and retain variation after
projection. A specification that removes all scaling variation is rejected.

{phang}
{opt cost} changes the sign of inefficiency. {opt production} is the default.
{opt distribution(hnormal)} fixes the latent location at zero;
{opt distribution(tnormal)} estimates it. Both distributions have support
on nonnegative inefficiency.

{phang}
{opt id(varname)} and {opt time(varname)} override the corresponding
{cmd:xtset} variables. Unbalanced panels are allowed. Duplicate panel-time
pairs are rejected. At least two usable panels are required.

{dlgtab:Individual heterogeneity}

{phang}
{opt trend(#)} specifies separate polynomial coefficients for each panel.
The default {cmd:trend(2)} includes an individual intercept, linear trend,
and quadratic trend. {cmd:trend(0)} includes only individual intercepts.
With the automatic intercept, time is centered and scaled for numerical
stability. Recovered coefficients use this transformed time basis; the
center and scale are saved in {cmd:e(time_center)} and {cmd:e(time_scale)}.

{phang}
{opt heterogeneity(varlist)} replaces the time polynomial with the entered
basis and an automatically added individual intercept. Its columns must
be linearly independent within every retained panel. Do not also specify
{cmd:trend()}. Generate nonlinear basis terms explicitly.

{phang}
{opt nohetconstant} removes the automatically added individual intercept.
It does not remove a constant explicitly supplied in {cmd:heterogeneity()}.
For example, {cmd:heterogeneity(one t t2) nohetconstant}, where {cmd:one=1},
retains individual intercepts. Without an intercept, polynomial time is
scaled but not centered, since centering would change the restricted model.
Choose the time origin accordingly. {cmd:trend(0) nohetconstant} is not
allowed; use {cmd:nohet} for an empty basis.

{phang}
{opt nohet} omits all individual effects and ordinarily estimates a common
frontier intercept. It cannot be combined with {cmd:trend()},
{cmd:heterogeneity()}, or {cmd:nohetconstant}.

{phang}
{opt noconstant} omits a common frontier intercept. This is distinct from
individual intercepts: a common intercept is automatically excluded when
it is absorbed by the heterogeneity basis. When the basis does not span a
constant, a common intercept is included unless {cmd:noconstant} is specified.

{phang}
{opt dropshort} excludes panels with no residual dimension after projecting
out the chosen basis. Other rank failures remain errors. The output reports
the number excluded; {cmd:e(sample)} identifies the retained observations.

{dlgtab:Endogenous regressors}

{phang}
{opt endogenous(varlist)} declares primitive endogenous variables.
{opt instruments(varlist)} supplies excluded instruments. The command uses
exactly the supplied excluded instruments and does not generate their
powers or interactions. At least one distinct excluded instrument per
primitive endogenous variable must survive projection. The complete
projected instrument matrix must have full column rank.

{phang}
{opt endofunctions(varlist)} declares included functions of endogenous
variables so they are excluded from the automatic instrument set. For
example, after generating {cmd:xsq=x^2}, specify
{cmd:en(x) endofunctions(xsq) i(z)}. This fits one reduced-form equation for
{cmd:x} and uses {cmd:z} as the excluded instrument. It neither treats
{cmd:xsq} as a second primitive endogenous variable nor adds {cmd:z^2}.
The abbreviation {cmd:endof(xsq)} is equivalent to
{cmd:endofunctions(xsq)}. For manually generated variables, list every
included endogenous function explicitly because a variable name does not
identify the formula used to create it.

{phang}
Continuous frontier expressions that contain a variable in {cmd:en()} are
recognized automatically. Thus {cmd:tvtie y c.x##c.x, en(x) i(z) ...}
requires no {cmd:endof()}. There is one reduced-form equation for {cmd:x};
the square remains in the frontier and is excluded from the automatic
instrument set. An interaction such as {cmd:c.x#c.w} is handled in the
same way when {cmd:x} is endogenous. Separate primitive endogenous variables
require separate entries in {cmd:en()}. This recognition does not add powers
or interactions of the excluded instruments.

{phang}
{opt rfvars(varlist)} replaces the automatic included reduced-form
regressors. By default these are the distinct frontier and scaling
covariates, excluding {cmd:en()} and {cmd:endofunctions()}. Excluded
instruments from {cmd:i()} are then added. A reduced-form intercept is
included when it is not absorbed by individual heterogeneity. The command
reports instruments absorbed by that projection. {cmd:rfvars()} does not
generate transformations or certify exclusion restrictions.

{dlgtab:Inference and maximization}

{phang}
{opt vce(oim)} uses the inverse observed information of the full joint
likelihood. {opt vce(robust)} uses a sandwich covariance with panel scores.
{opt vce(cluster clustvar)} sums panel scores within a larger cluster;
each panel must lie entirely within one cluster. Sandwich covariances use
no finite-sample multiplier and require more clusters than full estimated
parameters. These estimators rely on many independent panels or clusters
and adequate identification. They do not correct a misspecified likelihood
or provide weak-instrument-robust inference.

{phang}
{opt starts(#)} and {opt seed(#)} control multiple starting values. The
user's Stata random-number state is restored after estimation. The highest
likelihood among accepted stationary endpoints is selected. Multiple
starts do not guarantee a global maximum.

{phang}
{opt iterate(#)} limits BFGS iterations for each start. A subsequent Newton
refinement uses at most min(#,100) iterations. {opt tolerance(#)} must be
positive and smaller than .001. An endpoint must have a scaled full-score
norm no greater than max(20*tolerance,2e-6), and the final observed
information must be positive definite and sufficiently well conditioned.
Failure to find an acceptable endpoint is reported as an error.

{phang}
{opt from(matname)} supplies an initial row vector for the current
specification, in the same parameter order as {cmd:e(b)}. It supplies the
first start; any remaining starts are generated separately.
{opt nolog} suppresses progress output. {opt level(#)} controls confidence
intervals and can also be used when replaying results.

{marker examples}{...}
{title:Examples}

{p 4 4 2}Install directly from the author's website. The examples load simulated data
over HTTPS; an Internet connection is needed when loading a dataset.{p_end}

{phang2}{cmd:net install tvtie, from("https://leventkutlu.com/stata/tvtie") replace}{p_end}

{p 4 4 2}{browse "https://leventkutlu.com/stata/tvtie/tvtie.pdf":Documentation PDF}
provides a worked guide, model interpretation, options, and postestimation examples.
{browse "https://leventkutlu.com/stata/tvtie/tvtie_example.do":Example do-file} runs
three introductory examples using the hosted data.{p_end}

{p 4 4 2}{bf:1. Exogenous cost frontier}{p_end}

{p 4 4 2}The cost frontier uses two scaling covariates and the default quadratic
individual trends. The hosted data are simulated.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_example.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost nolog}{p_end}

{phang2}{cmd:estat diagnostics}{p_end}

{p 4 4 2}{bf:2. Endogenous cost frontier}{p_end}

{p 4 4 2}Declare primitive endogenous covariates in en() and the excluded instruments in
i(). The reported endogeneity test is a joint Wald test.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_example.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y x1 x2, u(u1 u2) en(x2 u2) i(z3 z4) cost nolog}{p_end}

{phang2}{cmd:estat endogeneity}{p_end}

{phang2}{cmd:estat firststage, detail}{p_end}

{phang2}{cmd:estat components}{p_end}

{p 4 4 2}{bf:3. Predictions and individual coefficients}{p_end}

{p 4 4 2}After example 2, compare the two efficiency summaries. Posterior quantiles
condition on fitted parameters; they are not confidence limits.{p_end}

{phang2}{cmd:predict double te, efficiency}{p_end}

{phang2}{cmd:predict double mean_te, meante}{p_end}

{phang2}{cmd:predict double te_q025, tequantile(.025)}{p_end}

{phang2}{cmd:predict double te_q975, tequantile(.975)}{p_end}

{phang2}{cmd:predict double individual_effect, fe}{p_end}

{phang2}{cmd:summarize te mean_te te_q025 te_q975}{p_end}

{phang2}{cmd:estat heterogeneity}{p_end}

{phang2}{cmd:matrix panel_coefficients=r(alpha)}{p_end}

{phang2}{cmd:matrix panel_identifiers=r(panel_id)}{p_end}

{p 4 4 2}{bf:4. Individual intercepts and user-specified heterogeneity}{p_end}

{p 4 4 2}A trend(0) basis contains individual intercepts. Heterogeneity variables need
not be powers of time. The custom basis below uses time and u1, with an automatic
individual intercept. Removing that automatic intercept leaves two basis columns.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_example.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost trend(0) nolog}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost heterogeneity(time u1) nolog}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost heterogeneity(time u1) nohetconstant nolog}{p_end}

{p 4 4 2}{bf:5. An explicit individual intercept}{p_end}

{p 4 4 2}An explicitly supplied constant remains in the basis when nohetconstant is
specified. With one, time, and time squared, the heterogeneity rank per panel is three.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_example.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:generate double one=1}{p_end}

{phang2}{cmd:generate double time2=time^2}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost heterogeneity(one time time2) nohetconstant nolog}{p_end}

{p 4 4 2}{bf:6. A nonlinear endogenous production frontier}{p_end}

{p 4 4 2}Continuous factor notation identifies the square as a function of x. There is
one primitive endogenous equation. Only z is added as the excluded instrument; no powers
of z are generated.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_nonlinear.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y c.x##c.x, nohet u(u1) en(x) i(z) nolog}{p_end}

{phang2}{cmd:estat firststage, detail}{p_end}

{p 4 4 2}{bf:7. A manually generated endogenous square}{p_end}

{p 4 4 2}For a named variable xsq, declare its status with endof(xsq), an abbreviation of
endofunctions(xsq). Use example 6 when requesting a bootstrap, so the square can be
regenerated in every draw.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_nonlinear.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:generate double xsq=x^2}{p_end}

{phang2}{cmd:tvtie y x xsq, nohet u(u1) en(x) endof(xsq) i(z) nolog}{p_end}

{p 4 4 2}{bf:8. Panel-robust covariance}{p_end}

{p 4 4 2}The robust covariance uses independent panel scores. It does not make the
endogeneity test robust to weak instruments or repair a misspecified likelihood.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_nonlinear.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y c.x##c.x, nohet u(u1) en(x) i(z) vce(robust) nolog}{p_end}

{p 4 4 2}{bf:9. Heterogeneity and endogeneity bootstrap tests}{p_end}

{p 4 4 2}Fit the nohet null before the omnibus heterogeneity test. Endogeneity requires a
separate null-specific bootstrap. These examples use 99 draws for illustration; consider
999 for reported inference, subject to the Stata edition matrix limit.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_nonlinear.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y c.x##c.x, nohet u(u1) en(x) i(z) nolog}{p_end}

{phang2}{cmd:estat hettest, reps(99) seed(271828)}{p_end}

{phang2}{cmd:matrix heterogeneity_draws=r(draws)}{p_end}

{phang2}{cmd:estat endogeneity, bootstrap reps(99) seed(314159)}{p_end}

{phang2}{cmd:matrix endogeneity_draws=r(draws)}{p_end}

{p 4 4 2}{bf:10. Individual trends beyond individual intercepts}{p_end}

{p 4 4 2}Fit the individual-intercept null with trend(0), then test for time variation.
Bootstrap is the default. The timevarying option does not test whether individual
intercepts exist.{p_end}

{phang2}{cmd:use "https://leventkutlu.com/stata/tvtie/tvtie_example.dta", clear}{p_end}

{phang2}{cmd:xtset id period}{p_end}

{phang2}{cmd:tvtie y_exo x1 x2, u(u1 u2) cost trend(0) nolog}{p_end}

{phang2}{cmd:estat hettest, timevarying trend(2) reps(99) seed(161803)}{p_end}

{marker results}{...}
{title:Stored results}

{p 4 4 2}
{cmd:e(b)} and {cmd:e(V)} contain full joint estimates and their covariance.
Equation names include {cmd:frontier}, {cmd:usigma}, {cmd:lnsig2r},
{cmd:kappa} for truncated-normal models, {cmd:eta} for endogenous models,
and reduced-form parameter equations. Use {cmd:matrix list e(b)} for the
exact order in a fitted specification.

{synoptset 29}{...}
{synopthdr:scalars and matrices}
{synoptline}
{synopt:{cmd:e(N)}, {cmd:e(N_g)}}observations and panels{p_end}

{synopt:{cmd:e(N_transformed)}}sum of panel residual dimensions{p_end}

{synopt:{cmd:e(k_het)}}heterogeneity rank per panel{p_end}

{synopt:{cmd:e(k)}, {cmd:e(k_profile)}}full and profiled parameter counts{p_end}

{synopt:{cmd:e(ll)}}maximized transformed log likelihood{p_end}

{synopt:{cmd:e(sigma_r2)}, {cmd:e(sigma_v2)}}conditional and unconditional noise variances{p_end}

{synopt:{cmd:e(sigma_u2)}, {cmd:e(mu)}}untruncated latent variance and location{p_end}

{synopt:{cmd:e(het_constant)}}automatic individual intercept indicator{p_end}

{synopt:{cmd:e(absorbs_constant)}}basis spans a constant indicator{p_end}

{synopt:{cmd:e(frontier_constant)}}common frontier intercept indicator{p_end}

{synopt:{cmd:e(time_center)}, {cmd:e(time_scale)}}polynomial time transformation{p_end}

{synopt:{cmd:e(dropped_panels)}}panels excluded by {cmd:dropshort}{p_end}

{synopt:{cmd:e(chi2_endogeneity)}}joint eta Wald statistic, if endogenous{p_end}

{synopt:{cmd:e(df_endogeneity)}}number of tested eta coefficients{p_end}

{synopt:{cmd:e(p_endogeneity)}}p-value of the endogeneity test{p_end}

{synopt:{cmd:e(V_oim)}}inverse observed information{p_end}

{synopt:{cmd:e(firststage)}}projected OLS strength diagnostics{p_end}

{synopt:{cmd:e(delta)}, {cmd:e(Omega)}}jointly estimated reduced form and covariance{p_end}

{synopt:{cmd:e(starts)}}outcomes for all attempted optimization starts{p_end}

{synopt:{cmd:e(diagnostics)}}dimensions, stationarity, conditioning, and scales{p_end}

{synoptline}

{p 4 4 2}
The fitted variable lists and options are saved as {cmd:e()} macros.
{cmd:e(endof_declared)} contains manually declared functions;
{cmd:e(endof_automatic)} contains recognized continuous expressions.
{cmd:e(zvars)} gives the included and excluded instrument terms.
{cmd:e(sample)} identifies the complete estimation sample.
{cmd:estat diagnostics} displays the numerical diagnostics.

{marker reference}{...}
{title:Reference}

{p 4 8 2}
Kutlu, L., K. C. Tran, and M. G. Tsionas. 2019. A time-varying true individual
effects model with endogenous regressors. {it:Journal of Econometrics}
211: 539-559. {browse "https://doi.org/10.1016/j.jeconom.2019.01.014":doi:10.1016/j.jeconom.2019.01.014}.

{title:Author}

{p 4 4 2}
Levent Kutlu, School of Economics and Finance,
The University of Texas Rio Grande Valley.{p_end}
