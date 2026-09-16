{smcl}
{* *! tvtie postestimation 1.2.0 13sep2026}{...}
{vieweralsosee "tvtie" "help tvtie"}{...}
{title:Postestimation for tvtie}

{p 4 4 2}
{cmd:predict} and the model-specific {cmd:estat} subcommands use the most
recently fitted or restored {cmd:tvtie} model. The complete original
estimation sample and its fitted variables must remain unchanged. Row
reordering is allowed. An {cmd:if} or {cmd:in} qualifier
on {cmd:predict} restricts only where predictions are written; it does not
remove other observations from the conditioning panel. Predictions outside
{cmd:e(sample)} are not supplied by this release.

{title:Syntax}

{p 8 12 2}
{cmd:predict} [{it:type}] {it:newvar} {ifin}
[{cmd:,} {it:statistic}]

{synoptset 23 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{synopt:{opt xb}}X_it beta, excluding individual effects; default{p_end}

{synopt:{opt inefficiency}}E[u_it | transformed panel data]{p_end}

{synopt:{opt efficiency}}exp(-E[u_it | transformed panel data]), as in the paper{p_end}

{synopt:{opt meante}}E[exp(-u_it) | transformed panel data]{p_end}

{synopt:{opt fe}}H_it alpha_i using the paper's plug-in recovery{p_end}

{synopt:{opt cf}}projected reduced-form correction, epsilon_tilde eta; zero in exogenous models{p_end}

{synopt:{opt fitted}}xb + fe + cf - s*inefficiency{p_end}

{synopt:{opt residuals}}depvar - fitted{p_end}

{synopt:{opt uscale}}h_it=exp(U_it phi/2), excluding sigma_u{p_end}

{synopt:{opt u0}}posterior mean of the original latent u_i*{p_end}

{synopt:{opt u0sd}}posterior standard deviation of u_i*{p_end}

{synopt:{opt uquantile(p)}}conditional p-quantile of u_it, 0<p<1{p_end}

{synopt:{opt tequantile(p)}}conditional p-quantile of exp(-u_it), 0<p<1{p_end}

{synoptline}

{p 4 4 2}
Specify only one statistic. Use {cmd:double} for full precision. The two
efficiency summaries are different; by Jensen's inequality {cmd:meante}
is at least {cmd:efficiency}, up to rounding. Technical/cost efficiency is
reported on a 0-1 scale, not as a percentage. {cmd:u0} and {cmd:u0sd} are
constant within a panel; {cmd:inefficiency} need not be.

{p 4 4 2}
The {cmd:cf} prediction uses the transformed reduced-form residual. Individual
components of an untransformed reduced form annihilated by H are not
identified by this likelihood. The {cmd:fitted} and {cmd:residuals} predictions
therefore provide a plug-in decomposition on the fitted sample; they are not
out-of-sample forecasts or separately recovered structural shocks.

{p 4 4 2}
The quantiles treat the estimated structural parameters as fixed. For
example, the 2.5th and 97.5th efficiency quantiles describe the fitted latent
conditional distribution. They are not 95% frequentist confidence bounds
accounting for parameter estimation or misspecification.

{title:estat subcommands}

{phang}
{cmd:estat endogeneity} tests joint eta=0 using the covariance chosen at
estimation. It reports an asymptotic chi-squared Wald statistic. It does not
test instrument validity and is not robust to weak identification. This
joint test also appears automatically after an endogenous fit.
Individual coefficients may also be tested with
{cmd:test [eta]varname=0}.

{phang}
{cmd:estat firststage} reports projected OLS first-stage joint F statistics
for the excluded instruments, their p-values, partial R-squared values, and
degrees of freedom. These diagnostics use q=sum_i(T_i-k_H) and denominator
degrees of freedom q-l. They are classical, not heteroskedasticity-robust or
weak-instrument-robust diagnostics. {cmd:estat firststage, detail} also shows
the jointly fitted reduced-form coefficients and residual covariance. The
joint coefficients need not equal the diagnostic OLS coefficients.

{phang}
{cmd:estat diagnostics} reports the scaled full score, the condition number
of the diagonally equilibrated observed information, projection survival of
the fitted inefficiency scale, and all attempted start outcomes. The stored
return code and iteration count in the starts matrix refer to the Newton
refinement; its return code is not the independent stationarity criterion.
The accepted endpoint can be the preserved BFGS endpoint.

{phang}
{cmd:estat components} gives sigma_r, sigma_v, sigma_u, and mu. sigma_u and
mu belong to the underlying Gaussian before truncation. The corresponding
{cmd:e()} results with a suffix {cmd:2} are variances, not standard deviations.

{phang}
{cmd:estat heterogeneity} returns the panel-specific coefficient matrix in
{cmd:r(alpha)} and matching numeric identifiers in {cmd:r(panel_id)}. It is
not a significance test. With {cmd:trend()}, coefficients refer to powers of
(time-e(time_center))/e(time_scale). With {cmd:heterogeneity()}, they refer
to the automatic intercept, if included, followed by the entered variables.
An explicitly supplied constant remains part of that entered basis even
with {cmd:nohetconstant}. Their fitted term is
available observation by observation through {cmd:predict ..., fe}.

{phang}
{cmd:estat hettest} [{cmd:,} {opt trend(#)} {opt heterogeneity(varlist)}
{opt time(varname)} {opt timevarying} {opt asymptotic} {opt bootstrap}
{opt reps(#)} {opt seed(#)} {opt starts(#)}] uses a residual-regression
F statistic with a parametric bootstrap reference distribution by default.
First fit the null model using {cmd:nohet} with a common
frontier intercept. The default alternative has individual intercepts
and quadratic individual trends. A custom {cmd:heterogeneity()} basis
replaces the polynomial; an intercept is always included in this
diagnostic's alternative basis. Each panel must have more observations
than the alternative basis rank.

{p 8 8 2}
Following Section 4.2.3 of Kutlu, Tran, and Tsionas (2019), the response is
y_it-X_it beta+s E[u_it | transformed panel data] from the fitted null.
The auxiliary regression compares a common intercept with individual
coefficients on the alternative basis. Its F statistic uses numerator
degrees of freedom G*k_H-1 and denominator degrees of freedom N-G*k_H.
The response includes any estimated endogenous correction in the noise.

{p 8 8 2}
{cmd:estat hettest, timevarying} instead requires a null fitted with
{cmd:trend(0)}. It compares individual intercepts with the chosen
time-varying alternative, using G*(k_H-1) numerator degrees of freedom.
This is an extension of the residual-regression diagnostic and also uses
bootstrap inference by default. Specify {cmd:asymptotic} for the ordinary
F reference in either version. With generated
residuals, the F reference is approximate and can be substantially
conservative. Use the bootstrap option to account for this residual
construction under the maintained parametric model. Neither version supplies
cluster-robust or weak-identification-robust inference, and neither is a
likelihood-ratio test across projection spaces. With {cmd:asymptotic}, the stored results are
{cmd:r(F)}, {cmd:r(df)}, {cmd:r(df_r)}, {cmd:r(p)}, {cmd:r(N)},
{cmd:r(N_g)}, {cmd:r(rss_null)}, and {cmd:r(rss_alternative)}.

{title:Parametric bootstrap tests}

{phang}
{cmd:estat hettest} estimates the reference distribution of the
heterogeneity statistic under the fitted null by default. The explicit
{cmd:bootstrap} option is equivalent. Use {cmd:nohet} for the
omnibus null, or {cmd:trend(0)} followed by
{cmd:estat hettest, timevarying} to test individual trends beyond
individual intercepts. The alternative basis options are the same as for
the residual-regression diagnostic.

{p 4 4 2}
Use {cmd:estat hettest, asymptotic} or
{cmd:estat hettest, timevarying asymptotic} to request the ordinary F reference.
The {cmd:bootstrap} and {cmd:asymptotic} options cannot be combined.

{phang}
{cmd:estat endogeneity, bootstrap} estimates the reference distribution of
the joint eta Wald statistic under eta=0. It first fits the restricted
exogenous frontier and its reduced forms, then re-estimates the unrestricted
endogenous model for each draw. The automatic test shown after estimation
remains the asymptotic Wald test.

{p 4 4 2}
Run a separate bootstrap procedure for each distinct null hypothesis.
The omnibus heterogeneity null excludes individual effects; the individual-trend
null permits individual intercepts; the endogeneity null imposes eta=0.
Their fitted nulls and simulated reference distributions differ. One joint
endogeneity bootstrap tests all declared eta coefficients together, so a
separate bootstrap for each endogenous variable is unnecessary. Each procedure
uses the number of draws specified in {cmd:reps()}; one draw is insufficient.

{p 4 4 2}
Both bootstrap commands accept {cmd:reps(#)}, {cmd:seed(#)}, and
{cmd:starts(#)}. Defaults are 199 replications, seed 873921, and two
optimization starts per draw. At least 19 replications are required.
For a reported analysis, use more replications, for example 999 when
supported by your Stata edition. The maximum is the edition's matrix limit,
{cmd:c(max_matsize)}, because every draw is returned in {cmd:r(draws)}.
More draws reduce simulation error in the p-value; they
do not remove model misspecification or guarantee finite-sample validity.

{p 4 4 2}
Each draw regenerates the primitive endogenous variables jointly, latent
inefficiency, and frontier noise. Exogenous covariates and instruments are
held fixed. Continuous endogenous expressions and scaling variables are
reconstructed from the new primitive variables. With individual effects
under the null, draws condition on the observed components absorbed by
that null basis. Every successful draw receives a new model fit and new
inefficiency predictions. The original dataset, estimates, and random-number
state are restored when the command finishes, including after an error.

{p 4 4 2}
This implementation requires {cmd:vce(oim)} and the maintained independent
panel, Gaussian noise, and specified inefficiency model. It does not provide
cluster-robust or weak-instrument-robust inference. Panel identifiers, times,
and heterogeneity basis variables must be fixed covariates. For nonlinear
endogenous frontier terms, use continuous factor notation. The bootstrap
rejects manually declared {cmd:endof()} variables because their generating
formulas are unavailable.

{p 4 4 2}
The bootstrap p-value is (1 + exceedances)/(B + 1), where B is the requested
number of replications. Failed draws remain in the denominator. If any draw
fails, {cmd:r(p)} is missing and {cmd:r(p_lower)} and {cmd:r(p_upper)} bound
the p-value by assigning failed draws to the nonexceedance and exceedance
categories. Inspect these bounds and the failed fits before drawing an
inference. The command does not silently discard failures or keep sampling
until it obtains B successful fits.

{p 4 4 2}
Returned results are {cmd:r(statistic)}, {cmd:r(p_asymptotic)},
{cmd:r(p)}, {cmd:r(p_lower)}, {cmd:r(p_upper)}, {cmd:r(mcse)},
{cmd:r(reps)}, {cmd:r(failed)}, {cmd:r(exceedances)}, and {cmd:r(seed)}.
{cmd:r(mcse)} approximates Monte Carlo uncertainty in a complete bootstrap
p-value. {cmd:r(draws)} contains the replication number, statistic, and
return code for every attempted draw. It does not replace the simulation
study needed to assess a test's empirical size and power.

{title:Examples}

{p 4 4 2}The following examples load public simulated data directly. See
{help tvtie##examples:tvtie examples} and the
{browse "https://leventkutlu.com/stata/tvtie/tvtie.pdf":documentation PDF} for the
complete guide.{p_end}

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

{title:Saved estimation results}

{p 4 4 2}
{cmd:estimates store} and {cmd:estimates restore} preserve the fitted model
specification. After loading results from disk with {cmd:estimates use},
restore the exact original dataset and reconstruct {cmd:e(sample)} with
{cmd:estimates esample:} and the appropriate sample indicator or qualifiers.
Do not mark excluded observations as part of the original sample. Changing
the conditioning data changes the posterior; it does not constitute a
counterfactual effect calculation holding information fixed.

{title:Not supported}

{p 4 4 2}
Automatic {cmd:margins}, postestimation score generation for {cmd:suest},
likelihood-ratio tests across different heterogeneity spaces, automatic efficiency
confidence bands, and out-of-sample prediction are not implemented.{p_end}
