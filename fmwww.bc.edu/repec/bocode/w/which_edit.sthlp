{smcl}
{viewerjumpto "Syntax" "which_edit##syntax"}{...}
{viewerjumpto "Examples" "which_edit##examples"}{...}
{viewerjumpto "Author and support" "which_edit##author"}{...}
{title:Title}
{phang}
{bf:which_edit} {hline 2} Given command name or name on extended functions finds 
and opens the code file or the help file in the Do-file Editor.

{error: Use only to look at code. Never edit code files!}

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:which_edit} name 
[{cmd:,}
{opt h:elp}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Optional}
{synopt:{opt h:elp}} Open help file for command in editor. {p_end}


{marker examples}{...}
{title:Examples}
{phang}Open do-file file for command {cmd:regress}.{p_end}
{phang}{stata `"which_edit regress"'}{p_end}
{phang}Open help-file file for command {cmd:regress}.{p_end}
{phang}{stata `"which_edit regress, help"'}{p_end}
{phang}Open do-file file for extended function {cmd:rowtotal}.{p_end}
{phang}{stata `"which_edit rowtotal"'}{p_end}


{marker author}{...}
{title:Authors and support}

{phang}{bf:Author:}{break}
 	Niels Henrik Bruun, {break}
	Aalborg University Hospital
{p_end}
{phang}{bf:Support:} {break}
	{browse "mailto:niels.henrik.bruun@gmail.com":niels.henrik.bruun@gmail.com}
{p_end}
