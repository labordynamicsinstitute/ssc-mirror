{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] shock_create()} {hline 2}}Initialize object storing sign restrictions on impulse responses to structural shocks
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:shock_create(}{it:struct var_struct scalar VAR}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:shock_create(}{it:VAR}{cmd:)} outputs an associative array containing an 
array to be populated with the names of the structural shocks using 
{help shock_name:shock_name()} and a matrix to be populated with information on 
the sign restrictions on the impulse responses to the shocks using 
{help shock_set:shock_set()}. When initialized, all shocks are left unrestricted, 
which means {help shock_set:shock_set()} does not need to be run for any shocks 
the user does not wish to restrict. The output of this function, once populated, 
is the {it:S} object fed into {help sign_restrict:sign_restrict()}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:shock_create()} can be called in Stata using function 
{bf:{help var_nr_shock_create:var_nr_shock_create}}.

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
