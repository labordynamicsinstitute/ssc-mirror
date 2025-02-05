{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template main_g {hline 2} main project.do file


{title:Description}

{pstd} 
This is a template for the main .do file in a project. This is the .do file that
calls all other .do files.
 
{pstd} 
This is the only file that can use an absolute path. All
other .do files in the project must only use relative paths. That way, if you
want to share your project with someone else, or if you need to run it on another
computer, you only have to change the {cmd:cd} command in this file and it will run.
 
{pstd} 
The three calls to {help sysdir} will make sure that, for the duration of this
Stata session, Stata will look for community contributed packages in the {cmd:ado}
folder within this project folder. So when you start your project, and you have
run the first part of this .do file till {cmd:cd ana} you will find no community
contributed packages. You can just install what you need using either {help ssc},
{help net}, or {help github}, and those commands will install those packages in the
ado folder local to this project. This means that if you hand over your project
folder to someone else, that person will automatically also get the community
contributed packages you installed for this project.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    version <stata_version>
    clear all
    macro drop _all
    
    // use only community contributed packages from 
    // the ado directory local to this project
    cd "<proj_basedir>"
    sysdir set PLUS     "`c(pwd)'/ado/plus"
    sysdir set PERSONAL "`c(pwd)'/ado/personal"
    sysdir set OLDPLACE "`c(pwd)'/ado"
    mata: mata mlib index
    
    // set the working directory
    cd ana
    
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

    {view "c:\ado\plus/m\mp_main_g.mpb":mp_main_g.mpb}
