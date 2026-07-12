{smcl}
{* *! version 1.0.0  11jul2026}{...}
{viewerjumpto "Syntax" "pididplot##syntax"}{...}
{viewerjumpto "Description" "pididplot##description"}{...}
{viewerjumpto "Options" "pididplot##options"}{...}
{viewerjumpto "Examples" "pididplot##examples"}{...}
{title:Title}

{phang}
{bf:pididplot} {hline 2} Graph the causal impact of a Path-Integrated
Difference-in-Differences (PI-DiD) analysis


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:pididplot} {it:depvar} {ifin} {cmd:,}
{cmd:panelvar(}{it:varname}{cmd:)}
{cmd:timevar(}{it:varname}{cmd:)}
{cmd:treatvar(}{it:varname}{cmd:)}
{cmd:t0(}{it:#}{cmd:)}
[{cmd:t1(}{it:#}{cmd:)} {cmd:t2(}{it:#}{cmd:)}
{cmd:xtitle(}{it:string}{cmd:)} {cmd:title(}{it:string}{cmd:)}
{cmd:subtitle(}{it:string}{cmd:)} {cmd:name(}{it:string}{cmd:)}
{cmd:saving(}{it:filename}{cmd:)} {cmd:scheme(}{it:schemename}{cmd:)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt panelvar(varname)}}unit (id) identifier{p_end}
{synopt:{opt timevar(varname)}}calendar/period variable{p_end}
{synopt:{opt treatvar(varname)}}time-invariant 0/1 treatment-group indicator{p_end}
{synopt:{opt t0(#)}}baseline period (start of the post-treatment window){p_end}

{syntab:Optional}
{synopt:{opt t1(#)}}evaluation horizon (endline); default is the maximum
observed {it:timevar}{p_end}
{synopt:{opt t2(#)}}intermediate rejoining date, marked with a reference
line, if the treated and control paths reconverge before t1{p_end}
{synopt:{opt xtitle}{cmd:(}{it:string}{cmd:)}}shared x-axis title{p_end}
{synopt:{opt title}{cmd:(}{it:string}{cmd:)}}overall graph title{p_end}
{synopt:{opt subtitle}{cmd:(}{it:string}{cmd:)}}overall graph subtitle{p_end}
{synopt:{opt name}{cmd:(}{it:string}{cmd:)}}name of the combined graph, passed to {cmd:graph combine}{p_end}
{synopt:{opt saving}{cmd:(}{it:filename}{cmd:)}}save the combined graph to disk{p_end}
{synopt:{opt scheme}{cmd:(}{it:schemename}{cmd:)}}graph scheme; default {cmd:s2color}{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:pididplot} draws a two-panel figure visualizing the causal impact
estimated by the {help pidid} framework (Salavi, 2026):

{phang2}1. {bf:Top panel} -- the realized treated path c1(t) and the
counterfactual control path c0(t), with the area between them over
[t0, t1] shaded to represent the cumulative causal effect sigma.{p_end}

{phang2}2. {bf:Bottom panel} -- the running (partial-sum) cumulative
effect sigma(t), computed by trapezoidal integration of tau(s) = c1(s) -
c0(s) from t0 up to each t. This panel makes the paper's central point
visible: sigma(t) rises while the paths are separated and then
{bf:plateaus} once tau(t) decays back to zero, even though a static
endline comparison at t1 would report (approximately) zero effect.

{pstd}
A dashed reference line marks the final cumulative value sigma(t1) in the
bottom panel, and the note beneath it reports both the path-integrated
ATT and the conventional static endpoint DiD side by side, so the
divergence between the two is immediately visible.

{pstd}
{cmd:pididplot} does not itself return the numeric estimates in
{cmd:r()}; use {help pidid} for that. Running {cmd:pidid} first (perhaps
with {cmd:notable}) and then {cmd:pididplot} on the same specification is
the recommended workflow.


{marker options}{...}
{title:Options}

{phang}
{opt panelvar(varname)}, {opt timevar(varname)}, {opt treatvar(varname)},
{opt t0(#)}, {opt t1(#)} are defined exactly as in {help pidid}.

{phang}
{opt t2(#)} is purely a graphing aid: it draws an extra vertical
reference line at the rejoining date t2 (must satisfy t0 < t2 <= t1) so
the reader can see where the treated and control paths reconverge.

{phang}
{opt name(string)}, {opt saving(filename)}, {opt scheme(schemename)},
{opt title()}, {opt subtitle()}, {opt xtitle()} are passed through to the
underlying {help graph combine} call.


{marker examples}{...}
{title:Examples}

{phang2}{cmd:. pidid earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) notable}{p_end}
{phang2}{cmd:. pididplot earnings, panelvar(id) timevar(time) treatvar(treat) t0(0) t1(5) t2(5)}{p_end}

{pstd}
See {cmd:example_pidid.do} for a fully worked example that reproduces the
paper's Table 1 and its figure.


{title:Also see}

{psee}
{help pidid}
