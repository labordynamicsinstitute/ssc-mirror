{smcl}
{* *! version 1.2.0}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{viewerjumpto "Syntax" "boilerplate##syntax"}{...}
{viewerjumpto "Description" "boilerplate##description"}{...}
{viewerjumpto "Options" "boilerplate##option"}{...}
{viewerjumpto "Examples" "boilerplate##example"}{...}
{title:Title}

{phang}
{bf:boilerplate} {hline 2} Creates a .do file with some boilerplate code


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:boilerplate}
{help filename:new_filename} ,
{cmd:[}
{opt dta}
{opt ana} 
{opt smclpres}
{opt git}
{opt noopen}
{cmd:]}

{marker description}{...}
{title:Description}

{pstd}
{cmd:boilerplate} creates a new .do file called {it:new_filename}, which will 
contain boilerplate code. The type of boilerplate code depends on whether the
{cmd:dta}, {cmd:ana}, or {cmd:smclpres} option has been specified;{p_end} 
{pmore}the first indicates that the .do file is mainly for data preparation,{p_end}
{pmore}the second indicates that the .do file is mainly for data analysis, and{p_end}
{pmore}the last indicates that the .do file is a source file for a 
{stata ssc desc smclpres:smclpres} presentation.{p_end}

{pstd}
Once {cmd:boilerplate} has created the file, it will open that .do file in the 
do file editor, unless the {cmd:noopen} option has been specified. 


{marker option}{...}
{title:Option}

{phang}
{opt dta} specifies that the .do file's main purpose is data preparation, the
default.

{phang}
{opt ana} specifies that the .do file's main purpose is data analysis.

{phang}
{opt smclpres} specified that the .do file is to be a source file for a 
{cmd:smclpres} presentation.

{phang}
{opt noopen} specifies that the created .do file is not to be opened in the 
do file editor.	

{phang}
{opt git} specifies that the .do file will use the directory structure for a 
project maintained by Git, i.e. the raw data is expected to be in 
../protected/data rather than in ../posted/data.


{marker example}{...}
{title:Example}

{phang}{cmd:. boilerplate foo_dta02.do, dta}{p_end}


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn   
