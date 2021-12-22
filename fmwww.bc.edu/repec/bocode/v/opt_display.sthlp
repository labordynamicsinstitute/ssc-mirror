{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] opt_display()} {hline 2}}displays current options settings
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:void function} 
{cmd:opt_display(}{it:struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:opt_display()} displays the current settings of options affecting SVAR 
identification, estimation, plotting, and other cosmetic toolbox elements.


{marker remarks}{...}
{title:Remarks}

{pstd}
The Stata function {bf:{help var_nr_options_display:var_nr_options_display}} 
functions similarly to {cmd:opt_display()}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.

{p_end}