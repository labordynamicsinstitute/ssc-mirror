{smcl}
{* *! version 1.1.0  29may2026}{...}
{vieweralsosee "qqr" "help qqr"}{...}
{vieweralsosee "qqsurf" "help qqsurf"}{...}
{vieweralsosee "qqsurf3d" "help qqsurf3d"}{...}
{vieweralsosee "qqtable" "help qqtable"}{...}
{vieweralsosee "qqr package overview" "help qqr_package"}{...}
{vieweralsosee "twoway contour" "help twoway_contour"}{...}
{title:Title}

{p 4 19 2}
{hi:qqheat} {hline 2}  MATLAB-style heatmap/contour for QQ results

{title:Syntax}

{p 8 17 2}
{cmd:qqheat} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 26}{...}
{synopthdr}
{synoptline}
{synopt:{opt v:alue(varname)}}value to plot (default {bf:coef}){p_end}
{synopt:{opt var:iable(name)}}filter by variable (for {help mqqr}){p_end}
{synopt:{opt band(name)}}filter by band (for wavelet results){p_end}
{synopt:{opt col:ormap(name)}}{cmd:jet} | {cmd:parula} | {cmd:viridis} | {cmd:plasma} | {cmd:hot} | {cmd:cool} | {cmd:redblue} (default {cmd:jet}){p_end}
{synopt:{opt l:evels(#)}}number of color steps (default 30){p_end}
{synopt:{opt sig:mark}}overlay markers where {bf:p} < {opt alpha}{p_end}
{synopt:{opt al:pha(#)}}significance threshold for sigmark (default 0.05){p_end}
{synopt:{opt t:itle(string)}}plot title{p_end}
{synopt:{opt sub:title(string)}}plot subtitle{p_end}
{synopt:{opt xt:itle(string)}}x-axis title{p_end}
{synopt:{opt yt:itle(string)}}y-axis title{p_end}
{synopt:{opt zt:itle(string)}}z-axis (color) title{p_end}
{synopt:{opt sa:ve(filename)}}export the graph{p_end}
{synopt:{opt name(name)}}Stata graph window name{p_end}
{synopt:{opt sch:eme(name)}}Stata scheme{p_end}
{synopt:{opt asp:ect(#)}}aspect ratio (default 1){p_end}
{synopt:{opt replace}}overwrite when saving{p_end}
{synoptline}

{title:Description}

{p 4 4 2}
{cmd:qqheat} produces a MATLAB-style heatmap of QQ-regression results using
{help twoway_contour:twoway contour} with continuous colormaps.  Symmetric
diverging maps are auto-centred at zero when the data crosses zero.{p_end}

{title:Available colormaps}

{p 4 8 2}{bf:jet}      — classic MATLAB rainbow (blue → cyan → yellow → red){p_end}
{p 4 8 2}{bf:parula}   — MATLAB's modern default (blue → green → yellow){p_end}
{p 4 8 2}{bf:viridis}  — perceptually uniform (purple → green → yellow){p_end}
{p 4 8 2}{bf:plasma}   — perceptually uniform (purple → red → yellow){p_end}
{p 4 8 2}{bf:hot}      — black → red → yellow → white{p_end}
{p 4 8 2}{bf:cool}     — cyan → magenta{p_end}
{p 4 8 2}{bf:redblue}  — diverging blue-white-red (ColorBrewer RdBu){p_end}
{p 4 8 2}{bf:redgreen} — diverging red-yellow-green (ColorBrewer RdYlGn){p_end}
{p 4 8 2}{bf:redwhitegreen} — diverging red-white-green (clean, no yellow midpoint){p_end}

{title:Dependencies}

{p 4 4 2}
{bf:None beyond base Stata.}  {cmd:qqheat} draws the heatmap with the built-in
{help twoway_contour:twoway contour} (available since Stata 12) and generates
all colormaps internally — you do {bf:not} need {cmd:heatplot},
{cmd:colorpalette}, {cmd:palettes}, {cmd:colrspace}, {cmd:grstyle} or any
other add-on.  The same is true of the 3D commands {help qqsurf:qqsurf} and
{help qqsurf3d:qqsurf3d}, which use only base {cmd:twoway}.  (The single
external dependency in the whole package is {help krls:krls} from SSC, needed
only by {help qqkrls:qqkrls}.){p_end}

{title:Example}

{phang2}{cmd:. qqr sp500 oil, saving(qq.dta) replace}{p_end}
{phang2}{cmd:. qqheat using qq.dta, value(coef) colormap(jet) sigmark}{p_end}
{phang2}{cmd:. qqheat using qq.dta, value(t)    colormap(redblue)}{p_end}

{title:Author}

{p 4 4 2}Merwan Roudane.  {browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{p_end}

{title:See also}

{p 4 8 2}{help qqr}, {help qqsurf}, {help qqsurf3d}, {help qqtable},
{help qqr_package}, {help twoway_contour}{p_end}
