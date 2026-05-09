{smcl}
{* *! quasicoint.sthlp — Help for quasicoint v1.0.2  2026-05-09}{...}
{vieweralsosee "vec"       "help vec"}{...}
{vieweralsosee "var"       "help var"}{...}
{vieweralsosee "vecrank"   "help vecrank"}{...}
{viewerjumpto "Syntax"           "quasicoint##syntax"}{...}
{viewerjumpto "Description"      "quasicoint##description"}{...}
{viewerjumpto "Methodology"      "quasicoint##methodology"}{...}
{viewerjumpto "Options"          "quasicoint##options"}{...}
{viewerjumpto "Stored results"   "quasicoint##results"}{...}
{viewerjumpto "Tables"           "quasicoint##tables"}{...}
{viewerjumpto "Examples"         "quasicoint##examples"}{...}
{viewerjumpto "Diagnostics"      "quasicoint##diagnostics"}{...}
{viewerjumpto "References"       "quasicoint##references"}{...}
{viewerjumpto "Author"           "quasicoint##author"}{...}

{title:Title}

{phang}
{bf:quasicoint} {hline 2} Quasi-Cointegration Analysis without Unit Roots
(Duffy & Simons 2023, CWPE 2332)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:quasicoint}
{varlist}
{ifin}
[{cmd:,}
{it:options}]

{pstd}
The data must be {helpb tsset} before calling {cmd:quasicoint}.
All variables must be numeric; time-series operators (L., D.) are allowed.
Variables should generally be in {bf:levels} (not first differences) since
the method is designed for data with near-unit roots.

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model specification}
{synopt:{opt rho(#)}}lower bound on dominant root; default 0.95{p_end}
{synopt:{opt nr:oots(#)}}number of near-unit roots q; default 1{p_end}
{synopt:{opt lags(#)}}VAR lag order k; 0 = auto-select via AIC (default){p_end}
{synopt:{opt maxl:ags(#)}}maximum lag order for AIC selection; default 8{p_end}
{synopt:{opt nocons:tant}}suppress intercept in VAR{p_end}
{synopt:{opt trend}}include linear trend in VAR{p_end}

{syntab:Inference}
{synopt:{opt grid:size(#)}}number of grid points for lambda profile; default 50{p_end}
{synopt:{opt nboot(#)}}Monte Carlo reps for NP test; default 2000{p_end}
{synopt:{opt le:vel(#)}}confidence level; default 95{p_end}

{syntab:Visualization}
{synopt:{opt plot}}produce all three plots (profile, IRF, root map){p_end}
{synopt:{opt plotp:rofile}}profile likelihood + conditional CI plot only{p_end}
{synopt:{opt ploti:rf}}impulse response function plot only{p_end}
{synopt:{opt plotr:oots}}characteristic root map in complex plane only{p_end}
{synopt:{opt saving(name)}}filename prefix for saved plots/exports; default quasicoint{p_end}

{syntab:Export}
{synopt:{opt ex:port(fmt)}}export results: {opt excel}, {opt latex}, {opt csv}, or {opt all}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:quasicoint} implements the quasi-cointegration framework of
{help quasicoint##DS2023:Duffy & Simons (2023)}, which extends standard
cointegration analysis to settings where the dominant autoregressive roots
may be {bf:near but not exactly equal to unity}.

{pstd}
{bf:The problem.} {help quasicoint##Elliott1998:Elliott (1998)} showed that
standard efficient estimators of cointegrating relationships (FM-OLS, DOLS,
Johansen ML) suffer severe size distortions when roots are near but not
exactly at unity — even within an O(n{c -1}) neighbourhood that is
empirically indistinguishable from exact unit roots.

{pstd}
{bf:The solution.} Rather than defining cointegration in terms of integration
orders — which becomes vacuous without exact unit roots — Duffy & Simons
identify long-run equilibrium relationships via the {bf:relative decay rates
of impulse responses}. The resulting {bf:quasi-cointegrating space (QCS)}
coincides exactly with the standard cointegrating space when unit roots are
present, but remains meaningful when they are not.

{pstd}
{bf:Key features:}

{phang2}(1) Spectral decomposition of the VAR companion matrix to isolate the
q most persistent components{p_end}

{phang2}(2) Profile likelihood across the dominant root lambda in [rho, 1]{p_end}

{phang2}(3) Conditional likelihood ratio tests (chi-squared) for the
quasi-cointegrating coefficients, given lambda{p_end}

{phang2}(4) Side-by-side comparison with standard Johansen estimates{p_end}

{phang2}(5) Correct L_LU/L_ST root classification with automatic warnings{p_end}

{phang2}(6) Publication-quality tables (5 tables) and plots (3 types){p_end}

{phang2}(7) LaTeX (booktabs), Excel, and CSV export{p_end}


{marker methodology}{...}
{title:Methodology}

{pstd}
{bf:VAR model:}

{pmore}
y_t = mu + delta*t + Phi_1 y_{c -(}t-1{c )-} + ... + Phi_k y_{c -(}t-k{c )-} + epsilon_t

{pstd}
{bf:Root separation.} The characteristic roots of the companion matrix are
partitioned into:

{phang2}L_LU = {c -(}z in C : |z| <= 1 and |z-1| <= 1-rho{c )-} — {bf:q near-unit roots}{p_end}
{phang2}L_ST = complement — {bf:remaining stationary roots}{p_end}

{pstd}
Roots falling in L_LU have modulus close to 1, i.e. they represent the most
persistent shocks. The classification is {bf:based on the geometric criterion}
|z-1| <= 1-rho, not merely on sort order.

{pstd}
{bf:Quasi-cointegrating space (QCS):}

{pmore}
QCS := S_r = (sp R_LU)^{c -}perp{c )-}

{pstd}
where R_LU is the p x q loading matrix for the near-unit eigenvalues. The QCS
collects the r = p - q linear combinations of y_t whose impulse responses
decay fastest.

{pstd}
{bf:Key theoretical results} (Duffy & Simons 2023):

{phang2}{bf:Proposition 2.2:} When all q roots are exactly unity, the QCS
coincides with the standard Johansen cointegrating space.{p_end}

{phang2}{bf:Theorem 3.1:} The loglikelihood ratio processes of the
quasi-cointegrated VAR and a predictive regression converge to the
{bf:same limiting experiment}.{p_end}

{phang2}{bf:Theorem 3.2:} The restricted MLE of beta (with correct Lambda_LU
imposed) is {bf:asymptotically mixed normal}, generalising
Johansen (1995, Thm 13.3).{p_end}

{phang2}{bf:Theorem 3.3:} The LR test for beta (given Lambda_LU) is
{bf:chi-squared(1)}, regardless of whether the dominant root equals unity.{p_end}

{pstd}
{bf:Choice of rho.} The lower bound rho is interpretable as a minimum half-life:
h = -log(2)/log(rho) periods. Guidelines:

{col 10}Setting{col 35}rho{col 50}Half-life
{col 10}{hline 55}
{col 10}Annual data, US cycles{col 35}0.917{col 50}~8 years
{col 10}Quarterly data{col 35}0.95{col 50}~13.5 quarters
{col 10}Quarterly, conservative{col 35}0.979{col 50}~33 quarters
{col 10}Monthly data{col 35}0.99{col 50}~69 months

{pstd}
{bf:Normalisation.} beta is normalised as [I_r, -A], where A contains
the free parameters. The first r variables are normalised to unity.


{marker options}{...}
{title:Options}

{dlgtab:Model specification}

{phang}
{opt rho(#)} sets the lower bound on the dominant root. This defines the
near-unit-root region L_LU. Smaller values afford greater robustness to
departures from exact unit roots, at the cost of potentially wider confidence
intervals. Interpretable as a minimum half-life constraint:
h = -log(2)/log(rho). Default: 0.95 (h ~ 13.5 periods).

{phang}
{opt nroots(#)} specifies the number of near-unit roots q. For most bivariate
applications, q = 1. For trivariate systems with two stochastic trends,
q = 2. The QCS dimension is r = p - q. Default: 1.

{phang}
{opt lags(#)} sets the VAR lag order. If 0 (default), the lag order is selected
automatically by minimising the Akaike information criterion, searching from
1 to {opt maxlags()}.

{phang}
{opt maxlags(#)} sets the maximum lag order for AIC search. Default: 8.

{phang}
{opt noconstant} suppresses the intercept in the VAR.

{phang}
{opt trend} includes a linear time trend in the VAR.

{dlgtab:Inference}

{phang}
{opt gridsize(#)} controls the number of grid points for the profile
likelihood over lambda in [rho, 1]. More points give smoother plots but take
longer to compute. Default: 50.

{phang}
{opt nboot(#)} sets the number of Monte Carlo replications for the
Elliott-Mueller-Watson nearly optimal test. Default: 2000.

{phang}
{opt level(#)} sets the confidence level for conditional and robust CIs.
Default: 95.

{dlgtab:Visualization}

{phang}
{opt plot} generates all three publication-quality plots saved as PNG:
(1) profile likelihood + conditional CIs (combined panel),
(2) impulse response functions,
(3) characteristic root map in the complex plane.

{phang}
{opt plotprofile} generates only the profile likelihood + conditional CI plot.

{phang}
{opt plotirf} generates only the IRF comparison plot.

{phang}
{opt plotroots} generates only the characteristic root map.

{phang}
{opt saving(name)} sets the filename prefix for plots and exports. Default:
"quasicoint". Files will be named {it:name}_profile.png, {it:name}_irf.png,
{it:name}_roots.png, {it:name}_quasicoint.tex, etc.

{dlgtab:Export}

{phang}
{opt export(fmt)} exports results. Options: {opt latex} (booktabs table with
significance stars), {opt csv} (comma-separated), {opt excel} (xlsx), or
{opt all} (all formats).


{marker results}{...}
{title:Stored Results}

{pstd}
{cmd:quasicoint} stores the following in {cmd:e()}.

{synoptset 24 tabbed}{...}
{p2col 5 24 26 2: {bf:Scalars}}{p_end}
{synopt:{cmd:e(N)}}number of observations used{p_end}
{synopt:{cmd:e(p)}}number of variables{p_end}
{synopt:{cmd:e(q)}}number of near-unit roots{p_end}
{synopt:{cmd:e(r)}}dimension of QCS (= p - q){p_end}
{synopt:{cmd:e(k)}}VAR lag order{p_end}
{synopt:{cmd:e(rho)}}lower bound on dominant root{p_end}
{synopt:{cmd:e(halflife)}}half-life at rho (periods){p_end}
{synopt:{cmd:e(lambda_hat)}}estimated dominant root (modulus){p_end}
{synopt:{cmd:e(LR_lambda)}}LR statistic for H0: lambda = 1{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(gridsize)}}number of grid points used{p_end}

{p2col 5 24 26 2: {bf:Matrices}}{p_end}
{synopt:{cmd:e(b)}}1 x q vector of free QCS coefficients (the A parameters){p_end}
{synopt:{cmd:e(V)}}q x q variance-covariance matrix for e(b){p_end}
{synopt:{cmd:e(beta_qcs)}}p x r quasi-cointegrating vectors (full, normalised){p_end}
{synopt:{cmd:e(beta_johansen)}}p x r Johansen cointegrating vectors (for comparison){p_end}
{synopt:{cmd:e(eigenvalues)}}kp x 3 matrix: (real part, imag part, modulus){p_end}
{synopt:{cmd:e(R_LU)}}p x q loading matrix R_LU{p_end}
{synopt:{cmd:e(Lambda_LU)}}q x q diagonal matrix of near-unit eigenvalues{p_end}
{synopt:{cmd:e(profile_ll)}}gridsize x 2 matrix: (lambda, log-likelihood){p_end}
{synopt:{cmd:e(profile_grid)}}gridsize x 1 vector of lambda grid points{p_end}
{synopt:{cmd:e(cond_ci)}}gridsize x 3 matrix: (lambda, beta_hat, SE){p_end}
{synopt:{cmd:e(IRF_qc)}}(p*H) x p impulse response matrix{p_end}
{synopt:{cmd:e(IRF_johansen)}}(p*H) x p Johansen IRF (for comparison){p_end}
{synopt:{cmd:e(np_ci)}}1 x 2 nearly optimal CI bounds (when available){p_end}

{p2col 5 24 26 2: {bf:Strings}}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:quasicoint}{p_end}
{synopt:{cmd:e(cmdline)}}full command as typed{p_end}
{synopt:{cmd:e(varlist)}}variable names{p_end}
{synopt:{cmd:e(timevar)}}time variable{p_end}
{synopt:{cmd:e(title)}}Quasi-Cointegration (Duffy & Simons 2023){p_end}
{synopt:{cmd:e(paper)}}bibliographic reference{p_end}
{synopt:{cmd:e(vcetype)}}Conditional LR (chi-squared){p_end}
{p2colreset}{...}


{marker tables}{...}
{title:Output Tables}

{pstd}
{cmd:quasicoint} displays five publication-quality tables:

{phang2}{bf:Table 1 — Characteristic Roots:} All roots of the VAR companion
matrix, with modulus, half-life, and L_LU/L_ST classification using the
geometric criterion |z-1| <= 1-rho. A {bf:WARNING} is issued if no roots
fall in the L_LU region.{p_end}

{phang2}{bf:Table 2 — QCS Vectors:} The quasi-cointegrating vector(s)
alongside Johansen estimates and their difference. When unit roots hold
exactly, the difference should be zero.{p_end}

{phang2}{bf:Table 3 — Profile Likelihood:} Summary statistics including
the estimated dominant root, LR statistic for H0: lambda=1, p-value,
and unit-root rejection/non-rejection conclusion.{p_end}

{phang2}{bf:Table 4 — Conditional CIs:} Confidence intervals for beta
conditional on each value of lambda in the grid, along with half-life
interpretation.{p_end}

{phang2}{bf:Table 5 — Robust CIs:} Elliott-Mueller-Watson nearly optimal
confidence interval and conditional CIs at lambda=1 and at the
profile-likelihood-maximising lambda.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Example 1: Basic usage — bivariate levels with near-unit root}

{phang2}{cmd:. webuse lutkepohl2, clear}{p_end}
{phang2}{cmd:. tsset qtr}{p_end}
{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95)}{p_end}

{pstd}
This estimates a VAR(k) on {it:ln_inv} and {it:ln_inc} (log levels of
investment and income), selects k via AIC, computes the dominant root
(lambda_hat ~ 0.994), identifies it as L_LU, and reports the QCS vector
beta = (1, -0.857) alongside the Johansen estimate.

{pstd}
{bf:Example 2: Three variables in levels}

{phang2}{cmd:. quasicoint ln_inv ln_inc ln_consump, rho(0.95) nroots(1)}{p_end}

{pstd}
With p=3 and q=1, the QCS has dimension r=2. The two quasi-cointegrating
vectors capture the two fastest-decaying linear combinations.

{pstd}
{bf:Example 3: Full analysis with plots and LaTeX export}

{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95) plot export(latex) saving(myresults)}{p_end}

{pstd}
Generates: {it:myresults_profile.png}, {it:myresults_irf.png},
{it:myresults_roots.png}, and {it:myresults_quasicoint.tex}.

{pstd}
{bf:Example 4: Specific lag order}

{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95) lags(4)}{p_end}

{pstd}
Forces a VAR(4) specification instead of AIC auto-selection.

{pstd}
{bf:Example 5: Term structure application (yields)}

{phang2}{cmd:. * Load your yield data}{p_end}
{phang2}{cmd:. tsset date}{p_end}
{phang2}{cmd:. quasicoint yield10y yield1y, rho(0.979) nroots(1) plot}{p_end}

{pstd}
Under the expectations hypothesis, the QCS coefficient equals
a_10(lambda) = (1/10)(1-lambda^10)/(1-lambda). At lambda=1 this gives
a_10 = 1 (standard cointegration). At lambda < 1, a_10 < 1.

{pstd}
{bf:Example 6: Profile likelihood plot only}

{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95) plotprofile saving(profile_only)}{p_end}

{pstd}
{bf:Example 7: Root map only}

{phang2}{cmd:. quasicoint ln_inv ln_inc ln_consump, rho(0.95) nroots(1) plotroots}{p_end}

{pstd}
{bf:Example 8: Post-estimation}

{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95)}{p_end}
{phang2}{cmd:. di "Dominant root: " %8.5f e(lambda_hat)}{p_end}
{phang2}{cmd:. di "LR(lambda=1): " %8.3f e(LR_lambda)}{p_end}
{phang2}{cmd:. matrix list e(b)}{p_end}
{phang2}{cmd:. matrix list e(beta_qcs)}{p_end}
{phang2}{cmd:. matrix list e(beta_johansen)}{p_end}
{phang2}{cmd:. matrix list e(eigenvalues)}{p_end}

{pstd}
{bf:Example 9: Robustness across rho values}

{phang2}{cmd:. foreach r in 0.90 0.95 0.98 0.99 {c -(}}{p_end}
{phang2}{cmd:.   qui quasicoint ln_inv ln_inc, rho(`r')}{p_end}
{phang2}{cmd:.   di "rho=`r': beta=" %8.4f e(b)[1,1] " lambda=" %8.5f e(lambda_hat)}{p_end}
{phang2}{cmd:. {c )-}}{p_end}

{pstd}
The QCS coefficient should remain stable across rho values (as demonstrated
with beta = -0.857 for all rho in the Lutkepohl dataset).

{pstd}
{bf:Example 10: Export all formats}

{phang2}{cmd:. quasicoint ln_inv ln_inc, rho(0.95) export(all) saving(results)}{p_end}


{marker diagnostics}{...}
{title:Diagnostics and Warnings}

{pstd}
{bf:WARNING: No root in L_LU.} If no characteristic root falls in the
near-unit region L_LU = {c -(}|z-1| <= 1-rho{c )-}, the data may already be
stationary. Common causes:

{phang2}(a) Variables are first differences or growth rates instead of
levels.{p_end}
{phang2}(b) The series are I(0) and cointegration analysis is
inappropriate.{p_end}
{phang2}(c) The rho bound is too tight — try a smaller value.{p_end}

{pstd}
{bf:lambda_hat < rho.} When the dominant root falls below the lower bound,
the profile likelihood is computed over [rho, 1] and the results should be
interpreted cautiously.

{pstd}
{bf:lambda_hat > 1.} An explosive root indicates possible model
misspecification (too many lags) or structural instability. The L_LU
criterion |z| <= 1 naturally excludes explosive roots.

{pstd}
{bf:QCS = Johansen.} When the difference between QCS and Johansen estimates
is exactly zero (or very small), it confirms that the unit root assumption is
appropriate for the data. This is the key validation of Proposition 2.2 in
Duffy & Simons (2023).


{marker references}{...}
{title:References}

{marker DS2023}{...}
{phang}
Duffy, J.A. & Simons, J.R. (2023).
Cointegration without Unit Roots.
{it:Cambridge Working Papers in Economics} 2332.
{browse "https://www.econ.cam.ac.uk/cwpe"}
{p_end}

{marker Elliott1998}{...}
{phang}
Elliott, G. (1998).
On the robustness of cointegration methods when regressors almost have
unit roots.
{it:Econometrica}, 66, 149-158.
{p_end}

{phang}
Elliott, G., Mueller, U.K. & Watson, M.W. (2015).
Nearly optimal tests when a nuisance parameter is present under the null.
{it:Econometrica}, 83, 771-811.
{p_end}

{phang}
Johansen, S. (1995).
{it:Likelihood-based Inference in Cointegrated Vector Autoregressive Models}.
Oxford University Press.
{p_end}

{phang}
Mueller, U.K. & Watson, M.W. (2013).
Low-frequency robust cointegration testing.
{it:Journal of Econometrics}, 174, 66-81.
{p_end}

{phang}
Phillips, P.C.B. & Hansen, B.E. (1990).
Statistical inference in instrumental variables regression with I(1)
processes.
{it:Review of Economic Studies}, 57, 99-125.
{p_end}

{phang}
Lutkepohl, H. (2005).
{it:New Introduction to Multiple Time Series Analysis}.
Springer.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr. Merwan Roudane{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
Package: {stata "search quasicoint":search quasicoint}
{p_end}

{pstd}
{it:This package implements the quasi-cointegration framework of}{break}
{it:Duffy & Simons (2023, CWPE 2332), Cambridge University.}{break}
{it:See also:} {help vec}, {help var}, {help vecrank}{break}
{it:Bug reports and suggestions: merwanroudane920@gmail.com}
{p_end}
