{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template ignore {hline 2} .ignore file for git, ignores everything in directory data, and all .dta and .csv files


{title:Description}

{pstd} 
This is a template for a .ignore file. This is what {browse "https://git-scm.com/":git}
uses to know what files it will not track. It will ignore anything in the directory
{it:data}, and all .dta and .csv files. It prevents that someone accidentally puts
individual level data on a place like github.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    data/
    *.dta
    *.csv
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

    {view "c:\ado\plus/m\mp_ignore.mpb":mp_ignore.mpb}
