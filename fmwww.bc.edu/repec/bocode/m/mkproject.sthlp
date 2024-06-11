{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{vieweralsosee "create new templates" "help mkproject_create"}{...}
{vieweralsosee "smclpres (if installed)" "help smclpres"}{...}
{vieweralsosee "dirtree (if installed)" "help dirtree"}{...}
{viewerjumpto "Syntax" "mkproject##syntax"}{...}
{viewerjumpto "Description" "mkproject##description"}{...}
{viewerjumpto "Example" "mkproject##example"}{...}
{title:Title}

{phang}
{bf:mkproject} {hline 2} Creates project folder with some boilerplate code 


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:mkproject}
{it:proj_abbrev}
[{cmd:,} {opt templ:ate(template)} 
{opt dir(directory)} ]

{p 8 17 2}
{cmd:mkproject}
[{cmd:,} {opt query} 
{opt create(filename)} 
{opt remove(template_name)} 
{opt default(template_name)} 
{opt resetdefault}
{opt replace}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt templ:ate(template)}}choose the template for the projects. The 
{it:query} option displays a list of templates available and the default{p_end}
{synopt:{opt dir(directory)}}specifies the directory in which the project 
directory is to be created{p_end}
{synopt:{opt query}}displays a list of templates available{p_end}

{syntab:Modify templates}
{synopt:{opt create(filename)}}create a template from {it:filename}{p_end}
{synopt:{opt remove(template_name)}}removes the template {it:template_name}{p_end}
{synopt:{opt default(template_name)}}set the default template to {it:template_name}{p_end}
{synopt:{opt resetdef:ault}}sets the default template back to {it:long}{p_end}
{synopt:{opt replace}}allow an existing template to be replaced when using the 
{opt create()} option{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
The purpose of {cmd:mkproject} is to create a standard directory structure and 
some files with boilerplate code in order to help get a project started. There 
is usually a set of commands that are included in every .do file a person makes, 
like {cmd:clear _all} or {cmd:log using}. What those commands are can differ 
from person to person, but most persons have such a standard set. Similarly, a 
project usually has a standard set of directories and files. Starting a new 
project thus involves a number of steps that could easily be automated. 
Automating has the advantage of reducing the amount of work you need to do. 
However, the more important advantage of automating the start of a project is 
that it makes it easier to maintain your own workflow: it is so easy to start 
"quick and dirty" and promise to yourself that you will fix that "later". If the 
start is automated, then you don't need to fix it. 

{pstd}
The {cmd:mkproject} command automates the beginning of a project. It comes with 
a set of "templates" I find useful. A template contains all the actions (like 
create sub-directories, create files, run other Stata commands) that 
{cmd:mkproject} will take when it creates a new project. Since everybody's 
workflow is different, {cmd:mkproject} allows users to create their own template. 

{pstd}
You can get a list of available templates at your computer by typing 
{stata mkproject, query}. It will show for each template a short label, which can
give a quick idea of what templates could potentially be useful for you. You can 
also click on the name of the template to open a helpfile for that template. 


{it:Other}

{pstd}
Additional .do files with boilerplate code can be created with {help boilerplate}.

{pstd}
Adding new templates is discussed in {help mkproject_create:this} helpfile.

{pstd}
This command was inspired by the book by {help mkproject##ref:Scott Long (2009)}. 


{marker example}{...}
{title:Example}

{phang}{cmd:. mkproject foo, dir(c:/temp) template(long)}{p_end}
{phang}{cmd:. mkproject, query}{p_end}

{marker ref}{...}
{title:Reference}

{phang}
J. Scott Long (2009) {it:The Workflow of Data Analysis Using Stata}. College Station, TX: Stata Press.


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn   

