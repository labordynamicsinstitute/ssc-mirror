{smcl}
{* 2jul2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: qlabel} {hline 2} Quick label definitions

{title:Syntax}

{pmore}
{cmd:qlabel} [{cmd:(}] {it:{help varelist}} [{cmd:)}] {it:#} {cmd:"}{it:label}{cmd:"} 
[{it:#} {cmd:"}{it:label}{cmd:"} ...] 
[, {it:options}]

{title:Description}

{pstd}{cmd:qlabel} can replace multiple {help label define} and {help label values} statements.

{pstd}{cmd:qlabel} uses the standard Stata label definition after the {it:{help varelist}}. These value labels will be applied to all the variables in {it:{help varelist}}.

{pstd}Parentheses around the varlist are optional.

{pstd}Ordinarily, the definition in {cmd:qlabel} {it:replaces} any existing definition with the same name, but see {opt m:odify}, below.

{title:Options} 
 
{phang}{cmdab:n:ame()} specifies the value label name.  If no name is specified, the label name will be the name of the first variable in {it:{help varelist}}, with the added suffix {bf:_qlab}.

{phang}{opt f:ilter} ignores any non-existent variables in {it:{help varelist}}. Without {opt f:ilter}, a reference to a non-existent variable would cause an error.

{phang}{opt m:odify} causes the specified mappings to modify an existing label, instead of replacing it entirely. All of the variables in {it:{help varelist}} must either use the same set of labels, or none.

