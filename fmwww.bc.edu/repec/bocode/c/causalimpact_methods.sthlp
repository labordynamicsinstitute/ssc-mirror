{smcl}
{* *! version 1.0.0  05aug2026}{...}
{vieweralsosee "causalimpact" "help causalimpact"}{...}
{vieweralsosee "causalimpact interpretation" "help causalimpact_interpretation"}{...}
{vieweralsosee "causalimpact rcheck" "help causalimpact_rcheck"}{...}
{vieweralsosee "causalimpact postestimation" "help causalimpact_postestimation"}{...}
{viewerjumpto "Overview" "causalimpact_methods##overview"}{...}
{viewerjumpto "The state-space model" "causalimpact_methods##model"}{...}
{viewerjumpto "Components of state" "causalimpact_methods##state"}{...}
{viewerjumpto "Priors" "causalimpact_methods##priors"}{...}
{viewerjumpto "Posterior simulation" "causalimpact_methods##inference"}{...}
{viewerjumpto "Evaluating impact" "causalimpact_methods##impact"}{...}
{viewerjumpto "Step to equation map" "causalimpact_methods##map"}{...}
{viewerjumpto "Documented deviations" "causalimpact_methods##deviations"}{...}
{viewerjumpto "Validation" "causalimpact_methods##validation"}{...}
{viewerjumpto "Author" "causalimpact_methods##author"}{...}

{title:Title}

{phang}
{bf:causalimpact methods} {hline 2} The model behind {cmd:causalimpact}, equation
by equation


{marker overview}{...}
{title:Overview}

{pstd}
This page documents exactly what {cmd:causalimpact} computes and where each
computation comes from. Equation numbers are those of Brodersen, Gallusser,
Koehler, Remy and Scott (2015), {it:Annals of Applied Statistics} 9(1): 247-274,
{browse "https://doi.org/10.1214/14-AOAS788":DOI: 10.1214/14-AOAS788}, which is
open access from the Institute of Mathematical Statistics. File and line
references of the form {cmd:impact_model.R:197} point into the source of the R
package {cmd:CausalImpact} 1.4.1, the compatibility target, at
{browse "https://github.com/google/CausalImpact":github.com/google/CausalImpact}.

{pstd}
Throughout, {it:n} is the number of pre-intervention time points, {it:m} the
total number of time points in the modelling window, {it:J} the number of
control series, and {it:d} the dimension of the latent state.


{marker model}{...}
{title:The state-space model}

{pstd}
A structural time-series model is a pair of equations,

{p 8 8 2}
    y_t     = Z_t' alpha_t + eps_t,     eps_t ~ N(0, sigma{c 94}2_t)     (2.1){break}
    alpha_t+1 = T_t alpha_t + R_t eta_t,  eta_t ~ N(0, Q_t)             (2.2)

{pstd}
(2.1) is the {bf:observation equation}: it links the scalar observation y_t to a
{it:d}-dimensional latent state alpha_t. (2.2) is the {bf:state equation}: it
governs how the state evolves. Writing the state error as R_t eta_t permits state
components of less than full rank, which the seasonal component needs.

{pstd}
The errors of different components are taken to be independent, so Q_t is
block-diagonal, alpha_t is the concatenation of the component states, and T_t and
R_t are block-diagonal. In this implementation R Q R' is therefore a diagonal
matrix and is stored as a vector.

{pstd}
The counterfactual is produced by a single device, and it is worth stating
plainly because everything else follows from it: {bf:the response is set to
missing over the post-intervention period before the model is fitted}
({cmd:impact_analysis.R:411}). The Kalman filter skips the update step wherever
the response is missing, so the smoothed state over the post-period is driven
entirely by the pre-period relationship and by the controls, which {it:are}
observed there. Draws of the state over that stretch are therefore draws from the
posterior predictive distribution of the counterfactual, eq. (2.14).


{marker state}{...}
{title:Components of state}

{dlgtab:Local level}

{pstd}
The paper's eq. (2.3) defines a local linear {it:trend},

{p 8 8 2}
    mu_t+1   = mu_t + delta_t + eta_mu,t{break}
    delta_t+1 = delta_t + eta_delta,t

{pstd}
The R package, and therefore this command, fits the special case with
delta_t identically zero, i.e. a {bf:local level}
({cmd:AddLocalLevel}, {cmd:impact_model.R:200}). The paper justifies the choice
in Sec. 4: when good controls are available they already absorb trend and
seasonality, and a local linear trend adds flexibility that widens the intervals
without buying accuracy. The transition block is the scalar 1 and the innovation
variance is sigma{c 94}2_mu.

{dlgtab:Seasonality}

{pstd}
With {cmd:nseasons(}{it:S}{cmd:)} the model adds

{p 8 8 2}
    gamma_t+1 = - sum_{c -(}s=0{c )-}{c 94}{c -(}S-2{c )-} gamma_t-s + eta_gamma,t     (2.5)

{pstd}
The state holds the S-1 most recent seasonal effects. The transition block is
(S-1) x (S-1) with -1 across the top row, 1 along the subdiagonal and 0
elsewhere; the error term is a scalar, so the block has less than full rank. The
mean structure forces the seasonal effects to sum to zero over S seasons.

{pstd}
With {cmd:seasonduration(}{it:D}{cmd:)} greater than 1 the season advances only
every D time points. Following the paper's own recipe for multiple periods, the
seasonal transition block is set to the identity with zero innovation variance
whenever t is not the last point of a season, and to the block above otherwise.
Internally the command builds the two transition matrices once and switches
between them with an indicator, which avoids rebuilding a matrix at every step.

{dlgtab:Contemporaneous covariates, static coefficients}

{pstd}
A static regression is written in state-space form by setting
Z_t = beta'x_t with alpha_t = 1. Computationally the command does not put beta in
the state. It follows the paper's own decomposition in Sec. 2.3: the regression
mean is subtracted from the response before the state is drawn, and the state
contribution is subtracted from the response before beta is drawn. The two
conditionals are exactly those of the joint model, so this is a Gibbs sweep, not
an approximation.

{pstd}
All covariates are assumed contemporaneous. A known lag can be handled by
shifting the regressor yourself, e.g. by passing {cmd:L3.x1}.

{dlgtab:Contemporaneous covariates, dynamic coefficients}

{pstd}
With {cmd:dynamicregression} the coefficients follow independent random walks,

{p 8 8 2}
    x_t' beta_t = sum_j x_j,t beta_j,t{break}
    beta_j,t+1  = beta_j,t + eta_beta,j,t,   eta_beta,j,t ~ N(0, sigma{c 94}2_beta_j)   (2.6)

{pstd}
which in state-space form means appending beta_t to the state, setting that part
of the transition matrix to the identity, Q_t = diag(sigma{c 94}2_beta_j), and
making the output vector Z_t = x_t time-varying. The command does exactly this,
so with dynamic regression the filter genuinely carries a time-varying Z.


{marker priors}{...}
{title:Prior distributions}

{dlgtab:Variance parameters}

{pstd}
Each component variance receives the conjugate prior of eq. (2.7),

{p 8 8 2}
    1/sigma{c 94}2 ~ G(nu/2, s/2)

{pstd}
so that s/nu is a prior estimate of sigma{c 94}2 and nu is the weight given to
it, in units of prior sample size. In the R package these are supplied through
{cmd:SdPrior(sigma.guess, sample.size, upper.limit)}, which corresponds to
nu = {cmd:sample.size} and s = nu * {cmd:sigma.guess}{c 94}2, with sigma
truncated above at {cmd:upper.limit}. The full conditional is
1/sigma{c 94}2 ~ G((nu+n)/2, (s + sum eta{c 94}2)/2), and the command draws from
it by inverse-CDF on the truncated gamma, so the truncation is respected exactly
rather than by rejection.

{pstd}
The settings replicate {cmd:impact_model.R} line for line:

{p2colset 8 46 48 2}{...}
{p2col :{bf:local level}}guess = {cmd:priorlevelsd()} * sd(y), nu = 32,
upper = sd(y){p_end}
{p2col :{bf:seasonal}}guess = 0.01 * sd(y), nu = 0.01, upper = sd(y){p_end}
{p2col :{bf:observation, dynamic branch}}guess = {cmd:priorlevelsd()} * sd(y),
nu = 32, upper = 0.1 * sd(y){p_end}
{p2col :{bf:observation, no covariates}}guess = sd(y), nu = 0.01,
upper = 1.2 * sd(y){p_end}
{p2colreset}{...}

{pstd}
The constant 32 is {cmd:kLocalLevelPriorSampleSize} and
{cmd:kDynamicRegressionPriorSampleSize} in the R source, and it is the nu = 32
the paper reports for its own analyses in Sec. 3 and Sec. 4.

{pstd}
In the static-regression branch the observation variance is {it:not} drawn
separately: it is part of the conjugate normal-inverse-Gamma block below, exactly
as in {cmd:BoomSpikeSlab}.

{dlgtab:Spike and slab}

{pstd}
Let gamma_j = 1 when beta_j is non-zero. The prior factors as

{p 8 8 2}
    p(gamma, beta, 1/sigma{c 94}2_eps) = p(gamma) p(sigma{c 94}2_eps | gamma) p(beta | gamma, sigma{c 94}2_eps)   (2.8)

{pstd}
The spike is a product of independent Bernoullis,

{p 8 8 2}
    p(gamma) = prod_j pi_j{c 94}gamma_j (1 - pi_j){c 94}(1 - gamma_j)          (2.9)

{pstd}
with pi_j = min(1, M/J) and M = {cmd:modelsize()}. Framing the prior through
expected model size, rather than through individual pi_j, is what lets the model
absorb growing numbers of candidate controls without a hierarchical prior.

{pstd}
The slab is conjugate normal-inverse-Gamma,

{p 8 8 2}
    beta_gamma | sigma{c 94}2_eps ~ N(b_gamma, sigma{c 94}2_eps (Omega{c 94}-1_gamma){c 94}-1)   (2.10){break}
    1/sigma{c 94}2_eps ~ G(nu_eps/2, s_eps/2)                                  (2.11)

{pstd}
with b = 0, s_eps = nu_eps (1 - R{c 94}2) s{c 94}2_y from {cmd:priordf()} and
{cmd:r2()}, and the g-prior of eq. (2.12) averaged with its own diagonal to
guarantee propriety when X'X is singular,

{p 8 8 2}
    Omega{c 94}-1 = (g/n) {c -(} w X'X + (1 - w) diag(X'X) {c )-}              (2.12)

{pstd}
Here g = {cmd:ginfo()} and 1 - w = {cmd:dshrinkage()}. Averaging with the
diagonal is what makes the prior usable with more controls than observations.


{marker inference}{...}
{title:Posterior simulation}

{pstd}
Inference is a Gibbs sampler alternating a data-augmentation step and a
parameter step, as in Sec. 2.3 of the paper. One iteration is:

{dlgtab:Step A. Draw the state given the parameters}

{pstd}
This uses the simulation smoother of Durbin and Koopman (2002). The textbook
recipe is: draw (alpha+, y+) from the unconditional model, smooth the observed y
to get alphahat, smooth y+ to get alphahat+, and set

{p 8 8 2}
    alphatilde = alphahat - alphahat+ + alpha+

{pstd}
which requires {bf:two} filter-and-smoother passes. The command uses a single
pass, and the equivalence is worth spelling out because it is the only place
where the implementation departs from the literal algorithm.

{pstd}
The smoother is affine in the data and in the initial state mean: for a fixed
model, alphahat(y; a1) = A y + B a1 for matrices A and B that do not depend on
y. Hence

{p 8 8 2}
    alphahat(y; a1) - alphahat(y+; a1) = A (y - y+) = alphahat(y - y+; a1 = 0)

{pstd}
So the command draws (alpha+, y+) using the true initial mean a1, forms
y* = y - y+, runs {bf:one} filter and smoother on y* with a {bf:zero} initial
mean, and adds alpha+ back. The result is algebraically identical to the two-pass
version and costs half as much. Where y is missing, y* is missing too, so the
filter skips those updates and the post-period state is drawn from the model
rather than from the data.

{pstd}
The filter is the standard univariate-observation recursion. For each t it
computes the prediction error v_t = y_t - Z_t' a_t, its variance
F_t = Z_t' P_t Z_t + sigma{c 94}2_eps, the gain K_t = T_t P_t Z_t / F_t, and
propagates a and P. Only v, F and K are stored, because the fast state smoother
needs nothing else: backwards it forms
r_t-1 = Z_t v_t/F_t + (T_t - K_t Z_t')' r_t, and forwards
alphahat_1 = a_1 + P_1 r_0 and alphahat_t+1 = T_t alphahat_t + R Q R' r_t. This
is linear in m and quadratic in d, matching the complexity the paper states.

{dlgtab:Step B. Draw the variance parameters}

{pstd}
Given the sampled state the innovations are known: eta_mu,t = mu_t+1 - mu_t for
the level, eta_gamma,t = gamma_t+1 + sum of the current seasonal states at each
season boundary, and eta_beta,j,t = beta_j,t+1 - beta_j,t for dynamic
coefficients. Each variance is then drawn from its conjugate truncated
inverse-Gamma as described above.

{dlgtab:Step C. Draw gamma, beta and sigma_eps given the state}

{pstd}
Let ydot_t be y_t with the contributions of the other state components removed.
Conjugacy allows beta and 1/sigma{c 94}2_eps to be integrated out, leaving the
marginal of eq. (2.13) with sufficient statistics

{p 8 8 2}
    V{c 94}-1 = X'X + Omega{c 94}-1{break}
    betatilde = V (X'ydot + Omega{c 94}-1 b){break}
    N = nu_eps + n{break}
    S = s_eps + ydot'ydot + b' Omega{c 94}-1 b - betatilde' V{c 94}-1 betatilde

{pstd}
so that, up to a constant that does not depend on gamma,

{p 8 8 2}
    log p(gamma | ydot) = log p(gamma) + (1/2) log|Omega{c 94}-1_gamma| - (1/2) log|V{c 94}-1_gamma| - (N/2) log S_gamma

{pstd}
The command sweeps over the inclusion indicators in random order, evaluating this
quantity with gamma_j set to 0 and to 1 while the others are held fixed, and
draws gamma_j from the resulting Bernoulli. The odds are formed on the log scale
so that no exponential overflows. All determinants come from a Cholesky
factorisation of the |gamma| x |gamma| submatrix, which is small whenever the
model is genuinely sparse; a configuration whose submatrix is not positive
definite, or that would include at least as many covariates as observations, is
assigned zero posterior mass. {cmd:maxflips()} restricts the sweep to a random
subset of indicators.

{pstd}
Once gamma is drawn, sigma{c 94}2_eps comes from G(N/2, S_gamma/2) and beta_gamma
from N(betatilde_gamma, sigma{c 94}2_eps V_gamma) via a Cholesky factor; the
excluded coefficients are set to exactly zero, which is what makes the reported
posterior means model-averaged.

{dlgtab:Step D. Store}

{pstd}
After burn-in the command stores, for every time point, the total state
contribution (level + seasonal + regression) and a draw of the response,

{p 8 8 2}
    y-draw_t = state_t + N(0, sigma{c 94}2_eps)

{pstd}
The point counterfactual is the mean of the {it:state} draws, which is noise-free
because the observation error is centred; the credible band comes from quantiles
of the {it:response} draws, which include observation noise. That asymmetry is
deliberate and matches {cmd:impact_inference.R:90-97}.

{pstd}
Quantiles use R's default type-7 definition, h = (n-1)p + 1 with linear
interpolation between order statistics, so that interval endpoints match R's
given the same draws.


{marker impact}{...}
{title:Evaluating impact}

{pstd}
For each draw tau and each post-period t,

{p 8 8 2}
    phi_t{c 94}(tau) = y_t - ytilde_t{c 94}(tau)                                (2.15)

{pstd}
gives the pointwise causal effect; the cumulative effect is

{p 8 8 2}
    sum_{c -(}t' = n+1{c )-}{c 94}t phi_t'{c 94}(tau)                            (2.16)

{pstd}
and the running average, which stays interpretable for stock quantities, is

{p 8 8 2}
    (1/(t-n)) sum_{c -(}t' = n+1{c )-}{c 94}t phi_t'{c 94}(tau)                  (2.17)

{pstd}
All three are available through {cmd:generate()}.

{pstd}
One implementation detail matters for reading the cumulative panel. Before the
post-period, the cumulative counterfactual is {it:pinned} to the observed
cumulative response rather than being computed from the model. Consequently the
cumulative effect is exactly zero throughout the pre-period, and the cumulative
credible band does not inherit pre-period prediction variance that would
otherwise make the post-period band misleadingly wide. This reproduces
{cmd:impact_inference.R:125-135}, where the reasoning is spelled out in a comment.

{pstd}
The summary table is computed over the post-period only. The relative effect is
the posterior of sum(y)/sum(counterfactual) - 1, and the Average and Cumulative
rows are forced to be identical, matching {cmd:impact_inference.R:238}. The
tail-area probability is

{p 8 8 2}
    p = min( #{c -(}draws >= observed{c )-}, #{c -(}draws <= observed{c )-} ) / (ndraws + 1)

{pstd}
with the observed sum itself included in both counts, matching
{cmd:impact_inference.R:278}.


{marker map}{...}
{title:Step to equation map}

{pstd}
Each block of {cmd:causalimpact.ado} is labelled with the step numbers below, so
the code can be read against this table.

{p2colset 5 14 16 2}{...}
{p2col :{bf:S1}}input and period checks; the pre-period is moved forward to the
first non-missing response. Sec. 1; {cmd:FormatInputForCausalImpact()}{p_end}
{p2col :{bf:S2}}standardisation of every column using {it:pre-period} moments.
{cmd:impact_misc.R Standardize()}{p_end}
{p2col :{bf:S3}}post-period response set to missing. Sec. 2.3;
{cmd:impact_analysis.R:411}{p_end}
{p2col :{bf:S4}}assembly of T, Z and R Q R'. eq. (2.1)-(2.2){p_end}
{p2col :{bf:S5}}local level block. eq. (2.3) with delta_t = 0{p_end}
{p2col :{bf:S6}}seasonal block, including the duration switch. eq. (2.5){p_end}
{p2col :{bf:S7}}static regression. Sec. 2.1{p_end}
{p2col :{bf:S8}}dynamic regression. eq. (2.6){p_end}
{p2col :{bf:S9}}variance priors and their truncated draws. eq. (2.7){p_end}
{p2col :{bf:S10}}spike prior. eq. (2.8)-(2.9){p_end}
{p2col :{bf:S11}}slab and g-prior. eq. (2.10)-(2.12){p_end}
{p2col :{bf:S12}}Durbin-Koopman simulation smoother. Sec. 2.3{p_end}
{p2col :{bf:S13}}stochastic search over gamma; conjugate draws of sigma and beta.
eq. (2.13){p_end}
{p2col :{bf:S14}}posterior predictive counterfactual. eq. (2.14){p_end}
{p2col :{bf:S15}}pointwise effect. eq. (2.15){p_end}
{p2col :{bf:S16}}cumulative effect. eq. (2.16){p_end}
{p2col :{bf:S17}}running-average effect. eq. (2.17){p_end}
{p2col :{bf:S18}}summary table and tail-area p. {cmd:CompileSummaryTable()}{p_end}
{p2col :{bf:S19}}verbal report. {cmd:InterpretSummaryTable()}{p_end}
{p2col :{bf:S20}}three-panel figure. Fig. 1 and Fig. 5-7; {cmd:impact_plot.R}{p_end}
{p2colreset}{...}


{marker deviations}{...}
{title:Documented deviations}

{pstd}
Four points where the paper, the R package, and this implementation do not
trivially coincide. Each is a deliberate choice, stated here rather than buried.

{phang}
{bf:1. The Zellner g default.} Sec. 2.2 of the paper states default values
g = 1 and w = 1/2 for eq. (2.12). The R package does not pass
{cmd:prior.information.weight} to {cmd:SpikeSlabPrior()}, so it inherits that
function's default of 0.01, not 1. Since the stated goal is compatibility with
the R package, {cmd:ginfo()} defaults to {bf:0.01}. Set {cmd:ginfo(1)} to follow
the printed paper instead. The diagonal weight w = 1/2 is the default in both,
i.e. {cmd:dshrinkage(0.5)}.

{phang}
{bf:2. The exponent in eq. (2.13).} The typeset marginal in the paper carries the
exponent (N/2) - 1 on S. The conjugate normal-inverse-Gamma marginal, for the
prior actually stated in eq. (2.11), has exponent -N/2, which is also what
{cmd:BoomSpikeSlab} computes. The command uses -N/2. The two differ by a constant
in gamma only through S_gamma, so the choice does shift the inclusion odds
slightly; the standard conjugate form was preferred because it is the one the
reference implementation uses.

{phang}
{bf:3. The observation-variance prior with no covariates.} With a regression
present the residual variance comes from the spike-and-slab block, exactly as in
R. With no covariates at all, the R package relies on the {cmd:bsts()} internal
default, which the published source does not make explicit. This command uses
guess = sd(y), nu = 0.01, upper = 1.2 sd(y), which is extremely diffuse and
therefore has essentially no influence once the data have been standardised. Use
{cmd:sigmaupper()} to change the truncation.

{phang}
{bf:4. The dynamic-regression innovation prior.} {cmd:Boom}'s
{cmd:DynamicRegressionRandomWalkOptions()} places a hierarchical Gamma prior on
the innovation precisions, shared across coefficients. This command implements
the model the {it:paper} writes in eq. (2.6): an independent inverse-Gamma per
sigma{c 94}2_beta_j, with prior guess 0.01 sd(y)/sd(x_j) matching Boom's prior
mean, nu = 32, and truncation at sd(y)/sd(x_j). The dynamic branch is therefore
{bf:paper-faithful and R-approximate}; the static branch, which is what the
paper's own empirical analyses use, is faithful to both.

{pstd}
Two further notes, not deviations but easy to misread. First, the reported
coefficients are in the metric the model is fitted in, that is standardised
unless {cmd:nostandardize} was used, because the R package likewise never
converts them back and because the intercept is confounded with the local level.
Second, like the R package this command models the data in row order and ignores
gaps in the time variable ({cmd:impact_analysis.R:390-391}); a note is printed
when gaps are detected.


{marker validation}{...}
{title:Validation}

{pstd}
{cmd:causalimpact_example.do} is a self-checking harness. Every example has a
known truth, and the last section runs the paper's own Monte Carlo design so that
the output can be refereed rather than merely inspected:

{phang2}
{bf:Recovery.} On the R vignette design (a lift of exactly 10 units over 30
periods) the estimated cumulative effect should be near 300 and the relative
effect near +11%.

{phang2}
{bf:Variable selection.} With two informative and eight noise controls, the
posterior inclusion probabilities of the noise controls should be low.

{phang2}
{bf:The paper's Sec. 3 design.} Two sinusoidal covariates with random-walk
coefficients, a random-walk level, and a 10% lift; the estimated relative effect
should be near +10%.

{phang2}
{bf:Specificity.} A placebo run with no intervention should return p above 0.05
and a credible interval covering zero, the analogue of the paper's Analysis 3.

{phang2}
{bf:Coverage and power.} Across replications, the 95% interval should contain the
true cumulative effect about 95% of the time regardless of the lift, which is
Fig. 3(c); and the rejection rate should rise with the true lift, which is
Fig. 3(b). The harness varies {cmd:seed()} on every replication, without which
the internal random-number stream resets and the rejection rate is degenerate.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
https://github.com/merwanroudane


{title:Also see}

{psee}
Help:  {helpb causalimpact},
{helpb causalimpact_interpretation:causalimpact interpretation},
{helpb causalimpact_rcheck:causalimpact rcheck},
{helpb causalimpact_postestimation:causalimpact postestimation}
{p_end}
