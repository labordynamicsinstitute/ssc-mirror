{smcl}
{vieweralsosee "trop" "help trop"}{...}
{vieweralsosee "trop estat" "help trop_estat"}{...}
{viewerjumpto "Syntax" "trop_predict##syntax"}{...}
{viewerjumpto "Description" "trop_predict##description"}{...}
{viewerjumpto "Options" "trop_predict##options"}{...}
{viewerjumpto "Remarks" "trop_predict##remarks"}{...}
{viewerjumpto "Examples" "trop_predict##examples"}{...}
{viewerjumpto "Stored results" "trop_predict##results"}{...}
{viewerjumpto "Methods and formulas" "trop_predict##methods"}{...}
{viewerjumpto "References" "trop_predict##references"}{...}
{viewerjumpto "Author" "trop_predict##author"}{...}
{title:Title}

{p2colset 5 24 26 2}{...}
{p2col:{cmd:predict} {hline 2}}Predictions after trop estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:predict} {newvar} {ifin} [{cmd:,} {it:statistic}]

{synoptset 20 tabbed}{...}
{synopthdr:statistic}
{synoptline}
{syntab:Main}
{synopt:{opt y0}}counterfactual prediction Y(0); the default{p_end}
{synopt:{opt y1}}potential outcome Y(1){p_end}
{synopt:{opt te}}treatment effect (treated observations only){p_end}
{synopt:{opt res:iduals}}residuals{p_end}
{synopt:{opt mu}}global intercept (joint method only){p_end}
{synopt:{opt alpha}}unit fixed effects{p_end}
{synopt:{opt beta}}time fixed effects{p_end}
{synopt:{opt xb}}linear prediction (alias for {opt y0}){p_end}
{synopt:{opt fitted}}fitted values Y_hat = Y(0) + tau * W{p_end}
{synopt:{opt att}}treatment effect (alias for {opt te}){p_end}
{synopt:{opt counterfactual}}counterfactual Y(0) (alias for {opt y0}){p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:predict} creates a new variable containing predictions, residuals, or
estimated model components after {cmd:trop} estimation.

{pstd}
If no statistic is specified, the default is {opt y0} (counterfactual
prediction).  Only one statistic may be specified at a time.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt y0} calculates the counterfactual prediction Y(0), representing the
outcome that would have been observed in the absence of treatment.
This is the default.

{pmore}
The computation depends on the estimation method:

{pmore}
{bf:Twostep (Algorithm 2):}
For treated observations, Y(0) = Y_obs - tau_hat, preserving the exact
identity Y_obs - Y(0) = tau_hat.  For control observations,
Y(0) = alpha_i + beta_t + L_{t,i}, reconstructed from the additive model
components stored in {cmd:e(alpha)}, {cmd:e(beta)}, and
{cmd:e(factor_matrix)}.

{pmore}
{bf:Joint (Remark 6.1):}
For all observations, Y(0) = mu + alpha_i + beta_t + L_{t,i}, where mu
is the global intercept stored in {cmd:e(mu)}, with identification
constraints alpha_1 = beta_1 = 0.  This is the shared-tau extension used
when a common treated block and homogeneous effects are substantively
appropriate.

{phang}
{opt y1} calculates the potential outcome Y(1) under treatment.

{pmore}
{bf:Twostep:} For treated observations, Y(1) = Y(0) + tau_it, where
tau_it is the observation-specific treatment effect from {cmd:e(tau)}.
For control observations, Y(1) = Y(0) + ATT, where ATT is the scalar
average treatment effect from {cmd:e(att)}.

{pmore}
{bf:Joint:} For all observations, Y(1) = Y(0) + ATT, using the
homogeneous scalar treatment effect from {cmd:e(att)}.

{phang}
{opt te} calculates the treatment effect for treated observations only.
Control observations receive missing values.

{pmore}
{bf:Twostep:} Returns the observation-specific treatment effect tau_it
from {cmd:e(tau)}, which permits heterogeneous effects across units and
time periods.

{pmore}
{bf:Joint:} Returns the homogeneous scalar ATT from {cmd:e(att)} for all
treated observations.  This applies the same shared tau to every treated
cell.

{pmore}
The same information is available without creating a new variable through
{cmd:e(tau_matrix)} (a {it:T x N} matrix indexed by (time, panel) with
missing values in untreated cells); see {helpb trop##results:trop} for
details.

{phang}
{opt residuals} calculates residuals for all observations.

{pmore}
{bf:Twostep (with e(tau) available):}
epsilon_it = Y_it - Y(0)_it - tau_it, where tau_it is the
observation-specific treatment effect.  For control observations
(tau_it = 0), this simplifies to epsilon_it = Y_it - Y(0)_it.

{pmore}
{bf:Twostep (without e(tau)) and Joint:}
epsilon_it = Y_it - Y(0)_it - ATT * D_it, where ATT is the scalar
average treatment effect and D_it is the treatment indicator.

{phang}
{opt mu} extracts the global intercept mu.

{pmore}
{bf:Twostep:} Returns missing values (.) for all observations.  The
Twostep decomposition Y(0) = alpha_i + beta_t + L_it does not identify
a separate global intercept.

{pmore}
{bf:Joint:} Returns the constant {cmd:e(mu)} for all observations.  The
Joint decomposition Y(0) = mu + alpha_i + beta_t + L_it includes an
explicit global intercept with identification constraints
alpha_1 = beta_1 = 0.

{phang}
{opt alpha} extracts unit fixed effects alpha_i from {cmd:e(alpha)}.
Each unit receives the same value across all time periods.

{phang}
{opt beta} extracts time fixed effects beta_t from {cmd:e(beta)}.  Each
time period receives the same value across all units.

{phang}
{opt xb} is an alias for {opt y0}.  Both produce identical results.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Method-dependent parameterization}

{pstd}
The {cmd:trop} command supports two estimation methods that differ in
their parameterization of the counterfactual outcome:

{p 8 12 2}
{bf:Twostep} (Algorithm 2): Y(0) = alpha_i + beta_t + L_it{p_end}
{p 8 12 2}
{bf:Joint} (Remark 6.1): Y(0) = mu + alpha_i + beta_t + L_it with
alpha_1 = beta_1 = 0{p_end}

{pstd}
Both parameterizations yield equivalent counterfactual predictions.  The
difference lies in how the intercept is distributed among the parameters.

{pstd}
{bf:Heterogeneous versus homogeneous treatment effects}

{pstd}
Under the Twostep method, each treated observation receives an
observation-specific treatment effect tau_it stored in {cmd:e(tau)}.  The
{opt te} option returns these heterogeneous effects directly.  Under the
Joint method, a single scalar ATT is estimated and applied uniformly to
all treated observations.  The {cmd:joint} path is therefore best viewed as
a shared-weight, homogeneous-effect extension rather than the default TROP
workflow.

{pstd}
{bf:Treatment effect sparsity}

{pstd}
The {opt te} option generates non-missing values only for treated
observations (D=1).  For control observations (D=0), the treatment
effect is undefined and set to missing.

{pstd}
{bf:Data consistency}

{pstd}
{cmd:predict} verifies that the data has not changed since estimation
through a multi-level validation procedure.  If the sample size, panel
structure, or dependent variable checksum has changed, an error is
reported.


{marker examples}{...}
{title:Examples}

{pstd}Setup: Generate test panel data{p_end}
{phang2}{cmd:. clear all}{p_end}
{phang2}{cmd:. set seed 12345}{p_end}
{phang2}{cmd:. set obs 1000}{p_end}
{phang2}{cmd:. gen id = ceil(_n/10)}{p_end}
{phang2}{cmd:. bysort id: gen t = _n}{p_end}
{phang2}{cmd:. gen y = rnormal() + 0.5*(id>80)*(t>7)}{p_end}
{phang2}{cmd:. gen d = (id > 80 & t > 7)}{p_end}

{pstd}Run trop estimation{p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) seed(42)}{p_end}

{pstd}Counterfactual prediction (default){p_end}
{phang2}{cmd:. predict y0_hat}{p_end}
{phang2}{cmd:. predict y0_hat2, y0}{p_end}

{pstd}Potential outcome under treatment{p_end}
{phang2}{cmd:. predict y1_hat, y1}{p_end}

{pstd}Treatment effects (treated only){p_end}
{phang2}{cmd:. predict te_hat, te}{p_end}

{pstd}Residuals{p_end}
{phang2}{cmd:. predict resid, residuals}{p_end}

{pstd}Fixed effects{p_end}
{phang2}{cmd:. predict alpha_hat, alpha}{p_end}
{phang2}{cmd:. predict beta_hat, beta}{p_end}

{pstd}Global intercept (joint method){p_end}
{phang2}{cmd:. trop y d, panelvar(id) timevar(t) method(joint) seed(42)}{p_end}
{phang2}{cmd:. predict mu_hat, mu}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:predict} after {cmd:trop} does not modify {cmd:e()} or store
results in {cmd:r()}.  It creates a new variable in the dataset.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
The TROP estimator predicts counterfactual outcomes for treated unit-time
pairs by solving a weighted nuclear-norm penalized regression (Eq. 2 of
Athey, Imbens, Qu, and Viviano, 2025):

{p 8 8 2}
(alpha_hat, beta_hat, L_hat) = argmin sum_{j,s} theta_s * omega_j *
(1 - W_{js}) * (Y_{js} - alpha_j - beta_s - L_{js})^2
+ lambda_nn * ||L||_*

{pstd}
where theta_s = exp(-lambda_time * |t - s|) are exponential time-decay
weights and omega_j = exp(-lambda_unit * dist(j, i)) are unit
distance-based weights (Eq. 3).  The treatment effect for each treated
observation (i, t) is then estimated as

{p 8 8 2}
tau_hat_{it} = Y_{it} - alpha_hat_i - beta_hat_t - L_hat_{it}

{pstd}
Under the Twostep method (Algorithm 2), each treated observation receives
its own weight matrix and observation-specific treatment effect tau_it.
Under the Joint method (Remark 6.1), a single set of global weights is
used and a homogeneous scalar ATT is estimated.  This shared-tau extension
is intended for simultaneous-adoption designs.

{pstd}
The triple robustness property (Theorem 5.1) states that the bias
satisfies

{p 8 8 2}
|Bias| <= ||Delta^u||_2 * ||Delta^t||_2 * ||B||_*

{pstd}
where Delta^u is unit imbalance, Delta^t is time imbalance, and B
captures regression adjustment misspecification.  The estimator is
consistent if any one of the three components removes the underlying
bias.

{pstd}
Tuning parameters (lambda_time, lambda_unit, lambda_nn) are selected via
leave-one-out cross-validation (LOOCV) minimizing (Eq. 5)

{p 8 8 2}
Q(lambda) = sum_{i,t} (1 - W_{it}) * (tau_hat_{it}(lambda))^2


{marker references}{...}
{title:References}

{phang}
Athey, S., G. W. Imbens, Z. Qu, and D. Viviano. 2025.
Triply robust panel estimators.
{it:arXiv preprint arXiv:2508.21536}.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Xuanyu Cai{break}
City University of Macau{break}
xuanyuCAI@outlook.com

{pstd}
Wenli Xu{break}
City University of Macau{break}
wlxu@cityu.edu.mo


{title:Also see}

{psee}
Online: {helpb trop}, {helpb trop_estat}
{p_end}
