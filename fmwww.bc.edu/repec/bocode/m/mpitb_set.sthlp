{smcl}
{* *! version 0.1.4  8 Nov 2022}{...}
{vieweralsosee "mpitb" "help mpitb"}{...}
{viewerjumpto "Syntax" "mpitb_set##syntax"}{...}
{viewerjumpto "Description" "mpitb_set##description"}{...}
{viewerjumpto "Options" "mpitb_set##options"}{...}
{viewerjumpto "Remarks" "mpitb_set##remarks"}{...}
{viewerjumpto "Examples" "mpitb_set##examples"}{...}
{p2colset 1 14 16 2}{...}
{p2col:{bf:mpitb set} {hline 2}} specifies the deprivation indicators for a MPI{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:mpitb set , }[{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt :{opt n:ame(mpiname)}}name of the MPI{p_end}
{synopt :{opt de:scription(text)}}short description of the MPI specified{p_end}
{synopt :{opt d1(varlist, subopts)}}specification of dimension 1{p_end}
{synopt :{opt ...}}...{p_end}
{synopt :{opt d10(varlist, subopts)}}specification of dimension 10{p_end}
{synopt :{opt clear}}clear all specifications{p_end}
{synopt :{opt replace}}replace specification if existing{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mpitb set} specifies the deprivation indicators for a MPI and stores this 
information with the currently loaded dataset. One may store several specifications
with one data set.{p_end}


{marker options}{...}
{title:Options}

{phang}
{opt n:ame(mpiname)} specifies the name of a particular MPI or, more precisely, its 
indicator selection. Internally, {it: mpiname} also serves as an ID and it is recommended 
to use short names (at most 10 characters are permitted).{p_end}

{phang}
{opt de:scription(text)} allows to add some extra information of the particular MPI 
to the data. This text may help to distinguish different specifications.{p_end}

{phang}
{opt d1(varlist, subopts)} assigns the variables in {varlist} as deprivation indicators to 
dimension 1. It is recommended to use short variable names (at most 10 characters are
permitted). A total of 10 dimensions is permitted. One may set the following 
{it:subopts}:{p_end}

{p 12 15 2}
{opt n:ame(dimname)} allows to choose a name for a particular dimension (optionally).
It is recommended to use short names (at most 6 characters are permitted). If no 
name is provided dimensions are generically named {it:d1}, {it:d2}, etc.{p_end}

{phang} 
{opt clear} removes all information on MPIs stored with the current data.{p_end}

{phang} 
{opt replace} replaces the information for the specified MPI.{p_end}

{marker remarks}
{title:Remarks}

{phang}
(1) {cmd: mpitb set} stores all MPI-related information as data characteristics, see
{help char} and {mansection U 12.8:[U] 12.8 Characteristics}. Specifically, 
{cmd:mpitb set} stores information about {it:mpiname}, the names of deprivation 
indicators and the names of dimensions.{p_end}

{phang}
(2) Deprivation indicators (e.g., for child mortality and nutrition) of MPIs 
are usually organized in dimensions (e.g., health). This organization may affect 
the weight a particular indicator is effectively assigned. {cmd:mpitb set} 
supports up to ten dimensions each containing an arbitrary number of indicators.
{p_end}

{phang}
(3) {cmd:mpitb} imposes constraints on the length of names for indicators, dimensions, 
and the MPI specification to prevent exceeding {cmd:} Stata internal limits 
(e.g., variable name length).
{p_end}


{marker examples}
{title:Examples}

    {hline}
{pstd}
1. A multidimensional poverty measure similar to the global MPI with 10 indicators 
organized in three dimensions (health, education, and living standards) may be set 
as follows:
{p_end}

{phang2}
{cmd:mpitb set , name(mympi) d1(d_cm d_nutr, name(hl)) /// } {p_end}
{phang3}	
	{cmd:d2(d_satt d_educ, name(ed)) /// } {p_end}
{phang3}	
	{cmd:d3(d_elct d_wtr d_sani d_hsg d_ckfl d_asst, name(ls))}
{p_end}

    {hline}
{pstd}2. One may specify several different trial measures before moving to the actual 
estimations:{p_end}

{phang2}
{cmd:mpitb set , name(trial01) d1(d_cm d_nutr_v01, name(hl)) /// } {p_end}
{phang3}	
	{cmd:d2(d_satt_v01 d_educ, name(ed)) /// } {p_end}
{phang3}	
	{cmd:d3(d_elct d_wtr d_sani_v01 d_hsg d_ckfl d_asst_v01, name(ls))}
{p_end}

{phang2}
{cmd:mpitb set , name(trial02) d1(d_cm d_nutr_v02, name(hl)) /// } {p_end}
{phang3}	
	{cmd:d2(d_satt_v02 d_educ, name(ed)) /// } {p_end}
{phang3}	
	{cmd:d3(d_elct d_wtr d_sani_v02 d_hsg d_ckfl d_asst_v02, name(ls))}
{p_end}

    {hline}

{pstd}3. Clear all information on MPI specifications previously stored with data 
using {cmd: mpitb set}.{p_end}
	
{phang2}
	{cmd:mpitb set , clear}{p_end}

    {hline}
