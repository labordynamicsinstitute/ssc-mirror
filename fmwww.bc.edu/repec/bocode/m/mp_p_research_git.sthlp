{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template research_git {hline 2} Research with git


{title:Description}

{pstd} 
This template sets up a directory for a medium sized research project that uses
{browse "https://git-scm.com/":git} to keep track of its history.


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /   
    {c LT}{c -}{c -}  ado / 
    {c |}    {c LT}{c -}{c -} personal /
    {c |}    {c BLC}{c -}{c -} plus /
    {c LT}{c -}{c -}  ana / 
    {c |}    {c LT}{c -}{c -} {help mp_b_ana:proj_abbrev_ana01.do} 
    {c |}    {c LT}{c -}{c -} {help mp_b_dta_g:proj_abbrev_dta01.do} 
    {c |}    {c BLC}{c -}{c -} {help mp_b_main_g:proj_abbrev_main.do} 
    {c LT}{c -}{c -}  data / 
    {c LT}{c -}{c -}  docu / 
    {c |}    {c BLC}{c -}{c -} {help mp_b_rlog:research_log.md} 
    {c LT}{c -}{c -}  txt / 
    {c LT}{c -}{c -}  {help mp_b_ignore:.gitignore}  
    {c BLC}{c -}{c -}  {help mp_b_readme:readme.md}  


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:!git init -b main}{p_end}
{pmore}{cmd:!git add .}{p_end}
{pmore}{cmd:!git commit -m "initial commit"}{p_end}
{pmore}{cmd:cd ana}{p_end}
{pmore}{cmd:projmanager proj_abbrev.stpr}{p_end}
{pmore}{cmd:doedit "proj_abbrev_main.do"}{p_end}
{pmore}{cmd:doedit "proj_abbrev_dta01.do"}{p_end}
{pmore}{cmd:doedit "proj_abbrev_ana01.do"}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_research_git.mpp":mp_research_git.mpp}
