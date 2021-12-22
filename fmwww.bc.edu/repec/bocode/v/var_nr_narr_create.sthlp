{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_narr_create} {hline 2}}Initialize object storing narrative sign restrictions on historical decomposition
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_narr_create}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt nsr:name("string")}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:var_nr_shock_create} initializes an object that can be loaded with 
narrative sign restrictions on the VAR specified in {opt var:name} named 
{opt nsr:name}. The object is populated with narrative sign restrictions on the 
historical decomposition of the structural shocks using 
{help var_nr_narr_set:var_nr_narr_set}. The output should ultimately be fed 
into {help var_nr_sign_restrict:var_nr_sign_restrict}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_narr_create} runs the Mata function 
{bf:{help nr_create:nr_create}}.

{p 4 4 2}
For an overview of functions in the toolbox, see 

        {bf:[VAR-NR] var_nr Toolbox {hline 2} {help var_nr_stata_functions:Stata functions} and {help var_nr_mata_functions:Mata functions}}.


{marker source}{...}
{title:Sources}

{p 4 4 2}
Code implements narrative sign restriction identification as proposed by 
Antolin-Diaz and Rubio-Ramirez in {it:Narrative Sign Restrictions for SVARs} 
(2018). Code follows Kilian and Lutkepohl's notation in 
{it:Structural Vector Autoregressive Analysis} (2016).
{p_end}
