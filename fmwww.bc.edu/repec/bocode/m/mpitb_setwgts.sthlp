{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_setwgts##syntax"}{...}
{viewerjumpto "Description" "mpitb_setwgts##description"}{...}
{viewerjumpto "Options" "mpitb_setwgts##options"}{...}
{viewerjumpto "Remarks" "mpitb_setwgts##remarks"}{...}
{viewerjumpto "Examples" "mpitb_setwgts##examples"}{...}
{viewerjumpto "Stored results" "mpitb_setwgts##storedresults"}{...}
{p2colset 1 18 20 2}{...}
{p2col:{bf:mpitb setwgts} {hline 2}} sets weights for a particular specification {p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mpitb setwgts ,} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:options}
{synoptline}
{p2coldent :* {opt name(mpiname)}}name of the MPI{p_end}
{p2coldent :* {opt wgtsname(wname)}}name of the weighting scheme{p_end}
{p2coldent :† {opth dimw(numlist)}}dimensional weights{p_end}
{p2coldent :† {opth indw(numlist)}}indicator weights{p_end}
{synopt :{opt store}}stores weighting scheme to the data{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}* required options; † exactly one of these options is required.{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb setwgts} may calculate and set the weighting scheme for a particular 
MPI specification. First, it calculates indicator weights for given dimensional 
weights or vice versa, depending on what the user provided. Moreover, {cmd:mpitb setwgts} stores both sets of weights for a particular MPI with the active data set.{p_end}

{pstd}
{cmd:mpitb setwgts} is intended for advanced users and programmers who wish to 
implement their own tools of analysis. For conventional analyses one may access 
all relevant functionality of {cmd:mpitb setwgts} also from {helpb mpitb est}.{p_end}

{marker options}{...}
{title:Options}

{phang}
{opt n:ame(mpiname)} {it:mpiname} is the name of the particular MPI for which the 
weights are to be set. This option is required.{p_end}

{phang}
{opt w:gtsname(wname)} {it:wname} is a name to be assigned to the chosen weighting 
scheme. Since weighting schemes are critical parameters, {it:wname} will be 
attached to every estimation, so short and concise names are strongly encouraged. 
This option is required.{p_end}

{phang}
{opth dimw(numlist)} specifies the weighting scheme for dimensions. Number of weights 
must equal number of dimensions, as provided by {helpb mpitb set}.{p_end}

{phang}
{opth indw(numlist)} specifies the weighting scheme for indicators. Number of weights 
must equal number of indicators, as provided by {helpb mpitb set}.{p_end}

{phang}
{opt st:ore} stores the weighting scheme as characteristics for the particular MPI
 with the data for later reference.{p_end}

{marker remarks}{...}
{title:Remarks}

{phang}
(1) In setting the indicator weights, {cmd:mpitb setwgts} takes the missing indicator 
policy of the global MPI into account. According to this policy, a missing indicator 
for a particular country implies that the remaining indicators of that dimension are 
re-weighted such that the weights of dimensions remain unchanged. The motivation for 
this policy is to balance a comprehensive coverage of countries in the world 
and cross-country comparability. For more details see the 
{browse "https://ophi.org.uk/publications/mpi-methodological-notes/":methodological notes}.
Technically, to detect a missing indicator the respective variable must exist and 
exclusively contain missing values.{p_end}

{marker examples}{...}
{title:Examples}

    {hline}
{phang}
First, the indicators of the MPI have to be set. Subsequently, one may specify 
the weight of dimensions and let {cmd:mpitb setwgts} calculate and set the 
indicator weights.{p_end}

{phang2}
{cmd:mpitb set , d1(d_cm d_nutr, name(hl)) d2(d_satt d_educ, name(ed)) /// } {p_end}
{phang3}
	{cmd:d3(d_elct d_sani d_wtr d_hsg d_asst d_ckfl , name(ls)) name(mympi)}
{p_end}

{phang2}
{cmd:mpitb setwgts , dimw(.5 .25 .25) wgtsname(myname) name(mympi)} {p_end}

    {hline}

{marker storedresults}{...}
{title:Stored Results}

{pstd}
{cmd:setwgts} stores the following in {cmd:r()}:
{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2:Macros}{p_end}
{synopt :{cmd:r(wgtsname)}}name of weighting scheme{p_end}
{synopt :{cmd:r(misind)}}missing indicator{p_end}
{synopt :{cmd:r(wgts_dep)}}indicator weights{p_end}
{synopt :{cmd:r(wgts_dim)}}dimensional weights{p_end}
{synopt :{cmd:r(dim_names)}}names of dimensions{p_end}
{synopt :{cmd:r(dep_vars_act)}}indicators actually found (not completely missing) {p_end}
{synopt :{cmd:r(cmd)}}command name of last {cmd:r()} posting{p_end}

{p2col 5 20 24 2:Matrices}{p_end}
{synopt :{cmd:r(wgts_dim_m)}}matrix of dimensional weights{p_end}
{synopt :{cmd:r(wgts_dep_m)}}matrix of indicator weights{p_end}

