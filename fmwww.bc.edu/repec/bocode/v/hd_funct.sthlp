{smcl}
{* *! version 16.0  23march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] hd_funct()} {hline 2}}Calculate historical decomposition of SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:hd_funct(}{it:struct var_struct scalar VAR, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:var_nr_hd} returns an associative array containing historical decompositions 
for the structural vector autoregression with elements contained in structure 
{it:VAR} using identification specified in structure {it:opts}. If {it:VAR} and/or 
{it:opts} are empty or missing crucial elements, {cmd:hd_funct()} will fail.

{pstd}
The associative array is indexed by the key strings "init", "cconst", "ltrend", 
"qtrend", "exo", and "shock", which correspond to, respectively, the 
contributions from the initial value, constant, linear trend, quadratic trend, 
exogenous variable(s), and the structual shocks. These keys access matrices 
except for "shock", which accesses an associative array indexed by real integers 
that access matrices storing the historical decomposition of each structural 
shock.

{pstd}
Options for impulse response function identification and estimation are set to 
defaults when {help var_nr:var_nr} is run. They are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Options affecting HD 
calculation are outlined below:


{dlgtab:Options}

{phang}
{opt ident} specifies the method used to identify the model.
This option will accept one of three strings: "{it:oir}", "{it:bq}", or 
"{it:sr}". "{it:oir}" specifies zero short-run restrictions; "{it:bq}" 
specifies zero long-run restrictions; and "{it:sr}" specifies sign 
restrictions (pure and/or narrative).

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:hd_funct()} can be called in Stata using function 
{bf:{help var_nr_hd:var_nr_hd}}. 

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
