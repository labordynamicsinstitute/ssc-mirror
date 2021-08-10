{smcl}
{* *! version 1.3  25oct2020}{...}
{title:Title}

{phang}
{bf:frameappend} {hline 2} Append frames


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:frameappend}
{it:framename}
[{cmd:,} {cmd:drop}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt drop}}drops the frame {it:framename} after it has been appended{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:frameappend} appends the contents of {framename} to current frame.  The new
observations will be at the bottom of the current frame.

{pstd}
The command works for variable names that begin with an underscore.

{marker author}{...}
{title:Author}

{pstd}
Jeremy Freese, Stanford University, jfreese@stanford.edu

{pstd}
Revision uses improvements provided by Daniel Fernandes and Roger Newson.

