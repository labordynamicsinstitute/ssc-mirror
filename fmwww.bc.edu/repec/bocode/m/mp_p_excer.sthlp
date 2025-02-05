{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template excer {hline 2} excercise for a course


{title:Description}

{pstd} 
This template sets up a directory for a basic excercise one may have to do for
a course


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev / 
    {c BLC}{c -}{c -}  {help mp_b_excer:proj_abbrev.do}


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:doedit proj_abbrev.do}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_excer.mpp":mp_excer.mpp}
