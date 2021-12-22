{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_shock_name} {hline 2}}Input names of structural shocks (for plotting)
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_shock_name}
{cmd:,}
{cmd:}
{opt lab:els("string")}
{opt sr:name("string")}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:var_nr_shock_name} allows the user to name the structural shocks of the SVAR 
that will be sign-identified by the restrictions outlined in {opt sr:name}. Names 
should be entered in {opt lab:els} as a string separated by commas.

{pstd}
The number of names in {opt lab:els} should be equal to the number of endogenous 
variables and should be entered in the order that these variables were entered 
when {help var:var} was initially run. For example, if the user ran 
"{it:var inflation unemployment}", {opt lab:els} should be specified as 
("Supply Shock,Demand Shock").

{pstd}
If the user does not wish to name a given shock, its slot in {opt lab:els} 
should be filled with an empty string: "". For example, to name the supply shock 
but not the demand shock shown above, {opt lab:els} should be specified as 
("Supply Shock,").


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_shock_name} runs the Mata function 
{bf:{help shock_name:shock_name()}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}
