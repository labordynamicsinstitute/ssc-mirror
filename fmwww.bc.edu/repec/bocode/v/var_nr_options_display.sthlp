{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_options_display} {hline 2}}print current settings
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_options_display}
{cmd:,}
{cmd:}
{opt opt:name("string")}
[{opt all}
{opt ident}
{opt nsteps}
{opt impact}
{opt shut}
{opt pctg}
{opt method}
{opt savefmt}
{opt shckplt}
{opt ndraws}
{opt errlmt}
{opt updtfrqcy}
{opt updt}]


{marker description}{...}
{title:Description}
{pstd} 
{cmd:var_nr_options_display} displays the current settings for the options that are used in creating 
the structual vector autoregression specified in {opt opt:name} and the analysis following including 
impulse response, forecast error variance decomposition, and the historical decomposition. For more 
information on these options, look at {help var_nr_options:var_nr_options}.

{pstd}
If {opt all} is specified, then every options' current setting is printed. Otherwise, the setting is 
printed for every option that is specified.


{marker remarks}{...}
{title:Remarks}

{pstd}
The Mata function {bf:{help options_display:options_display()}} achieves the same effect. 

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code for this function is adapted from Ambrogio Cesa-Bianchi's VAR Toolbox. 
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}

