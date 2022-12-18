{smcl}
{* *! version 1.0.0  15december2022}{...}
{p2colset 1 17 19 2}{...}
{p2col:{bf:pullin} {hline 2} Run a many-to-one merge with a specific set of options}{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

	{cmd:pullin} {varlist} {cmd:using} {it:{help filename}}


{marker description}{...}
{title:Description}

{pstd}
{opt pullin} runs a many-to-one merge with the options {cmd:keep(}1 3{opt )} and {opt nomerge} specified. This "pulls in" the data attached to matched observations from the using file without bringing in unmatched observations from said dataset.

{pstd}
Running this command:

{pstd}
{cmd:pullin} {varlist} {cmd:using} {it:{help filename}}

{pstd}
is equivalent to running this command:

{pstd}
{cmd:merge m:1} {varlist} {cmd:using} {it:{help filename}} {cmd:, keep(}1 3{opt ) nogen}

{pstd}
and that's that!


{marker option}{...}
{title:Option}

{phang}
{cmd:pullin} does not allow if, in or any options. The whole point of the command is to do the very specific kind of merge specified above.

