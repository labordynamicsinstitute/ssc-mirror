{smcl}
{* *! version 1.2.3  06may2026}{...}
{viewerjumpto "Syntax" "xtbalfront##syntax"}{...}
{viewerjumpto "Description" "xtbalfront##description"}{...}
{viewerjumpto "Options" "xtbalfront##options"}{...}
{viewerjumpto "Output" "xtbalfront##output"}{...}
{viewerjumpto "Workflow" "xtbalfront##workflow"}{...}
{viewerjumpto "Examples" "xtbalfront##examples"}{...}
{viewerjumpto "Stored results" "xtbalfront##results"}{...}
{viewerjumpto "Methodological note" "xtbalfront##notes"}{...}
{viewerjumpto "Acknowledgments" "xtbalfront##ack"}{...}
{viewerjumpto "Author" "xtbalfront##author"}{...}
{title:Title}

{phang}
{bf:xtbalfront} {hline 2} Trade-off frontier diagnostics and balanced-subsample
selection for unbalanced panel data


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:xtbalfront} {varlist} {ifin}{cmd:,}
{cmdab:id(}{varname}{cmd:)}
{cmdab:time(}{varname}{cmd:)}
[{it:options}]

{synoptset 28 tabbed}{...}
{synopthdr:options}
{synoptline}
{syntab:Required}
{synopt :{cmdab:id(}{varname}{cmd:)}}numeric cross-section identifier{p_end}
{synopt :{cmdab:time(}{varname}{cmd:)}}numeric time identifier{p_end}

{syntab:Subsample target (optional, mutually exclusive)}
{synopt :{opt years(#)}}choose a subsample of {it:#} balanced years{p_end}
{synopt :{cmdab:cross:sections(}{it:#}{cmd:)}}choose a subsample with at least {it:#} balanced cross-sections{p_end}

{syntab:Anchor (optional - constrains where the balanced window may sit)}
{synopt :{cmdab:end:period(}{it:#}{cmd:)}}window must end at period {it:#}{p_end}
{synopt :{cmdab:start:period(}{it:#}{cmd:)}}window must start at period {it:#}{p_end}
{synopt :{opt rec:ent}}window must end at the most recent period (shortcut){p_end}

{syntab:Apply the subsample}
{synopt :{cmdab:gen:erate(}{newvar}{cmd:)}}create a 0/1 indicator marking the chosen subsample{p_end}
{synopt :{opt keep}}drop observations not in the chosen subsample{p_end}
{synopt :{opt dry:run}}show diagnostics for the proposed subsample without applying {opt generate()} or {opt keep}{p_end}

{syntab:Mode}
{synopt :{opt any}}use per-firm survival count instead of consecutive-window logic{p_end}

{syntab:Output controls}
{synopt :{opt nograph}}suppress all graphs{p_end}
{synopt :{cmdab:nohea:tmap}}suppress the data presence/absence heatmap{p_end}
{synopt :{opt nohist}}suppress the distribution-of-availability histogram{p_end}
{synopt :{opt nolist}}suppress the trade-off tables and L x N peak printout{p_end}
{synopt :{cmdab:nocomp:are}}suppress the full-vs-subsample comparison table{p_end}
{synopt :{cmdab:nohist:compare}}suppress the per-variable pre/post histogram plots{p_end}
{synopt :{cmdab:nogap:note}}suppress the internal-gap diagnostic and {bf:xtmispanel} note{p_end}
{synopt :{cmdab:nosel:list}}suppress the list of selected cross-sections{p_end}
{synopt :{cmdab:maxli:st(}{it:#}{cmd:)}}maximum cross-sections to print in the selected list (default 50){p_end}
{synopt :{cmdab:maxs:how(}{it:#}{cmd:)}}maximum cross-sections to render in the heatmap (default 200){p_end}

{syntab:Cosmetic}
{synopt :{cmdab:lc:olor(}{it:colour}{cmd:)}}line colour for the best-window curve{p_end}
{synopt :{cmdab:mc:olor(}{it:colour}{cmd:)}}marker colour for the best-window curve{p_end}

{syntab:Saving}
{synopt :{cmdab:savem:atrix(}{it:matname}{cmd:)}}save the best-window trade-off curve as a Stata matrix{p_end}
{synopt :{cmdab:saver:ecent(}{it:matname}{cmd:)}}save the anchored trade-off curve as a Stata matrix{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:xtbalfront} examines an unbalanced panel and characterises the trade-off
between balanced length (number of years) and balanced breadth (number of
cross-sections) implied by the pattern of missing data on a user-supplied
{varlist}.  An observation is treated as {it:valid} if every variable in
{varlist} is non-missing for that cross-section / period.

{pstd}
The command gives the analyst high flexibility in choosing the specific
balanced window - any length, any anchor, optionally pinned to the most
recent period - and a quantitative read on how that choice differs
distributionally from the original unbalanced data.  The default invocation
runs every diagnostic at once: panel structure, both trade-off curves
(best-window and recency-anchored), the L x N peak, a presence/absence
heatmap, a per-firm availability histogram, and an internal-gap note.

{pstd}
By default the command produces, in a single call:

{phang2}{bf:1.}  A {it:panel structure} block via {help xtset:xtset} +
{help xtdescribe:xtdescribe} on the {it:if/in} sample, so the analyst sees
the panel before any subsetting decision.{p_end}

{phang2}{bf:2.}  A {it:trade-off table} listing, for every balanced length
L = 1, 2, ..., the maximum number of cross-sections that can form a balanced
panel of that length, together with the start and end of the optimal
window.{p_end}

{phang2}{bf:3.}  A second trade-off table for the {it:recency-anchored} case,
in which the window is held fixed against the most recent period in the data.
This second table answers the question "if I want my balanced panel to end at
the latest available year, how many cross-sections survive at each
length?"{p_end}

{phang2}{bf:4.}  Two {it:trade-off plots}, one per curve, each with the L x N
peak (the largest balanced sample) marked.  The plots are produced as named
graphs ({cmd:xtbalfront_best} and {cmd:xtbalfront_recent} or
{cmd:xtbalfront_anchored}) so the analyst can recall, modify or export them
independently.{p_end}

{phang2}{bf:5.}  A {it:heatmap} of data presence/absence across cross-sections
and time, suppressed automatically when the panel exceeds {opt maxshow()}
cross-sections.{p_end}

{phang2}{bf:6.}  A {it:histogram} of the per-cross-section count of valid
years.{p_end}

{phang2}{bf:7.}  An {it:internal-gap diagnostic} flagging cross-sections whose
valid observations are non-contiguous, with a suggestion to consider
{help xtmispanel} or interpolation if appropriate.{p_end}

{pstd}
When {opt years()} or {opt crosssections()} is supplied, the command additionally:

{phang2}{bf:8.}  Identifies the implied balanced sub-panel and reports L, N
and the window endpoints.{p_end}

{phang2}{bf:9.}  Reports a {it:comparison table} of mean and standard deviation
for every variable in {varlist}, with a Welch t-test of the difference between
the proposed subsample and the cross-sections that would be discarded.  A
small p-value warns that the subsetting is removing systematic variation, not
just observations.{p_end}

{phang2}{bf:10.} Produces an {it:overlaid pre/post histogram plot} for each
variable in {varlist}, comparing the full sample with the selected subsample
and reporting the percentage change in the mean in the plot's note.{p_end}

{phang2}{bf:11.} Lists the selected cross-sections (with value labels where
present), capped at {opt maxlist()}.{p_end}

{phang2}{bf:12.} Optionally creates an indicator variable ({opt generate()})
or restricts the dataset in memory ({opt keep}).  Specifying {opt dryrun}
shows everything except the actual subsetting, so the analyst can review the
diagnostics before committing.{p_end}

{pstd}
The default command does {bf:not} restrict the dataset.  Use {opt generate()}
or {opt keep} to materialise a subsample.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmdab:id(}{varname}{cmd:)} numeric cross-section identifier (e.g. country,
firm, individual).  Must be numeric.

{phang}
{cmdab:time(}{varname}{cmd:)} numeric time identifier (e.g. year, quarter
encoded as a Stata numeric).  Must be numeric.

{dlgtab:Subsample target}

{phang}
{opt years(#)} requests a balanced panel of exactly {it:#} years.  The
command picks the L = {it:#} row of the trade-off curve and identifies the
optimal cross-sections that survive that window.  When an anchor option is
also supplied, the anchored trade-off curve is used.

{phang}
{cmdab:cross:sections(}{it:#}{cmd:)} requests a balanced panel containing at
least {it:#} cross-sections.  The command picks the {it:longest} balanced
length consistent with that target.

{phang}
{opt years()} and {opt crosssections()} are mutually exclusive.

{dlgtab:Anchor}

{phang}
{cmdab:end:period(}{it:#}{cmd:)} forces the balanced window to end at period
{it:#}.

{phang}
{cmdab:start:period(}{it:#}{cmd:)} forces the window to start at period
{it:#}.

{phang}
{opt recent} is shorthand for {cmd:endperiod(}{it:max-time}{cmd:)}.  Equivalent
to "anchor at the most recent period in the data".

{pstd}
With no anchor option, the second curve drawn alongside the best-window curve
is automatically the recency-anchored one (so default behaviour matches the
common expectation: "best obtainable" vs. "what survives if I insist on the
latest period").

{dlgtab:Apply the subsample}

{phang}
{cmdab:gen:erate(}{newvar}{cmd:)} creates a new 0/1 indicator equal to 1 for
observations in the chosen balanced subsample, 0 otherwise.  Non-destructive.

{phang}
{opt keep} removes from memory any observation outside the subsample.
Destructive - use after {opt dryrun} or in a {help preserve} block.

{phang}
{opt dryrun} shows the trade-off curves, the gap note, the comparison table,
the per-variable histograms and the selected-cross-section list, but does
{bf:not} create the indicator variable or drop any rows.  Re-run without
{opt dryrun} to apply.

{dlgtab:Mode}

{phang}
{opt any} switches from consecutive-window logic to a per-firm survival count.
The y-axis of the trade-off then shows "cross-sections with at least L valid
years anywhere in time" rather than "cross-sections whose L valid years are
{it:consecutive}".  Use {opt any} only if your downstream estimator does not
require consecutive observations.

{dlgtab:Output controls}

{phang}
{opt nograph}, {cmdab:nohea:tmap}, {opt nohist}, {opt nolist},
{cmdab:nocomp:are}, {cmdab:nohist:compare}, {cmdab:nogap:note},
{cmdab:nosel:list} suppress the corresponding output element.

{phang}
{cmdab:maxli:st(#)} controls how many cross-sections are printed in the
selected list before truncation; default 50.

{phang}
{cmdab:maxs:how(#)} caps the heatmap; if the panel has more cross-sections
than this, the heatmap is suppressed (the histogram still appears).
Default 200.


{marker output}{...}
{title:What each chart and table shows}

{pstd}
{bf:Panel structure block.} Reports the panel variable, time variable, time
range, and the distribution of T_i (number of periods per cross-section) via
{help xtset} and {help xtdescribe}.  Read this first to confirm the panel is
the shape you expect.

{pstd}
{bf:Trade-off plots.} The horizontal axis is the balanced window length L
(in periods).  The vertical axis is the number of cross-sections that can
form a balanced panel of that length.  Two separate plots are produced:

{phang2}{it:Best-window plot.} For each L, the best obtainable count when
the window may sit anywhere in time.  Reading right means asking for a
longer balanced span, so the count weakly falls; the L x N peak (red diamond)
is the L at which L * N is maximised - i.e. the most data-rich balanced
sample.  Saved as the named graph {cmd:xtbalfront_best}.{p_end}

{phang2}{it:Recency-anchored or user-anchored plot.} For each L, the count
when the window's endpoints are forced.  With no anchor option, the window
is held to end at the most recent period; reading right then means
extending the window further back from the latest year.  With
{opt endperiod()} or {opt startperiod()}, the anchor is wherever you put
it.  Saved as the named graph {cmd:xtbalfront_recent} or
{cmd:xtbalfront_anchored}.{p_end}

{phang2}A caption beneath each plot reminds the reader of these
conventions.  Plot titles are intentionally omitted; the named-graph
mechanism lets the analyst add a title via
{help graph_display:graph display} if desired.{p_end}

{pstd}
{bf:Trade-off tables.} Numerical equivalents of the curves, one row per L,
showing the start and end periods of the optimal window for that length.

{pstd}
{bf:L x N peak printout.} The single largest balanced sample for each curve,
printed as L = ?  N = ? L*N = ? window = ? to ?  Use these numbers as the
arguments to a follow-up call: {cmd:xtbalfront ..., years(L) gen(insample)}.

{pstd}
{bf:Heatmap (presence/absence).} A matrix view: each row is one cross-section
(sequentially indexed), each column is a period, each square is filled (navy)
if the row has all variables present in that period and hollow (red) if not.
The heatmap is the fastest way to {it:see} whether unbalancedness is
concentrated (e.g. all attrition at the end) or scattered.  Suppressed
automatically when the panel has more than {opt maxshow()} cross-sections.

{pstd}
{bf:Distribution histogram.} A frequency histogram of the count of valid
years per cross-section.  A bimodal distribution typically indicates two
populations of firms (e.g. survivors vs. short-lived); a long left tail
suggests entrants and exits.

{pstd}
{bf:Internal-gap diagnostic.} For every cross-section we locate the first
and last valid period and ask whether all interior periods are valid too.
If not, the cross-section has an internal gap.  The note reports the count
of gappy cross-sections and the total number of interior missing values -
i.e. how many observations interpolation could potentially recover.  The
note suggests {help xtmispanel}, {help mipolate} or {help ipolate} as
candidates but {bf:does not} apply them.

{pstd}
{bf:Comparison table (full vs proposed subsample).} For each variable in
{varlist} we report the mean and standard deviation in the full {it:if/in}
sample and in the proposed subsample, plus a Welch t-statistic for the
difference between the subsample and its complement (the cross-sections
that would be discarded).  This is a {it:warning} test, not a randomness
test: significant differences mean the subsetting is removing systematic
variation.

{pstd}
{bf:Pre/post histograms.} One overlaid plot per variable in {varlist} (named
{cmd:xtbf_h_}{it:varname}, with {it:varname} truncated to 24 characters
when needed to fit Stata's 32-character graph-name limit), showing the
density of the full sample (navy) on top of the selected subsample
(cranberry).  The plot's note reports the percentage change in the mean
and the two mean values themselves.  This is the visual companion to the
comparison table - a small mean shift may still hide a meaningful change
in the distribution's shape.

{pstd}
{bf:Selected cross-section list.} Once a target is given, the unique IDs
that make the cut are printed, with their value labels where attached.  Long
lists are truncated at {opt maxlist()}.


{marker workflow}{...}
{title:Recommended workflow}

{phang}{bf:Step 1.}  Run {cmd:xtbalfront} with no target.  Inspect the panel
structure, both curves, the heatmap, the histogram and the gap note.{p_end}

{phang}{bf:Step 2.}  Decide on a target.  If you care about a specific length
(say, six years) use {opt years(6)}.  If you care about breadth (say, at
least 1000 firms) use {opt crosssections(1000)}.  If the most recent period
matters substantively, add {opt recent}.{p_end}

{phang}{bf:Step 3.}  Re-run with the target and {opt dryrun}.  Read the
comparison table and the pre/post histograms.  If a t-test for any key
variable is large or the histograms shift visibly, the balanced-subsample
estimates may not generalise.{p_end}

{phang}{bf:Step 4.}  Re-run without {opt dryrun}, supplying {opt generate()}
(non-destructive) or {opt keep} (destructive).  Estimate your model on the
full and selected samples and compare the substantive results.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}Setup:{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}
{phang2}{cmd:. xtset idcode year}{p_end}

{pstd}Diagnostics only - panel summary, both curves, heatmap, gap note:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year)}{p_end}

{pstd}Pick a six-year balanced panel using the best window; preview only:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year) years(6) gen(in6) dryrun}{p_end}

{pstd}Same, but anchored at the latest year and applied:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year) years(6) recent gen(in6_recent)}{p_end}

{pstd}Pick the longest panel containing at least 1000 cross-sections, drop the rest:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year) crosssections(1000) keep}{p_end}

{pstd}Anchor at a specific period:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year) years(6) endperiod(86) gen(in_anchored)}{p_end}

{pstd}Save both curves to matrices for further work:{p_end}
{phang2}{cmd:. xtbalfront ln_wage grade union, id(idcode) time(year) savematrix(C_BEST) saverecent(C_REC)}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:xtbalfront} stores the following in {cmd:r()}:{p_end}

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:r(total_cross)}}number of unique cross-sections in the if/in sample{p_end}
{synopt:{cmd:r(nodata_cross)}}cross-sections with no valid observation{p_end}
{synopt:{cmd:r(max_years)}}number of unique periods in the data{p_end}
{synopt:{cmd:r(gap_count)}}cross-sections with at least one internal gap{p_end}
{synopt:{cmd:r(gap_severity)}}total interior missing values across all cross-sections{p_end}
{synopt:{cmd:r(peak_best_L)}}L at the best-window L x N peak{p_end}
{synopt:{cmd:r(peak_best_N)}}N at the best-window L x N peak{p_end}
{synopt:{cmd:r(peak_anc_L)}}L at the anchored L x N peak (when available){p_end}
{synopt:{cmd:r(peak_anc_N)}}N at the anchored L x N peak (when available){p_end}
{synopt:{cmd:r(selected_years)}}L of the chosen subsample (when targeted){p_end}
{synopt:{cmd:r(selected_cross)}}N of the chosen subsample (when targeted){p_end}
{synopt:{cmd:r(selected_start)}}window start of the chosen subsample{p_end}
{synopt:{cmd:r(selected_end)}}window end of the chosen subsample{p_end}
{synopt:{cmd:r(selected_obs)}}L * N of the chosen subsample{p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:r(mode)}}{bf:window} or {bf:any}{p_end}
{synopt:{cmd:r(anchor)}}description of the anchored curve, when shown{p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:r(curve)}}best-window trade-off curve (L, N, start, end){p_end}
{synopt:{cmd:r(curve_anchored)}}anchored trade-off curve (L, N, start, end){p_end}


{marker notes}{...}
{title:Methodological note}

{pstd}
{bf:Why the best-window curve is monotone weakly decreasing.}  Any window of
length L+1 contains a window of length L; the cross-sections that are valid
in the longer window are a subset of those valid in some length-L window.
Hence N(L+1) <= N(L).

{pstd}
{bf:Recency-anchored vs best-window.}  The recency-anchored curve answers a
substantively different question.  If your downstream analysis requires the
panel to end at the most recent period (because you're projecting forward
from "now"), the best-window count for length L is irrelevant - what
matters is how many cross-sections survive the L most recent years.  This
is why {cmd:xtbalfront} draws both by default.


{marker ack}{...}
{title:Acknowledgments}

{pstd}
{cmd:xtbalfront} uses Stata's built-in {help xtset} and {help xtdescribe} to
print the panel-structure summary at the top of every run.  Both are part
of the {help xt} suite shipped with Stata; this command is grateful for
their availability.


{marker author}{...}
{title:Author}

{pstd}
Noman Arshed, Sunway Business School, Sunway University, Malaysia.{break}
Email: nomana@sunway.edu.my{break}
Web:   https://econistics.com{break}

{pstd}
Bug reports and feature requests are welcome via email or the
{browse "https://www.statalist.org/":Statalist} forum.


{title:Also see}

{psee}
Stata: {help xtdescribe}, {help xtset}, {help xtreg}{p_end}
{psee}
SSC:   {stata "ssc describe xtmispanel":xtmispanel}{p_end}
