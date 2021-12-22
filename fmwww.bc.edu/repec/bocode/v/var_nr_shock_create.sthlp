{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_shock_create} {hline 2}}Initialize object storing sign restrictions on impulse responses to structural shocks
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_shock_create}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt sr:name("string")}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:var_nr_shock_create} initializes an object that can be loaded with sign 
restrictions on the VAR specified in {opt var:name} named {opt sr:name}. The 
object is populated with sign restrictions on the impulse responses to the 
structural shocks using {help var_nr_shock_set:var_nr_shock_set} and the shocks 
are named for the purpose of plotting, if desired, using 
{help var_nr_shock_name:var_nr_shock_name}. The output should ultimately be fed 
into {help var_nr_sign_restrict:var_nr_sign_restrict}.

{pstd}
When {cmd:var_nr_shock_create} is run, all signs on the impulse responses are 
left unrestricted. Any impulses that are not explicitly restricted by 
{help var_nr_shock_set:var_nr_shock_set} are left unrestricted.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_shock_create} runs the Mata function 
{bf:{help shock_create:shock_create()}}.

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
