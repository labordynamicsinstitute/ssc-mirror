{smcl}
{* 23jul2026}{...}
{vieweralsosee "covstat" "help covstat"}{...}
{vieweralsosee "flexur (library)" "help flexur"}{...}
{viewerjumpto "Model" "covstat_methods##model"}{...}
{viewerjumpto "RALS covariates" "covstat_methods##rals"}{...}
{viewerjumpto "Jansson statistics" "covstat_methods##jansson"}{...}
{viewerjumpto "Long-run covariance" "covstat_methods##lrv"}{...}
{viewerjumpto "p-values" "covstat_methods##pval"}{...}
{viewerjumpto "Step-to-code map" "covstat_methods##map"}{...}
{title:Title}

{phang}
{bf:covstat methods} {hline 2} Methods and formulas for {helpb covstat}

{marker model}{...}
{title:Model and hypothesis}

{pstd}
The data-generating process is {it:y{sub:t} = X{sub:t}'b + r{sub:t} + e{sub:t}},
{it:r{sub:t} = r{sub:t-1} + u{sub:t}}, with X{sub:t}=1 (level) or X{sub:t}=[1,t]
(trend). Under H0 the variance of u{sub:t} is zero, so {it:y{sub:t}} is stationary;
the alternative is a unit root. Tests reject for large values.

{marker rals}{...}
{title:RALS covariates (eq. 3)}

{pstd}
Let {it:e{sub:t}} be the OLS residuals of y on X, m{sub:k} the k-th sample moment
of e. The RALS terms are

{p 12 12 2}{it:w{sub:t} = [ e{sub:t}{sup:2} - m{sub:2} ,  e{sub:t}{sup:3} - m{sub:3} - 3 m{sub:2} e{sub:t} ]'}.{p_end}

{pstd}
They follow the updated error {it:phi{sub:kt} = e{sub:t}{sup:k} - m{sub:k} -
k m{sub:k-1} e{sub:t}} and satisfy the two conditions for valid stationary
covariates (Hansen 1995): E(phi e) {c 141} 0 but E(phi X) = 0. Under normality the
second term is redundant (m{sub:4}=3 sigma{sup:4}), so no power is lost.

{marker jansson}{...}
{title:Jansson statistics}

{pstd}
Write V-hat for the residuals of (y, w) on their deterministic terms, and let
OMEGA be the long-run covariance of V-hat, partitioned into y and x blocks with
OMEGA{sub:yy.x} the conditional variance. With a GLS-detrending parameter
lambda-bar (7 for the constant, 12 for the trend model):

{p 8 10 2}{bf:Benchmark} (no covariates): Ly_T = S'S / OMEGA{sub:yy} where
S = cumsum(V-hat{sub:y})/T; Qy_T is the point-optimal analogue with the
lambda-bar GLS transform.{p_end}
{p 8 10 2}{bf:Jansson-RALS}: L_T and Q_T replace the univariate objects by their
covariate-conditional counterparts, built from the block moment matrices
S{sub:DD}, S{sub:Dz}, S{sub:zz} (with Kronecker structure across the covariates)
and the GLS-transformed data. Q_T = P_T - 2 lambda-bar GAMMA{sub:yy.x}/OMEGA{sub:yy.x}.{p_end}

{pstd}
The signal-to-noise ratio is {it:rho^2 = 1 - OMEGA{sub:yy.x}/OMEGA{sub:yy}}.

{marker lrv}{...}
{title:Long-run covariance}

{pstd}
By default OMEGA and GAMMA are estimated by the VAR(1)-{it:prewhitened}
quadratic-spectral kernel estimator with the Jansson (2004, p.74) plug-in
bandwidth: a VAR(1) is fitted to V-hat, its eigenvalues are capped at modulus 0.97
for stability, the QS kernel is applied to the prewhitened residuals, and the
result is {it:recolored}. The {opt iid} option sets OMEGA = SIGMA (contemporaneous
covariance) and GAMMA = 0.

{marker pval}{...}
{title:Critical values and p-values}

{pstd}
The distribution of L_T and Q_T depends on rho^2. The paper's response surfaces
give, for each significance level l and each (model, test), the critical value as
a fourth-order polynomial in z = rho^2/sqrt(1-rho^2^2). {cmd:covstat} ships all
999-level tables in {cmd:jrals_rs.txt} (verified against Table 1 of the paper) and,
following MacKinnon (1996), inverts them locally to return a p-value. Setting
rho^2 = 0 recovers the benchmark (KPSS/Jansson) critical values, used for Ly_T and
Qy_T.

{marker map}{...}
{title:Step-to-code map}

{synoptset 30 tabbed}{...}
{synopthdr:computation}
{synoptline}
{synopt:RALS terms w (eq. 3)}Mata {cmd:_jr_getrals}{p_end}
{synopt:Ly_T, Qy_T, L_T, Q_T, rho^2}Mata {cmd:_jr_jansson}{p_end}
{synopt:VAR(1) prewhitening + QS kernel + recolor}Mata {cmd:_jr_jansson} (prewhite branch){p_end}
{synopt:response-surface p-value}Mata {cmd:_jr_rspval} (+ {cmd:_jr_readcv}){p_end}
{synoptline}
{p2colreset}{...}

{pstd}Each block reproduces the corresponding GAUSS procedure in
{cmd:appl_JanssonRALS.gss}; the statistics and p-values match Table 9 of the paper
(Nelson-Plosser application) to the last reported digit.{p_end}

{title:Reference}

{phang}Nazlioglu, S., J. Lee, C. Karul, and Y. You. 2021. Testing for stationarity
with covariates: more powerful tests with non-normal errors. {it:Studies in
Nonlinear Dynamics & Econometrics}.{p_end}

{pstd}{helpb covstat:Back to covstat} {c |} {helpb flexur:flexur library}{p_end}
