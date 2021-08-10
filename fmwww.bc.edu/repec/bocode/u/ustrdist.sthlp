{smcl}
{* *! version 1.1  06may2017 Michael D Barker Felix Pöge}{...}
{cmd:help ustrdist}
{hline}

{title:Title}

{phang}
{cmd:ustrdist} {hline 2} Calculate the Levenshtein distance, or edit distance, between strings.


{title:Syntax}

{p 8 17 2}
{cmd:ustrdist}
{c -(}{varname:1}|{cmd:"}{it:string1}{cmd:"}{c )-}
{c -(}{varname:2}|{cmd:"}{it:string2}{cmd:"}{c )-}
{ifin}
[{cmd:,} {opth g:enerate(newvar)} ]


{title:Description}

{pstd}
{cmd:ustrdist} calculates the distance between strings and/or string
variables using the Levenshtein distance metric. Levenshtein distance, or edit
distance, is the smallest number of edits required to make one string 
match a second string. An edit may be an insertion, deletion, or 
substitution of any single letter.

{pstd}
{cmd:ustrdist} accepts two arguments, which may be string variables or 
string scalars in any combination. String scalars must be enclosed in quotes. 

{pstd}
Edit distances are returned in a scalar or a new variable, depending on
the type of arguments supplied. If the arguments contain one or two string 
variables, edit distances are returned in a new variable with default 
name {bf:ustrdist}. If both arguments are string scalars, edit distance 
is returned in {bf:r(d)}. 

{pstd}
Unicode characters are supported. 

{title:Options}

{dlgtab:Main}

{phang}
{opth generate(newvar)} Create a new variable named {it:newvar} containing 
edit distance(s). If the arguments include a string variable without
the {opt generate()} option, a new variable will be created with
default name {bf:ustrdist}.


{title:Examples}

{phang}{cmd:. ustrdist "cat" "hat"}

{phang}{cmd:. sysuse census} 

{phang}{cmd:. ustrdist state "west virginia" , gen(wvdist)} 


{title:Saved results}

{pstd}
{cmd:ustrdist} saves the following in {cmd:r()}:


{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(d)}}edit distance if arguments are both string scalars{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(ustrdist)}}name of new edit distance variable if created{p_end}
{p2colreset}{...}


{title:Author}

{pstd} Michael Barker {p_end}
{pstd} Georgetown University {p_end}
{pstd} mdb96@georgetown.edu {p_end}

{pstd} Felix Pöge {p_end}
{pstd} Max Planck Institute for Innovation and Competition {p_end}
{pstd} felix.poege@ip.mpg.de {p_end}


{title:Also see}

{pstd}
{help f_soundex:soundex},
{help strgroup:strgroup}


