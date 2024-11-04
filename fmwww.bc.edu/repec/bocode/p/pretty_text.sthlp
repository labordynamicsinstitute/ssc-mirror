{smcl}
{* *! version 1.0 11 September 2024}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "pretty_text##syntax"}{...}
{viewerjumpto "Description" "pretty_text##description"}{...}
{viewerjumpto "Options" "pretty_text##options"}{...}
{viewerjumpto "Remarks" "pretty_text##remarks"}{...}
{viewerjumpto "Examples" "pretty_text##examples"}{...}
{hline}
help for {cmd:pretty_text} {right: Version 1.0 11 September 2024}
{hline}
{title:Author}
{tab}Georgia McRedmond & Rafael Gafoor
{tab}University College London, London UNITED KINGDOM 
{tab}{cmd:r.gafoor@ucl.ac.uk}

{tab}{bf:Version} 	     {bf:Date}    		  {bf:Comments}
{tab}1.0		11 September 2024	First release

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:pretty_text}
[{help if}]
[{cmd:,}
{it:options}]


{synoptset 32 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required }
{synopt:{opt string}({help varlist})} - string variables to be summarised. {p_end}

{syntab:Optional}
{synopt:{opt by}({help varlist})} - grouping variables. {p_end}
{synopt:{opt sav:ing}({help filename})} - filename or path to save putdocx copy of table. {p_end}


{synoptline}


{p2colreset}{...}
{p 4 6 2}

{title:Description}

{phang}{marker description}{cmd:pretty_text} generates publication quality tables of string variables with or without grouping variables.{p_end}

{pstd}
{opt pretty_text} can take multiple grouping variables. Grouping variables will group any specified string variables by repeating categories. {p_end}

{pstd}
If multiple grouping variables are specified these will be nested in the order that they are passed to {opt pretty_text}.{p_end}
 
{pstd} {opt pretty_text} tables must be saved to preview, this will export the table using {help putdocx} to the specified filename. {p_end}

{pstd} If you wish to embed the {opt pretty_text} table inside an already open {help putdocx}, saving should not be used or it will cause the current file to be closed. {p_end} 

{hline}

{marker examples}{...}

{title:Examples}
{marker examples}{...}

Setup
{tab}{phang}{cmd:. sysuse auto, clear}{p_end}
{tab}{phang}{cmd:. keep in 50/60}{p_end}

Basic table with one grouping variable
{tab}{phang} {cmd:. pretty_text, string(make) by(foreign) sav("Example_Table")}{p_end}

Table with multiple grouping variables
{tab}{phang}{cmd:. gen Colour = "White"}{p_end}
{tab}{phang}{cmd:. replace Colour = "Black" in 5/10}{p_end}
{tab}{phang}{cmd:. pretty_text, string(make) by(foreign) sav("Example_Table")}{p_end}


