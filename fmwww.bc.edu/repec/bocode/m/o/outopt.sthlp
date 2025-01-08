{smcl}
{* 7oct2009}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "html" "html"}{...}
{vieweralsosee "toview" "toview"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{cmd:Output destination and details}

{title:Syntax}

{pmore}{cmd:out(}[{it:destination}] [{cmd:,} {it:sub-options}]{cmd:)}

{pstd}where {it:destination} is one of:

{pmore}{opt results}{p_end}
{pmore}{opt v:iewer}{p_end}
{pmore}{opt htm:l file}{p_end}
{pmore}{opt html p:age}{p_end}
{pmore}{opt m:ata}{p_end}


{title:Description}

{pstd}{opt out()} specifies where the output from its command appears, along with a few related details.

{pstd}Sub-options are described with each destination, and general style sub-options after that.


{title:Destination: results}

{phang}{opt results} is an optional specification; when no {it:destination} is specified, output is to the Results window as usual.


{title:Destination: viewer}

{pstd}{opt v:iewer} sends the output to a Viewer tab.{p_end}

{pstd}{ul:sub-options}

{phang}{opt n:ame(which)} specifies which viewer tab to use. If {it:which} is a valid stata {it:name}, output will go to that viewer (opening one of that {it:name} if necessary).
Otherwise, if {it:which} is a valid {it:file-path}, output will be saved to the specified file, and then displayed in a viewer named with the file name.

{phang}{opt app:end} specifies that the current output be appended to a viewer window, instead of overwriting it. This will always work with the most recently used tab;
however, to append to 'older' tabs, they must have been (and continue to be) specified with {it:file-paths}, rather than {it:names}.

{title:Destination: html file}

{phang}{opt htm:l file} sends the output to an html file on disk, and displays the file in a browser (eg, Firefox, IE).

{pstd}{ul:sub-options}

{phang}{opt email} specifies a special, self-contained, format (ie, html {cmd:<pre>}) that can be cut & pasted from the browser into (html) email with formatting/appearance intact.

{phang}{opt t:itle()}, {opt r:evision()}, and {opt d:escription()} each provide text for pre-defined field that will display at the top of the page.

{phang}{opt sav:ing(filepath)} specifies where to save the output file. When it is not specified, the file is saved (as {cmd:_html.html}) in the settings directory.

{phang}{cmd:ms}{space 2}specifies a special format that enables Word, Excel, etc. to recognize and retain the html formatting.

{pmore}You can set up {opt ms} to open files directly in Word or Excel instead of a browser: Along with {opt ms}, specify {opt saving()}, and include a custom file extension in the {it:filepath}.
The extension will be remembered and used by default whenever {opt ms} is specified.
With the proper OS fiddling to recognize the extension, the files will open in Word or Excel instead of a browser, whenever {opt ms} is specified.


{title:Destination: html page}

{phang}{opt html p:age} sends the output to the currently selected {help html} {cmd:page} (and {cmd:div}) in memory. See {help html}.


{title:Destination: mata}

{pstd}{opt m:ata} sends the output (as a text string) to a Mata variable. By default, the text is formatted as {help smcl}.

{pstd}{ul:sub-options}

{phang}{opt v:ariable(name)} is mandatory; it is the name of the mata variable to receive the output.

{phang}{opt html} specifies formatting the text as standard html, instead of {help smcl}.

{phang}{opt email} specifies formatting the text as html {cmd:<pre>}, instead of {help smcl}.


{marker schemes}{title:Style sub-options}

{phang}{opt sch:eme(name)} selects a set of styles (eg, fonts, colors, lines), defined and managed through the {help elfs} command.

{pmore}There is always a default scheme, used when none is specified, and it can also be defined with the {help elfs##out:elfs} command.

{phang}{opt sty:les(defs|file)} defines individual additions to, or replacements for, the scheme:

{phang2}o-{space 2}{it:defs} are style definitions typed directly in the option.{p_end}
{phang2}o-{space 2}{it:file} is a path to a text file containting style definitions.

{pmore}For {bf:html} text, the definitions are {bf:standard CSS}. For {cmd:email} or {bf:smcl}, the class names and attributes differ as they do for schemes, as described in {help elfs##out:elfs}.

{pstd}An html example: You could {hline 1} one way or another {hline 1} make use of the style-name {cmd:superbig} in your output.
Then you could define the style in the {cmd:out} option:

{pmore}{cmd:out(htm, styles(.superbig {font-size: 300%}))}

