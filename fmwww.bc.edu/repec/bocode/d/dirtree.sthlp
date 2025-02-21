{smcl}
{* *! version 1.2.0 20Feb2025 MLB}{...}
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
{synopt:{opt noexp:and}{cmd:[(}{it:list}{cmd:)]}}specifies that directories in 
{it:list} will not be expanded. If no list is specified than no directory will be
expanded.{p_end}
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

{phang}
{opt noexpand(list)} specifies that directories in {it:list} are not to be 
expanded. This means that the files and directories in such a directory will not
be displayed. Instead of the content of that directory {cmd:dirtree} will display:

            {cmd:{c BLC}{c -}{c -} ...}

{pmore}
Where the {cmd:...}	is a link to a call to {cmd:dirtree} that will display the 
content	of the non-expanded directory, unless the {cmd:nolink} option was specified.

{pmore}
{it:list} does not contain the full paths to the directories, but just their name.
Any directory with that name will not be expanded. If a directory name contains 
spaces, then the name of that directory needs to be enclosed in double quotes. 

{phang}
{opt noexpand} specifies that only the content of the current directory is to be
displayed and none of the sub-directories are to be expanded.


{marker examples}{...}
{title:Examples}

{phang}{stata dirtree}{p_end}

{phang}{cmd:dirtree, noexp(data "directory name with spaces")}


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn   
