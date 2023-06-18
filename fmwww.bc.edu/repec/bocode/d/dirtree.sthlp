{smcl}
{* *! version 1.0.0 15June2023 MLB}{...}
{vieweralsosee "cd" "help cd"}{...}
{vieweralsosee "dir" "help dir"}{...}
{viewerjumpto "Syntax" "dirtree##syntax"}{...}
{viewerjumpto "Description" "dirtree##description"}{...}
{viewerjumpto "Options" "dirtree##options"}{...}
{viewerjumpto "Examples" "dirtree##examples"}{...}
{title:Title}

{phang}
{bf:dirtree} {hline 2} Display content of directory as a tree


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:dirtree}
[{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt dir(directory)}}specify the directory; default is the current 
        working directory{p_end}
{synopt:{opt cd}}change to the directory specified in {cmd:dir()}{p_end}
{synopt:{opt hidden}}display hidden files and directories{p_end}
{synopt:{opt onlyd:irs}}only display the directories and not the files{p_end}
{synopt:{opt nolink}}files that can be opened in Stata are not shown as a link{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:dirtree} shows the content of a directory, including sub-directories, as a 
tree. By default, files that can be opened in Stata are shown as clickable links.


{marker options}{...}
{title:Options}

{phang}
{opt dir(directory)} Specifies the directory that is to be displayed. By default
the current working directory is used

{phang}
{opt cd} change the current working directory to the directory specified in {opt dir()}

{phang}
{opt hidden} display hidden directories and files, that is, files and directories 
starting with a "."

{phang}
{opt onlydirs} Only display the directories and not the files

{phang}
{opt nolink} Shows just the file names. By default files that can be opened in 
Stata are shown as a link that will open that file. 


{marker examples}{...}
{title:Examples}

{phang}{stata dirtree}{p_end}


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn   
