{smcl}
{* *! version 1.0.0  19jul2026}{...}
{vieweralsosee "regbreak methods" "help regbreak_methods"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "regbreak##syntax"}{...}
{viewerjumpto "Description" "regbreak##description"}{...}
{viewerjumpto "Options" "regbreak##options"}{...}
{viewerjumpto "Interpreting the output" "regbreak##interpret"}{...}
{viewerjumpto "Remarks" "regbreak##remarks"}{...}
{viewerjumpto "Examples" "regbreak##examples"}{...}
{viewerjumpto "Stored results" "regbreak##results"}{...}
{viewerjumpto "References" "regbreak##refs"}{...}
{viewerjumpto "Author" "regbreak##author"}{...}
{title:Title}

{phang}
{bf:regbreak} {hline 2} Estimation and inference for structural breaks in the
coefficients and error variance of a linear regression

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:regbreak} {it:depvar} [{it:indepvars}] {ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt x(varlist)}}regressors whose coefficients are {it:constant} across
regimes (partial structural change model); {it:indepvars} are those whose
coefficients {it:change} across regimes.{p_end}
{synopt:{opt noconstant}}suppress the changing intercept.{p_end}
{synopt:{opt maxb(#)}}maximum number of coefficient breaks; default {cmd:maxb(5)}.{p_end}
{synopt:{opt maxv(#)}}maximum number of variance breaks (joint mode); default {cmd:maxv(2)}.{p_end}
{synopt:{opt trim(#)}}trimming {it:{c 949}}; one of {cmd:0.05}, {cmd:0.10},
{cmd:0.15}, {cmd:0.20}, {cmd:0.25}; default {cmd:trim(0.15)}.{p_end}

{syntab:Procedure}
{synopt:{opt joint}}run the joint variance{c 43}coefficient tests of Perron,
Yamamoto & Zhou; the default runs the Bai & Perron (1998) coefficient-break
analysis.{p_end}
{synopt:{opt ic(string)}}information criterion selecting the number of breaks:
{cmd:BIC}, {cmd:LWZ} or {cmd:KT}; default {cmd:KT}.{p_end}
{synopt:{opt fixn(#)}}estimate a model with a pre-specified number of breaks.{p_end}
{synopt:{opt signif(#)}}significance level for sequential selection: {cmd:1}=10%,
{cmd:2}=5%, {cmd:3}=2.5%, {cmd:4}=1%; default {cmd:signif(2)}.{p_end}

{syntab:Covariance / error structure}
{synopt:{opt robust(#)}}heteroskedasticity- and autocorrelation-consistent
covariance ({cmd:1}) or i.i.d. ({cmd:0}); default {cmd:1}.{p_end}
{synopt:{opt vrobust(#)}}robust variant for the variance-break statistics (joint
mode); default {cmd:1}.{p_end}
{synopt:{opt prewhite(#)}}AR(1) prewhitening of the long-run covariance; default
{cmd:1} (Bai-Perron) or {cmd:0} (joint).{p_end}
{synopt:{opt hetdat(#)}}allow segment-specific moment matrices; default {cmd:1}.{p_end}
{synopt:{opt hetvar(#)}}allow segment-specific residual variances; default {cmd:1}.{p_end}
{synopt:{opt hetomega(#)}}segment-specific long-run variances for the break-date
CIs; default {cmd:1}.{p_end}
{synopt:{opt hetq(#)}}segment-specific data moment matrices for the break-date
CIs; default {cmd:1}.{p_end}
{synopt:{opt typek(#)}}kernel construction for the joint statistics: {cmd:0}=under
H0, {cmd:1}=under H1, {cmd:2}=hybrid; default {cmd:2}.{p_end}

{syntab:Reporting}
{synopt:{opt graph}}draw the fitted-regime plot (Bai-Perron mode).{p_end}
{synopt:{opt gname(name)}}name for the graph.{p_end}
{synopt:{opt level(#)}}confidence level; default {cmd:level(95)}.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}{it:depvar} and {it:indepvars} may contain time-series operators; the data
are treated as an ordered time series.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:regbreak} estimates and tests for multiple structural changes in a linear
regression. Two complementary procedures are provided in one command:

{phang2}
{bf:Default (Bai & Perron 1998)} {hline 1} tests for breaks in the {it:regression
coefficients}. It reports the Sup F tests of no break versus a fixed number of
breaks, the {help regbreak_methods##udmax:UDmax} double-maximum test, the
sequential Sup F(l+1|l) tests, and the number of breaks selected by the BIC, LWZ
and KT information criteria. It then estimates the selected model, giving the
break dates with confidence intervals and the regime-specific coefficients with
heteroskedasticity- and autocorrelation-corrected standard errors.

{phang2}
{bf:Joint ({opt joint}) {hline 1} Perron, Yamamoto & Zhou} tests jointly for
breaks in the {it:error variance} and the {it:coefficients}. It reports the
Sup LR4 joint statistic, the marginal Sup LR / Sup LR3 (coefficient breaks given
variance breaks) and Sup LR1 / Sup LR2 (variance breaks given coefficient
breaks), the UDmax4 test, and the sequential SeqLR9 / SeqLR10 procedures that
select the number of coefficient and variance breaks and their dates.

{pstd}
The estimation and testing machinery reproduces the authors' reference programs
(the {cmd:mbreaks} R package and the Perron{c 45}Yamamoto{c 45}Zhou MATLAB code)
numerically. The equation-by-equation correspondence is documented in
{help regbreak_methods:{bf:help regbreak methods}}.

{marker options}{...}
{title:Options}

{dlgtab:Model}

{phang}
{opt x(varlist)} lists regressors whose coefficients are held {it:constant} across
regimes, turning the model into a partial structural change model. The
{it:indepvars} in the command line are the regressors whose coefficients are
allowed to {it:change} at every break. With no {it:indepvars} and no
{opt noconstant}, {cmd:regbreak} fits a pure mean-shift model.

{phang}
{opt maxb(#)} sets the largest number of coefficient breaks considered. The
tabulated critical values allow up to 10 breaks at {cmd:trim(0.05)}, 8 at
{cmd:0.10}, 5 at {cmd:0.15}, 3 at {cmd:0.20} and 2 at {cmd:0.25}.

{phang}
{opt maxv(#)} sets the largest number of variance breaks in {opt joint} mode.
Joint critical values are tabulated for {cmd:trim(0.05)} and {cmd:trim(0.10)}.

{phang}
{opt trim(#)} is the minimal segment length as a fraction of the sample. It
determines the critical values and the smallest admissible regime.

{dlgtab:Procedure}

{phang}
{opt joint} switches from the Bai{c 45}Perron coefficient-break analysis to the
Perron{c 45}Yamamoto{c 45}Zhou joint variance-and-coefficient tests.

{phang}
{opt ic(BIC|LWZ|KT)} chooses which information criterion selects the number of
breaks that is then estimated. {cmd:KT} is the modified Bayesian criterion of
Kurozumi & Tuvaandorj (2011); {cmd:LWZ} is Liu, Wu & Zidek (1997); {cmd:BIC} is
Yao (1988).

{phang}
{opt fixn(#)} overrides the information criterion and estimates a model with
exactly {it:#} breaks.

{dlgtab:Covariance}

{phang}
{opt robust(#)}, {opt hetdat(#)}, {opt hetvar(#)}, {opt hetomega(#)},
{opt hetq(#)}, {opt prewhite(#)}, {opt vrobust(#)} and {opt typek(#)} control the
assumptions on the errors used to build the test statistics, the corrected
standard errors and the break-date confidence intervals. See
{help regbreak_methods##errors:{bf:help regbreak methods}} for the exact role of
each. Do {ul:not} set {opt robust(1)} when lagged dependent variables enter as
regressors.

{marker interpret}{...}
{title:Interpreting the output}

{pstd}
{bf:Bai-Perron mode} prints four blocks:

{phang2}(a) {bf:Sup F} of no break versus {it:m} breaks, with critical values at
10/5/2.5/1%. Stars flag rejection at 10 ({it:*}), 5 ({it:**}) and 1% ({it:***}).{p_end}
{phang2}(b) {bf:Sequential Sup F(l+1|l)}: the first {it:l} for which the test
fails to reject suggests {it:l} breaks.{p_end}
{phang2}(c) The number of breaks chosen by {bf:BIC}, {bf:LWZ} and {bf:KT}.{p_end}
{phang2}(d) The {bf:estimated model}: break dates with 95% and 90% confidence
intervals, the global minimized SSR, and the regime-specific coefficients with
corrected standard errors in parentheses.{p_end}

{pstd}
{bf:Joint mode} prints the Sup LR4 matrix (rows {it:m} coefficient breaks, columns
{it:n} variance breaks) with bracketed critical values, the marginal coefficient
and variance tables, UDmax4, and the sequentially-selected numbers of
coefficient and variance breaks together with their estimated dates.

{marker remarks}{...}
{title:Remarks and practical guidance}

{phang}
{bf:Sample size.} A break model needs enough observations per regime. With
{it:q} changing regressors each segment must contain at least {it:q} usable
points; {cmd:regbreak} enforces the trimming and warns when {opt maxb()} is too
large for the sample.

{phang}
{bf:Choosing the number of breaks.} The sequential Sup F(l+1|l) and the KT
criterion are the most reliable in practice; UDmax is a useful omnibus check that
{it:some} break is present. When they disagree, prefer the sequential procedure.

{phang}
{bf:When to use {opt joint}.} If the residual volatility looks non-constant (for
example an interest-rate or inflation series spanning a change in monetary
regime), the coefficient-only tests can be size-distorted; the joint procedure
separates genuine coefficient shifts from pure variance shifts.

{phang}
{bf:Trimming and critical values.} Joint critical values exist only for
{cmd:trim(0.05)} and {cmd:trim(0.10)}; a "." in a critical-value cell means the
value is not tabulated for the chosen {it:q}, break count or trimming.

{marker examples}{...}
{title:Examples}

{pstd}Ex-post real interest rate (mean-shift model){p_end}
{phang2}{cmd:. regbreak rate, trim(0.15) maxb(5)}{p_end}
{phang2}{cmd:. regbreak rate, trim(0.15) graph}{p_end}

{pstd}Force a two-break model and view its coefficients{p_end}
{phang2}{cmd:. regbreak rate, fixn(2)}{p_end}

{pstd}A regression with changing slope, constant control{p_end}
{phang2}{cmd:. regbreak inf inflag inffut, x(ygap) prewhite(0) trim(0.10)}{p_end}

{pstd}Joint variance-and-coefficient tests{p_end}
{phang2}{cmd:. regbreak rate, joint trim(0.10) maxb(3) maxv(2)}{p_end}

{marker results}{...}
{title:Stored results}

{pstd}{cmd:regbreak} (Bai-Perron mode) stores in {cmd:e()}:{p_end}
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(nbreak)}}number of breaks estimated{p_end}
{synopt:{cmd:e(UDmax)}}UDmax statistic{p_end}
{synopt:{cmd:e(SSR)}}minimized sum of squared residuals{p_end}
{synopt:{cmd:e(T)}}number of observations{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:regbreak}{p_end}
{synopt:{cmd:e(method)}}{cmd:Bai-Perron}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(supF)}}Sup F statistics{p_end}
{synopt:{cmd:e(supFcv)}}Sup F critical values{p_end}
{synopt:{cmd:e(seqF)}}sequential Sup F statistics{p_end}
{synopt:{cmd:e(seqFcv)}}sequential Sup F critical values{p_end}
{synopt:{cmd:e(IC)}}breaks chosen by BIC, LWZ, KT{p_end}
{synopt:{cmd:e(date)}}estimated break dates{p_end}
{synopt:{cmd:e(CI)}}break-date confidence intervals{p_end}
{synopt:{cmd:e(beta)}}regime-specific coefficients{p_end}
{synopt:{cmd:e(SE)}}corrected standard errors{p_end}

{pstd}In {opt joint} mode {cmd:e()} contains {cmd:e(supLR4)}, {cmd:e(cvLR4)},
{cmd:e(supLR3)}, {cmd:e(supLR2)}, {cmd:e(UDmax4)}, {cmd:e(mcoef)} and
{cmd:e(nvar)}.{p_end}

{marker refs}{...}
{title:References}

{phang}Bai, J., and P. Perron. 1998. Estimating and testing linear models with
multiple structural changes. {it:Econometrica} 66: 47{c 45}78.{p_end}
{phang}Perron, P., Y. Yamamoto, and J. Zhou. Testing jointly for structural
changes in the error variance and coefficients of a linear regression model.{p_end}
{phang}Kurozumi, E., and P. Tuvaandorj. 2011. Model selection criteria in
multivariate models with multiple structural changes. {it:Journal of
Econometrics} 164: 218{c 45}238.{p_end}
{phang}Liu, J., S. Wu, and J. V. Zidek. 1997. On segmented multivariate
regressions. {it:Statistica Sinica} 7: 497{c 45}525.{p_end}

{marker author}{...}
{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
