{smcl}
{* *! version 1.0.0  11May2026}{...}
{viewerjumpto "Syntax" "gtcsem##syntax"}{...}
{viewerjumpto "Description" "gtcsem##description"}{...}
{viewerjumpto "Options" "gtcsem##options"}{...}
{viewerjumpto "Remarks" "gtcsem##remarks"}{...}
{viewerjumpto "Examples" "gtcsem##examples"}{...}
{viewerjumpto "Stored results" "gtcsem##results"}{...}
{viewerjumpto "References" "gtcsem##references"}{...}
{viewerjumpto "Also see" "gtcsem##alsosee"}{...}
{title:Title}

{phang}
{bf:gtcsem} {hline 2} Conditional standard errors of measurement in
Generalizability Theory


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:gtcsem} {varlist} {ifin}
[{cmd:,} {it:options}]

{pstd}
where {it:varlist} contains two or more numeric variables holding the
item-level scores for a single-facet, fully-crossed persons-by-items
(p x i) design.{p_end}

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Estimator}
{synopt:{opth m:ethod(string)}}{cmd:full}, {cmd:large_a},
{cmd:uncorrelated}, or {cmd:all}; default is {cmd:full}{p_end}
{synopt:{opth se:method(string)}}{cmd:analytical}, {cmd:bootstrap},
or {cmd:both}; default is {cmd:analytical}{p_end}
{synopt:{opth ni:temsd(#)}}number of items for D-study extrapolation;
default is the number of observed items{p_end}
{synopt:{opth cut:point(#)}}cutpoint {it:lambda} for Phi(lambda);
not computed by default{p_end}

{syntab:Smoothing}
{synopt:{opt sm:ooth}}fit a quadratic smoother of each error variance
on the observed score{p_end}
{synopt:{opt excl:udeextremes}}exclude floor/ceiling cases from the
quadratic fit (requires {opt smooth}){p_end}

{syntab:Bootstrap}
{synopt:{opth bootb(#)}}number of bootstrap replications;
default is {cmd:bootb(1000)}, minimum 100{p_end}
{synopt:{opth bootseed(#)}}seed for the bootstrap;
default is {cmd:bootseed(0)} (no seed set){p_end}
{synopt:{opt nodo:ts}}suppress per-person bootstrap progress dots{p_end}

{syntab:Output variables}
{synopt:{opth g:enerate(name)}}prefix for the generated variables;
default is {cmd:generate(csem)}{p_end}
{synopt:{opt r:eplace}}overwrite generated variables if they already
exist{p_end}

{syntab:Truncation}
{synopt:{opt truncneg}}set negative per-person error variances to zero
before taking the square root{p_end}
{synopt:{opt truncvc}}set negative ANOVA variance components to zero{p_end}
{synoptline}

{p 4 6 2}
{it:varlist} must contain at least two numeric variables; the design
is required to be balanced and complete (no missing values).{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gtcsem} estimates conditional standard errors of measurement
(CSEMs) under Generalizability Theory for a univariate, single-facet,
persons-by-items (p x i) crossed design.  Whereas the overall
(population) SEM summarizes measurement precision averaged across
the population, the CSEM characterizes the precision of the
measurement for an individual at a given score level (Brennan,
1998).  This is the relevant index when measurement decisions are
made about persons rather than groups, including the assessment of
the local accuracy of cut-score classifications.

{pstd}
Unlike most other psychometric models, Generalizability Theory
distinguishes two types of conditional measurement error.  The
{it:absolute} CSEM is appropriate when decisions concern the
absolute magnitude of a person's score (for example, mastery
classification against a fixed cutpoint), whereas the {it:relative}
CSEM is appropriate when decisions concern comparisons among
persons (for example, ranking or selection) (Brennan, 1998).

{pstd}
For each person {it:p}, {cmd:gtcsem} returns the absolute conditional
error variance (Brennan, 1998, eq. 20) together with up to three
estimators of the relative conditional error variance corresponding
to alternative simplifying assumptions about the population:

{phang2}o {cmd:full} {hline 2} Brennan (1998, eqs. 35-36); no
simplifying assumption about the number of persons.{p_end}

{phang2}o {cmd:large_a} {hline 2} Brennan (1998, eq. 40); takes the
limit as the number of persons {it:A} grows large.{p_end}

{phang2}o {cmd:uncorrelated} {hline 2} Brennan (1998, eq. 41); also
assumes that the within-person item-by-residual covariance is
zero.{p_end}

{pstd}
Standard errors of these per-person estimators are obtained
analytically (closed-form formulas conditional on items, under
Gaussianity of the residuals) or via an item-resampling bootstrap.
The command also reports the standard generalizability coefficient
(E rho^2; Brennan, 2001, eq. 2.40), the dependability coefficient
(Phi; eq. 2.41), and, when a cutpoint is supplied, the dependability
coefficient for mastery decisions Phi(lambda) (Brennan & Kane, 1977;
Brennan, 2001, eq. 2.55).


{marker options}{...}
{title:Options}

{dlgtab:Estimator}

{phang}
{opth method(string)} selects the estimator of the per-person
relative error variance.  {cmd:full} (the default) implements
Brennan (1998, eqs. 35-36) without any simplifying assumption.
{cmd:large_a} implements eq. 40, which drops the finite-{it:A}
correction by taking {it:A} to infinity.  {cmd:uncorrelated}
implements eq. 41, which additionally assumes that, conditional on
the focal person, the covariance between item difficulty and the
person-by-item residual is zero.  Specifying {cmd:all} computes the
three estimators jointly so that they can be compared.

{phang}
{opth semethod(string)} selects how the sampling variance of each
per-person estimator is computed.  {cmd:analytical} (the default)
returns exact closed-form variances derived under the assumption
that residuals are Gaussian and conditional on the observed item
mean structure; under that model the sampling variance does not
depend on the focal person, so it is reported as a constant across
persons.  {cmd:bootstrap} replaces the analytical formula with a
nonparametric item-resampling bootstrap that resamples item indices
with replacement and recomputes the focal estimator at each
replication.  {cmd:both} returns both, which is useful for
diagnostic comparison.

{phang}
{opth nitemsd(#)} performs a D-study extrapolation: the per-person
error variances and the population variance components are projected
to a hypothetical decision study with {it:#} items per person, while
keeping the variance-component estimates from the observed G-study
unchanged.  When {opth nitemsd(#)} is omitted, the D-study item
count equals the number of observed items.

{phang}
{opth cutpoint(#)} requests the dependability coefficient for
mastery classifications, Phi(lambda), at cutpoint {it:lambda} = {it:#}
(Brennan & Kane, 1977; Brennan, 2001, eq. 2.55).  Phi(lambda)
quantifies the proportion of variance among the observed deviations
from the cutpoint that is attributable to true (rather than error)
deviation, and is the appropriate dependability index when scores
are used to make criterion-referenced decisions.

{dlgtab:Smoothing}

{phang}
{opt smooth} fits a quadratic regression of each per-person error
variance on the observed score (Brennan, 2001, p. 162).  Because
the fit is by ordinary least squares, the mean of the smoothed
values equals the mean of the unsmoothed values.  Smoothed CSEMs
are recovered as the square root of the smoothed error variance.

{phang}
{opt excludeextremes} excludes from the quadratic fit those persons
whose responses are all at the empirical minimum (floor) or all at
the empirical maximum (ceiling) across {it:varlist}.  Such cases are
structurally degenerate (zero within-person item variance) and can
unduly influence the smoother.  Smoothed values for the excluded
cases are returned as missing.  Requires {opt smooth}.

{dlgtab:Bootstrap}

{phang}
{opth bootb(#)} sets the number of bootstrap replications used per
person when {opt semethod(bootstrap)} or {opt semethod(both)} is in
effect.  Default is 1000; the minimum permitted is 100.

{phang}
{opth bootseed(#)} sets the random-number seed before the bootstrap
loop, ensuring reproducibility.  The default value of 0 leaves the
current seed untouched.

{phang}
{opt nodots} suppresses the progress dots printed during the
bootstrap.  By default a dot is printed every {it:k} persons, where
{it:k} is chosen so that the bootstrap finishes in roughly 200 dots.

{dlgtab:Output variables}

{phang}
{opth generate(name)} sets the prefix used for all generated
variables.  Default is {cmd:csem}.  See {it:{help gtcsem##remarks:Remarks}}
for the full list of generated variables.

{phang}
{opt replace} drops any pre-existing variable with a generated name
before regenerating it.  Without {opt replace}, the command exits
with an error if any target variable already exists.

{dlgtab:Truncation}

{phang}
{opt truncneg} sets negative per-person error variances to zero
before taking the square root, so that the corresponding CSEM is 0
rather than missing.  Without {opt truncneg}, persons with negative
estimated error variance are assigned a missing CSEM.

{phang}
{opt truncvc} sets to zero any ANOVA variance component (sigma^2(p),
sigma^2(i), sigma^2(pi)) that is estimated as negative.  This affects
all downstream quantities that depend on the truncated component.


{marker remarks}{...}
{title:Remarks}

{pstd}
{ul:Generated variables.}  All generated variables share the prefix
specified by {opt generate(name)} (default {cmd:csem}).  In what
follows the prefix is denoted by {it:p}.  Suffixes are kept short to
fit within Stata's 32-character variable-name limit when
{opt method(all)} is requested.

{phang2}o {it:p}{cmd:_score} {hline 2} observed person mean (sum
score divided by the number of items).{p_end}

{phang2}o {it:p}{cmd:_abs_ev}, {it:p}{cmd:_abs_csem} {hline 2}
absolute conditional error variance and SEM.{p_end}

{phang2}o {it:p}{cmd:_cov_xim} {hline 2} per-person covariance
between item scores and item difficulties (the {it:c}_p building
block of Brennan, 1998).{p_end}

{phang2}o {it:p}{cmd:_vabs_an}, {it:p}{cmd:_vabs_bs} {hline 2}
analytical and bootstrap variance of the per-person absolute error
variance estimator (the bootstrap column is present whenever
{opt semethod(bootstrap)} or {opt semethod(both)} is in effect).
{p_end}

{phang2}o {it:p}{cmd:_rel_ev}, {it:p}{cmd:_rel_csem},
{it:p}{cmd:_vrev_an}, {it:p}{cmd:_vrev_bs} {hline 2} relative
conditional error variance, CSEM, and (analytical/bootstrap) SE
under the selected method.  When {opt method(all)} is specified,
the suffixes {cmd:_full}, {cmd:_la}, and {cmd:_unc} provide each
of the three estimators separately, and the unsuffixed variables
({it:p}{cmd:_rel_ev} etc.) duplicate the {cmd:full} estimator for
convenience.{p_end}

{phang2}o When {opt smooth} is in effect, each
{it:..._ev}/{it:..._csem} pair has a parallel {it:..._ev_sm}/
{it:..._csem_sm} pair containing the quadratic-smoothed values.{p_end}

{pstd}
{ul:Returned matrices.}  In addition to the generated variables, the
command stores variance components ({cmd:r(vc)}), the ANOVA table
({cmd:r(anova)}), the population-level error variances and SEMs
({cmd:r(overall)}), and the reliability-like coefficients
({cmd:r(coefficients)}).  When {opt smooth} is in effect, a matrix
{cmd:r(smooth_fits)} contains the coefficients ({it:b}0, {it:b}1,
{it:b}2), {it:R}^2, RMSE, and sample size of every quadratic fit.
When the bootstrap is run, {cmd:r(boot)} returns the per-person
mean bootstrap variances for the four estimators.

{pstd}
{ul:Reproducibility across calls.}  {cmd:gtcsem} also stores the
prefix and the estimation options as dataset characteristics
({cmd:char _dta[gtcsem_prefix]}, {cmd:char _dta[gtcsem_method]},
{cmd:char _dta[gtcsem_smooth]}, {cmd:char _dta[gtcsem_excludeextremes]}).
{help gtcsem_plot} reads these characteristics so that plots remain
available even after intervening r-class commands have wiped
{cmd:r()}.

{pstd}
{ul:D-study extrapolation.}  When {opth nitemsd(#)} differs from
the number of observed items, all per-person and population-level
error variances are scaled to a decision study with {it:#} items
while keeping the G-study variance components unchanged.  This is
the standard D-study transformation: sigma^2(I) = sigma^2(i)/n_i'
and sigma^2(pI) = sigma^2(pi)/n_i' (Brennan, 2001, eqs. 2.26-2.27).

{pstd}
{ul:Limitations.}  The command currently supports only the
univariate, single-facet, fully-crossed design (one set of items
administered to all persons).  Missing item scores are not allowed;
data must be balanced and complete.  More general designs (nested,
multifacet) are not implemented.


{marker examples}{...}
{title:Examples}

{pstd}Default estimator ({cmd:method(full)}) with analytical SE:{p_end}
{phang2}{cmd:. gtcsem item1-item10}{p_end}

{pstd}All three relative-error estimators with quadratic smoothing
of the per-person error variances:{p_end}
{phang2}{cmd:. gtcsem item1-item10, method(all) smooth}{p_end}

{pstd}Bootstrap SE with a reproducible seed:{p_end}
{phang2}{cmd:. gtcsem item1-item10, semethod(bootstrap) bootb(2000) bootseed(123)}{p_end}

{pstd}Comparison of analytical and bootstrap SE in a single call:{p_end}
{phang2}{cmd:. gtcsem item1-item10, semethod(both) bootseed(123)}{p_end}

{pstd}D-study extrapolation: project to a 20-item form:{p_end}
{phang2}{cmd:. gtcsem item1-item10, nitemsd(20)}{p_end}

{pstd}Dependability for a cutpoint of 7:{p_end}
{phang2}{cmd:. gtcsem item1-item10, cutpoint(7)}{p_end}

{pstd}Smoothing while excluding floor/ceiling cases from the fit:{p_end}
{phang2}{cmd:. gtcsem item1-item10, smooth excludeextremes}{p_end}

{pstd}Use a custom prefix for the generated variables:{p_end}
{phang2}{cmd:. gtcsem item1-item10, generate(myrun)}{p_end}

{pstd}Re-run the command, overwriting any pre-existing generated
variables:{p_end}
{phang2}{cmd:. gtcsem item1-item10, method(all) smooth replace}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gtcsem} is {cmd:r}-class and stores the following in {cmd:r()}.

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(A)}}number of persons{p_end}
{synopt:{cmd:r(I_observed)}}number of observed items{p_end}
{synopt:{cmd:r(nitems_D)}}number of items in the D-study{p_end}
{synopt:{cmd:r(sigma2_p)}}variance component for persons{p_end}
{synopt:{cmd:r(sigma2_i)}}variance component for items{p_end}
{synopt:{cmd:r(sigma2_pi)}}variance component for persons-by-items
(residual){p_end}
{synopt:{cmd:r(absolute_error_var)}}sigma^2(Delta){p_end}
{synopt:{cmd:r(absolute_sem)}}sigma(Delta){p_end}
{synopt:{cmd:r(relative_error_var)}}sigma^2(delta){p_end}
{synopt:{cmd:r(relative_sem)}}sigma(delta){p_end}
{synopt:{cmd:r(erho2)}}generalizability coefficient {it:E}rho^2{p_end}
{synopt:{cmd:r(phi)}}dependability coefficient Phi{p_end}
{synopt:{cmd:r(phi_lambda)}}dependability for cutpoint
(only with {opt cutpoint()}){p_end}
{synopt:{cmd:r(cutpoint)}}cutpoint value
(only with {opt cutpoint()}){p_end}
{synopt:{cmd:r(bootb)}}number of bootstrap replications
(only with bootstrap){p_end}
{synopt:{cmd:r(bootseed)}}bootstrap seed
(only with bootstrap){p_end}
{synopt:{cmd:r(n_floor)}}number of floor cases
(only with {opt excludeextremes}){p_end}
{synopt:{cmd:r(n_ceiling)}}number of ceiling cases
(only with {opt excludeextremes}){p_end}
{synopt:{cmd:r(n_fit)}}sample size of the smoothing fit
(only with {opt excludeextremes}){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(method)}}selected estimator{p_end}
{synopt:{cmd:r(semethod)}}selected SE method{p_end}
{synopt:{cmd:r(prefix)}}prefix used for the generated variables{p_end}
{synopt:{cmd:r(smooth)}}{cmd:smooth} if smoothing was applied,
empty otherwise{p_end}
{synopt:{cmd:r(excludeextremes)}}{cmd:excludeextremes} if applied,
empty otherwise{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(vc)}}1 x 3 vector of variance components{p_end}
{synopt:{cmd:r(anova)}}3 x 4 ANOVA table (df, SS, MS, sigma^2){p_end}
{synopt:{cmd:r(overall)}}4 x 1 column of population-level error
variances and SEMs{p_end}
{synopt:{cmd:r(coefficients)}}coefficients column ({it:E}rho^2,
Phi, and Phi(lambda) when applicable){p_end}
{synopt:{cmd:r(smooth_fits)}}per-quantity quadratic-fit diagnostics
(only with {opt smooth}){p_end}
{synopt:{cmd:r(boot)}}{it:A} x 4 matrix of per-person bootstrap
variances of the absolute and three relative estimators
(only with bootstrap){p_end}


{marker references}{...}
{title:References}

{phang}
Brennan, R. L. (1998). Raw-score conditional standard errors of
measurement in Generalizability Theory.
{it:Applied Psychological Measurement}, {it:22}(4), 307-331.
https://doi.org/10.1177/014662169802200402

{phang}
Brennan, R. L. (2001). {it:Generalizability Theory}.
Springer-Verlag.

{phang}
Brennan, R. L., & Kane, M. T. (1977). An index of dependability for
mastery tests. {it:Journal of Educational Measurement}, {it:14}(3),
277-289.

{phang}
Cronbach, L. J., Gleser, G. C., Nanda, H., & Rajaratnam, N. (1972).
{it:The dependability of behavioral measurements: Theory of generalizability for scores and profiles}.
Wiley.


{marker author}{...}
{title:Author}

{pstd}Rene Gempp{break}
Facultad de Administracion y Economia, Universidad Diego Portales, Santiago, Chile{break}
Email: {browse "mailto:rene.gempp@udp.cl":rene.gempp@udp.cl}
{p_end}


{marker citation}{...}
{title:Citation}

{pstd}
Please cite this software as:
{p_end}

{pmore}
Gempp, R. (2026). gtcsem: Stata module to compute conditional standard errors of measurement in Generalizability Theory (Version 1.0.0). 
 Statistical Software Components S459702, Boston College Department of Economics.
{p_end}


{marker support}{...}
{title:Support and updates}

{pstd}
Bug reports, feature requests, and the development version are
available at {browse "https://github.com/rgempp/gtcsem"}.
{p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 13 2}
Help: {help gtcsem_plot}
