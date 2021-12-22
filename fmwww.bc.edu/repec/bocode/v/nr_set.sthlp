{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] nr_set()} {hline 2}}Set narrative sign restriction on given shock for given time period
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:nr_set(}{it:real scalar start, real scalar end, string scalar nr_type, string scalar shock, string scalar affected, transmorphic scalar nsr}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:nr_set(}{it:start,end,nr_type,shock,affected,S}{cmd:)} 
imposes a narrative sign restriction on part of the historical decomposition of 
a given variable's fluctuations in response to the specified structural shock.
{it:start} and {it:end} set the start and end periods through which the 
restriction is enforced. If these are equal, the restriction is imposed on a 
single period. These should be in the format of the {it:timevar} set by 
{help tsset:tsset}. For example, if the user's time variable is quarterly, and 
they wish to impose a restriction on the first quarter of the year 2000 through 
the last quarter in 2002, they should enter start as {it:{help yq:yq(2000,1)}} 
and end as {it:yq(2002,4)}. {it:nr_type} indicates what type of narrative 
restriction is implemented. Following the definitions provided by Antolin-Diaz 
and Rubio-Ramirez (2018), this argument accepts the strings "positive", 
"negative", "mostimportant", "leastimportant", "overwhelming", and "negligible". 
"positive" and "negative" may also be shortened to "pos", "+", "neg", or "-". 
{it:shock} should be loaded with the name of the shock that is 
being restricted as it is entered in {help shock_name:shock_name()} (if the 
shock is not named, the corresponding variable name should be entered instead). 
{it:affected} should be filled with the name (as a string) of the endogenous 
variable whose historical decomposition of the specified shock is to be 
restricted. {it:nsr} is the narrative sign restriction object output by 
{help nr_create:nr_create()} that is to be updated. The function has no 
output, but updates {it:nsr}.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:nr_set()} can be called in Stata using function 
{bf:{help var_nr_narr_set:var_nr_narr_set}}.

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
