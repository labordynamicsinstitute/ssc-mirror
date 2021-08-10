{smcl}
{* 8jan2010}{...}
{* @@ Written by Elliott Lowy, mostly on the US government's dime (17 US Code § 105).}{...}
{vieweralsosee "out()" "outopt"}{...}
INCLUDE help also_vlowy
{title:Title}

{pstd}{bf:html} {hline 2} Combine output in an html file

{title:Contents}

{p2colset 5 25 28 2}{...}
{p2col:{ul:{it:Sub-command}}}{ul:{it:Description}}{p_end}
{p2col:{help html##page:html page}}Create a page in memory{p_end}
{p2col:{it:cmd}{cmd:,} {help outopt:out(html p)}}Add data (tables){p_end}
{p2col:{help html##bits:html bits}}Add text, graphics, controls, stata log, page breaks{p_end}
{p2col:{help html##write:html write}}Write/display a page{p_end}

{p2col:{help html##div:html div}}Create or select a page division{p_end}
{p2col:{help html##redir:html {ul:redir}ect}}Select a different page.{p_end}
{p2col:{help html##query:html query}}Display page styles{p_end}
{p2col:html clear}Clear the html contents in memory{p_end}

{p2col:{help html##html:htm html}}{help html##html:See below}{p_end}


{title:Overall Description}

{pstd}This suite of commands is for incorporating multiple elements into a single (html) document. The usual, simplest, sequence would be something like:

{phang2}{cmd:html page, title(New Stats) rev(today) des(of current interest)}{p_end}
{phang2}{cmd:tfreq a b c, out(html p)}{p_end}
{phang2}{cmd:tstats d e f, by(g) out(html p)}{p_end}
{phang2}{cmd:html write recent stats}{p_end}

{phang}o-{space 2}Output from any command that uses the {help outopt:out option} can be included.{p_end}
{phang}o-{space 2}Stata graphs in memory, or any external web-compatible image files can be included.{p_end}
{phang}o-{space 2}Table-of-Contents entries create a menu at the top of the page that can be used to skip down to any point.{p_end}
{phang}o-{space 2}Dynamic displays can be created by using controls to show/hide different bits.


{marker page}{title:html page}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html page} [{it:page-id}] [{cmd:,} {opt t:itle(text)} {opt r:evision(text)} {opt d:escription(text)} {opt st:yles(css|filepath)} ]

{pstd}{ul:Description}

{pmore}{cmd:html page} creates or replaces a page in memory, which becomes the destination for html content. An existing {it:page-id} will be replaced with a fresh empty one.
{it:page-id} can be omitted, in which case {cmd:pg1} is used, but that detail can be safely ignored.

{pstd}{ul:Options}

{phang2}{opt t:itle(text)}, {opt r:evision(text)}, and {opt d:escription(text)} each specify text for a pre-defined field that will display at the top of the page.
There are no formatting restrictions for {it:text} {hline 2} eg, revision can be a date or number or whatever you like. These three fields are also included as html meta-data in the written page.

{phang2}{opt st:yles(css|filepath)} adds user-defined css styles, that can then be referenced by any elements on the page. {it:css} is explicit css style definitions; {it:filepath} points to a css file.


{marker bits}{title:html bits}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html bits,} {it:options}

{pstd}where options is any sequence composed of the following:

{col 9}{opt toc(text)}
{col 9}{opt p:aragraph(text)}
{col 9}{opt text(text)}
{col 9}{opt file(fileref)}
{col 9}{opt image(details)}
{col 9}{opt log(details)}
{col 9}{opt break}
{col 9}{opt cbox(details)}
{col 9}{opt dropdown(details)}
{col 9}{opt buttons(details)}


{pstd}{ul:Description}

{pmore}Each specified option is added in order. Sub-options and related details are described in their own section, below all the options.

{pstd}{ul:Options}

{phang2}{opt toc(text)} adds {it:text} both in a menu at the top of the page, and as a section marker in the body of the page. Selecting the the menu item will jump to the section on the page.

{phang2}{opt p:aragraph(text)} adds {it:text}, as a paragraph with class {cmd:bitsp}.

{phang2}{opt text(text)} adds the {it:text}, exactly, on the page. It can/should include markup.

{phang2}{opt file(fileref)} adds the contents of {it:fileref}, exactly, on the page. The contents can/should include markup.

{phang2}{cmd:image(}{it:stgraph}|{it:filepath} [{cmd:,} {opt t:ip(text)} {opt w:idth(pixels)}]{cmd:)} adds an image/graphic to the page. {it:stgraph} is the name of a Stata graph in memory.
If you didn't assign one yourself, Stata uses {hi:Graph}, and the capitalization matters.
{opt w:idth()} only has an effect when placing graphs from memory {hline 1} images from disk files are not adjusted. The default {opt w:idth()} is 800 pixels.

{phang2}{cmd:log(}{it:command} [{cmd:;} {it:command} ...]{cmd:)} simply logs the results of all included {it:commands}, and then places the log  contents on the page.

{phang2}{opt break} adds a printer page break.

{phang2}{cmd:cbox(}{it:name}{cmd:,} {opt d:isplay(text)} [{opt t:ip(text)} {opt i:check}]{cmd:)} adds a checkbox control. {opt i:check} specifies that the box is initially checked.

{phang2}{cmdab:drop:down(}{it:name}{cmd:,} [{cmd:i}]{opt ch:oice(text)} [...]{cmd:)} adds a dropdown control. Only one of the {opt ch:oice()} options can be {opt ich:oice()}; that one will be initially selected.

{phang2}{cmd:buttons(}{it:name}{cmd:,}  [{cmd:i}]{opt btn(button-def)} [...] [{it:colors}]{cmd:)} adds push-button controls. Only one of the {opt btn()} options can be {opt ibtn()}; that one will be initially selected.
Each {it:button-def} is:

{p 16 20 2}{opt d:isplay(text)} [{opt t:ip(text)}]

{pmore2}{it:colors} is the option:

{p 16 20 2}{opt colors(normal hover chosen)}

{pmore2}where {it:normal}, {it:hover}, and {it:chosen} are each a valid CSS/html color to use for that purpose.


{pstd}{ul:Sub-options}

{phang2}o-{space 2}The {it:text} of {opt d:isplay()} or {opt ch:oice()} is what will be visible on the page.{p_end}
{phang2}o-{space 2}The {it:text} of {opt t:ip()} will show up as a tool-tip when the cursor is over the relevant element.{p_end}

{phang2}o-{space 2}{it:name} is used to uniquely identify {ul:controls} on the page.{p_end}
{phang3}o-{space 2}Each {it:name} should, therefore, be distinct.{p_end}
{phang3}o-{space 2}{it:name} cannot contain spaces.{p_end}
{phang3}o-{space 2}The state of a {ul:control} affects the display when its {it:name} is used in a {opt showif()} option. See {help html##div:html div}{p_end}


{marker write}{title:html write}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html write} [{it:filepath}] [{cmd:,} {opt page(page-id)}]

{pstd}{ul:Description}

{pmore}{cmd:html write} writes a page to disk, and displays it in a browser. {it:page-id} can be omitted when there is only one.

{pmore}When no {it:filepath} is specified, the file {hi:_html.html} is (over)written in the settings directory.


{marker div}{title:html div}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html div top}{p_end}
{phang2}{cmd:html div left}{p_end}
{phang2}{cmd:html div} {it:div-id} [{cmd:,} {opt sh:owif(condition)} {opt p:arent(parent-id)} ]{p_end}

{pstd}{ul:Description}

{pmore}In {bf:html}, a {cmd:<div>} is an abstract container for other things. This command specifies  that subsequent {cmd:html bits} and {cmd:out(html p)} options place their things in the specified {cmd:div}.

{pmore}There are two main reasons to use this command:

{phang2}1){space 2}to place things in a top- or left- 'navigation bar'{p_end}
{phang2}2){space 2}to create a page that responds to user choices


{pmore}{bf:{ul:Navbar:}} To place things in a navbar, execute either {cmd:html div top} or {cmd:html div left}. All subsequent content will then go to the relevant navbar, until another {it:div-id} (or page!) is specified.

{pmore}The page {opt title()}, {opt rev()}, {opt des()}, as well as the {opt toc()} menu are all placed in {cmd:div top} automatically. Anything you add will go below those.

{pmore}The size of the navbars is determined by the size of the stuff you place there; if they get too big, they won't be much like navbars anymore.

{pmore}You should be able to place all content on the main part of the page first, then switch to {cmd:top} and/or {cmd:left}, without the need to switch back to the main part of the page.
However, you can switch back by specifying any new {cmd:html div} {it:div-id}, without specifying {opt parent()}.

{pmore}{bf:{ul:Dynamic content:}} You can achieve a variety of dynamic effects, from the user's perspective, by using the {opt sh:owif(conditions)} option.
For example, you can re-arrange or redefine table rows or columns, change colors or highlighting, expand or collapse things, etc.

{pmore}You accomplish this by generating each arrangement you might like to see, sending versions to separate {cmd:div}s, and specifying alternating {it:conditions} in {opt showif()},
so that when the control changes, one version is swapped for another. When done correctly, the control will appear to modify the display, not hide one thing and show another.

{pmore}Or, of course, you can just specify different things to show.


{pstd}{ul:Options}

{phang2}{opt sh:owif(condition)} checks the values of {ul:controls} (buttons, dropdowns, checkboxes) to determine when its {cmd:div} will be visible.
{it:condition} is any stata logical expression, using {ul:control} {it:names} as variables.

{pmore2}In {it:condition}, a {ul:control} is referred to as:

{p 16 20 2}{cmd:controls.}{it:name}

{pmore2}Values are all strings:
For buttons and dropdown choices, the values are the exact option {it:text}; for checkboxes the values  are either {cmd:yes} or {cmd:no}.

{pmore2}{it:condition} can be a complex expression referring to many controls, eg:

{p 16 16 2}{cmd:showif(controls.year<"2009" & contols.color=="yellow" | controls.override=="yes")}

{phang2}{opt p:arent(parent-id)} is used to create a {cmd:div} inside another {cmd:div}, instead of in the main body of the page. For examle, to show/hide a set of buttons in the navbar,
the buttons would need to go in a {cmd:div} with a {opt showif()} option, which in turn would need to be in the navbar:

{p 16 20 2}{cmd:html div top}{p_end}
{p 16 20 2}{cmd:html bits, checkbox(mastercheck, d(Choose your destiny) iyes)}{p_end}
{p 16 20 2}{cmd:html div forbuttons, showif(mastercheck=="yes") parent(top)}{p_end}
{p 16 20 2}{cmd:html bits, buttons(pickone, btn(d(A)) btn(d(B)) btn(d(C)))}{p_end}


{marker redir}{title:html redirect}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html} {cmdab:redir:ect} {it:page-id}{p_end}

{pstd}{ul:Description}

{pmore}It is possible to compose several pages at the same time, in case some onerous bit of data processing is the basis for more than one report.
To switch the destination from one page to another, use this command.


{marker query}{title:html query}{space 2}{hline}

{pstd}{ul:Syntax}

{phang2}{cmd:html query} [{it:debug}]{p_end}

{pstd}{ul:Description}

{pmore}With no parameter, this command will display most of the css styles defined for the page. You might use this information to re-define a style by using {cmd:html page, styles()},
and specifying one of the defined selectors with your own choice of attributes.

{pmore}With any main parameter, this command will display a summary of the html pages in memory, useful for debugging.


{marker html}{title:htm html}{space 2}{hline}

{pstd}If you installed this from {cmd:ssc}, this command will actually be {cmd:htm}, not {cmd:html}, since the SSC repository already contained a command called {cmd:html}.
You can just read {cmd:htm} wherever you see a reference to {cmd:html}, or you can do {cmd:htm html}, which will overwrite any exising {cmd:html} command you have installed, and make it refer to this command.

{pstd}If you installed from any other source, {cmd:html} and {cmd:htm} will work interchangeably.

