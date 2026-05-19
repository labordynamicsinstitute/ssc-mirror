{smcl}
{title:Title}
{p 4 4 2}{bf:tc_eqtar} {hline 2} 3-regime EQ-TAR / Band-TAR / RD-TAR (Balke-Fomby 1997)

{title:Syntax}
{p 4 8 2}
{cmd:tc_eqtar} {it:resvar} {ifin} [{cmd:,} {opt type(eq|band|rd)} {opt threshold(#)} {opt maxlag(#)} {opt trim(#)} {opt ngrid(#)}]

{title:Description}
{pstd}
Three-regime AR adjustment:

{p 8 8 2}{it:Regime low}  : e_{t-1} <= -τ{p_end}
{p 8 8 2}{it:Regime mid}  : -τ <  e_{t-1} < τ{p_end}
{p 8 8 2}{it:Regime high} : e_{t-1} >= τ{p_end}

{pstd}
{opt type(eq)} / {opt type(band)} estimate AR coefficients by regime
(Balke & Fomby's equilibrium / band-TAR).  {opt type(rd)} fits the
returning-drift specification: regime-specific intercepts with
unit-root behaviour in all regimes.

{title:Threshold}
{pstd}If {opt threshold(#)} is omitted, the optimal τ is selected by
SSR-minimisation over a grid trimmed at {opt trim()} from each side.

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_tar} | {helpb tc_setar} | {helpb tc_bf} | {helpb tc_plot}{p_end}
