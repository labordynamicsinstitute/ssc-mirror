{smcl}
{* *! version 1.0.0  08jul2026}{...}
{vieweralsosee "xthkrcoint postestimation" "help xthkrcoint_postestimation"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtcointtest" "help xtcointtest"}{...}
{vieweralsosee "xtunitroot" "help xtunitroot"}{...}
{viewerjumpto "Syntax" "xthkrcoint##syntax"}{...}
{viewerjumpto "Description" "xthkrcoint##description"}{...}
{viewerjumpto "Options" "xthkrcoint##options"}{...}
{viewerjumpto "Method" "xthkrcoint##method"}{...}
{viewerjumpto "Tuning parameters" "xthkrcoint##tuning"}{...}
{viewerjumpto "Stored results" "xthkrcoint##results"}{...}
{viewerjumpto "Examples" "xthkrcoint##examples"}{...}
{viewerjumpto "References" "xthkrcoint##references"}{...}
{viewerjumpto "Author" "xthkrcoint##author"}{...}
{title:Title}

{phang}
{bf:xthkrcoint} {hline 2} Hadri-Kurozumi-Rao panel cointegration test with the
null of cointegration, robust to cross-section dependence, for fixed {it:N} and
large {it:T}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xthkrcoint}
{it:depvar} {it:indepvars}
{ifin}
[{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt tr:end}}include a linear time trend in the deterministic part
(default: constant only){p_end}
{synopt:{opt ols}}also report the OLS-residual autocovariance statistic as a
comparator{p_end}

{syntab:Tuning parameters}
{synopt:{opt k(#)}}lag order {it:K} for the autocovariance; default
{cmd:k(}{it:floor((a*T)^delta)}{cmd:)}{p_end}
{synopt:{opt a(#)}}multiplier {it:a} in the default rule for {it:K}; default
{cmd:a(2)}{p_end}
{synopt:{opt d:elta(#)}}exponent {it:delta} in the default rule for {it:K};
default {cmd:delta(0.5)}{p_end}
{synopt:{opt m(#)}}number of DOLS leads and lags {it:M}; default
{cmd:m(}{it:floor(2*(T/100)^(1/5))}{cmd:)}{p_end}
{synopt:{opt j(#)}}Bartlett bandwidth {it:J} for the long-run variance; default
{cmd:j(}{it:floor(12*(T/100)^(1/4))}{cmd:)}{p_end}

{syntab:Reporting and graphs}
{synopt:{opt noind:ividual}}suppress the per-unit results table{p_end}
{synopt:{opt gr:aph}}draw the publication diagnostics dashboard (unit forest
plot + {it:K}-sensitivity curve){p_end}
{synopt:{opt ksens(numlist)}}values of {it:K} for the sensitivity curve
(integers > 0){p_end}
{synopt:{opt name(string)}}stub for the stored graph name(s); default
{cmd:name(xthkr)}{p_end}
{synopt:{opt sch:eme(string)}}graph scheme; default {cmd:scheme(s2color)}{p_end}
{synopt:{opt tit:le(string)}}replace the header title{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
The data must be declared as panel data with {helpb xtset} (fixed {it:N}, large
{it:T}) or, for a single time series, with {helpb tsset} (in which case the test
reduces to the univariate cointegration test of the same paper). The panel must
be {bf:strongly balanced} with no gaps.{p_end}
{p 4 6 2}
{it:depvar} is the dependent variable {it:y}; {it:indepvars} are the {it:I}(1)
regressors {it:x}. {it:depvar} and {it:indepvars} are assumed {it:I}(1); under
the null they are cointegrated.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xthkrcoint} implements the panel cointegration tests of
{help xthkrcoint##HKR2015:Hadri, Kurozumi and Rao (2015, Econometrics Journal)}.
The distinctive features of the test are:

{p 8 10 2}{bf:1.} The {bf:null hypothesis is cointegration} for {it:every} unit;
the alternative is that at least one unit is not cointegrated. This is the
natural null when the researcher wishes to establish a long-run relationship,
and it complements the more common no-cointegration-null tests
({helpb xtcointtest}).{p_end}

{p 8 10 2}{bf:2.} The asymptotics hold with {bf:{it:N} fixed and {it:T} large},
so the test suits typical macroeconomic and financial panels where {it:N} is
small relative to {it:T}. No estimation of the number of common factors is
required.{p_end}

{p 8 10 2}{bf:3.} Arbitrary {bf:cross-section dependence} (weak or strong,
including common factors and cross-unit cointegration) is mopped up
{it:nonparametrically} through the long-run variance of the pooled
autocovariances, in the spirit of Driscoll-Kraay. The pooled statistic is
therefore asymptotically {bf:standard normal} and no bootstrap critical values
are needed.{p_end}

{p 8 10 2}{bf:4.} Serial correlation is handled by dynamic OLS (DOLS) — the
cointegrating regression is augmented with leads and lags of {it:{c 68}x} — and
a {bf:bias correction} removes the finite-sample negative bias of the
autocovariance statistic (which otherwise makes the test conservative).{p_end}

{pstd}
The command reports the pooled statistic {bf:S{sub:K}} (uncorrected) and
{bf:S~{sub:K}} (bias-corrected), each with a one-sided (upper-tail)
{it:p}-value, a decision at the 5% level, and a per-unit breakdown showing which
cross-sections drive a rejection. With {opt graph} it draws a two-panel
diagnostics dashboard.

{marker options}{...}
{title:Options}

{dlabel:Model}

{phang}
{opt trend} adds a linear time trend to the deterministic component of the
cointegrating regression, so {it:X}{sub:t} = [1, {it:t}, {it:x}{sub:t}]. Without
it the deterministic part is a constant only, {it:X}{sub:t} = [1,
{it:x}{sub:t}]. The bias correction uses {it:p{sub:c}} = 1 (constant) or
{it:p{sub:c}} = 2 (constant and trend).

{phang}
{opt ols} additionally computes the autocovariance statistic from static OLS
residuals, {bf:S{sub:K}{sup:ols}}, which is also asymptotically N(0,1) under the
null and is reported for comparison. The DOLS-based {bf:S~{sub:K}} is the
recommended statistic.

{dlabel:Tuning parameters}

{phang}
{opt k(#)} sets the lag order {it:K} of the autocovariance
{it:a}{sub:K,t} = {it:{c 240}}{sub:t}{it:{c 240}}{sub:t-K}. {it:K} must diverge
with {it:T} (Assumption 3, {it:T}{sup:1/4} {c 60}= {it:K} {c 60} {it:T}). The
default is {it:K} = floor((a*T){sup:delta}) with {cmd:a(2)} and
{cmd:delta(0.5)}, i.e. {it:K} = floor((2{it:T}){sup:1/2}), the value recommended
in the paper. See {help xthkrcoint##tuning:Tuning parameters}.

{phang}
{opt a(#)} and {opt delta(#)} control the default rule {it:K} =
floor((a*T){sup:delta}). They are ignored if {opt k()} is given.

{phang}
{opt m(#)} sets the number {it:M} of DOLS leads and lags of {it:{c 68}x}. It
must satisfy Assumption 2 ({it:M}{sup:4}/{it:T} {c 174} 0). The default is
{it:M} = floor(2*(T/100){sup:1/5}). The effective sample after trimming is
{it:T} {c 45} 2{it:M} {c 45} 1.

{phang}
{opt j(#)} sets the Bartlett-kernel bandwidth {it:J} used for every long-run
variance in the procedure. It must be {it:o}({it:T}{sup:1/2}). The default is
{it:J} = floor(12*(T/100){sup:1/4}).

{dlabel:Reporting and graphs}

{phang}
{opt noindividual} suppresses the per-unit table (shown by default when
{it:N} {c 62} 1).

{phang}
{opt graph} draws the diagnostics dashboard: (a) a forest / caterpillar plot of
the unit-specific bias-corrected statistics with the 5% and 1% one-sided
critical values, units beyond the line shown in a contrasting colour; and (b)
the pooled {bf:S~{sub:K}} and {bf:S{sub:K}} as functions of {it:K} with the
critical values marked, so the robustness of the conclusion to the lag order can
be judged at a glance.

{phang}
{opt ksens(numlist)} supplies the grid of {it:K} values for the sensitivity
curve. If omitted while {opt graph} is on, a default grid of about 16 values
spanning ({it:0.5T}){sup:1/2} to ({it:3T}){sup:1/2} is used. The grid is also
returned in {cmd:r(ksens)}.

{phang}
{opt name(string)}, {opt scheme(string)} and {opt title(string)} control the
stored graph name stub, the graph scheme and the header title, respectively.

{marker method}{...}
{title:Method}

{pstd}
For unit {it:i} the cointegrating regression is estimated by DOLS,

{p 12 12 2}
{it:y}{sub:i,t} = {it:{c 98}}{sub:i}{it:'X}{sub:i,t} +
{c 138}{sub:j=-M}{sup:M} {it:{c 112}}{sub:i,j}{it:'}{c 68}{it:x}{sub:i,t-j} +
{it:{c 240}}{sub:i,t}{sup:*},

{pstd}
and the residuals are standardized, {it:{c 240}~}{sub:i,t} =
{it:{c 240}^}{sub:i,t}/{it:{c 240}^}{sub:i}. The pooled cross-product is
{it:a}{sub:K,t} = {c 138}{sub:i=1}{sup:N}
{it:{c 240}~}{sub:i,t}{it:{c 240}~}{sub:i,t-K} and

{p 12 12 2}
{bf:S{sub:K}} = {it:C~}{sub:K} / {it:{c 240}^}{sub:a},{space 4}
{bf:S~{sub:K}} = ({it:C~}{sub:K} + {it:b~}) / {it:{c 240}^}{sub:a},

{pstd}
where {it:C~}{sub:K} = ({it:T-K}){sup:-1/2} {c 138}{sub:t=K+1}{sup:T}
{it:a}{sub:K,t}, {it:{c 240}^}{sub:a}{sup:2} is the Bartlett long-run variance of
{it:a}{sub:K,t} (this is what absorbs the cross-section dependence), and the
bias term is {it:b~} = ({it:T-K}){sup:-1/2} {c 138}{sub:i}
({it:p{sub:i,c}}+{it:p{sub:i,x}}) {it:{c 240}^}{sub:i}{sup:2} /
{it:{c 240}^}{sub:i}{sup:2}. Under H0 both statistics converge to N(0,1) and
diverge to +{c 165} under H1, so the test is {bf:one-sided (upper tail)}: large
positive values are evidence {bf:against} panel cointegration.

{marker tuning}{...}
{title:Tuning parameters — practical guidance}

{pstd}
The finite-sample behaviour depends mostly on {it:K} (paper, Section 5):

{p 8 10 2}{bf:-} Smaller {it:K} gives {bf:more power} but larger {it:K} gives a
{bf:better-controlled size} under strong serial correlation. The uncorrected
{bf:S{sub:K}} is conservative; the {bf:bias-corrected S~{sub:K}} is close to
nominal and is the one to report.{p_end}

{p 8 10 2}{bf:-} The authors {bf:recommend {it:K} = floor((2T){sup:1/2}) or
floor((3T){sup:1/2})} — i.e. {cmd:a(2)} (the default) or {cmd:a(3)}. Avoid very
small ({it:K}={it:T}{sup:1/4}) or very large ({it:K}={it:T}{sup:3/4}) exponents
when errors are strongly serially correlated.{p_end}

{p 8 10 2}{bf:-} Always inspect the {cmd:graph} {it:K}-sensitivity curve and the
per-unit table before concluding.{p_end}

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:xthkrcoint} is an {cmd:r-class} command. It stores:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(S)}}pooled uncorrected statistic {bf:S{sub:K}}{p_end}
{synopt:{cmd:r(p)}}one-sided {it:p}-value for {cmd:r(S)}{p_end}
{synopt:{cmd:r(Sbc)}}pooled bias-corrected statistic {bf:S~{sub:K}}{p_end}
{synopt:{cmd:r(pbc)}}one-sided {it:p}-value for {cmd:r(Sbc)}{p_end}
{synopt:{cmd:r(Sols)}}pooled OLS-residual statistic (with {opt ols}){p_end}
{synopt:{cmd:r(pols)}}one-sided {it:p}-value for {cmd:r(Sols)}{p_end}
{synopt:{cmd:r(Cbar)}}pooled autocovariance {it:C~}{sub:K}{p_end}
{synopt:{cmd:r(omega_a)}}Bartlett long-run variance {it:{c 240}^}{sub:a}{sup:2}{p_end}
{synopt:{cmd:r(bias)}}bias term {it:b~}{p_end}
{synopt:{cmd:r(N)}}number of panels{p_end}
{synopt:{cmd:r(T)}}time periods per panel{p_end}
{synopt:{cmd:r(Teff)}}effective obs after DOLS trimming ({it:T}{c 45}2{it:M}{c 45}1){p_end}
{synopt:{cmd:r(na)}}{it:T}{c 45}{it:K} used in {it:C~}{sub:K}{p_end}
{synopt:{cmd:r(K)}}lag order used{p_end}
{synopt:{cmd:r(M)}}DOLS leads/lags used{p_end}
{synopt:{cmd:r(J)}}Bartlett bandwidth used{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xthkrcoint}{p_end}
{synopt:{cmd:r(depvar)}}name of {it:depvar}{p_end}
{synopt:{cmd:r(regr)}}names of the {it:I}(1) regressors{p_end}
{synopt:{cmd:r(det)}}deterministic specification{p_end}
{synopt:{cmd:r(null)}}{cmd:panel cointegration}{p_end}

{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(panel)}}1{c 215}20 vector of all pooled quantities{p_end}
{synopt:{cmd:r(indiv)}}{it:N}{c 215}9 per-unit results (unit, T_i, K, S_K, S_bc,
p_S, p_bc, S_ols, p_ols){p_end}
{synopt:{cmd:r(ksens)}}{it:G}{c 215}5 sensitivity grid (K, S_K, S_bc, p_S,
p_bc), when computed{p_end}

{marker examples}{...}
{title:Examples}

{pstd}Setup a balanced panel:{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Baseline test (constant, default {it:K}, {it:M}, {it:J}):{p_end}
{phang2}{cmd:. xthkrcoint invest mvalue kstock}{p_end}

{pstd}Trend case, with the OLS comparator and the diagnostics dashboard:{p_end}
{phang2}{cmd:. xthkrcoint invest mvalue kstock, trend ols graph}{p_end}

{pstd}Robustness across lag orders, saving the sensitivity grid:{p_end}
{phang2}{cmd:. xthkrcoint invest mvalue kstock, ksens(5 8 11 14 17 20)}{p_end}
{phang2}{cmd:. matrix list r(ksens)}{p_end}

{pstd}A single time series (reduces to the univariate cointegration test):{p_end}
{phang2}{cmd:. tsset year}{p_end}
{phang2}{cmd:. xthkrcoint y x1 x2}{p_end}

{marker references}{...}
{title:References}

{marker HKR2015}{...}
{phang}
Hadri, K., E. Kurozumi, and Y. Rao. 2015. Novel panel cointegration tests
emending for cross-section dependence with N fixed. {it:Econometrics Journal}
18(3): 363-411. {browse "https://doi.org/10.1111/ectj.12054":doi:10.1111/ectj.12054}.

{phang}
Harris, D., B. McCabe, and S. Leybourne. 2003. Some limit theory for
autocovariances whose order depends on sample size. {it:Econometric Theory}
19(5): 829-864.

{phang}
Harris, D., S. Leybourne, and B. McCabe. 2005. Panel stationarity tests for
purchasing power parity with cross-sectional dependence. {it:Journal of Business
and Economic Statistics} 23(4): 395-409.

{phang}
Saikkonen, P. 1991. Asymptotically efficient estimation of cointegration
regressions. {it:Econometric Theory} 7(1): 1-21.

{phang}
Driscoll, J. C., and A. C. Kraay. 1998. Consistent covariance matrix estimation
with spatially dependent panel data. {it:Review of Economics and Statistics}
80(4): 549-560.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
