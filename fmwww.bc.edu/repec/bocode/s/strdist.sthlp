{smcl}
{* *! version 1.1  06may2017 Michael D Barker Felix Pöge}{...}
{cmd:help strdist}
{hline}

{title:Title}

{phang}
{cmd:strdist} {hline 2} Calculate the Levenshtein distance, or edit distance, between strings.


{title:Syntax}

{p 8 17 2}
{cmd:strdist}
{c -(}{varname:1}|{cmd:"}{it:string1}{cmd:"}{c )-}
{c -(}{varname:2}|{cmd:"}{it:string2}{cmd:"}{c )-}
{ifin}
[{cmd:,} {opth g:enerate(newvar)} ]


{title:Description}

{pstd}
{cmd:strdist} calculates the distance between strings and/or string
variables using the Levenshtein distance metric. Levenshtein distance, or edit
distance, is the smallest number of edits required to make one string 
match a second string. An edit may be an insertion, deletion, or 
substitution of any single letter.

{pstd}
{cmd:strdist} accepts two arguments, which may be string variables or 
string scalars in any combination. String scalars must be enclosed in quotes. 

{pstd}
Edit distances are returned in a scalar or a new variable, depending on
the type of arguments supplied. If the arguments contain one or two string 
variables, edit distances are returned in a new variable with default 
name {bf:strdist}. If both arguments are string scalars, edit distance 
is returned in {bf:r(d)}. 

{pstd}
For a version supporting unicode for Stata 14 and above, see {help ustrdist}.

{title:Options}

{dlgtab:Main}

{phang}
{opth generate(newvar)} Create a new variable named {it:newvar} containing 
edit distance(s). If the arguments include a string variable without
the {opt generate()} option, a new variable will be created with
default name {bf:strdist}.


{title:Examples}

{phang}{cmd:. strdist "cat" "hat"}

{phang}{cmd:. sysuse census} 

{phang}{cmd:. strdist state "west virginia" , gen(wvdist)} 


{title:Saved results}

{pstd}
{cmd:strdist} saves the following in {cmd:r()}:


{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Scalars}{p_end}
{synopt:{cmd:r(d)}}edit distance if arguments are both string scalars{p_end}

{synoptset 15 tabbed}{...}
{p2col 5 15 19 2: Macros}{p_end}
{synopt:{cmd:r(strdist)}}name of new edit distance variable if created{p_end}
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
{help strgroup:strgroup},
{help ustrdist}.

