{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "mpitb set" "help mpitb_set"}{...}
{vieweralsosee "mpitb est" "help mpitb_est"}{...}
{vieweralsosee "mpitb show" "help show"}{...}
{vieweralsosee "mpitb est2dta" "help est2dta"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "mpitb ctyselect" "help mpitb_ctyselect"}{...}
{vieweralsosee "mpitb undpwr" "help mpitb_undpwr"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "mpitb assoc" "help mpitb_assoc"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "mpitb setwgts" "help mpitb_setwgts"}{...}
{vieweralsosee "mpitb genwgts" "help mpitb_genwgts"}{...}
{vieweralsosee "mpitb gafvars" "help mpitb_gafvars"}{...}
{viewerjumpto "Syntax" "mpitb##syntax"}{...}
{viewerjumpto "Description" "mpitb_estcot##description"}{...}
{viewerjumpto "Options" "mpitb_estcot##options"}{...}
{viewerjumpto "Remarks" "mpitb_estcot##remarks"}{...}
{viewerjumpto "Examples" "mpitb_estcot##examples"}{...}
{p2colset 1 17 18 2}{...}
{p2col:{bf:mpitb estcot} {hline 2}}estimates changes over time{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd: mpitb estcot} ,  [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent :* {opt fr:ame(name)}}name of frame where to store results{p_end}
{p2coldent :* {opt tv:ar(varname)}}time variable (counter){p_end}
{p2coldent :* {opt y:ear(varname)}}year variable (for annualisation){p_end}
{p2coldent :† {opt inseq:uence}}estimate of consecutive changes{p_end}
{p2coldent :† {opt tot:al}}estimate overall change{p_end}
{synopt:{opt sub:gvar(varname)}}subgroup variable{p_end}
{synopt:{opt ann}}annualises changes{p_end}
{synopt:{opt raw}}raw changes{p_end}
{p2coldent :* {opt m:easure}}name of measure (pass through to {help mpitb_stores:mpitb stores}){p_end}
{p2coldent :* {opt sp:ec}}name of specification (pass through to {help mpitb_stores:mpitb stores}){p_end}
{synopt:{it:stores_options}}any other {helpb mpitb_stores:mpitb stores} option{p_end}
{synoptline}
{p 4 6 2}* required options; † at least of these options is required.{p_end}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd: mpitb estcot} estimates changes over time for a single custom quantity and 
is intended for advanced users and programmers. For a more comprehensive estimation 
of changes over time of standard quantities, see {helpb mpitb_est:mpitb est}.{p_end}

{pstd}
Estimated changes may be absolute and relative and, moreover, annualised or raw. 
Standard errors and confidence intervals are provided, too. Changes may also be 
estimated by subgroups and, where data permits, for all consecutive years 
(i.e. year-to-year changes) and the total change (i.e. from the first to the last 
period of observation.{p_end}

{pstd}
{cmd: mpitb estcot} assumes that the levels over time have been previously estimated
using, for instance, {cmd:mean ... , over({it:t})} where {it:t}
is the time variable. 
{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt fr:ame(name)} specifies the name of the frame where to store results. Result 
frame may be created using {helpb mpitb_est:mpitb est} or {helpb mpitb mpitb_rframe:mpitb rframe}.

{phang}
{opt tv:ar(varname)} specified the time variable, which identifies the different 
rounds of the survey in the data.

{phang}
{opt y:ear(varname)} specifies the variable which is used for the annualisation, 
which is usually a year variable, where decimal digits are permitted.

{phang}
{opt inseq:uence} results in producing all consecutive (i.e. year-to-year) changes. 
At least one of {cmd:insequence} and {bf:total} must be specified. 

{phang}
{opt tot:al} results in producing the overall change, i.e. from the first to the
last period of observation. At least one of {cmd:insequence} and {bf:total} must 
be specified. 


{phang}
{opt sub:gvar(varname)} specifies variable identifying the subgroups. 

{phang}
{opt raw} produces the raw, i.e. non-annualised changes over time. This option is activated 
by default. Specify {cmd: noraw} to skip the estimation of raw changes.

{phang}
{opt ann} produces annualised changes over time. This option is activated by default. 
Specify {cmd: noann} to skip the estimation of annualised changes.

{phang}
{opt m:easure(name)} specifies the name of measures for which changes are estimated. 
Essential meta information to be stored with any estimate.

{phang}
{opt sp:ec(name)} specifies the name of the specification for which changes are 
estimated. Essential meta information to be stored with any estimate.

{marker remarks}{...}
{title:Remarks}

{phang}
1. Last estimates have to be obtained by {helpb mean}.

{phang}
2. For a coherent result file additional information may have to be passed to 
{helpb mpitb stores} using its options.

{phang}
3. Technically, the program relies on {helpb lincom:lincom} for absolute and 
{helpb nlcom:nlcom} for relative changes.


{marker examples}{...}
{title:Examples}

    {hline}
{pstd}Setup the results frame{p_end}

{phang2}{cmd:mpitb rframe , frame(mycot) cot}

{pstd}Estimate quantity of interest{p_end}

{phang2}{cmd:svy : mean d_cm , over(t)}

{pstd}Estimate changes over time and store in results frame{p_end}

{phang2}{cmd:mpitb estcot, frame(mycot) tvar(t) total m(mym) sp(myspec) y(year_cot)}

{pstd}Estimate quantity of interest by subpopulation{p_end}

{phang2}{cmd:svy : mean d_cm , over(t area)}

{pstd}Estimate changes over time by subpopulation and store in results frame{p_end}

{phang2}{cmd:mpitb estcot , frame(mycot) subgvar(area) tvar(t) total measure(mym) spec(myspec) y(year_cot)}

    {hline}
	
	
