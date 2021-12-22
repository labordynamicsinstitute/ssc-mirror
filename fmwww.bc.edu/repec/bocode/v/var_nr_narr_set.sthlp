{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_narr_set} {hline 2}}Set narrative sign restriction on given shock for given time period
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_narr_set}
{cmd:,}
{cmd:}
{opt nsr:name("string")}
{opt start:pd(num)}
{opt shock("string")}
[{opt end:pd(num)}
{opt pos:itive}
{opt neg:ative}
{opt most:important}
{opt least:important}
{opt overwhelm:ing}
{opt neglig:ible}
{opt affecting("string")}]


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:var_nr_narr_set} imposes a narrative sign restriction on part of the 
historical decomposition of a given variable's fluctuations in response to the 
specified structural shock. The fuction populates the object created by 
{help var_nr_narr_create:var_nr_narr_create} specified in {opt nsr:name}.

{pstd}
{opt start:pd} and {opt end:pd} set the start and end periods through which the 
restriction is enforced. If these are equal, the restriction is imposed on a 
single period. These should be in the format of the {it:timevar} set by 
{help tsset:tsset}. For example, if the user's time variable is quarterly, and 
they wish to impose a restriction on the first quarter of the year 2000 through 
the last quarter in 2002, they should enter {opt start:pd} as 
{it:{help yq:yq(2000,1)}} and {opt end:pd} as {it:yq(2002,4)}.

{pstd}
The type of narrative restriction must be identified. Following the definitions 
provided by Antolin-Diaz and Rubio-Ramirez (2018), options are {opt pos:itive}, 
{opt neg:ative}, {opt most:important}, {opt least:important}, 
{opt overwhelm:ing} and {opt neglig:ible}. Only one of these may be specified.

{pstd} 
{opt shock} should be loaded with the name of the shock that is being restricted 
as it is entered in {help var_nr_shock_name} (if the shock is not named, the 
corresponding variable name should be entered instead). {opt affecting} should 
be filled with the name (as a string) of the endogenous variable whose 
historical decomposition of the specified shock is to be restricted.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_narr_set} runs the Mata function {bf:{help nr_set:nr_set()}}.

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
