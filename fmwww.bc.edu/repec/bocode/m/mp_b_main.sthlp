{smcl}
{* *! version 2.0.1}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template main {hline 2} main project.do file


{title:Description}

{pstd} 
This is a template for the main .do file in a project. This is the .do file that
calls all other .do files.
 
{pstd} 
This is the only file that can use a absolute path. All
other .do files in the project must only use relative paths. That way, if you
want to share your project with someone else, or if you need to run it on another
computer, you only have to change the {cmd:cd} command in this file and it will run.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    version <stata_version>
    clear all
    <as of 16>frames reset
    macro drop _all
    cd "<basedir>"
    
    do <abbrev>_dta01.do // some comment
    do <abbrev>_ana01.do // some comment
    
    exit
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

    {view "c:\ado\plus/m\mp_main.mpb":mp_main.mpb}
