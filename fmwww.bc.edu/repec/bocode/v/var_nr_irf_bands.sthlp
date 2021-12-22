{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_irf_bands()} {hline 2}}Calculate confidence bands for impulse responses of SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_irf_bands}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt opt:name("string")}
{opt out:name("string")}
[{opt statamatrix("string")}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:var_nr_irf} calculates the impulse responses for
the structual vector autoregression specified in {opt var:name} estimated 
previously using {help var_nr:var_nr}. Impulse responses are stored in 
Mata (see {bf:{help irf_funct:irf_funct()}} for more details) under the 
name specified in {opt out:name}. The Impulse responses are used to calculate the confidence bands around them.

{pstd}
{opt statamatrix} is optional. If it is specified, a matrix containing the 
impulse responses will be generated in Stata and stored under the name 
specified within the parantheses (note the name is entered as a string but the 
name itself, of course, will not be). Column names are descriptive.

{pstd}
Options for impulse response function identification and estimation are set to 
defaults when {help vnrs_var_nr:var_nr} is run and are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting IRF 
calculation are outlined below. Note that the same options that determine the 
{help var_nr_irf:var_nr_irf} calculations also affect {cmd:var_nr_irf_bands}, as 
well as two additional options shown below: {opt pctg} and {opt method}.


{dlgtab:Options}

{phang}
{opt pctg} specifies the size of the error bands around the impulse displayed 
in the plotted irf. For example, if {it:95} is specified, then a 95% 
confidence interval is plotted.

{phang}
{opt method} specifies the method for calculating the uncertainty. If "{it:bs}" 
is specified, then the error is calculated using the residuals to 
calculate bootstraps. If "{it:wild}" is specified, then the error is calculated 
using a wild bootstrap based on a simple distribution  using Rademacher weights.

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
it is set to {it:0} then shock is one standard deviation. If it is set to 
{it:1} the shock is 1.

{phang}
{opt shut} specifies if there is a row of the inverse-A matrix to be set to 0. 
Options are 0 or 1, where 1 specifies that a row be shut.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_irf_bands()} can be called in Mata using function 
{bf:{help irf_bands_funct:irf_bands_funct}}.

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