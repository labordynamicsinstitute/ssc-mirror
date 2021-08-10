{smcl}
{* 9jan2015}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "finddata" "help finddata"}{...}
{vieweralsosee "same" "help same"}{...}
{vieweralsosee "collect" "help collect"}{...}
INCLUDE help also_vlowy
{title:Title} 
 
{pstd}{bf:drany} 'drop any' {hline 1} drop (existing) variables and/or observations

{title:Syntax} 
 
{pmore}
{cmdab:drany} {it:{help varelist}} {ifin} [{cmd:,} {opt cl:ear}[{cmd:(}{it:command-list}{cmd:)}] ]


{title:Description}

{pstd}{cmdab:drany} works like {help drop}, with two distinctions:

{phang}1){space 2}Terms in {it:{help varelist}} that do not match existing variables are simply reported, they do not cause an error.

{phang}2){space 2}The {opt clear} option will drop command-generated variables (eg, {cmd:_found}) {hline 1} {bf:after} dropping any specified observations. For example, after {cmd:finddata}:

{pmore2}{cmd:drany if !_found, cl}

{pmore}would drop any observations not found in the external file, and then drop the variable {cmd:_found}.


{title:Options}

{phang}{opt cl:ear} drops descriptive variables that are left behind by various commands {hline 1} eg, {cmd:_found}, {cmd:_dups}, {cmd:_file} (only {help lowy:my} commands).

{pmore}With no parameters, {opt cl:ear} will cause {bf:all} such variables to be dropped. Otherwise, {opt cl:ear(command-list)} will drop only variables created by the specified commands; eg, {cmdab:cl:ear(finddata)}.

