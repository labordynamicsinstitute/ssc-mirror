{smcl}
{* *! version 1.0.0  11jul2026}{...}
{vieweralsosee "xthpool" "help xthpool"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Model" "xthpool_methods##model"}{...}
{viewerjumpto "Estimators" "xthpool_methods##est"}{...}
{viewerjumpto "Bias adjustment" "xthpool_methods##bias"}{...}
{viewerjumpto "Test statistic" "xthpool_methods##stat"}{...}
{viewerjumpto "Factors" "xthpool_methods##factors"}{...}
{viewerjumpto "Defactoring" "xthpool_methods##defactor"}{...}
{viewerjumpto "Iteration" "xthpool_methods##iter"}{...}
{viewerjumpto "Step-equation map" "xthpool_methods##map"}{...}
{viewerjumpto "Author" "xthpool_methods##author"}{...}
{title:Title}

{phang}
{bf:xthpool methods} {hline 2} Methodology and derivation of the Hausman
poolability test (Westerlund and Hess 2011)

{marker model}{...}
{title:The model and hypotheses}

{pstd}
The cointegrated panel data-generating process is (eqs 1-3 of the paper)

{p 8 8 2}{it:y_it} = {it:a_i} + {it:b_i} {it:x_it} + {it:e_it},{p_end}
{p 8 8 2}{it:x_it} = {it:x_i,t-1} + {it:v_it},{p_end}
{p 8 8 2}{it:e_it} = {it:lambda_i}' {it:f_t} + {it:u_it},{p_end}

{pstd}
where {it:x_it} is an {it:m}-vector of I(1) regressors, {it:f_t} is a vector of
{it:r} unobserved common factors with loadings {it:lambda_i}, and {it:u_it} is an
idiosyncratic I(0) error. The common factors make the units cross-sectionally
dependent. The hypotheses are

{p 8 8 2}H0: {it:b_i} = {it:b} for all {it:i}   vs   H1: {it:b_i} != {it:b} for
some {it:i}.{p_end}

{marker est}{...}
{title:Individual and pooled estimators}

{pstd}
Let {it:x°_it} = {it:x_it} - mean_t({it:x_it}) be the within (fixed-effects)
transformed regressor and {it:M_i} = sum_t {it:x°_it} {it:x°_it}'. The individual
and pooled least-squares slopes are

{p 8 8 2}{it:b_i}^ = [sum_t {it:y_it} {it:x°_it}'] {it:M_i}^-1,{p_end}
{p 8 8 2}{it:b_pool}^ = [sum_i sum_t {it:y_it} {it:x°_it}'] {it:M_pool}^-1,
   {it:M_pool} = sum_i {it:M_i}.{p_end}

{marker bias}{...}
{title:Bias adjustment}

{pstd}
Because the regressors are endogenous and the error carries common factors, the
least-squares slopes are biased. Define {it:z_it} = ({it:f_t}', {it:u_it},
{it:v_it}')' and let {it:Delta} = {it:Omega} + {it:Lambda} + {it:Lambda}' be the
Newey-West Bartlett long-run covariance of {it:z_it}, with {it:Omega} the
contemporaneous term and {it:Lambda} = sum_{j>=1} the one-sided lagged sum. Write
{it:Gamma} = {it:Omega} + {it:Lambda} = {it:Delta} - {it:Lambda}' for the
{bf:one-sided} long-run covariance. The bias corrections are

{p 8 8 2}U_fvi = {it:Delta_fv} {it:Delta_vv}^-1 (sum_t d{it:x_it} {it:x°_it}' - T
{it:Gamma_vv}) + T {it:Gamma_fv},{p_end}
{p 8 8 2}U_uvi = {it:Delta_uv} {it:Delta_vv}^-1 (sum_t d{it:x_it} {it:x°_it}' - T
{it:Gamma_vv}) + T {it:Gamma_uv},{p_end}
{p 8 8 2}U_i   = {it:lambda_i}' U_fvi + U_uvi,{p_end}

{pstd}
and the bias-adjusted slopes are {it:b_i}+ = {it:b_i}^ - U_i {it:M_i}^-1 and
{it:b_pool}+ = {it:b_pool}^ - (sum_i U_i) {it:M_pool}^-1. The one-sided
{it:Gamma} (contemporaneous {bf:plus} lagged, not the lagged sum alone) is what
makes the correction remove the drift exactly: on p.79 of the paper
{cmd:(1/T) sum_t d}{it:x_it}{cmd: }{it:x°_it}{cmd:' - }{it:Gamma_vv}{cmd: }
converges to a driftless stochastic integral.

{marker stat}{...}
{title:The Hausman statistic}

{pstd}
The individual Hausman statistic contrasts each unit's bias-adjusted slope with
the pooled one, weighted by the (realized) information and the conditional
long-run variance of the error,

{p 8 8 2}{it:Delta_e.vi} = {it:lambda_i}'({it:Delta_ff} - {it:Delta_fv}
{it:Delta_vv}^-1 {it:Delta_vf}) {it:lambda_i} + ({it:Delta_uu} - {it:Delta_uv}
{it:Delta_vv}^-1 {it:Delta_vu}),{p_end}

{p 8 8 2}H_i = ({it:b_i}+ - {it:b_pool}+) {it:M_i} ({it:b_i}+ - {it:b_pool}+)' /
{it:Delta_e.vi}.{p_end}

{pstd}
{bf:A note on the variance.} The paper writes the asymptotic variance of
{it:T(b_i+ - b)} as {it:M}^-1 (1/6 {it:Delta_e.v} {it:Delta_vv}) {it:M}^-1. The
factor {cmd:1/6 }{it:Delta_vv}{cmd: } is the probability limit of the
{bf:normalized} moment matrix {it:M_i}/{it:T}^2 (because E[integral of a demeaned
Brownian bridge squared] = 1/6), used only to state the variance in closed form.
Plugging that expression literally with the realized {it:M_i} would give a
statistic equal to chi-square times a random multiple of the realized
{cmd:6 }{it:M_i}/{it:T}^2/{it:Delta_vv}{cmd: } and would {bf:not} be pivotal.
Theorem 1 (and Remark 2, invoking the maximum domain of attraction of the Gumbel
for chi-square/Gamma variates) requires each {it:H_i} to be asymptotically
chi-square({it:m}); this is obtained by using the {bf:realized information}
{it:M_i} as above. That is the form {cmd:xthpool} computes.

{pstd}
The test statistic is the maximum and its Gumbel normalization,

{p 8 8 2}H_max = max_i H_i,   Z_max = (H_max - b_N)/a_N,{p_end}
{p 8 8 2}b_N = F^-1(1 - 1/N),   a_N = 2,{p_end}

{pstd}
where F is the chi-square({it:m}) cdf. Under H0 and Assumptions 1-5, as
{it:N,T} -> infinity with {it:sqrt(N)/T} -> 0,

{p 8 8 2}P(Z_max <= x) -> exp(-exp(-x))   (Gumbel),{p_end}

{pstd}
so the p-value is {cmd:1 - exp(-exp(-Z_max))}.

{marker factors}{...}
{title:Estimating the common factors}

{pstd}
The factors are estimated by principal components from the individual
least-squares residuals {it:e^_it} = {it:y°_it} - {it:b_i}^ {it:x°_it}. Stacking
these into the {it:T x N} matrix {it:e^}, {it:f^} is sqrt({it:T}) times the
eigenvectors of the {it:r} largest eigenvalues of {it:e^ e^}', the loadings are
{it:lambda^} = (1/{it:T}) {it:f^}' {it:e^}, and {it:u^_it} = {it:e^_it} -
{it:lambda^_i}' {it:f^_t}. The number of factors is chosen by the Bai-Ng {it:IC1}
criterion

{p 8 8 2}IC1(r) = log(V(r)) + r [({it:N}+{it:T})/({it:N}{it:T})]
log({it:N}{it:T}/({it:N}+{it:T})),   V(r) = (1/{it:NT}) sum_i sum_t
{it:u^_it}^2,{p_end}

{pstd}
minimized over {cmd:0..rmax}. Set {cmd:factors(#)} to fix {it:r}.

{marker defactor}{...}
{title:Defactoring the regressors (Corollary 1)}

{pstd}
If the regressors follow {it:x_it} = {it:Gamma_i} {it:g_t} + {it:w_it} with
{it:w_it} a random walk and {it:g_t} observable stationary common factors, the
poolability test is applied to the {bf:defactored} regressor {it:x_it}^p =
{it:x_it} - {it:Gamma^_i} {it:g_t}, where {it:Gamma^_i} is the unit-by-unit
least-squares projection of {it:x_it} on {it:g_t}. Corollary 1 shows the Gumbel
result carries over. {it:g_t} must be distinct from the error factors and
stationary.

{marker iter}{...}
{title:Iterative poolability (Section 3.2)}

{pstd}
To learn {it:which} units are poolable, the maximizing unit is removed after a
rejection and the test recomputed. Because step {it:j} is only reached after
{it:j}-1 previous rejections, the correct critical value at step {it:j} is the
upper {it:alpha^j} percentile of the Gumbel distribution; equivalently the
reported adjusted p-value is the one-step p-value raised to the power
{cmd:1/j}. {cmd:xthpool, iterate} tabulates the dropped unit, H_max, Z_max and
both p-values at every step.

{marker map}{...}
{title:Step-to-equation map}

{pstd}
Each block of {cmd:xthpool.ado} is tagged [A]-[J] against the paper:

{p 8 12 2}[A] within demeaning of {it:y_it}, {it:x_it} — eqs (1),(6){p_end}
{p 8 12 2}[B] individual and pooled LS slopes — Section 2.2{p_end}
{p 8 12 2}[C] principal-components factors {it:f^},{it:lambda^},{it:u^} — Section
2.2, p.63{p_end}
{p 8 12 2}[D] {it:IC1} factor-number selection — Proposition 1{p_end}
{p 8 12 2}[E] Newey-West Bartlett long-run covariance of {it:z_it} — Section 2.2{p_end}
{p 8 12 2}[F] one-sided bias terms and {it:b_i}+, {it:b_pool}+ — pp.60-61,
Appendix p.79{p_end}
{p 8 12 2}[G] individual Hausman statistic {it:H_i} — p.61, Lemma A.1{p_end}
{p 8 12 2}[H] {it:H_max}, {it:Z_max}, Gumbel p-value — Theorem 1, Remarks 1-3{p_end}
{p 8 12 2}[I] defactoring on observable {it:g_t} — Corollary 1, eqs (4),(5){p_end}
{p 8 12 2}[J] iterative sequential-drop scheme — Section 3.2{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
