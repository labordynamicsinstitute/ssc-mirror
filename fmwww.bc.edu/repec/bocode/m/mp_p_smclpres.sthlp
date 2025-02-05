{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
project template smclpres {hline 2} a smclpres presentation project


{title:Description}

{pstd} 
This template sets up a directory for a {help smclpres} presentation.


{title:File structure}

{pstd}
This template will create the following sub-directories and files:

    proj_abbrev /  
    {c LT}{c -}{c -}  handout /
    {c LT}{c -}{c -}  presentation /
    {c LT}{c -}{c -}  source /
    {c |}    {c BLC}{c -}{c -} {help mp_b_smclpres:presentation.do}
    {c BLC}{c -}{c -}  {help mp_b_readme_sp:readme.txt} 


{title:Commands}

{pstd}
After creating these sub-directories and files it will change the working directory to {it:proj_abbrev} directory.
Subsequently it will execute the following commands:{p_end}
{pmore}{cmd:qui cd source}{p_end}
{pmore}{cmd:doedit presentation.do}{p_end}


{title:Source code}

    {view "c:\ado\plus/m\mp_smclpres.mpp":mp_smclpres.mpp}
