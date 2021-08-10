{smcl}
{* 21nov2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:elfs colors} {hline 2} Manage colors for Stata windows, on Windows


{title:Description}

{pstd}These are sets of colors (plus {bf:boldface} and {ul:underline}) to be used by the {bf:Results} or {bf:Viewer} windows.

{pstd}The three {hi:EL} sets of result/viewer colors are intended to be useful as {bf:Preference Sets} for {stata "elfs instance, help":multiple instances}.


{title:Fields}

{phang}{cmd:Scheme} is a name for a whole set of seven colors (six types of text plus background).

{pstd}The following fields are present when editing, but not in the listing:

{phang}{cmd:tstyle} is an identifier for the six kinds of text (plus background) that can be assigned a color in the {bf:General Preferences}.

{phang}{cmd:red}, {cmd:green}, and {cmd:blue} are the rgb values for the color (0-255).

{phang}{cmd:bold} and {cmd:ul} specify whether the text should also be bold or underlined, respectively (0 for no, 1 for yes).

{title:Links}

{phang}{cmd:Use for Results} sets the {bf:Results} window to use its {bf:Custom Color Scheme 3}, and assigns the relevant colors to that scheme.

{phang}{cmd:Use for Viewer} sets the {bf:Viewer} window to use its {bf:Custom Color Scheme 3}, and assigns the relevant colors to that scheme.

{phang}{cmd:Delete} deletes a user-created scheme.

{phang}{cmd:Edit All} opens a data editor with all the defined schemes. Each {bf:Scheme} should have seven rows; one for each {cmd:tstyle}.

{phang}{cmd:Save Current Results} and {cmd:Save Current Viewer} will write the relevant colors as user-defined schemes {hi:Current Results} or {hi:Current Viewer}, respectively.
This will overwrite any existing schemes with those names, so it might be desirable to edit the names, after the settings are created.

{phang}{cmd:Set to on}/{cmd:Set to off} (Color Warning): 

{pmore}Commands which use the {help outopt:out()} option keep track of the colors they produce. When the same color is used for parts of the display that are ideally distinct,
a note is appended to the output (by default), pointing out that you can't see all of the intended contrast.

{pmore}For example, {help tfreq} uses different types of text for counts vs percents. If you use the same color for both types, you may not be able to tell which is which.
The note after the display points out that there is more detail than you can see.

{pmore}The ideal way to deal with this would be to assign distinct colors to every type of text. However, you can also turn off the warning.


