{smcl}
{* 28aug2007}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:uniq} {hline 2} Unique combinations of variables

{title:Syntax}

{pstd}{cmd:uniq} {it:{help varelist}} {ifin} [ {cmd:,} {opt c:ount} ]

{title:Description}

{pstd}For the specified {it:{help varelist}}, {cmd:uniq} counts the number of distinct value-combinations in the dataset. It can be used with the {cmd:by} prefix.

{pstd}If {opt c:ount} is specified, the total number of records will be displayed as well.

{pstd}{cmd:uniq} does not count missing values.

{title:Examples}

   {cmd:. uniq firstname lastname}
   
   {cmd:. uniq name if female}
   
   {cmd:. bysort state: uniq county}

