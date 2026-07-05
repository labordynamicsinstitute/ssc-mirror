{smcl}
{* *! version 1.0.0  03jul2026}{...}
{viewerjumpto "Syntax" "tsadvroot_cisur##syntax"}{...}
{viewerjumpto "Description" "tsadvroot_cisur##description"}{...}
{viewerjumpto "Options" "tsadvroot_cisur##options"}{...}
{viewerjumpto "Methods" "tsadvroot_cisur##methods"}{...}
{viewerjumpto "Source compatibility" "tsadvroot_cisur##compat"}{...}
{viewerjumpto "Stored results" "tsadvroot_cisur##results"}{...}
{viewerjumpto "Examples" "tsadvroot_cisur##examples"}{...}
{viewerjumpto "References" "tsadvroot_cisur##references"}{...}
{vieweralsosee "tsadvroot" "help tsadvroot"}{...}
{vieweralsosee "tsadvroot qadf" "help tsadvroot_qadf"}{...}
{vieweralsosee "tsadvroot fqadf" "help tsadvroot_fqadf"}{...}
{vieweralsosee "tsadvroot npadf" "help tsadvroot_npadf"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[TS] dfgls" "help dfgls"}{...}
{title:Title}

{phang}
{bf:tsadvroot cisur} {hline 2} GLS-based unit-root tests with multiple
structural breaks (Carrion-i-Silvestre, Kim and Perron 2009)


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:tsadvroot} {cmd:cisur} {varname} {ifin}
[{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt m:odel(string)}}{cmd:const} (0: constant, no breaks),
{cmd:trend} (1: linear trend, no breaks), {cmd:slope} (2: breaks in the
trend slope), {cmd:break} (3: breaks in level and slope; the default){p_end}
{synopt:{opt b:reaks(#)}}number of {it:unknown} breaks to estimate, 1-3;
default {cmd:breaks(1)}{p_end}
{synopt:{opt breakd:ates(numlist)}}{it:known} break dates (time-variable
values, up to 5); overrides {opt breaks()}{p_end}
{synopt:{opt p:enalty(string)}}lag penalty for the long-run variance:
{cmd:maic} (default) or {cmd:bic}{p_end}
{synopt:{opt km:ax(#)}}maximum lag for the long-run variance; default
{cmd:kmax(4)}{p_end}
{synopt:{opt kmi:n(#)}}minimum lag; default {cmd:kmin(0)}{p_end}
{synopt:{opt gr:aph}}plot the series with the GLS-estimated broken trend and
break dates{p_end}
{synopt:{opt na:me(string)}}graph name{p_end}
{synopt:{opt nopr:int}}suppress the results table{p_end}
{synoptline}
{p 4 6 2}The data must be {helpb tsset}, contiguous within the sample.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:tsadvroot cisur} implements the Carrion-i-Silvestre, Kim and Perron
(2009) extension of the Elliott-Rothenberg-Stock / Ng-Perron framework to
multiple structural breaks under {it:both} the null and the alternative. It
reports seven statistics computed on the quasi-GLS-detrended series:

{p2colset 8 16 18 2}{...}
{p2col:PT, MPT}feasible point-optimal statistics{p_end}
{p2col:ADF}augmented Dickey-Fuller t on the GLS-detrended series{p_end}
{p2col:ZA}Phillips-Perron Z_alpha (GLS){p_end}
{p2col:MZA, MSB, MZT}Ng-Perron M-tests (GLS){p_end}
{p2colreset}{...}

{pstd}
Unknown break dates are estimated by minimizing the GLS sum of squared
residuals over all admissible break-date combinations (the source's
brute-force algorithm, its default). The non-centrality parameter c-bar and
the 1%, 5% and 10% critical values are evaluated from the authors' response
surfaces at the estimated break fractions, so no bootstrap is needed. All
seven tests reject the unit root for values {it:below} the critical value.


{marker options}{...}
{title:Options}

{phang}
{opt model()}: models 0 and 1 are the no-break ERS cases with fixed
c-bar = -7 and -13.5 respectively; model 2 lets each break shift the slope
of the trend; model 3 (the default, the paper's leading case) lets each
break shift both the level and the slope.

{phang}
{opt breaks(#)}: with unknown dates the brute-force search is O(T) for one
break, O(T^2) for two and O(T^3) for three - with T around 200 and
{cmd:breaks(3)} expect several minutes. Minimum segment length is 2, and the
first/last 3 observations are excluded, as in the source.

{phang}
{opt breakdates(numlist)}: supply up to 5 known break dates (values of the
time variable, strictly increasing). The statistics and critical values are
then computed at those dates without any search.

{phang}
{opt penalty()}, {opt kmax()}, {opt kmin()}: the autoregressive long-run
variance s2(AR) uses a lag order selected by MAIC (Ng-Perron) or BIC on the
{it:OLS-detrended} series (Perron's recommendation, as in the source), with
k between {opt kmin()} and {opt kmax()}.


{marker methods}{...}
{title:Methods and formulas}

{pstd}
For a candidate break vector, the deterministics are z_t = (1, t, ...) plus,
for each break TB_j, a level shift DU_j (model 3 only) and a slope shift
DT_j = (t-TB_j)1(t>TB_j). The series is quasi-differenced at
alpha-bar = 1 + c-bar/T, where c-bar is the response-surface value at the
break fractions; the GLS coefficients minimize the quasi-differenced SSR,
and the break dates minimize that SSR over the grid. On the detrended series
y-tilde the statistics follow Ng and Perron (2001):

{p 8 8 2}MZA = (y-tilde_T^2/(T-1) - s2AR) / (2 kappa),
MSB = sqrt(kappa/s2AR), MZT = MZA x MSB,{p_end}
{p 8 8 2}ZA = (T-1)(alpha-hat - 1) - (s2AR - s2u)/(2 kappa),
kappa = sum(y-tilde_t-1^2)/(T-1)^2,{p_end}
{p 8 8 2}PT = (SSR(alpha-bar) - alpha-bar SSR(1))/s2AR, and the MPT
analogue,{p_end}

{pstd}
with s2AR the autoregressive long-run variance estimated from the ADF
regression with the MAIC/BIC lag chosen on OLS-detrended data.


{marker compat}{...}
{title:Source compatibility (carrion silvestre2009.src)}

{pstd}The following source conventions are reproduced exactly:{p_end}
{phang2}- the brute-force estimation path, which is the source's own default
({cmd:sburControlCreate} sets {cmd:estimation = 0}); the alternative
dynamic-programming path ({cmd:estimation = 1}, Bai-Perron dating plus
Perron-Qu restricted iterations) is {it:not} implemented - with unknown
dates the command therefore supports up to 3 breaks, exactly like the
source's brute-force code;{p_end}
{phang2}- search bounds j in [3, T-3] with a minimum of 2 periods between
consecutive breaks;{p_end}
{phang2}- c-bar re-evaluated from the response surface at every candidate
break vector;{p_end}
{phang2}- s2(AR) lag chosen on OLS-detrended data; its regression has no
constant, variance divisor n (not n-k), and the fixed common sample
T-kmax-1 in the selection step;{p_end}
{phang2}- the critical-value mapping of the source's output routine:
PT and MPT use the PT surface, ADF and MZT use the MZT surface, ZA and MZA
use the MZA surface, MSB its own;{p_end}
{phang2}- response-surface coefficient matrices transcribed digit-for-digit
from the source (61 c-bar coefficients; 63 x 16 critical-value
coefficients).{p_end}


{marker results}{...}
{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(pt)}, {cmd:r(mpt)}, {cmd:r(adf)}, {cmd:r(za)}, {cmd:r(mza)},
{cmd:r(msb)}, {cmd:r(mzt)}}the seven statistics{p_end}
{synopt:{cmd:r(cbar)}}non-centrality parameter c-bar{p_end}
{synopt:{cmd:r(lags)}}long-run-variance lag (MAIC/BIC){p_end}
{synopt:{cmd:r(nbreaks)}}number of breaks{p_end}
{synopt:{cmd:r(T)}}sample size{p_end}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}, {cmd:r(varname)}, {cmd:r(model)}, {cmd:r(penalty)},
{cmd:r(breakdates)}}{p_end}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:r(stats)}}1 x 7: PT MPT ADF ZA MZA MSB MZT{p_end}
{synopt:{cmd:r(cv)}}4 x 3 critical values (rows MSB MZA MZT PT; columns
1% 5% 10%){p_end}
{synopt:{cmd:r(breakpos)}}estimated/known break positions (models 2-3){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{phang}{cmd:. webuse air2, clear}{p_end}
{phang}{cmd:. gen lair = ln(air)}{p_end}

{pstd}No-break GLS tests (ERS/Ng-Perron with response-surface cv){p_end}
{phang}{cmd:. tsadvroot cisur lair, model(trend)}{p_end}

{pstd}One estimated level-and-slope break, with the fitted broken trend{p_end}
{phang}{cmd:. tsadvroot cisur lair, model(break) breaks(1) graph}{p_end}

{pstd}Two estimated breaks, BIC lag penalty{p_end}
{phang}{cmd:. tsadvroot cisur lair, model(break) breaks(2) penalty(bic)}{p_end}

{pstd}Known break dates{p_end}
{phang}{cmd:. tsadvroot cisur lair, model(break) breakdates(1955m1 1958m1)}{p_end}
{pmore}(supply the dates as values of the time variable; for string dates
use e.g. {cmd:breakdates(`=tm(1955m1)' `=tm(1958m1)')}){p_end}


{marker references}{...}
{title:References}

{phang}
Carrion-i-Silvestre, J. L., D. Kim, and P. Perron. 2009. GLS-based unit root
tests with multiple structural breaks under both the null and the
alternative hypotheses. {it:Econometric Theory} 25: 1754-1792.

{phang}
Elliott, G., T. J. Rothenberg, and J. H. Stock. 1996. Efficient tests for an
autoregressive unit root. {it:Econometrica} 64: 813-836.

{phang}
Ng, S., and P. Perron. 2001. Lag length selection and the construction of
unit root tests with good size and power. {it:Econometrica} 69: 1519-1554.

{phang}
Perron, P., and Z. Qu. 2007. A simple modification to improve the finite
sample properties of Ng and Perron's unit root tests.
{it:Economics Letters} 94: 12-19.


{title:Author}

{pstd}
Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane"}


{title:Also see}

{psee}
Help: {helpb tsadvroot}, {helpb tsadvroot_qadf}, {helpb tsadvroot_fqadf},
{helpb tsadvroot_npadf}, {helpb dfgls}
{p_end}
