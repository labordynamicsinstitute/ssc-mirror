{smcl}
{* *! version 1.0.0  06jun2026}{...}
{vieweralsosee "xtpdlib" "help xtpdlib"}{...}
{vieweralsosee "xtfpss" "help xtfpss"}{...}
{vieweralsosee "xtpgc" "help xtpgc"}{...}
{vieweralsosee "xtcips (if installed)" "help xtcips"}{...}
{vieweralsosee "pescadf (if installed)" "help pescadf"}{...}
{viewerjumpto "Syntax" "xtcipsm##syntax"}{...}
{viewerjumpto "Description" "xtcipsm##description"}{...}
{viewerjumpto "Options" "xtcipsm##options"}{...}
{viewerjumpto "Method" "xtcipsm##method"}{...}
{viewerjumpto "Interpretation" "xtcipsm##interp"}{...}
{viewerjumpto "Cautions" "xtcipsm##cautions"}{...}
{viewerjumpto "Examples" "xtcipsm##examples"}{...}
{viewerjumpto "Stored results" "xtcipsm##results"}{...}
{viewerjumpto "References" "xtcipsm##references"}{...}
{viewerjumpto "Author" "xtcipsm##author"}{...}
{title:Title}

{phang}
{bf:xtcipsm} {hline 2} Modified CADF / CIPS panel unit-root test with standard
chi-squared and normal limiting distributions (Westerlund & Hosseinkouchack, 2016)

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:xtcipsm} {varname} {ifin} [{cmd:,} {it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt mod:el(none|constant|trend)}}deterministic term; default {cmd:constant}{p_end}
{synopt:{opt maxl:ags(#)}}maximum augmentation lags; default {cmd:maxlags(4)}{p_end}
{synopt:{opt ic(#)}}lag-selection criterion: 1=AIC, 2=SIC, 3=t-stat; default {cmd:ic(3)}{p_end}

{syntab:Reporting & graph}
{synopt:{opt gr:aph}}plot per-unit CADF and M-CADF against their critical values{p_end}
{synopt:{opt nopr:intind}}suppress the table of individual statistics{p_end}
{synopt:{it:graph_options}}any options passed to {helpb graph combine}{p_end}
{synoptline}

{phang}The data must be {helpb xtset} and the panel must be {bf:balanced}.
{cmd:xtcipsm} is part of the {helpb xtpdlib} library.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtcipsm} implements the {it:modified} cross-sectionally augmented Dickey-Fuller
(M-CADF) and modified CIPS panel unit-root statistics of
{help xtcipsm##WH2016:Westerlund and Hosseinkouchack (2016)}. Cross-section dependence
is handled by augmenting the ADF regression with the cross-sectional averages of the
levels and first differences, as in {help xtcipsm##P2007:Pesaran (2007)}.

{pstd}
The novelty of the modified test is its {bf:standard} limiting distribution: the
individual statistic {bf:D = LM - CADF^2} is asymptotically {bf:chi-squared} with
{it:q} degrees of freedom ({it:q}=2 for the constant model, {it:q}=3 for the trend
model), and the standardized panel statistic {bf:Dp} (the modified CIPS) is
asymptotically {bf:N(0,1)}. This avoids the non-standard, tabulated distributions and
the truncation needed for the original CIPS.

{pstd}
The null hypothesis is a {bf:unit root} in every unit. {cmd:xtcipsm} reports the
modified statistics together with the standard Pesaran CIPS (computed from the same
regression as a by-product and benchmarked against Pesaran's 2007 tables).

{pstd}
This command is a Stata translation of the GAUSS routine {bf:pd_cips} (proc {bf:cips})
from S. Nazlioglu's {bf:TSPDLIB}.

{pstd}{bf:Relation to other commands.} The standard single-series Pesaran CADF/CIPS test
is provided by {helpb pescadf} (P. Lewandowski) and the panel CIPS by {helpb xtcips}
(M. Sangiacomo). {cmd:xtcipsm} adds the {it:modified} version with standard
distributions; the CADF column is reported only because the modified statistic is built
from it.


{marker options}{...}
{title:Options}

{phang}{opt model(none|constant|trend)} sets the deterministic component of the CADF
regression. The modified statistic and its chi-squared/normal distributions are defined
for {cmd:constant} ({it:q}=2) and {cmd:trend} ({it:q}=3). With {cmd:none} only the
standard CIPS is reported.

{phang}{opt maxlags(#)} sets the maximum number of augmentation lags considered.

{phang}{opt ic(#)} chooses the lag-length criterion: 1 = Akaike, 2 = Schwarz,
3 = t-statistic general-to-specific (default, as in the GAUSS code).

{phang}{opt graph} draws a two-panel figure: individual CADF statistics against the
Pesaran 5% critical value and the CIPS average, and individual M-CADF statistics against
the chi-squared 5% critical value.

{phang}{opt noprintind} prints only the panel statistics.


{marker method}{...}
{title:Method}

{pstd}
For each unit {it:i}, after selecting {it:p} lags, the CADF regression is

{p 12 12 2}{cmd:D.y = a_i + b_i * L.y + c_i * L.ybar + d_i * D.ybar + (lags) + e}

{pstd}
where {cmd:ybar} are the cross-sectional averages. {bf:CADF_i} is the t-statistic for
{cmd:b_i = 0}; {bf:LM_i} is the Lagrange-multiplier statistic for the same restriction;
and the modified statistic is {bf:D_i = LM_i - CADF_i^2 ~ chi2(q)}. The panel statistics
are

{p 12 12 2}{cmd:CIPS = mean_i CADF_i}

{p 12 12 2}{cmd:M-CIPS (Dp) = sqrt(N) * (mean_i D_i - q) / sqrt(2q) ~ N(0,1)}.

{pstd}
The reported M-CIPS p-value is the lower-tail normal probability, matching the GAUSS
implementation.


{marker interp}{...}
{title:Interpretation}

{pstd}
{bf:Null hypothesis.} For all panel statistics here H0 is a {bf:unit root in every unit}.
Rejection (large negative statistics) is evidence of stationarity in at least some units.

{pstd}
{bf:Modified CIPS (Dp).} This is the headline statistic. It is N(0,1) under the null and
{cmd:xtcipsm} reports the lower-tail p-value Phi(Dp) (matching the GAUSS implementation),
so:{break}
 - {bf:p-value < 0.05} {space 1}=>{space 1}reject the unit-root null at 5% (panel contains
   stationary units).{break}
 - {bf:p-value >= 0.05} =>{space 1}cannot reject the unit-root null.

{pstd}
{bf:Standard CIPS.} Reported as a by-product and compared with the Pesaran (2007) tables
shown on the same line: reject H0 when {cmd:CIPS < critical value} (the critical values
are negative; "smaller" means more negative). The modified test is preferred for
inference because its distribution is standard and free of the truncation/nuisance issues
of CIPS, but agreement between the two is reassuring.

{pstd}
{bf:Individual statistics.} {cmd:CADF_i} is each unit's cross-sectionally augmented DF
t-statistic (more negative = more evidence against a unit root). {cmd:M-CADF_i} (= D_i)
is chi-squared(q) under the null, so compare it with the printed chi-squared critical
values, or read its {cmd:p-val} column (upper tail): {cmd:p-val < 0.05} rejects the
unit root for that unit. The {cmd:lags} column shows the augmentation order selected.

{pstd}
{bf:Why M-CADF can be negative.} D = LM - CADF^2 is only asymptotically chi-squared;
in finite samples it can be negative for strongly stationary units. The reported per-unit
p-value uses |D|; treat clearly negative D as strong rejection.


{marker cautions}{...}
{title:Cautions}

{phang}o {bf:Balanced panel only}, declared with {helpb xtset}.{p_end}

{phang}o {bf:Model choice.} The modified statistics (chi-squared / N(0,1)) are defined for
{opt model(constant)} (q=2) and {opt model(trend)} (q=3). With {opt model(none)} only the
standard CIPS is produced. Choose {cmd:trend} if the series display deterministic trends.{p_end}

{phang}o {bf:Lag length.} Too few lags leaves residual serial correlation (size
distortion); too many wastes power. The default {opt ic(3)} (t-stat general-to-specific)
follows the GAUSS code; AIC tends to pick longer, SIC shorter lags. Keep {opt maxlags()}
modest relative to T.{p_end}

{phang}o {bf:Need enough T.} Each CADF regression loses {it:p}+1 observations and the
cross-section averages must be informative; very short T gives unreliable individual
statistics.{p_end}

{phang}o {bf:Cross-section dependence is assumed} and handled through the cross-sectional
averages (a single common factor). If dependence is driven by multiple strong factors,
consider a multi-factor approach in addition.{p_end}

{phang}o {bf:Relation to existing commands.} Standard Pesaran CADF/CIPS are available in
{helpb pescadf} and {helpb xtcips}; {cmd:xtcipsm} adds the {it:modified} version and shows
CADF/CIPS only for comparison.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. webuse grunfeld, clear}{p_end}
{phang2}{cmd:. xtset company year}{p_end}

{pstd}Constant model, lags by t-stat (default){p_end}
{phang2}{cmd:. xtcipsm invest, model(constant)}{p_end}

{pstd}Trend model, SIC lag selection, maximum 3 lags{p_end}
{phang2}{cmd:. xtcipsm invest, model(trend) ic(2) maxlags(3)}{p_end}

{pstd}With the two-panel CADF / M-CADF diagnostic graph{p_end}
{phang2}{cmd:. xtcipsm invest, model(constant) maxlags(3) graph}{p_end}

{pstd}Suppress the per-unit table, show only panel statistics{p_end}
{phang2}{cmd:. xtcipsm invest, model(constant) noprintind}{p_end}

{pstd}Use the stored results{p_end}
{phang2}{cmd:. xtcipsm invest, model(constant)}{p_end}
{phang2}{cmd:. display "CIPS = " r(cips) "   M-CIPS = " r(mcips) "  p = " r(mpval)}{p_end}
{phang2}{cmd:. matrix list r(results)}{p_end}

{pstd}Test the first difference if the level is found non-stationary{p_end}
{phang2}{cmd:. gen dinvest = D.invest}{p_end}
{phang2}{cmd:. xtcipsm dinvest, model(constant)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtcipsm} stores the following in {cmd:r()}:{p_end}

{synoptset 18 tabbed}{...}
{p2col 5 18 22 2: Scalars}{p_end}
{synopt:{cmd:r(cips)}}standard CIPS statistic{p_end}
{synopt:{cmd:r(mcips)}}modified CIPS (Dp) statistic{p_end}
{synopt:{cmd:r(mpval)}}lower-tail p-value of Dp{p_end}
{synopt:{cmd:r(mdbar)}}average of individual D statistics{p_end}
{synopt:{cmd:r(cv10)}, {cmd:r(cv5)}, {cmd:r(cv1)}}Pesaran CIPS critical values{p_end}
{synopt:{cmd:r(N)}, {cmd:r(T)}}panel dimensions{p_end}
{synopt:{cmd:r(model)}}deterministic model code (0/1/2){p_end}

{p2col 5 18 22 2: Matrices}{p_end}
{synopt:{cmd:r(results)}}{it:N} x 6: id, CADF, LM, M-CADF, p-value, lags{p_end}

{p2col 5 18 22 2: Macros}{p_end}
{synopt:{cmd:r(cmd)}}{cmd:xtcipsm}{p_end}


{marker references}{...}
{title:References}

{marker P2007}{...}
{phang}Pesaran, M. H. 2007. A simple panel unit root test in the presence of
cross-section dependence. {it:Journal of Applied Econometrics} 22: 265-312.{p_end}

{marker WH2016}{...}
{phang}Westerlund, J., and M. Hosseinkouchack. 2016. Modified CADF and CIPS panel unit
root statistics with standard chi-squared and normal limiting distributions.
{it:Oxford Bulletin of Economics and Statistics} 78(3): 347-364.{p_end}


{marker author}{...}
{title:Author}

{pstd}Stata implementation:{p_end}
{pmore}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}

{pstd}Original GAUSS code (TSPDLIB, proc cips):{p_end}
{pmore}Saban Nazlioglu, Pamukkale University, snazlioglu@pau.edu.tr{p_end}

{pstd}See also:{p_end}
{pmore}{helpb xtpdlib}, {helpb xtfpss}, {helpb xtpgc}{p_end}
