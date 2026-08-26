{smcl}
{* *! version 1.0.0  24aug2026}{...}
{vieweralsosee "ardldml postestimation" "help ardldml_postestimation"}{...}
{vieweralsosee "ardldml methods" "help ardldml_methods"}{...}
{vieweralsosee "ardldml examples" "help ardldml_examples"}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{vieweralsosee "ddml" "help ddml"}{...}
{viewerjumpto "Syntax" "ardldml##syntax"}{...}
{viewerjumpto "Description" "ardldml##description"}{...}
{viewerjumpto "Options" "ardldml##options"}{...}
{viewerjumpto "Interpreting the output" "ardldml##output"}{...}
{viewerjumpto "Remarks" "ardldml##remarks"}{...}
{viewerjumpto "Examples" "ardldml##examples"}{...}
{viewerjumpto "Stored results" "ardldml##results"}{...}
{viewerjumpto "References" "ardldml##references"}{...}
{viewerjumpto "Author" "ardldml##author"}{...}

{title:Title}

{phang}
{bf:ardldml} {hline 2} DML-Bounds: ARDL bounds testing for cointegration with
many persistent controls


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:ardldml} {it:depvar} {it:focalvar} {ifin}{cmd:,}
{opth c:ontrols(varlist)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opth c:ontrols(varlist)}}nuisance controls, in {bf:levels}; required{p_end}
{synopt:{opth i:ntegrated(varlist)}}subset of {cmd:controls()} to treat as I(1){p_end}
{synopt:{opt lags(#)}}short-run lag order p; default {cmd:lags(4)}{p_end}
{synopt:{opt case(#)}}deterministic case 1-5; default {cmd:case(3)}{p_end}
{synopt:{opt dlags}}also put lags of D.{it:focalvar} in the conditional design{p_end}

{syntab:Cross-fitting}
{synopt:{opt blo:cks(#)}}number of chronological blocks K; default {cmd:blocks(5)}{p_end}
{synopt:{opt kf:olds(#)}}synonym for {cmd:blocks()}, for {helpb ddml} users{p_end}
{synopt:{opt buf:fer(#)}}buffer width h in observations; default {cmd:buffer(0)}{p_end}

{syntab:First stage}
{synopt:{opt mz:proj(string)}}{cmd:adaptive} (default), {cmd:plain} or {cmd:ols}{p_end}
{synopt:{opt pen:alty(string)}}{cmd:plugin} (default), {cmd:low}, {cmd:medium}, {cmd:high}, or a number{p_end}
{synopt:{opt cp:en(#)}}constant c in the plug-in penalty; default {cmd:cpen(1.1)}{p_end}
{synopt:{opt ltol(#)}}LASSO convergence tolerance; default {cmd:ltol(1e-10)}{p_end}

{syntab:Bootstrap}
{synopt:{opt b:reps(#)}}bootstrap replications B; default {cmd:breps(999)}{p_end}
{synopt:{opt seed(#)}}random-number seed{p_end}
{synopt:{opt bsch:eme(string)}}{cmd:system} (default) or {cmd:fixed}{p_end}
{synopt:{opt nobo:otstrap}}skip the bootstrap (no critical value is produced){p_end}
{synopt:{opt nofr:eeze}}re-select the stationary support on every draw too{p_end}
{synopt:{opt eta:file(filename)}}read the Rademacher weights from a text file{p_end}
{synopt:{opt l:evel(#)}}confidence level; default {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt:{opt showf:irst}}report which variables the first stage selected{p_end}
{synopt:{opt graph}}plot the bootstrap null distribution{p_end}
{synopt:{opt graphbl:ocks}}plot the h-block cross-fitting structure{p_end}
{synopt:{opt name(string)}}name for the graph{p_end}
{synopt:{opt graphopt:s(string)}}other {help twoway_options}{p_end}
{synopt:{opt nohe:ader}}suppress the header block{p_end}
{synopt:{opt nota:ble}}suppress the results table{p_end}
{synopt:{opt nole:gend}}suppress the interpretive footer{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The data must be {helpb tsset} as a single time series, and the estimation
sample must be a contiguous span with no gaps.{p_end}
{p 4 6 2}
{it:depvar} and {it:focalvar} enter in {bf:levels}. Take logs yourself
beforehand if the relation is in logs.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:ardldml} implements {bf:DML-Bounds}, the procedure of Villena (2026): a
test for a long-run (cointegrating) relationship between {it:depvar} and
{it:focalvar} when the conditioning set is high-dimensional and may itself
carry stochastic trends.

{pstd}
The classical ARDL bounds test of Pesaran, Shin and Smith (2001) brackets one
unknown: whether the tested regressors are I(0) or I(1). With a large,
persistent control set a second unknown appears. Partialling out controls that
carry stochastic trends can {bf:absorb} part of the long-run variation that
identifies the error-correction relation. What then governs the null is not the
integration order of the original regressors but the {bf:effective integrated
count} k-tilde: the number of stochastic trends that survive residualisation.
k-tilde = k puts the null at the classical I(1) endpoint, k-tilde = 0 at the
I(0) endpoint, and anything between lands inside the bracket.

{pstd}
The procedure has three stages. A {bf:balanced} first stage projects the
differenced outcome on stationary regressors only and the lagged levels on the
control levels, cross-fitted over contiguous time blocks separated by an
h-observation buffer. The lagged levels are then residualised, and the F form
of the Wald test of joint insignificance is computed on the orthogonalised
terms. Inference comes from a {bf:restricted system wild bootstrap} that
regenerates the outcome and the focal regressor jointly under the null.

{pstd}
{bf:There is no bounds table in this command.} The critical value is generated
from your data. Comparing the statistic with the tabulated 4.94/5.73 values
over-rejects severely once the controls are integrated; see
{helpb ardldml_methods:ardldml methods}.

{pstd}
See {helpb ardldml_methods:ardldml methods} for the equation-by-equation
derivation and the step-to-equation map, and
{helpb ardldml_postestimation:ardldml postestimation} for the diagnostics you
should run before believing any single fit.


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opth controls(varlist)} gives the nuisance controls, {bf:in levels}. Required.
The set may be large relative to the sample; that is the point of the method.
It must not contain {it:depvar} or {it:focalvar}.

{phang}
{opth integrated(varlist)} names the subset of {cmd:controls()} to treat as
I(1). This choice is a {bf:specification decision}, not a pre-test: integrated
controls enter the differenced-target projection in first differences, and only
integrated controls can absorb a stochastic trend. Choose them on economic
grounds. If you leave the option empty every control is treated as stationary,
which forces k-tilde = k and switches the whole trend-absorption mechanism off.

{phang}
{opt lags(#)} sets the short-run lag order p, the number of lagged differences
of {it:depvar} entering the conditional design. Default 4, the paper's monthly
specification. The effective sample loses p+1 observations.

{phang}
{opt case(#)} selects the deterministic case, numbered as in Pesaran, Shin and
Smith and as in {helpb ardl}: 1 no intercept no trend, 2 restricted intercept,
3 unrestricted intercept (default), 4 unrestricted intercept and restricted
trend, 5 unrestricted intercept and trend. {bf:This does not enter the
statistic}, which is a no-intercept projection on the orthogonalised levels
either way. It sets the deterministic terms of the restricted conditional model
the bootstrap resamples from, which Algorithm 1 requires to match the empirical
specification.

{phang}
{opt dlags} adds lags of D.{it:focalvar} to the conditional design, giving the
general ARDL(p,q) short-run structure. Off by default, because equation (3) of
the paper carries only the contemporaneous term. The bootstrap's marginal model
always has its own lags either way.

{dlgtab:Cross-fitting}

{phang}
{opt blocks(#)} is the number of contiguous chronological blocks K. Folds
cannot be random in a time series: randomly held-out observations are adjacent
to their own training data and the first-stage error is then correlated with
the evaluation innovations. {opt kfolds(#)} is accepted as a synonym for users
coming from {helpb ddml}.

{phang}
{opt buffer(#)} is the buffer width h. Observations within h of an evaluation
window are dropped from that window's training set, which is what decouples the
first-stage error from the evaluation-fold innovations. It should cover the
memory of the process: with monthly data and p = 4, values of 6 to 12 are
reasonable. It costs sample; {helpb ardldml_postestimation:estat blocks} reports
exactly how much.

{dlgtab:First stage}

{phang}
{opt mzproj(string)} chooses the projection of the lagged levels on the control
levels, which is the only place trend absorption can happen.

{p2colset 12 26 28 2}{...}
{p2col:{cmd:adaptive}}adaptive LASSO with marginal-slope weights on the
integrated block, the paper's default{p_end}
{p2col:{cmd:plain}}vanilla L1, which over-selects integrated regressors and so
induces spurious absorption{p_end}
{p2col:{cmd:ols}}unpenalised, the low-dimensional corner; unstable or infeasible
when the control set is large{p_end}
{p2colreset}{...}

{phang}
{opt penalty(string)} sets how the penalty for the {it:differenced-target}
equation is chosen: {cmd:plugin} (default) uses c*sqrt(log d/n)*sigma-hat;
{cmd:low}, {cmd:medium} and {cmd:high} are the three rolling-origin
cross-validation rules of the paper's Section 7.5 (the profile minimum, the
geometric midpoint, and the one-standard-error rule); a number fixes it
directly. The level projection always uses the plug-in rule regardless.

{phang}
{opt cpen(#)} is the constant c in the plug-in penalty. 1.1 is the paper's
value. Lower values select more aggressively.

{phang}
{opt ltol(#)} is the convergence tolerance of the coordinate-descent LASSO.
The default is tight enough that the selected support is determinate and does
not depend on the machine's floating-point arithmetic. Loosen it only to probe
how close a borderline control sits to its selection boundary.

{dlgtab:Bootstrap}

{phang}
{opt breps(#)} sets the number of bootstrap replications. The paper uses 999.

{phang}
{opt seed(#)} seeds Stata's random-number generator, making the run
reproducible {it:within Stata}. It cannot reproduce the reference Python
package's draws, which come from NumPy's PCG64 stream; use {opt etafile()} for
that.

{phang}
{opt bscheme(string)} chooses the resampling scheme. {cmd:system} is Algorithm
1: one Rademacher sequence multiplies the {bf:stacked} residual pair, so every
draw carries the empirical contemporaneous covariance between the conditional
and marginal innovations, and the focal regressor is regenerated and
re-cumulated. {cmd:fixed} holds the focal regressor at its realised path and
reweights the conditional residual alone. {bf:fixed is valid only under strong
exogeneity} of the focal regressor; under exogeneity the two agree
asymptotically, so nothing is lost by keeping the default.

{phang}
{opt nobootstrap} computes the statistic but no critical value. The statistic
then has no reference distribution and should not be interpreted. Useful when
sweeping specifications.

{phang}
{opt nofreeze} re-selects the stationary first-stage support on every bootstrap
path as well. By default that support is frozen while the {bf:level} supports
are re-selected on every path, which is what the paper specifies: freezing the
level supports instead "leaves a size distortion that grows with T".

{phang}
{opt etafile(filename)} reads the {c 177}1 wild weights from a plain text file,
B rows by n columns, whitespace or comma separated, instead of drawing them.
This exists so a bootstrap can be reproduced across languages: feed the same
weights to this command and to the reference implementation and the two
p-values agree exactly. n here is the {it:design} length, e(N).

{dlgtab:Reporting}

{phang}
{opt showfirst} lists the variables the first stage selected in each
projection, and the realised plug-in penalty.

{phang}
{opt graph} plots the bootstrap null distribution with the observed statistic
and the critical value marked. {opt graphblocks} plots the cross-fitting
structure. {opt name()} and {opt graphopts()} control the result.


{marker output}{...}
{title:Interpreting the output}

{pstd}
{bf:Header.} The three lines on the left name the orthogonalised objects, in
the style {helpb ddml} uses: the differenced outcome after its stationary
projection, and each lagged level after its projection on the control levels.
On the right are the design length (shorter than your sample by p+1), the
number of controls and how many are being treated as I(1).

{pstd}
{bf:DML-Bounds F.} The F form of the Wald test that both residualised level
terms are zero. {bf:Read it only against the bootstrap critical value in the
next column.} It is not a classical bounds statistic and the tabulated values do
not apply to it.

{pstd}
{bf:bootstrap p-value.} The share of bootstrap draws at or above the observed
statistic. Small p means reject the null of no level relationship, that is,
evidence of a long-run relationship {it:conditional on your controls}.

{pstd}
{bf:alpha.} The speed of adjustment, minus the coefficient on the residualised
lagged dependent variable. A well-behaved error-correction relation has alpha
positive in this parameterisation. Values near zero mean the level terms carry
almost no information and theta is then poorly identified, which shows up as a
very large se(theta).

{pstd}
{bf:theta.} The long-run coefficient, the ratio of the two level coefficients,
with a delta-method standard error and a Wald confidence interval. When the test
does not reject, theta is describing a relation the data do not support: read it
as descriptive, not as an estimate of an equilibrium that has been established.

{pstd}
{bf:selected.} With {opt showfirst}, the number of control {bf:levels} the m_Z
projection retained is the empirical counterpart of the effective integrated
count. Zero means nothing was absorbed and orthogonalisation did nothing; a
large number means heavy absorption, and the long-run coefficient should be
checked for instability with
{helpb ardldml_postestimation:estat penalty}.


{marker remarks}{...}
{title:Remarks and practical guidance}

{pstd}
{bf:The estimand is conditional, and that is the central caveat.} {cmd:ardldml}
does not ask whether {it:depvar} and {it:focalvar} cointegrate unconditionally.
It asks whether they cointegrate {bf:given} {cmd:controls()}. If a control is
itself part of the equilibrium system, partialling it out absorbs the very trend
the test is meant to detect: k-tilde is driven toward zero and the relation is
destroyed rather than cleaned. A non-rejection then reflects over-absorption,
not the absence of a long-run relationship. This cannot be diagnosed from a
single fit. Always run
{helpb ardldml_postestimation:estat absorption}.

{pstd}
{bf:Do not compare the statistic with 4.94 and 5.73.} The generated-regressor
remainder is O(s log d / sqrt(T)), which is order one at the sample sizes
applied work uses: at s = 3, d = 40, T = 200 it is roughly 0.78. The first-order
asymptotics have not taken hold, so the tabulated value is a not-yet-reached
asymptotic reference rather than a valid finite-sample one. In the paper's Monte
Carlo, testing against 5.73 reaches a rejection rate of 0.737 under a null with
integrated nuisance. That is why every critical value here is computed.

{pstd}
{bf:Choosing K and h.} K trades bias against the size of each training set;
5 or 6 is usual. h should cover the memory of the process. The buffer discards
at most h(K-1) observations from each training set, which is second-order
asymptotically but very much first-order at applied sample sizes. Check the cost
with {helpb ardldml_postestimation:estat blocks} before committing.

{pstd}
{bf:Sample size.} The design loses p+1 observations, and the bootstrap statistic
is computed on a path that is p+1 shorter again, exactly as in the reference
implementation. With p = 4 you need a comfortable margin above 50 observations
for the first stage to have degrees of freedom left after selection.

{pstd}
{bf:The integrated block should stay small.} The paper's validity theory holds
the integrated nuisance block fixed-dimensional; selection over a growing
integrated block is a sparse-cointegration problem it explicitly leaves open,
and it can absorb trends spuriously. Prefer a short, economically motivated
{cmd:integrated()} list.

{pstd}
{bf:Relation to other Stata commands.} {helpb ardl} (Kripfganz and Schneider)
implements the classical bounds test with response-surface critical values and
is the right tool when the conditioning set is small; {cmd:ardldml} reduces to
that setting only in spirit, not in arithmetic. {helpb ddml} (Ahrens, Hansen,
Schaffer and Wiemann) shares the orthogonalisation and cross-fitting logic but
targets a low-dimensional causal parameter under random or cluster-randomised
folds with asymptotic-normal inference; it cannot produce this test. Use
{helpb ardldml_postestimation:estat classical} to put the classical benchmark
next to the DML-Bounds result on the same sample.

{pstd}
{bf:Reproducibility.} Results are deterministic given the data and options; the
only randomness is the bootstrap, controlled by {opt seed()}. The first-stage
LASSO is solved to a tight tolerance by default so the selected support does not
depend on the machine.


{marker examples}{...}
{title:Examples}

{pstd}Setup: exchange-rate pass-through to U.S. prices, late Great Moderation{p_end}
{phang2}{cmd:. net get ardldml}{p_end}
{phang2}{cmd:. use ardldml_passthrough, clear}{p_end}
{phang2}{cmd:. foreach v in cpi neer m2 ip oil {c -(}}{p_end}
{phang2}{cmd:.     replace `v' = ln(`v')}{p_end}
{phang2}{cmd:. {c )-}}{p_end}
{phang2}{cmd:. tsset mdate}{p_end}
{phang2}{cmd:. keep if inrange(mdate, tm(1999m1), tm(2007m12))}{p_end}

{pstd}The paper's reference specification{p_end}
{phang2}{cmd:. ardldml cpi neer, controls(m2 ffr ip unrate oil gs10 baa)}{break}
{cmd:      integrated(m2 ip oil gs10 baa ffr) lags(4) blocks(5) buffer(6)}{break}
{cmd:      breps(999) seed(20260625) showfirst}{p_end}

{pstd}The diagnostic you must not skip{p_end}
{phang2}{cmd:. estat absorption, drop(m2 oil)}{p_end}

{pstd}Robustness across the penalty and the projection{p_end}
{phang2}{cmd:. estat penalty}{p_end}

{pstd}The classical benchmark on the same sample{p_end}
{phang2}{cmd:. estat classical}{p_end}

{pstd}See {helpb ardldml_examples:ardldml examples} for a fuller worked
session.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:ardldml} stores the following in {cmd:e()}:{p_end}

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}design length (sample minus p+1){p_end}
{synopt:{cmd:e(N_raw)}}observations in the estimation sample{p_end}
{synopt:{cmd:e(N_boot)}}design length of each bootstrap path{p_end}
{synopt:{cmd:e(F)}}DML-Bounds statistic{p_end}
{synopt:{cmd:e(crit)}}bootstrap critical value{p_end}
{synopt:{cmd:e(p)}}bootstrap p-value{p_end}
{synopt:{cmd:e(B)}}bootstrap replications used{p_end}
{synopt:{cmd:e(n_fail)}}bootstrap draws that failed and were dropped{p_end}
{synopt:{cmd:e(corr_ev)}}correlation of the conditional and marginal residuals{p_end}
{synopt:{cmd:e(alpha)}}speed of adjustment{p_end}
{synopt:{cmd:e(theta)}}long-run coefficient{p_end}
{synopt:{cmd:e(theta_se)}}its delta-method standard error{p_end}
{synopt:{cmd:e(df_rest)}}number of restrictions (2){p_end}
{synopt:{cmd:e(nsel_dy)}}variables selected in the differenced-target projection{p_end}
{synopt:{cmd:e(nsel_z)}}control levels selected in the m_Z projection{p_end}
{synopt:{cmd:e(lambda)}}realised plug-in penalty{p_end}
{synopt:{cmd:e(k_ctrl)}, {cmd:e(k_int)}}controls, and how many treated as I(1){p_end}
{synopt:{cmd:e(lags)}, {cmd:e(blocks)}, {cmd:e(buffer)}, {cmd:e(case)}}the specification{p_end}
{synopt:{cmd:e(cpen)}, {cmd:e(ltol)}, {cmd:e(dlags)}, {cmd:e(st3cons)}}tuning{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:ardldml}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}, {cmd:e(focal)}}the two tested variables{p_end}
{synopt:{cmd:e(controls)}, {cmd:e(integrated)}}the conditioning set{p_end}
{synopt:{cmd:e(mzproj)}, {cmd:e(penrule)}, {cmd:e(bscheme)}}first stage and bootstrap{p_end}
{synopt:{cmd:e(sel_dy)}, {cmd:e(sel_z)}}names of the selected variables{p_end}
{synopt:{cmd:e(tvar)}}time variable{p_end}
{synopt:{cmd:e(predict)}}{cmd:ardldml_p}{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b)}, {cmd:e(V)}}the two level coefficients and their covariance{p_end}
{synopt:{cmd:e(draws)}}the usable bootstrap statistics{p_end}
{synopt:{cmd:e(blocks_tab)}}the cross-fitting partition{p_end}

{p2col 5 22 26 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks the estimation sample{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
Villena, M. 2026. Testing cointegration with many persistent controls. SSRN
working paper 6472826.
{browse "https://doi.org/10.2139/ssrn.6472826":https://doi.org/10.2139/ssrn.6472826}

{phang}
Pesaran, M. H., Y. Shin, and R. J. Smith. 2001. Bounds testing approaches to the
analysis of level relationships. {it:Journal of Applied Econometrics} 16:
289-326.

{phang}
Chernozhukov, V., D. Chetverikov, M. Demirer, E. Duflo, C. Hansen, W. Newey, and
J. Robins. 2018. Double/debiased machine learning for treatment and structural
parameters. {it:Econometrics Journal} 21: C1-C68.

{phang}
Kripfganz, S., and D. C. Schneider. 2020. Response surface regressions for
critical value bounds and approximate p-values in equilibrium correction models.
{it:Oxford Bulletin of Economics and Statistics} 82: 1456-1481.

{phang}
Zou, H. 2006. The adaptive lasso and its oracle properties. {it:Journal of the
American Statistical Association} 101: 1418-1429.

{phang}
McCracken, M. W., and S. Ng. 2016. FRED-MD: A monthly database for
macroeconomic research. {it:Journal of Business and Economic Statistics} 34:
574-589.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}

{pstd}
The method is Villena's; this is an independent implementation of it, validated
against an independent Python implementation of the same paper. Please cite the
paper alongside the software.
