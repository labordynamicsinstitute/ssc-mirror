{smcl}
{title:Title}
{p 4 4 2}{bf:tc_bf} {hline 2} Balke & Fomby (1997) sup-Wald threshold cointegration test

{title:Syntax}
{p 4 8 2}
{cmd:tc_bf} {it:depvar} {it:indepvars} {ifin} [{cmd:,} {opt maxlag(#)} {opt trim(#)} {opt ngrid(#)} {opt savegrid(name)}]

{title:Description}
{pstd}
Two-step: Engle-Granger then a sup-Wald scan over {it:n_grid} candidate
thresholds.  No tabulated CVs -- use the residual bootstrap of Balke &
Fomby (1997) or compare to the empirical distribution of sup-Wald under
a linear DGP.

{title:Stored results}
{pstd}{cmd:r(sup_wald)}, {cmd:r(threshold)}, {cmd:r(grid_values)}, {cmd:r(grid_stats)}

{title:Plot}
{phang}{cmd:tc_plot grid}  plots the grid search. See {helpb tc_plot}.{p_end}

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_eg} | {helpb tc_es} | {helpb tc_hs} | {helpb tc_plot}{p_end}
