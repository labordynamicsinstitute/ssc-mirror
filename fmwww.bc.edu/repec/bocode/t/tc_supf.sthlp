{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_supf} {hline 2} Schweikert (2019) supF* -- threshold cointegration with structural break

{title:Syntax}

{p 4 8 2}
{cmd:tc_supf} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt model(tar|mtar)} {opt breaktype(#)} {opt maxlag(#)} {opt threshold(#)} {opt u(#)} {opt trim(#)} {opt criterion(aic|bic)}]

{title:Description}

{pstd}
Direct port of the original {it:supF.r} routine from the SNDE supplement.
Performs threshold cointegration testing robust to structural breaks
in the long-run relationship.

{title:Break types}

{synoptset 30 tabbed}{...}
{synopt:{opt breaktype(1)}}no break (standard E-S){p_end}
{synopt:{opt breaktype(2)}}C{sub:0} -- intercept shift{p_end}
{synopt:{opt breaktype(3)}}C/T -- trend shift{p_end}
{synopt:{opt breaktype(4)}}C/S -- slope shift{p_end}
{synoptline}

{pstd}When breaktype>1, the breakpoint is searched within
[{it:trim}·T, (1-{it:trim})·T].  The supremum of the Φ statistic over the
breakpoint grid is reported as F*.

{title:Example}
{phang}{stata "tc_supf ln_inv ln_inc, breaktype(4) maxlag(4) model(tar)"}{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_glsmtar} | {helpb tc_bf} | {helpb tc_compare}{p_end}
