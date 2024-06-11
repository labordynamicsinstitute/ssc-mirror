{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "boilerplate" "help boilerplate"}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{viewerjumpto "Syntax" "mkproject##syntax"}{...}
{viewerjumpto "Description" "mkproject##description"}{...}
{viewerjumpto "Example" "mkproject##example"}{...}
{title:Title}

{phang}
{bf:boilerplate, create} {hline 2} Create new templates for the {cmd:boilerplate} command.


{title:Description}

{pstd}
As a mimimum you can create a new template by creating a .do file with the 
boilerplate code you want between the tags {cmd:<body>} and {cmd:</body>}, then 
type in Stata {cmd:boilerplate, create(}{it:that_do_file}{cmd:)}. Based on that 
.do file {cmd:boilerplate} will create the template, and the corresponding help 
file.

{pstd}
You can also the following tags, to your .do file:{p_end}
{pmore}{cmd:<stata_version>} will be replaced by the Stata version{p_end}
{pmore}{cmd:<date>} will be replaced by the date{p_end}
{pmore}{cmd:<fn>} will be replaced by the file name{p_end}
{pmore}{cmd:<stub>} will be replaced by the file name without the suffix{p_end}
{pmore}{cmd:<abbrev>} will be replaced by the file name without the suffix up to the last underscore{p_end}
{pmore}{cmd:<basedir>} will be replaced by the directory in which the file is saved{p_end}
{pmore}{cmd:<as of #>} will include whatever comes after that tag only if the Stata version is # or higher{p_end}

{pstd}
You can also add meta information in the header. Within the header you can add 
five types of meta data:

{pmore}
{cmd:<mkproject>} Indicates that this is a template, and the word after it can 
be either {cmd:project} or {cmd:boilerplate}, to indicate whether this is a 
{cmd:mkproject} or {cmd:boilerplate} template. You can specify it in your text 
file or if you don't specify it, {cmd:boilerplate, create()} will add it for you.

{pmore}
{cmd:<version>} Indicates which version of {cmd:boilerplate} is used to create this
template. {cmd:boilerplate} uses that information to ensure backwards compatability;
if a new version of {cmd:boilerplate} becomes available, you can install that 
without fearing that it will break your older templates. You can specify it 
yourself, or if you don't specify it, {cmd:boilerplate, create()} will set it to
the current version of {cmd:boilerplate}

{pmore}
{cmd:<label>} gives the short description of your template, that will be shown 
with {cmd:boilerplate, query}

{pmore}
{cmd:<reqs>} specifies a community contributed package that is required for this
template.

{pmore}
The lines between {cmd:<description>} and {cmd:</description>} give a longer
description of the template as it will appear in the help-fearing. It may contain
{help smcl} tags.

{title:Example}
{pstd}
Below is the template for {help mp_b_excer:excer}. 
You can look at the source code for any template by typing {cmd:boilerplate, query}, 
click on any template you are interested in, that opens a help-file, and at the 
bottom there is a link that will show the source code for that template in the 
viewer.

    --------------- begin template -------------------
{cmd}{...}
    <header>
    <mkproject> boilerplate
    <version> 2.1.2
    <label> course exercise
    <description>
    {c -(}pstd{c )-} 
    This a a template for a .do file that a student can use to do an
    exercise in a course.
    </description>
    </header>
    
    <body>
    capture log close
    log using <stub>.txt, replace text
    
    // ---------------------------------------------------------------------------
    // course        : 
    // exercise      : 
    // name          : 
    // student number: 
    // ---------------------------------------------------------------------------
    
    version <stata_version>
    clear all
    <as of 16>frames reset
    macro drop _all
    
    *use [original_data_file.dta]
    
    // exercise 1 ................................................................
    
    /*
    Answer
    */
    
    // exercise 2 ................................................................
    
    /*
    Answer
    */
    
    log close
    exit
    </body>
{txt}{...}
    -------------- end template --------------------
