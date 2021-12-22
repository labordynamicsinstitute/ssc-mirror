{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] sign_restrict()} {hline 2}}Routine to generate sign-identified credible set for SVAR
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar} 
{cmd:sign_restrict(}{it:struct var_struct scalar VAR, transmorphic scalar S, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:sign_restrict(}{it:VAR,S,opts}{cmd:)} generates a credible set of 
sign-identified SVARs. Its output is an associative array containing VAR 
{it:var_struct} structures that satisfy the sign restrictions on the IRF 
specified in {it:S} (more details on this in the help file for 
{help shock_create:shock_create()}).

{pstd}
The sign restrictions algorithm first draws an OLS reduced-form matrix of 
coefficients and variance-covariance matrix from the previously estimated VAR 
input. Additionally, a random orthonormal matrix {it:Q} is drawn. The impact 
matrix of effects on the structural shocks is then calculated as the product of 
the drawn covariance matrix and {it:Q}. The IRF of the VAR with these drawn 
elements is calculated and sign restrictions are imposed. If sign restrictions 
are satisfied, the draw is retained; otherwise, the draw is discarded, and the 
algorithm begins anew. This process repeats until the target number of credible 
draws is obtained or too many failures occur prior to a successful draw; both 
thresholds are set in the {it:opts} structure prior to running 
{cmd:sign_restrict()}.

{pstd}
Options for sign restriction identification and functioning are set to defaults 
when {help var_nr:var_nr} is run. They are adjusted using 
{help var_nr_options:var_nr_options} in Stata or using standard 
{it:structure.element} structure syntax in Mata. Relevant options are outlined 
below. Note that options affecting impulse response calculations are naturally 
relevant as well, and are outlined in the help file for 
{help irf_funct:irf_funct()}.


{dlgtab:Options}

{phang}
{opt ndraws} specifies the target number of successful draws. When 
{cmd:sign_restrict} has generated the target number of draws that satisfy 
the given sign restrictions, the functions stops. This value should be a 
positive integer.

{phang}
{opt err_lmt} specifies the maximum number of failed draws before the first
successful draw that the {cmd:sign_restrict} algorithm should tolerate. If this 
threshold is met, the function aborts with an error message. This value should 
be a positive integer.

{phang}
{opt updt} indicates whether the {cmd:sign_restrict} function should 
periodically update the user on its progress. Options are "yes" or "no". If 
"yes", the function will display the number of successful draws and the number 
of total draws so far at the interval set by the {opt updt_frqcy} option.

{phang}
{opt updt_frqcy} specifies how often the {cmd:sign_restrict} function updates the 
user on its progress if {opt updt} is set to "yes". After every {opt updt_frqcy} 
draws, function prints the number of successful draws and the number of total 
draws so far. This value should be a positive integer.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:sign_restrict()} can be called in Stata using function 
{bf:{help var_nr_sign_restrict:var_nr_sign_restrict}}.

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
