{smcl}
{* 24jul2026}{...}
{vieweralsosee "segmcoint" "help segmcoint"}{...}
{vieweralsosee "segmcoint kim" "help segmcoint_kim"}{...}
{vieweralsosee "segmcoint dm" "help segmcoint_dm"}{...}
{vieweralsosee "segmcoint mr" "help segmcoint_mr"}{...}
{viewerjumpto "Overview" "segmcoint_methods##ov"}{...}
{viewerjumpto "Kim (2003)" "segmcoint_methods##kim"}{...}
{viewerjumpto "Davidson-Monticini (2010)" "segmcoint_methods##dm"}{...}
{viewerjumpto "Martins-Rodrigues (2021)" "segmcoint_methods##mr"}{...}
{viewerjumpto "References" "segmcoint_methods##refs"}{...}
{title:Methods and formulas}

{marker ov}{...}
{title:Overview}

{pstd}
All three procedures test H0: no cointegration over the whole sample, against the
alternative that a stable cointegrating relation holds over a subset of the sample.
Let the cointegrating regression be y_t = d_t'g + b'x_t + e_t with deterministic
kernel d_t ({cmd:none}/{cmd:const}/{cmd:trend}).  What differs is how the sample is
partitioned, how b is estimated, and which residual statistic is extremised.

{marker kim}{...}
{title:Kim (2003) {hline 1} weighted-LS infimum tests}

{pstd}
For a trial noncointegration interval N_T (complement C_T) the cointegrating vector
is estimated by weighted least squares with weight w_t = 1 on C_T and 0 on N_T
(eq 3.1-3.2); this is the only weighting that gives a consistent b under the
alternative (Note 2: the N_T "variance" is O_p(T), so its reciprocal weight
vanishes).  On the C_T residuals e_t an AR(1) e_t = rho e_{t-1} + v_t is fitted
using within-C_T consecutive pairs, and:

{p 8 8 2}Zrho(C_T) = Tc(rho^-1) - (1/2)(Tc^2 s2rho/s^2)(lam^2 - g0)  {space 6}(eq 3.3){p_end}
{p 8 8 2}Zt(C_T)   = sqrt(g0/lam^2) t_rho - (1/2)(lam^2-g0)/lam (Tc s_rho/s)  (eq 3.4){p_end}

{pstd}
where g0 is the short-run variance and lam^2 the Bartlett long-run variance of v_t.
An ADF variant (eq 3.5-3.7) regresses De_t on p lagged differences and the weighted
error-correction term w_t(rho-1)e_{t-1}.  The reported statistics are the
{it:infimum} over admissible segmentations (eq 3.13-3.15, Theorem 2), restricted to
noncointegration length <= l-bar (Lemma 1; the command's {opt trimbar()}).  Critical
values are Kim's Tables 1 (Zrho*/ADFrho*) and 2 (Zt*/ADFt*) for Case I/II/III and
n = 1..6.  The noncointegration interval is located by the extremum estimator
Lambda_T(tau) of eq (3.16)-(3.17) and, equivalently, by the inf-statistic
segmentation (eq 3.18).

{marker dm}{...}
{title:Davidson & Monticini (2010) {hline 1} subsample minima}

{pstd}
On each subsample [T*lam1, T*lam2] the data are put in (subsample) mean-deviation
form, b is re-estimated (eq 3.4), residuals z_t are formed (eq 3.2), and a
Dickey-Fuller t-statistic (eq 3.1) or its Phillips-Perron correction (eq 3.5-3.6)
is computed.  The tests take the {it:minimum} over a family of subsamples:

{p 8 8 2}QS, QS*  {space 3}split-sample halves (eq 3.9-3.10);{p_end}
{p 8 8 2}QI(lam0) {space 1}incremental forward {c 43} backward, min length lam0 (eq 3.11);{p_end}
{p 8 8 2}QR, QR*  {space 1}rolling windows of length lam0 (eq 3.12-3.13).{p_end}

{pstd}
Critical values are Table 1 (1-2 regressors, +/- trend, T = 1000).  DF and PP share
the same limiting distribution (eq 4.7-4.8, Theorem 4.1), so both use the same
critical values.  Consistency requires one tested subset to lie inside a
cointegrated subset (Theorem 4.2).

{marker mr}{...}
{title:Martins & Rodrigues (2021) {hline 1} residual sup-Wald}

{pstd}
Full-sample OLS residuals e_t (eq 2.1) enter the ADF regression

{p 8 8 2}De_t = c_j + gamma_j e_{t-1} + sum_i pi_i De_{t-i} + a_t {space 6}(eq 3.1){p_end}

{pstd}
with regime-specific (c_j, gamma_j) and common short-run dynamics pi_i.  For m
breaks the Wald-type statistic contrasts the restricted SSR0 (c_j = gamma_j = 0,
lags kept) with the unrestricted SSR over the m+1 segments,

{p 8 8 2}F_k(tau,m) = [(T-m-2*dB-p)/(m+2*dB)] (SSR0-SSR_k)/SSR_k  (m even){p_end}
{p 8 8 2}F_k(tau,m) = [(T-m-1-p)/(m+1)] (SSR0-SSR_k)/SSR_k {space 6}(m odd){p_end}

{pstd}
(eq 3.2), k = A, B and dB = 1 for k = B.  Under F_A the odd-indexed regimes are
restricted (unit root) and the even ones free (stationary); under F_B the roles are
reversed.  Because F is monotone decreasing in the segment SSR, sup F_k equals F_k
at the SSR-minimising partition, found here by Bai-Perron dynamic programming with
the segment cost alternating between the restricted (lags-only) and free
([1, e_{t-1}, lags]) fits according to the regime parity.  Then

{p 8 8 2}W(m)  = max( sup F_A, sup F_B ) {space 8}(eq 3.4){p_end}
{p 8 8 2}Wmax  = max over m = 1..m-bar of W(m) {space 1}(eq 3.5){p_end}

{pstd}
Critical values are Table 1 (K+1 = 2..6, no det / intercept / intercept+trend,
T = 1000).  Serial correlation is absorbed by the ADF lags ({opt adflags()}); the
long-run-variance nuisance correction of Remark A.1 is not applied.

{pstd}
The complete step -> equation map is also in the package file {cmd:COMPAT_MAP.md}.

{marker refs}{...}
{title:References}

{phang}Davidson, J., and A. Monticini. 2010. {it:Comput. Stat. Data Anal.} 54: 2498-2511.{p_end}
{phang}Kim, J.-Y. 2003. {it:Econometric Theory} 19: 620-639.{p_end}
{phang}Martins, L. F., and P. M. M. Rodrigues. 2021. {it:Empirical Economics} 63: 567-600.{p_end}

{pstd}
Dr Merwan Roudane {c 124} merwanroudane920@gmail.com {c 124}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
