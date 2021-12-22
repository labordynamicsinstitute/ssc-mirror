{smcl}
{* *! version 16.0  23march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] var_nr} {hline 2}} initializes Stata/Mata objects to run var_nr Toolbox functions
{p_end}
{p2colreset}{...}

{p2colset 1 16 18 2}{...}
{p2col:{bf:Authors} {hline 2}}

Author 1 name: Abigail Kuchek	
Author 1 from: Federal Reserve Bank of Dallas, Research Department, Dallas, Texas 
Author 1 email: abigail.kuchek@dal.frb.org		

Author 2 name:  Jonah Danziger	
Author 2 from:  Federal Reserve Bank of Dallas, Research Department, Dallas, Texas
Author 2 email: jonah.danziger@dal.frb.org	

Author 3 name:  Chris Koch
Author 3 from:  International Monetary Fund, Research Department, Washington, DC
Author 3 email: ckoch2@imf.org
{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}
{p 8 12 2}
{cmd:var_nr}
{opt ident}
{cmd:,}
{cmd:}
{opt var:name("string")}
{opt opt:name("string")}
[{opt lin:trend(varname)}
{opt quad:trend(varname)}]


{marker description}{...}
{title:Description}


{pstd}
{cmd:var_nr} passes output from the previously run {bf:{help var:var}} to Mata 
in order to be used by subsequent 
{help var_nr_stata_functions:var_nr toolbox functions}. The resulting objects 
in Mata are bundled as a structure named {opt var:name}. A Mata structure storing 
options is initialized with defaults under the name specified in {opt out:name}.

{pstd}
{opt ident} must be specified. {opt lin:trend} and {opt quad:trend} {it:must} be specified if a linear and/or 
quadratic trend variable are included in the {help var:var} estimation. Details 
on these and other options provided below.


{dlgtab:Options}
{phang}

{phang}
{opt ident} specifies the  method for identifying the VAR. This option will 
accept one of three strings: "{it:oir}", "{it:bq}", or "{it:sr}". "{it:oir}" 
specifies zero short-run restrictions; "{it:bq}" specifies zero long-run 
restrictions; and "{it:sr}" specifies [narrative] sign restrictions.

{opt var:name} specifies the name of the structure that saves the output from 
the vector autoregression and resulting calculations. This string is passed into 
subsequent var_nr Toolbox functions.

{phang}
{opt opt:name} specifies the name of the structure that contains the options 
that are specified for future analysis. This string is passed into subsequent 
var_nr Toolbox functions.

{phang}
{opt lin:trend} specifies the name of the linear trend variable used in 
{help var:var} when previously run.

{phang} 
{opt quad:trend} specifies the name of the quadratic trend variable in 
{help var:var} when previously run.

{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:var_nr} runs functions {cmd:var_funct} and {cmd:opt_funct} in Mata. All 
outputs are automatically stored in Mata to be used by other 
{bf:{help var_nr_mata_functions:other functions included in the var_nr Toolbox}}.

Examples of the {help var_nr_stata_functions:var_nr toolbox functions} used are {stata do EXAMPLE_stata_shortrun} 

{stata "do EXAMPLE_data_shortrun.do"; : . stata do EXAMPLE_data_shortrun.do}.

{p 4 4 2}
For an overview of Stata functions in the toolbox, see 

        {bf:{help var_nr_stata_functions:[VAR-NR] var_nr Toolbox {hline 2} Stata functions}}.
		
