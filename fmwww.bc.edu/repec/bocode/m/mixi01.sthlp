{smcl}
{* *! version 1.0.0  20may2026  Dr Merwan Roudane (merwanroudane920@gmail.com)}{...}
{vieweralsosee "[R] mixi01_fmols" "help mixi01_fmols"}{...}
{vieweralsosee "[R] mixi01_fmvar" "help mixi01_fmvar"}{...}
{vieweralsosee "[R] mixi01_fmiv"  "help mixi01_fmiv"}{...}
{vieweralsosee "[R] mixi01_acl"   "help mixi01_acl"}{...}
{vieweralsosee "[R] mixi01_svar"  "help mixi01_svar"}{...}
{vieweralsosee "[R] mixi01_vecm"  "help mixi01_vecm"}{...}
{vieweralsosee "[R] mixi01_irf"   "help mixi01_irf"}{...}
{vieweralsosee "[R] mixi01_test"  "help mixi01_test"}{...}
{viewerjumpto "Description"  "mixi01##description"}{...}
{viewerjumpto "Package contents" "mixi01##contents"}{...}
{viewerjumpto "Commands"     "mixi01##commands"}{...}
{viewerjumpto "Quick start"  "mixi01##quickstart"}{...}
{viewerjumpto "References"   "mixi01##references"}{...}
{viewerjumpto "Author"       "mixi01##author"}{...}
{viewerjumpto "Also see"     "mixi01##alsosee"}{...}

{title:Title}

{p2colset 5 17 19 2}{...}
{p2col :{hi:mixi01} {hline 2}}Econometric methods for systems mixing I(0) and I(1) variables{p_end}
{p2colreset}{...}

{pstd}
{it:Scope:} {bf:every} estimator and every test in {cmd:mixi01} is purpose-built
for time series that mix {bf:stationary I(0)} and {bf:unit-root I(1)}
components.  None of the methods assume a single integration order; all of them
deliver valid inference whether a given regressor is I(0), I(1), or part of a
cointegrating relation among I(1) variables.  Higher orders of integration
(I(2) and above) are {bf:out of scope}: difference any I(2) variable to I(1)
before using these commands.


{marker description}{...}
{title:Description}

{pstd}
{cmd:mixi01} is a comprehensive Stata package for estimation and inference in
time series systems that contain a mixture of {bf:I(1)} (nonstationary,
unit-root) and {bf:I(0)} (stationary) variables.  Higher orders of integration
(I(2) and above) are out of scope; series that are I(2) should be
first-differenced to I(1) before being used as inputs.  The package implements the fully modified (FM)
estimation framework of Phillips (1995) and Kitamura and Phillips (1997),
the structural VAR methodology of Fisher, Huh and Pagan (2016) for systems
with P0/T0/P1/T1 shock classifications, and the mixed VECM of Chen (2022).

{pstd}
Standard cointegration methods typically require that {it:all} variables in a
system share the same order of integration.  In practice, macroeconomic systems
routinely mix trending and stationary variables — output, prices and interest
rates, for example.  {cmd:mixi01} provides a unified framework where the
researcher does not need to pretest variables for unit roots, determine the
dimension of the cointegration space, or separate I(1) from I(0) regressors
before estimation.

{pstd}
{bf:All commands are specialised for the mixed I(0)/I(1) setting.}  Key
features of the package include:

{p 8 12 2}
{bf:1.} Fully modified OLS, VAR, and IV/GMM/GIVE estimation that delivers
normal or mixed-normal asymptotics for {it:all} coefficient estimates,
irrespective of whether each regressor is {bf:I(0)} or {bf:I(1)}.

{p 8 12 2}
{bf:2.} The Augmented Cointegrating Linear (ACL) plain-OLS estimator of Peng
and Dong (2021) for the same {bf:I(0)/I(1)} mix, with self-normalised
inference that does not require any kernel/bandwidth choice.

{p 8 12 2}
{bf:3.} Structural VAR identification with the Fisher–Huh–Pagan (2016)
four-way shock classification: P1 (permanent from {bf:I(1)} equations),
T1 (transitory from {bf:I(1)} equations), P0 (permanent from {bf:I(0)}
equations), and T0 (transitory from {bf:I(0)} equations).

{p 8 12 2}
{bf:4.} Wald-type hypothesis tests — including Granger causality — that remain
valid regardless of the number of unit roots in a mixed {bf:I(0)/I(1)}
system.  The conservative chi-squared upper bound of Phillips (1995,
Theorem 6.1) is always available, together with a liberal bound based on
{it:Omega_ee.2}.

{p 8 12 2}
{bf:5.} Impulse-response functions and forecast-error variance decompositions
for mixed {bf:I(0)/I(1)} SVARs, with bootstrap confidence intervals and
P0/T0 shock labels, plotted in a publication-quality grid layout.

{p 8 12 2}
{bf:6.} A mixed VECM estimator following Chen (2022) that extends the
Johansen procedure to systems containing both {bf:I(0)} and {bf:I(1)}
components, with explicit decomposition of {it:beta} into true and
pseudo-cointegrating subspaces.


{marker contents}{...}
{title:Package contents}

{pstd}
{cmd:mixi01} is organised as a master command with eight public sub-commands.
{bf:Every command in the table below is specialised for systems that mix
I(0) and I(1) variables} — none requires the user to commit to a single
integration order ex ante.  Click any name to jump to that command's help
page.

{synoptset 24 tabbed}{...}
{synopthdr:command}
{synoptline}
{syntab:Estimation (mixed I(0)/I(1) regressors)}
{synopt :{helpb mixi01_fmols}}Fully Modified OLS — mixed I(0)/I(1) regression with FM endogeneity + serial-correlation correction (Phillips 1995){p_end}
{synopt :{helpb mixi01_fmvar}}Fully Modified VAR — levels VAR with I(0)/I(1) variables; no unit-root distributions (Phillips 1995){p_end}
{synopt :{helpb mixi01_fmiv}}Fully Modified IV / GIVE / GMM — mixed I(0)/I(1) endogenous regressors and instruments (Kitamura & Phillips 1997){p_end}
{synopt :{helpb mixi01_acl}}Augmented Cointegrating Linear — plain-OLS with self-normalised inference for strongly correlated I(0)/I(1) regressors (Peng & Dong 2021){p_end}
{synopt :{helpb mixi01_svar}}Structural VAR — P1/T1/P0/T0 shock identification in mixed I(0)/I(1) systems (Fisher, Huh & Pagan 2016){p_end}
{synopt :{helpb mixi01_vecm}}Mixed VECM — Johansen procedure extended to systems with both I(0) and I(1) variables (Chen 2022){p_end}

{syntab:Post-estimation (mixed I(0)/I(1)-aware)}
{synopt :{helpb mixi01_irf}}Impulse-response functions and FEVD with bootstrap CIs and P0/T0 shock labels for mixed I(0)/I(1) SVARs{p_end}
{synopt :{helpb mixi01_test}}Wald / Granger / permanence tests with the mixed chi-squared limit theory of Phillips (1995, Thm 6.1) — valid for any I(0)/I(1) mix{p_end}
{synoptline}

{pstd}
The master command {cmd:mixi01} also accepts each name as a subcommand
({cmd:mixi01 fmols ...}, {cmd:mixi01 svar ...}, etc.) for users who prefer
that style.


{marker commands}{...}
{title:Commands}

{pstd}
Each command below is purpose-built for systems mixing {bf:I(0)} and
{bf:I(1)} variables.

{synoptset 24 tabbed}{...}
{synopt :{helpb mixi01_fmols}}Fully Modified OLS regression with mixed
{bf:I(0)/I(1)} regressors and kernel-based FM corrections for endogeneity
and serial correlation (Phillips, 1995, Sections 3–4){p_end}

{synopt :{helpb mixi01_fmvar}}Fully Modified VAR: unrestricted levels VAR
in mixed {bf:I(0)/I(1)} variables — no unit-root distributions in the limit
theory (Phillips, 1995, Section 5){p_end}

{synopt :{helpb mixi01_fmiv}}Fully Modified IV, GIVE and GMM with endogenous
regressors and instruments that may be a mix of {bf:I(0)} and {bf:I(1)}
processes (Kitamura and Phillips, 1997){p_end}

{synopt :{helpb mixi01_acl}}Augmented Cointegrating Linear regression with
plain OLS and self-normalised inference for strongly correlated {bf:I(0)}
and {bf:I(1)} regressors (Peng and Dong, 2021){p_end}

{synopt :{helpb mixi01_svar}}Structural VAR with P1/T1/P0/T0 shock
identification for mixed {bf:I(0)/I(1)} systems (Fisher, Huh and Pagan,
2016){p_end}

{synopt :{helpb mixi01_vecm}}Mixed VECM extending the Johansen procedure to
systems with both {bf:I(0)} and {bf:I(1)} variables (Chen, 2022){p_end}

{synopt :{helpb mixi01_irf}}Impulse-response functions and FEVD with
bootstrap confidence intervals and P0/T0 shock labels for mixed
{bf:I(0)/I(1)} SVARs (Fisher-Huh-Pagan 2016){p_end}

{synopt :{helpb mixi01_test}}Wald tests (Granger causality, general linear
restrictions, permanence tests) using the mixed chi-squared limit theory of
Phillips (1995, Theorem 6.1) — valid for any {bf:I(0)/I(1)} mix{p_end}
{synoptline}


{marker quickstart}{...}
{title:Quick start}

{dlgtab:FM-OLS regression}

{phang2}{cmd:. mixi01_fmols y x1 x2 x3, i1(x1 x2) i0(x3) kernel(bartlett) bw(4)}{p_end}

{dlgtab:FM-VAR estimation}

{phang2}{cmd:. mixi01_fmvar y1 y2 y3, lags(2) i1(y1 y2) i0(y3) kernel(parzen) bw(auto)}{p_end}

{dlgtab:FM-IV / FM-GMM estimation}

{phang2}{cmd:. mixi01_fmiv y x1 x2, iv(z1 z2 z3) i1(x1 z1 z2) i0(x2 z3) method(gmm)}{p_end}

{dlgtab:Augmented Cointegrating Linear regression (Peng-Dong)}

{phang2}{cmd:. mixi01_acl y x1 x2 z1, i1(x1 x2) i0(z1)}{p_end}

{dlgtab:Structural VAR with shock classification}

{phang2}{cmd:. mixi01_svar y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) p1(1) t1(2 3) p0(4)}{p_end}

{dlgtab:Mixed VECM}

{phang2}{cmd:. mixi01_vecm y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) rank(1)}{p_end}

{dlgtab:Granger causality test}

{phang2}{cmd:. mixi01_fmvar y1 y2 y3, lags(2) i0(y3)}{p_end}
{phang2}{cmd:. mixi01_test, granger(y2) conservative}{p_end}

{dlgtab:Impulse-response plot}

{phang2}{cmd:. mixi01_svar y1 y2 y3 y4, lags(2) i1(y1 y2 y3) i0(y4) p1(1) t1(2 3) p0(4)}{p_end}
{phang2}{cmd:. mixi01_irf, step(40) ci nreps(500) combine}{p_end}


{marker references}{...}
{title:References}

{phang}
Phillips, P. C. B. (1995).  Fully modified least squares and vector
autoregression.  {it:Econometrica}, 63(5), 1023–1078.
{p_end}

{phang}
Kitamura, Y. and P. C. B. Phillips (1997).  Fully modified IV, GIVE and GMM
estimation with possibly non-stationary regressors and instruments.
{it:Journal of Econometrics}, 80(1), 85–123.
{p_end}

{phang}
Fisher, L. A., H.-S. Huh and A. R. Pagan (2016).  Econometric methods for
modelling systems with a mixture of I(1) and I(0) variables.
{it:Journal of Applied Econometrics}, 31(5), 892–911.
{p_end}

{phang}
Fisher, L. A., H.-S. Huh and A. R. Pagan (2022).  Structural analysis
with mixed-frequency data.  Working Paper.
{p_end}

{phang}
Chen, P. (2022).  Vector error correction models with stationary and
nonstationary variables.  SSRN Working Paper No. 4218834.
{p_end}

{phang}
Peng, Z. and C. Dong (2021).  Augmented cointegrating linear models with
possibly strongly correlated stationary and nonstationary regressors.
SSRN Working Paper No. 3943779.
{p_end}


{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
Department of Economics (Independent Researcher){break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}
{p_end}

{pstd}
Bug reports, suggestions, and citations of empirical work using {cmd:mixi01}
are warmly welcome by email.
{p_end}


{marker alsosee}{...}
{title:Also see}

{pstd}
Sub-command help pages — {helpb mixi01_fmols}, {helpb mixi01_fmvar},
{helpb mixi01_fmiv}, {helpb mixi01_acl}, {helpb mixi01_svar},
{helpb mixi01_vecm}, {helpb mixi01_irf}, {helpb mixi01_test}.
{p_end}

{pstd}
Stata base commands — {helpb var}, {helpb svar}, {helpb vec},
{helpb regress}, {helpb ivregress}, {helpb dfuller}.
{p_end}
