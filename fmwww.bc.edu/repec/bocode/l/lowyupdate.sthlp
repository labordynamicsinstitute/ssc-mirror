{smcl}
{* 19jun2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:lowyseattle} {hline 2} Update installation

{title:Syntax}

{p 8 17 2}{cmd:lowyseattle} [{cmd:,} {opt c:ompile}]

{title:Description}

{pstd}{cmd:lowyseattle} is a utility for creating and/or updating the main lowyseattle mata library. The library must be created locally when using an older version of Stata.

{pstd}Without the compile option, it will report version date/times for the compiled library (if any) and for the available source code, and the Stata version the library was compiled by.
It will also provide a link to run with the compile option.

