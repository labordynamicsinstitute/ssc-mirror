{smcl}
{* *! version 2.0.0}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template readme {hline 2} readme.md for when you want to put your project on github or the like


{title:Description}

{pstd} 
This template creates a readme.md file that will be used if you put your project
on github to introduce your project to people visiting your project page.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    # Title
    
    *Author*
    
    *affiliation*
    
    ## Description
    
    These are the replication files for the project [title]. The aim of this project is [something brilliant]. 
    
    ## Requirements and use
    
    These .do files require Stata # or higher.
    
    In addition it requires the following community contributed package(s):
    
    - `fre` from SSC
    
    To use these .do files you:
    
    1. Install the required packages
    2. fork this repository
    3. Obtain the raw data files [name1, name2, ...]  from  https://doi.org/######### and save those in the directory `data`
    4. In ana/main.do change line 5 (`cd ..."`) to where your directory is
    5. run main.do 
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

    {view "c:\ado\plus/m\mp_readme.mpb":mp_readme.mpb}
