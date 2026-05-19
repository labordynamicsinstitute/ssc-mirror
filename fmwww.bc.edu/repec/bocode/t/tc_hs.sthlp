{smcl}
{title:Title}

{p 4 4 2}
{bf:tc_hs} {hline 2} Hansen & Seo (2002) supLM test for threshold cointegration

{title:Syntax}

{p 4 8 2}
{cmd:tc_hs} {it:y1var} {it:y2var} {ifin} [{cmd:,} {opt lag(#)} {opt beta(#)} {opt trim(#)} {opt ngrid(#)}]

{title:Description}

{pstd}
Tests linear VECM against threshold VECM via the supremum-LM statistic.
Direct Mata port of {bf:tsDyn}'s {cmd:TVECM.HStest}.  Critical values are
not tabulated for arbitrary configurations -- compare to the fixed-regressor
bootstrap CVs in Hansen & Seo (2002).

{title:Stored results}
{pstd}{cmd:r(sup_lm)}  {cmd:r(threshold)}  {cmd:r(beta_est)}  {cmd:r(lag)}
{cmd:r(grid_values)}  {cmd:r(grid_stats)} (useful for {helpb tc_plot:tc_plot grid}).

{title:Also see}
{p 4 4 2}{helpb threshcoint:Package overview} | {helpb tc_tvecm} | {helpb tc_sysadl} | {helpb tc_bf} | {helpb tc_plot}{p_end}
