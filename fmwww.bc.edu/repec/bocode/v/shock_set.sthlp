{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] shock_set()} {hline 2}}Set sign restriction on given structural shock
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:shock_set(}{it:real scalar start, real scalar end, string scalar sign, string scalar shock, string scalar affected, transmorphic scalar S}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:shock_set(}{it:start,end,sign,shock,affected,S}{cmd:)} 
imposes a sign restriction on the impulse response to a given structural shock. 
{it:start} and {it:end} set the horizons on the impulse response that the sign 
restriction is enforced. If these are equal, the restriction is imposed on a 
single horizon. {it:sign} indicates whether the sign is restricted to be 
positive or negative; this argument accepts "positive", "pos", "+", "negative", 
"neg", or "-". {it:shock} should be loaded with the name of the shock that is 
being restricted as it is entered in {help shock_name:shock_name()} (if the shock 
is not named, the corresponding variable name should be entered instead). 
{it:affected} should be filled with the name (as a string) of the endogenous 
variable whose impulse response to the specified shock is to be restricted. 
{it:S} is the sign restriction object output by 
{help shock_create:shock_create()} that is to be updated. The function has no 
output, but updates {it:S}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:shock_set()} can be called in Stata using function 
{bf:{help var_nr_shock_set:var_nr_shock_set}}.

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
