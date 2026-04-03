{smcl}
{* *! version 1.0.0 26mar2026  Ben A. Dwamena (University of Michigan)}

{title:Title}

{p2col:{cmd:midas_assess} {hline 2}}Pre-model diagnostic battery for DTA meta-analysis{p_end}

{title:Syntax}

{p 8 16 2}
{cmd:midas assess} {it:tp} {it:fp} {it:fn} {it:tn} {ifin}
[{cmd:,} {opt id(varname)} {opt cc(#)} {opt cutoff(#)} {opt bacontest} {opt savegraph(string)}]

{title:Description}

{pstd}
{cmd:midas assess} runs a structured pre-model diagnostic battery before bivariate
pooling. It integrates three diagnostic tools:

{phang2}1. {bf:Bivariate boxplot + robust ellipticity diagnostic} ({cmd:midas_bivbox, robnormtest}){p_end}
{phang2}2. {bf:Kendall tau} threshold-effect test ({cmd:midas_kendall}){p_end}
{phang2}3. {bf:BACON multivariate outlier detection} (optional; requires {cmd:ssc install bacon}){p_end}

{pstd}
Results are synthesised into an overall GREEN / YELLOW / RED traffic-light
with an actionable recommendation for bivariate pooling.

{title:Options}

{phang}{opt id(varname)} study identifier for outlier labelling.{p_end}
{phang}{opt cc(#)} continuity correction; default {cmd:0.5}.{p_end}
{phang}{opt cutoff(#)} outer ellipse cutoff; default {cmd:7}.{p_end}
{phang}{opt bacontest} include BACON outlier screen (requires {cmd:bacon}).{p_end}

{title:Stored results}

{pstd}Scalars: {cmd:r(robnorm_rqq)}, {cmd:r(robnorm_maxdev)}, {cmd:r(n_out)},
{cmd:r(corr)}, {cmd:r(kendall_tau)}, {cmd:r(kendall_p)},
{cmd:r(bacon_n)}, {cmd:r(bacon_prop)}{p_end}
{pstd}Locals: {cmd:r(overall_color)}, {cmd:r(overall_text)}{p_end}

{title:Example}

{phang2}{cmd:. midas assess tp fp fn tn}{p_end}
{phang2}{cmd:. midas assess tp fp fn tn, id(study) bacontest}{p_end}

{title:Author}

{pstd}Ben Adarkwa Dwamena, MD{break}University of Michigan{break}bdwamena@umich.edu
