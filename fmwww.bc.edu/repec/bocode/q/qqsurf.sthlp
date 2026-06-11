{smcl}
{* *! version 1.1.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqheat" "help qqheat"}{...}
{vieweralsosee "qqsurf3d" "help qqsurf3d"}{...}
{vieweralsosee "qqtable" "help qqtable"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{title:Title}

{p 4 19 2}
{hi:qqsurf} {hline 2}  Pseudo-3D surface plot for QQ results

{title:Syntax}

{p 8 17 2}
{cmd:qqsurf} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 26}{...}
{synopthdr}
{synoptline}
{synopt:{opt v:alue(varname)}}value to plot (default {bf:coef}){p_end}
{synopt:{opt var:iable(name)}}filter by variable name (for mqqr){p_end}
{synopt:{opt col:ormap(name)}}see {help qqheat} (default {cmd:jet}){p_end}
{synopt:{opt l:evels(#)}}color resolution (default 30){p_end}
{synopt:{opt azim:uth(#)}}rotation angle (degrees, default 35){p_end}
{synopt:{opt ele:vation(#)}}elevation angle (degrees, default 25){p_end}
{synopt:{opt t:itle(string)}}plot title{p_end}
{synopt:{opt sa:ve(filename)}}export graph{p_end}
{synopt:{opt name(name)}}graph window name{p_end}
{synopt:{opt replace}}overwrite when saving{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:qqsurf} renders a pseudo-3D surface using oblique projection.  Each grid
cell is drawn as a square marker, coloured by its z-value with the chosen
colormap, then projected onto 2D using the {opt azimuth} and {opt elevation}
angles.{p_end}

{p 4 4 2}
{bf:Limitations:} Stata cannot rotate the resulting graph interactively. For
a richer filled surface with a wireframe, bounding box and colour bar, use
{help qqsurf3d:qqsurf3d}; for true interactive 3D, export the data and plot in
MATLAB / Python / R.{p_end}

{title:Dependencies}

{p 4 4 2}
{bf:None beyond base Stata.}  {cmd:qqsurf} uses only base {help twoway:twoway}
{cmd:scatter} and generates colormaps internally — no {cmd:heatplot},
{cmd:colorpalette}, {cmd:palettes} or other add-on is needed.{p_end}

{title:Example}

{phang2}{cmd:. qqsurf using qq.dta, value(coef) colormap(parula) azim(45) ele(30)}{p_end}

{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr}, {help qqheat}, {help qqsurf3d}, {help qqtable},
{help qqr_package}{p_end}
