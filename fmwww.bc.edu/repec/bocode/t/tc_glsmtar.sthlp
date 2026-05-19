{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_glsmtar} {hline 2} Cook (2007) GLS-MTAR threshold cointegration test


{title:Syntax}

{p 4 8 2}
{cmd:tc_glsmtar} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt threshold(#)} {opt maxlag(#)} {opt case(c|ct)} {opt criterion(aic|bic)} {opt cbar(#)}]

{title:Description}

{pstd}
Augments the Enders-Siklos MTAR test with GLS local-to-unity detrending
of cointegrating residuals (Elliott-Rothenberg-Stock 1996), yielding
substantially higher power.  Uses Cook's (2007) finite-sample critical
values (interpolated by sample size T).

{title:Options}

{synoptset 26 tabbed}{...}
{synopt:{opt case(c|ct)}}{bf:c}: c̄ = -7 (default).  {bf:ct}: c̄ = -13.5.{p_end}
{synopt:{opt threshold(#)}}MTAR threshold (default 0){p_end}
{synopt:{opt cbar(#)}}override default c̄{p_end}
{synoptline}

{title:Example}
{phang}{stata "tc_glsmtar ln_inv ln_inc, case(c)"}{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_exes} | {helpb tc_covaug} | {helpb tc_supf} | {helpb tc_compare}{p_end}
