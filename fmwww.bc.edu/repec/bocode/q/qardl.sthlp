{smcl}
{* *! version 1.1.0  14feb2026}{...}
{vieweralsosee "qreg" "help qreg"}{...}
{vieweralsosee "ardl" "help ardl"}{...}
{viewerjumpto "Syntax" "qardl##syntax"}{...}
{viewerjumpto "Description" "qardl##description"}{...}
{viewerjumpto "Options" "qardl##options"}{...}
{viewerjumpto "Remarks" "qardl##remarks"}{...}
{viewerjumpto "Examples" "qardl##examples"}{...}
{viewerjumpto "Output interpretation" "qardl##interpretation"}{...}
{viewerjumpto "Stored results" "qardl##results"}{...}
{viewerjumpto "Methods and formulas" "qardl##methods"}{...}
{viewerjumpto "Companion commands" "qardl##companion"}{...}
{viewerjumpto "References" "qardl##references"}{...}
{viewerjumpto "Author" "qardl##author"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{cmd:qardl} {hline 2}}Quantile Autoregressive Distributed-Lag (QARDL) Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:qardl}
{depvar}
{indepvars}
{ifin}{cmd:,}
{opt tau(numlist)}
[{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tau(numlist)}}quantile levels; {ul:required}; values in (0,1){p_end}
{synopt:{opt p(#)}}autoregressive lag order for {depvar}; default 0 = auto BIC{p_end}
{synopt:{opt q(#)}}distributed lag order for {indepvars}; default 0 = auto BIC{p_end}
{synopt:{opt pmax(#)}}maximum p for BIC search; default is {cmd:pmax(7)}{p_end}
{synopt:{opt qmax(#)}}maximum q for BIC search; default is {cmd:qmax(7)}{p_end}
{synopt:{opt ecm}}estimate QARDL-ECM (Error Correction Model) form{p_end}
{synopt:{opt nocons:tant}}suppress constant term{p_end}

{syntab:Rolling estimation}
{synopt:{opt rolling(#)}}rolling window size; 0 = auto (10% of sample){p_end}
{synopt:{opt window(#)}}alias for {opt rolling()}{p_end}

{syntab:Simulation}
{synopt:{opt simulate(# [#])}}Monte Carlo with {it:reps} [and {it:nobs}]{p_end}

{syntab:Testing}
{synopt:{opt waldtest(string)}}Wald test specification{p_end}

{syntab:Output}
{synopt:{opt graph}}produce quantile process graphs{p_end}
{synopt:{opt notable}}suppress coefficient tables{p_end}
{synopt:{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synoptline}

{pstd}
{it:depvar} and {it:indepvars} may contain time-series operators; see {help tsvarlist}.


{marker description}{...}
{title:Description}

{pstd}
{cmd:qardl} estimates the Quantile Autoregressive Distributed-Lag (QARDL) model
proposed by {help qardl##CKS2015:Cho, Kim & Shin (2015)}.  The QARDL model extends 
the traditional {help qardl##PS1998:Pesaran & Shin (1998)} ARDL cointegration 
framework into a quantile regression setting, enabling researchers to examine how 
the relationship between an I(1) dependent variable and I(1) regressors varies 
across different quantiles of the conditional distribution.

{pstd}
{cmd:qardl} provides the following estimation results for each specified quantile:

{p2colset 9 30 32 2}{...}
{p2col:{bf:beta(tau)}}long-run cointegrating parameters{p_end}
{p2col:{bf:phi(tau)}}short-run autoregressive (AR) parameters{p_end}
{p2col:{bf:gamma(tau)}}short-run impact (distributed lag) parameters{p_end}
{p2colreset}{...}

{pstd}
Along with their asymptotic covariance matrices and Wald tests for parameter 
constancy across quantiles.

{pstd}
The key advantage of QARDL over standard ARDL is the ability to detect 
{bf:asymmetric} and {bf:heterogeneous} long-run and short-run dynamics.
For example, the speed of adjustment or the long-run equilibrium may differ
between bull and bear markets (upper vs. lower quantiles).


{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt tau(numlist)} specifies the quantile levels at which to estimate the model.
Values must be strictly between 0 and 1. Multiple quantiles can be specified for 
across-quantile testing. At least two quantiles are needed for Wald tests of
parameter constancy. Common choices:

{p 12 16 2}
{cmd:tau(0.25 0.5 0.75)} for quartile analysis{break}
{cmd:tau(0.1 0.25 0.5 0.75 0.9)} for comprehensive coverage{break}
{cmd:tau(0.1(0.1)0.9)} for a fine grid of 9 quantiles

{phang}
{opt p(#)} specifies the autoregressive lag order for the dependent variable 
(p >= 1). If both {opt p()} and {opt q()} are left at their defaults (0), 
the BIC-based automatic lag selection is performed, displaying a {bf:full BIC grid}
of all (p,q) combinations with the optimal pair highlighted.

{phang}
{opt q(#)} specifies the distributed lag order for the independent variables
(q >= 1). Works analogously to {opt p()}.

{phang}
{opt pmax(#)} specifies the maximum autoregressive lag order for the BIC 
search; default is {cmd:pmax(7)}. The grid searches all combinations from
p=1 to pmax and q=1 to qmax.

{phang}
{opt qmax(#)} specifies the maximum distributed lag order for the BIC search;
default is {cmd:qmax(7)}.

{phang}
{opt ecm} requests the QARDL Error Correction Model (ECM) form. In addition
to the standard beta, phi, and gamma, the ECM form estimates:

{p 12 16 2}
{bf:phi*(tau)} — cumulative AR coefficients that capture the short-run dynamics
in the ECM parameterization.{break}
{bf:theta(tau)} — ECM impact coefficients of the differenced independent 
variables.

{dlgtab:Rolling estimation}

{phang}
{opt rolling(#)} activates rolling-window QARDL estimation with the specified 
window size. This produces time-varying parameter estimates and Wald test 
statistics, useful for structural break analysis. If set to 0, the window 
size is automatically chosen as max(10% of sample, p+q+k+10).

{dlgtab:Simulation}

{phang}
{opt simulate(# [#])} runs a Monte Carlo simulation to evaluate finite-sample 
properties of the Wald tests. The first number is the number of replications; 
the second (optional) is the sample size per replication (default = actual 
sample size). Reports empirical rejection rates at 10%, 5%, and 1% levels.

{dlgtab:Testing}

{phang}
{opt waldtest(string)} specifies the Wald test. By default, {cmd:qardl} 
automatically performs constancy tests for all parameters. The null hypothesis
is H0: parameter(tau_i) = parameter(tau_{i+1}).

{dlgtab:Output}

{phang}
{opt graph} produces quantile process plots showing parameter estimates and 
confidence bands across quantiles. For rolling estimation, also produces 
time-varying plots.

{phang}
{opt notable} suppresses the coefficient display tables while still performing 
estimation and storing all results.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Data requirements.} The variables must be time series. Ensure data is 
{cmd:tsset} before using {cmd:qardl}. The QARDL framework is designed for 
cointegrated I(1) variables, but it does not test for unit roots or 
cointegration rank — users should determine the integration order of their 
variables beforehand.

{pstd}
{bf:Lag selection.} When {opt p()} and {opt q()} are not specified, the BIC 
criterion selects the optimal lag orders via OLS (at the conditional mean).
The selected orders are then used for quantile regression at all specified 
tau values.

{pstd}
{bf:Parameter ordering.} The parameter vectors (beta, phi, gamma) are stored 
in {bf:quantile-first} order. For example, with 2 independent variables and 
3 quantiles, the beta vector is ordered as:

{p 12 12 2}
beta = (beta_x1(tau1), beta_x2(tau1), beta_x1(tau2), beta_x2(tau2), beta_x1(tau3), beta_x2(tau3))'

{pstd}
Similarly, with p=2 lags and 3 quantiles:

{p 12 12 2}
phi = (phi_1(tau1), phi_2(tau1), phi_1(tau2), phi_2(tau2), phi_1(tau3), phi_2(tau3))'

{pstd}
This matches the ordering used in the original GAUSS implementation by Cho, Kim & Shin.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}{bf:Example 1: Basic QARDL with fixed lags}{p_end}
    {hline}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}

{pstd}Estimate QARDL(2,1) at three key quantiles{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1)}{p_end}

{pstd}This produces three output tables:{p_end}
{p 8 8 2}
1. {bf:Long-run parameters (beta):} Equilibrium relationship at each quantile.
   Different beta values across quantiles indicate asymmetric long-run effects.{break}
2. {bf:Short-run AR parameters (phi):} How past {depvar} values affect the current 
   level at each quantile. Labeled as L1.dln_inv, L2.dln_inv.{break}
3. {bf:Short-run impact parameters (gamma):} Contemporaneous effect of x-variables 
   at each quantile.

{pstd}Plus a Wald test table checking if parameters are constant across quantiles.

    {hline}
{pstd}{bf:Example 2: Automatic BIC lag selection}{p_end}
    {hline}

{pstd}Let the BIC choose optimal p and q (searched over 1 to 7){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9)}{p_end}

{pstd}For a narrower search range:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) pmax(4) qmax(4)}{p_end}

    {hline}
{pstd}{bf:Example 3: QARDL-ECM estimation}{p_end}
    {hline}

{pstd}Estimate the Error Correction form — useful when the ECM term (speed of 
adjustment) is of interest{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecm}{p_end}

{pstd}This additionally reports:{p_end}
{p 8 8 2}
{bf:phi*(tau):} Cumulative AR parameters in the ECM parameterization.{break}
{bf:theta(tau):} Impact coefficients of dx in the ECM form.{break}
Plus ECM-specific Wald tests for constancy of phi* and theta.

    {hline}
{pstd}{bf:Example 4: Fine quantile grid with graphs}{p_end}
    {hline}

{pstd}Estimate at 9 quantiles and plot the quantile process{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.1(0.1)0.9) p(1) q(1) graph}{p_end}

    {hline}
{pstd}{bf:Example 5: Rolling window estimation}{p_end}
    {hline}

{pstd}Time-varying QARDL with a 60-observation rolling window{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(1) q(1) rolling(60)}{p_end}

{pstd}Auto window size (10% of sample){p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.5) p(1) q(1) rolling(0)}{p_end}

    {hline}
{pstd}{bf:Example 6: Monte Carlo simulation}{p_end}
    {hline}

{pstd}Evaluate Wald test size with 500 replications and n=500{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc, tau(0.25 0.5 0.75) p(1) q(1) simulate(500 500)}{p_end}

    {hline}
{pstd}{bf:Example 7: Post-estimation access to stored results}{p_end}
    {hline}

{pstd}Run estimation and access results{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1)}{p_end}

{pstd}View stored beta coefficients{p_end}
{phang2}{cmd:. matrix list e(beta)}{p_end}

{pstd}View beta covariance matrix{p_end}
{phang2}{cmd:. matrix list e(beta_cov)}{p_end}

{pstd}View raw quantile regression coefficients{p_end}
{phang2}{cmd:. matrix list e(bt_raw)}{p_end}

{pstd}Access specific elements{p_end}
{phang2}{cmd:. display "Beta for x1 at tau=0.25: " e(beta)[1,1]}{p_end}
{phang2}{cmd:. display "Optimal p = " e(p) " , q = " e(q)}{p_end}
{phang2}{cmd:. display "Number of quantiles = " e(ntau)}{p_end}

    {hline}
{pstd}{bf:Example 8: Reproducing the Cho, Kim & Shin demo}{p_end}
    {hline}

{pstd}
The original GAUSS demo uses data with 2 independent variables, 
selects p via BIC (gets p=2, overridden to p=3 in the demo), q=1, 
and estimates at 9 quantiles (tau = 0.1, 0.2, ..., 0.9).
To replicate with {cmd:qardl}:

{phang2}{cmd:. * Load your data (e.g., from the GAUSS qardl_data.dat)}{p_end}
{phang2}{cmd:. * Assuming variables are y, x1, x2}{p_end}
{phang2}{cmd:. qardl y x1 x2, tau(0.1(0.1)0.9) p(3) q(1)}{p_end}

{pstd}The output should match the GAUSS demo results:{p_end}
{p 8 8 2}
{bf:Phi} (with p=3): L1.y (≈0.26), L2.y (≈-0.007), L3.y (≈-0.002) at each quantile{break}
{bf:Beta}: x1 (≈6.665), x2 (≈6.667) at each quantile{break}
{bf:Gamma}: x1 (≈4.99), x2 (≈4.99) at each quantile

    {hline}
{pstd}{bf:Example 9: Generate example data with known DGP}{p_end}
    {hline}

{pstd}Generate data from the Cho, Kim & Shin (2015) DGP for testing{p_end}
{phang2}{cmd:. qardl_makedata, n(500) seed(12345)}{p_end}

{pstd}Estimate and compare to known true values (beta = 6.6667){p_end}
{phang2}{cmd:. qardl y x1 x2, tau(0.25 0.5 0.75) p(1) q(2)}{p_end}

    {hline}
{pstd}{bf:Example 10: Post-estimation Wald tests}{p_end}
    {hline}

{pstd}After estimation, run individual Wald tests{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(1) q(1)}{p_end}

{pstd}Test beta constancy (quantile cointegration){p_end}
{phang2}{cmd:. _qardl_waldtest, type(beta) tau(0.25 0.5 0.75)}{p_end}

{pstd}Test phi constancy (short-run AR asymmetry){p_end}
{phang2}{cmd:. _qardl_waldtest, type(phi) tau(0.25 0.5 0.75)}{p_end}

{pstd}Test gamma constancy (short-run impact asymmetry){p_end}
{phang2}{cmd:. _qardl_waldtest, type(gamma) tau(0.25 0.5 0.75)}{p_end}

{pstd}For ECM: test phi* and theta constancy{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.25 0.5 0.75) p(2) q(1) ecm}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(phi_ecm) tau(0.25 0.5 0.75)}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(theta) tau(0.25 0.5 0.75)}{p_end}

    {hline}
{pstd}{bf:Example 11: Rolling estimation with graphs}{p_end}
    {hline}

{pstd}Combine rolling window estimation with visualizations{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) p(1) q(1) rolling(60) graph}{p_end}

{pstd}This produces:{p_end}
{p 8 8 2}
1. Quantile process plots for beta, phi, gamma with 95% confidence bands{break}
2. Combined panel of all parameter plots{break}
3. Rolling window plots of beta at the median quantile{break}
4. Rolling Wald statistic plot with 5% critical value line

    {hline}
{pstd}{bf:Example 12: Advanced asymmetry analysis}{p_end}
    {hline}

{pstd}After estimation, run the full asymmetry diagnostic suite{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9) p(1) q(1)}{p_end}
{phang2}{cmd:. qardl_analysis}{p_end}

{pstd}This produces:{p_end}
{p 8 8 2}
1. Asymmetry summary tables for beta and gamma (min, max, ratio, index, Wald){break}
2. Coefficient heatmap across quantiles{break}
3. Pairwise quantile equality test matrix{break}
4. Fan charts showing all variables on a single plot{break}
5. Asymmetry ratio bar chart (max/min for each variable){break}
6. Tail divergence plot with confidence intervals{break}
7. Quantile gradient plot showing where asymmetry is concentrated{break}
8. Combined dashboard panel

{pstd}For tables only (no graphs):{p_end}
{phang2}{cmd:. qardl_analysis, nograph}{p_end}

{pstd}For graphs only (no tables):{p_end}
{phang2}{cmd:. qardl_analysis, nosummary}{p_end}

    {hline}
{pstd}{bf:Example 13: Automatic lag order selection with BIC grid}{p_end}
    {hline}

{pstd}Let the BIC criterion select optimal (p,q) and display the full grid{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.25 0.5 0.75 0.9)}{p_end}

{pstd}This displays a table of BIC values for all combinations p=1,...,7 and q=1,...,7,
with the optimal pair marked by {cmd:*}. You can limit the search range:{p_end}
{phang2}{cmd:. qardl dln_inv dln_inc dln_consump, tau(0.1 0.5 0.9) pmax(4) qmax(4)}{p_end}

{pstd}The BIC grid follows {help qardl##CKS2015:Cho et al. (2015)} and
the original MATLAB/GAUSS {cmd:pqorder()} function. It computes
BIC = n*ln(mean(u^2)) + k*ln(n) for each (p,q) via OLS at the conditional
mean, then selects the combination with smallest BIC value.{p_end}


{marker interpretation}{...}
{title:Output interpretation}

{pstd}
{bf:Output tables.} The {cmd:qardl} output displays three main coefficient 
tables, each organized by quantile. Within each quantile block, all 
lags/variables are listed:

{col 5}{hline 66}
{col 5}Long-Run Parameters: {it:beta}(tau)
{col 5}{hline 66}
{col 7}Variable    Quantile     Estimate    Std.Err.     t-stat    p-value
{col 5}{hline 66}
{col 5}{hline 4}{it: tau = 0.25}{hline 48}
{col 7}x1            0.25       6.6646      0.5184      12.856     0.0000
{col 7}x2            0.25       6.6669      0.1954      34.114     0.0000
{col 5}{hline 4}{it: tau = 0.50}{hline 48}
{col 7}x1            0.50       6.6660      0.4900      13.604     0.0000
{col 7}x2            0.50       6.6667      0.1847      36.085     0.0000
{col 5}{hline 66}

{pstd}
{bf:Interpreting beta (long-run parameters).} The long-run equilibrium 
relationship at quantile tau is:

{p 8 8 2}
y = alpha(tau) + beta_1(tau)*x1 + beta_2(tau)*x2

{pstd}
If beta varies across quantiles, the long-run relationship is {bf:asymmetric}: 
the equilibrium impact of x differs depending on whether y is in the upper or 
lower tail of its distribution.

{pstd}
{bf:Interpreting phi (short-run AR parameters).} phi_i(tau) captures the 
persistence of the dependent variable at quantile tau. The sum of all phi 
coefficients indicates the total short-run persistence. If the sum is close to 1,
shocks are highly persistent at that quantile.

{pstd}
{bf:Interpreting gamma (short-run impact parameters).} gamma_j(tau) measures the 
immediate impact of x on y at quantile tau. If gamma varies across quantiles, the 
short-run response is asymmetric.

{pstd}
{bf:Interpreting the Wald test.} The Wald test for constancy tests:

{p 8 8 2}
H0: parameter(tau_i) = parameter(tau_{i+1}) for all adjacent quantile pairs.

{pstd}
{bf:Rejection} (p < 0.05) means the parameter varies significantly across 
quantiles — evidence of {bf:quantile heterogeneity}. This is the key result 
of the QARDL approach: if the standard ARDL (conditional mean) misses these 
quantile differences, it provides an incomplete picture.

{pstd}
{bf:Interpreting ECM parameters.} With the {opt ecm} option:

{p 8 8 2}
{bf:phi*(tau):} Cumulative autoregressive parameters after reparameterization. 
These correspond to the coefficients of the differenced lagged dependent 
variable in the ECM form.{break}
{bf:theta(tau):} The short-run impact coefficients in the ECM form, 
combining the contemporaneous and lagged effects of dx.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:qardl} stores the following in {cmd:e()}:

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(p)}}autoregressive lag order{p_end}
{synopt:{cmd:e(q)}}distributed lag order{p_end}
{synopt:{cmd:e(k)}}number of independent variables{p_end}
{synopt:{cmd:e(ntau)}}number of quantile levels{p_end}

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Matrices}{p_end}
{synopt:{cmd:e(tau)}}(ntau x 1) vector of quantile levels{p_end}
{synopt:{cmd:e(beta)}}(k*ntau x 1) long-run parameters{p_end}
{synopt:{cmd:e(beta_cov)}}(k*ntau x k*ntau) covariance of beta{p_end}
{synopt:{cmd:e(phi)}}(p*ntau x 1) short-run AR parameters{p_end}
{synopt:{cmd:e(phi_cov)}}(p*ntau x p*ntau) covariance of phi{p_end}
{synopt:{cmd:e(gamma)}}(k*ntau x 1) short-run impact parameters{p_end}
{synopt:{cmd:e(gamma_cov)}}(k*ntau x k*ntau) covariance of gamma{p_end}
{synopt:{cmd:e(bt_raw)}}(ncols x ntau) raw quantile regression coefficients{p_end}
{synopt:{cmd:e(fh)}}(ntau x 1) kernel density estimates{p_end}

{pstd}
With {cmd:ecm} option, additionally:

{synoptset 30 tabbed}{...}
{synopt:{cmd:e(phi_ecm)}}((p-1)*ntau x 1) ECM cumulative AR parameters{p_end}
{synopt:{cmd:e(phi_ecm_cov)}}covariance of phi_ecm{p_end}
{synopt:{cmd:e(theta)}}(q*k*ntau x 1) ECM impact parameters{p_end}
{synopt:{cmd:e(theta_cov)}}covariance of theta{p_end}

{pstd}
With {cmd:rolling()} option, additionally:

{synoptset 30 tabbed}{...}
{synopt:{cmd:e(rolling_beta)}}(nwindows x k*ntau) time-varying beta{p_end}
{synopt:{cmd:e(rolling_phi)}}(nwindows x p*ntau) time-varying phi{p_end}
{synopt:{cmd:e(rolling_gamma)}}(nwindows x k*ntau) time-varying gamma{p_end}
{synopt:{cmd:e(rolling_wald_beta)}}(nwindows x 1) time-varying beta Wald stats{p_end}
{synopt:{cmd:e(rolling_wald_phi)}}(nwindows x 1) time-varying phi Wald stats{p_end}
{synopt:{cmd:e(rolling_wald_gamma)}}(nwindows x 1) time-varying gamma Wald stats{p_end}
{synopt:{cmd:e(rolling_window)}}rolling window size{p_end}

{synoptset 30 tabbed}{...}
{p2col 5 30 34 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qardl}{p_end}
{synopt:{cmd:e(model)}}{cmd:qardl} or {cmd:qardl-ecm}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(indepvars)}}names of independent variables{p_end}
{synopt:{cmd:e(title)}}estimation title{p_end}
{synopt:{cmd:e(author)}}Dr Merwan Roudane{p_end}
{synopt:{cmd:e(email)}}merwanroudane920@gmail.com{p_end}


{marker methods}{...}
{title:Methods and formulas}

{pstd}
{bf:Notation.}  Let y_t be the dependent variable, x_t = (x_1t,...,x_kt)' a
k-vector of I(1) regressors, t = 1,...,n.  Let tau denote a quantile level
in (0,1) and s the number of specified quantiles.{p_end}


    {hline}
{pstd}{bf:1. QARDL(p,q) Model} (Cho et al., 2015, eq. 1){p_end}
    {hline}

{pstd}
The conditional quantile function is:{p_end}

{col 7}Q_y(tau | F_t-1) = alpha(tau)
{col 28}+ SUM_j=0^q-1  delta_j(tau)' * Dx_t-j
{col 28}+ gamma(tau)' * x_t
{col 28}+ SUM_i=1^p  phi_i(tau) * y_t-i

{pstd}
where Dx_t-j = x_t-j - x_t-j-1 are first differences.{p_end}

{pstd}Parameters:{p_end}
{phang2}- {bf:alpha(tau)}: intercept at quantile tau{p_end}
{phang2}- {bf:delta_j(tau)}: (k x 1) response to the j-th lagged difference{p_end}
{phang2}- {bf:gamma(tau)}: (k x 1) coefficient on the level of x_t{p_end}
{phang2}- {bf:phi_i(tau)}: autoregressive coefficient on y_t-i{p_end}

{pstd}
Estimation is by quantile regression (IRLS algorithm initialized with OLS).{p_end}


    {hline}
{pstd}{bf:2. Long-Run Parameters: beta(tau)} (Cho et al., 2015, eq. 4){p_end}
    {hline}

{pstd}The long-run cointegrating coefficient at quantile tau:{p_end}

{col 7}beta(tau) = gamma(tau) / (1 - SUM_i  phi_i(tau))

{pstd}
If constant across quantiles, beta(tau) = beta for all tau, recovering the
standard Pesaran and Shin (1998) ARDL result.{p_end}

{pstd}Covariance (Theorem 1):{p_end}

{col 7}V_beta = Omega (kron) M^-1

{pstd}where (kron) denotes the Kronecker product.{p_end}

{pstd}{bf:Omega} is (s x s) with element:{p_end}

{col 7}Omega(j,i) = [min(tau_j, tau_i) - tau_j*tau_i] * b(tau_j) * b(tau_i)

{pstd}
where b(tau) = 1 / [(1 - SUM phi_i(tau)) * f(tau)] and f(tau) is the
conditional density of the regression error.{p_end}

{pstd}{bf:M} is the (k x k) data-dependent matrix:{p_end}

{col 7}M = [X'X - X'W * inv(W'W) * W'X] / (n-q)^2

{pstd}
where X = x_q+1:n (level regressors) and W = (1, barw) (constant and
cumulated lagged differences).{p_end}

{pstd} {p_end}
    {hline}
{pstd}{bf:3. Conditional Density Estimation}{p_end}
    {hline}

{pstd}The density f(tau) is estimated nonparametrically:{p_end}

{col 7}f_hat(tau) = (1/n) * SUM_t  phi(-u_t / h_B) / h_B

{pstd}
where phi(.) is the standard normal density and h_B is the Bofinger (1975)
bandwidth:{p_end}

{col 7}h_B = [4.5 * phi(z_tau)^4 / (n * (2*z_tau^2 + 1)^2)]^(1/5)

{pstd}
with z_tau = Phi^-1(tau).  This follows the original MATLAB and GAUSS codes.{p_end}


    {hline}
{pstd}{bf:4. Short-Run AR Parameters: phi(tau)} (Theorem 2){p_end}
    {hline}

{pstd}
phi(tau) = (phi_1(tau),...,phi_p(tau))' are from the quantile regression.
Joint covariance across quantiles (nuisance parameter approach):{p_end}

{col 7}V_phi: block (j,i) = c(tau_j, tau_i) * Psi(j,i)

{pstd}where:{p_end}

{col 7}c(tau_j, tau_i) = [min(tau_j,tau_i) - tau_j*tau_i] / [f(tau_j)*f(tau_i)]

{col 7}Psi(j,i) = inv(L_jj) * L_ji * inv(L_ii)

{pstd}
L is the (s*p x s*p) matrix of auxiliary regression residual products from
regressions of each lagged y_t-l on (1, x, Dx-lags).{p_end}


    {hline}
{pstd}{bf:5. Short-Run Impact Parameters: gamma(tau)} (Corollary 1){p_end}
    {hline}

{pstd}
gamma(tau) are the level coefficients on x_t.  Covariance by delta method:{p_end}

{col 7}V_gamma = Lambda * V_phi * Lambda'

{pstd}
Lambda is (k*s x s*p) block-diagonal with Lambda_j = beta(tau_j) * iota_p'.{p_end}


    {hline}
{pstd}{bf:6. Wald Tests for Parameter Constancy} (Section 3){p_end}
    {hline}

{pstd}Tests whether parameters are constant across quantiles:{p_end}

{col 7}H0: param(tau_1) = param(tau_2) = ... = param(tau_s)

{pstd}Implemented via (s-1) pairwise equality restrictions R*param = 0.{p_end}

{pstd}Wald statistics:{p_end}

{col 7}W_beta  = (n-1)^2 * (R*b)' * inv[R * V_beta  * R'] * (R*b)
{col 7}W_phi   = (n-1)   * (R*p)' * inv[R * V_phi   * R'] * (R*p)
{col 7}W_gamma = (n-1)   * (R*g)' * inv[R * V_gamma * R'] * (R*g)

{pstd}
Under H0: W ~ chi2(df) with df = (s-1)*d.  W_beta uses (n-1)^2 because
V_beta contains (n-q)^-2 from M; W_phi and W_gamma use (n-1).{p_end}

{pstd}
{bf:Rejection} (p < 0.05) = quantile heterogeneity = evidence of
{bf:quantile cointegration}.{p_end}

    {hline}
{pstd}{bf:7. ECM Speed of Adjustment: rho(tau)}{p_end}
    {hline}

{pstd}
The error correction coefficient at each quantile is:{p_end}

{col 7}rho(tau) = SUM phi_i(tau) - 1

{pstd}
Negative rho(tau) implies convergence to equilibrium.
The SE is computed via the delta method from the phi covariance.{p_end}


    {hline}
{pstd}{bf:8. Pairwise Equality Tests (by variable)}{p_end}
    {hline}

{pstd}
Variable-specific pairwise tests for each (tau_i, tau_j) pair:{p_end}

{col 7}W_v = scale * [param_v(tau_i) - param_v(tau_j)]^2 / Var(diff)

{pstd}
where Var(diff) = V_ii + V_jj - 2*V_ij, and scale = (n-1)^2 for beta,
(n-1) for gamma. Under H0, W_v ~ chi2(1).{p_end}


    {hline}
{pstd}{bf:9. BIC Lag Selection} (p. 290){p_end}
    {hline}

{col 7}BIC(p,q) = n * ln(mean(u_hat^2)) + k_total * ln(n)

{pstd}
u_hat = OLS residuals, k_total = 1 + q*k + k + p.  Grid search over
p = 1,...,pmax and q = 1,...,qmax (default 7 each).{p_end}


{marker companion}{...}
{title:Companion commands}

{pstd}
The {cmd:qardl} package includes the following companion commands:

{synoptset 25 tabbed}{...}
{synopt:{cmd:qardl_analysis}}advanced post-estimation analysis: quantile
   cointegration summary table (per-variable Wald tests with QC verdict),
   asymmetry diagnostics (min/max/ratio/index), coefficient heatmap,
   pairwise equality tests, fan charts, asymmetry ratio bars, tail
   divergence, gradient plots, ECM speed-of-adjustment bar chart, pairwise
   p-value dot plots (beta & gamma), and two combined dashboards;
   options: {opt nosummary} {opt nograph} {opt nopairwise}{p_end}
{synopt:{cmd:qardl_makedata}}generate example data from the Cho, Kim & Shin (2015)
   DGP with known true parameter values for validation{p_end}
{synopt:{cmd:_qardl_waldtest}}post-estimation Wald test for individual parameter
   types (beta, phi, gamma, phi_ecm, theta); returns r(wald), r(df), r(pval){p_end}
{synopt:{cmd:qardl_graph}}standalone graphing command (called automatically with
   {opt graph} option, but can be called separately after estimation){p_end}

{pstd}
Usage examples:

{phang2}{cmd:. qardl_analysis}{p_end}
{phang2}{cmd:. qardl_analysis, nograph}{p_end}
{phang2}{cmd:. qardl_makedata, n(1000) seed(42)}{p_end}
{phang2}{cmd:. _qardl_waldtest, type(beta) tau(0.25 0.5 0.75)}{p_end}


{marker references}{...}
{title:References}

{marker CKS2015}{...}
{phang}
Cho, J. S., Kim, T., & Shin, Y. (2015). 
Quantile cointegration in the autoregressive distributed-lag modeling framework.
{it:Journal of Econometrics}, 188(2), 281-300.
{browse "https://doi.org/10.1016/j.jeconom.2015.05.003"}

{marker PS1998}{...}
{phang}
Pesaran, M. H., & Shin, Y. (1998). 
An autoregressive distributed-lag modelling approach to cointegration analysis.
{it:Econometric Society Monographs}, 31, 371-413.

{phang}
Xiao, Z. (2009). 
Quantile cointegrating regression.
{it:Journal of Econometrics}, 150(2), 248-260.

{phang}
Koenker, R., & Bassett, G. (1978).
Regression quantiles.
{it:Econometrica}, 46(1), 33-50.


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
{cmd:qardl} v1.1.0 — February 2026

{pstd}
The GAUSS and MATLAB implementations were developed by Jin Seo Cho, Tae-hwan Kim 
& Yongcheol Shin. This Stata implementation was translated and extended by 
Dr Merwan Roudane.

{pstd}
Please cite this package as:{break}
Roudane, M. (2026). {cmd:qardl}: Stata module for Quantile Autoregressive 
Distributed-Lag estimation. Based on Cho, Kim & Shin (2015).
{p_end}
