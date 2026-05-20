{smcl}
{* *! version 1.0.0  18may2026}{...}
{cmd:help multicoint_graph}{right: (part of {bf:multicoint})}
{hline}

{title:Title}

{phang}
{bf:multicoint_graph} {hline 2} Diagnostic graphs after {helpb multicoint}

{title:Package}

{p 4 6 2}
This command is part of the {helpb multicoint} library
({help multicoint##syntax:main}, {helpb multicoint_sim},
{helpb multicoint_cv}).

{title:Syntax}

{p 8 14 2}
{cmd:multicoint_graph} [{cmd:,} {it:options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt onepanel}}only the residual u_t panel{p_end}
{synopt :{opt twopanel}}flows + cumulated series{p_end}
{synopt :{opt fourpanel}}default (flows, cumulated, S_t, u_t){p_end}
{synopt :{opt sixpanel}}adds Y vs X scatter and u_t histogram{p_end}
{synopt :{opt sch:eme(name)}}override scheme (default {bf:s2color}){p_end}
{synopt :{opt name(name)}}name for combined graph (default {bf:mc_diag}){p_end}
{synopt :{opt ti:tle(string)}}override title{p_end}
{synopt :{opt note(string)}}override note{p_end}
{synopt :{opt save(filename)}}export combined graph to file{p_end}
{synoptline}

{title:Description}

{pstd}
{cmd:multicoint_graph} produces a tiled diagnostic plot summarising the
output of the most recent {helpb multicoint} estimation.  Panels (in order):

{phang2}1.  Flow series y_t and x_t over time.{p_end}
{phang2}2.  Cumulated I(2) series Y_t and X_t.{p_end}
{phang2}3.  Cumulated equilibrium error S_t = Σ Z_s (Granger-Lee stage 1).{p_end}
{phang2}4.  Multicoint regression residual u_t.{p_end}
{phang2}5.  Long-run scatter Y vs X with linear fit (six-panel only).{p_end}
{phang2}6.  Histogram of u_t with N(0,σ²) overlay (six-panel only).{p_end}

{title:Examples}

{phang}{bf:1.  Default four-panel layout}{p_end}
{p 8 16 2}{stata "multicoint y x, est(taols) test(all)"}{p_end}
{p 8 16 2}{stata "multicoint_graph"}{p_end}

{phang}{bf:2.  Six-panel with PDF export}{p_end}
{p 8 16 2}{stata "multicoint_graph, sixpanel save(mcdiag.pdf)"}{p_end}

{phang}{bf:3.  Only the residual trace}{p_end}
{p 8 16 2}{stata "multicoint_graph, onepanel"}{p_end}

{title:Author}

{phang}
Dr Merwan Roudane,
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}.{p_end}

{title:Also see}

{psee}Online:  {helpb multicoint}, {helpb multicoint_sim}, {helpb multicoint_cv}{p_end}
