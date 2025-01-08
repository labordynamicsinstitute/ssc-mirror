{smcl}
{vieweralsosee "opendf read" "help opendf read"}{...}
{vieweralsosee "opendf write" "help opendf write"}{...}
{viewerjumpto "Syntax" "opendf docu##syntax"}{...}
{viewerjumpto "Options" "opendf docu##options"}{...}
{viewerjumpto "Description" "opendf docu##description"}{...}
{viewerjumpto "Examples" "opendf docu##examples"}{...}
help for {cmd:opendf docu (opendf_docu)}{right: version 2.0.2 (28 August 2024)}
{hline}

{phang}
{bf:opendf docu} {hline 2} Display information about the dataset or a variable. {p_end}


{marker syntax}
{title:Syntax}
{p 8 17 2}
{cmd:opendf docu}
[{it:{help varname}}, {opt languages()}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synopt :{opt languages(string)}} Chooses, which languages to display. Default is the active label language. To see all languages, set languages("all") {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}
{cmd:opendf docu} displays information about the dataset or a variable, if a variable is specified. {p_end}
{pstd}
{it:  varname} can be indicated to display information about a variable instead of the dataset. {p_end}
{pstd}
{opt languages} indicates the languages that should be displayed. Default is the active label language. To see all languages, set languages("all") {p_end}
{marker remarks}


{title:Remarks}

{pstd}
This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}


{marker examples}
{title:Examples}

{phang}Displays information about the dataset.{p_end}
{phang}{cmd:. opendf docu}{p_end}

{phang}Displays information about the variable bap9001.{p_end}
{phang}{cmd:. opendf docu bap9001}{p_end}

{phang}Displays information about the variable bap9001 in all languages available.{p_end}
{phang}{cmd:. opendf docu bap9001, languages("all")}{p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf read}, {help opendf write}{p_end}
