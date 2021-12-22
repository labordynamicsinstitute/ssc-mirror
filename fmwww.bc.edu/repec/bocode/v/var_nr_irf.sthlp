{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr_irf} {hline 2}} Calculate impulse responses of SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr_irf}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt opt:name("string")}
{opt out:name("string")}
[{opt statamatrix("string")}
{opt sr:name}]


{marker description}{...}
{title:Description}


{pstd}
{cmd:var_nr_irf} calculates the impulse responses for
the structual vector autoregression specified in {opt var:name} estimated 
previously using {help var_nr:var_nr}. Impulse responses are stored in 
Mata (see {bf:{help irf_funct:irf_funct()}} for more details) under the 
name specified in {opt out:name}.

{pstd}
{opt statamatrix} is optional. If it is specified, a matrix containing the 
impulse responses will be generated in Stata and stored under the name 
specified within the parantheses (note the name is entered as a string but the 
name itself, of course, will not be). Column names are descriptive.

{pstd}
If the SVAR was identified using [narrative] sign restrictions, {opt sr:name} 
must be specified with the name of the credible set output by 
{help var_nr_sign_restrict:var_nr_sign_restrict}.

{pstd}
Options for impulse response function identification and estimation are set to 
defaults when {help vnrs_var_nr:var_nr} is run and are adjusted using 
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
{opt impact}  sets the size of the shock for the impulse. Options are 0 or 1. 
If it is set to "{it:0}" then shock is one standard deviation. If it is set to 
"{it:1}" the shock is 1.

{phang}
{opt shut} specifies if there is a row of the inverse-A matrix to be set to 0. 
Options are 0 or 1, where 1 specifies that a row be shut.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr_irf} runs function {bf:{help irf_funct:irf_funct()}} in Mata 
when identification strategy is short or long-run zero restrictions. If the 
SVAR is identified with [narrative] sign restrictions, 
{bf:{help sr_analysis_funct:sr_analysis_funct()}} is run in Mata. All outputs 
are automatically stored in Mata to be used by other 
{bf:{help var_nr_mata_functions:other functions included in the var_nr Toolbox}}. 

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
