{smcl}
{* *! version 2.1.4}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{title:Title}

{phang}
boilerplate template smclpres {hline 2} a smclpres presentation


{title:Description}

{pstd} 
This template starts a {help smclpres} presentation.


{title:Boilerplate}

{pstd}
This template creates a .do file with the following content: 

{cmd}
    //version 4.0.2
    
    //layout toc title(subsection) link(subsection) 
    //layout toc secfont(bold) subsubsecfont(italic) 
    //toctitle [presentation title] 
    
    /*toctxt
    {center:[author]}
    {center:[Institute]}
    
    toctxt*/
    
    
    //slide ------------------------------------------------------------------------
    //title [slide title]
    
    /*txt
    {pstd}
    txt*/
    
    //ex
    //endex
    //endslide ------------------------------------------------------------------------
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

    {view "c:\ado\plus/m\mp_smclpres.mpb":mp_smclpres.mpb}
