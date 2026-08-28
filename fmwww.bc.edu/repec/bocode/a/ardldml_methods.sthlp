{smcl}
{* *! version 1.0.1  24aug2026}{...}
{vieweralsosee "ardldml" "help ardldml"}{...}
{vieweralsosee "ardldml postestimation" "help ardldml_postestimation"}{...}
{vieweralsosee "ardldml examples" "help ardldml_examples"}{...}
{viewerjumpto "The problem" "ardldml_methods##problem"}{...}
{viewerjumpto "The statistic" "ardldml_methods##statistic"}{...}
{viewerjumpto "The bootstrap" "ardldml_methods##bootstrap"}{...}
{viewerjumpto "Step-to-equation map" "ardldml_methods##map"}{...}
{viewerjumpto "Choices the paper leaves open" "ardldml_methods##choices"}{...}
{viewerjumpto "Compatibility" "ardldml_methods##compat"}{...}
{viewerjumpto "Author" "ardldml_methods##author"}{...}

{title:Title}

{phang}
{bf:ardldml methods} {hline 2} the DML-Bounds procedure, equation by equation


{marker problem}{...}
{title:The problem}

{pstd}
Let u(t) be a candidate equilibrium error following u(t) = rho*u(t-1) + e(t).
No cointegration is H0: rho = 1. Writing pi = rho - 1, the test of pi = 0 is the
Dickey-Fuller root of everything that follows, with the two features that carry
through the whole construction: the rate is T rather than sqrt(T), because
integrated regressors are super-consistent, and the limit is a functional of a
Brownian motion rather than a normal, which is why critical values must be
simulated rather than read off a t table.

{pstd}
With the equilibrium error unobserved and defined through two variables,
u(t) = Y(t) - beta*D(t), the conditional error-correction form is

{p 8 8 2}
D.Y(t) = a0 + rho*Y(t-1) + theta*D(t-1) + delta*D.D(t)
+ sum_i gamma_i*D.Y(t-i) + e(t){p_end}

{pstd}
and the no-cointegration hypothesis is the joint restriction rho = theta = 0 on
the lagged levels Z(t-1) = (Y(t-1), D(t-1)). Pesaran, Shin and Smith bracket the
unknown integration order of D: the lower critical value treats D as I(0), the
upper as I(1). {cmd:ardldml} transplants that device to a {it:different}
unknown.

{pstd}
{bf:Why residualisation is not innocuous.} Partial out a covariate w that is
I(0). A stationary regressor cannot track the stochastic trend of an integrated
one, so the residualised level keeps its unit root no matter how many stationary
controls are removed (Lemma 1 of the paper). Now let w be I(1). Two regimes
appear. If Z cointegrates with w, the population projection recovers the
cointegrating coefficient and the residual is {bf:stationary}: the trend has
been absorbed. If Z and w are independent random walks, no population
cointegrating coefficient exists, the sample projection converges to a
non-degenerate random limit by spurious regression, and the residual stays I(1)
but is contaminated in finite samples.

{pstd}
{bf:Effective integrated count.} With Z in R^k and r independent cointegrating
relations between Z and the integrated nuisance block reproduced by the
population projection, k-tilde = k - r. The orthogonalised statistic converges
to a bounds-type Brownian functional whose stochastic-trend dimension is
k-tilde. So residualisation shifts the relevant null reference {it:within} the
Pesaran-Shin-Smith bracket: k-tilde = k sits at the I(1) endpoint, k-tilde = 0
at the I(0) endpoint.

{pstd}
k-tilde is never estimated. It indexes the limit experiment. The bootstrap
conditions on its realised value implicitly, by holding the nuisance space at
its observed path and regenerating the focal regressor from a marginal model
that conditions on the differenced controls, so any common trend between the
focal regressor and the controls is inherited rather than broken.


{marker statistic}{...}
{title:The statistic}

{pstd}
{bf:Stage 1, balanced block cross-fitting.} Three features of the scalar
analysis dictate the design.

{phang2}
{bf:Balance.} The first-stage target D.Y is I(0). Regressing a stationary target
on integrated levels is unbalanced and spurious, so integrated confounders enter
the D.Y projection {bf:in first differences}. Integrated levels enter only the
projection of the lagged levels, which is where absorption lives. With W0
stationary and W1 integrated, the two designs are

{p 12 12 2}
X(t) = (W0(t), D.W1(t), D.Y(t-1), ..., D.Y(t-p), D.D(t)){p_end}
{p 12 12 2}
and Z(t-1) is projected on the levels (W0(t), W1(t)).{p_end}

{phang2}
{bf:Regularisation.} An unpenalised projection of Z onto many independent
integrated series spuriously stationarises Z, driving k-tilde toward zero and
destroying the relation the test is meant to detect. Vanilla L1 over-selects
integrated regressors for the same reason. The default is therefore adaptive
LASSO with marginal (univariate) slope weights on the {bf:integrated block
only}, with the plug-in penalty lambda = c*sqrt(log d/n)*sigma-hat, c = 1.1.
This is a stabilisation device, not a selection-consistency theorem: the paper's
formal result keeps the integrated block fixed-dimensional.

{phang2}
{bf:Cross-fitting.} The nuisance is estimated on chronological training blocks
separated from the evaluation block by an h-observation buffer, so that the
first-stage error is decoupled from the evaluation-fold innovations. This turns
Neyman orthogonality from an assumption into a consequence of the construction.

{pstd}
Each selected support is refit by unpenalised OLS (Post-LASSO) to remove
shrinkage bias. Degrees of freedom charge the selected support size, and a cell
with non-positive residual degrees of freedom is reported as not estimable
rather than silently returning a number.

{pstd}
{bf:Stage 2, orthogonalisation.} With the out-of-fold fits l-hat, mY-hat and
mD-hat,

{p 8 8 2}
D.Y-tilde(t) = D.Y(t) - l-hat(W(t)),{p_end}
{p 8 8 2}
Y-tilde(t-1) = Y(t-1) - mY-hat(W(t)),{p_end}
{p 8 8 2}
D-tilde(t-1) = D(t-1) - mD-hat(W(t)).{p_end}

{pstd}
{bf:Stage 3, the statistic.} The long-run parameters are estimated by an
{bf:unpenalised, no-intercept} regression on the orthogonalised variables, and
the statistic is the F form of the Wald test of joint insignificance. Writing
the coefficient vector as (pi_y, pi_x), the speed of adjustment is
alpha = -pi_y and the long-run coefficient is theta = pi_x/alpha, whose standard
error comes from the delta method with gradient
(pi_x/pi_y^2, -1/pi_y).

{pstd}
{bf:Penalty selection.} For the D.Y equation the penalty may instead be chosen
by rolling-origin time-series cross-validation: for origins t = T0,...,T-1 the
projection is fitted on {c -(}1,...,t{c )-} and evaluated one step ahead, and
lambda minimises the average out-of-sample squared error. This respects temporal
ordering, unlike ordinary k-fold cross-validation, which would train on the
future. {cmd:penalty(low)} takes the profile minimum, {cmd:penalty(high)} the
one-standard-error rule, {cmd:penalty(medium)} their geometric midpoint.


{marker bootstrap}{...}
{title:The bootstrap, and why the tables fail}

{pstd}
The feasible statistic shares the limit of a classical bounds test in which
k-tilde of the k tested regressors are integrated. That does {bf:not} license
reading it against the tabulated 4.94 and 5.73. The reason is the rate. The
remainder is O(s*log d/sqrt(T)), which vanishes only in the limit: at s = 3,
d = 40, T = 200 it equals about 0.78, and closer to 0.9 once the differenced
block is counted in d. The first-order asymptotics have not taken hold, the
generated-regressor term is still inflating the null, and 5.73 is a
not-yet-reached asymptotic reference rather than a valid finite-sample one.

{pstd}
{bf:Algorithm 1, restricted system wild bootstrap.}

{phang2}
(1) Compute the observed statistic F.

{phang2}
(2) Estimate two auxiliary models. The {bf:restricted conditional model} for
D.Y under H0, with the same deterministic terms and short-run lag structure as
the empirical specification but excluding the lagged levels and the
high-dimensional confounder levels, giving residuals eps-hat. The {bf:marginal
model} for the focal regressor, D.D on an intercept, its own lags, and the
first-stage-selected differenced controls, giving residuals v-hat.

{phang2}
(3) For b = 1,...,B draw a {bf:single} Rademacher sequence eta(t) in
{c -(}-1,+1{c )-} and apply it to the {bf:stacked} residual pair, so that
eps*(t) = eps-hat(t)*eta(t) and v*(t) = v-hat(t)*eta(t). Regenerate D.D*
recursively from the marginal dynamics with the control path held fixed, and
cumulate to the level path D*. Regenerate D.Y* recursively from the restricted
conditional dynamics driven by D.D* and eps*, and cumulate to Y*. Recompute the
{bf:entire} residualised statistic on (Y*, D*, W) with W held at its realised
path, re-selecting the level supports on the regenerated paths so that selection
error is reflected in the bootstrap law.

{phang2}
(4) The critical value is the 1-alpha quantile of the F* and the p-value is the
share of draws at or above F.

{pstd}
{bf:Why the weight is shared.} The Pesaran-Shin-Smith framework exists
{it:because} the focal regressor need not be exogenous: the conditional model
absorbs the contemporaneous correlation between the marginal innovations and the
equation error through the D.D term. A scheme that holds the focal regressor at
its realised path and reweights the conditional residual alone makes the
bootstrap innovations independent of the regressor path {bf:by construction}, so
it simulates a world with zero correlation whatever the data say. Applying one
weight to the stacked pair carries the empirical cross-covariance into every
draw, and with Rademacher weights the conditional heteroskedasticity of both
innovations is preserved as well. Under exogeneity the two schemes coincide
asymptotically, which is why {cmd:bscheme(system)} is the default and
{cmd:bscheme(fixed)} is retained only as the strong-exogeneity special case.

{pstd}
{bf:Why W is held fixed.} Holding the nuisance space at its realised path is
what conditions the bootstrap on the realised trend content, the object the
bracket is built on. Cumulating v* keeps the regenerated focal regressor
integrated by construction, and because the marginal model conditions on the
differenced controls, any common trend it shares with the integrated controls is
transmitted through the fixed control path rather than destroyed by independent
resampling. That is what makes the bootstrap distribution track the correct
point inside the bracket.

{pstd}
{bf:Which supports are frozen.} The stationary first-stage support is frozen
across draws while the level supports are re-selected on every path. Freezing
the level supports instead leaves a size distortion that grows with T.
{cmd:nofreeze} lifts the stationary freeze as well.

{pstd}
{bf:Sample length in the bootstrap.} Each regenerated path is built on the
design index, so constructing its own design costs a further p+1 observations.
{cmd:e(N_boot)} reports the result. This matches the reference implementation
exactly and is deliberate: the bootstrap statistic must be the same functional
of the same construction, not a version computed on a longer sample.


{marker map}{...}
{title:Step-to-equation map}

{pstd}
Every computational step, named against the paper.

{synoptset 34}{...}
{synopthdr:code}
{synoptline}
{synopt:{cmd:ardldml_design()}}Section 3.5, Assumption 4: the balanced split of
stationary levels, integrated differences and lagged differences{p_end}
{synopt:{cmd:ardldml_lasso()}}L1-penalised projection; the plug-in rule of
Appendix B{p_end}
{synopt:{cmd:ardldml_apl()}}Section 4.1: adaptive weights on the integrated
block, Post-LASSO refit{p_end}
{synopt:{cmd:ardldml_edges()}, {cmd:ardldml_crossfit()}}Section 4.1 and Lemma 2:
h-block cross-fitting with buffer{p_end}
{synopt:{cmd:ardldml_tscv()}}equation (11): rolling-origin penalty selection{p_end}
{synopt:{cmd:ardldml_compute()}}equations (4)-(6) then (7)-(9) then (10): fit,
residualise, test{p_end}
{synopt:{cmd:ardldml_boot()}}Algorithm 1 and Section 6, applied form{p_end}
{synopt:{cmd:ardldml_quantile()}}the 1-alpha quantile of the finite F*{p_end}
{synopt:{cmd:ardldml_classical()}}Pesaran, Shin and Smith (2001), all three
steps{p_end}
{synopt:{cmd:ardldml_pss()}}the Table CI data-generating process, resimulated at
your sample size{p_end}
{synoptline}
{p2colreset}{...}


{marker choices}{...}
{title:Choices the paper leaves open, and how they were resolved}

{pstd}
Each of these is a place where the text admits more than one reading. All were
resolved to match the reference implementation, and all are numerically
checkable with the shipped {cmd:ardldml_validate.do}.

{phang}
1. {bf:Stage 3 carries no intercept}, as equation (10) is written. The
first-stage projections already carry intercepts, so the residuals are mean-zero
and a constant would be redundant. {cmd:st3cons} adds one for sensitivity; it is
not the paper's statistic.

{phang}
2. {bf:case() does not enter the statistic.} It sets the deterministic terms of
the restricted conditional model the bootstrap resamples from, which Algorithm 1
requires to match the empirical specification.

{phang}
3. {bf:Adaptive weights apply to the integrated block only}, which is Section
4.1's stated motivation: vanilla L1 over-selects {it:integrated} regressors.
Stationary controls stay under the plain penalty.

{phang}
4. {bf:The m_Z projection always uses the plug-in penalty.} Equation (11)
defines the cross-validated penalty for the D.Y equation alone.

{phang}
5. {bf:Equation (3) carries only the contemporaneous D.D term}, so lags of D.D
enter the conditional design only under {cmd:dlags}. The bootstrap's marginal
model always has its own lags, per Appendix B: these are two different models.

{phang}
6. {bf:Definition 2's Delta_m arm.} Definition 2 words the comparison arm as
"the unpenalized m_Z projection", but Section 4.1 motivates the contrast as
adaptive versus {it:vanilla L1}, and the reference implementation takes the
second reading. {helpb ardldml_postestimation:estat absorption} therefore
defaults to {cmd:mzalt(plain)} and offers {cmd:mzalt(ols)} for the literal
wording.


{marker compat}{...}
{title:Numerical compatibility}

{pstd}
{cmd:ardldml} was validated against an independent Python implementation of the
same paper, on the paper's own application. The shipped do-file
{cmd:ardldml_validate.do} checks sixty quantities: the design length, statistic,
speed of adjustment, long-run coefficient and standard error for four monetary
regimes on two control sets, plus the four arms of the trend-absorption
diagnostic and the seven cells of the penalty sweep. All sixty agree.

{pstd}
Agreement is to machine precision, not merely to the printed digits: the
residualised series, the realised plug-in penalties and the per-fold selected
supports match to eleven or more significant digits. Two things were needed to
achieve that, and both are worth knowing.

{phang}
{bf:Storage type matters.} The bundled data is stored as {cmd:double}. Held as
{cmd:float}, the series carry only about seven significant digits, which moves
the statistic in its fourth decimal. If you import your own data, do not let it
land in {cmd:float}.

{phang}
{bf:The LASSO tolerance matters at a selection boundary.} The first-stage
penalty is refined in two steps, and the second step reads sigma-hat off the
first LASSO fit. A loosely converged first fit therefore shifts lambda, which at
a boundary can flip a control in or out of a fold's support. In one fold of one
of the sixty checked quantities the reference's published figure reflects
scikit-learn's default tol = 1e-4 stopping short of convergence; tightening the
reference's own solver by a single decade reproduces {cmd:ardldml}'s answer to
eleven significant digits. {cmd:ardldml} solves to a tight tolerance by default
({cmd:ltol()}), so its selected support is determinate and does not depend on
the machine's BLAS.

{pstd}
{bf:The bootstrap p-value is not cross-language reproducible} by seeding alone,
because Stata's random-number generator is not NumPy's PCG64. Differences are
ordinary Monte Carlo noise: on the paper's application at B = 999 the two
implementations give critical values of 3.94 and 3.97 and p-values of 0.75 and
0.73, with the same verdict. Use {cmd:etafile()} to feed identical wild weights
to both if you need exact agreement.


{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
