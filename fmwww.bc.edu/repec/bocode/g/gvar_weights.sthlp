{smcl}
{* *! version 1.0.1  21aug2026}{...}
{vieweralsosee "gvar" "help gvar"}{...}
{vieweralsosee "gvar setup" "help gvar_setup"}{...}
{vieweralsosee "gvar foreign" "help gvar_foreign"}{...}
{vieweralsosee "gvar dominant" "help gvar_dominant"}{...}
{viewerjumpto "Syntax" "gvar_weights##syntax"}{...}
{viewerjumpto "Description" "gvar_weights##description"}{...}
{viewerjumpto "Remarks" "gvar_weights##remarks"}{...}
{viewerjumpto "Examples" "gvar_weights##examples"}{...}
{viewerjumpto "Stored results" "gvar_weights##results"}{...}
{viewerjumpto "Options" "gvar_weights##options"}{...}
{title:Title}

{phang}
{bf:gvar weights} {hline 2} build or load the link weights


{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:gvar weights} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{synoptset 32 tabbed}{...}
{synopthdr:options}
{synoptline}
{synopt:{opt mat:rix(name)}}use a matrix already in memory, rows and columns in unit order.{p_end}
{synopt:{opt type(#)}}which weight matrix this is, when variables use different ones. Default {cmd:type(1)}.{p_end}
{synopt:{opt flow(name)}}the flow variable in the {cmd:using} file.{p_end}
{synopt:{opt sou:rce(name)}}the partner identifier in the {cmd:using} file.{p_end}
{synopt:{opt dest:ination(name)}}the home identifier in the {cmd:using} file.{p_end}
{synopt:{opt year(name)}}the year variable in the {cmd:using} file.{p_end}
{synopt:{opt years(numlist)}}average the flows over these years.{p_end}
{synopt:{opt map(filename)}}crosswalk from flow-file names to model units.{p_end}
{synopt:{opt wide}}the {cmd:using} file is already a wide matrix.{p_end}
{synopt:{opt rown:ame(name)}}the row identifier in a wide file.{p_end}
{synopt:{opt slice(name)}}which slice of a stacked time-varying file to use.{p_end}
{synopt:{opt time:varying}}build one weight matrix per year.{p_end}
{synopt:{opt win:dow(#)}}moving-average window for time-varying weights. Default 3.{p_end}
{synopt:{opt sol:years(numlist)}}years whose weights are used when solving.{p_end}
{synopt:{opt eq:ual}}equal weights, 1/(N-1) off the diagonal.{p_end}
{synopt:{opt list}}print the matrix.{p_end}
{synopt:{opt gr:aph}}heatmap of the weights.{p_end}
{synopt:{opt name(name)}}graph name.{p_end}
{synopt:{opt noreb:uild}}do not rebuild the foreign variables afterwards.{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:gvar weights} supplies the {it:w_ij} used to build each unit's foreign
variables. Weights may be computed from bilateral flows, taken from a matrix
in memory, read from a wide file, set equal, or allowed to vary over time.

{pstd}
Rows are normalised to sum to one with {it:w_ii} = 0. The command refuses an
all-zero column outright, because that would make a unit's foreign variables
identically zero and silently drive its cointegrating rank to zero.


{marker options}{...}
{title:Options}

{pstd}
There are two ways to supply weights, and the options divide accordingly: give a
{bf:matrix} that is already a weight matrix, or give {bf:flow data} and let the
command build one.

{dlgtab:From a matrix}

{phang}
{opt matrix(name)} names a Stata matrix holding {it:W}, and {opt rowname(name)}
and {opt slice(name)} identify its rows and, for a stack of matrices, which slice
to take. {opt wide} says the file is in wide rather than long layout.

{dlgtab:From flow data}

{phang}
{opt flow(name)} is the variable holding the flow -- trade, financial claims --
with {opt source(name)} and {opt destination(name)} naming the two country
variables.

{pmore}
{bf:Get the direction right.} {it:W_i} weights the {bf:other} units from unit
{it:i}'s point of view, so which of the two columns is the source and which the
destination determines whether you build {it:W} or {it:W'}. A transposed weight
matrix produces foreign variables that look entirely plausible and are wrong --
{helpb gvar_foreign:gvar foreign}'s {opt list} option exists for checking this,
and it is worth doing once per new dataset.

{phang}
{opt year(name)} and {opt years(numlist)} select the years averaged over. Fixed
weights are the usual choice and the Toolbox averages a short window -- the demo
uses 2009 to 2011 -- rather than a single year, because annual bilateral flows are
noisy.

{phang}
{opt timevarying}, {opt window(#)} and {opt solyears(numlist)} instead build a
weight matrix per period from a rolling window of {it:#} years, default 3, and
{opt solyears()} chooses which years the solved model uses.

{phang}
{opt equal} builds equal weights, which is the null case worth running once: if
your conclusions are the same under trade weights and equal weights, the weights
are not doing the work you think they are.

{dlgtab:Common}

{phang}
{opt type(#)} labels the weight type, so several can be loaded and
{helpb gvar_setup:gvar setup}'s {opt wtype()} can choose between them per
variable -- trade weights for real variables, financial weights for the rest.

{phang}
{opt map(filename)} supplies the aggregation map, which is how the eight euro-area
members become one unit. Aggregation happens {bf:before} the weights are
normalised, so the map is not a post-processing step.

{phang}
{opt list} prints the resulting matrix and {opt nosummary} suppresses the report.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:On map().} If any unit in your model is an aggregate of several entities
in the flow file, you must supply a crosswalk. In the shipped demo the euro
area is built from eight members; those members appear in the trade data under
their own names and the aggregate does not appear at all. Without
{cmd:map()} the euro column is identically zero, its foreign variables vanish
and its rank collapses. The command detects the all-zero column and stops.

{pstd}
{bf:On years().} The weights are an average over the chosen window, and
different windows give visibly different responses, so record which you used.
The Toolbox demo averages 2009-2011.

{pstd}
{bf:A sanity check worth doing.} After building, {cmd:list} the matrix and
look at a row you know. In the demo the United States' three largest trade
weights are Canada 0.200, China 0.176 and Mexico 0.149, which is the right
real-world ranking. If the largest weights look implausible, the source and
destination variables are probably the wrong way round.


{marker examples}{...}
{title:Examples}

        {cmd:. gvar weights using gvar_flows.dta, flow(trade) source(partner) ///}
                {cmd:destination(home) year(year) years(2009 2011) type(1) ///}
                {cmd:map(gvar_demoagg.dta)}

        {cmd:. gvar weights, equal}
        {cmd:. gvar weights, matrix(Wtrade) list graph}
        {cmd:. gvar weights using gvar_flows.dta, flow(trade) source(partner) ///}
                {cmd:destination(home) year(year) timevarying window(3)}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:gvar weights} stores the following in {cmd:r()}:

{synoptset 26 tabbed}{...}
{synopt:{cmd:r(type)}}the weight-matrix type just built{p_end}
{synopt:{cmd:r(units)}}unit names in row order{p_end}
{synopt:{cmd:r(W)}}the weight matrix{p_end}
{synoptline}


{marker source}{...}
{title:Source}

{pstd}
Toolbox {it:build_wmat.m}, {it:weightmat.m}, {it:country_weights.m};
the crosswalk follows {it:update_matrix.m}.

{marker author}{...}
{title:Author}

{pstd}
Dr Merwan Roudane{break}
{browse "mailto:merwanroudane920@gmail.com":merwanroudane920@gmail.com}{break}
{browse "https://github.com/merwanroudane":https://github.com/merwanroudane}
