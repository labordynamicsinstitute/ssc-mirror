{smcl}
{* *! version 1.2.2  15may2018}{...}
{findalias asfradohelp}{...}
{vieweralsosee "[D] expand" "help expand"}{...}
{viewerjumpto "Syntax" "expandrank##syntax"}{...}
{viewerjumpto "Description" "expandrank##description"}{...} 
{viewerjumpto "Examples" "expandrank##examples"}{...}
{viewerjumpto "Contact" "expandrank##contact"}{...}
{title:Title}

{phang}
{bf:expandrank} {hline 2} Expand and rank observations 


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:expandr:ank} [{cmd:=}]{it:{help exp}} {ifin}
[{cmd:,} {opth b:ase(real)} {opth n:ame(string)}  {opt ord:ered} {opth s:ort(varlist)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opth b:ase(real)}}sets a base value for the ranking variable (default is {cmd:1}){p_end}
{synopt:{opth n:ame(string)}}sets the name of the ranking variable (default is {cmd:rank}){p_end}
{synopt:{opt ord:ered}}ranked observations in the expanded dataset are listed in numerical order (from {cmd:1} to {it:{help exp}}, requires more memory than the default command){p_end}
{synopt:{opth s:ort(varlist)}}the expanded dataset is sorted on {cmd:varlist} and {cmd:rank} (requires more memory & comp. time than the default command){p_end}
{synoptline}
{p2colreset}{...} 


{marker description}{...}
{title:Description}

{pstd}
{cmd:expandrank} is a wrapper for {cmd:expand} which runs the command and 
creates a ranking variable ({cmd:rank}) that assigns values {cmd:1}...{cmd:n} to the {cmd:1}st...{cmd:n}th duplicate observations.

                                +-------------------+
                                | name   age   rank |
                                |-------------------|
                                | Alice   20      1 |
    +------------+              | Alice   20      2 |
    | name   age |              | Alice   20      3 |
    +------------+              | Alice   20      4 |
    | Alice   20 |              | Alice   20      5 |
    |------------|  -------->   |-------------------|
    | Bob     63 |              | Bob     63      1 |
    +------------+              | Bob     63      2 |
                                | Bob     63      3 |
                                | Bob     63      4 |
                                | Bob     63      5 |
                                +-------------------+
                   
{phang}This is analogous to running the {cmd:expand} command followed by:{p_end} 
{phang}{cmd:. bysort name: gen rank = _n }{p_end}

{pstd}
{cmd:expandrank} avoids the computationally-intensive sorting, 
which is appreciated when handling large data sets.

{marker examples}{...}
{title:Examples}

    Setup
{phang2}{cmd:. webuse stackxmpl}{p_end}
{phang2}{cmd:. list}{p_end}
  
    Expand by 3 and create the ranking variable (note that the duplicate observations are not stored in numerical order)
{phang2}{cmd:. expandrank 3}{p_end}
{phang2}{cmd:. list, sep(0)}{p_end}

    {hline}
	
    Expand by 3 and have the duplicate observations stored in numerical order
{phang2}{cmd:. webuse stackxmpl}{p_end}
{phang2}{cmd:. expandrank 3, ord}{p_end}
{phang2}{cmd:. list, sep(3)}{p_end}

    {hline}
	
    Expand by 3 and have the initial observations sorted in reverse 
{phang2}{cmd:. webuse stackxmpl}{p_end}
{phang2}{cmd:. gen id = - _n}{p_end}
{phang2}{cmd:. expandrank 3, sort(id)}{p_end}
{phang2}{cmd:. list, sep(3)}{p_end}

    {hline}
    
    Expand by 3, observations stored in numerical order, count rank from 2000
{phang2}{cmd:. webuse stackxmpl}{p_end}
{phang2}{cmd:. expandrank 3, ord base(2000)}{p_end}
{phang2}{cmd:. list, sep(3)}{p_end}


{marker contact}{...}
{title:Contact}

{phang2}Jan Kabátek, The University of Melbourne{p_end}
{phang2}j.kabatek@unimelb.edu.au{p_end} 
