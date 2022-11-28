{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_assoc##syntax"}{...}
{viewerjumpto "Description" "mpitb_assoc##description"}{...}
{viewerjumpto "Options" "mpitb_assoc##options"}{...}
{viewerjumpto "Examples" "mpitb_assoc##examples"}{...}
{viewerjumpto "Stored results" "mpitb_assoc##storedresults"}{...}
{p2colset 1 16 18 2}{...}
{p2col:{bf:mpitb assoc} {hline 2}} calculates association measures for indicators{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb assoc} {varlist} {weight} {ifin} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth dep:ind(varlist)}}specifies deprivation indicators{p_end}
{synopt:{opth n:ame(name)}}{it:name} of MPI specification{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}only {opt aweight}s are allowed, see {help weight}.{p_end}



{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb assoc} calculates association measures for deprivations indicators. 
Currently supported are Cramer's V and the redundancy measures R0. For further 
details and formulae, see Alkire et al. ({help mpitb##AFSSRB2015:2015}, ch. 7.3).{p_end}

{marker options}{...}
{title:Options}

{phang} {opth dep:ind(varlist)} specifies the deprivation indicators for which the 
association measures are to be calculated.{p_end}

{phang} {opth n:ame(name)} specifies the name of a MPI specification from which to take 
the indicators for the association measure calculation.{p_end}


{marker examples}{...}
{title:Examples}

    {hline}
	
{pstd}1. Calculating association measures for arbitrary specific variables using 
weights{p_end}

{phang2}{cmd:mpitb assoc [aw=weight], dep(d_*)}

    {hline}

{pstd}2. Calculating association measures for the indicators of a particular 
MPI specification using weights{p_end}

{phang2}{cmd:mpitb assoc [aw=weight], name(trial01)}

    {hline}

	
{marker storedresults}{...}
{title:Stored Results}

{pstd}
{cmd:mpitb assoc} stores the following in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2:Macros}{p_end}
{synopt :{cmd:r(N)}}number of observations{p_end}

{p2col 5 16 20 2:Matrices}{p_end}
{synopt :{cmd:r(R0)}}redundancy measure{p_end}
{synopt :{cmd:r(CV)}}Cramer's V{p_end}
{synopt :{cmd:r(hd)}}uncensored headcount ratios{p_end}
{p2colreset}{...}
