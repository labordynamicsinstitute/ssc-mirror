{smcl}
{* 27aug2007}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:file/directory path} {c -} el version

{title:Description}

{pstd}{it:path_el} is a somewhat more flexible version of a standard file- or directory- path. It does not require quotes, even if it includes spaces, and it allows the standard wildcard characters:

{pstd}{cmd:*} for any string of 0 or more characters{break}
{cmd:?} for any single character

{pstd}Enough information must be included for each directory to resolve unambigously to a single, existing, directory. Any part of the {it:path_el} that could refer to more than one directory will cause an error.

{pstd}The same thing is {it:usually} true for files; however, there are some commands that allow wildcards to specify multiple files in a directory.

{p 0 4 2}{bf:[+]} One thing to watch out for: Stata interprets {cmd:/*} as the beginning of a comment, so it will not recognize it as part of a {it:path_el}. The simplest solution (on a windows machine) is to use {cmd:\*} instead.

{title:Examples}

{pstd}Given a directory with subdirectories:

{col 9}{cmd:able}
{col 9}{cmd:baker}
{col 9}{cmd:charlie}
{col 9}{cmd:delta}

{pstd}the {it:path_el} {cmd:c*} would be interpreted as {cmd:charlie}. If the subdirectories were:

{col 9}{cmd:able}
{col 9}{cmd:baker}
{col 9}{cmd:charlie}
{col 9}{cmd:chan}
{col 9}{cmd:delta}

{pstd}the {it:path_el} {cmd:c*} would result in an error message listing both {cmd:charlie} and {cmd:chan}.

{col 5}{hline 10}

{pstd}Given a file: {cmd:top/next/third/thefile.dta} 

{pstd}The {it:path_el} {cmd:t*/n*/th*/t*} would successfully refence it {c -} assuming that the abbreviations at each level could be resolved without ambiguity. 

