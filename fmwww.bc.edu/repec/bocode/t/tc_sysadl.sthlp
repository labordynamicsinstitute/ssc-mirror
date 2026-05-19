{smcl}
{title:Title}
{p 4 4 2}{bf:tc_sysadl} {hline 2} System-equation ADL threshold cointegration test (Li 2016)

{title:Syntax}
{p 4 8 2}
{cmd:tc_sysadl} {it:varlist} {ifin} [{cmd:,} {opt lag(#)} {opt trim(#)} {opt ngrid(#)} {opt case(c|ct)}]

{title:Description}
{pstd}
System-equation extension of the ADL test of Li (2016) that does not
require weak exogeneity.  Reports the sup-Wald statistic over the
threshold grid summed across equations.  No tabulated CVs -- use bootstrap
or compare to Li (2016) tables.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adlbdm} | {helpb tc_adlbo} | {helpb tc_hs} | {helpb tc_tvecm}{p_end}
