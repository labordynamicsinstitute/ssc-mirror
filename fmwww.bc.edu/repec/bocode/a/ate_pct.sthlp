{smcl}
{* *! version 1.0.0  26jan2026}{...}
{viewerjumpto "Syntax" "ate_pct##syntax"}{...}
{viewerjumpto "Description" "ate_pct##description"}{...}
{viewerjumpto "Options" "ate_pct##options"}{...}
{viewerjumpto "Returned results" "ate_pct##results"}{...}
{viewerjumpto "Examples" "ate_pct##examples"}{...}
{viewerjumpto "Remarks" "ate_pct##remarks"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{hi:ate_pct} {hline 2}}ATE in percentage points under subgroup heterogeneity (post-estimation){p_end}
{p2colreset}{...}

{marker syntax}{title:Syntax}

{p 8 15 2}
{cmd:ate_pct} {it:groupvars} [if]
{cmd:,} [{opt truew} {opt groupsize(numlist)}]

{p 8 15 2}
where {it:groupvars} is a varlist of G mutually exclusive subgroup indicator variables
(0/1 dummies) whose coefficients are estimated in the preceding model and therefore 
appear in {cmd:e(b)} and {cmd:e(V)}.


{p 8 15 2}
If {opt groupsize(numlist)} is not specified, {cmd:ate_pct} uses {it:groupvars} and
the estimation sample {cmd:e(sample)} to compute subgroup sizes and construct
empirical weights.

{p 8 15 2}
The {it:if} qualifier is for advanced users only. It can further restrict the sample used to compute subgroup weights/shares; coefficients and the variance–covariance matrix are always taken from the preceding estimation command (i.e., from e(b) and e(V) on e(sample)).


{marker description}{title:Description}

{pstd}
{cmd:ate_pct} is a post-estimation command for computing average treatment effect (ATE) in percentage points under treatment-effect heterogeneity across observable subgroups.

{pstd}
The command extracts the coefficients on the subgroup indicator variables from {cmd:e(b)} and treats them as subgroup-specific average
log-point treatment effects, denoted by {it:tau_g} for g = 1, ..., G, together with
their covariance matrix from {cmd:e(V)}.

{pstd}
If subgroup sizes are not supplied, {cmd:ate_pct} counts observations in each subgroup using {cmd:e(sample)} to obtain subgroup sizes {it:N_g}. 
Using either the computed or supplied subgroup
sizes, the command constructs subgroup weights
{it:w_g = N_g / (sum_h N_h)} and, unless {opt truew} is specified, estimates the
associated weight covariance matrix.

{pstd}
The command reports the following ATE-in-percentage-points functionals:

{p 8 12 2}
(1) {bf:taubar}: weighted average of subgroup-specific log-point effects,
{it:taubar = sum_g (w_g·tau_g)} .

{p 8 12 2}
(2) {bf:rho_a}: conventional approximation, 
{it:rho_a = exp(taubar) - 1}. 

{p 8 12 2}
(3) {bf:rho_b}: subgroup-aggregated percentage-point effect, {it:rho_b = sum_g [ w_g·exp(tau_g) ] -1} .

{pstd}
Standard errors are computed using delta-method formulas that account for estimation
uncertainty in subgroup effects and, when applicable, in subgroup weights.

{pstd}
{cmd:ate_pct} requires the preceding command to have stored {cmd:e(b)}, {cmd:e(V)},
and {cmd:e(sample)}.

{marker options}{title:Options}

{phang}
{opt groupsize(numlist)} supplies subgroup sizes {it:N_g}, one per variable in
{it:groupvars} and in the same order. All values must be positive.

{phang}
{opt truew} treats subgroup weights as fixed/known and sets the weight-variance component to zero (i.e., {it:Sigma_w = 0}).
This option is appropriate when subgroup weights are known or when inference is conditional on weights (for example, when equal weights are assigned to all subgroups).
{marker results}{title:Returned results}

{pstd}
{cmd:ate_pct} returns the following in {cmd:r()}:

{p 8 12 2}
Scalars:{p_end}
{p 12 12 2}
{cmd:r(N)} estimation sample size from the preceding command {p_end}
{p 12 12 2}
{cmd:r(N_T)} sample size used by {cmd:ate_pct} to compute subgroup weights/shares.
({it:N_T = sum_g N_g}){p_end}
{p 12 12 2}
{cmd:r(p_T)} target-sample share, 
{it:p_T = N_T / N}, when weights are estimated{p_end}

{p 8 12 2}
Matrices:{p_end}
{p 12 12 2}
{cmd:r(b)} 1x3 vector with columns {cmd:taubar rho_a rho_b}{p_end}
{p 12 12 2}
{cmd:r(V)} 3x3 variance matrix corresponding to {cmd:r(b)}. Off-diagonal covariances are ignored and set to 0. {p_end}
{p 12 12 2}
{cmd:r(tau)} Gx1 vector of subgroup average log-point effects {it:tau_g}{p_end}
{p 12 12 2}
{cmd:r(w)} Gx1 vector of subgroup weights {it:w_g}{p_end}
{p 12 12 2}
{cmd:r(Sigma_tau)} GxG covariance matrix of {it:tau}{p_end}
{p 12 12 2}
{cmd:r(Sigma_w)} GxG covariance matrix of {it:w} (zero if {opt truew}){p_end}
{p 12 12 2}
{cmd:r(delta)} stacked vector ({it:tau} \ {it:w}){p_end}
{p 12 12 2}
{cmd:r(Sigma_delta)} block-diagonal covariance matrix of ({it:tau},{it:w}){p_end}

{marker examples}{title:Examples}

{pstd} Suppose variables {it:gr1}, {it:gr2}, {it:gr3} are indicators for three sub-treatment groups and we are interested in the ATE in percentage points of these three sub-treatment groups. 

{pstd}
1. After a semi-log regression with subgroup-specific treatment effects:

{phang2}
{cmd:. use "ate_pct_example",clear}

{phang2}
{cmd:. regress lny gr1 gr2 gr3 x, robust}

{phang2}
{cmd:. ate_pct gr1 gr2 gr3}

{pstd}
2. Treat subgroup weights as fixed/known:

{phang2}
{cmd:. ate_pct gr1 gr2 gr3, truew}

{pstd}
3. Equal subgroup weights (requires {opt truew}), and focuses on subgroups 1 and 2:

{phang2}
{cmd:. ate_pct gr1 gr2, groupsize(1 1) truew}


{pstd}
4. Provide subgroup sizes externally. The command below is exactly the same as {cmd:ate_pct gr1 gr2 gr3} as 15, 24, 37 are the sample sizes for the three treatment groups.

{phang2}
{cmd:. ate_pct gr1 gr2 gr3, groupsize(15 24 37)}

{marker remarks}{title:Remarks}

{pstd}
{bf:Requirements.}
The variables in {it:groupvars} must be a subset of the coefficient names in {cmd:e(b)}.
When subgroup sizes are computed from the data, subgroup indicators must be 0/1 and
mutually exclusive within the estimation sample.

{title:Reference}

{pstd}
Zeng, Y. {it:Estimation and inference on average treatment effects in percentage points under heterogeneity}. Working paper.

{title:Author and support}

{pstd}
Ying Zeng

{pstd}
School of Economics and Wang Yanan Institute for Studies in Economics (WISE),
Xiamen University

{pstd}
Email: zengying17@gmail.com

{pstd}
The latest version of the code and related materials are available at:
{browse "https://github.com/zengying17/ate_pct-stata":https://github.com/zengying17/ate_pct-stata}


