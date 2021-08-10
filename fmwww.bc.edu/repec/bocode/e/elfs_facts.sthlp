{smcl}
{* 11mar2016}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs facts} {hline 2} File actions and associations


{title:Description}

{pstd}These are file settings that can be implemented in the Windows registry, to assign handy info & actions to relevant files.

{pstd}These settings do nothing unless/until the {cmd:Set} link is clicked, when they set the current info into the registry. Things that are {cmd:Set} cannot be unSet, unlike most of the other settings.
They can be {cmd:Set} again, with new info, or the registry can be adjusted in any other usual way.

{title:Fields}

{phang}{cmd:Name} is the file-type {hline 1} the logical identity.

{phang}{cmd:Extension} is a space-separated list of file extensions that will be treated as file-type {cmd:Name}.

{phang}{cmd:Icon} is the name of an icon file, to use as the source of the icon. The file must be located in a proper place on the {help adopath} {hline 1} as if it were an {cmd:.ado} file. Leave it blank to use (any) default icons.

{phang}{cmd:open} is something to do when the file is double-clicked or otherwise opened in Windows Explorer. If {cmd:open} = {cmd:usel}, Stata & {help usel} will be used to open the file.
If {cmd:open} is anything else, the exact text will be put in the registry as the open command.

{phang}{cmd:Desc} Is a description for {cmd:Name}. It shows up in Windows Explorer as the 'Type'.


{title:Links}

{phang}{cmd:Set} Adds an entry to the Windows registry for {cmd:name}, if it doesn't exist, and assigns any specified extensions, icons, open commands, and descriptions.

{phang}{cmd:Edit All} opens a data editor where all the settings can be edited.


