{smcl}
{* *! version 1.0.0  28may2026}{...}
{cmd:help xtcsnardl_graph}{right:also see:  {help xtcsnardl}  {help xtcsnardl_methodology}  {help xtcsnardl_examples}  {help xtcsnardl_postestimation}}
{hline}

{title:Publication-quality CS-NARDL graphs}

{title:Syntax}

{pstd}
Invoked automatically by {cmd:xtcsnardl, graph}.  Can also be called explicitly after
{cmd:xtcsnardl} (advanced):

{p 8 17 2}
{cmd:xtcsnardl_graph}
{cmd:,}
{cmdab:ec(}{it:name}{cmd:)}
{cmdab:ivar(}{it:panelvar}{cmd:)}
{cmdab:asym:vars(}{it:varlist}{cmd:)}
{cmdab:pos:vars(}{it:varlist}{cmd:)}
{cmdab:neg:vars(}{it:varlist}{cmd:)}
[{cmdab:periods(}{it:#}{cmd:)} {cmdab:depvar(}{it:varname}{cmd:)}]


{title:Description}

{pstd}
{cmd:xtcsnardl_graph} produces five publication-quality plots, each saved as a Stata graph
under a stable {cmd:name()} so you can {cmd:graph export}, {cmd:graph combine}, or restyle
them later.

{pstd}
{bf:Author names are deliberately omitted from titles, subtitles and notes} - the plots are
intended to be dropped directly into a paper without further redaction.


{title:Plots produced}

{p2col 5 26 26 2:Plot}Name{p_end}
{p2col 5 26 26 2:{hline 26}}{hline 26}{p_end}
{p2col 5 26 26 2:1. ECT speed of adjustment}{cmd:csn_ect}{p_end}
{p2col 5 26 26 2:2. LR asymmetry (beta+/-)}{cmd:csn_lr_asym}{p_end}
{p2col 5 26 26 2:3. Dynamic multipliers}{cmd:csn_multip_1}, {cmd:csn_multip_2}, ...{p_end}
{p2col 5 26 26 2:4. Asymmetric IRF}{cmd:csn_irf_1}, {cmd:csn_irf_2}, ...{p_end}
{p2col 5 26 26 2:5. CSA loadings}{cmd:csn_csa}{p_end}


{title:Plot 1.  ECT speed of adjustment per panel  (csn_ect)}

{pstd}
Vertical bar chart of {&phi}{sub:i} across panels, coloured by convergence class (strong
< -0.5, moderate, weak, non-convergent).  95% confidence whiskers are added via {cmd:rcap}.
The cross-section mean of {&phi} is overlaid as a dashed reference line.

{p 4 6 2}
{bf:Use for:}  showing heterogeneity in adjustment speed across panels and supporting the
choice of MG vs PMG.

{p 4 6 2}
{bf:Top-journal styling:}  white plot region, dotted gridlines, no chartjunk.  Legend
position 6 (below), single row.


{title:Plot 2.  Long-run asymmetric coefficients  (csn_lr_asym)}

{pstd}
Grouped vertical bar chart of {&beta}{sup:+} and {&beta}{sup:-} for every variable in
{opt asymmetric()}, with 95% CI whiskers.  Variables are labelled on the x-axis.

{p 4 6 2}
{bf:Use for:}  visual evidence of long-run asymmetry.  When the CIs of {&beta}{sup:+} and
{&beta}{sup:-} do not overlap, the asymmetry test (Table 5) rejects symmetry.


{title:Plot 3.  Cumulative dynamic multipliers  (csn_multip_<idx>)}

{pstd}
For each asymmetric variable, plots m{sup:+}(h), m{sup:-}(h), the asymmetry curve
m{sup:+} - m{sup:-} with a 95% confidence band, and the long-run targets {&beta}{sup:+} and
{&beta}{sup:-} as dashed reference lines.

{p 4 6 2}
{bf:Use for:}  showing the {ul:speed} of adjustment to asymmetric long-run targets and any
overshooting.  This is the canonical CS-NARDL figure (see Mehta & Derbeneva 2024 Fig. 3).

{p 4 6 2}
{bf:Reading the asymmetry band:}  if the 95% CI on m{sup:+} - m{sup:-} excludes zero from
some horizon onward, asymmetry is statistically significant at that horizon.


{title:Plot 4.  Asymmetric impulse responses  (csn_irf_<idx>)}

{pstd}
For each asymmetric variable, plots the response of y to a unit positive shock and to a unit
negative shock, with horizontal dashed reference lines at the long-run targets {&beta}{sup:+}
and {&beta}{sup:-}.

{p 4 6 2}
{bf:Use for:}  contrasting the {ul:trajectory} (not just the cumulative effect) of positive
vs negative shocks.


{title:Plot 5.  CSA loadings  (csn_csa)}

{pstd}
Horizontal bar chart of the loadings on each CSA proxy, with 95% CI whiskers.  Variables are
labelled csa({it:varname}), L1.csa({it:varname}), ... .

{p 4 6 2}
{bf:Use for:}  showing that CSA augmentation is "doing work" {hline 2} significant loadings
on CSA confirm the presence of common factors that the augmentation absorbs.

{p 4 6 2}
{bf:If most loadings are insignificant:}  consider reducing {opt cr_lags()} to save degrees
of freedom.


{title:Restyling and exporting}

{pstd}
All graphs use {cmd:name(..., replace)} so subsequent {cmd:xtcsnardl} calls overwrite them.
Export to PDF / EPS / PNG:

{phang2}{cmd:. graph export csn_ect.pdf, name(csn_ect) replace}{p_end}
{phang2}{cmd:. graph export csn_multip_1.png, name(csn_multip_1) width(1200) replace}{p_end}

{pstd}
Combine in a 2x2 panel:

{phang2}{cmd:. graph combine csn_ect csn_lr_asym csn_multip_1 csn_csa, cols(2) ///}{break}
{phang2}{cmd:    title("CS-NARDL diagnostic dashboard") name(csn_combined, replace)}{p_end}

{pstd}
Restyle interactively:

{phang2}{cmd:. graph edit csn_multip_1}{p_end}


{title:Customising the palette}

{pstd}
The default palette is colour-blind safe (Tableau 10).  To restyle for B&W printing, edit the
ado at the {cmd:lcolor()} / {cmd:color()} options.  Example - replace the dynamic-multiplier
colours with greyscale:

{phang2}{cmd:.do c:\ado\plus\x\xtcsnardl_graph.ado}{p_end}

{pstd}
and search/replace:

{p 8 8 2}
{cmd:"31 119 180"} {c -}> {cmd:gs4}    (positive series){break}
{cmd:"214 39 40"}  {c -}> {cmd:gs10}   (negative series){p_end}


{title:Author}

{pstd}
{bf:Dr Merwan Roudane}{break}
{bf:merwanroudane920@gmail.com}{break}
{cmd:xtcsnardl} v1.0.0, 28 May 2026{p_end}


{title:Also see}

{psee}
Online: {help xtcsnardl},  {help xtcsnardl_methodology},  {help xtcsnardl_examples},  {help xtcsnardl_postestimation}{p_end}
{psee}
Stata graphics: {help twoway},  {help graph_combine:graph combine},  {help graph_export:graph export},  {help palettes}{p_end}
