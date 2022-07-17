{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[P] timer" "help timer"}{...}
{viewerjumpto "Syntax" "toc##syntax"}{...}
{viewerjumpto "Description" "toc##description"}{...} 
{viewerjumpto "Examples" "toc##examples"}{...}
{viewerjumpto "Contact" "toc##contact"}{...}
{title:Title}

{phang}
{bf:tic & toc} {hline 2} Simplified timer commands 


{marker syntax}{...}
{title:Syntax}

{pstd}Start the timer

{p 8 17 2}
{cmdab:tic} [{it:#} {cmd:,} {opt p:ause} {opt r:esume}]  

{pstd}Measure the elapsed time

{p 8 17 2}
{cmdab:toc} [{it:#}]
 
{pstd}where {it:#} is an integer, 1 through 100.


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt p:ause}}pauses the timer (number {it:#} if {it:#} provided) {p_end}
{synopt:{opt r:esume}}resumes the timer (number {it:#} if {it:#} provided) {p_end}
{synoptline}
{p2colreset}{...} 


{marker description}{...}
{title:Description}

{pstd}
{bf:tic & toc} are simplified timer commands for measuring elapsed time. 
 
{pstd}
{bf:tic} activates the timer and {bf:toc} displays the time elapsed since activation. This information is also stored as an r-class scalar. A {bf:tic} can be followed by multiple {bf:toc}s, and the timer can be paused and resumed as needed.  

{pstd}
An integer {it:#} = 1..100 can be used to distinguish multiple timers running at once. {it:#} is set to 100 if no number is provided.

{marker examples}{...}
{title:Examples}

    Basic use:
	
{phang2}{cmd:. tic}{p_end}
{phang2}{cmd:. sleep 1000}{p_end}
{phang2}{cmd:. toc}{p_end}

    {hline}
	
    Pausing and resuming Timer 1 while Timer 2 is running:
	
{phang2}{cmd:. tic 1}{p_end}
{phang2}{cmd:. tic 2}{p_end}
{phang2}{cmd:. sleep 1000}{p_end}

{phang2}{cmd:. tic 1, pause}{p_end}
{phang2}{cmd:. sleep 1000}{p_end}

{phang2}{cmd:. tic 1, resume}{p_end}
{phang2}{cmd:. sleep 1000}{p_end}

{phang2}{cmd:. toc 1}{p_end}
{phang2}{cmd:. toc 2}{p_end}
	

{marker contact}{...}
{title:Contact}

{phang2}Jan Kabátek, The University of Melbourne{p_end}
{phang2}j.kabatek@unimelb.edu.au{p_end} 
 
