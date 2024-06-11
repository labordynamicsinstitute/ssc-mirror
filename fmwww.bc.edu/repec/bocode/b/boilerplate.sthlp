{smcl}
{* *! version 2.1.3}{...}
{vieweralsosee "mkproject" "help mkproject"}{...}
{vieweralsosee "create a new template" "help boilerplate create"}
{viewerjumpto "Syntax" "boilerplate##syntax"}{...}
{viewerjumpto "Description" "boilerplate##description"}{...}
{viewerjumpto "Examples" "boilerplate##example"}{...}
{title:Title}

{phang}
{bf:boilerplate} {hline 2} Creates a .do file with some boilerplate code


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:boilerplate}
{help filename:new_filename}
[{cmd:,} {opt templ:ate(template)} ]

{p 8 17 2}
{cmd:boilerplate}
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
{synopt:{opt templ:ate(template)}}choose the template for the boilerplate. The 
{it:query} option displays a list of templates available and the default{p_end}
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
There is usually a set of commands that are included in every .do file a person 
makes, like {cmd:clear _all} or {cmd:log using}. What those commands are can 
differ from person to person, but most persons have such a standard set. The 
purpose of {cmd:boilerplate} is to help creating new .do file by adding those
standard commands (often called boilerplate code). The type of boilerplate code 
that will be added to {it:new_filename} depends on the template. Use the 
{cmd:query} option to see what what templates are available. 

{pstd}
{help boilerplate_create:This} help file discusses how to create your own 
template.


{marker example}{...}
{title:Example}

{phang}{cmd:. boilerplate , query}{p_end}
{phang}{cmd:. boilerplate foo_dta02.do, template(dta)}{p_end}


{title:Author}

{pstd}Maarten Buis, University of Konstanz{break} 
      maarten.buis@uni.kn   
