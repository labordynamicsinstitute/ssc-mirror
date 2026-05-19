{smcl}
{title:Title}
{p 4 4 2}{bf:tc_bbc} {hline 2} BBC (2004) unit root vs SETAR test

{title:Syntax}
{p 4 8 2}
{cmd:tc_bbc} {it:varname} {ifin} [{cmd:,} {opt m(#)} {opt trim(#)} {opt type(Wald|LM|LR)}]

{title:Description}
{pstd}
Bec, Ben Salem & Carrasco (2004) unit-root null against a stationary
three-regime SETAR alternative.  Defaults: AR lag {opt m(1)},
{opt trim(0.10)}, {opt type(Wald)}.  Critical values from the {bf:tsDyn}
R package.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_adf} | {helpb tc_pp} | {helpb tc_setar} | {helpb tc_kss}{p_end}
