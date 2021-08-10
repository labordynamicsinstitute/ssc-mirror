{smcl}
{* 3Nov2014}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:insertat} {hline 2} Insert empty records in dataset
 
{title:Syntax}

{pmore}
{cmd:insertat} {it:row-number}[{cmd:*}{it:number-of-rows}]

{title:Description}

{pstd}{cmd:insertat} inserts one or more empty records at the specified point in the dataset. If {it:number-of-rows} is not specified, it defaults to 1.

