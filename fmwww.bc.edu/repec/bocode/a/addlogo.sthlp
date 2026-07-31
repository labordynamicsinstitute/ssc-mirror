{smcl}
{* *! version 1.0.0  2026-07-18}{...}
{viewerjumpto "Syntax" "addlogo##syntax"}{...}
{viewerjumpto "Description" "addlogo##description"}{...}
{viewerjumpto "Getting started" "addlogo##quickstart"}{...}
{viewerjumpto "Options" "addlogo##options"}{...}
{viewerjumpto "Engines" "addlogo##engines"}{...}
{viewerjumpto "Stored results" "addlogo##results"}{...}
{viewerjumpto "Examples" "addlogo##examples"}{...}
{viewerjumpto "Remarks" "addlogo##remarks"}{...}

{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:addlogo} {hline 2}}Stamp a logo onto a Stata graph{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:addlogo} [{cmd:using} {it:imagefile}]{cmd:,}
{cmdab:l:ogo(}{it:file}{cmd:)}
{cmdab:sav:ing(}{it:file}{cmd:)}
[{it:options}]

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Required}
{synopt :{cmdab:l:ogo(}{it:file}{cmd:)}}logo image; a PNG with transparency is ideal{p_end}
{synopt :{cmdab:sav:ing(}{it:file}{cmd:)}}output file; the format is taken from its extension{p_end}

{syntab :Placement}
{synopt :{cmdab:pos:ition(}{it:anchor}{cmd:)}}{cmd:nw n ne w c e sw s se}; default {cmd:se}{p_end}
{synopt :{cmdab:sc:ale(}{it:#}{cmd:)}}logo width as a fraction of the graph width; default {cmd:.12}{p_end}
{synopt :{cmd:pad(}{it:#}{cmd:)}}margin from the edge as a fraction of graph width; default {cmd:.02}{p_end}
{synopt :{cmdab:op:acity(}{it:#}{cmd:)}}alpha multiplier {cmd:0}-{cmd:1}; default {cmd:1}{p_end}

{syntab :Source graph}
{synopt :{cmdab:w:idth(}{it:#}{cmd:)}}export width in px for the current/named graph; default {cmd:2400}{p_end}
{synopt :{cmdab:n:ame(}{it:name}{cmd:)}}export a specific named graph in memory{p_end}

{syntab :Engine}
{synopt :{cmdab:eng:ine(}{it:e}{cmd:)}}{cmd:auto}, {cmd:python}, or {cmd:magick}; default {cmd:auto}{p_end}
{synopt :{cmdab:py:exec(}{it:path}{cmd:)}}python interpreter that has Pillow{p_end}
{synopt :{cmdab:magick:exec(}{it:path}{cmd:)}}path to the ImageMagick {cmd:magick} binary{p_end}
{synopt :{cmd:replace}}overwrite {cmd:saving()} if it exists{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:addlogo} adds a logo to a Stata graph.  Stata cannot place a raster image
inside the plot region, so {cmd:addlogo} exports the graph and then composites
the logo onto the exported image.  The logo is sized {it:relative to the graph}
(see {cmd:scale()}), so it keeps the same proportions at whatever export
resolution you choose -- which keeps a set of figures looking consistent.

{pstd}
With no {cmd:using}, the current graph (or the one named in {cmd:name()}) is
exported first.  A {cmd:using} ending in {cmd:.gph} is opened and rendered; any
other {cmd:using} is treated as an already-exported image.  Output may be PNG,
TIF, JPG, or PDF; the format is taken from the {cmd:saving()} extension.


{marker quickstart}{...}
{title:Getting started}

{pstd}
The pattern is always the same -- draw a graph, then hand its name, your logo,
and an output file to {cmd:addlogo}:

{p 8 12 2}{it:(draw a graph)} {cmd:..., name(}{it:mygraph}{cmd:, replace)}{p_end}
{p 8 12 2}{cmd:addlogo, logo(}{it:your_logo.png}{cmd:) saving(}{it:out.png}{cmd:) name(}{it:mygraph}{cmd:) replace}{p_end}

{pstd}
A complete, copy-paste example using Stata's own {cmd:auto} data (any PNG will
do for {cmd:logo()}):

{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. scatter price mpg, name(g1, replace)}{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("price_mpg.png") name(g1) replace}{p_end}

{pstd}
That writes {cmd:price_mpg.png} with your logo in the bottom-right corner.  From
there, move it with {cmd:position()}, resize it with {cmd:scale()}, and fade it
to a watermark with {cmd:opacity()}.  See {help addlogo##examples:Examples} for
more.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmdab:l:ogo(}{it:file}{cmd:)} is the logo to stamp.  A PNG with a transparent
background gives the cleanest result; {cmd:opacity()} can fade it further.

{phang}
{cmdab:sav:ing(}{it:file}{cmd:)} is the output file.  Its extension sets the
format ({cmd:.png}, {cmd:.tif}, {cmd:.jpg}, {cmd:.pdf}).  Combine with
{cmd:replace} to overwrite an existing file.

{dlgtab:Placement}

{phang}
{cmdab:pos:ition(}{it:anchor}{cmd:)} chooses one of nine anchors: {cmd:nw n ne}
(top), {cmd:w c e} (middle), {cmd:sw s se} (bottom).  Long forms
({cmd:northwest}, {cmd:top-left}, ...) are also accepted.  The default is
{cmd:se} (bottom-right).

{phang}
{cmdab:sc:ale(}{it:#}{cmd:)} sets the logo width as a fraction of the graph
width.  {cmd:scale(.12)} (the default) makes the logo 12% as wide as the graph.

{phang}
{cmd:pad(}{it:#}{cmd:)} is the margin between the logo and the graph edge, as a
fraction of the graph width (default {cmd:.02}).

{phang}
{cmdab:op:acity(}{it:#}{cmd:)} multiplies the logo's alpha channel; {cmd:1} is
opaque, {cmd:.85} a light watermark.

{dlgtab:Source graph}

{phang}
{cmdab:w:idth(}{it:#}{cmd:)} is the pixel width at which the current or named
graph is exported before compositing (default {cmd:2400}).

{phang}
{cmdab:n:ame(}{it:name}{cmd:)} exports the named graph in memory instead of the
one currently displayed.

{dlgtab:Engine}

{phang}
{cmdab:eng:ine(}{it:e}{cmd:)} selects the compositor: {cmd:magick} (ImageMagick),
{cmd:python} (Python + Pillow), or {cmd:auto} (the default: ImageMagick if its
binary is found, otherwise Python).

{phang}
{cmdab:py:exec(}{it:path}{cmd:)} and {cmdab:magick:exec(}{it:path}{cmd:)} give
the full path to the interpreter / binary.  Alternatively set the globals
{cmd:$ADDLOGO_PY} and {cmd:$ADDLOGO_MAGICK} once in your {help profile}.


{marker engines}{...}
{title:Engines}

{pstd}
{cmd:addlogo} needs one image compositor:

{p 8 12 2}o  {bf:ImageMagick} -- install with {cmd:brew install imagemagick}
(macOS); it is used with no Python at all.{p_end}
{p 8 12 2}o  {bf:Python + Pillow} -- install with {cmd:pip install Pillow}; the
shipped helper {cmd:addlogo_helper.py} does the compositing.{p_end}

{pstd}
On macOS, a Stata launched from the Dock has a minimal {cmd:PATH} that omits
{cmd:/opt/homebrew/bin}.  Set the engine path once in your {help profile}:

{p 8 12 2}{cmd:global ADDLOGO_MAGICK "/opt/homebrew/bin/magick"}{p_end}
{p 8 12 2}{cmd:global ADDLOGO_PY     "/opt/homebrew/bin/python3"}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:addlogo} is {cmd:rclass} and stores in {cmd:r()}:

{synoptset 16 tabbed}{...}
{p2col 5 16 20 2: Macros}{p_end}
{synopt:{cmd:r(file)}}the output file written{p_end}
{synopt:{cmd:r(engine)}}the engine used ({cmd:magick} or {cmd:python}){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Brand the current graph, bottom-right:{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. twoway scatter price mpg, name(g1, replace)}{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("fig1.png") name(g1) replace}{p_end}

{pstd}A light watermark, top-left:{p_end}
{phang2}{cmd:. addlogo, logo("logo.png") saving("fig1.png") position(nw) scale(.18) opacity(.85) replace}{p_end}

{pstd}Stamp a graph you saved earlier as {cmd:.gph}:{p_end}
{phang2}{cmd:. addlogo using "fig.gph", logo("logo.png") saving("fig.png") replace}{p_end}

{pstd}Re-brand an already-exported image:{p_end}
{phang2}{cmd:. addlogo using "old.png", logo("logo.png") saving("old_branded.png") replace}{p_end}

{pstd}Batch-brand every {cmd:.gph} in a folder:{p_end}
{phang2}{cmd:. local files : dir "graphs" files "*.gph"}{p_end}
{phang2}{cmd:. foreach f of local files {c -(}}{p_end}
{phang2}{cmd:.     local stem = substr("`f'", 1, strrpos("`f'", ".") - 1)}{p_end}
{phang2}{cmd:.     addlogo using "graphs/`f'", logo("logo.png") saving("branded/`stem'.png") replace}{p_end}
{phang2}{cmd:. {c )-}}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
For a true {it:vector} logo overlay in LaTeX / Beamer, export the graph as
{cmd:.svg} and inject an {cmd:<image>} tag, or overlay the logo at
{cmd:\includegraphics} time with a TikZ node.  {cmd:saving(fig.pdf)} here gives
a raster-in-PDF, which embeds fine for most uses.


{marker author}{...}
{title:Author}

{pstd}
Eric A. Booth, Sr Researcher, Texas 2036.
Email {browse "mailto:eric.a.booth@gmail.com":eric.a.booth@gmail.com}.
MIT-licensed.  A companion to {help googlechart}, {help googlesheets}, and
{help webapi}.
