{smcl}
{* *! version 1.0.0 Matthew White 25nov2013}{...}
{title:Title}

{phang}
{cmd:specialexp} {hline 2} Obtain expression that evaluates to string


{marker syntax}{...}
{title:Syntax}

{pmore}
{it:string scalar} {cmd:specialexp(}{it:string scalar s}
[{cmd:,} {it: real scalar n}]{cmd:)}


{marker description}{...}
{title:Description}

{pstd}
{cmd:specialexp()} converts a string to an expression that
evaluates to the string.
It can facilitate writing do-files that use difficult strings.


{marker remarks}{...}
{title:Remarks}

{pstd}
To be used in an expression, most strings need only be enclosed in
{help quotes##double:double quotes}. However, strings that contain
the Stata special characters {cmd:`}, {cmd:$}, or {cmd:"} or
an ASCII control character, such as the line-feed character ({cmd:\n}),
may also need the {cmd:\} escape character.
They may even require an expression that contains multiple strings.
For instance:

{pstd}
The string {cmd:abc} need only be enclosed in simple double quotes:

{cmd}{...}
{phang2}: specialexp("abc"){p_end}
{phang2}{space 2}"abc"{p_end}
{txt}{...}

{pstd}
The string {cmd:`x'} needs the {cmd:\} escape character:

{cmd}{...}
{phang2}: s = "`" + "x" + "'"{p_end}
{phang2}: s{p_end}
{phang2}{space 2}`x'{p_end}

{phang2}: specialexp(s){p_end}
{phang2}{space 2}"\`x'"{p_end}
{txt}{...}

{pstd}
The string {cmd:`\${x}""y""`} requires more than the escape character;
it must be split into multiple strings:

{cmd}{...}
{phang2}: s = "`\" + `"\${x}""y"""' + "`"{p_end}
{phang2}: s{p_end}
{phang2}{space 2}`\${x}""y""`{p_end}

{phang2}: specialexp(s){p_end}
{phang2}{space 2}"\`\" + `"\${x}""y"""' + "`"{p_end}

{phang2}: stata("mata: " + specialexp(s)){p_end}
{phang2}{space 2}`\${x}""y""`{p_end}
{txt}{...}

{pstd}
{cmd:specialexp(}{it:s}{cmd:)} returns an expression that evaluates to {it:s}.
{cmd:specialexp(}{it:s}, {it:n}{cmd:)} returns the expression and
stores in {it:n} the number of strings that the expression contains,
replacing {it:n}.

{cmd}{...}
{phang2}: specialexp("abc", n){p_end}
{phang2}{space 2}"abc"{p_end}

{phang2}: n{p_end}
{phang2}{space 2}1{p_end}

{phang2}: s = "`\" + `"\${x}""y"""' + "`"{p_end}
{phang2}: s{p_end}
{phang2}{space 2}`\${x}""y""`{p_end}

{phang2}: specialexp(s, n){p_end}
{phang2}{space 2}"\`\" + `"\${x}""y"""' + "`"{p_end}

{phang2}: n{p_end}
{phang2}{space 2}3{p_end}
{txt}{...}


{marker conformability}{...}
{title:Conformability}

{pstd}{cmd:specialexp(}{it:s}{cmd:,} {it:n}{cmd:)}{p_end}
		{it:s}:  {it:1 x 1}
		{it:n}:  {it:1 x 1}
	   {it:result}:  {it:1 x 1}


{marker diagnostics}{...}
{title:Diagnostics}

{pstd}
{cmd:specialexp(}{it:s} [{cmd:,} {it:n}]{cmd:)} aborts in error
if {it:s} contains binary 0 ({cmd:\0}).


{marker source}{...}
{title:Source code}

{pstd}
{help specialexp_source:specialexp.mata}


{marker author}{...}
{title:Author}

{pstd}Matthew White, Innovations for Poverty Action{p_end}
{pstd}mwhite@poverty-action.org{p_end}
