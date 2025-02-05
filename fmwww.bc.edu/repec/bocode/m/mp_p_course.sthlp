{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template course {hline 2} Small research project as part of a course


{title:Description}

{pstd} 
This template is for a small research project that takes place over a
short period of time that does not require snapshots. A typical example
would be a project someone has to do for a course.


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /  
    {c LT}{c -}{c -}  ana /
    {c |}    {c LT}{c -}{c -} {help mp_b_ana:proj_abbrev_ana01.do}
    {c |}    {c LT}{c -}{c -} {help mp_b_dta_c:proj_abbrev_dta01.do}
    {c |}    {c BLC}{c -}{c -} {help mp_b_main:proj_abbrev_main.do}
    {c LT}{c -}{c -}  data /
    {c LT}{c -}{c -}  docu /
    {c |}    {c BLC}{c -}{c -} {help mp_b_rlogc:research_log.md}
    {c BLC}{c -}{c -}  txt /


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:dirtree}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_course.mpp":mp_course.mpp}
