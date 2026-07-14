{smcl}
{* *! version 1.0.0  12jul2026}{...}
{vieweralsosee "xtmixedroot" "help xtmixedroot"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[XT] xtunitroot" "help xtunitroot"}{...}
{viewerjumpto "The model" "xtmixedroot_methods##model"}{...}
{viewerjumpto "Why the cross-sectional variance identifies theta" "xtmixedroot_methods##idea"}{...}
{viewerjumpto "Estimator A" "xtmixedroot_methods##esta"}{...}
{viewerjumpto "Estimator B" "xtmixedroot_methods##estb"}{...}
{viewerjumpto "Estimator C" "xtmixedroot_methods##estc"}{...}
{viewerjumpto "Westerlund fixed-T statistics" "xtmixedroot_methods##west"}{...}
{viewerjumpto "Local power and identification" "xtmixedroot_methods##power"}{...}
{viewerjumpto "Step-by-equation map" "xtmixedroot_methods##map"}{...}
{viewerjumpto "Reconciliations with the printed papers" "xtmixedroot_methods##recon"}{...}
{viewerjumpto "Validation" "xtmixedroot_methods##valid"}{...}
{viewerjumpto "References" "xtmixedroot_methods##references"}{...}

{title:Title}

{p2colset 5 29 31 2}{...}
{p2col :{bf:xtmixedroot methods} {hline 2}}Formulas, assumptions and the
code-to-paper map for {helpb xtmixedroot}{p_end}
{p2colreset}{...}


{marker model}{...}
{title:The model}

{pstd}
For units i = 1,...,N and periods t = 1,...,T,

{p 8 8 2}y_it = lambda_i + u_it,{space 8}u_it = alpha_i u_it-1 + e_it,

{pstd}
where alpha_i is in [0,1], e_it is iid over i and t, and lambda_i is a
unit-specific intercept independent of alpha_i and e_it (Ng's A1-A3).
A fraction theta = N1/N of the units has alpha_i = 1 ("I(1) units"); the
rest have alpha_i < 1 ("I(0) units"). The object of interest is theta,
with null hypotheses H0: theta = theta_0 for theta_0 in (0,1].
Extensions: unit-specific AR(p) dynamics and heteroskedastic errors
(Estimator A), a common stationary factor y_it = lambda_i F_t + u_it with
beta(L)F_t = v_t (Estimator B, Ng's A4-A5), and incidental trends
y_it = lambda_i t + u_it (Estimator C).


{marker idea}{...}
{title:Why the cross-sectional variance identifies theta (Ng, Lemma 1)}

{pstd}
Let V_t = (1/N) sum_i (y_it - ybar_t)^2 be the cross-sectional variance.
For an I(0) unit the variance of y_it settles at a constant; for an I(1)
unit it grows like t. Decomposing the mixture variance into within- and
between-group parts, Ng shows that for t beyond a short transient

{p 8 8 2}V_t ~ constant + theta * t,{space 5}so{space 5}Delta V_t -> theta.

{pstd}
The between-group term (Ybar1_t - Ybar0_t)^2 is a squared random walk whose
drift and variance vanish at rates 1/N1 and t/N1^2, which is why V_t is
first-differenced (a levels regression of V_t on t would be spurious for
fixed N). Time-averaging Delta V_t gives Ng's Theorem 1:

{p 8 8 2}sqrt(N) (theta-hat - theta) -> N(0, 2*theta),{space 4}as N -> inf, then T -> inf.

{pstd}
The rate is sqrt(N), not sqrt(NT), because var(Delta V_t) grows linearly in
t, so averaging over time does not accelerate convergence.


{marker esta}{...}
{title:Estimator A (heterogeneous dynamics, heteroskedastic errors)}

{pstd}For each unit i:{p_end}

{phang2}1. OLS on y_it = a_0 + a_1 y_it-1 + ... + a_p y_it-p + e_it (Ng eq.
(8)). p is fixed by {opt lags(#)} or selected unit-by-unit by the BIC over
1..maxlags on a common estimation sample, then the chosen model is refit on
the unit's full sample.{p_end}

{phang2}2. sigma_i^2-hat = (1/T) x the sum of squared residuals (Ng step 2 verbatim).{p_end}

{phang2}3. phi_i1-hat,...,phi_ip-hat = the inverse roots of the estimated AR
polynomial, computed as the eigenvalues of its companion matrix and ordered
by modulus (phi_i1 is the dominant root).{p_end}

{phang2}4. D_i-hat = product over k = 2..p of (phi_i1 - phi_ik). This is the
partial-fractions denominator attached to the dominant root: for a series
with phi_i1 = 1, var(y_it) = (sigma_i^2/D_i^2) t + lower-order terms, so the
rescaled series D_i y_it / sigma_i has variance slope 1 and the
cross-sectional variance of the rescaled panel has slope theta.
{cmd:xtmixedroot} uses |D_i| (only D_i^2 matters) and floors it at 1e-6
against near-repeated roots. For p = 1, D_i = 1.{p_end}

{phang2}5. V-hat_t = cross-sectional variance of the rescaled panel;
theta-hat = mean of Delta V-hat_t over the T-1 available increments;
eta-hat_t = Delta V-hat_t - theta-hat. The variance of theta-hat is
estimated by the Bartlett/Newey-West long-run variance of eta-hat_t with
truncation M ({opt hac(#)}), divided by the number of increments:{p_end}

{p 12 12 2}se(theta-hat)^2 = [gamma(0) + 2 sum_{s=1..M} (1 - s/(M+1)) gamma(s)] / (T-1).

{pstd}
The studentized statistic t = (theta-hat - theta_0)/se is treated as N(0,1).
Ng does not state Estimator A as a theorem (nuisance parameters are
estimated) but verifies by simulation that the normal approximation is
accurate; {cmd:xtmixedroot}'s shipped validation reproduces her Table 1.


{marker estb}{...}
{title:Estimator B (cross-sectional correlation)}

{pstd}
Identical to A except that step 1 augments the regression with proxies for
the common stationary factor (Ng eq. (12)):

{p 8 8 2}y_it = a_0 + a_1 y_it-1 + ... + a_p y_it-p + l_0 F-hat_t + ... + l_q F-hat_t-q + e_it,

{pstd}
where F-hat_t is the cross-sectional average of the differenced data
(Pesaran-type proxy; default, with q = {opt factors(#)} lags) or the first
principal component of the differenced panel ({opt pc}). Under a stationary
factor, Delta F_t^2 acts as a stationary error component in Delta V_t, so
theta-hat remains consistent even {it:without} the augmentation - but
augmenting sharpens the estimates of the dynamic parameters and removes the
finite-sample downward bias Ng documents in her Table 3.


{marker estc}{...}
{title:Estimator C (incidental trends)}

{pstd}
With y_it = lambda_i t + u_it the cross-sectional variance acquires a
quadratic term var(lambda_i) t^2. Step 1 adds a linear trend to the AR
regression; step 4 rescales by 1/sigma_i-hat (exactly as printed in Ng's
Estimator C; see the reconciliation notes below); and theta is estimated as
the intercept of the OLS regression (Ng eq. (13))

{p 8 8 2}Delta V-hat_t = theta + beta [t^2 - (t-1)^2] + eta_t,

{pstd}
with Newey-West HAC standard errors for both coefficients.
beta-hat estimates var(lambda_i) (returned in {cmd:r(varlambda)}).
Ng's Theorem 2 gives sqrt(N/T) (theta-hat - theta) -> N(0,
32 theta var(lambda_i)/15): the rate deteriorates from sqrt(N) to
sqrt(N/T), so consistency requires T/N -> 0 and very large panels
(her Table 4 uses T = 300-600, N = 200-400).


{marker west}{...}
{title:Westerlund (2016) fixed-T statistics}

{pstd}
Westerlund replaces Ng's sequential asymptotics with a finite-sample
expansion valid for any T >= 2 and derives the exact fixed-T bias and
variance. With theta-hat_w = (1/T) sum_{t=2..T} Delta V_t computed on the
{it:raw} data (V_T - V_1, telescoped):

{p 8 8 2}theta* = theta-hat_w / sigma_eps^2-hat,{space 6}theta*_BA = theta* + theta_0/T,

{pstd}
since E(theta* - theta_0) = -theta_0/T exactly under the null. The
statistics, all asymptotically N(0,1) as N -> inf:

{p2colset 6 20 22 2}{...}
{p2col:tau*_1,T}= sqrt(N)(theta*_BA - 1)/sigma-hat_theta,T with
sigma-hat_theta,T^2 = 2(T^2-1)/T^2 + (T-1)/T^2 (kappa-hat - 3). Valid for
any T >= 2 under homogeneous intercepts (sigma_lambda^2 = 0); a common time
effect is handled by {opt demean}. Left-tailed test of theta = 1.{p_end}
{p2col:tau*_1,NT}= same numerator with sigma-hat_theta,NT^2 =
2(T^2-1)/T^2 + (T-1)/T^2 [4 sigma-hat_lambda^2/sigma-hat_eps^2 +
kappa-hat - 3], where sigma-hat_lambda^2 is the cross-sectional variance of
the intercepts from unit-wise regressions of y_it on (1, y_it-1). Requires
larger T for sigma-hat_lambda^2 to be consistent.{p_end}
{p2col:tau*_1}= sqrt(N)(theta*_BA - 1)/sqrt(2), the large-(N,T) form.{p_end}
{p2col:tau*_theta0}= sqrt(N)(theta*_BA - theta_0)/sqrt(2 theta*) for
theta_0 in (0,1) (Westerlund Theorem 2), two-sided; requires N,T -> inf
jointly with sqrt(N)/T -> 0. The sigma_theta,NT-variance variant is also
reported. Under theta_0 < 1, sigma_eps^2 and kappa are estimated from the
unit-wise AR(1) {it:residuals} rather than from Delta y (Delta y is a valid
proxy for e only under theta = 1).{p_end}
{p2colreset}{...}

{pstd}
Moment estimators: sigma-hat_eps^2 and kappa-hat are the pooled second and
fourth moments of Delta y_it (t = 2..T), normalized by the number of
increments N(T-1); see the reconciliation notes.


{marker power}{...}
{title:Local power and identification (what a rejection means)}

{pstd}
Westerlund models the stationary units as alpha_i = exp(c_i/N^eta), c_i <= 0.
Key results: (i) under fixed alternatives (eta = 0) power goes to 1 as
N -> inf and theta is estimable; (ii) under local alternatives (eta > 0)
theta-hat converges to 1 {it:regardless of theta} - the fraction is not
identified, and only H0: theta = 1 is testable; (iii) with T fixed the
test has nontrivial local power exactly at eta = 1/2; with T = N^gamma
growing, at eta = gamma + 1/2, so a larger T buys power against closer
alternatives. Practical reading: in a short panel, failing to reject
theta = 1 - or estimating theta-hat near 1 - may only mean the stationary
units are very persistent, and having a large T is necessary but not
sufficient to pin down theta (the deviation from the null must also not be
too small).


{marker map}{...}
{title:Step-by-equation map (code block -> paper)}

{p2colset 6 44 46 2}{...}
{p2col:{bf:code step}}{bf:source}{p_end}
{p2col:{hline 36}}{hline 30}{p_end}
{p2col:V_t = (1/N) sum (y_it - ybar_t)^2}Ng Sec. 2 (definition of V_t,N); Westerlund Sec. 3.1 (V_t){p_end}
{p2col:theta-hat_w = (V_T - V_1)/T}Westerlund's feasible estimator, sum over t = 2..T{p_end}
{p2col:per-unit OLS AR(p), BIC lags}Ng Estimator A step 1, eq. (8); BIC per Ng Sec. 4 and applications{p_end}
{p2col:sigma_i^2-hat = mean sq. residual}Ng Estimator A step 2{p_end}
{p2col:phi-hat = companion eigenvalues}Ng Estimator A step 3 ("reciprocal of the roots of alpha_i(L) = 0"){p_end}
{p2col:D_i = prod_k>=2 (phi_i1 - phi_ik)}Ng p. 117, the D_i = A^-1 B construction (see reconciliations){p_end}
{p2col:rescale D_i y/sigma_i; V-hat_t}Ng Estimator A step 4{p_end}
{p2col:theta-hat = mean Delta V-hat_t; HAC se}Ng Estimator A step 5, Bartlett kernel K(s,M) = 1 - s/(M+1){p_end}
{p2col:factor proxy dybar_t, lags 0..q}Ng Estimator B step 1, eq. (12); Pesaran cross-sectional average{p_end}
{p2col:first-PC proxy ({opt pc})}Ng Sec. 3.2 ("first principal component of Delta y_it"){p_end}
{p2col:trend in AR; Delta V on (1, 2t-1)}Ng Estimator C steps 1 and 5, eq. (13){p_end}
{p2col:t tests at theta_0, .01, 1}Ng Sec. 4, hypotheses A, B, C{p_end}
{p2col:classification by |phi_i1| rank}Ng Sec. 4 (informal proposal; ~60 percent correct rate){p_end}
{p2col:s2_eps, kappa from Delta y}Westerlund Sec. 3.1.1{p_end}
{p2col:theta*_BA = theta* + theta_0/T}Westerlund Remark 4 / Theorem 1{p_end}
{p2col:sigma_theta,T^2; tau*_1,T}Westerlund Sec. 3.1.1{p_end}
{p2col:sigma_theta,NT^2; tau*_1,NT; tau*_1}Westerlund Sec. 3.1.2{p_end}
{p2col:residual-based s2_eps under theta_0<1}Westerlund Sec. 3.2{p_end}
{p2col:tau*_theta0, two-sided}Westerlund Theorem 2 and following display{p_end}
{p2col:{opt demean} option}Westerlund Remark 1 and footnote 3{p_end}
{p2colreset}{...}


{marker recon}{...}
{title:Reconciliations with the printed papers}

{pstd}
Three places where the printed text is internally inconsistent were resolved
in favor of the papers' own defining constructions and simulation tables;
each choice is verified by the shipped Monte Carlo validation.

{phang2}1. {bf:sigma_eps^2-hat denominator (Westerlund).} The text prints
sigma-hat_eps^2 = sum_i sum_{t=2..T} (Delta y_it)^2 / NT, but the sum has
N(T-1) terms and the /NT normalization would shift the mean of tau*_1,T by
sqrt(N)/T (e.g. +8.9 at T = 2, N = 320), contradicting the near-zero means
in his Table 1. {cmd:xtmixedroot} divides by N(T-1), which makes
E(theta*_BA) = 1 exact under the null; the shipped validation reproduces his
Table 1 size (empirical 3.0 percent vs his 3.5 at T = 4, N = 160).{p_end}

{phang2}2. {bf:D_i table (Ng, p. 117).} The rows for p = 3 and p = 4 of the
convenience table contain typographical errors (a sign on the phi_2 phi_3
term at p = 3; a dropped product in the last term at p = 4). Solving Ng's
own defining system D_i = A^-1 B gives the dominant-root partial-fractions
weight A_i1/D_i = phi_i1^(p-1) / prod_{k>=2}(phi_i1 - phi_ik), which matches
the printed table exactly at p = 1, 2 and matches A^-1 B numerically for
all p. {cmd:xtmixedroot} therefore uses D_i = prod_{k>=2}(phi_i1 -
phi_ik).{p_end}

{phang2}3. {bf:Estimator C rescaling (Ng, p. 123).} Step 4 of Estimator C
rescales by 1/sigma_i only (no D_i), although step 3 still computes D_i-hat.
{cmd:xtmixedroot} follows the printed step 4 verbatim.{p_end}

{pstd}
Two further implementation notes. (i) Ng's step 5 prints the studentized
statistic as (theta-hat - theta)/omega with omega^2 the long-run variance of
eta_t; the variance of a sample mean is that long-run variance divided by
the number of increments, and only this normalization yields a t statistic
with unit variance - confirmed by the validation, which reproduces
N var(theta-hat)/theta = 3.2 against Ng's Table 1 value 2.996. (ii) V_0 is
unobservable, so the time average runs over the T-1 observable increments
(Westerlund's feasible convention); for the Ng block the average divides by
T-1, which is the exact sample mean of the increments.


{marker valid}{...}
{title:Validation}

{pstd}
The ancillary file {cmd:xtmixedroot_example.do} regenerates the papers' own
Monte Carlo designs and checks every code path. Headline results (seeds
fixed in the file):

{p2colset 6 52 54 2}{...}
{p2col:{bf:quantity (design)}}{bf:xtmixedroot vs paper}{p_end}
{p2col:{hline 44}}{hline 22}{p_end}
{p2col:mean theta-hat, Ng Model 1a (N=30, T=100, theta=.5)}.515 vs .517{p_end}
{p2col:N var(theta-hat)/theta, same design}3.22 vs 2.996{p_end}
{p2col:5 percent two-sided rejection of the true null}.125 vs .114{p_end}
{p2col:size of tau*_1,T (theta=1, T=4, N=160)}.030 vs .035{p_end}
{p2col:est. A vs B means under a common factor (N=60, T=100)}.421/.452 vs .459/.481{p_end}
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}Ng, S. 2008. A simple test for nonstationarity in mixed panels.
{it:Journal of Business & Economic Statistics} 26(1): 113-127.
{browse "https://doi.org/10.1198/073500106000000675"}{p_end}

{phang}Westerlund, J. 2016. A simple test for nonstationarity in mixed
panels: A further investigation. {it:Journal of Statistical Planning and
Inference} 173: 1-30.
{browse "https://doi.org/10.1016/j.jspi.2016.01.004"}{p_end}


{title:Author}

{pstd}
Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
GitHub: {browse "https://github.com/merwanroudane"}{p_end}
