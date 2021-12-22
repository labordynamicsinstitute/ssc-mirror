{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] nr_create()} {hline 2}}Initialize object storing narrative sign restrictions on historical decomposition
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:nr_create(}{it:struct var_struct scalar VAR}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:nr_create(}{it:VAR}{cmd:)} outputs an associative array containing an 
array to be populated with with information on the narrative sign restrictions 
on the historical decomposition of the structural shocks. The output of this 
function, once populated, is the {it:nsr} object fed into 
{help narr_sign_restrict:narr_sign_restrict()}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:nr_create()} can be called in Stata using function 
{bf:{help var_nr_narr_create:var_nr_narr_create}}.

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
