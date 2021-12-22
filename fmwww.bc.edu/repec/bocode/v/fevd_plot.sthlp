{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] fevd_plot()} {hline 2}}plot forecast error variance decomposition(s) with confidence bands
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:void} 
{cmd:fevd_plot(}{it:transmorphic scalar fevd, struct fevd_bands_struct scalar fevdb, struct var_struct scalar VAR, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:fevd_plot()} plots the forecast error variance decompositions, {it:fevd}, 
identified as specified in {it:opts} for the SVAR stored in {it:VAR}. It also 
plots confidence intervals, which are entered as {it:fevdb}.

{pstd}
If the SVAR was identified using short-run or long-run zero restrictions, 
{it:fevd} should be filled with the output from {help fevd_funct:fevd_funct()} and 
{it:fevdb} should be filled with the ouptut from 
{help fevd_bands_funct:fevd_bands_funct()}.

{pstd}
If the SVAR was identified using [narrative] sign restrictions, {it:fevd} should 
be filled with the object indexed by the key string "median" in the associative 
array output by {help sr_analysis_funct:sr_analysis_funct()} with the "fevd" 
option specified. {it:fevdb} should be filled with the object indexed by "bands" 
from the same associative array. In this case, the median draw is plotted and 
confidence bands are the draws corresponding to the {opt pctg}-percentiles as 
set by {it:opts}.

{pstd}
Options for impulse response function plotting are set to defaults when 
{help var_nr:var_nr} is run and are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting FEVD 
plotting are outlined below. Note that the options that determine the 
{help fevd_funct:fevd_funct()} and {help fevd_bands_funct:fevd_bands_funct()} 
calculations also affect {cmd:fevd_plot()}, so these should be kept 
constant for the purpose of plotting.


{dlgtab:Options}

{phang}
{opt save_fmt} specifies the file type that output plots should be saved as. 
Outputs are automatically saved to the current working directory. If "none" is 
specified, then the plots are displayed, but not saved. "none" is the default.

{phang}
{opt shck_plt} allows the user to select just one shock for which forecast error 
variance decompositions should be plotted. If "all" is specified, 
{cmd:fevd_plot()} will plot impulse responses for all endogenous variables. If a 
variable name or, in the [narrative] sign restrictions case, a shock name is 
specified, the function will only plot the forecast error variance decompositions 
for the specified shock. "all" is the default.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:fevd_plot()} can be called in Stata using function 
{bf:{help var_nr_fevd_plot:var_nr_fevd_plot}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}