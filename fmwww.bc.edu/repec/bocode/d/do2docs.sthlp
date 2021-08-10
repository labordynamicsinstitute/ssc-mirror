{smcl}
{* *! version 1.0  4 May 2020}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Help log2markup" "help log2markup"}{...}
{viewerjumpto "Syntax" "do2docs##syntax"}{...}
{viewerjumpto "Description" "do2docs##description"}{...}
{viewerjumpto "Examples" "do2docs##examples"}{...}
{viewerjumpto "Author and support" "matprint##author"}{...}
{title:Title}
{phang}
{bf:do2docs} {hline 2} A quick way of building different documents from your 
do file specified by the {it:using} modifier.

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:do2docs}
using/
[{cmd:,}
{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Standard options}
{synopt:{opt doc:type(string)}} Specify standard output document type.
Standard types are: beamer1 - slide level 1; beamer2 - slide level 2;
html - with mathjax; pdf; tex or latex; word; ppt or powerpoint{p_end}
{synopt:{opt t:imeout(#)}} To see possible errors from pandoc specify time i 
seconds different than 0. Default value is 0{p_end}
{synopt:{opt c:leanup}} Automatically delete temporary (log and markdown) files{p_end}
{synopt:{opt d:atestamp}} Add datestamp in output document name{p_end}
{synopt:{opt b:ibliography(string)}} Specify path and name for bibtex library{p_end}
{synopt:{opt s:avein(string)}} Specify path for output{p_end}
{synopt:{opt sh:ow}} Show (if possible) output document{p_end}
{syntab:Non-standard output documents}
{synopt:{opt e:xtension(string)}} Specify a non-standard document type.
{browse "https://pandoc.org/demos.html":See eg pandoc examples for types}{p_end}
{synopt:{opt p:andocstring(string)}} To style the non-standard output document.
{browse "https://pandoc.org/MANUAL.html":See pandoc user guide}{p_end}
{syntab:Different pandoc path}
{synopt:{opt pa:ndocpath(string)}} Specify alternative path to pandoc.
Default is the pandoc default: "C:/Program Files/Pandoc/pandoc.exe"{p_end}
{syntab:From {help log2markup}}
{synopt:{opt codestart}} set your markdown coding for code start, eg 
\begin{stlog} if the document is intended for the Stata Journal.{break}
Works best with html or latex{p_end}
{synopt:{opt codeend}} set your markdown coding for code end, eg 
\end{stlog} if the document is intended for the Stata Journal.{break}
Works best with html or latex{p_end}
{synopt:{opt samplestart}} set your markdown coding for sample start, eg 
{\smallskip}\begin{stlog} if the document is intended for the Stata Journal.{break}
Works best with html or latex{p_end}
{synopt:{opt sampleend}} set your markdown coding for sample end, eg 
\begin{stlog} if the document is intended for the Stata Journal.{break}
Works best with html or latex{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
A quick way of building different documents from your do file specified by 
the {it:using} modifier. It uses {cmd:log2markup} and requires that 
{browse "https://pandoc.org":pandoc} is installed.


{marker examples}{...}
{title:Examples}
{pstd}
One can choose to change directory to where the do-file is placed:

{pstd}
{cmd:cd "C:\my\path\to\the\do\file"}

{pstd}
Otherwise specify full path and name to do-file.

{pstd}
To generate a word output document (named "my do file name.docx") from the do-file
"my do file name.do".{break}
The word file is saved in subfolder Output.{break}
There is a 30 seconds timeout to see possible pandoc errors.{break}
The log and markdown file is deleted at the end.{break}

{pstd}
{cmd:do2docs using `"my do file name.do"', doctype(word) savein(Output) timeout(30) cleanup}

{pstd}
To use a word template use options {opt e:xtension} and {opt p:andocstring} 
instead of option {opt doc:type} with the following arguments (works also for 
eg powerpoint presentations):

{pstd}
{cmd:do2docs using `"my do file name.do"', extension(docx) pandocstring(--reference-doc="folder/my-reference.docx")}

{pstd}
The command to create eg a word template template in a {cmd:dos} or 
{cmd:powershell} is:

{pstd}
{cmd:pandoc -o folder/my-reference.docx --print-default-data-file reference.docx}

{pstd}
Edit only a limited set of styles.{break} 
See {browse "https://pandoc.org/MANUAL.html":pandoc} 
for more information. Search on {it:--reference-doc={bf:FILE}}. 

{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}

