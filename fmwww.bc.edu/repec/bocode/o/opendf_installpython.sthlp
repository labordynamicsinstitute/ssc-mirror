{smcl}
{vieweralsosee "opendf read" "help opendf read"}{...}
{vieweralsosee "opendf write" "help opendf write"}{...}
{vieweralsosee "opendf docu" "help opendf docu"}{...}
{vieweralsosee "opendf removepython" "help opendf removepython"}{...}
{viewerjumpto "Syntax" "opendf installpython##syntax"}{...}
{viewerjumpto "Options" "opendf installpython##options"}{...}
{viewerjumpto "Description" "opendf installpython##description"}{...}
{viewerjumpto "Examples" "opendf installpython##examples"}{...}
help for {cmd:opendf installpython (opendf_installpython)}{right: version 2.0.0 (27 August 2024)}
{hline}

{phang}
{bf:opendf installpython} {hline 2} Downloads a Portable Python Installation. {p_end}


{marker syntax}
{title:Syntax}
{p 8 17 2}
{cmd:opendf installpython} 
[, {opt version()} {opt location()}]

{synoptset 20 tabbed}{...}
{marker options}{synopthdr:options}
{synoptline}
{synopt :{opt version(string)}} specifies a Python version. eg. "3.12" {p_end}
{synopt :{opth location(string)}} specifies a path where to copy Python to {p_end}
{synoptline}


{marker description}
{title:Description}

{pstd}
{cmd:opendf installpython} Copies a portable Python installation to your computer. For Python version to work with the opendf package in Stata install Python to default location (Stata ado plus folder).{p_end}
{pstd}The command only works for Windows and does not require administrator privileges. But the user needs writing permission for the folder where Python is saved.{p_end}
{pstd}
{opt version} Specifies the version of Python. It should be 2.7 or higher to function with Stata. Default is 3.12. Python 3 is strongly recommended.{p_end}
{pstd}
{opt location} Specifies the location where the Python folder will be copied to. If this option is set, the user has to manually indicate where Python is located using {cmd: set python_exec "path to python.exe"} at every start of Stata.{p_end}


{marker remarks}
{title:Remarks}

{pstd}
This command from the opendf package is part of the Open Data Format Project bundle, written to assist with survey data files in the open data format(.zip).{p_end}
{pstd}
The deployed Python version will not be found automatically by Stata. However, it will be found by the functions of the opendf package, if it is installed to the default location (ado/plus-folder of Stata).{p_end}
{pstd}
To activate any Python installation on your computer in Stata, run: {cmd: set python_exec "C:/...path to python.exe"}.{p_end}


{marker examples}
{title:Examples}

{phang}Install portable Python v3.12 (default) to the folder python3.12 in the ado\plus folder. {p_end}
{phang}{cmd:. opendf installpython}{p_end}

{phang}Install Python v3.10  to the folder python3.10 in the ado\plus folder. {p_end}
{phang}{cmd:. opendf installpython, version("3.10")}{p_end}

{phang}Install Python v3.10  to the folder "C:\Program Files\python". {p_end}
{phang}{cmd:. opendf installpython, version("3.10") location("C:\Program Files\python")} {p_end}


{marker author}
{title:Author}

{pstd}
Tom Hartl ({browse "mailto:thartl@diw.de":thartl@diw.de}), Deutsches Institut für Wirtschaftsforschung Berlin. 


{marker alsosee}
{title:Also see}

{psee}
{space 2}Help: {help opendf read}, {help opendf write}, {help opendf docu}, {help opendf installpython}, {help opendf removepython}{p_end}
