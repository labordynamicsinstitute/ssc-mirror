{smcl}
{* 2sep2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title} 

{pstd}{bf:varelist} {c -} extended varlist

{title:Description}

{pstd}A {it:varelist} is a superset of a Stata {varlist}. The differences can be safely ignored if you like.

{pstd}The three differences are:

{phang}1){space 2}{bf:Repeated variables} {hline 2} which are only selected once{p_end}
{phang}2){space 2}{bf:Ranges} {hline 2} which are more expansive{p_end}
{phang}3){space 2}{bf:Modifiers} {hline 2} which are bits set off in parentheses{p_end}


{title:Repeated Variables}

{pstd}In the following, consider the dataset {cmd:arch}-{cmd:bromide}-{cmd:carpet}:

{phang}o-{space 2}The results of a {it:varelist} will include each selected variable only once, no matter how many times it is specified. {cmd:tlist a a} would display a single column of {cmd:arch}, not two columns.

{phang}o-{space 2}A variable will show up in the first place it is specified. For example, {cmd:tlist * b} would display {cmd:arch bromide carpet}, while {cmd:tlist b *} would display {cmd:bromide arch carpet}.

{phang}o-{space 2}A variable is {bf:modified}, or operated upon, only in its first occurrence. For example:

{pmore2}{cmd:finddata key using afile, copy(arch->bromide *)}

{pmore}would copy all variables, renaming {cmd:arch} to {cmd:bromide}. But, if the command were written {cmd:copy(* arch->bromide)}, {cmd:arch} would not be renamed.


{title:Ranges}

{pstd}Ranges extend a standard stata {varlist} range in two ways:

{phang}o-{space 2}Endpoints can be specified in either order. Both {cmd:tlist a-z} and {cmd:tlist z-a} would yield the alphabet.

{phang}o-{space 2}Ranges can be combined with wildcards. When a wildcard is included, the most extreme variables found are used as the endpoint(s).
{cmd:tlist b*-y*} would find all variables that start with either {cmd:b} or {cmd:y}, choose the first and last, and list everything between them (inclusive).


{marker mods}{title:Modifiers}

{pstd} In general, a {bf:modifier} is anything enclosed in parentheses {cmd:( )}, and {it:modifies} either:

{phang}o-{space 2}whatever is touching the opening or closing paren (either is allowed, but not both), or{p_end}
{phang}o-{space 2}if nothing is touching a paren, everything that follows the {bf:modifier}, until another modifier (or modified variable/range) is reached.

{pstd}For example:

{p2colset 9 35 35 2}{...}
{p2col:{cmd:a(mod1)}}{cmd:mod1} affects {cmd:a}{p_end}
{p2col:{cmd:b*(mod2)}}{cmd:mod2} affects all variables starting with {cmd:b}{p_end}
{p2col:{cmd:a-z()}}The empty modifier affects all variables in the range {cmd:a} to {cmd:z}{p_end}
{p2col:{cmd:(mod3) a b c* h-k(mod4)}}{cmd:mod3} affects {cmd:a}, {cmd:b}, and {cmd:c*}; {cmd:mod4} affects range {cmd:h-k}.{p_end}


{pstd}{bf:Modifiers} are specific to certain commands. If a command does not describe any modifiers, none are allowed. When {it:any} modifiers are allowed, empty parens {hline 1} {cmd:()} {hline 1} can be used to specify {it:no} modifier.

