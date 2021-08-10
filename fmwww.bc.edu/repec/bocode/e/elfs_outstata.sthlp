{smcl}
{* 21dec2013}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "elfs" "elfs"}{...}
{vieweralsosee "elfs outhtml" "elfs outhtml"}{...}
{vieweralsosee "elfs outemail" "elfs outemail"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf: elfs outstata} {hline 2} Output Schemes for commands using {cmd:out()}


{title:Description}

{pstd}These schemes determine how the ouput appears, using {cmd:out(results)} or {cmd:out(results)}. And since {cmd:out(results)} is the default, they also determine the appearance when no {cmd:out()} option is specified.

{pstd}If {cmd:class} and {cmd:attributes} are unfamiliar to you, you can consider {cmd:class} to be 'input' and {cmd:attributes} to be 'output':
A command produces text with some {cmd:class}es, and you determine what the result looks like by specfiying the {cmd:attributes} for those {cmd:classes}.

{pstd}However, in the case of {cmd:outstata}, there is an added wrinkle, in that the {bf:output} {cmd:attributes} are themselves the {bf:input} to Stata's translation into colors (etc.), using the {bf:General Preference} settings.

{pstd}This makes it unlikely that you would want to adjust these settings; to set final Stata output appearance, see {stata "elfs colors, help":elfs colors}.


{title:Fields}

{phang}{cmd:scheme} is the identifier for the whole group of style definitions. This is the identifier you would use in {cmd:out( , scheme(}{it:scheme}{cmd:))}.

{phang}{cmd:class} is the 'internal' representation of the style, so to speak. All of the {cmd:classes} that are produced by the regular commands are included in all built-in schemes.

{pmore}You can include fewer or more {cmd:classes} in your own schemes:

{phang2}o-{space 2}{cmd:Classes} that are not defined in your scheme will be filled in from the built-in, if necessary.{p_end}
{phang2}o-{space 2}Extra {cmd:classes} that you define can be used by {help tlist:tlist, class()}.

{phang}{cmd:attributes} can be any of the attributes found in the built-in scheme ({bf:only}).{p_end}


{title:Links}

{phang}{cmd:Set Default} sets the scheme to be used by {cmd:out()} whenever  no {opt scheme()} is explicitly specified.

{phang}{cmd:Delete} deletes a user-created scheme.

{phang}{cmd:Edit All} opens a data editor with all the defined schemes.

