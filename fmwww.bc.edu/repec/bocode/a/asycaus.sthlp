{smcl}
{* *! version 1.0.4  19jul2026}{...}
{vieweralsosee "[TS] var" "help var"}{...}
{vieweralsosee "caustests" "help caustests"}{...}
{vieweralsosee "bcgcausality" "help bcgcausality"}{...}
{vieweralsosee "tvgc" "help tvgc"}{...}
{viewerjumpto "Syntax" "asycaus##syntax"}{...}
{viewerjumpto "Subcommands" "asycaus##sub"}{...}
{viewerjumpto "Description" "asycaus##desc"}{...}
{viewerjumpto "Options" "asycaus##opts"}{...}
{viewerjumpto "Examples" "asycaus##ex"}{...}
{viewerjumpto "Stored results" "asycaus##sr"}{...}
{viewerjumpto "References" "asycaus##ref"}{...}
{viewerjumpto "Author" "asycaus##auth"}{...}

{title:Title}

{phang}{bf:asycaus} {hline 2} Asymmetric Granger-causality suite for Stata

{marker syntax}{title:Syntax}

{p 8 17 2}
{cmd:asycaus} {it:subcommand} {it:depvar} {it:causvar} {ifin} [{cmd:,} {it:options}]

{p 8 17 2}
{cmd:asycaus components} {it:varlist} {ifin} [{cmd:,} {opt pos(stub)} {opt neg(stub)} {opt replace}]

{phang}
{it:depvar} is the variable that may be {it:caused}.{p_end}
{phang}
{it:causvar} is the candidate cause.{p_end}
{phang}
H{sub:0}: {it:causvar} does NOT Granger-cause {it:depvar}.

{marker sub}{title:Subcommands  (click for detailed help)}

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt :{help asycaus_static:{bf:static}}}Hatemi-J (2012) static asymmetric test with leverage bootstrap{p_end}
{synopt :{help asycaus_dynamic:{bf:dynamic}}}Hatemi-J (2021) rolling / recursive time-varying test{p_end}
{synopt :{help asycaus_fourier:{bf:fourier}}}Nazlioglu, Gormus & Soytas (2016) Fourier asymmetric TY{p_end}
{synopt :{help asycaus_spectral:{bf:spectral}}}Bahmani-Oskooee, Chang & Ranjbar (2016) frequency-domain asymmetric (BC)2006{p_end}
{synopt :{help asycaus_quantile:{bf:quantile}}}Fang, Wang, Shieh & Chung (2026) quantile asymmetric (+ optional Fourier){p_end}
{synopt :{help asycaus_efficient:{bf:efficient}}}Hatemi-J (2024) efficient SUR test (Pos / Neg / Joint / Pos=Neg){p_end}
{synopt :{help asycaus_all:{bf:all}}}Full battery + unified summary + dashboard{p_end}
{synopt :{bf:components}}Generate cumulative positive / negative shock components{p_end}
{synoptline}

{marker desc}{title:Description}

{pstd}
{cmd:asycaus} implements the full battery of {bf:asymmetric Granger causality}
tests for time series. Each subcommand decomposes the two series into
{bf:cumulative positive} and {bf:cumulative negative} shocks following
Granger and Yoon (2002), then conducts the relevant inference within an
augmented VAR (Toda and Yamamoto 1995).{p_end}

{pstd}
The package is bivariate by design (testing whether {it:causvar} causes
{it:depvar}) and follows Hatemi-J's program — the inference is exact when
combined with the leverage bootstrap (Hacker and Hatemi-J, 2006, 2012). The
default lag-selection criterion is the {bf:Hatemi-J information criterion}
(HJC; Hatemi-J 2003), with AIC, AICC, SBC and HQC also available via
{cmd:ic()}.{p_end}

{pstd}
For each subcommand a professional table is printed and a publication-quality
graph is produced (suppress with {cmd:nograph}).{p_end}

{marker opts}{title:Options common to most subcommands}

{synoptset 22 tabbed}{...}
{synopthdr:option}
{synoptline}
{synopt :{opt maxl:ag(#)}}maximum VAR lag to search over (default depends on subcommand){p_end}
{synopt :{opt ic(string)}}{bf:aic} | {bf:aicc} | {bf:sbc} | {bf:hqc} | {bf:hjc} (default){p_end}
{synopt :{opt into:rder(#)}}TY augmentation lags (max integration order). Default 1{p_end}
{synopt :{opt shock(string)}}{bf:pos} | {bf:neg} | {bf:both}. Default per subcommand{p_end}
{synopt :{opt boot(#)}}bootstrap replications (where applicable){p_end}
{synopt :{opt seed(#)}}RNG seed for the bootstrap. Default 12345{p_end}
{synopt :{opt ln:form}}take natural log of {it:depvar} and {it:causvar} first{p_end}
{synopt :{opt nograph}}suppress the graph{p_end}
{synopt :{opt sav:ing(filename)}}save the graph to {it:filename}.gph{p_end}
{synoptline}

{pstd}
Subcommand-specific options are documented on each subcommand's help page —
click the subcommand names above.

{marker ex}{title:Examples (clickable)}

{phang}Load the Lutkepohl demo data and tsset:{p_end}
{phang2}{stata "webuse lutkepohl2, clear"}{p_end}
{phang2}{stata "tsset qtr"}{p_end}

{phang}1. Generate cumulative pos/neg shocks for browsing:{p_end}
{phang2}{stata "asycaus components dln_inv dln_inc, pos(p_) neg(n_) replace"}{p_end}

{phang}2. Static Hatemi-J (2012) test:{p_end}
{phang2}{stata "asycaus static dln_inv dln_inc, maxlag(4) ic(hjc) boot(500) shock(both)"}{p_end}

{phang}3. Dynamic Hatemi-J (2021) rolling-window:{p_end}
{phang2}{stata "asycaus dynamic dln_inv dln_inc, rolling window(40) boot(200) shock(pos)"}{p_end}

{phang}4. Fourier Nazlioglu et al. (2016):{p_end}
{phang2}{stata "asycaus fourier dln_inv dln_inc, kmax(3) form(single) shock(both)"}{p_end}

{phang}5. Frequency-domain Bahmani-Oskooee et al. (2016):{p_end}
{phang2}{stata "asycaus spectral dln_inv dln_inc, nfreq(50) shock(both)"}{p_end}

{phang}6. Quantile Fang et al. (2026), with Fourier detrending:{p_end}
{phang2}{stata "asycaus quantile dln_inv dln_inc, quantiles(0.1 0.25 0.5 0.75 0.9) fourier kmax(2)"}{p_end}

{phang}7. Efficient SUR Hatemi-J (2024) — also tests Pos = Neg:{p_end}
{phang2}{stata "asycaus efficient dln_inv dln_inc, maxlag(4)"}{p_end}

{phang}8. Full battery + dashboard:{p_end}
{phang2}{stata "asycaus all dln_inv dln_inc, maxlag(4) boot(300)"}{p_end}

{marker sr}{title:Stored results}

{pstd}{cmd:asycaus} {it:subcommand} stores in {cmd:r()}:

{synoptset 22 tabbed}{...}
{p2col 5 22 26 2: Matrices}{p_end}
{synopt :{cmd:r(results)}}full table of statistics, lag, critical values, p-values{p_end}

{p2col 5 22 26 2: Scalars}{p_end}
{synopt :{cmd:r(boot)}}bootstrap replications used{p_end}
{synopt :{cmd:r(maxlag)}}max lag searched{p_end}
{synopt :{cmd:r(nsub)}}number of subsamples (dynamic){p_end}
{synopt :{cmd:r(window)} / {cmd:r(Smin)}}window length used / Phillips-Shi-Yu min (dynamic){p_end}
{synopt :{cmd:r(Wpos)} {cmd:r(Wneg)} {cmd:r(Wjoint)} {cmd:r(Wdiff)}}efficient subcommand statistics{p_end}
{synopt :{cmd:r(p_pos)} {cmd:r(p_neg)} {cmd:r(p_joint)} {cmd:r(p_diff)}}efficient subcommand p-values{p_end}
{synopt :{cmd:r(kmax)}}max Fourier frequency searched (fourier){p_end}
{synopt :{cmd:r(nfreq)}}number of spectral grid frequencies (spectral){p_end}

{p2col 5 22 26 2: Macros}{p_end}
{synopt :{cmd:r(test)}}description of the test{p_end}
{synopt :{cmd:r(depvar)} / {cmd:r(cause)}}variables tested{p_end}
{synopt :{cmd:r(shock)} / {cmd:r(ic)} / {cmd:r(form)} / {cmd:r(mode)}}selected options{p_end}

{marker ref}{title:References}

{phang}Bahmani-Oskooee, M., Chang, T., and Ranjbar, O. (2016). Asymmetric causality
using frequency-domain and time-frequency-domain (wavelet) approaches.
{it:Economic Modelling}, 56, 66–78.{p_end}

{phang}Breitung, J., and Candelon, B. (2006). Testing for short- and long-run
causality: a frequency-domain approach. {it:Journal of Econometrics}, 132, 363–378.{p_end}

{phang}Enders, W., and Jones, P. (2016). Grain prices, oil prices, and multiple smooth
breaks in a VAR. {it:Studies in Nonlinear Dynamics & Econometrics}, 20(4), 399–419.{p_end}

{phang}Fang, H., Wang, C.-H., Shieh, J. C. P., and Chung, C.-P. (2026). The asymmetric
Granger causality between banking-sector and stock-market development and economic
growth in quantiles considering Fourier. {it:Applied Economics}, 58(20), 3822–3838.{p_end}

{phang}Granger, C. W. J., and Yoon, G. (2002). Hidden cointegration. UCSD Disc. Paper 2002-02.{p_end}

{phang}Hacker, R. S., and Hatemi-J, A. (2006). Tests for causality between integrated
variables using asymptotic and bootstrap distributions: theory and application.
{it:Applied Economics}, 38(13), 1489–1500.{p_end}

{phang}Hacker, R. S., and Hatemi-J, A. (2012). A bootstrap test for causality with
endogenous lag length choice: theory and application in finance.
{it:Journal of Economic Studies}, 39(2), 144–160.{p_end}

{phang}Hatemi-J, A. (2003). A new method to choose optimal lag order in stable and
unstable VAR models. {it:Applied Economics Letters}, 10(3), 135–137.{p_end}

{phang}Hatemi-J, A. (2012). Asymmetric causality tests with an application.
{it:Empirical Economics}, 43, 447–456.{p_end}

{phang}Hatemi-J, A. (2021). Dynamic Asymmetric Causality Tests with an Application.
{it:arXiv} 2106.07612.{p_end}

{phang}Hatemi-J, A. (2024). Efficient Asymmetric Causality Tests. {it:arXiv} 2408.03137.{p_end}

{phang}Nazlioglu, S., Gormus, N. A., and Soytas, U. (2016). Oil prices and real estate
investment trusts (REITs): gradual-shift causality and volatility transmission analysis.
{it:Energy Economics}, 60, 168–175.{p_end}

{phang}Pata, U. K. (2020). How is COVID-19 affecting environmental pollution in US cities?
Evidence from asymmetric Fourier causality test. {it:Air Quality, Atmosphere & Health}, 13, 1149–1155.{p_end}

{phang}Phillips, P. C. B., Shi, S., and Yu, J. (2015). Testing for multiple bubbles:
limit theory of real-time detectors. {it:International Economic Review}, 56(4), 1043–1078.{p_end}

{phang}Toda, H. Y., and Yamamoto, T. (1995). Statistical inference in vector
autoregressions with possibly integrated processes. {it:Journal of Econometrics}, 66, 225–250.{p_end}

{marker auth}{title:Author}

{pstd}
{bf:Dr Merwan Roudane}{break}
Email: {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}

{pstd}
This package is the copyright of the author. Non-commercial use only. Proper
citation required. No performance guarantee is made. Bug reports welcome.{p_end}

{pstd}
{bf:Companion packages on SSC:}
{stata "ssc describe caustests":caustests},
{stata "ssc describe bcgcausality":bcgcausality},
{stata "ssc describe tvgc":tvgc}.{p_end}

{pstd}
{bf:Citation suggestion:}{break}
Roudane, M. (2026). {bf:asycaus}: Asymmetric Granger-causality suite for Stata.
Statistical Software Components, Boston College Department of Economics.
