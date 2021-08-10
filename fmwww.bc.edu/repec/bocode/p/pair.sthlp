{smcl}
{* 22dec2011}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: pair} {hline 2} Label a numeric var with a corresponding string var

{title:Syntax}

{pmore}{cmd:pair} {varname} {varname} {ifin} [, {opt k:eep} ]

{title:Description}

{pstd}{cmd:pair} creates value lables for a numeric variable based on the values in a string variable. A number cannot be paired with more than one string value.

{pstd}Unless {opt k:eep} (or {ifin}) is specified, the string variable will be dropped after the value labels are created.

{pstd}The value labels get the name of the numeric variable, with "_pair" appended.

