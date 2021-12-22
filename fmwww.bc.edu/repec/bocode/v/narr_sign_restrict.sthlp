{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] narr_sign_restrict()} {hline 2}}Routine to generate sign- and narrative-sign-identified credible set for SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:narr_sign_restrict(}{it:struct var_struct scalar VAR, transmorphic scalar S, struct opt_struct scalar opts, transmorphic scalar nsr}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:narr_sign_restrict(}{it:VAR,S,opts,nsr}{cmd:)} generates a credible set 
of SVARs identified using both sign and narrative sign restrictions 
(Antolin-Diaz & Rubio-Ramirez 2018). Its output is an associative array 
containing VAR {it:var_struct} structures that satisfy the sign restrictions on 
the IRF specified in {it:S} as well as the narrative restrictions on the 
historical decomposition specified in {it:nsr} (more details on setting these 
restrictions in the help files for {help shock_create:shock_create()}) and 
{help nr_create:nr_create()}.

{pstd}
{cmd:narr_sign_restrict()} is an extension of the traditional sign restriction 
algorithm. This is outlined in the help file for 
{help sign_restrict:sign_restrict()}. {cmd:narr_sign_restrict()} adds an 
additional step by verifying that narrative restrictions are satisfied for any 
draw for which sign restrictions are satisfied. If so, the draw is retained. 
Otherwise, it is discarded, and the algorithm begins anew.

{pstd}
If the user wishes to use only narrative sign restrictions on the historical 
decomposition without enforcing sign restrictions on the impulse responses, they 
will need to generate an {it:S} object using {help shock_create:shock_create()} 
and leave it unrestricted (simply by never filling it using 
{help shock_set:shock_set()}).

{pstd}
Options for (narrative) sign restriction identification and functioning are set 
to defaults when {help var_nr:var_nr} is run. They are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Relevant options are outlined 
below. Note that options affecting impulse response calculations and 
historical decompositions are naturally relevant as well, and are outlined in 
the help files for {help irf_funct:irf_funct()} and {help hd_funct:hd_funct()}.


{dlgtab:Options}

{phang}
{opt ndraws} specifies the target number of successful draws. When 
{cmd:sign_restrict} has generated the target number of draws that satisfy 
the given sign restrictions, the functions stops. This value should be a 
positive integer.

{phang}
{opt err_lmt} specifies the maximum number of draws that fail to satisfy the 
sign restrictions on the impulse responses before the first successful draw that 
the {cmd:sign_restrict} algorithm should tolerate. If this threshold is met, the 
function aborts with an error message. This value should be a positive integer.

{phang}
{opt updt} indicates whether the {cmd:sign_restrict} function should 
periodically update the user on its progress. Options are "yes" or "no". If 
"yes", the function will display the number of draws satisfying the sign 
restrictions, the number of draws satisfying both sign and narrative sign 
restrictions, and the number of total draws so far at the interval set by the 
{opt updt_frqcy} option.

{phang}
{opt updt_frqcy} specifies how often the {cmd:sign_restrict} function updates the 
user on its progress if {opt updt} is set to "yes". After every {opt updt_frqcy} 
draws, function prints the number of draws satisfying the sign restrictions, the 
number of draws satisfying both sign and narrative sign restrictions, and the 
number of total draws so far. This value should be a positive integer.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:narr_sign_restrict()} can be called in Stata using function 
{bf:{help var_nr_sign_restrict:var_nr_sign_restrict}}.

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
