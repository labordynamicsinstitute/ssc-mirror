{smcl}
{* *! version 2.0.0}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{viewerjumpto "Syntax" "mkproject##syntax"}{...}
{viewerjumpto "Description" "mkproject##description"}{...}
{viewerjumpto "Example" "mkproject##example"}{...}
{title:Title}

{phang}
{bf:mkproject, create} {hline 2} Create new templates for the {cmd:mkproject} command.


{title:Description}

{pstd}
To create a new template you are going to create a text file telling 
{cmd:mkproject} what actions it should take, and then type in Stata 
{cmd:mkproject, create(}{it:that_text_file}{cmd:)}. Based on that text file 
{cmd:mkproject} will create the template, and the corresponding help file.

{pstd}
This template is going to be used at three times when {cmd:mkproject} makes a 
project folder:

{pmore} 
First, {cmd:mkproject} creates the project folder, and any sub-folders specified 
in the template. It changes the current working directory to the project folder.

{pmore}
Second, {cmd:mkproject} creates any files specified in the template, using 
{help boilerplate}.

{pmore}
Third, {cmd:mkproject} executes any commands specified in the template.

{pstd}
So a template should tell {cmd:mkproject} what subdirectories it needs to create,
what files it needs to create, and what commands it needs to execute. On top of 
that you can add various meta-data in the header.

{pstd}
Lets look at an example. Below is the template for {help mp_p_course:course}. 
You can look at the source code for any template by typing {cmd:mkproject, query}, 
click on any template you are interested in, that opens a help-file, and at the 
bottom there is a link that will show the source code for that template in the 
viewer.

    --------------- begin template -------------------
{cmd}{...}
    <header>
    <mkproject> project
    <version> 2.0.0
    <label> Small research project as part of a course
    <reqs> dirtree
    <description>
    {c -(}pstd{c )-} 
    This template is for a small research project that takes place over a
    short period of time that does not require snapshots. A typical example
    would be a project someone has to do for a course.
    </description>
    </header>
    
    <dir> docu
    <dir> data
    <dir> ana
    <dir> txt
    
    <file> rlogc  docu/research_log.md
    <file> main   ana/<abbrev>_main.do
    <file> dta_c  ana/<abbrev>_dta01.do
    <file> ana    ana/<abbrev>_ana01.do
    
    <cmd> dirtree
{txt}{...}
    -------------- end template --------------------

{pstd}
Lines between {cmd:<header>} and {cmd:</header>} contain 
meta-information, like the label for that template. 

{pstd}
Lines starting with {cmd:<dir>} tell you what sub-directories that template will
create

{pstd}
Lines starting with {cmd:<file>} have two elements, the first "word" is the name
of the template that {help boilerplate} will use to create a file, and the second
"word" is the filename. This filename can contain the tag {cmd:<abbrev>} which 
{cmd:mkproject} will replace with the {it:proj_abbrev} you will specify when using
{cmd:mkproject} to create a project folder.  

{pstd}
Lines starting with {cmd:<cmd>} tell you what commands {cmd:mkproject} will run
after creating those directories and files

{pstd}
Within the header you can add five types of meta data:

{pmore}
{cmd:<mkproject>} Indicates that this is a template, and the word after it can 
be either {cmd:project} or {cmd:boilerplate}, to indicate whether this is a 
{cmd:mkproject} or {cmd:boilerplate} template. You can specify it in your text 
file or if you don't specify it, {cmd:mkproject, create()} will add it for you.

{pmore}
{cmd:<version>} Indicates which version of {cmd:mkproject} is used to create this
template. {cmd:mkproject} uses that information to ensure backwards compatability;
if a new version of {cmd:mkproject} becomes available, you can install that 
without fearing that it will break your older templates. You can specify it 
yourself, or if you don't specify it, {cmd:mkproject, create()} will set it to
the current version of {cmd:mkproject}

{pmore}
{cmd:<label>} gives the short description of your template, that will be shown 
with {cmd:mkproject, query}

{pmore}
{cmd:<reqs>} specifies a community contributed package that is required for this
template. If any of the {cmd:boilerplate} templates used in the {cmd:<file>}
tag have a requirement, then that will be automatically copied here by 
{cmd:mkproject, create()}.

{pmore}
The lines between {cmd:<description>} and {cmd:</description>} give a longer
description of the template as it will appear in the help-fearing. It may contain
{help smcl} tags.

{pstd}
In practice, the easiest way to create a new template is usually to look for a
template that is close to what you want, and copy and adapt the source of that
template.
