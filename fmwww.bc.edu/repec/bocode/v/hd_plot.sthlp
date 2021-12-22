{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] hd_plot()} {hline 2}}plot impulse response(s) with confidence bands
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:void} 
{cmd:hd_plot(}{it:transmorphic scalar hd, struct var_struct scalar VAR, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:hd_plot()} plots the historical decomposition of the structural shocks 
estimated using {help hd_funct:hd_funct()} identified as specified in {opt hd} 
for the SVAR stored in {it:VAR}.

{pstd}
If the SVAR was identified using short-run or long-run zero restrictions, 
{it:hd} should be filled with the output from {help hd_funct:hd_funct()}.

{pstd}
If the SVAR was identified using [narrative] sign restrictions, {it:hd} should 
be filled with the object indexed by the key string "median" in the associative 
array output by {help sr_analysis_funct:sr_analysis_funct()} with the "hd" 
option specified. In this case, the median draw is plotted.

{pstd}
Options for historical decomposition plotting are set to defaults when 
{help var_nr:var_nr} is run and are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting HD 
plotting are outlined below. Note that the options that determine the 
{help hd_funct:hd_funct()} calculations also affect {cmd:hd_plot()}, so these 
should be kept constant for the purpose of plotting.


{dlgtab:Options}

{phang}
{opt save_fmt} specifies the file type that output plots should be saved as. 
Outputs are automatically saved to the current working directory. If "none" is 
specified, then the plots are displayed, but not saved. "none" is the default.

{phang}
{opt shck_plt} allows the user to select just one shock for which historical 
decomposition should be plotted. If "all" is specified, {cmd:hd_plot()} will 
plot historical decomposition for all endogenous variables. If a variable name 
or, in the [narrative] sign restrictions case, a shock name is specified, the 
function will only plot the impulse response for the specified shock. "all" is 
the default.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:hd_plot()} can be called in Stata using function 
{bf:{help var_nr_hd_plot:var_nr_hd_plot}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}