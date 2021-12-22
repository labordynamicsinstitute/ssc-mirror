{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_shock_set} {hline 2}}Set sign restriction on given structural shock
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_shock_set}
{cmd:,}
{cmd:}
{opt sr:name("string")}
{opt shock("string")}
{opt affecting("string")}
{opt start:hzn(num)}
[{opt end:hzn(num)}
{opt pos:itive}
{opt neg:ative}]


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:var_nr_shock_set} imposes a sign restriction on the impulse response to a 
given structural shock. {opt shock} designates the structural shock to be 
restricted. This should be filled with the shock name designated in 
{help var_nr_shock_name:var_nr_shock_name}, if a name was specified; otherwise, 
it should be filled with the corresponding variable name. {opt affecting} should 
be specified with the name of the endogenous variable whose impulse response to 
the shock is to be restricted.

{pstd}
{opt start:hzn} and {opt end:hzn} set the horizons on 
the impulse response that the sign restriction is enforced. If these are equal, 
or if {opt end:hzn} if not specified, the restriction is imposed on a single 
horizon. {opt pos:itive} indicates that the sign is restricted to be 
positive. {opt neg:ative} imposes a negative sign restriction. One of 
{opt pos:itive} and {opt neg:ative} should be specified, but these cannot both 
be specified.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_shock_set} runs the Mata function 
{bf:{help shock_set:shock_set()}}.

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
