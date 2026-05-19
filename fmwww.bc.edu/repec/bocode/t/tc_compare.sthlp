{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_compare} {hline 2} Run a panel of threshold cointegration tests and tabulate results

{title:Syntax}

{p 4 8 2}
{cmd:tc_compare} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt maxlag(#)} {opt tests(namelist)}]

{title:Description}

{pstd}
Runs a default battery of twelve tests on the same series and prints a
single comparison table with test name, statistic, 5% CV, and conclusion.
Use {opt tests()} to restrict to a subset.

{title:Default test list}

{pstd}{it:es_tar, es_mtar, glsmtar, exes, covaug_tar, covaug_mtar, bf,
supf_none, supf_slope, adlbdm, adlbo, kss}.

{title:Example}

{phang}{stata "tc_compare ln_inv ln_inc, maxlag(6)"}{p_end}
{phang}{stata "tc_compare ln_inv ln_inc, tests(es_mtar glsmtar adlbdm)"}{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_glsmtar} | {helpb tc_exes} | {helpb tc_covaug} | {helpb tc_bf} | {helpb tc_adlbdm} | {helpb tc_adlbo} | {helpb tc_supf} | {helpb tc_kss}{p_end}
