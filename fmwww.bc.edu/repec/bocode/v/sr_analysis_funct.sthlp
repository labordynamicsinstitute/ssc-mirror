{smcl}
{* *! version 16.0  18march2021}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:[VAR-NR] sr_analysis_funct()} {hline 2}}calculate IRFs, FEVDs, and HDs for [narrative] sign-identified SVARs
{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 12 2}
{it:transmorphic scalar function} 
{cmd:sr_analysis_funct(}{it:string scalar output, transmorphic scalar sro, struct opt_struct scalar opts}{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sr_analysis_funct()} calculates impulse response functions, forecast error 
variance decompositions, and historical decompositions for [narrative] 
sign-identified SVARs. {it:output} can be set as "irf", "fevd" or "hd" to 
generate the IRFs, FEVDs, or HDs, respectively, of every VAR in the credible set 
stored in the object {it:sro} output by {help sign_restrict:sign_restrict()} or 
{help narr_sign_restrict:narr_sign_restrict()}.

{pstd}
The output of the function is an associative array indexed by string keys. "all" 
accesses an integer-indexed associative array containing the output of 
{help irf_funct:irf_funct()}, {help fevd_funct:fevd_funct()} or 
{help hd_funct:hd_funct()} for each VAR in the credible set. "median" accesses 
the median IRF, FEVD, or HD from the set contained in "all" (for the HD, this 
is the median of the decomposition of the forecast errors of the structural 
shocks). Additionally, in the IRF and FEVD cases, "bands" accesses the IRFs and 
FEVDs corresponding to the {otp pctg}-percentiles as set by {it:opts}.

{pstd}
Options for identification and estimation executed by 
{cmd:sr_analysis_funct()} are set to defaults when {help var_nr:var_nr} is run. 
They are adjusted using {help var_nr_options:var_nr_options} in Stata or using 
standard {it:structure.element} structure syntax in Mata. Options affecting 
{cmd:sr_analysis_funct} calculation are outlined below:


{dlgtab:Options}

{phang}
{opt ident} must be set equal to "{it:sr}" to run {cmd:sr_analysis_funct()}, 
specifying [narrative] sign-restriction identification.

{phang}
{opt nsteps} specifies the number of steps for which, or the maximum horizon 
out to which, the IRF or FEVD is calculated (must be positive integer).

{phang}
{opt impact} sets the size of the shock for the impulse. Options are 0 or 1. If 
it is set to "{it:0}" then shock is one standard deviation. If it is set to 
"{it:1}" the shock is 1.

{phang}
{opt shut} specifies if there is a row of the inverse-A matrix to be set to 0. 
Options are 0 or 1, where 1 specifies that a row be shut.

{phang}
{opt pctg} specifies the size of the confidence bands around the IRF or FEVD 
displayed when plotted. For example, if "{it:90}" is specified, then a 90% 
confidence interval is plotted. In the case of [narrative] sign identification, 
this would correspond to the IRF or FEVD draws corresponding to the fifth 
percentile and the ninety-fith percentile.


{marker remarks}{...}
{title:Remarks}

{pstd}
{cmd:sr_analysis_funct()} is called in Stata by 
{bf:{help var_nr_irf:var_nr_irf}}, {bf:{help var_nr_fevd:var_nr_fevd}} and 
{bf:{help var_nr_hd:var_nr_hd}} when {opt sr:name} is specified.

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