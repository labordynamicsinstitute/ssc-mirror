{smcl}
{* 11mar2016}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs misc} {hline 2} Miscellaneous Settings


{title:Description}

{pstd}For this group, each {bf:record} is a different kind of setting.

{title:Records}

{phang}{cmd:Stata appID} Is a string that goes at the beginning of the main window title. It's used to identify the window as {cmd:Stata} to other applications/processes. You can set it to empty.

{phang}{cmd:wformat} is a pattern for the main window title (after the {cmd:Stata appID}).

{pmore}When the {help recent##datasource:current data source} or {help elfs instance:instance} is updated, the main window title is updated to reflect it. You can specify what shows in the window title with this setting.
It can include whatever text you like, including the following special placeholders:

{p2colset 9 23 24 2}{...}
{p2col:Placeholder}Replaced with{p_end}
{col 9}{hline}
{p2col :{opt %i}}The {it:{help elfs instance:instance id}} of this instance of Stata{p_end}

{p2col :{opt %p}}For usel/savel, the path to the datafile{p_end}
{p2col :{opt %p}{it:n}}For usel/savel, the first {it:n} subdirectories of the path ({it:n} from 1 to 9){p_end}
{p2col :{opt %p-}{it:n}}For usel/savel, the last {it:n} subdirectories of the path ({it:n} from 1 to 9){p_end}
{p2col :{opt %f}}For usel/savel, the file-name{p_end}
{p2col :{opt %e}}For usel/savel, the file extension{p_end}
{p2col :{opt %e?}}For usel/savel, the file extension, only if it is not {cmd:.dta}{p_end}

{p2col :{opt %c}}For other commands, the name or identifier of the command{p_end}

{pmore}The default format is: {cmd:%i %f%e?%c} {hline 2} instance-id, and then either the local file-name (for {cmd:usel} and {cmd:savel}) or the command name (for {cmd:sql} and {cmd:clearl}).
The file extension is displayed only if it's not {cmd:.dta}.

{pmore}Leading and trailing spaces in {it:format} are ignored.

{phang}{cmd:fromEditor path} is the filepath to use for code being passed from an external editor to Stata.{p_end}

{phang}{cmd:dobreak} is markup for code being passed in from an external editor. When code is executed based on the cursor position instead of an explicit selection,
all the code  will be executed from the prior {cmd:dobreak} up to the next {cmd:dobreak}.{p_end}

{title:Links}

{phang}{cmd:Delete} deletes a user-added setting.

{phang}{cmd:Edit All} opens a data editor where all the settings can be edited.


