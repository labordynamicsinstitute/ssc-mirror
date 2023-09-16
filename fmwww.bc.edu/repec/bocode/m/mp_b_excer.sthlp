{smcl}
{* *! version 2.0.1}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template excer {hline 2} course exercise


{title:Description}

{pstd} 
This a a template for a .do file that a student can use to do an
exercise in a course.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    capture log close
    log using <stub>.txt, replace text
    
    // ---------------------------------------------------------------------------
    // course        : 
    // exercise      : 
    // name          : 
    // student number: 
    // ---------------------------------------------------------------------------
    
    version <stata_version>
    clear all
    <as of 16>frames reset
    macro drop _all
    
    *use [original_data_file.dta]
    
    // exercise 1 ................................................................
    
    /*
    Answer
    */
    
    // exercise 2 ................................................................
    
    /*
    Answer
    */
    
    log close
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

    {view "c:\ado\plus/m\mp_excer.mpb":mp_excer.mpb}
