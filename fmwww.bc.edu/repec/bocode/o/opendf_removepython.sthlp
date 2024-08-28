{smcl}
{vieweralsosee "opendf read" "help opendf read"}{...}
{vieweralsosee "opendf write" "help opendf write"}{...}
{vieweralsosee "opendf docu" "help opendf docu"}{...}
{vieweralsosee "opendf installpython" "help opendf installpython"}{...}
{viewerjumpto "Syntax" "opendf installpython##syntax"}{...}
{viewerjumpto "Options" "opendf installpython##options"}{...}
{viewerjumpto "Description" "opendf installpython##description"}{...}
{viewerjumpto "Examples" "opendf installpython##examples"}{...}
help for {cmd:opendf removepython (opendf_removepython)}{right: version 2.0.0 (27 August 2024)}
{hline}

{phang}
{bf:opendf removepython} {hline 2} Removes portable Python installation(s) from the ado/plus folder or a specified folder. {p_end}


{marker syntax}
{title:Syntax}
{p 8 17 2}
{cmd:opendf removepython} 
[, {opt version()} {opt location()}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synoptline}
{synopt :{opt version(string)}} specifies a Python version. eg. "3.12" {p_end}
{synopt :{opth location(string)}} specifies a path where to delete Python {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}{cmd: opendf removepython} Removes portable Python installation(s) from some directory on your computer.{p_end}
{pstd}The command only works for Windows and does not require administrator privileges. But the user needs writing permission for the folder where Python is saved. {p_end}
{pstd}{opt version} Specifies the version of Python to be removed. {p_end}
{pstd}{opt location} Specifies the location where the Python folder should be deleted. Default is the Stata ado/plus folder, where opendf installpython deploys portable Python installation(s). {p_end}


{marker remarks}
{title:Remarks}

{pstd}
This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}
{pstd}
If this command is not working, restarting Stata and executing the command before running any other functions from the opendf package can fix the issue.{p_end}

{marker examples}
{title:Examples}

{phang}Install Python v3.12 (default) to the folder python3.12 in the ado\plus folder{p_end}
{phang}{cmd:. opendf installpython}{p_end}

{phang} Deletes Python v3.12 from the ado\plus folder{p_end}
{phang}{cmd:. opendf removepython, version("3.12")}{p_end}

{phang} Deletes all folders which contain "python" in the name in C:\Program Files\python {p_end}
{phang}{cmd:. opendf removepython, location("C:\Program Files\python")} {p_end}

{phang} Deletes a folder "python3.12" in C:\Program Files\python if it exists {p_end}
{phang}{cmd:. opendf removepython, version("3.12") location("C:\Program Files\python")} {p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf read}, {help opendf write}, {help opendf docu}, {help opendf removepython}, {help opendf installpython}{p_end}
