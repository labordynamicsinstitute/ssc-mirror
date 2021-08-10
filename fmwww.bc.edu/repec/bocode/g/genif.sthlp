{smcl}
{* 4nov2004}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:genif} {c -} Generate values by logical conditions

{title:Syntax}

{pmore}
{cmdab:genif} [{it:type}] {it:newvar} {cmd:=} {opt (value_if)} [{opt (value_if)} ...] [{opt (default_value)}]

{pstd}where {it:value_if} is

{pmore}{it:value} {cmd:if} {it:condition}

{pstd} and where {it:value}, {it:condition}, and {it:default_value} are valid stata {help exp:expressions}.

{title:Description}

{pstd}{cmd:genif} creates a new variable, and determines its values by evaluating, in order, the conditions in the list. If the first condition evaluates to true, the variable takes on the first value. Otherwise, if the second condition 
evaluates to true, the variable takes on the second value, etc.

{pstd}If no condition is true, the value is set to {it:default_value}, if specified, or otherwise missing.

{title:Example}

    {cmd:. genif happy= (10,sun=="shining") (7,sky=="blue") (3,temp=="warm") (2)}

