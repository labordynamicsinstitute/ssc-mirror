{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template longt {hline 2} based on (Long 2009), display project with dirtree


{title:Description}

{pstd} 
This template starts a project folder for a medium sized a research project. It
is loosely based on J. Scott Long (2009) The workflow of data analysis using Stata.
College Station, TX: Stata Press.
 
{pstd} 
The work folder is where you do most of the work. You can change its content freely.
 
{pstd} 
The posted folder is there to store snapshots of your project. A snapshot is just
a copy of the content of the work folder. Important is that you can only add to
the posted folder, but never change files stored in it. That way you can return to
that state if you need to. For example, you presented your work at a conference
and afterwards continued to work on it. After a while someone comes up to you and
asks you how you did something for that presentation. If you have taken a snapshot
of your project just before the presentation, you can return to that state and
answer the question. If not ...
 
{pstd} 
The only difference with the {help mp_p_long:long} template is that this template
shows the content of the created project folder using {help dirtree}, and the
{it:long} template does not.


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /   
    ├──  docu / 
    |    └── {help mp_b_rlog:research_log.md} 
    ├──  posted / 
    |    ├── analysis /
    |    ├── data /
    |    └── txt /
    └──  work / 
         ├── analysis /
         |   ├── {help mp_b_ana:proj_abbrev_ana01.do}
         |   ├── {help mp_b_dta:proj_abbrev_dta01.do}
         |   └── {help mp_b_main:proj_abbrev_main.do}
         └── txt /


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:dirtree}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_longt.mpp":mp_longt.mpp}
