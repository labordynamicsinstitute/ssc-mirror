{smcl}
{* 23jul2026}{...}
{vieweralsosee "xtpstat" "help xtpstat"}{...}
{vieweralsosee "xtbreaklm" "help xtbreaklm"}{...}
{vieweralsosee "xtfaclm" "help xtfaclm"}{...}
{vieweralsosee "xtpanicsb" "help xtpanicsb"}{...}
{vieweralsosee "xtpdcause" "help xtpdcause"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "xtflexur (panel factor unit root)" "help xtflexur"}{...}
{vieweralsosee "flexur (time series)" "help flexur"}{...}
{vieweralsosee "ffrals (time series, Fourier+RALS)" "help ffrals_hub"}{...}
{title:Title}

{phang}
{bf:xtpdroot} {hline 2} Second-generation panel unit-root and stationarity tests
robust to cross-sectional dependence

{title:Description}

{pstd}
{bf:xtpdroot} collects panel unit-root and {it:stationarity} tests that control
for cross-sectional dependence through common factors (the PANIC approach) and,
where relevant, structural breaks. Commands read the panel from {helpb xtset},
return everything in {cmd:r()}, and ship cross-linked help with a companion
{it:methods} page. It complements {helpb xtflexur} (factor-based panel unit-root
tests) and {helpb flexur} (single-series tests).

{title:Commands}

{synoptset 22 tabbed}{...}
{synopthdr:command}
{synoptline}
{syntab:Panel stationarity}
{synopt:{helpb xtpstat}}CSD-robust panel stationarity tests: Yin-Wu (2000),
Bai-Ng (2005) PANIC, and Hadri-Kurozumi (2012) cross-section-augmented KPSS{p_end}
{syntab:Panel unit root with breaks}
{synopt:{helpb xtbreaklm}}panel LM unit-root tests with structural breaks:
Enders-Lee flexible-Fourier (smooth) and Lee-Tieslau two-break (sharp){p_end}
{synopt:{helpb xtfaclm}}factor-augmented panel LM unit-root test with two breaks
(PANIC + Lee-Strazicich){p_end}
{synopt:{helpb xtpanicsb}}PANIC panel unit-root test with sharp breaks and the MSB
statistic (Bai-Carrion 2009){p_end}
{syntab:Panel causality}
{synopt:{helpb xtpdcause}}CSD-robust panel Granger causality (lag-augmented VAR
with PANIC / PANIC-CA factor correction){p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Further {bf:xtpdroot} commands (PANIC with sharp breaks, panel Lagrange-multiplier
tests with breaks, factor-corrected panel causality) build on the same factor
engine and are documented under their own help files.

{title:Author}

{pstd}Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}{p_end}
