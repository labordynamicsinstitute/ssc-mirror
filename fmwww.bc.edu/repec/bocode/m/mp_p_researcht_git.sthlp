{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template researcht_git {hline 2} Research project with git, display project with dirtree


{title:Description}

{pstd} 
This template sets up a directory for a medium sized research project that uses
{browse "https://git-scm.com/":git} to keep track of its history.
 
{pstd} 
The only difference with the {help mp_p_research_git:research_git} template is
that this template shows the content of the created project folder using
{help dirtree}, and the {it:research_git} template does not.


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /  
    ├──  ana /
    |    ├── {help mp_b_ana:proj_abbrev_ana01.do}
    |    ├── {help mp_b_dta_g:proj_abbrev_dta01.do}
    |    └── {help mp_b_main:proj_abbrev_main.do}
    ├──  data /
    ├──  docu /
    |    └── {help mp_b_rlog:research_log.md}
    ├──  txt /
    ├──  {help mp_b_ignore:.ignore} 
    └──  {help mp_b_readme:readme.md} 


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:!git init -b main}{p_end}
{pmore}{cmd:!git add .}{p_end}
{pmore}{cmd:!git commit -m "initial commit"}{p_end}
{pmore}{cmd:dirtree}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_researcht_git.mpp":mp_researcht_git.mpp}
