{smcl}
{* *! version 2.0.1}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template readme_sp {hline 2} readme.md for when you want to put your project on github or the like


{title:Description}

{pstd} 
This template creates a readme.txt file that tells users of your presentation
how to use your presentation.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    Readme
    ======
    
    This .zip file contains a presentation. If you extract it, 
    you will get 3 folders:
    
    presentation
    ------------
    
    This is the folder contains the .smcl presentation. To view this:
    o open Stata, 
    o use -cd- to change to this directory
    o type -view presentation.smcl- 
    
    handout
    -------
    
    This contains the .html handout created for this presentation. This 
    is particularly useful for quickly looking things up and if you don't 
    have Stata installed on your current devise.
    
    source
    ------
    
    This folder contains the source used to create the presentation. To 
    create the presentation from this source:
    
    o open Stata
    o Install smclpres by typing -ssc install smclpres-
    o use -cd- to change to this directory
    o make the presentation by typing 
      -smclpres using presentation.do , dir(../presentation) replace-
{txt}

{title:Tags}

{pstd}
This file may contain one or more of the following tags:{p_end}
{pmore}{cmd:<stata_version>} will be replaced by the Stata version{p_end}
{pmore}{cmd:<date>} will be replaced by the date{p_end}
{pmore}{cmd:<fn>} will be replaced by the file name{p_end}
{pmore}{cmd:<stub>} will be replaced by the file name without the suffix{p_end}
{pmore}{cmd:<abbrev>} will be replaced by the file name without the suffix up to the last underscore{p_end}
{pmore}{cmd:<basedir>} will be replaced by the directory in which the file is saved{p_end}
{pmore}{cmd:<as of #>} will include whatever comes after that tag only if the Stata version is # or higher{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_readme_sp.mpb":mp_readme_sp.mpb}
