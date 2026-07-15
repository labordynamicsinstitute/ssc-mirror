{smcl}
{* *! version 1.0.0  09jul2026}{...}
{viewerjumpto "Syntax" "chord##syntax"}{...}
{viewerjumpto "Description" "chord##description"}{...}
{viewerjumpto "Data formats" "chord##dataformats"}{...}
{viewerjumpto "Separator rules" "chord##separators"}{...}
{viewerjumpto "Options" "chord##options"}{...}
{viewerjumpto "Common syntax conventions" "chord##conventions"}{...}
{viewerjumpto "Remarks" "chord##remarks"}{...}
{viewerjumpto "Examples" "chord##examples"}{...}
{viewerjumpto "Stored results" "chord##results"}{...}
{viewerjumpto "Authors" "chord##authors"}{...}
{title:Title}

{phang}
{bf:chord} {hline 2} Stata package to draw chord diagrams


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:chord}
{it:fromvar} {it:tovar} [{it:valuevar}]
{ifin}
[{cmd:,} {it:options}]

{p 8 16 2}
{cmd:chord}
{it:rowvar} {it:numvar1} {it:numvar2} [{it:numvar3} ...]
{ifin}
{cmd:,} {opt adjm:atrix} [{it:options}]

{pstd}
In the option table below, {bf:[s]} marks options whose items are
{bf:space-separated} and {bf:[c]} marks options whose items are
{bf:comma-separated}; see {help chord##separators:Separator rules}
for the one-line rule behind this and a quick-reference table with examples.

{synoptset 36 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Data input}
{synopt:{opt adjm:atrix}}interpret the variable list as an adjacency matrix (wide format){p_end}
{synopt:{opt colsec:tors(names)}}{bf:[s]} sector names for the numeric columns in {opt adjmatrix} mode{p_end}

{syntab:Sector layout}
{synopt:{opt sectoror:der(names)}}{bf:[s]} order of sectors around the circle, e.g. {cmd:sectororder(East South North)}{p_end}
{synopt:{opt sectorg:roup(pairs)}}{bf:[s]} assign sectors to groups, e.g. {cmd:sectorgroup(East-G1 South-G1 North-G2)}{p_end}
{synopt:{opt groupg:ap(#)}}gap in degrees between groups; default is 4 x {opt gap()}{p_end}
{synopt:{opt gap(#)}}gap in degrees between adjacent sectors; default is {cmd:gap(3)}{p_end}
{synopt:{opt withingapover:ride(pairs)}}{bf:[s]} per-group within-group gap, e.g. {cmd:withingapoverride(G1-0.5)}{p_end}
{synopt:{opt scale}}give every sector an equal angular span instead of a flow-proportional span{p_end}
{synopt:{opt sectorscaleover:ride(pairs)}}{bf:[s]} multiply the angular span of individual sectors, e.g. {cmd:sectorscaleoverride(East-1.5)}{p_end}
{synopt:{opt startangle(#)}}rotate the whole diagram by # degrees{p_end}
{synopt:{opt splithorizontal}}with exactly two groups, place them top/bottom instead of left/right{p_end}

{syntab:Ribbon ordering and placement}
{synopt:{opt linksort(method)}}ribbon-endpoint ordering: {cmd:circular} (default), {cmd:asis}, {cmd:value}, or {cmd:minimize}{p_end}
{synopt:{opt niter(#)}}refinement iterations for {cmd:linksort(minimize)}; default is {cmd:niter(6)}{p_end}
{synopt:{opt ribbonposition(spec)}}{bf:[c]} pin ribbon endpoints to fixed slots within the whole sector, e.g. {cmd:ribbonposition(East-South: from(1) to(2), North-South: to(1))}{p_end}
{synopt:{opt ribbonzorder(pairs)}}{bf:[s]} draw specific ribbons on top, e.g. {cmd:ribbonzorder(East-South North-West)}; first listed is topmost{p_end}

{syntab:Ribbon appearance}
{synopt:{opt colorlist(colors)}}{bf:[s]} one color per sector, e.g. {cmd:colorlist(navy #FF7F0E 128,0,200)}{p_end}
{synopt:{opt ribbontransparency(#)}}ribbon transparency, 0-100; default is {cmd:ribbontransparency(30)}{p_end}
{synopt:{opt ribboncolorover:ride(spec)}}{bf:[s]} recolor individual ribbons, e.g. {cmd:ribboncoloroverride(East-South-red)}{p_end}
{synopt:{opt bulge(#)}}curvature of ribbons toward the center, 0-1; default is {cmd:bulge(0.85)}{p_end}
{synopt:{opt ribbonbulgeover:ride(spec)}}{bf:[s]} per-ribbon curvature, e.g. {cmd:ribbonbulgeoverride(East-South-0.4)}{p_end}
{synopt:{opt arrow}}draw the "to" end of each ribbon as an arrowhead to show direction{p_end}
{synopt:{opt arrowgap(#)}}radial depth reserved for the arrowheads; default is {cmd:arrowgap(0.05)}{p_end}
{synopt:{opt ribbonborder}}draw an outline around every ribbon{p_end}
{synopt:{opt ribbonborderopts(line_options)}}default outline style; default is {cmd:lwidth(thin) lpattern(solid) lcolor(black)}{p_end}
{synopt:{opt ribbonborderover:ride(spec)}}{bf:[c]} per-ribbon outline, e.g. {cmd:ribbonborderoverride(East-South: lcolor(red), North-West: lpattern(dash))}{p_end}
{synopt:{opt ribbongap(#)}}gap between ribbons and the sector ring{p_end}

{syntab:Sector ring}
{synopt:{opt ringwidth(#)}}radial thickness of the outer sector ring, 0-1; default is {cmd:ringwidth(0.06)}{p_end}
{synopt:{opt ringcolorlist(colors)}}{bf:[s]} one ring color per sector; default is the sector color{p_end}
{synopt:{opt ringtransparency(#)}}ring transparency, 0-100; default is {cmd:ringtransparency(0)}{p_end}
{synopt:{opt interseg}}draw a thin inner "target segment" arc, colored by destination sector, under each ribbon's from-end{p_end}
{synopt:{opt intersegwidth(#)}}radial thickness of the target segments; default is {cmd:intersegwidth(0.01)}{p_end}
{synopt:{opt intersegoutgap(#)}}gap between the ring and the target segments; default is {cmd:intersegoutgap(0.03)}{p_end}
{synopt:{opt intersegingap(#)}}gap between the target segments and the ribbons; default is {cmd:intersegingap(0.01)}{p_end}

{syntab:Sector labels}
{synopt:{opt labelsize(size)}}label size; a number or a {help textsizestyle} keyword; default is {cmd:labelsize(2.2)}{p_end}
{synopt:{opt labeldir(dir)}}label orientation: {cmd:curved} (default), {cmd:curvedwestern}, {cmd:radial}, or {cmd:horizontal}{p_end}
{synopt:{opt labelradius(#)}}radius at which labels are placed; default is {cmd:labelradius(1.12)}{p_end}
{synopt:{opt labelinside}}place labels inside the sector ring instead of outside{p_end}
{synopt:{opt labelcolor(color)}}default label color; default is {cmd:black}{p_end}
{synopt:{opt labelcolorover:ride(pairs)}}{bf:[s]} per-sector label color, e.g. {cmd:labelcoloroverride(East-red)}{p_end}
{synopt:{opt labelsizeover:ride(pairs)}}{bf:[s]} per-sector label size, e.g. {cmd:labelsizeoverride(East-3.2)}{p_end}
{synopt:{opt sectorlabelover:ride(spec)}}{bf:[c]} display-text override, e.g. {cmd:sectorlabeloverride(East-East Region, North-North Region)}{p_end}
{synopt:{opt labelfont(fontname)}}font used for sector labels{p_end}
{synopt:{opt curvechargap(#)}}angular spacing per character in curved labels; default is {cmd:curvechargap(3)}{p_end}
{synopt:{opt narrowcharwidth(#)}}relative width of narrow (Latin) characters in curved labels; default is {cmd:narrowcharwidth(0.55)}{p_end}
{synopt:{opt curvedlabeladjust(#)}}radial fine-tuning of curved labels to compensate upper/lower asymmetry; default is {cmd:curvedlabeladjust(-0.01)}{p_end}

{syntab:Value axis (outer scale)}
{synopt:{opt ticks}}draw a circular value axis with tick marks and numeric labels around each sector{p_end}
{synopt:{opt tickdir(dir)}}direction in which values increase: {cmd:clockwise} (default) or {cmd:counterclockwise}{p_end}
{synopt:{opt tickstep(#)}}distance between major ticks in data units; default is chosen automatically per sector{p_end}
{synopt:{opt tickstepover:ride(pairs)}}{bf:[s]} per-sector major tick step, e.g. {cmd:tickstepoverride(East-25)}{p_end}
{synopt:{opt minorticks(#)}}number of intervals between major ticks; default is {cmd:minorticks(5)}{p_end}
{synopt:{opt minorticksover:ride(pairs)}}{bf:[s]} per-sector number of minor intervals{p_end}
{synopt:{opt ticklen(#)}}major tick length; default is {cmd:ticklen(0.02)}{p_end}
{synopt:{opt minorlen(#)}}minor tick length; default is half of {opt ticklen()}{p_end}
{synopt:{opt tickside(outside|inside)}}side on which minor ticks are drawn; default is {cmd:outside}{p_end}
{synopt:{opt tickgap(#)}}gap between the ring and the axis line; default is {cmd:tickgap(0.01)}{p_end}
{synopt:{opt ticklabgap(#)}}gap between the tick tips and the tick labels; default is {cmd:ticklabgap(0.025)}{p_end}
{synopt:{opt ticklabdir(dir)}}tick-label orientation: {cmd:curved} (default), {cmd:radial}, or {cmd:horizontal}{p_end}
{synopt:{opt ticklabsize(size)}}tick-label size; default is {cmd:ticklabsize(1.4)}{p_end}
{synopt:{opt tickcolor(color)}}default axis/tick color; default is {cmd:gs8}{p_end}
{synopt:{opt ticklabcolor(color)}}default tick-label color; default is {cmd:gs6}{p_end}
{synopt:{opt tickcolorover:ride(pairs)}}{bf:[s]} per-sector axis/tick color{p_end}
{synopt:{opt ticklabcolorover:ride(pairs)}}{bf:[s]} per-sector tick-label color{p_end}
{synopt:{opt ticklabsizeover:ride(pairs)}}{bf:[s]} per-sector tick-label size{p_end}
{synopt:{opt axislwidth(linewidth)}}axis line width; default is {cmd:thin}{p_end}
{synopt:{opt ticklwidth(linewidth)}}major tick line width; default is {cmd:thin}{p_end}
{synopt:{opt minorlwidth(linewidth)}}minor tick line width; default is {cmd:vthin}{p_end}
{synopt:{opt ticklpattern(linepattern)}}line pattern for the whole value axis; default is {cmd:solid}{p_end}
{synopt:{opt ticklabfont(fontname)}}font used for tick labels{p_end}

{syntab:Percentage axis}
{synopt:{opt pctticks}}draw a second axis showing 0-100% of each sector's total flow{p_end}
{synopt:{opt pcttickstep(#)}}major tick step in percentage points; default is {cmd:pcttickstep(20)}{p_end}
{synopt:{opt pctminorticks(#)}}minor intervals between major ticks; see Options for the default rule{p_end}
{synopt:{opt pctaxisgap(#)}}radial gap between the value axis and the percentage axis; default is {cmd:pctaxisgap(0.05)}{p_end}
{synopt:{opt pctticklen(#)}}major tick length; default is {opt ticklen()}{p_end}
{synopt:{opt pctminorlen(#)}}minor tick length; default is half of {opt pctticklen()}{p_end}
{synopt:{opt pctticklabgap(#)}}gap between tick tips and labels; default is {opt ticklabgap()}{p_end}
{synopt:{opt pcttickcolor(color)}}default axis/tick color; default is {opt tickcolor()}{p_end}
{synopt:{opt pctticklabcolor(color)}}default label color; default is {opt ticklabcolor()}{p_end}
{synopt:{opt pctticklabsize(size)}}label size; default is {opt ticklabsize()}{p_end}
{synopt:{opt pcttickcolorover:ride(pairs)}}{bf:[s]} per-sector axis color{p_end}
{synopt:{opt pctticklabcolorover:ride(pairs)}}{bf:[s]} per-sector label color{p_end}
{synopt:{opt pctticklabsizeover:ride(pairs)}}{bf:[s]} per-sector label size{p_end}
{synopt:{opt pctaxislwidth(linewidth)}}axis line width; default is {opt axislwidth()}{p_end}
{synopt:{opt pctticklwidth(linewidth)}}major tick line width; default is {opt ticklwidth()}{p_end}
{synopt:{opt pctminorlwidth(linewidth)}}minor tick line width; default is {opt minorlwidth()}{p_end}
{synopt:{opt pctticklpattern(linepattern)}}line pattern for the whole percentage axis; default is {cmd:solid}{p_end}
{synopt:{opt pctticklabfont(fontname)}}label font; default is {opt ticklabfont()}{p_end}

{syntab:Center-to-center link lines}
{synopt:{opt linkchords(spec)}}{bf:[c]} overlay curved link lines, e.g. {cmd:linkchords(East-South: arrow(double) lcolor(red), North-West)}{p_end}

{syntab:Rendering resolution}
{synopt:{opt nrim(#)}}points per ribbon end arc; default is {cmd:nrim(15)}{p_end}
{synopt:{opt nconn(#)}}points per ribbon side (Bezier) curve; default is {cmd:nconn(20)}{p_end}
{synopt:{opt nring(#)}}points per sector-ring arc; default is {cmd:nring(60)}{p_end}
{synopt:{opt axisarcres(#)}}points per axis arc line; default is {cmd:axisarcres(40)}{p_end}
{synopt:{opt linkres(#)}}points per link curve; default is {cmd:linkres(60)}{p_end}
{synopt:{opt intersegres(#)}}arc resolution of each target segment; default is {cmd:intersegres(15)}{p_end}

{syntab:Titles and overall graph}
{synopt:{opt title(text [, textbox_options])}}overall title; passed to {helpb title_options:twoway title()}{p_end}
{synopt:{opt subtitle(text [, textbox_options])}}subtitle{p_end}
{synopt:{opt note(text [, textbox_options])}}note{p_end}
{synopt:{opt caption(text [, textbox_options])}}caption{p_end}
{synopt:{opt plotmargin(#)}}extra margin around the diagram as a fraction of its radius; default is {cmd:plotmargin(0)}{p_end}
{synopt:{opt name(name)}}name of the graph window{p_end}
{synopt:{opt scheme(schemename)}}graph scheme; also supplies the default sector palette{p_end}
{synopt:{opt graphregion(suboptions)}}passed to twoway {helpb region_options:graphregion()}, e.g. {cmd:graphregion(color(white))}{p_end}
{synopt:{opt plotregion(suboptions)}}passed to twoway {helpb region_options:plotregion()}{p_end}
{synoptline}
{p2colreset}{...}


{marker description}{...}
{title:Description}

{pstd}
{cmd:chord} is a Stata command to draw chord diagrams. A chord diagram represents
directed (or undirected) flows between categories: each category is represented by a
{it:sector} on the circumference of a circle, and each flow is represented by a
{it:ribbon} whose width at each end is proportional to the flow value. The package is 
built based on native Stata graphics (help {helpb twoway scatter}, {helpb twoway line}, {helpb twoway area}, {helpb twoway pcarrow}). The 
functionality is inspired by the R package {bf:circlize}.

{pstd}
The command supports flow-proportional or equal sector spans, sector
grouping, several ribbon-sorting algorithms (including a
crossing-minimization heuristic), directional arrowheads, inner
destination-colored segments, a numeric value axis and a percentage axis
around the circle, curved/radial/horizontal labels with full CJK
(Chinese/Japanese/Korean) support, per-sector and per-ribbon style
overrides, and overlaid center link lines. It can be combined with {helpb graph export},
{helpb graph combine}, schemes, and standard title/textbox options.

{pstd}
The user's dataset is preserved and restored automatically; running
{cmd:chord} does not modify the data in memory.


{marker dataformats}{...}
{title:Data formats}

{pstd}
Two input formats are supported.

{pstd}
{ul:1. Long (edge-list) format} {hline 2} the default.  Supply two or three
variables:

{p 8 12 2}{it:fromvar}  origin category (string or numeric; numeric values are converted to strings){p_end}
{p 8 12 2}{it:tovar}    destination category{p_end}
{p 8 12 2}{it:valuevar} (optional) flow value; if omitted, each observation counts as 1 (frequency weights){p_end}

{pstd}
Multiple observations with the same from/to pair are summed automatically.
Rows with missing values or zero/negative aggregated flows are dropped.
Self-loops (from = to) are allowed and drawn as ribbons that start and end
in the same sector.

{pstd}
{ul:2. Adjacency-matrix (wide) format} {hline 2} specify the {opt adjmatrix}
option.  The first variable must be a string variable holding the row
(origin) category names; every remaining variable must be numeric and
represents one destination category.  By default each numeric variable's own
name is used as the destination sector name, which works directly with
Unicode variable names (Stata 14+ allows Chinese variable names, for
example).  Use {opt colsectors()} when the variable names cannot serve as
display names (spaces, length limits, names starting with digits, etc.).
Missing cells are treated as "no flow" and skipped.


{marker separators}{...}
{title:Separator rules: space-separated vs comma-separated options}

{pstd}
Many options accept a {it:list} of items (one per sector, or one per
ribbon).  There are exactly two flavors, and one simple rule tells you which
is which:

{pstd}
{ul:The rule.}  If each item's value can never contain a space (a color
name, a hex code, a number, a hyphen-free sector name), the items are
{bf:separated by spaces}.  If an item's value may itself contain spaces
(a combination of sub-options like {cmd:lcolor(red) lwidth(thick)}, a
multi-word display text like {cmd:East Region}, or a font name like
{cmd:Times New Roman}), the items are {bf:separated by commas}.

{pstd}
{ul:Quick-reference table.}

{p2colset 6 55 57 2}{...}
{p2col:{bf:Space-separated} {bf:[s]}}{bf:Comma-separated} {bf:[c]}{p_end}
{p2line}
{p2col:{cmd:colsectors()}, {cmd:sectororder()}}{cmd:ribbonposition()}{p_end}
{p2col:{cmd:sectorgroup()}, {cmd:sectorscaleoverride()}}{cmd:ribbonborderoverride()}{p_end}
{p2col:{cmd:withingapoverride()}}{cmd:linkchords()}{p_end}
{p2col:{cmd:tickstepoverride()}, {cmd:minorticksoverride()}}{cmd:sectorlabeloverride()}{p_end}
{p2col:{cmd:labelcoloroverride()}, {cmd:labelsizeoverride()}}{p_end}
{p2col:{cmd:tickcoloroverride()}, {cmd:ticklabcoloroverride()}}{p_end}
{p2col:{cmd:ticklabsizeoverride()}}{p_end}
{p2col:{cmd:ribboncoloroverride()}, {cmd:ribbonbulgeoverride()}}{p_end}
{p2col:{cmd:ribbonzorder()}}{p_end}
{p2col:{cmd:colorlist()}, {cmd:ringcolorlist()}}{p_end}
{p2col:{cmd:pcttickcoloroverride()}, {cmd:pctticklabcoloroverride()}}{p_end}
{p2col:{cmd:pctticklabsizeoverride()}}{p_end}
{p2line}
{p2colreset}{...}

{pstd}
{ul:One example of each flavor side by side:}

{p 8 12 2}space-separated (each item is one "word"):{p_end}
{p 12 12 2}{cmd:ribboncoloroverride(East-South-red North-West-#1F77B4)}{p_end}
{p 8 12 2}comma-separated (each item may contain spaces):{p_end}
{p 12 12 2}{cmd:ribbonborderoverride(East-South: lcolor(red) lwidth(medthick), North-West: lpattern(dash))}{p_end}

{pstd}
In color lists, RGB triples would break the space rule ({cmd:128 0 200} is
three words), so write them in the compact comma form {cmd:128,0,200}
(one word) instead.

{pstd}
{ul:Safety net.}  If {cmd:chord} detects a comma inside a
space-separated option, it prints a bilingual note reminding you that the
option uses spaces, so accidental commas are flagged rather than silently
misparsed.


{marker options}{...}
{title:Options}

{dlgtab:Data input}

{phang}
{opt adjmatrix} declares that the variable list is a wide adjacency matrix
rather than a from/to/value edge list; see {it:Data formats} above.  At
least one row variable plus two numeric columns are required.

{phang}
{opt colsectors(names)} supplies, in order, one sector name per numeric
column in {opt adjmatrix} mode (space-separated).  The number of names must
equal the number of numeric columns.  If omitted, the variable names
themselves are used.

{dlgtab:Sector layout}

{phang}
{opt sectororder(names)} fixes the order of sectors around the circle
(space-separated), e.g. {cmd:sectororder(East South North Southwest Northeast)}.
Sectors are laid out in the listed order, proceeding clockwise from
the 12 o'clock position.  The list must contain exactly the set of
categories that occur in the data, each exactly once; otherwise an error is
issued that also displays the categories actually found.  If omitted,
sectors appear in order of first appearance in the data (from-values first,
then to-values).

{phang}
{opt sectorgroup(pairs)} assigns sectors to named groups using
space-separated {it:sector-group} pairs, for example
{cmd:sectorgroup(East-Coastal South-Coastal North-Inland)}.  Sectors of the
same group are rearranged to be contiguous on the circle.  Sectors not
mentioned form their own single-member groups.  When the result is exactly
two groups, the diagram is automatically rotated so that the two group
centers sit exactly left and right (or top and bottom with
{opt splithorizontal}); a note is displayed when this happens, and
{opt startangle()} can still be used for fine adjustment.

{phang}
{opt groupgap(#)} sets the gap in degrees inserted between different groups.
The default is 4 times {opt gap()}.

{phang}
{opt gap(#)} sets the gap in degrees between adjacent sectors (within a
group, or everywhere when no groups are defined).  Default is 3.

{phang}
{opt withingapoverride(pairs)} overrides the within-group gap for particular
groups using space-separated {it:group-#} pairs, e.g.
{cmd:withingapoverride(Coastal-0.5)}.

{phang}
{opt scale} makes all sectors span the same angle regardless of their total
flow, mimicking {cmd:scale = TRUE} in circlize.  Without it, each sector's
span is proportional to its total (incoming + outgoing) flow.

{phang}
{opt sectorscaleoverride(pairs)} multiplies the angular weight of individual
sectors by a positive factor, using space-separated {it:sector-#} pairs;
e.g. {cmd:sectorscaleoverride(East-1.5 North-0.8)} enlarges East by 50% and
shrinks North by 20%.  It can be combined with or without {opt scale}.

{phang}
{opt startangle(#)} rotates the whole diagram.  The first sector starts at
the 12 o'clock position and # rotates it by # degrees.

{phang}
{opt splithorizontal} only takes effect when {opt sectorgroup()} yields
exactly two groups; the two groups are then centered at the top and bottom
of the circle instead of left and right.

{dlgtab:Ribbon ordering and placement}

{phang}
{opt linksort(method)} chooses how ribbon endpoints are stacked within each
sector:

{phang2}{cmd:circular} (default) sorts by circular distance between origin
and destination sectors, which usually produces a tidy, circlize-like
layout.{p_end}
{phang2}{cmd:asis} keeps the original data order.{p_end}
{phang2}{cmd:value} sorts by descending flow value.{p_end}
{phang2}{cmd:minimize} starts from the circular layout and iteratively
reorders endpoints to reduce the number of ribbon crossings.  The command
reports the crossing counts of the seed layout and the refined layout and
automatically keeps whichever is better.{p_end}

{phang}
{opt niter(#)} sets the number of refinement iterations used by
{cmd:linksort(minimize)}; default is 6.

{phang}
{opt ribbonposition(spec)} pins the endpoint of specific ribbons to a fixed
physical slot within a sector's {bf:whole} arc.  Within each sector, all
ribbon endpoints that touch it (both from-ends and to-ends) share one
sequence of slots numbered 1, 2, ..., {it:m}, where {it:m} is the total
number of ribbons touching that sector; slot 1 is the first position in the
stacking direction.  The specification is a {bf:comma-separated} list of
{cmd:{it:A}-{it:B}: from({it:#}) to({it:#})} items — the comma goes
{bf:between} items, i.e. after one ribbon's sub-options and before the next
{it:A-B} pair:

{p 12 12 2}{cmd:ribbonposition(East-South: from(1) to(2), North-South: to(1))}{p_end}

{pmore}
Here {it:A-B} identifies a directed ribbon (from {it:A} to {it:B}),
{cmd:from(#)} pins its endpoint within sector {it:A}'s arc, and
{cmd:to(#)} pins its endpoint within sector {it:B}'s arc.  Either
suboption may be given alone.  Because from- and to-endpoints share the
same slot numbering inside a sector, an endpoint can be pinned anywhere in
the sector, not just inside its own from- or to-block — and two pins in
the same sector may not claim the same slot.  Unpinned endpoints fill the
remaining slots in their natural order.  Out-of-range or duplicated slots
are reported as errors.

{phang}
{opt ribbonzorder(pairs)} raises specific directed ribbons above all
others, using space-separated {it:A-B} pairs:

{p 12 12 2}{cmd:ribbonzorder(East-South North-West)}{p_end}

{pmore}
Ribbons are drawn bottom-up: unlisted ribbons first, then the listed pairs
so that the {it:first} listed pair ends up on top (in the example,
East-South is topmost, North-West second).  Each pair must match an
existing directed edge (direction matters) and may not be repeated.

{dlgtab:Ribbon appearance}

{phang}
{opt colorlist(colors)} supplies one color per sector, space-separated, in
sector order, e.g. {cmd:colorlist(navy #FF7F0E 128,0,200 green%60)}.
Ribbons take the color of their origin sector and are drawn
semi-transparent by default; append {cmd:%}{it:alpha} to a color to set an
individual item's opacity.  Any color may use the extended color syntax
described under {it:Common syntax conventions} below.  If fewer colors than
sectors are given, the remaining sectors fall back to the default palette:
the scheme palette when {opt scheme()} is specified, otherwise evenly
spaced HSV hues.

{phang}
{opt ribbontransparency(#)} sets the global ribbon transparency (0 = opaque,
100 = invisible).  Default is 30.  A per-color {cmd:%alpha} suffix in
{opt colorlist()} or {opt ribboncoloroverride()} takes precedence for that
item.

{phang}
{opt ribboncoloroverride(spec)} recolors individual directed ribbons with
space-separated {it:A-B-color} triples, e.g.
{cmd:ribboncoloroverride(East-South-red East-North-#1F77B4%60)}.  Direction
matters.

{phang}
{opt bulge(#)} controls how strongly ribbon sides bend toward the center
(0 = straight chords, 1 = pulled fully to the center).  Default is 0.85.

{phang}
{opt ribbonbulgeoverride(spec)} sets the curvature of individual directed
ribbons with space-separated {it:A-B-#} triples (# between 0 and 1), e.g.
{cmd:ribbonbulgeoverride(East-South-0.4 North-West-1)}.  Unlisted ribbons
keep the global {opt bulge()}.

{phang}
{opt arrow} replaces the smooth arc at each ribbon's "to" end with a
triangular arrowhead pointing at the destination sector, making flow
direction visible.  {opt arrowgap(#)} reserves the radial depth of the
arrowheads (default 0.05) and slightly shrinks the ring accordingly.

{phang}
{opt ribbonborder} outlines every ribbon using {opt ribbonborderopts()}
(default {cmd:lwidth(thin) lpattern(solid) lcolor(black)}).

{phang}
{opt ribbonborderoverride(spec)} restyles the outlines of individual
ribbons and also works {it:without} {opt ribbonborder} (only the listed
ribbons then get outlines).  It is a {bf:comma-separated} list of
{cmd:{it:A}-{it:B}: {it:line_options}} items — the comma sits between one
ribbon's options and the next pair:

{p 12 12 2}{cmd:ribbonborderoverride(East-South: lcolor(red) lwidth(medthick), North-West: lpattern(dash))}{p_end}

{phang}
{opt ribbongap(#)} sets the gap between the ribbons and the inner edge of
the sector ring (or, with {opt interseg}, between the ribbons and the
target segments).  When omitted, a sensible default is used (0.04 without
{opt interseg}).

{dlgtab:Sector ring}

{phang}
{opt ringwidth(#)} sets the radial thickness of the outer sector arcs,
strictly between 0 and 1 (fraction of the unit radius).  Default is 0.06.

{phang}
{opt ringcolorlist(colors)} (space-separated, one per sector) styles the
ring independently of the ribbons; by default the ring reuses the sector
colors.

{phang}
{opt interseg} adds, just inside the ring, a thin arc under each ribbon's
from-end colored by the {it:destination} sector (using the destination's
ring color), so that a sector's outgoing composition can be read at a
glance {hline 2} similar to the "diffHeight + target track" style of
circlize.  {opt intersegwidth()}, {opt intersegoutgap()},
{opt intersegingap()}, and {opt intersegres()} control its thickness,
outer gap, inner gap, and arc resolution.

{dlgtab:Sector labels}

{phang}
{opt labelsize(size)} accepts a number (in Stata text-size units) or one of
{cmd:tiny}, {cmd:vsmall}, {cmd:small}, {cmd:medsmall}, {cmd:medium},
{cmd:medlarge}, {cmd:large}, {cmd:vlarge}, {cmd:huge}.  Default is 2.2.

{phang}
{opt labeldir(dir)} chooses the label orientation:

{phang2}{cmd:curved} (default) bends the label along the circle.  Wide
(CJK/full-width) characters are placed one by one; runs of narrow
(Latin/digit) characters are kept together as one segment and rendered
natively, so Western text keeps natural letter spacing.{p_end}
{phang2}{cmd:curvedwestern} is like {cmd:curved} but also places narrow
(Western) characters one by one along the arc, so long Latin labels hug the
circle more tightly.{p_end}
{phang2}{cmd:radial} points the label along the radius.{p_end}
{phang2}{cmd:horizontal} keeps the label upright.{p_end}

{pmore}
In {cmd:curved} and {cmd:radial} modes, labels on the appropriate half of
the circle are flipped automatically so that text never appears upside
down.

{phang}
{opt labelradius(#)} places labels at radius # (default 1.12, i.e. just
outside the ring).  {opt labelinside} instead centers labels within the
ring itself; a note suggests enlarging {opt ringwidth()} if the ring is
thin.  With {opt labelinside}, Western segments are automatically switched
to per-character curved placement (as in {cmd:labeldir(curvedwestern)}) so
they follow the narrow arc band; a note is displayed when this happens.

{phang}
{opt curvechargap(#)} is the angular spacing per (wide) character in curved
labels, in degrees; default is 3.  {opt narrowcharwidth(#)} (default 0.55)
is the assumed width of a narrow character relative to a wide one when
allocating arc length.  {opt curvedlabeladjust(#)} (default -0.01) is a
small radial offset that compensates the slight vertical asymmetry of
curved labels between the upper and lower halves of the circle; set it to 0
to disable.

{phang}
{opt labelfont(fontname)} sets the label font.  Inline
{cmd:{c -(}fontface "{it:name}":...{c )-}} tags inside sector display texts
are also honored, including in curved mode, where each character keeps the
font of its enclosing tag.

{phang}
{opt sectorlabeloverride(spec)} replaces the displayed text of individual
sectors without affecting matching elsewhere.  It is a {bf:comma-separated}
list of {it:sector-text} items (the text may contain spaces):

{p 12 12 2}{cmd:sectorlabeloverride(East-East Region, North-North Region)}{p_end}

{pmore}
To render a replacement text in a specific font, embed a
{cmd:{c -(}fontface "{it:name}":...{c )-}} tag in the text part; font names
with spaces are fine because this option is comma-separated:

{p 12 12 2}{cmd:sectorlabeloverride(East-{c -(}fontface "Times New Roman":East Region{c )-}, North-North Region)}{p_end}

{pmore}
All other options ({opt sectorgroup()}, the various overrides, the data
itself) keep referring to the original sector name.

{phang}
{opt labelcolor(color)} sets the default label color;
{opt labelcoloroverride(pairs)} and {opt labelsizeoverride(pairs)} adjust
individual sectors with space-separated {it:sector-value} pairs, e.g.
{cmd:labelcoloroverride(East-red)} and {cmd:labelsizeoverride(East-3.2)}.
Precedence follows the common rules described below.

{dlgtab:Value axis (ticks)}

{phang}
{opt ticks} draws, outside each sector, a continuous arc-shaped axis with
major ticks (numbered in data units, starting at 0) and unnumbered minor
ticks.  Values increase in the {opt tickdir()} direction along each
sector.

{phang}
When {opt tickstep()} is not given, the major step for each sector is
chosen automatically as a "nice" number (1, 2, or 5 times a power of 10)
that yields roughly five major intervals over the sector's total flow.
{opt tickstepoverride()} and {opt minorticksoverride()} adjust individual
sectors via space-separated {it:sector-#} pairs, e.g.
{cmd:tickstepoverride(East-25)} and {cmd:minorticksoverride(East-2)}.

{phang}
{opt tickside(outside|inside)} determines whether minor ticks protrude
outward or inward from the axis line.  Major ticks always point outward,
and tick labels always sit outside the major tick tips at distance
{opt ticklabgap()}.

{phang}
{opt ticklpattern(linepattern)} sets a global line pattern (e.g.
{cmd:dash}, {cmd:dot}) for the whole value axis: main arc, major ticks, and
minor ticks; default is {cmd:solid}.

{phang}
The color/size options ({opt tickcolor()}, {opt ticklabcolor()},
{opt ticklabsize()}, and their per-sector {cmd:...override()} variants)
follow the common precedence rules described below.

{dlgtab:Percentage axis (pctticks)}

{phang}
{opt pctticks} draws a second axis on which every sector runs from 0% to
100% of its own total flow, regardless of absolute size.  It can be used
alone (it then occupies the position of the value axis) or together with
{opt ticks} (it is then placed {opt pctaxisgap()} outside the value-axis
labels).  All styling defaults fall back to the corresponding value-axis
settings unless overridden by the {cmd:pct...} options; a distinct line
pattern via {opt pctticklpattern()} (e.g. {cmd:dot}) is handy for visually
distinguishing the two axes.

{phang}
Default minor-tick rule: when {opt ticks} and {opt pctticks} are both on,
the percentage axis draws no minor ticks (to reduce clutter); when only
{opt pctticks} is on, it inherits {opt minorticks()}.  Override with
{opt pctminorticks(#)}.

{phang}
The {cmd:pct...override()} options are space-separated {it:sector-value}
pairs — exactly the same syntax as their value-axis counterparts.

{dlgtab:Center-to-center link lines}

{phang}
{opt linkchords(spec)} overlays curved lines connecting the midpoints of a
ribbon's two ends, optionally with arrowheads {hline 2} useful for calling
out specific flows on a busy diagram.  The specification is a
{bf:comma-separated} list of {cmd:{it:A}-{it:B}} pairs, each optionally
followed by {cmd::} and per-link suboptions; the comma sits between one
link's suboptions and the next pair:

{p 12 12 2}{cmd:linkchords(East-South: arrow(double) lcolor(red) lwidth(medthick) bulge(0.6), Southwest-Northeast: arrow(none) lpattern(dash), North-West)}{p_end}

{pmore}
Recognized per-link suboptions:

{phang2}{cmd:arrow(single|double|none)} arrowhead style for this link:
one arrowhead at the destination end, arrowheads at both ends, or a plain
line; default is {cmd:single};{p_end}
{phang2}{cmd:lcolor({it:color})} line and arrowhead color; default is
{cmd:black};{p_end}
{phang2}{cmd:lwidth({it:linewidth})} line width; default is
{cmd:thin};{p_end}
{phang2}{cmd:lpattern({it:linepattern})} line pattern (e.g. {cmd:solid},
{cmd:dash}, {cmd:dot}); default is {cmd:solid};{p_end}
{phang2}{cmd:msize({it:marker_size})} arrowhead size; default is
{cmd:1pt};{p_end}
{phang2}{cmd:mangle({it:#})} arrowhead angle, passed to
{helpb twoway pcarrow}; default is the scheme default;{p_end}
{phang2}{cmd:barbsize({it:#})} arrowhead barb size, passed to
{helpb twoway pcarrow}; default is the scheme default;{p_end}
{phang2}{cmd:radiusfrom({it:#})} and {cmd:radiusto({it:#})} radii at which
this link starts and ends (both must be positive); default is the ribbon
rim radius at each end;{p_end}
{phang2}{cmd:bulge({it:#})} curvature of this link, 0-1 (0 = straight
chord, 1 = pulled fully to the center); default is the value of
{opt bulge()};{p_end}
{phang2}{cmd:res({it:#})} number of points used to draw this link's curve
(>= 2); default is {opt linkres()};{p_end}
{phang2}any remaining text is appended verbatim to the underlying
{helpb twoway line} call.{p_end}

{dlgtab:Rendering resolution}

{phang}
{opt nrim(#)} sets the number of points used to approximate each ribbon's
end arc; default is 15.

{phang}
{opt nconn(#)} sets the number of points per ribbon side (Bezier) curve;
default is 20.

{phang}
{opt nring(#)} sets the number of points per sector-ring arc; default
is 60.

{phang}
{opt axisarcres(#)} sets the number of points used to draw each sector's
continuous axis arc line (the value axis and the percentage axis both use
it); default is 40.

{phang}
{opt linkres(#)} sets the default number of points per {opt linkchords()}
curve; default is 60.  Individual links can override it with the per-link
{cmd:res()} suboption.

{pstd}
The defaults render smoothly at ordinary sizes; increase these values for
large-format export, decrease them to speed up drawing of very dense
diagrams.  {opt intersegres(#)} (documented under {it:Sector ring}) plays
the same role for the inner target segments.


{marker conventions}{...}
{title:Common syntax conventions}

{pstd}
{ul:Colors.}  Wherever a color is expected, you may use:

{p 8 12 2}- any Stata {help colorstyle} name, e.g. {cmd:navy};{p_end}
{p 8 12 2}- an RGB triple in the compact comma form {cmd:128,0,200} (required inside space-separated lists, where the spaced form {cmd:"128 0 200"} would split into three items);{p_end}
{p 8 12 2}- a hex code, {cmd:#RRGGBB} or {cmd:#RGB}, e.g. {cmd:#1F77B4};{p_end}
{p 8 12 2}- any of the above followed by {cmd:%}{it:alpha} (0-100 opacity), e.g. {cmd:#E24A33%60}, which sets that item's opacity.  Color opacity requires Stata 15 or newer.{p_end}

{pstd}
{ul:Pair lists.}  Space-separated pair options expect items of the form
{it:name-value} (or {it:name1-name2-value} for per-ribbon items), where
{it:name} is a sector name exactly as it appears in the data.  Because
{cmd:-} is the separator, sector names containing hyphens cannot be
addressed by these options; rename such categories first (or use
{opt sectorlabeloverride()} to display a hyphenated label while keeping a
hyphen-free internal name).

{pstd}
{ul:Comma-separated options.}  In {opt ribbonposition()},
{opt ribbonborderoverride()}, {opt linkchords()}, and
{opt sectorlabeloverride()}, the comma separates whole items ({it:pair +}
its sub-options/text).  See
{help chord##separators:Separator rules} above.

{pstd}
{ul:Style precedence.}  For any styled element (sector labels, ticks, tick
labels, percentage-axis items), the effective style of sector {it:i} is
resolved as: {cmd:...override()} entry for that sector, if any; otherwise
the global option (e.g. {opt labelcolor()}, {opt tickcolor()}); otherwise
the built-in default.


{marker remarks}{...}
{title:Remarks and notes}

{pstd}
1. {ul:Stata version and fonts.}  {cmd:chord} requires Stata 14.0
or newer; the {cmd:%alpha} opacity suffix in colors additionally requires
Stata 15.  For CJK labels, make sure the graph font (or {opt labelfont()})
covers the required glyphs.

{pstd}
2. {ul:Data are never modified.}  The command runs under
{cmd:preserve}/{cmd:restore}; your dataset is intact afterward.  Results of
interest are returned in {cmd:r()}.

{pstd}
3. {ul:Direction and self-loops.}  Ribbons are directed (from origin to
destination).  Use {opt arrow} to visualize direction.  Self-loops are
drawn within their own sector.

{pstd}
4. {ul:Angles vs. radii.}  {opt gap()}, {opt groupgap()},
{opt startangle()}, and {opt curvechargap()} are in degrees; radii and
radial gaps ({opt ringwidth()}, {opt ticklen()}, {opt ribbongap()},
{opt labelradius()}, etc.) are fractions of the unit circle radius.

{pstd}
5. {ul:Too many categories.}  If the total of all gaps reaches 360 degrees
the command exits with an error; reduce {opt gap()}/{opt groupgap()} or the
number of categories.

{pstd}
6. {ul:Legibility of dense axes.}  With {opt ticks}, sectors with very
large totals may receive many major ticks; use {opt tickstep()} or
{opt tickstepoverride()} to thin them.

{pstd}
7. {ul:Quoting.}  Sector names in the pair-list options should be written
without quotes; stray quotes and backticks are stripped defensively, but it
is best not to include them.  If a comma is detected inside a
space-separated option, a warning note is printed.

{pstd}
8. {ul:Exporting.}  For publication-quality output, export with
{helpb graph export} to PDF/SVG/PNG at the desired size; consider raising
{opt nconn()}/{opt nring()} for very large formats.


{marker examples}{...}
{title:Examples}

{pstd}Setup: a 5-region flow dataset (long format){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str10 from str10 to value}{p_end}
{phang2}{cmd:  "South" "East" 19}{p_end}
{phang2}{cmd:  "North" "East" 18}{p_end}
{phang2}{cmd:  "Southwest" "East" 7}{p_end}
{phang2}{cmd:  "Northeast" "East" 46}{p_end}
{phang2}{cmd:  "East" "South" 47}{p_end}
{phang2}{cmd:  "North" "South" 18}{p_end}
{phang2}{cmd:  "Southwest" "South" 29}{p_end}
{phang2}{cmd:  "Northeast" "South" 30}{p_end}
{phang2}{cmd:  "East" "North" 31}{p_end}
{phang2}{cmd:  "South" "North" 9}{p_end}
{phang2}{cmd:  "Southwest" "North" 32}{p_end}
{phang2}{cmd:  "Northeast" "North" 13}{p_end}
{phang2}{cmd:  "East" "Southwest" 33}{p_end}
{phang2}{cmd:  "South" "Southwest" 39}{p_end}
{phang2}{cmd:  "North" "Southwest" 12}{p_end}
{phang2}{cmd:  "Northeast" "Southwest" 11}{p_end}
{phang2}{cmd:  "East" "Northeast" 46}{p_end}
{phang2}{cmd:  "South" "Northeast" 13}{p_end}
{phang2}{cmd:  "North" "Northeast" 23}{p_end}
{phang2}{cmd:  "Southwest" "Northeast" 40}{p_end}
{phang2}{cmd:  "North" "North" 15}{p_end}
{phang2}{cmd:  "Southwest" "Southwest" 30}{p_end}
{phang2}{cmd:  end}{p_end}

{pstd}Basic chord diagram{p_end}
{phang2}{cmd:. chord from to value}{p_end}

{pstd}Directional arrows, custom colors, and a value axis{p_end}
{phang2}{cmd:. chord from to value, arrow ticks colorlist(#1F77B4 #FF7F0E #2CA02C #D62728 #9467BD) graphregion(color(white))}{p_end}

{pstd}Fixed sector order (clockwise from 12 o'clock), larger gaps, rotated start{p_end}
{phang2}{cmd:. chord from to value, sectororder(East South North Southwest Northeast) gap(5) startangle(15)}{p_end}

{pstd}Two groups, auto-centered left/right, group gap widened{p_end}
{phang2}{cmd:. chord from to value, sectorgroup(East-Coastal South-Coastal Northeast-Inland North-Inland Southwest-Inland) groupgap(15)}{p_end}

{pstd}Crossing minimization{p_end}
{phang2}{cmd:. chord from to value, linksort(minimize)}{p_end}

{pstd}Per-ribbon curvature and outline (note: one space-separated, one comma-separated){p_end}
{phang2}{cmd:. chord from to value, ribbonbulgeoverride(East-South-0.4) ribbonborderoverride(East-South: lcolor(red) lwidth(medthick))}{p_end}

{pstd}Inner destination segments with a value axis{p_end}
{phang2}{cmd:. chord from to value, arrow interseg ticks}{p_end}

{pstd}Value axis plus dotted percentage axis{p_end}
{phang2}{cmd:. chord from to value, ticks pctticks pctticklpattern(dot) pcttickstep(25) labelradius(1.25) gap(6)}{p_end}

{pstd}Overlay a double-headed link line on one pair and put that ribbon on top{p_end}
{phang2}{cmd:. chord from to value, linkchords(East-South: arrow(single) lcolor(red) lwidth(medthick)) ribbonzorder(East-South)}{p_end}

{pstd}Titles with textbox options and display-name overrides{p_end}
{phang2}{cmd:. chord from to value, title("Regional trade flows", size(large) color(navy)) note("Source: simulated data") sectorlabeloverride(East-East Region, North-North Region) arrow}{p_end}

{pstd}Adjacency-matrix (wide) input{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str10 region double South double East double North double Southwest double Northeast}{p_end}
{phang2}{cmd:  "South"      0  19   9  39  13}{p_end}
{phang2}{cmd:  "East"      47   0  31  33  46}{p_end}
{phang2}{cmd:  "North"     18  18  15  12  23}{p_end}
{phang2}{cmd:  "Southwest" 29   7  32  30  40}{p_end}
{phang2}{cmd:  "Northeast" 30  46  13  11   0}{p_end}
{phang2}{cmd:  end}{p_end}
{phang2}{cmd:. chord region South East North Southwest Northeast, adjmatrix arrow}{p_end}

{pstd}Chinese labels (Stata 14+ Unicode variable names work directly){p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. input str10 区域 double 华南 double 华东 double 华北 double 西南 double 东北}{p_end}
{phang2}{cmd:  "华南"  0  19  9  39 13}{p_end}
{phang2}{cmd:  "华东" 47   0 31  33 46}{p_end}
{phang2}{cmd:  "华北" 18  18 15  12 23}{p_end}
{phang2}{cmd:  "西南" 29   7 32  30 40}{p_end}
{phang2}{cmd:  "东北" 30  46 13  11  0}{p_end}
{phang2}{cmd:  end}{p_end}
{phang2}{cmd:. chord 区域 华南 华东 华北 西南 东北, adjmatrix labeldir(curved) labelfont(SimSun) //宋体}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:chord} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(sector_count)}}number of sectors drawn{p_end}
{synopt:{cmd:r(edge_count)}}number of aggregated edges (ribbons){p_end}
{synopt:{cmd:r(total_flow)}}sum of all flow values{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(sectors)}}sector names in the order drawn{p_end}
{p2colreset}{...}


{marker authors}{...}
{title:Authors}

{pstd}
Jiajun Zhou (周家俊){break}
Technical University of Munich (TUM){break}
zhoujiajun_06@163.com

{pstd}
De Zhou (周德){break}
Nanjing Agricultural University{break}
zhou-de@hotmail.com

{pstd}
The design of {cmd:chord} is inspired by the R package
{bf:circlize} (Gu et al., 2014, {it:Bioinformatics} 30:2811-2812).
Bug reports and feature requests are welcome by email or on the project's GitHub repository issues.{p_end}