{smcl}
{* *! version 16.0  23march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_hd_plot} {hline 2}}plot the historical decomposition of the SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_hd_plot}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt opt:name("string")}
{opt hd("string")}
[{opt sr:name("string")}]


{marker description}{...}
{title:Description}


{pstd}
{cmd:var_nr_hd_plot} plots the the historical decomposition of the structural 
shocks estimated using {help var_nr_hd:var_nr_hd} specified in {opt hd} for 
the SVAR specified in {opt var:name} and estimated previously using 
{help var_nr:var_nr}.

{pstd}
If the SVAR was identified using [narrative] sign restrictions, {opt sr:name} 
must be specified with the name of the credible set output by 
{help var_nr_sign_restrict:var_nr_sign_restrict}.

{pstd}
Options for historical decomposition plotting are set to defaults when 
{help var_nr:var_nr} is run and are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting HD 
plotting are outlined below. Note that the options that determine the 
{help var_nr_hd:var_nr_hd} calculations also affect {cmd:var_nr_hd_plot()}, 
so these should be kept constant for the purpose of plotting. 


{dlgtab:Options}

{phang}
{opt save_fmt} specifies the file type that output plots should be saved as. 
Outputs are automatically saved to the current working directory. If "none" is 
specified, then the plots are displayed, but not saved. "none" is the default.

{phang}
{opt shck_plt} allows the user to select just one variable for which the 
historical decomposition should be plotted. If "all" is specified, 
{cmd:var_nr_hd_plot()} will plot historical decompositions for all endogenous 
variables. If a variable name is specified, the function will only plot the 
historical decomposition for the specified variable. "all" is the default.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_hd} runs the Mata function {bf:{help hd_plot:hd_plot()}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}
