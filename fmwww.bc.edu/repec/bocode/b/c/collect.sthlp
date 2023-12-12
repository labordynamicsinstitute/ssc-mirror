{smcl}
{* 18feb2011}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "recent" "recent"}{...}
INCLUDE help also_vlowy
{title:Title} 
 
{pstd}{bf:collect} {hline 2} Concatenate multiple files

{title:Syntax}

{pmore}{cmdab:collect} {it:{help path_el}} [{cmd:;} {it:{help path_el}} ...] [{cmd:,}  {opt ap:pend} {cmdab:k:eep(}{it:{help varelist}}{cmd:)} {opt pass(options)} {opt t:est}]

{pstd}Wildcards in {it:{help path_el}} can be used to specify multiple files in a directory.


{title:Description}

{pstd}{cmd:collect} concatenates multiple files into a single dataset in memory. The files may be in a mix of formats (though some formats would require StatTransfer). Variables can be combined and renamed.

{pstd}Before collecting any data, {cmd:collect} gives a fairly detailed report of what it is about to do. It shows, for each data file that will be collected:

{phang2}o-{space 2}The paths and assigned id numbers{p_end}
{phang2}o-{space 2}The number of variables that will be kept{break}
(as a link showing all variables, and highlighting the ones to be kept){p_end}
{phang2}o-{space 2}Any naming/renaming errors

{pstd}and then:

{phang2}o-{space 2}Anything specified in {opt keep()} that was not found in any dataset.

{pstd}If there are errors, all of them will be reported before the command aborts.

{pstd}{cmd:collect} adds a variable, {cmd:_file}, identifying the file each observation came from. {cmd:_file} contains id numbers, and is labeled with the file names.


{title:Options}

{phang}{opt ap:pend} causes the specified files to be {bf:appended} to the data in memory, rather than {bf:replacing} it.

{phang}{cmdab:k:eep(}{it:{help varelist}}{cmd:)} specifies the variables to be kept from any of the files collected. The variables in {cmdab:k:eep()} do not need to be present in every (or indeed any) file.
If they are present in any of the collected files, they will be kept in the final data file.

{pmore}{it:{help varelist}} allows {help varelist##mods:modifiers} for combining/renaming variables:

{p2col 13 29 29 2:{ul:{help varelist##mods:Modifier}}}{ul:Description}{p_end}

{p2col 13 29 29 2:{cmd:(->} {it:varname}{cmd:)}}Rename any modified variables to {it:varname}

{pmore}For example:

{pmore2}{cmd:collect f*, keep(Rob*(-> Bobby) A-Z )}

{pmore}would collect all files starting with {cmd:f}. From each of those files, all variables starting with {cmd:Rob}, and from {cmd:A} to {cmd:Z} would be kept.
All variables starting with {cmd:Rob} (eg, {cmd:Rob}, {cmd:Robby}, {cmd:Robert}) would be renamed to {cmd:Bobby}. 

{pmore}If multiple variables from the same dataset would end up with the same name, an error will be generated.

{pmore}

{phang}{opt t:est} causes {cmd:collect} to report on what it would do (ie, which files it would use, variables used or not found, any errors, estimate of observations), without actually collecting the data.

{phang}{opt pass()} passes import/export options along to the appropriate handler.

{phang2}o-{space 2}For file extensions {cmd:.txt} or {cmd:.csv}, the options are those for {help import delimited}.{p_end}
{phang2}o-{space 2}For file extensions {cmd:.xl}, {cmd:.xls} or {cmd:.xlsx}, the options are described under {help portel xl}.{p_end}
{phang2}o-{space 2}For other file extensions (besides {cmd:.dta}), the options are those for {help callst}.{p_end}


{title:Examples}

{pstd}Using unrelated semicolon-separated paths:

{pstd}{cmd:. collect a:/one/path.dta; b:/another/path.dta}

{pstd}Using wildcards to select multiple files from a single directory:

{pstd}{cmd:. collect a:/single*/dir*/allofthese*.dta}

