{smcl}
{* 14may2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}File I/O {hline 2} Use, save, import, export data

{title:Syntax}

{pmore}{cmd:usel}{space 3}[{help path_el} | {cmd:<}]  {ifin} [{cmd:,} {it:options}]

{pmore}{cmd:savel}{space 2}[{help path_el}] {ifin} [{cmd:,} {it:options}]

{synoptset}
{synopthdr}
{synoptline}
{synopt:{opt cd}}Changes the working directory to the directory of the data{p_end}
{synopt:{cmdab:k:eep(}{it:{help varelist}}{cmd:)}}Uses or saves only the specified variables{p_end}
{synopt:{opt pass(options)}}Passes import/export options through to other commands{p_end}

{syntab:Options for usel}
{synopt:{opt sys}}Look for the file in the system directories; like {help sysuse}

{syntab:Options for savel}
{synopt:{opt drop:after}}Drops the saved records from current data{p_end}
{synopt:{opt m:akedir}}Creates the specified directory path, if it doesn't already exist.{p_end}
{synopt:{opt l:abel(text)}}Sets the dataset label{p_end}
{synoptline}

{title:Description}

{pstd}{cmd:usel} and {cmd:savel} affect and are affected by the {help recent##datasource:current data source}, which is roughly the most recent external source of data, and is fully described under {help recent}.

{pstd}{bf:{ul:Common Features}} 

{phang}o-{space 2}They use {help path_el} to specify the file, which is more flexible than a standard {it:filepath}.{p_end}
{phang}o-{space 2}There are no {cmd:clear} or {cmd:replace} options, existing files or data in memory will always be replaced.{p_end}
{phang}o-{space 2}File types other than Stata data files may be saved and used, by including their extensions.{p_end}
{phang}o-{space 2}References to non-existent variables in external files will not cause an error.{p_end}
{phang}o-{space 2}A file reference is optional when one can be determined from the {help recent##datasource:current data source} {hline 1} which is usually the case.{p_end}

{pstd}{bf:{ul:Usel}}

{p2colset 9 30 32 2}{...}
{p2col:{ul:Command}}{ul:Description}

{p2col:{cmd:usel}}{cmd:usel} the {help recent##datasource:current data source}, if possible.{p_end}
{p2col:{cmd:usel <}}Use the most recent valid dataset, prior to the {help recent##datasource:current data source}{p_end}
{p2col:{cmd:usel} {it:{help path_el}}}Use the specified file.{p_end}

{pmore}Note that {cmd:usel <} will search back before the {help recent##datasource:current data source} as far as necessary to find the most recent source it can use (ie, one that was set with {cmd:usel} or {cmd:savel}).


{pstd}{bf:{ul:Savel}}

{p2colset 9 37 39 2}{...}
{p2col:{ul:Command}}{ul:Description}

{p2col:{cmd:savel}}Save using the directory and filename of the {help current data source}, if possible.{p_end}
{p2col:{cmd:savel} {it:{help path_el}}}Save to the specified path.{p_end}
{p2col:{cmd:savel} {it:{help path_el}} {cmd:if}/{cmd:in}/{cmd:,keep()}}Save the specified subset of data.{p_end}

{pmore}{cmd:if}, {cmd:in}, and/or {cmd:keep()} can be used with {cmd:savel} as they are with most commands: Ie, they limit the observations and variables acted upon.
In particular, they determine the data that will be {it:saved}, but they do not affect the data in memory. They allow you to save a subset of the data.

{pmore}When {cmd:savel} is specified with no main parameter, it will use the directory and filename of the {help current data source}, and the {cmd:.dta} extension, if possible. In other words:{p_end}

{phang3}o-{space 2}If the {help current data source} is a {cmd:.dta} file, it will be overwritten.{p_end}
{phang3}o-{space 2}If the {help current data source} is a file with some other extension, a {cmd:.dta} version will be written, in the same directory, with the same name.{p_end}
{phang3}o-{space 2}If the {help current data source} is empty or remote, {cmd:savel} will require an explict {it:{help path_el}}.


{title:Options}

{dlgtab:General}

{phang}{opt cd} changes the working directory to the directory containing the used or saved file.

{phang}{opth keep(varlist)} applies the command to the specified variables only.

{phang}{opt pass()} passes import/export options along to the appropriate handler.

{phang2}o-{space 2}For file extensions {cmd:.txt} or {cmd:.csv}, the options are those for {help import delimited} or { help export delimited}.{p_end}
{phang2}o-{space 2}For file extensions {cmd:.xl}, {cmd:.xls} or {cmd:.xlsx}, the options are described under {help portel xl}.{p_end}
{phang2}o-{space 2}For other file extensions (besides {cmd:.dta}), the options are those for {help callst}.{p_end}


{dlgtab:Usel}

{phang}{opt sys} specifies that the file to be useled is (correctly placed) in the system directories. When that is the case, {opt sys} is an alternative to specifying the entire path explicitly.


{dlgtab:Savel}

{phang}{opt drop:after} drops the records specified by {cmd:if} and {cmd:in} after they've been saved to another data file.

{pmore}Note that while {opth k:eep(varlist)} identifies specific variables to be {it:saved}, this has no effect on {opt drop:after}; the entire records specified by {cmd:if} and {cmd:in} will be dropped.

{phang}{opt m:akedir} will create the directory path specified in {it:{help path_el}}, if it doesn't already exist.

{phang}{opt l:abel(text)} is just a shortcut for setting the dataset {help label}.

{phang}{opt vers:ion(#)} specifies saving/exporting with an older file format: 11, 12, or 13 can be specified.


{title:Examples}

   {cmd:. usel a space filled name}
   
   {cmd:. usel other-directory/goodies, cd}
   
   {cmd:. usel blahblah/bl*/bl*/bl*/bl*}
   
   {cmd:. usel <}
   
   {cmd:. savel asubset in 1/100 if flag=="OK", keep(some-somemore another)}

