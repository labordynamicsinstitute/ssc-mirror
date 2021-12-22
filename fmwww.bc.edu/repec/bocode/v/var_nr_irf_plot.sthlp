{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_irf_plot} {hline 2}}plot impulse response(s) with confidence bands
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_irf_plot }
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt opt:name("string")}
{opt irf("string")}
[{opt irfb:ands("string")}
{opt sr:name("string")}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:var_nr_irf_plot} plots the impulse responses to the structural 
shocks estimated using {help var_nr_irf:var_nr_irf} specified in {opt irf} for 
the SVAR specified in {opt var:name} and estimated previously using 
{help var_nr:var_nr}. It also plots confidence intervals.

{pstd}
If the SVAR was identified using short-run or long-run zero restrictions, 
{opt irfb:ands} should be specified with the name of the IRF bands object 
output by {help var_nr_irf_bands:var_nr_irf_bands}. In this case, {opt sr:name} 
should not be specified.

{pstd}
If the SVAR was identified using [narrative] sign restrictions, {opt sr:name} 
must be specified with the name of the credible set output by 
{help var_nr_sign_restrict:var_nr_sign_restrict}. In this case, {opt irfb:ands} 
should not be specified.

{pstd}
Options for impulse response function plotting are set to defaults when 
{help var_nr:var_nr} is run and are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting IRF 
plotting are outlined below. Note that the options that determine the 
{help var_nr_irf:var_nr_irf} and {help var_nr_irf_bands:var_nr_irf_bands} 
calculations also affect {cmd:var_nr_irf_plot()}, so these should be kept 
constant for the purpose of plotting. 


{dlgtab:Options}

{phang}
{opt save_fmt} specifies the file type that output plots should be saved as. 
Outputs are automatically saved to the current working directory. If "none" is 
specified, then the plots are displayed, but not saved. "none" is the default.

{phang}
{opt shck_plt} allows the user to select just one shock for which impulse 
responses should be plotted. If "all" is specified, {cmd:var_nr_irf_plot()} will 
plot impulse responses for all endogenous variables. If a variable name or, in 
the [narrative] sign restrictions case, a shock name is specified, the function 
will only plot the impulse response for the specified shock. "all" is the 
default.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_irf_plot()} calls the Mata function {bf:{help irf_plot:irf_plot}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}
