{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_plot} {hline 2} Threshold cointegration visualisations

{title:Syntax}

{p 4 8 2}
{cmd:tc_plot regime} {it:resvar} {ifin} [{cmd:,} {opt threshold(#)} {opt model(tar|mtar)} {opt title(text)} {opt saving(name)} {opt scheme(name)}]

{p 4 8 2}
{cmd:tc_plot grid}                       [{cmd:,} {opt title(text)} {opt saving(name)} {opt scheme(name)}]

{p 4 8 2}
{cmd:tc_plot ect} {it:ectvar} {ifin}  [{cmd:,} {opt threshold(#)} {opt title(text)} {opt saving(name)} {opt scheme(name)}]

{title:Description}

{pstd}
Publication-quality {cmd:twoway} graphs for threshold cointegration analysis.

{phang}{bf:regime}: scatter of {it:resvar} colored by regime, with threshold reference line.{p_end}
{phang}{bf:grid}: plots grid statistics stored by the last test (uses {cmd:r(grid_values)}/{cmd:r(grid_stats)}).{p_end}
{phang}{bf:ect}: time-series scatter of the ECT (TVECM) colored by regime.{p_end}

{title:Examples}

{phang}{stata "tc_es ln_inv ln_inc, model(mtar)"}{p_end}
{phang}{stata "tc_plot regime _resid, threshold(0) model(mtar)"}{p_end}

{phang}{stata "tc_bf ln_inv ln_inc"}{p_end}
{phang}{stata "tc_plot grid, title(Balke-Fomby sup-Wald grid)"}{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_es} | {helpb tc_bf} | {helpb tc_hs} | {helpb tc_tvecm} | {help twoway}{p_end}
