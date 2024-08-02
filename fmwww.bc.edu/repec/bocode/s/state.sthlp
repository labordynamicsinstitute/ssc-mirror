{smcl}
{* *! version 0.0.1 05feb2024}{...}
{vieweralsosee "[P] creturn" "mansection P creturn"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "state##syntax"}{...}
{viewerjumpto "Description" "state##description"}{...}
{viewerjumpto "Example" "state##examples"}{...}
{viewerjumpto "Returned Values" "state##retvals"}{...}
{viewerjumpto "Additional Information" "state##additional"}{...}
{viewerjumpto "Contact" "state##contact"}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 32 2}
{cmd:state}

{marker description}{...}
{title:Description}

{pstd} 
{cmd:state} is part of the {help crossvalidate} suite of tools to implement 
cross-validation methods with Stata estimation commands. {cmd:state} is used 
internally by the {help xv} and {help xvloo} commands to return information 
about the current state to the end user and to bind that information to the 
dataset via dataset characteristics.

{marker examples}{...}
{title:Example}

{p 8 4 2}{stata state}{p_end}

{marker retvals}{...}
{title:Returned Values}
{p 4 4 8}The following lists the names of the r-macros and their contents.{p_end}

{synoptset 25 tabbed}{...}
{synoptline}
{synopthdr}
{synoptline}
{synopt :{cmd:r(rng)}}the current set rng setting{p_end}
{synopt :{cmd:r(rngcurrent)}}the current RNG in effect{p_end}
{synopt :{cmd:r(rngstate)}}the current state of the runiform() generator{p_end}
{synopt :{cmd:r(rngseed)}}the seed last set for the stream RNG{p_end}
{synopt :{cmd:r(rngstream)}}the current stream of the stream RNG{p_end}
{synopt :{cmd:r(filename)}}the name of the file loaded in memory{p_end}
{synopt :{cmd:r(filedate)}}the last saved date of the file in memory{p_end}
{synopt :{cmd:r(version)}}the current Stata version{p_end}
{synopt :{cmd:r(currentdate)}}the current date{p_end}
{synopt :{cmd:r(currenttime)}}the current time{p_end}
{synopt :{cmd:r(stflavor)}}the flavor of Stata currently in use (i.e., BE, SE, MP){p_end}
{synopt :{cmd:r(processors)}}the number of processors currently set for use{p_end}
{synopt :{cmd:r(hostname)}}the name of the host machine{p_end}
{synopt :{cmd:r(machinetype)}}description of the hardware platform{p_end}
{synoptline}

{marker additional}{...}
{title:Additional Information}
{p 4 4 8}If you have questions, comments, or find bugs, please submit an issue in the {browse "https://github.com/wbuchanan/crossvalidate":crossvalidate GitHub repository}.{p_end}


{marker contact}{...}
{title:Contact}
{p 4 4 8}William R. Buchanan, Ph.D.{p_end}
{p 4 4 8}Sr. Research Scientist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}wbuchanan at sagcorp [dot] com{p_end}

{p 4 4 8}Steven D. Brownell, Ph.D.{p_end}
{p 4 4 8}Economist, SAG Corporation{p_end}
{p 4 4 8}{browse "https://www.sagcorp.com":SAG Corporation}{p_end}
{p 4 4 8}sbrownell at sagcorp [dot] com{p_end}
