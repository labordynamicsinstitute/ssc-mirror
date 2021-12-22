{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] irf_funct()} {hline 2}}Calculate impulse responses of SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:irf_funct(}{it:struct var_struct scalar VAR, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:irf_funct(}{it:VAR,opts}{cmd:)} returns an associative array containing 
impulse responses for the structual vector autoregression with elements 
contained in structure {it:VAR} using identification and other options 
specified in structure {it:opts}. If {it:VAR} and/or {it:opts} are empty or 
missing crucial elements, {cmd:irf_funct()} will fail.

{pstd}
Options for impulse response function identification and estimation are set to 
defaults when {help var_nr:var_nr} is run. They are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting IRF 
calculation are outlined below:


{dlgtab:Options}

{phang}
{opt ident} specifies the method used to identify the model.
This option will accept one of three strings: "{it:oir}", "{it:bq}", or 
"{it:sr}". "{it:oir}" specifies zero short-run restrictions; "{it:bq}" 
specifies zero long-run restrictions; and "{it:sr}" specifies sign 
restrictions (pure and/or narrative).

{phang}
{opt nsteps} specifies the number of steps for which, or the maximum horizon 
out to which, the IRF is calculated (must be positive integer).

{phang}
{opt impact} sets the size of the shock for the impulse. Options are 0 or 1. If 
it is set to "{it:0}" then shock is one standard deviation. If it is set to 
"{it:1}" the shock is 1.

{phang}
{opt shut} specifies if there is a row of the inverse-A matrix to be set to 0. 
Options are 0 or 1, where 1 specifies that a row be shut.

{phang}
{opt pctg} specifies the size of the confidence bands around the impulse 
displayed in the plotted irf. For example, if "{it:95}" is specified, then a 95% 
confidence interval is plotted.

{phang}
{opt method} specifies the method for calculating the uncertainty. If "{it:bs}" 
is specified, then the error is calculated using the residuals to 
calculate bootstraps. If "{it: wild}" is specified, then the error is calculated 
using a wild bootstrap based on a simple distribution  using Rademacher weights.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:irf_funct()} can be called in Stata using function 
{bf:{help var_nr_irf:var_nr_irf}}.

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
