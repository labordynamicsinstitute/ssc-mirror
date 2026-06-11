{smcl}
{* May 2026 — v1.0.0}{...}
{cmd:help qnardl}
{hline}

{title:Title}

{phang}
{bf:qnardl} {hline 2} Quantile Nonlinear Autoregressive Distributed Lag model
of {bf:Cho, Greenwood-Nimmo, Kim and Shin (2020)} with bounds testing, Wald
symmetry tests, dynamic multipliers, CUSUM/CUSUM² stability checks and
post-estimation diagnostics


{title:Syntax}

{p 8 17 2}
{cmd:qnardl} {it:depvar} {it:indepvars} {ifin} {cmd:,}
{cmdab:dec:ompose(}{it:varlist}{cmd:)}
{cmdab:tau(}{it:numlist}{cmd:)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{cmdab:dec:ompose(}{it:varlist}{cmd:)}}variables in {it:indepvars} to be
partial-sum decomposed into (+) and (−) regimes (Shin/Yu/Greenwood-Nimmo 2014){p_end}
{synopt:{cmdab:tau(}{it:numlist}{cmd:)}}quantile grid, each in (0,1) sorted{p_end}

{syntab:Estimator choice}
{synopt:{cmdab:two:step}}two-step QNARDL: FM-quantile long-run + qreg ECM (default; Cho et al. 2020a){p_end}
{synopt:{cmdab:one:step}}single-step QNARDL: direct qreg on the URECM (Bertsatos et al. 2022){p_end}
{synopt:{cmdab:step1(}{it:type}{cmd:)}}long-run engine for two-step: {cmd:fmqr} (default; Xiao 2009 via {help xqcoint}) | {cmd:qr} | {cmd:augfmqr}{p_end}
{synopt:{cmdab:bw:idth(}{it:#}{cmd:)}}kernel bandwidth for FM long-run variance (default 2·T^(1/3)){p_end}

{syntab:Lag specification}
{synopt:{cmdab:la:gs(}{it:p q [r]}{cmd:)}}user-supplied lag orders. {it:p} = AR lags of Δy; {it:q} = DL lags of Δx⁺/Δx⁻; {it:r} = DL lags of Δ(linear regressors){p_end}
{synopt:{cmdab:ma:xlags(}{it:numlist}{cmd:)}}max lags for IC-based selection; one to three values for pmax, qmax, rmax{p_end}
{synopt:{cmd:bic} | {cmd:aic} | {cmd:hqic}}information criterion for lag selection (default {cmd:bic}){p_end}
{synopt:{cmd:dots}}print every grid point during the IC search{p_end}

{syntab:Deterministic factors (Bertsatos 2022 cases I–XI)}
{synopt:{cmdab:noc:onstant}}exclude intercept{p_end}
{synopt:{cmdab:tr:endvar}{cmd:[(}{it:var}{cmd:)]}}include a linear trend (uses {help tsset} timevar if no arg){p_end}
{synopt:{cmdab:quad:ratictrend}}include a quadratic trend t²{p_end}
{synopt:{cmdab:res:tricted}}restrict deterministic factors to the long-run equation{p_end}
{synopt:{cmdab:cas:e(}{it:#}{cmd:)}}override case inference, force Bertsatos case 1..11{p_end}
{synopt:{cmdab:thr:eshold(}{it:#|numlist}{cmd:)}}threshold for partial-sum decomposition (default 0){p_end}
{synopt:{cmdab:e:xog(}{it:varlist}{cmd:)}}strictly exogenous regressors (e.g. crisis dummies){p_end}

{syntab:Bounds testing and Wald tests}
{synopt:{cmd:bounds}}PSS F-test (F_yx, F_x) and t-test (t_y) at each τ with verdict from Bertsatos 2022 CV table{p_end}
{synopt:{cmdab:lrsym:metry}}Long-run sign-symmetry test per τ + JOINT test across all asymmetric regressors{p_end}
{synopt:{cmdab:srsym:metry}}Short-run additive symmetry test per τ + JOINT test{p_end}
{synopt:{cmdab:interp:ercentile}}Interquartile (3 quartiles) χ² equality of level coefficients across τ{p_end}
{synopt:{cmdab:interd:ecile}}Interdecile (9 deciles) χ² equality across τ{p_end}
{synopt:{cmdab:sim:ulate(}{it:#}{cmd:)}}simulate exact PSS CVs at (T, k) with # Monte-Carlo reps (TODO v1.1){p_end}

{syntab:Dynamic multipliers and stability}
{synopt:{cmd:multipliers}}compute cumulative response paths m⁺(h), m⁻(h) per τ{p_end}
{synopt:{cmdab:hor:izon(}{it:#}{cmd:)}}horizon for dynamic multipliers (default 12){p_end}
{synopt:{cmd:cusum}}CUSUM and CUSUM² recursive-residual stability tests with 5% Brown-Durbin-Evans bands{p_end}
{synopt:{cmdab:cusumt:au(}{it:#}{cmd:)}}quantile at which to run CUSUM (default 0.5){p_end}
{synopt:{cmdab:diag:nostics}}post-estimation tests per τ: Breusch-Godfrey, Breusch-Pagan, Jarque-Bera, Ramsey RESET{p_end}
{synopt:{cmdab:bgl:ags(}{it:#}{cmd:)}}lag order for the BG serial-correlation test (default 4){p_end}

{syntab:Reporting and graphs}
{synopt:{cmd:graph}}produce the standard 3-panel quantile-process plot at end of run{p_end}
{synopt:{cmd:full}}show the short-run/URECM table for ALL quantiles (default: median only){p_end}
{synopt:{cmdab:noct:able}}suppress coefficient table{p_end}
{synopt:{cmdab:nohe:ader}}suppress header{p_end}
{synopt:{cmd:level(}{it:#}{cmd:)}}set confidence level (default 95){p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:qnardl} estimates the {bf:Quantile Nonlinear Autoregressive Distributed
Lag} model — a quantile-regression generalisation of NARDL that admits both:

{phang2}- {bf:Sign asymmetry} via the partial-sum decomposition of selected
regressors into positive and negative cumulative changes (Shin, Yu &
Greenwood-Nimmo 2014); and{p_end}

{phang2}- {bf:Locational (quantile) asymmetry} by estimating the long-run and
short-run dynamics at user-specified quantiles τ of the conditional
distribution of the dependent variable (Cho, Kim & Shin 2015).{p_end}


{title:Mathematical specification}

{pstd}
Let {it:y_t} be the dependent variable and decompose each chosen regressor x_j
into partial sums of positive and negative first differences:

{phang2}x_jt⁺ = Σ_{s=1..t} max(Δx_js − τ_j, 0){p_end}
{phang2}x_jt⁻ = Σ_{s=1..t} min(Δx_js − τ_j, 0){p_end}

{pstd}
where τ_j is the threshold (option {opt threshold}, default 0).

{pstd}
The {bf:unrestricted error-correction representation} (URECM) at quantile τ:

{phang2}Δy_t = γ(τ) + γ₁(τ)·t + γ₂(τ)·t²{p_end}
{phang2}      + φ_y(τ)·y_{t-1}{p_end}
{phang2}      + Σ_j [φ_j⁺(τ)·x_jt-1⁺ + φ_j⁻(τ)·x_jt-1⁻]{p_end}
{phang2}      + δ(τ)′·lin_{t-1}{p_end}
{phang2}      + ψ(τ)′·exog_t{p_end}
{phang2}      + Σ_{i=1..p-1} λ_i(τ)·Δy_{t-i}{p_end}
{phang2}      + Σ_j Σ_{i=0..q-1} [a_ij⁺(τ)·Δx_jt-i⁺ + a_ij⁻(τ)·Δx_jt-i⁻]{p_end}
{phang2}      + Σ_j Σ_{i=0..r-1} ω_ij(τ)·Δlin_{jt-i}{p_end}
{phang2}      + ε_t(τ){p_end}

{pstd}
The {bf:long-run multipliers} are:

{phang2}β_j⁺(τ) = −φ_j⁺(τ)/φ_y(τ),   β_j⁻(τ) = −φ_j⁻(τ)/φ_y(τ){p_end}

{pstd}
{cmd:Sign symmetry test}: H₀: β_j⁺(τ) = β_j⁻(τ) (equivalently φ_j⁺ = φ_j⁻).
{cmd:Asymmetry magnitude}: β_j⁺(τ) − β_j⁻(τ).


{title:Two estimation strategies}

{pstd}
{bf:1. Two-step (default, {opt twostep}).}  Following Cho, Greenwood-Nimmo,
Kim & Shin (2020a), the long-run parameters are estimated by {bf:FM-quantile
regression} (Xiao 2009, via {help xqcoint}) under the re-parameterisation
{it:λ = β⁻, η = β⁺ − β⁻} that kills the asymptotic singularity from the
partial-sum decomposition. The cointegration residual u_hat_{t-1}(τ) is plugged
into a quantile ECM estimated by {help qreg}. Long-run Wald tests on
β⁺(τ) − β⁻(τ) follow standard χ² because the long-run estimator is
T-consistent and mixed-normal.

{pstd}
{bf:2. Single-step ({opt onestep}).}  Following Bertsatos, Sakellaris & Tsionas
(2022 eq. 13), the URECM above is estimated directly by quantile regression at
each τ. PSS-style bounds testing is conducted using simulated critical values
from that paper (cases I–XI, k=0..13, embedded for the most common
configurations).


{title:Bertsatos 2022 deterministic cases}

{synoptset 8}{...}
{synopt:Case I}no intercept, no trend{p_end}
{synopt:Case II}restricted intercept, no trend{p_end}
{synopt:Case III}unrestricted intercept, no trend  (default){p_end}
{synopt:Case IV}unrestricted intercept + restricted linear trend{p_end}
{synopt:Case V}unrestricted intercept + unrestricted linear trend{p_end}
{synopt:Case VI / VII}intercept + trend in DGP, alternative restrictions{p_end}
{synopt:Case VIII}intercept + linear + restricted quadratic trend{p_end}
{synopt:Case IX}intercept + linear + unrestricted quadratic trend{p_end}
{synopt:Case X / XI}quadratic-trend variants of VI / VII{p_end}


{title:Examples}

{dlgtab:Quick start}

{phang2}{cmd:. tsset t}{p_end}
{phang2}{cmd:. qnardl y x1 x2, decompose(x1 x2) tau(0.25 0.5 0.75)}{p_end}

{dlgtab:Default two-step (FM-quantile) with full test battery}

{phang2}{cmd:. qnardl pb zscore dpr growth,}
{cmd:        decompose(zscore dpr growth)}
{cmd:        tau(0.1(0.1)0.9)}
{cmd:        maxlags(6) bic}
{cmd:        trendvar}
{cmd:        bounds lrsymmetry srsymmetry interpercentile}
{cmd:        multipliers horizon(20)}
{cmd:        cusum cusumtau(0.5)}
{cmd:        diagnostics bglags(4)}
{cmd:        graph}{p_end}

{dlgtab:Single-step QNARDL with quadratic trend (Bertsatos 2022 case IX)}

{phang2}{cmd:. qnardl pb zscore dpr growth,}
{cmd:        decompose(zscore dpr growth)}
{cmd:        tau(0.25 0.5 0.75)}
{cmd:        onestep trendvar quadratictrend}
{cmd:        exog(crisis_dummy)}
{cmd:        bounds lrsymmetry srsymmetry}{p_end}

{dlgtab:Replay with the full short-run table at every τ}

{phang2}{cmd:. qnardl, full}{p_end}

{dlgtab:Plot any graph type stand-alone after estimation}

{phang2}{cmd:. qnardl_graph , type(beta)         }{it:// β⁺/β⁻ quantile process per variable}{p_end}
{phang2}{cmd:. qnardl_graph , type(ect)          }{it:// φ_y(τ) with CI band}{p_end}
{phang2}{cmd:. qnardl_graph , type(asymmetry)    }{it:// β⁺(τ) − β⁻(τ) for each variable}{p_end}
{phang2}{cmd:. qnardl_graph , type(all)          }{it:// combined 4-panel layout}{p_end}
{phang2}{cmd:. qnardl_mgraph                     }{it:// dynamic multipliers at median τ}{p_end}
{phang2}{cmd:. qnardl_mgraph , tau(0.75)         }{it:// at a specific quantile}{p_end}
{phang2}{cmd:. qnardl_cgraph                     }{it:// CUSUM only}{p_end}
{phang2}{cmd:. qnardl_cgraph , cusumsq           }{it:// CUSUM² only}{p_end}
{phang2}{cmd:. qnardl_cgraph , both              }{it:// CUSUM + CUSUM² side-by-side}{p_end}
{phang2}{cmd:. qnardl_showall                    }{it:// display every saved qnardl graph as tabs}{p_end}


{title:Stored results}

{pstd}{cmd:qnardl} stores the following in {cmd:e()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(k)}}number of asymmetric regressors{p_end}
{synopt:{cmd:e(k_lin)}}number of linear (non-decomposed) regressors{p_end}
{synopt:{cmd:e(ntau)}}number of quantiles{p_end}
{synopt:{cmd:e(case)}}Bertsatos case 1..11{p_end}
{synopt:{cmd:e(p_lag) e(q_lag) e(r_lag)}}selected/specified lag orders{p_end}
{synopt:{cmd:e(level)}}confidence level{p_end}
{synopt:{cmd:e(horizon_mult)}}multiplier horizon (if {opt multipliers} used){p_end}
{synopt:{cmd:e(cv_F_lo) e(cv_F_hi)}}embedded Bertsatos F-test 5% bounds{p_end}
{synopt:{cmd:e(cv_t_lo) e(cv_t_hi)}}embedded Bertsatos t-test 5% bounds{p_end}

{p2col 5 22 26 2: Matrices}{p_end}
{synopt:{cmd:e(b_lr_pos)}}long-run β⁺(τ), ntau × k_asym{p_end}
{synopt:{cmd:e(b_lr_neg)}}long-run β⁻(τ), ntau × k_asym{p_end}
{synopt:{cmd:e(t_lr_pos)}}t-statistic for β⁺(τ) (or asymmetry t under twostep){p_end}
{synopt:{cmd:e(t_lr_neg)}}t-statistic for β⁻(τ){p_end}
{synopt:{cmd:e(phi_y)}}ECT speed-of-adjustment per τ, ntau × 2 (coef, SE){p_end}
{synopt:{cmd:e(b_sr) e(V_sr)}}short-run ECM coefs (twostep only){p_end}
{synopt:{cmd:e(b_urecm) e(V_urecm)}}URECM coefs (onestep only){p_end}
{synopt:{cmd:e(bounds)}}F_yx, F_x, t_y, p-values, verdict per τ (if {opt bounds}){p_end}
{synopt:{cmd:e(mult_pos) e(mult_neg)}}cumulative response paths m⁺_jh(τ), m⁻_jh(τ) (if {opt multipliers}){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:qnardl}{p_end}
{synopt:{cmd:e(method)}}{cmd:twostep} or {cmd:onestep}{p_end}
{synopt:{cmd:e(step1)}}long-run engine used (twostep only){p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(asymvars)}}original (pre-decomposition) asymmetric variable names{p_end}
{synopt:{cmd:e(pos_vars) e(neg_vars)}}generated partial-sum variable names{p_end}


{title:Interpretation guide}

{phang}{bf:Long-run β⁺(τ) and β⁻(τ)} measure the cumulative impact on y of a
unit positive or negative shock to x in the long run, conditional on the τ-th
quantile of y. Sign asymmetry exists when β⁺(τ) ≠ β⁻(τ); test with {opt lrsymmetry}.

{phang}{bf:Speed-of-adjustment φ_y(τ)} measures the per-period correction
toward long-run equilibrium. Negative and statistically significant ⇒
cointegration is operating at quantile τ. |1 + φ_y(τ)| < 1 implies stable
convergence.

{phang}{bf:Bounds verdict} per τ: "cointegration" (F > I(1) bound),
"inconclusive" (between bounds), "no cointegration" (F < I(0) bound). Computed
against the Bertsatos et al. 2022 simulated critical values.

{phang}{bf:Dynamic multipliers} m⁺(h), m⁻(h) show the cumulative response of y
over horizon h to a unit positive (negative) shock in x⁺ (x⁻). Asymptotes
converge to β⁺(τ), β⁻(τ).

{phang}{bf:CUSUM / CUSUM²} tests detect parameter instability over the sample
period. Breaches outside the 5% Brown-Durbin-Evans bands indicate structural
change.

{phang}{bf:Diagnostics}: BG p-value < 0.05 rejects no serial correlation; BPG
< 0.05 rejects homoskedasticity; JB < 0.05 rejects normality. RESET tests
functional-form adequacy.


{title:Dependencies}

{phang}- {bf:Stata 14.0+} (qreg with quantile() option){p_end}
{phang}- {bf:qcointlib} ({stata "ssc install qcointlib":ssc install qcointlib}) — for FM-quantile estimation via {help xqcoint} (only required when using the default {opt twostep} estimator with {opt step1(fmqr)}; the package falls back to plain qreg otherwise){p_end}


{title:Companion commands}

{phang}{bf:qnardl_graph} — quantile-process plots (β, ECT, asymmetry, all){p_end}
{phang}{bf:qnardl_mgraph} — dynamic multipliers per quantile{p_end}
{phang}{bf:qnardl_cgraph} — CUSUM and CUSUM² stability plots{p_end}
{phang}{bf:qnardl_showall} — re-display every saved qnardl graph as tabs{p_end}


{title:Author}

{pstd}
{bf:Dr Merwan Roudane}{break}
{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{break}
May 2026 — v1.0.0

{pstd}
Please cite this package as:

{phang2}
Roudane, M. (2026). {bf:qnardl}: Stata implementation of the Cho,
Greenwood-Nimmo, Kim & Shin (2020) Quantile Nonlinear ARDL model with bounds
testing, Wald symmetry tests, dynamic multipliers, CUSUM and diagnostics.
Stata package v1.0.0.{p_end}


{title:References}

{phang}Bertsatos, G., Sakellaris, P. & Tsionas, M. G. (2022). Extensions of
the Pesaran, Shin and Smith (2001) bounds testing procedure.
{it:Empirical Economics} 62, 605–634.

{phang}Brown, R. L., Durbin, J. & Evans, J. M. (1975). Techniques for testing
the constancy of regression relationships over time. {it:Journal of the Royal
Statistical Society, Series B} 37, 149–192.

{phang}Cho, J. S., Greenwood-Nimmo, M., Kim, T.-h. & Shin, Y. (2020a). Hawks,
doves and asymmetry in US monetary policy: Evidence from a dynamic quantile
regression model. Mimeo, University of York.

{phang}Cho, J. S., Greenwood-Nimmo, M. & Shin, Y. (2019). Two-step estimation
of the nonlinear autoregressive distributed lag model. Working paper, Yonsei
University.

{phang}Cho, J. S., Greenwood-Nimmo, M. & Shin, Y. (2021). Recent developments
of the autoregressive distributed lag modelling framework. Working paper.

{phang}Cho, J. S., Kim, T.-h. & Shin, Y. (2015). Quantile cointegration in
the autoregressive distributed-lag modeling framework.
{it:Journal of Econometrics} 188, 281–300.

{phang}Pesaran, M. H., Shin, Y. & Smith, R. J. (2001). Bounds testing
approaches to the analysis of level relationships.
{it:Journal of Applied Econometrics} 16, 289–326.

{phang}Shin, Y., Yu, B. & Greenwood-Nimmo, M. J. (2014). Modelling asymmetric
cointegration and dynamic multipliers in a nonlinear ARDL framework. In:
{it:Festschrift in Honor of Peter Schmidt}, eds. Horrace & Sickles, Springer.

{phang}Xiao, Z. (2009). Quantile cointegrating regression.
{it:Journal of Econometrics} 150, 248–260.


{title:Also see}

{psee}
{help qnardl_graph}, {help qnardl_mgraph}, {help qnardl_cgraph},
{help qnardl_showall}, {help ardl} (Kripfganz–Schneider), {help twostep_nardl},
{help qardl}, {help xqcoint}, {help qcointlib}
