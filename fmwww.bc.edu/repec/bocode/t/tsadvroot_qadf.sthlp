{smcl}
{* *! version 1.0.0  03jul2026}{...}
{viewerjumpto "Syntax" "tsadvroot_qadf##syntax"}{...}
{viewerjumpto "Description" "tsadvroot_qadf##description"}{...}
{viewerjumpto "Options" "tsadvroot_qadf##options"}{...}
{viewerjumpto "Methods" "tsadvroot_qadf##methods"}{...}
{viewerjumpto "Source compatibility" "tsadvroot_qadf##compat"}{...}
{viewerjumpto "Stored results" "tsadvroot_qadf##results"}{...}
{viewerjumpto "Examples" "tsadvroot_qadf##examples"}{...}
{viewerjumpto "References" "tsadvroot_qadf##references"}{...}
{vieweralsosee "tsadvroot" "help tsadvroot"}{...}
{vieweralsosee "tsadvroot fqadf" "help tsadvroot_fqadf"}{...}
{vieweralsosee "tsadvroot npadf" "help tsadvroot_npadf"}{...}
{vieweralsosee "tsadvroot cisur" "help tsadvroot_cisur"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] qreg" "help qreg"}{...}
{vieweralsosee "[TS] dfuller" "help dfuller"}{...}
{title:Title}

{phang}
{bf:tsadvroot qadf} {hline 2} Quantile ADF unit-root test
(Koenker and Xiao 2004)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsadvroot} {cmd:qadf} {varname} {ifin}
[{cmd:,} {it:options}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt t:au(numlist)}}quantile(s) in (0,1); default is
{cmd:tau(0.1(0.1)0.9)}{p_end}
{synopt:{opt m:odel(string)}}{cmd:c} (constant, the Koenker-Xiao default) or
{cmd:ct} (constant and trend){p_end}
{synopt:{opt pm:ax(#)}}maximum number of lags of D.{it:varname};
default {cmd:pmax(8)}; {cmd:pmax(0)} forces no lags{p_end}
{synopt:{opt ic(string)}}lag-selection criterion: {cmd:aic}, {cmd:sic} or
{cmd:tstat}; default {cmd:tstat} (the GAUSS-source default,
general-to-specific with |t| > 1.645){p_end}
{synopt:{opt gr:aph}}two-panel profile plot of rho(tau) and t_n(tau) with
critical-value bands{p_end}
{synopt:{opt na:me(string)}}stub name for the graph{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}, contiguous within the sample.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsadvroot qadf} implements the quantile autoregression unit-root test
of Koenker and Xiao (2004). For each requested quantile tau it estimates by
quantile regression

{p 8 8 2}
Q_y(tau | F_t-1) = alpha0(tau) + rho1(tau) y_t-1 +
sum_j alpha_j(tau) D.y_t-j [+ delta(tau) t]

{pstd}
and tests H0: rho1(tau) = 1 (unit root at quantile tau) with the t-ratio
statistic t_n(tau), which studentizes rho1(tau)-1 using a kernel estimate of
the sparsity function and the projection of y_t-1 off the remaining
regressors. Critical values are taken from Hansen (1995, Table II) as a
function of the nuisance parameter delta-squared, exactly as prescribed in
Koenker and Xiao (2004, section 3).

{pstd}
Persistence may be rejected in some parts of the conditional distribution
and not in others - e.g. shocks that die out in the lower quantiles but are
permanent in the upper quantiles - which is the main empirical attraction of
the test.


{marker options}{...}
{title:Options}

{phang}
{opt tau(numlist)} sets the quantile(s). With more than one value the
command prints one row per quantile and (with {opt graph}) draws the
quantile profile. Default: the nine deciles.

{phang}
{opt model(string)}: {cmd:c} includes only a constant (the default in
Koenker and Xiao 2004); {cmd:ct} adds a linear trend. Numeric codes
{cmd:1}/{cmd:2} (the GAUSS convention) are also accepted.

{phang}
{opt pmax(#)} and {opt ic()}: the lag order p is selected {it:once} from a
standard OLS ADF regression with constant (GAUSS: {cmd:ADF(y, 1, pmax, ic)})
and then used at every quantile, exactly as in the source. {cmd:aic} and
{cmd:sic} use the tspdlib penalty 2(k+2)/n and (k+2)ln(n)/n; {cmd:tstat}
scans from {it:pmax} down and keeps the first lag whose last-lag |t| exceeds
1.645.

{phang}
{opt graph} draws a combined figure: top panel rho(tau) with the unity
reference line; bottom panel t_n(tau) with the 1%, 5% and 10% critical-value
curves. {opt name(stub)} controls the graph names
({it:stub}, {it:stub}_rho, {it:stub}_tn).


{marker methods}{...}
{title:Methods and formulas}

{pstd}
Let p be the selected lag order and n = T - p - 1 the effective sample. The
statistic is

{p 8 8 2}
t_n(tau) = f(F^-1(tau)) / sqrt(tau(1-tau)) * sqrt(Y_1' P_X Y_1) *
(rho1(tau) - 1)

{pstd}
where f(F^-1(tau)) = 2h / (x'b(tau+h) - x'b(tau-h)) is the
difference-quotient sparsity estimate at the mean design point (Koenker-Xiao
eq. 9), h is the Hall-Sheather (1988) bandwidth with the Bofinger (1975)
fallback and the boundary caps of the source, and P_X projects off the
constant and the lagged differences ({it:not} the trend, matching the
source). delta-squared is the squared correlation-type nuisance parameter
computed from psi_tau(residuals) and D.y; the Hansen (1995) critical values
are linearly interpolated in delta-squared over the grid 0.1, 0.2, ..., 1.

{pstd}
Quantile regressions are computed with Stata's exact {helpb qreg} solver
(same check-function objective as GAUSS {cmd:quantileFit}).


{marker compat}{...}
{title:Source compatibility (qr_adf.src)}

{pstd}The following source conventions are reproduced exactly:{p_end}
{phang2}- lag order selected from a {it:constant-only} OLS ADF regression,
regardless of {opt model()};{p_end}
{phang2}- estimation sample drops the first p+1 observations; the dependent
variable is y_t in {it:levels};{p_end}
{phang2}- trend variable = original observation index (not restarted after
trimming);{p_end}
{phang2}- the projection matrix P_X excludes the trend even under
{cmd:model(ct)};{p_end}
{phang2}- delta-squared uses w = D.y and the n-1 covariance divisor;{p_end}
{phang2}- density guard: f < 0 is replaced by 0.01;{p_end}
{phang2}- critical-value interpolation saturates below 0.1 and above 1.0.{p_end}

{pstd}
{it:Note for users of the SSC} {cmd:qadf} {it:package}: this implementation
differs from {cmd:ssc install qadf} (same author) in using the exact
{helpb qreg} solution rather than an IRLS approximation, the tspdlib lag
penalties 2(k+2)/n, the 1.645 threshold in the t-stat rule, the
{cmd:tstat} default criterion, and in reporting delta-squared unclamped.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:tsadvroot qadf} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{synopt:{cmd:r(N)}}effective sample (T - p - 1){p_end}
{synopt:{cmd:r(lags)}}selected lag order p{p_end}
{p2col 5 18 22 2: Scalars (only with a single tau)}{p_end}
{synopt:{cmd:r(tn)}}quantile ADF t-statistic{p_end}
{synopt:{cmd:r(rho_tau)}}quantile AR(1) coefficient{p_end}
{synopt:{cmd:r(rho_ols)}}OLS AR(1) coefficient{p_end}
{synopt:{cmd:r(delta2)}}nuisance parameter delta-squared{p_end}
{synopt:{cmd:r(cv1)}, {cmd:r(cv5)}, {cmd:r(cv10)}}Hansen critical values{p_end}
{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(varname)}, {cmd:r(model)}, {cmd:r(ic)},
{cmd:r(tau)}}{p_end}
{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}one row per quantile: tau, rho_tau, rho_ols,
delta2, tn, cv1, cv5, cv10{p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}{cmd:. webuse air2, clear}{p_end}
{phang}{cmd:. gen lair = ln(air)}{p_end}
{phang}{cmd:. tsadvroot qadf lair, model(ct) graph}{p_end}
{phang}{cmd:. tsadvroot qadf lair, tau(0.25 0.5 0.75) model(c) ic(aic)}{p_end}
{phang}{cmd:. tsadvroot qadf lair, tau(0.5) pmax(4) ic(sic)}{p_end}
{phang}{cmd:. matrix list r(results)}{p_end}


{marker references}{...}
{title:References}

{phang}
Hansen, B. E. 1995. Rethinking the univariate approach to unit root testing.
{it:Econometric Theory} 11: 1148-1171.

{phang}
Koenker, R., and Z. Xiao. 2004. Unit root quantile autoregression inference.
{it:Journal of the American Statistical Association} 99: 775-787.


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Help: {helpb tsadvroot}, {helpb tsadvroot_fqadf}, {helpb tsadvroot_npadf},
{helpb tsadvroot_cisur}, {helpb qreg}
{p_end}
