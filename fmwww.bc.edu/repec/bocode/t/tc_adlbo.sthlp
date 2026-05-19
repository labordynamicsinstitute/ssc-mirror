{smcl}
{title:Title}
{p 4 4 2}{bf:tc_adlbo} {hline 2} ADL-BO (Boswijk) threshold cointegration test (Li & Lee 2010)

{title:Syntax}
{p 4 8 2}
{cmd:tc_adlbo} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt maxlag(#)} {opt trim(#)} {opt ngrid(#)} {opt case(c|ct)}]

{title:Description}
{pstd}
Boswijk-style variant testing joint significance of {it:y{sub:t-1}} and
{it:x{sub:t-1}} across threshold regimes.  Reports the sup-Wald statistic
along with finite-sample CVs (m = 1-4).

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adlbdm} | {helpb tc_sysadl} | {helpb tc_es}{p_end}
