{smcl}
{* *! version 0.5.0  02jun2026}{...}
{vieweralsosee "xtdpdgmm" "help xtdpdgmm"}{...}
{vieweralsosee "xtabond2" "help xtabond2"}{...}
{vieweralsosee "xtabond" "help xtabond"}{...}
{vieweralsosee "xtcd2" "help xtcd2"}{...}
{viewerjumpto "Syntax" "xtdyntest##syntax"}{...}
{viewerjumpto "Description" "xtdyntest##description"}{...}
{viewerjumpto "Options" "xtdyntest##options"}{...}
{viewerjumpto "Stored results" "xtdyntest##results"}{...}
{viewerjumpto "Examples" "xtdyntest##examples"}{...}
{viewerjumpto "References" "xtdyntest##references"}{...}
{viewerjumpto "Author" "xtdyntest##author"}{...}

{title:Title}

{phang}
{bf:xtdyntest} {hline 2} Specification tests after dynamic panel-data GMM estimation

{pstd}{bf:Contents}{p_end}
{phang2}{help xtdyntest##syntax:Syntax}  {c 124}  {help xtdyntest##description:Description}  {c 124}  {help xtdyntest##options:Options}  {c 124}  {help xtdyntest##results:Stored results}  {c 124}  {help xtdyntest##examples:Examples}  {c 124}  {help xtdyntest##references:References}  {c 124}  {help xtdyntest##author:Author}{p_end}

{pstd}Jump to a subcommand:
{help xtdyntest##description:csd} {c 124}
{help xtdyntest##syr_desc:syr} {c 124}
{help xtdyntest##break_desc:break} {c 124}
{help xtdyntest##lee_desc:lee}{p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtdyntest} {it:subcommand} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt csd}}cross-sectional dependence battery on residuals{p_end}
{synopt:{opt syr}}Sarafidis-Yamagata-Robertson (2009) error-CSD Sargan-difference test{p_end}
{synopt:{opt break}}De Wachter-Tzavalis (2012) structural-break test (known {it:or} unknown breakpoint){p_end}
{synopt:{opt lee}}Lee (2014) generalized-spectral linearity / functional-form test{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{it:csd} {hline 2} cross-sectional dependence tests:

{p 8 15 2}
{cmd:xtdyntest csd} [{cmd:,} {it:csd_options}]

{synoptset 24 tabbed}{...}
{synopthdr:csd_options}
{synoptline}
{synopt:{opt resid:uals(varname)}}use {it:varname} as the residual series instead of
reconstructing from {cmd:e(b)}{p_end}
{synopt:{opt graph}}draw a heatmap of the pairwise residual correlation matrix
(requires {cmd:heatplot} from SSC){p_end}
{synopt:{opt graphname(string)}}name for the saved graph (default {cmd:xtd_csd_heat}){p_end}
{synopt:{opt notab:le}}suppress the results table{p_end}
{synopt:{opt save:corr(name)}}save the N{c 215}N pairwise correlation matrix in {it:name}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest csd} is run {it:after} a dynamic panel estimator (see {help xtdyntest##description:Description}).

{pstd}
{it:syr} {hline 2} Sarafidis-Yamagata-Robertson (2009) test:

{p 8 15 2}
{cmd:xtdyntest syr} [{cmd:,} {opt notab:le}]

{pstd}
Run {cmd:xtdyntest syr} {it:after} {help xtdpdgmm:xtdpdgmm} or {help xtabond2:xtabond2}.
It re-fits the model with the lagged-dependent-variable GMM instruments removed
and reports the Sargan/Hansen difference statistic (D_DIF2 after difference GMM,
D_SYS2 after system GMM). See {help xtdyntest##syr_desc:Description: syr}.

{pstd}
{it:break} {hline 2} De Wachter-Tzavalis (2012) structural-break test:

{p 8 15 2}
{cmd:xtdyntest break} {it:depvar} {ifin} [{cmd:,} {opt at(#)}
{opt ar(#)} {opt reduced} {opt full} {opt reps(#)} {opt seed(#)} {opt trim(#)} {opt notab:le}]

{synoptset 26 tabbed}{...}
{synopthdr:break_options}
{synoptline}
{synopt:{opt at(#)}}candidate breakpoint, given as an observed value of the panel
{it:time} variable. {it:If omitted}, the unknown-breakpoint {bf:sup}-test is run
instead (sweep over all admissible candidate dates){p_end}
{synopt:{opt ar(#)}}autoregressive order {it:p} of the dynamic model (default {cmd:ar(1)}){p_end}
{synopt:{opt full}}test a break in {it:both} the slope coefficients and the fixed
effects (default){p_end}
{synopt:{opt reduced}}test a break in the fixed effects only{p_end}
{synopt:{opt reps(#)}}number of simulation draws for the sup-test null
distribution (default {cmd:reps(499)}, minimum 99; ignored when {opt at()} is given){p_end}
{synopt:{opt seed(#)}}random-number seed for reproducible sup-test p-values
(ignored when {opt at()} is given){p_end}
{synopt:{opt trim(#)}}symmetric trimming fraction of the candidate window for the
sup-test, in [0,0.5) (default {cmd:trim(0.15)}; ignored when {opt at()} is given){p_end}
{synopt:{opt notab:le}}suppress the results table{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest break} is {it:self-contained}: it fits its own Arellano-Bond
difference-GMM models (it does not require a prior estimation command). The data
must be {cmd:xtset}. It estimates a pure dynamic AR({it:p}) panel by difference GMM
with standard non-collapsed (GMM-style) level instruments, and reports the
likelihood-ratio-type statistic {bf:N(Q2 {c 45} Qtau)}, where {bf:Q2} is the
no-break two-step GMM objective (the standard Arellano-Bond Hansen {it:J}) and
{bf:Qtau} is the objective of the model with a break at {opt at()}. {bf:Qtau} drops
the moment conditions of the contaminated differenced equation at the break and
reuses the no-break moment-covariance submatrix as its weight (a shared-weight
Hansen difference / C statistic). Under H0 of no break the statistic is
{it:chi-squared} with degrees of freedom equal to the number of omitted moment
conditions plus the number of extra break parameters. See
{help xtdyntest##break_desc:Description: break}.

{pstd}
{it:lee} {hline 2} Lee (2014) generalized-spectral linearity test:

{p 8 15 2}
{cmd:xtdyntest lee} {it:depvar} [{it:indepvars}] {ifin} [{cmd:,} {opt resid:uals(varname)}
{opt ar(#)} {opt ef:fects(string)} {opt p:bar(#)} {opt lags(#)} {opt ng:rid(#)} {opt notab:le}]

{synoptset 26 tabbed}{...}
{synopthdr:lee_options}
{synoptline}
{synopt:{opt resid:uals(varname)}}use {it:varname} as the residual series (skips
estimation entirely){p_end}
{synopt:{opt ar(#)}}autoregressive order {it:p} of the self-contained linear fit
(default {cmd:ar(1)}; used only when residuals are obtained internally){p_end}
{synopt:{opt ef:fects(string)}}within transform of the residuals: {cmd:twoway}
(default), {cmd:individual}, {cmd:time}, or {cmd:none}{p_end}
{synopt:{opt p:bar(#)}}preliminary bandwidth used to compute the data-driven
plug-in (default {cmd:pbar(4)}, minimum 2){p_end}
{synopt:{opt lags(#)}}fix the bandwidth (lag truncation {it:p}) at {it:#};
{cmd:lags(0)} (default) requests the data-driven plug-in {bf:p0 = c0 T^(1/3)}{p_end}
{synopt:{opt ng:rid(#)}}number of points in the integration grid on [-3,3]
(default {cmd:ngrid(31)}, odd, minimum 11){p_end}
{synopt:{opt notab:le}}suppress the results table{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest lee} obtains residuals in one of three ways: from {opt residuals()}
if supplied; otherwise from the {it:host} estimator via {cmd:predict} when an
estimation is in memory and no {it:indepvars} are given (post-estimation default);
otherwise from a {it:self-contained} linear dynamic fixed-effects fit of {it:depvar}
on its first {it:p} lags and any {it:indepvars}. See
{help xtdyntest##lee_desc:Description: lee}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtdyntest} provides post-estimation specification tests intended to be run
after dynamic panel-data GMM estimators, including
{help xtdpdgmm:xtdpdgmm} (Kripfganz),
{help xtabond2:xtabond2} (Roodman), and the official
{help xtabond:xtabond}/{help xtdpd:xtdpd}/{help xtdpdsys:xtdpdsys}.

{pstd}
The {cmd:csd} subcommand reports a battery of cross-sectional dependence (CSD)
tests computed on the estimation residuals:

{p 8 12 2}{bf:o} Pesaran (2004) {it:CD} test {c 45} valid for large {it:N};{p_end}
{p 8 12 2}{bf:o} Friedman (1937) rank test {it:FR};{p_end}
{p 8 12 2}{bf:o} Frees (1995) test {it:FRE} (normal approximation);{p_end}
{p 8 12 2}{bf:o} Breusch & Pagan (1980) {it:LM} test {c 45} valid for fixed {it:N}, large {it:T}.{p_end}

{pstd}
The null hypothesis in every case is that the errors are cross-sectionally
independent. By default the residuals are reconstructed from the stored
coefficient vector as {cmd:depvar} {c 45} {cmd:xb}, where {cmd:xb} is built with
{cmd:matrix score} over {cmd:e(sample)}. Supply your own residual series with
{opt residuals()} (for example, first-difference residuals or a transformed
equation) when the level-equation reconstruction is not what you want.

{pstd}
The statistics are computed natively (in Mata) so the command does not depend on
any other CSD package being installed. Where a bias-corrected CD* is wanted, use
{help xtcd2:xtcd2} (Ditzen) directly; {cmd:xtdyntest} will call it opportunistically
if it is installed.

{marker syr_desc}{...}
{pstd}
{bf:syr} {hline 2} The {cmd:syr} subcommand implements the Sarafidis, Yamagata and
Robertson (2009) test for error cross-sectional dependence in short dynamic panels
estimated by GMM. The idea is that, under a multi-factor error structure, the
instruments based on lagged levels (or lagged differences) of the {it:dependent
variable} become invalid, whereas instruments based on the {it:regressors} remain
valid. The test is therefore a Sargan/Hansen difference (overidentification)
statistic comparing the full instrument set with the set that excludes the
lagged-dependent-variable instruments:

{p 8 12 2}{bf:o} {bf:D_DIF2} after difference GMM (Arellano-Bond);{p_end}
{p 8 12 2}{bf:o} {bf:D_SYS2} after system GMM (Blundell-Bond).{p_end}

{pstd}
Run it after {help xtdpdgmm:xtdpdgmm} or {help xtabond2:xtabond2}.
{cmd:xtdyntest syr} reads {cmd:e(cmdline)}, identifies the GMM/IV instrument blocks
that reference the dependent variable (the y-instruments), re-estimates the model
with those blocks dropped, and differences the two overidentification statistics:
D = S(full) {c 45} S(restricted), with degrees of freedom equal to the number of
y-instruments removed. Two versions are reported: one based on the two-step
(robust/Hansen) J and one based on the unadjusted Sargan J. The null is
{it:homogeneous} error cross-sectional dependence (equivalently, validity of the
lagged-dependent-variable instruments).

{pstd}
Each overidentification statistic is re-optimized on its own instrument set,
following SYR (their Eqs. 27-28). Consequently the value can differ from a host
command's built-in difference-in-Hansen (which reuses the full-model weighting
matrix as a shared-weight C statistic) and, like any such difference, may be
negative in finite samples; a negative difference is truncated at zero for the
reported p-value. The {cmd:syr} subcommand requires {cmd:xtdpdgmm} or {cmd:xtabond2}
because it relies on their GMM machinery and stored {cmd:e(cmdline)}; standard
{cmd:gmm()}/{cmd:iv()} instrument syntax is assumed.

{marker break_desc}{...}
{pstd}
{bf:break} {hline 2} The {cmd:break} subcommand implements the De Wachter and
Tzavalis (2012) procedure for detecting a structural break in a linear dynamic
panel data model. Under the null hypothesis the model is a stable AR({it:p}) panel
with individual fixed effects; under the alternative, at a candidate time {opt at()}
the slope coefficients and/or the fixed effects shift. Because the individual
intercepts and their changes cannot be estimated consistently with {it:T} fixed,
detection is carried out in the Arellano-Bond GMM framework on the first-differenced
equations.

{pstd}
For the no-break model all standard moment conditions {bf:E[y_is {c 215} Deps_it]=0}
(levels as instruments for the differenced equations) are used, giving the two-step
GMM objective {bf:Q2}, which is exactly the Arellano-Bond Hansen {it:J}. For a break
at {it:tau} the fixed-effect break introduces a one-time spike in the differenced
equation at {it:t=tau}; the moment conditions belonging to that equation are
therefore {it:dropped}, and (with {opt full}) slope-break interaction regressors are
added. The break objective {bf:Qtau} reuses the {it:no-break} moment-covariance
submatrix as its weighting matrix, so the difference

{p 8 12 2}{bf:N(Q2 {c 45} Qtau)} {c 126} chi-squared,
df = #(omitted moments) + (dim theta_tau {c 45} dim theta_2),{p_end}

{pstd}
is a shared-weight Hansen difference (C) statistic and is non-negative
asymptotically (De Wachter-Tzavalis Theorem 1). With {opt reduced} only a
fixed-effect break is tested (no extra parameters, so df = #omitted moments); with
{opt full} a joint slope-and-fixed-effect break is tested (df adds {it:p} slope-break
parameters).

{pstd}
The engine is self-contained and uses non-collapsed (GMM-style) level instruments
with minimum lag 2, matching a textbook Arellano-Bond fit; as a check, {cmd:r(Q2)}
and {cmd:r(df2)} reproduce the two-step Hansen {it:J} and its df from
{cmd:xtdpdgmm}{c 39}s difference-GMM estimator on the same series.

{pstd}
{bf:Unknown breakpoint (sup-test).} When {opt at()} is {it:omitted}, {cmd:break}
performs the De Wachter-Tzavalis sup-type test for a break at an {it:unknown} date.
It computes the pointwise statistic {bf:V(tau) = N(Q2 {c 45} Qtau)} at every
admissible candidate {it:tau} in the (symmetrically trimmed) interior of the time
window, and reports the supremum

{p 8 12 2}{bf:Vmax = max_tau S(tau){c 215}V(tau)}{p_end}

{pstd}
where {bf:S(tau)} is the distributional rescaling of eq.(11) that maps each
candidate{c 39}s marginal {it:chi-squared}(df_tau) onto a common reference, so the
maximum is not mechanically dominated by the candidates with the most degrees of
freedom. The estimated break date is the {it:argmax}. Because the candidate
statistics are correlated and the components have different df, the sup statistic is
{it:not} {it:chi-squared}; its null distribution is the limit of DWT Theorem 2,

{p 8 12 2}{bf:Vmax} {c 126} {bf:max_k S(k){c 215}v{c 39}G_k v},  v {c 126} N(0,I),{p_end}

{pstd}
where the {bf:G_k} are the idempotent matrices of eq.(25). {cmd:break} forms the
{bf:G_k} analytically from the no-break moment-covariance matrix and obtains the
p-value by Monte-Carlo simulation of this limit ({opt reps()} draws, made
reproducible with {opt seed()}). Equivalently the comparison is carried out in
CDF (probability) space, which is invariant to the arbitrary reference
{it:chi-squared} used by {bf:S(.)}. The full candidate profile {bf:V(tau)} is
printed and returned in {cmd:r(profile)}.

{marker lee_desc}{...}
{pstd}
{bf:lee} {hline 2} The {cmd:lee} subcommand implements the Lee (2014)
individual-specific {it:generalized-spectral derivative} test of a linear dynamic
panel data model against unspecified nonlinear alternatives. It tests whether the
errors of the fitted linear model form a martingale difference sequence (m.d.s.) -
equivalently, whether the conditional mean is correctly specified with no neglected
nonlinearity. The test is consistent against a wide class of nonlinear departures
(e.g. threshold, smooth-transition, and Markov-switching dynamics).

{pstd}
Let {bf:e_it} be the (two-way demeaned) residuals. The test is built from the
empirical-characteristic-function building blocks
{bf:sigma_ij(0,v) = (1/(Ti-j)) {c 138}_t e_it psi_{i,t-j}(v)}, where
{bf:psi_it(v) = exp(i{c 215}v{c 215}e_it) - phi_i(v)} and {bf:phi_i(v)} is the
empirical c.f. of unit {it:i}. These measure the dependence between {bf:e_it} and
nonlinear functions of its own past, summed across lags {it:j} with a Bartlett
kernel {bf:k(j/p)} and integrated over {it:v} against the N(0,1) weight on [-3,3].

{pstd}
{cmd:lee} reports all {it:four} statistics of Lee (2014), each
{bf:->d N(0,1)} under H0 and {it:upper-tailed} (large positive values reject):
{bf:M^a} and {bf:M^b} use the heteroskedasticity-{it:robust} centering/scaling
(pooled and unit-averaged forms, eqs 2.11-2.12); {bf:M0^a} and {bf:M0^b} use the
i.i.d.-error centering (eqs 2.13-2.14). Lee recommends the robust {bf:M^a}; the
i.i.d. versions over-reject under conditional heteroskedasticity. The bandwidth
(lag truncation {it:p}) is chosen by the data-driven plug-in {bf:p0 = c0 T^(1/3)}
(eq 5.4) using a preliminary {opt pbar()}, or fixed at {opt lags()}. Parameter-
estimation uncertainty has no asymptotic impact, so any root-NT-consistent
{it:beta-hat} (host residuals, supplied residuals, or the self-contained FE fit)
is valid.


{marker options}{...}
{title:Options}

{phang}
{opt residuals(varname)} supplies the residual series directly. When omitted,
{cmd:xtdyntest} reconstructs level-equation residuals from {cmd:e(b)} and
{cmd:e(depvar)} over {cmd:e(sample)}.

{phang}
{opt graph} draws a diverging-color heatmap of the N{c 215}N pairwise correlation
matrix. Requires {cmd:heatplot} ({stata ssc install heatplot}); if it is not
installed the graph is skipped with a note.

{phang}
{opt graphname(string)} sets the name of the saved graph. Default is
{cmd:xtd_csd_heat}.

{phang}
{opt notable} suppresses the printed results table (the stored results in
{cmd:r()} are still set).

{phang}
{opt savecorr(name)} stores the pairwise correlation matrix as a Stata matrix
named {it:name}.

{pstd}{it:break-specific options:}

{phang}
{opt at(#)} gives the candidate breakpoint as an observed value of the panel
{it:time} variable (e.g. {cmd:at(1981)}). The known-breakpoint Theorem-1 test is
run. {it:If {opt at()} is omitted}, the unknown-breakpoint {bf:sup}-test of Theorem
2 is run instead, sweeping over all admissible candidate dates.

{phang}
{opt ar(#)} sets the autoregressive order {it:p} of the dynamic model. Default is
{cmd:ar(1)}.

{phang}
{opt full} tests a joint break in {it:both} the slope coefficients and the fixed
effects (the default). {opt reduced} tests a break in the fixed effects only; these
two options are mutually exclusive.

{phang}
{opt reps(#)} sets the number of Monte-Carlo draws used to simulate the sup-test
null distribution (DWT Theorem 2). Default is {cmd:reps(499)}; the minimum is 99.
Ignored when {opt at()} is supplied.

{phang}
{opt seed(#)} sets the random-number seed so that the simulated sup-test p-value is
reproducible. Ignored when {opt at()} is supplied.

{phang}
{opt trim(#)} sets the symmetric fraction of the candidate window trimmed from each
end before taking the supremum (standard practice for sup-type break tests, which
have no power at the sample extremes). Must lie in [0,0.5); default {cmd:trim(0.15)}.
Ignored when {opt at()} is supplied.

{pstd}{it:lee-specific options:}

{phang}
{opt residuals(varname)} supplies the residual series directly, bypassing
estimation. When omitted, residuals come from the host estimator (via
{cmd:predict}) if one is in memory and no {it:indepvars} are given, otherwise from
a self-contained fixed-effects fit of {it:depvar} on its first {it:p} lags and any
{it:indepvars}.

{phang}
{opt ar(#)} sets the autoregressive order {it:p} of the self-contained linear fit.
Default is {cmd:ar(1)}. Used only when residuals are obtained internally.

{phang}
{opt effects(string)} chooses the within transform applied to the residuals before
testing: {cmd:twoway} (remove unit {it:and} time means; the default), {cmd:individual}
(unit means only), {cmd:time} (time means only), or {cmd:none}.

{phang}
{opt pbar(#)} sets the preliminary bandwidth used by the data-driven plug-in for the
final lag truncation. Default is {cmd:pbar(4)} (Lee uses 2, 4, 6); the minimum is 2.

{phang}
{opt lags(#)} fixes the bandwidth (lag truncation {it:p}) at {it:#}. The default
{cmd:lags(0)} requests the data-driven plug-in {bf:p0 = c0 T^(1/3)}. If the plug-in
inputs are ill-conditioned the bandwidth safely falls back to {opt pbar()}.

{phang}
{opt ngrid(#)} sets the number of points in the uniform numerical-integration grid
on [-3,3]. Must be {it:odd} (so the grid is symmetric about 0) and at least 11.
Default is {cmd:ngrid(31)}.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xtdyntest csd} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of cross-sectional units used{p_end}
{synopt:{cmd:r(Tmin)}, {cmd:r(Tmax)}}min/max time periods per unit{p_end}
{synopt:{cmd:r(avgrho)}}average pairwise correlation{p_end}
{synopt:{cmd:r(avgabsrho)}}average absolute pairwise correlation{p_end}
{synopt:{cmd:r(CD)}, {cmd:r(p_CD)}}Pesaran CD statistic and p-value{p_end}
{synopt:{cmd:r(FR)}, {cmd:r(FR_df)}, {cmd:r(p_FR)}}Friedman statistic, df, p-value{p_end}
{synopt:{cmd:r(FRE)}, {cmd:r(FRE_z)}, {cmd:r(p_FRE)}}Frees statistic, z, p-value{p_end}
{synopt:{cmd:r(LM)}, {cmd:r(LM_df)}, {cmd:r(p_LM)}}Breusch-Pagan LM, df, p-value{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(corr)}}N{c 215}N pairwise residual correlation matrix{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(host)}}host estimation command detected{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtdyntest csd}{p_end}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest syr} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(D)}}SYR difference statistic (two-step/Hansen){p_end}
{synopt:{cmd:r(D_df)}}degrees of freedom of the difference test{p_end}
{synopt:{cmd:r(p_D)}}p-value of {cmd:r(D)}{p_end}
{synopt:{cmd:r(D_sargan)}, {cmd:r(p_D_sargan)}}Sargan (unadjusted) difference and p-value{p_end}
{synopt:{cmd:r(S_full)}, {cmd:r(S_rest)}}full / restricted two-step J{p_end}
{synopt:{cmd:r(S_full_u)}, {cmd:r(S_rest_u)}}full / restricted Sargan J{p_end}
{synopt:{cmd:r(df_full)}, {cmd:r(df_rest)}}full / restricted overid df{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(type)}}{cmd:DIF} or {cmd:SYS}{p_end}
{synopt:{cmd:r(host)}}host estimation command{p_end}
{synopt:{cmd:r(rcmd)}}the restricted (x-only) command that was run{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtdyntest syr}{p_end}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest break} with {opt at()} (known breakpoint) stores the following in
{cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}break statistic N(Q2 {c 45} Qtau){p_end}
{synopt:{cmd:r(df)}}degrees of freedom of the break test{p_end}
{synopt:{cmd:r(p)}}p-value of {cmd:r(stat)}{p_end}
{synopt:{cmd:r(Q2)}, {cmd:r(df2)}}no-break GMM objective (Hansen J) and its df{p_end}
{synopt:{cmd:r(Qtau)}, {cmd:r(df_tau)}}break-model objective and its df{p_end}
{synopt:{cmd:r(tau)}, {cmd:r(ktau)}}break time value and its grid position{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}units and number of time periods on the grid{p_end}
{synopt:{cmd:r(M)}, {cmd:r(M_tau)}}moment counts, no-break / break model{p_end}
{synopt:{cmd:r(ar)}}autoregressive order used{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:pointwise (known break)}{p_end}
{synopt:{cmd:r(model)}}{cmd:full} or {cmd:reduced}{p_end}
{synopt:{cmd:r(host)}}{cmd:(self-contained)}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtdyntest break}{p_end}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest break} {it:without} {opt at()} (unknown-breakpoint sup-test) stores
the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(stat)}}sup statistic {bf:Vmax} (on the reference {it:chi-squared}(1) scale){p_end}
{synopt:{cmd:r(p)}}simulated p-value of the sup statistic{p_end}
{synopt:{cmd:r(tau)}, {cmd:r(ktau)}}estimated break time value and its grid position{p_end}
{synopt:{cmd:r(stat_b)}, {cmd:r(df_b)}}pointwise V and df at the estimated break{p_end}
{synopt:{cmd:r(Q2)}, {cmd:r(df2)}}no-break GMM objective (Hansen J) and its df{p_end}
{synopt:{cmd:r(ntau)}}number of candidate breakpoints swept{p_end}
{synopt:{cmd:r(reps)}}number of simulation draws used{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}units and number of time periods on the grid{p_end}
{synopt:{cmd:r(M)}}no-break moment count{p_end}
{synopt:{cmd:r(ar)}}autoregressive order used{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(profile)}}{it:ntau}{c 215}5 candidate profile: position, time, V(tau), df, scaled V{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:sup (unknown break)}{p_end}
{synopt:{cmd:r(model)}}{cmd:full} or {cmd:reduced}{p_end}
{synopt:{cmd:r(host)}}{cmd:(self-contained)}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtdyntest break}{p_end}
{p2colreset}{...}

{pstd}
{cmd:xtdyntest lee} stores the following in {cmd:r()}:

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(Ma)}, {cmd:r(p_Ma)}}robust pooled statistic {bf:M^a} and its (upper-tailed) p-value{p_end}
{synopt:{cmd:r(Mb)}, {cmd:r(p_Mb)}}robust unit-averaged statistic {bf:M^b} and p-value{p_end}
{synopt:{cmd:r(M0a)}, {cmd:r(p_M0a)}}i.i.d. pooled statistic {bf:M0^a} and p-value{p_end}
{synopt:{cmd:r(M0b)}, {cmd:r(p_M0b)}}i.i.d. unit-averaged statistic {bf:M0^b} and p-value{p_end}
{synopt:{cmd:r(stat)}, {cmd:r(p)}}aliases for the recommended {bf:M^a} and its p-value{p_end}
{synopt:{cmd:r(p0)}}bandwidth (lag truncation {it:p}) actually used{p_end}
{synopt:{cmd:r(pbar)}}preliminary bandwidth used by the plug-in{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}units and maximum time periods per unit{p_end}
{synopt:{cmd:r(M)}}number of integration-grid points{p_end}
{synopt:{cmd:r(ar)}}autoregressive order of the self-contained fit{p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}4{c 215}2 matrix (rows {cmd:Ma Mb M0a M0b}; cols {cmd:stat p}){p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(test)}}{cmd:generalized-spectral (linearity)}{p_end}
{synopt:{cmd:r(bw)}}{cmd:plug-in} or {cmd:fixed}{p_end}
{synopt:{cmd:r(effects)}}within transform used ({cmd:twoway}/{cmd:individual}/{cmd:time}/{cmd:none}){p_end}
{synopt:{cmd:r(host)}}residual source / host estimator{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtdyntest lee}{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Arellano-Bond data, system GMM with {cmd:xtdpdgmm}:{p_end}
{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtdpdgmm L(0/1).n w k, gmm(n, lag(2 4) collapse) model(diff) two vce(r)}{p_end}
{phang2}{cmd:. xtdyntest csd}{p_end}
{phang2}{cmd:. xtdyntest csd, graph savecorr(C)}{p_end}

{pstd}After {cmd:xtabond2}:{p_end}
{phang2}{cmd:. xtabond2 n L.n w k, gmm(L.n, collapse) iv(w k) twostep robust noleveleq}{p_end}
{phang2}{cmd:. xtdyntest csd}{p_end}

{pstd}Using your own residual series:{p_end}
{phang2}{cmd:. xtdyntest csd, residuals(myres)}{p_end}

{pstd}SYR error-CSD test after difference GMM (D_DIF2):{p_end}
{phang2}{cmd:. xtdpdgmm L(0/1).n w k, gmm(n, lag(2 4) collapse model(diff)) gmm(w k, lag(1 3) collapse model(diff)) two vce(r)}{p_end}
{phang2}{cmd:. xtdyntest syr}{p_end}

{pstd}SYR error-CSD test after system GMM (D_SYS2):{p_end}
{phang2}{cmd:. xtdpdgmm L(0/1).n w k, gmm(n, lag(2 4) collapse model(diff)) gmm(n, lag(1 1) collapse model(level)) gmm(w k, lag(1 3) collapse) gmm(w k, lag(0 0) collapse model(level)) two vce(r)}{p_end}
{phang2}{cmd:. xtdyntest syr}{p_end}

{pstd}De Wachter-Tzavalis structural-break test, fixed-effect break at 1981:{p_end}
{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtdyntest break n, at(1981) ar(1) reduced}{p_end}

{pstd}Joint slope-and-fixed-effect break (full), AR(1):{p_end}
{phang2}{cmd:. xtdyntest break n, at(1981) full}{p_end}

{pstd}Unknown-breakpoint sup-test (omit {opt at()}), reduced break, reproducible:{p_end}
{phang2}{cmd:. xtdyntest break n, ar(1) reduced reps(499) seed(12345)}{p_end}

{pstd}Inspect the candidate profile and the estimated break date:{p_end}
{phang2}{cmd:. matrix list r(profile)}{p_end}
{phang2}{cmd:. display "break at " r(tau) ", p = " r(p)}{p_end}

{pstd}Lee (2014) linearity test, self-contained AR(1) fixed-effects fit:{p_end}
{phang2}{cmd:. webuse abdata}{p_end}
{phang2}{cmd:. xtset id year}{p_end}
{phang2}{cmd:. xtdyntest lee n, ar(1)}{p_end}

{pstd}Self-contained fit with extra regressors and AR(2) dynamics:{p_end}
{phang2}{cmd:. xtdyntest lee n w k, ar(2)}{p_end}

{pstd}Post-estimation: test the residuals of a fitted model directly:{p_end}
{phang2}{cmd:. xtreg n L.n w k, fe}{p_end}
{phang2}{cmd:. xtdyntest lee n}{p_end}

{pstd}Fixed bandwidth and your own residual series:{p_end}
{phang2}{cmd:. xtdyntest lee n, residuals(myres) lags(4)}{p_end}

{pstd}Read the four statistics from the returned matrix:{p_end}
{phang2}{cmd:. matrix list r(stats)}{p_end}


{marker references}{...}
{title:References}

{phang}
Breusch, T. S., and A. R. Pagan. 1980. The Lagrange multiplier test and its
applications to model specification in econometrics.
{it:Review of Economic Studies} 47: 239-253.

{phang}
De Hoyos, R. E., and V. Sarafidis. 2006. Testing for cross-sectional dependence
in panel-data models. {it:Stata Journal} 6: 482-496.

{phang}
De Wachter, S., and E. Tzavalis. 2012. Detection of structural breaks in linear
dynamic panel data models. {it:Computational Statistics & Data Analysis} 56:
3020-3034.

{phang}
Frees, E. W. 1995. Assessing cross-sectional correlation in panel data.
{it:Journal of Econometrics} 69: 393-414.

{phang}
Friedman, M. 1937. The use of ranks to avoid the assumption of normality implicit
in the analysis of variance. {it:Journal of the American Statistical Association}
32: 675-701.

{phang}
Lee, Y. 2014. Testing a linear dynamic panel data model against nonlinear
alternatives. {it:Journal of Econometrics} 178: 146-166.

{phang}
Pesaran, M. H. 2004. General diagnostic tests for cross section dependence in
panels. Cambridge Working Papers in Economics No. 0435.

{phang}
Sarafidis, V., T. Yamagata, and D. Robertson. 2009. A test of cross section
dependence for a linear dynamic panel model with regressors.
{it:Journal of Econometrics} 148: 149-161.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
