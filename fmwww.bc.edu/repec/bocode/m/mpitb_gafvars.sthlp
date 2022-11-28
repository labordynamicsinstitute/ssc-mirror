{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_gafvars##syntax"}{...}
{viewerjumpto "Description" "mpitb_gafvars##description"}{...}
{viewerjumpto "Options" "mpitb_gafvars##options"}{...}
{viewerjumpto "Remarks" "mpitb_gafvars##remarks"}{...}
{viewerjumpto "Examples" "mpitb_gafvars##examples"}{...}
{p2colset 1 18 20 2}{...}
{p2col:{bf:mpitb gafvars} {hline 2}} generates variables for the AF-framework.{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb gafvars , }[{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{p2coldent :* {opth indv:ars(varlist)}}the deprivation indicator variables{p_end}
{p2coldent :* {opth indw(numlist)}}the indicator weights{p_end}
{p2coldent :* {opt wgtsid(name)}}name of the weighting scheme{p_end}
{p2coldent :† {opt k:list}(numlist)}poverty cutoffs for which to generate the AF-variables{p_end}
{p2coldent :† {opt cvec:tor}}generate uncensored (weighted) deprivation scores{p_end}
{synopt :{opt ind:icator}}generate indicator-specific variables{p_end}
{synopt :{opt replace}}potentially existing variables will be replaced{p_end}
{synopt :{opt dou:ble}}generate non-{bf:byte} variables as {bf:double}; default is {bf:float}{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* required options; † at least one of these options is required. {p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb gafvars} generates variables of the Alkire-Foster framework. Specifically, 
it may be used to create censored and uncensored deprivation scores, and binary 
variables identifying (i) the poor and (ii) the poor and deprived in a particular 
indicator. The default is to only generate the censored deprivation score and the 
binary poverty status indicator.{p_end}

{pstd}
{cmd:mpitb gafvars} is intended for advanced users and programmers. Note that {cmd:mpitb est} 
also provides a {cmd:gen} option to generate the underlying variables.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opth indv:ars(varlist)} specifies the underlying deprivation indicator variables.{p_end}

{phang}
{opth indw(numlist)} specifies the indicator weights. The number of weights must 
equal the number of indicators, as provided by {cmd:mpitb set}.{p_end}

{phang}
{opt wgtsid(string)} sets a name for the weighting scheme, which will also be used 
in variable names.{p_end}

{phang}
{opth k:list(numlist)} specifies the cutoffs for which the variables are to be 
generated.{p_end}

{phang}
{opt cvec:tor} generates a variable containing the (uncensored) deprivation score.{p_end}

{phang}
{opt ind:icator} generates variables for the estimation of indicator-specific 
quantities (e.g., censored headcount ratios).{p_end}

{phang}
{opt replace} will replace potentially existing variables.{p_end}

{phang}
{opt dou:ble} generates non-byte variables as double; the default is float.{p_end}

{marker remarks}{...}
{title:Remarks}

{pstd}
1. {cmd:mpitb gafvars} currently generates variables according to specific naming 
conventions, which include a prefix followed by the value of {it:k} and the name 
of the weighting scheme where appropriate. Generated variables currently include 
the deprivation score ({cmd:c_{it:wgtsname}}), the censored deprivation score 
({cmd:c_{it:k}_{it:wgtsname}}), a binary variable identifying the poor ({cmd:I_{it:k}}) 
and a variable indicating the sample used for estimations ({cmd:sample}). Additionally,
variables used to estimate the censored headcount ratio ({cmd:c{it:dvar}_{it:k}_{it:wgtsname}}), 
the absolute contribution ({cmd:actb_{it:dvar}_{it:k}_{it:wgtsname}}) and the percentage 
contribution ({cmd:pctb_{it:dvar}_{it:k}_{it:wgtsname}}) are generated for every 
deprivation indicator {it:dvar}.
Note that calling {cmd:mpitb gafvars} repeatedly may, therefore, either require the 
{opt replace} option or to rename or drop previously created variables.{p_end}

{pstd} 
2. As {cmd:mpitb gafvars} does not read any information from data characteristics, 
everything must be provided via options.{p_end}

{pstd}
3. Currently {cmd:mpitb gafvars} does not perform any consistency checks on the input 
provided by the user. In particular, inconsistent input may lead to the 
{err:gcvec():  3200  conformability error}.{p_end}

{marker examples}{...}
{title:Examples}

    {hline}
{pstd}
1. To generate censored and uncensored deprivation scores and a binary variable  
indicating the poverty status for a three indicator measure, one may issue {p_end}

{phang2}
	{cmd:mpitb gafvars , indv(d_cm d_nutr d_satt) indw(.5 .25 .25) wgtsid(eql) k(33) cvec}{p_end}

    {hline}
