{smcl}
{* *! version 1.0.2 18sep2024}{...}
{viewerjumpto "Title" "replacen##title"}{...}
{viewerjumpto "Syntax" "replacen##syntax"}{...}
{viewerjumpto "Description" "replacen##description"}{...}
{viewerjumpto "Examples" "replacen##examples"}{...}
{viewerjumpto "Author" "replacen##author"}{...}
{marker title}{...}
{title:Title}

{pstd}
replacen {hline 2} Replace contents in exactly n observations.


{marker syntax}{...}
{title:Syntax}

{phang2}
{cmd:replacen} 
{it:n}
{it:oldvar}
={it:{help exp}}
{ifin}
[, options]


{marker description}{...}
{title:Description}

{pstd}
{cmd:replacen} executes the {help replace} command, but checks whether exactly {it:n} observations have been modified. If not, an error is issued.


{marker examples}{...}
{title:Examples}

The first call to {cmd:replacen} will not produce an error. The second, same, call will produce an error as no observations will be modified by the {cmd:replace} command.

	{cmd:. sysuse auto, clear}
	{cmd:. replacen 1 price = 0 if make == "AMC Concord"}
	{cmd:. replacen 1 price = 0 if make == "AMC Concord"}


{marker author}{...}
{title:Author} 

{pstd}
Hendri Adriaens, Centerdata, The Netherlands.{break}
hendri.adriaens@centerdata.nl
