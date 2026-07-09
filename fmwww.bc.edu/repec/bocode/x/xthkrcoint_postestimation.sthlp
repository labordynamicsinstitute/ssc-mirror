{smcl}
{* *! version 1.0.0  08jul2026}{...}
{vieweralsosee "xthkrcoint" "help xthkrcoint"}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Description" "xthkrcoint_postestimation##description"}{...}
{viewerjumpto "Graphs" "xthkrcoint_postestimation##graphs"}{...}
{viewerjumpto "Working with stored results" "xthkrcoint_postestimation##results"}{...}
{viewerjumpto "Building a journal table" "xthkrcoint_postestimation##table"}{...}
{viewerjumpto "Author" "xthkrcoint_postestimation##author"}{...}
{title:Title}

{phang}
{bf:xthkrcoint postestimation} {hline 2} Postestimation tools, graphs and stored
results for {helpb xthkrcoint}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xthkrcoint} is a test command: everything it produces is left behind in
{cmd:r()} (it does not post an {cmd:e()} estimation vector). This page documents
the stored objects, the graphs, and how to assemble publication-ready tables and
figures from them.

{marker graphs}{...}
{title:Graphs}

{pstd}
The {opt graph} option draws a two-panel dashboard, each panel stored under a
name derived from {opt name()} (default stub {cmd:xthkr}):

{p 8 10 2}{bf:{it:stub}_units} {hline 1} a forest / caterpillar plot of the
per-unit bias-corrected statistics {bf:S~{sub:K,i}} with vertical reference
lines at the 5% (1.645) and 1% (2.326) one-sided critical values. Units that
reject cointegration at 5% are drawn in a contrasting colour.{p_end}

{p 8 10 2}{bf:{it:stub}_ksens} {hline 1} the pooled {bf:S~{sub:K}} and
{bf:S{sub:K}} as functions of the lag order {it:K}, with horizontal critical
values and a marker at the reported {it:K}.{p_end}

{p 8 10 2}{bf:{it:stub}} {hline 1} the two panels combined side by side.{p_end}

{pstd}
Because the panels are stored graphs, you can recall, restyle, combine or export
them after the command:{p_end}

{phang2}{cmd:. xthkrcoint y x, graph name(fig1)}{p_end}
{phang2}{cmd:. graph display fig1_units}{p_end}
{phang2}{cmd:. graph export figure1.png, replace width(2000)}{p_end}

{pstd}
Supply your journal's scheme with {opt scheme()} (for example a black-and-white
scheme for print):{p_end}

{phang2}{cmd:. xthkrcoint y x, graph scheme(s1mono)}{p_end}

{marker results}{...}
{title:Working with stored results}

{pstd}
The full per-unit matrix {cmd:r(indiv)} ({it:N}{c 215}9) and the sensitivity
grid {cmd:r(ksens)} can be pulled into the data for custom plotting:{p_end}

{phang2}{cmd:. xthkrcoint y x, ksens(5(3)26)}{p_end}
{phang2}{cmd:. matrix S = r(ksens)}{p_end}
{phang2}{cmd:. preserve}{p_end}
{phang2}{cmd:. clear}{p_end}
{phang2}{cmd:. svmat double S, name(col)}{p_end}
{phang2}{cmd:. twoway line S_bc K, yline(1.645 2.326)}{p_end}
{phang2}{cmd:. restore}{p_end}

{marker table}{...}
{title:Building a journal table}

{pstd}
A compact top-journal-style results block can be produced directly from the
scalars. For example, to loop the test over several lag orders and print one
row each:{p_end}

{phang2}{cmd:. foreach k in 10 15 20 {c 123}}{p_end}
{phang2}{cmd:.     quietly xthkrcoint y x, k(`k')}{p_end}
{phang2}{cmd:.     di as res %4.0f `k' _col(10) %9.3f r(Sbc) _col(24) %7.3f r(pbc)}{p_end}
{phang2}{cmd:. {c 125}}{p_end}

{pstd}
To collect the per-unit statistics into a labelled table for export with
{helpb estout} / {helpb esttab} (if installed), post them as a matrix and use
{cmd:matlist} or write them to a frame.{p_end}

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
merwanroudane920@gmail.com{break}
{browse "https://github.com/merwanroudane":github.com/merwanroudane}
{p_end}
