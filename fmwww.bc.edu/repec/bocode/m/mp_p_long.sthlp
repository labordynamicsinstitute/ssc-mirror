{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template long {hline 2} based on (Long 2009)


{title:Description}

{pstd} 
This template starts a project folder for a medium sized research project. It
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


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /   
    {c LT}{c -}{c -}  docu / 
    {c |}    {c BLC}{c -}{c -} {help mp_b_rlog:research_log.md} 
    {c LT}{c -}{c -}  posted / 
    {c |}    {c LT}{c -}{c -} analysis /
    {c |}    {c LT}{c -}{c -} data /
    {c |}    {c BLC}{c -}{c -} txt /
    {c BLC}{c -}{c -}  work / 
         {c LT}{c -}{c -} analysis /
         {c |}   {c LT}{c -}{c -} {help mp_b_ana:proj_abbrev_ana01.do}
         {c |}   {c LT}{c -}{c -} {help mp_b_dta:proj_abbrev_dta01.do}
         {c |}   {c BLC}{c -}{c -} {help mp_b_main:proj_abbrev_main.do}
         {c BLC}{c -}{c -} txt /


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:qui cd work/analysis}{p_end}
{pmore}{cmd:projmanager "proj_abbrev.stpr"}{p_end}
{pmore}{cmd:doedit "proj_abbrev_main.do"}{p_end}
{pmore}{cmd:doedit "proj_abbrev_dta01.do"}{p_end}
{pmore}{cmd:doedit "proj_abbrev_ana01.do"}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_long.mpp":mp_long.mpp}
