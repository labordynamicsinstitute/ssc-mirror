{smcl}
{* *! version 2.2.0 27jul2026}{...}
{vieweralsosee "return" "help return"}{...}
{vieweralsosee "weight" "help weight"}{...}
{vieweralsosee "export delimited" "help export delimited"}{...}
{vieweralsosee "javacall" "help javacall"}{...}

{title:Title}

{phang}
{bf:surveye} {hline 2} SurvEye: create an interactive HTML dashboard from a
Survey Solutions or SurveyCTO questionnaire and the corresponding Stata data


{marker quickstart}{...}
{title:Quick start}

{pstd}
Load one survey data file and point {cmd:surveye} to the questionnaire.
Three questionnaire files are accepted, detected by content rather than
extension: a Survey Solutions questionnaire preview ({bf:HTML}); a SurveyCTO
form definition ({bf:XML}, downloaded in SurveyCTO under Design {c -} form
files), which is read exactly, including groups, repeats, choice lists,
translations, and calculate fields; and a SurveyCTO printable form
({bf:HTML}) {c -} the printed Field/Question/Answer table is read directly,
including group sections, nested and repeated subgroups, choice lists, and
relevance conditions.  Printables do not encode field types, so choice
fields import as {it:select_one} and open or note fields as text; notes
drop automatically when no matching data column exists.  When a printable
layout is not recognized, the error points to the XML definition.
SurveyCTO split select_multiple exports ({cmd:field_1}, {cmd:field_2}, ...)
are reassembled automatically.

{phang2}{cmd:. use "survey_data.dta", clear}

{phang2}{cmd:. surveye using "questionnaire.html", saving("dashboard.html") replace open}

{phang2}{cmd:. surveye using "form_definition.xml", saving("dashboard.html") replace open}

{pstd}
The original Survey Solutions flow is unchanged:

{phang2}{cmd:. use "survey_data.dta", clear}

{phang2}{cmd:. surveye using "questionnaire.html", saving("dashboard.html") replace open}

{pstd}
Inspect an unfamiliar questionnaire before building:

{phang2}{cmd:. surveye describe using "questionnaire.html", detail}

{pstd}
Preview the questionnaire with clearly marked simulated data:

{phang2}{cmd:. surveye demo using "questionnaire.html", saving("preview.html") n(300) seed(42) replace open}

{pstd}
SurvEye 2.0.0 uses the public command name {cmd:surveye}.  Update do-files that
use the former {cmd:suso_dashboard} command or the interim {cmd:surveydash}
preview name; no legacy compatibility command is installed.


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:surveye} [{varlist}] {ifin}
{cmd:using} {it:questionnaire.html}
[{cmd:[aw=}{it:wvar}{cmd:]} | {cmd:[fw=}{it:wvar}{cmd:]} |
 {cmd:[iw=}{it:wvar}{cmd:]} | {cmd:[pw=}{it:wvar}{cmd:]}]
{cmd:,}
{opt saving(filename)} [{it:options}]

{p 8 17 2}
{cmd:surveye build} [{varlist}] {ifin}
{cmd:using} {it:questionnaire.html}
[{cmd:[aw=}{it:wvar}{cmd:]} | {cmd:[fw=}{it:wvar}{cmd:]} |
 {cmd:[iw=}{it:wvar}{cmd:]} | {cmd:[pw=}{it:wvar}{cmd:]}]
{cmd:,}
{opt saving(filename)} [{it:options}]

{p 8 17 2}
{cmd:surveye describe using} {it:questionnaire.html}
[{cmd:,} {opt detail} {opt strict} {opt diagnostics(filename)} {opt replace}]

{p 8 17 2}
{cmd:surveye demo using} {it:questionnaire.html}{cmd:,}
{opt saving(filename)}
[{opt n(#)} {opt seed(#)} {opt maxpanels(#)} {opt ci} {opt level(#)}
{opt replace} {opt open} {it:presentation_options}]

{pstd}
The main command uses the dataset in memory.  Stata 16 or newer is required.
Use Stata's native weight syntax after the {cmd:using} filename and before the
comma, for example
{cmd:[aw=wmedian]}, {cmd:[fw=frequency]}, {cmd:[iw=importance]}, or
{cmd:[pw=pop]}.  There is no {cmd:weight()} option.  The optional {cmd:build}
word is equivalent to the main form.  It is useful when the first selected data
variable is named {cmd:build}, {cmd:describe}, or {cmd:demo}.  Repeat that
variable after the subcommand; for example,
{cmd:surveye build build sales using "questionnaire.html", saving("results.html")}.


{marker options}{...}
{title:Options for the main command}

{dlgtab:Output}

{phang}
{opt saving(filename)} is required and names the HTML dashboard.  The
{cmd:.html} extension is added if omitted.

{phang}
{opt replace} permits an existing dashboard, diagnostics file, or other engine
output to be replaced.

{phang}
{opt open} opens the completed dashboard in the system browser.  The file is
still saved if Stata cannot open the browser.

{phang}
{opt diagnostics(filename)} writes a technical log for troubleshooting.


{dlgtab:Questionnaire selection}

{phang}
{it:varlist} selects ordinary Stata variables to chart.  If both {it:varlist}
and {opt questions()} are omitted, the command considers all chartable
questionnaire items present in the data.  Variables used only for filters,
highlights, weights, or maps are added to the temporary export automatically
and are not charted unless selected.  Variables used only by the optional
profile table or local-currency/USD switch are handled the same way.

{phang}
{opt questions(question_names)} selects logical Survey Solutions question
names.  Separate names with spaces or commas and quote the list, for example
{cmd:questions("services_used certifications_used")}.  This option is useful
when a multiselect question {cmd:q} is stored as {cmd:q__1}, {cmd:q__2}, and so
on, with no variable named {cmd:q}.  Do not use wildcards.  {it:varlist} and
{opt questions()} may be combined; duplicate selections are removed.  Names
shown by {cmd:surveye describe ..., detail} are suitable inputs.

{phang}
{opt exclude(names)} omits questionnaire items.  It accepts Stata varlists and
logical Survey Solutions question names.  A name may not be both selected or
chart-overridden and excluded.

{phang}
{opt sections(numlist)} keeps questionnaire sections by number.  Use
{cmd:surveye describe ..., detail} to see the section numbers.

{phang}
{opt sectionmatch(text)} keeps sections whose title contains any term in a
pipe-separated list, such as {cmd:sectionmatch("profile|employment")}.  It may
not be combined with {opt sections()}.

{phang}
{opt customsections(spec)} reorganizes all selected charts.  Separate groups
with {cmd:|} and write each group as {cmd:Title: varlist}.  Unassigned charts
are placed in {it:Other indicators}.  Example:
{cmd:customsections("Firm profile: sector size|Performance: sales employment")}.
It may not be combined with {opt addtosections()}.

{phang}
{opt showempty} keeps an explicitly selected questionnaire item even when no
matching nonempty data column is found.  It is mainly useful for diagnostics
and templates.

{phang}
{opt strict} stops on undeclared selected variables and promotes questionnaire
parser warnings to errors.  Variables deliberately declared in
{opt customvars()} are allowed under {cmd:strict}.

{phang}
{opt maxpanels(#)} limits indicator charts while preserving questionnaire
order.  The default is 100; {cmd:maxpanels(0)} removes the limit.  Allowed
values are 0 through 5,000.  Explicit custom variables are processed first so
the cap does not silently place them behind a long questionnaire.  The command
stops if {opt customvars()} alone contains more variables than the cap.


{marker customvars}{...}
{dlgtab:Variables not in the questionnaire}

{phang}
{opt customvars(varlist)} adds constructed indicators, quality-control fields,
administrative classifications, or other variables in memory even when they
do not exist in the questionnaire.  It is additive: normal questionnaire
selection still applies, and the custom variables are added to it.

{pmore}
The variable label becomes the chart title by default; the variable name is
used when the label is empty.  Generic Survey Solutions labels such as
{it:Calculated variable of type String} also fall back to the variable name.
Numeric variables receive distributions.
Variables formatted as {cmd:%tc}, {cmd:%td}, {cmd:%tw}, {cmd:%tm}, {cmd:%tq},
{cmd:%th}, or {cmd:%ty} receive date charts.  Strings receive categorical
charts, and numeric variables with value labels receive categorical charts.
Observed Stata value-label text is retained when the number of levels does not
exceed {opt maxcategories()}.  Custom variables not otherwise placed appear in
{it:Additional indicators}.

{pmore}
Business-calendar {cmd:%tb} values are not currently interpreted as dates
because their calendar rules are dataset-specific.  Convert or export them to
one of the supported date representations before including them in
{opt customvars()}.

{phang}
{opt addtosections(spec)} places variables declared in {opt customvars()} in
any selected section.  Separate assignments with {cmd:|}.  The target before
the colon may be an exact section title (ignoring case), a number, or a new
text title.  A number first matches the questionnaire's original section
number; when that number is not selected, it matches the visible dashboard
position (1, 2, 3, and so on).  A new text title creates a new section; an
unmatched numeric target is an error.  Examples:

{phang2}{cmd:addtosections("Firm profile: qc_score risk_band")}

{phang2}{cmd:addtosections("3: qc_score|Quality checks: risk_band")}

{pmore}
Only variables listed in {opt customvars()} may be moved.  Unmentioned custom
variables remain in {it:Additional indicators}.  {opt addtosections()} may not
be combined with {opt customsections()}.


{dlgtab:Related-variable families}

{phang}
SurvEye automatically combines high-confidence families of related binary
variables into one compact comparison figure.  For example,
{cmd:srib8a}, {cmd:srib8b}, and {cmd:srib8c} can be displayed as three labelled
rows in a single card.  Automatic grouping is conservative: members must have
a recognizable letter suffix, compatible response categories, and the same
final dashboard section.  Survey Solutions multiselect storage columns such as
{cmd:q__1} and {cmd:q__2} are never treated as a suffix family.

{phang}
{opt vargroups(spec)} defines groups manually.  Separate groups with {cmd:|}
and write each as {cmd:Title:: varlist}.  The double colon separates the
displayed title from an ordinary Stata varlist, so ranges and wildcards are
expanded by Stata.  Every group requires at least two variables, and a
variable may occur in only one manual group.  Members must already be selected
by the main {it:varlist}, {opt questions()}, or {opt customvars()}.  Example:

{phang2}{cmd:vargroups("Digital channels:: srib8a srib8b srib8c|Business support:: srib9a srib9b srib9c")}

{pmore}
Questionnaire text supplies each row label.  For a custom variable, its Stata
variable label is used, with the variable name as the fallback.  Manual groups
take precedence over automatic grouping and inherit the final section shared
by their members.  Use {opt customsections()} or {opt addtosections()} first
when custom variables need to be placed together.

{phang}
{opt ungroupvars(varlist)} keeps named variables as separate cards while
leaving automatic grouping available elsewhere.  Use {opt noautogroups} to
turn off all automatically detected families.  Explicit {opt vargroups()}
remain active with {opt noautogroups}.  A variable may not appear in both
{opt vargroups()} and {opt ungroupvars()}.


{dlgtab:Explicit binary comparisons}

{phang}
{opt compare(varlist)} combines up to 12 selected binary variables in one
grouped horizontal-bar comparison.  Each bar reports the affirmative response
share, and {opt compareby(varname)} supplies the comparison groups.  Both
options are required together.  The {opt compareby()} variable is exported
for the comparison but is not added as an indicator card unless it is also
selected normally.  Example:

{phang2}{cmd:compare(srib8a srib8b srib8c) compareby(city)}

{phang}
{opt comparetitle(text)} replaces the automatically generated comparison
title.

{phang}
{opt comparelevels(levels)} limits and orders the displayed values of
{opt compareby()}.  Separate exact raw values or displayed value labels with
{cmd:|}; for example,
{cmd:comparelevels("01_Colombo|02_Kandy|03_Jaffna")}.  Without this option,
valid observed comparison levels are used in their natural order.

{pmore}
Comparison variables must be selected and must have a recognizable binary
affirmative response.  Missing values, special response codes, {ifin}, and
weights follow the same rules as the corresponding binary cards.  Confidence
interval whiskers are never drawn on these binary comparison bars, including
when {opt ci} is specified.


{dlgtab:Controls, messages, and charts}

{phang}
{opt filters(varlist)} creates dashboard filters from low-cardinality
variables.  If omitted, the engine may suggest up to three conservative
filters.  Use this option for required controls, particularly with translated
questionnaires.  A requested filter with more than {opt maxcategories()}
levels is rejected.

{pmore}
Choices come only from observed valid values; codes named by
{opt missingcodes()} are never offered.  Numeric choices are compared by
numeric value, multiselect choices match when any selected option is present,
and privacy-reduced text or media questions offer localized
{it:Answered}/{it:Missing} choices.  An explicitly requested categorical
filter with no observed valid values stops with an explanatory error instead
of showing controls that can only produce zero results.

{pmore}
The sticky search/filter panel is collapsed by default so it does not cover the
figures.  Select {bf:Show filters} to reveal its contents and {bf:Hide filters}
to return to the compact toolbar.  Collapsing the panel preserves the search
text and selected choices.  The toolbar keeps {bf:Reset all}, the live interview
count, and—when applicable—the number of active filter choices visible.
{bf:Reset all} clears both the response filters and the indicator search.

{phang}
{opt highlights(varlist)} creates up to six summary cards.

{phang}
{opt keymessages(text)} adds up to six editorial messages.  Separate messages
with {cmd:|}.  An optional heading precedes {cmd:::}; for example,
{cmd:keymessages("Coverage::Completed interviews|Caution::Weighted estimates")}.

{phang}
Automatic chart selection uses horizontal percentage bars for categorical and
multiselect questions, split bars for binary and answered/missing items,
histograms for numeric variables, and time distributions for dates.  Donuts
are not selected automatically.

{phang}
{opt bars(varlist)}, {opt donuts(varlist)}, and {opt histograms(varlist)}
override compatible automatic chart choices.  A variable may appear in only
one override.  With a main {it:varlist} or {opt questions()} selection, an
override must also be selected there or in {opt customvars()}.

{phang}
Small integer-valued numeric variables are recognized automatically as
discrete counts when their question text and observed support strongly look
like counts, such as number of workers or household members.  Detection is
conservative and uses the actual analysis sample after {ifin}, weights, and
missing-code exclusions.  Readable ranges display one bar for every integer,
including zero-frequency gaps.  Wider ranges automatically use equal-width,
integer-aligned bins.  A numeric x axis supplies regular round-number ticks.
Negative questionnaire response codes are excluded.  Every valid measurement
remains in the chart and summary.  A dotted mean-plus-three-standard-deviations
guide is drawn only when it falls strictly inside the plotted range.  The
numeric Stats tab remains available and updates immediately with filters.

{phang}
{opt discrete(varlist)} forces numeric counts, bounded scores, or numeric
category codes to use this smart integer distribution.  It preserves exact
values when readable and bins only a genuinely wide integer range.
{opt continuous(varlist)} forces numeric variables to use a continuous
histogram and numeric Stats table, even when all observed values are integers
or a Stata value label is attached.  Both options require numeric, non-date
variables that are also selected for the dashboard.  Examples:

{phang2}{cmd:discrete(employees visits) continuous(revenue productivity_score)}

{phang}
{opt noautodiscrete} disables only automatic discrete-count detection.
Explicit {opt discrete()}, {opt continuous()}, and chart overrides still
apply.  {opt histograms()} explicitly requests continuous behavior and may be
combined redundantly with {opt continuous()}; it conflicts with
{opt discrete()}.  {opt bars()} and {opt donuts()} may accompany
{opt discrete()} but conflict with {opt continuous()}.

{phang}
{opt maxcategories(#)} sets the maximum categories for filters and categorical
figures.  The default is 12; allowed values are 2 through 200.  Compact mode
shows at most seven displayed levels.  Less frequent levels are combined as
{it:Other}, while percentages continue to use the full valid denominator.
This option does not limit {opt discrete()} or continuous numeric distributions.

{phang}
{opt missingcodes(numlist)} explicitly excludes extra numeric nonresponse or
sentinel codes from chart denominators and numeric/date calculations, for
example {cmd:missingcodes(-999 -998 999)}.  Questionnaire-defined special
responses remain visible and muted in categorical figures.  Negative special
codes are automatically excluded from numeric distributions, statistics,
and numeric filters because response codes such as
{cmd:-4} and {cmd:-9} are not measurements.  Nonnegative substantive
shortcuts and legitimate negative-valued questions remain valid.  Use
{opt missingcodes()} for additional undeclared sentinels.


{marker weights}{...}
{dlgtab:Weights}

{pstd}
Weights use ordinary Stata command syntax; they are not options.  Place one
single-variable weight specification after the {cmd:using} filename and before
the comma:

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [aw=wmedian], saving("analytic.html") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [fw=frequency], saving("frequency.html") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [iw=importance], saving("importance.html") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [pw=pop], saving("population.html") replace}

{pstd}
The weight must resolve to one numeric variable.  Negative values are rejected.
Frequency weights must contain integers.  Observations with zero or missing
weights are excluded for all four types, so every retained weight is positive.
The command stops if no observations remain after {cmd:if}, {cmd:in}, and
weight restrictions.  A weight-only variable is exported for calculation but
is not charted unless selected.  See {help weight}.

{pstd}
Weights are applied to shares, histograms, means, medians, quantiles, standard
deviations, and numeric Stats tables.  They do not replace {cmd:svyset}, and
{cmd:surveye} does not estimate design-based standard errors.  When {opt ci}
is supplied, frequency-weighted Wilson intervals use the weighted count.
Analytic- and probability-weighted intervals use a labelled Kish effective-
sample-size approximation;
they do not account for strata, primary sampling units, finite-population
corrections, or other complex-design features.  Importance weights have no
general sampling interpretation, so {cmd:surveye} automatically suppresses a
requested interval for {cmd:iweight} and displays an explanatory note.

{pstd}
Supplying any supported weight automatically adds a {bf:Weighted estimates}
switch to the dashboard.  It is on initially.  Turning it off recalculates
charts, comparisons, numeric summaries, and the optional profile table with
one unit per row; turning it on restores the supplied weight.  Raw sample
counts remain raw in either mode.  Both modes use the same exported analysis
sample, so the switch does not restore observations removed by {cmd:if},
{cmd:in}, or invalid, zero, or missing weights when the file was built.


{marker currency}{...}
{dlgtab:Local currency and USD}

{phang}
{opt usdvars(varlist)} identifies numeric, non-date monetary variables that
readers may display in local currency or US dollars.  It requires
{opt usdrate()}.

{phang}
{opt usdrate(#)} gives the fixed number of local-currency units per US dollar.
For example, with {cmd:usdrate(300)}, a stored local value of 30,000 is shown
as USD 100 when the USD switch is on.  The rate must be positive.

{phang}
{opt currency(code)} gives the local-currency code printed with converted
variables, for example {cmd:currency(LKR)}, {cmd:currency(KES)}, or
{cmd:currency(PKR)}.  When it is omitted, the label is {it:Local currency}.

{pmore}
The dashboard starts in local currency.  Its USD switch updates charts,
numeric Stats, and {opt mean}, {opt median}, or {opt sum} cells in the optional
profile table for variables named in {opt usdvars()}.  It does not change the
embedded source values.  SurvEye does not retrieve a current or historical
exchange rate; choose a rate appropriate to the survey reference period and
document it with {opt note()} or {opt source()}.

{phang2}{cmd:. surveye sales costs using "questionnaire.html", saving("financials.html") usdvars(sales costs) usdrate(300) currency(LKR) replace open}


{marker profiletable}{...}
{dlgtab:Side-by-side profile table}

{phang}
{opt tableby(varname)} supplies the grouping variable whose displayed levels
become table rows.  {opt tablevars(varlist)} supplies the indicator columns.
The two options are required together.  Variables used only in the table are
exported automatically and do not become chart cards unless selected normally.
The responsive table appears near the top of the dashboard, before the
detailed chart sections.

{phang}
{opt tablestats(spec)} chooses each indicator's statistic.  Give one entry per
{opt tablevars()} variable, in the same order, separated by {cmd:|}.  Allowed
entries are {cmd:auto}, {cmd:share}, {cmd:share:}{it:code}, {cmd:mean},
{cmd:median}, and {cmd:sum}.  {cmd:auto} uses the median for numeric
distribution variables and an affirmative share for other compatible
variables.  {cmd:share} also uses a recognized affirmative category;
{cmd:share:}{it:code} identifies the intended raw response code explicitly.
{cmd:mean}, {cmd:median}, and {cmd:sum} require numeric variables.  Omitting
{opt tablestats()} uses {cmd:auto} for every column.

{phang}
{opt tablelabels(labels)} overrides the indicator column headings.  Supply one
label per {opt tablevars()} variable, in the same order, separated by {cmd:|}.
Without this option, SurvEye uses each variable's available label from the
questionnaire or Stata metadata; the variable name is the fallback when that
label is empty.

{phang}
{opt tabletitle(text)} supplies the profile-table title.  The default is
{it:Summary table}.

{phang}
{opt tablesubtitle(text)} supplies a short explanation immediately below the
table title.

{phang}
{opt tabletotal(text)} changes the label of the all-group reference row, for
example {cmd:tabletotal("Sri Lanka (all surveyed locations)")}.  Every profile
table includes that reference; its default label is
{it:All filtered interviews}.  The table ignores only its own
{opt tableby()} dashboard filter,
so every grouping row and the reference remain visible for comparison;
selected grouping rows may be highlighted.  Every other active filter is
honored.  The reference, table rows, and cells also follow the current weight
and local-currency/USD switches.

{phang}
{opt tableweightlabel(text)} changes the weighted-total column heading, for
example {cmd:tableweightlabel("Est. firms")}.  Raw {it:n} is always shown.
The weighted total is the sum of the active Stata weights.  Interpret it
according to the supplied weight type; only an appropriate expansion weight
should be described as an estimated population count.  The column appears
only when a Stata weight was supplied and {bf:Weighted estimates} is on; it is
hidden in unweighted mode.  Its default heading is {it:Weighted total}.

{pmore}
Table shares, means, medians, sums, raw counts, and conditional weighted totals
recalculate immediately with the dashboard controls.  Use a concise set of
decision-relevant columns so the table remains readable on smaller screens.

{phang2}{cmd:. surveye women_led sales banked digital_channel using "questionnaire.html"}
{cmd:[pw=pop], saving("profile.html") filters(stratum owner_type) usdvars(sales)}
{cmd:usdrate(300) currency(LKR) tableby(stratum)}
{cmd:tablevars(women_led sales banked digital_channel)}
{cmd:tablestats("share:1|median|share:1|share:1")}
{cmd:tablelabels("Women-led|Median sales|Banked|Digital channel")}
{cmd:tabletitle("Stratum profile") tablesubtitle("Key indicators side by side")}
{cmd:tabletotal("Sri Lanka (all surveyed locations)") tableweightlabel("Est. firms")}
{cmd:replace open}


{marker ci}{...}
{dlgtab:Confidence intervals and numeric statistics}

{pstd}
Confidence intervals are off by default.  This keeps compact dashboards easy
to scan and avoids inferential marks that can be mistaken for ranges covering
part of a binary stacked bar.

{phang}
{opt ci} requests pointwise Wilson confidence intervals for ordinary
categorical and multiselect horizontal bars.  Binary yes/no cards,
answered/missing completion cards, and donuts never display confidence-
interval text or whiskers, even when {opt ci} is supplied.

{phang}
{opt level(#)} sets the requested interval's confidence level.  It requires
{opt ci}; the default with {opt ci} is 95, and the value must be greater than
50 and less than 100.

{pmore}
Unweighted requested intervals use the valid raw count.  Frequency-weighted
intervals use the weighted count.  Analytic- and probability-weighted intervals use a
Kish effective-sample-size approximation.  They are descriptive pointwise
intervals, not design-based survey estimates, and do not adjust for strata,
clusters, finite-population corrections, or other complex-design features.
Importance weights automatically suppress requested intervals because they
have no general sampling interpretation.

{pstd}
Each numeric card has {it:Distribution} and {it:Stats} tabs.  The distribution
includes every valid measurement on a regular numeric axis.  A dotted
{it:Mean + 3 SD} reference is shown only when the standard deviation is positive
and the reference lies strictly inside the plotted range.  The Stats tab
reports valid raw n, missing/excluded n, mean, standard deviation, minimum,
maximum, p25, median, p75, and the mean-plus-three-standard-deviations
reference.  It recalculates immediately whenever a dashboard filter changes,
including while the Stats tab is open.  Weighted dashboards identify these
statistics as descriptive weighted summaries and report the valid weighted
sum.  SurvEye does not classify or label observations as Tukey outliers.


{marker map}{...}
{dlgtab:GPS map}

{phang}
{opt latitude(varname)} and {opt longitude(varname)} request a Leaflet map.
Both variables must be numeric and both options must be supplied.

{phang}
{opt country(name_or_code)} is required for a GPS map.  Use a country name,
ISO-2 code, or ISO-3 code, such as {cmd:country(Kenya)} or {cmd:country(KEN)}.

{phang}
{opt boundaries(filename)} supplies a ZIP with a polygon shapefile
({cmd:.shp}, {cmd:.dbf}, and preferably {cmd:.prj}) for detailed boundaries.
Coordinates and boundaries must use WGS84 longitude/latitude.  Without this
option, a bundled country outline is used.  Country and Admin-2 lines are drawn
as WGS84 Leaflet rings aligned with the points and tiles; antimeridian
geometries are normalized to one longitude branch.

{phang}
{opt maplevel(country|admin2)} selects boundary detail.  The default is
{cmd:country} without {opt boundaries()} and {cmd:admin2} with a boundary ZIP.
{cmd:admin2} requires a compatible ZIP.

{phang}
{opt maptype(points|cluster|heat)} selects the point display.  The default is
{cmd:points}: every valid row receives its own circle marker and nearby points
are not collapsed.  Exact duplicate coordinates are separated slightly on
screen so every marker remains selectable; popups show the original coordinate.
Each point can receive keyboard focus and opens its localized popup with Enter
or Space.
{cmd:cluster} and {cmd:heat} are explicit aggregated alternatives.

{phang}
{opt basemap(google_hybrid|google_sat|google_road|osm)} chooses the initial
Leaflet base layer.  The default is {cmd:google_hybrid}.  The options follow
{cmd:esqc_gps}: Google Hybrid uses satellite imagery and labels,
{cmd:google_sat} uses satellite imagery, {cmd:google_road} uses the road map,
and {cmd:osm} uses OpenStreetMap.  The map layer control can switch among all
four after the file opens.

{pmore}
Leaflet, survey points, and boundary geometry are embedded in the dashboard.
Base-map tiles are fetched when the map opens, so a map-enabled dashboard needs
internet access to the selected provider.  The {cmd:esqc_gps}-compatible Google
choices use keyless compatibility tile endpoints; they are not an authenticated
Google Maps Platform integration, and their availability or access policy can
change.  Before distributing a dashboard, verify that the selected provider is
approved for the intended use and follow its current terms and attribution
rules.  Tile requests contain map coordinates, not other survey variables.

{phang}
{opt mapby(varname)} colors or groups the map by a variable with at most ten
observed categories after {opt missingcodes()} exclusions.  A point whose map
group is an excluded code remains visible in the default point color but is
not added to the legend.

{phang}
{opt maptitle(text)} replaces the default map title.


{dlgtab:Presentation}

{phang}
{opt uilanguage(auto|english|arabic|urdu)} selects the language of interface
controls, summaries, map text, chart descriptions, and empty-state messages.  Technical
parser warnings, diagnostics, and Stata console messages remain in English.  The
default is {cmd:auto}.  The aliases {cmd:en}, {cmd:ar}, and {cmd:ur} are
accepted.  Auto gives priority to a questionnaire declaration of Arabic
({cmd:ar}) or Urdu ({cmd:ur}).  Otherwise, predominantly Arabic-script
questionnaire text selects Arabic, with Urdu-specific characters selecting
Urdu; incidental Arabic text in an otherwise non-Arabic instrument does not
change the interface.  Other text selects English.  Questionnaire wording and user-supplied
titles, notes, sources, and messages are never translated.

{phang}
{opt direction(auto|ltr|rtl)} selects document and component direction.  The
default is {cmd:auto}, which follows the resolved interface language: Arabic
and Urdu use {cmd:rtl}, while English uses {cmd:ltr}.  An explicit {cmd:rtl} or
{cmd:ltr} overrides layout direction but does not translate text.  Thus,
{cmd:uilanguage(english) direction(auto)} stays left-to-right even for an
Arabic questionnaire.  The output
sets matching HTML {cmd:lang} and {cmd:dir} attributes for browsers and
assistive technology.  RTL mode mirrors navigation, controls, tables,
horizontal chart axes and direct labels, and Leaflet controls; it does not
merely align the surrounding text.

{phang}
{opt title(text)} and {opt subtitle(text)} set the dashboard heading.  The
questionnaire title is used by default.  A pair of asterisks marks emphasis:
{cmd:title("The shape of *informality*")} renders the marked words as a
cyan accent in the masthead, and marked words in {opt subtitle()} render in
bold.  Single asterisks pass through unchanged, and the marks never reach the
browser tab title.

{phang}
{opt byline(text)} signs the masthead with up to four parts separated by
{cmd:|} in the order label, name, role, and email:
{cmd:byline("Task Team Leader|A. Rehman|Economist|arehman@worldbank.org")}.
Any part may be left empty and the email becomes a mailto link.  The byline
follows World Bank task-attribution practice and prints with the dashboard.

{phang}
{opt theme(editorial|worldbank|clean|forest|dark)} selects the overall finish.
The default is {cmd:editorial}: a warm paper canvas, subtle cyan/gold glow,
World Bank role colors, serif heading hierarchy, rounded cards, shallow shadows,
and reduced-motion-safe subtle entrance transitions.  The preset is entirely
survey-agnostic and does not change questions, calculations, filters, or chart
selection.  Explicit {cmd:worldbank}, {cmd:clean}, {cmd:forest}, and {cmd:dark}
retain their earlier appearance unless an individual layer below is overridden.

{phang}
{opt background(auto|glow|paper|plain)} controls the page canvas.  {cmd:auto}
leaves the selected legacy theme unchanged.  The editorial default is
{cmd:glow}; it places restrained cyan and gold radial light over warm paper.

{phang}
{opt typography(auto|editorial|modern|system)} controls heading hierarchy.
{cmd:editorial} uses a serif display stack for headings and key figures while
retaining a highly legible sans-serif body.  No web-font request is made.

{phang}
{opt corners(auto|rounded|soft|square)} and
{opt shadow(auto|soft|lifted|none)} control card finishing independently of the
color theme.

{phang}
{opt motion(none|subtle|reveal)} controls entrance motion.  Both animated modes
use an intersection observer so sections animate only when first visible and
honor the browser's reduced-motion preference.  The editorial default is
{cmd:subtle}; legacy themes default to {cmd:none}.

{phang}
{opt pagewidth(#)} sets the maximum content width in pixels.  Use 0 to leave a
legacy theme unchanged, or a value from 960 through 2,000.  The editorial
default is 1,280 pixels.

{phang}
{opt density(compact|comfortable)} controls spacing.  The default,
{cmd:compact}, uses balanced rows of up to three panels, short charts, focused
labels, and a collapsed map summary.  Incomplete rows are repacked as equal
pairs or a full-width single panel, so card edges remain aligned without adding
page height.  {cmd:comfortable} uses a roomier two-column grid,
larger figures, and an initially open map.  Meanings and denominators do not
change.

{phang}
{opt logo(filename)} embeds a local PNG, JPEG, GIF, or SVG logo.

{phang}
{opt note(text)}, {opt source(text)}, and {opt disclaimer(text)} add context.
Document the universe, reference period, weighting, source, and disclosure
limitations.  Without {opt disclaimer()}, a conservative internal-working and
disclosure-review notice is shown.


{marker describe}{...}
{title:Questionnaire inspection}

{pstd}
{cmd:surveye describe} reads only the questionnaire and does not change
the dataset in memory.  {opt detail} displays numbered sections, chartable
variable names, possible filters, and possible GPS fields.  {opt strict}
promotes parser warnings to errors.  This is the fastest way to inspect an
unfamiliar, translated, legacy, or current Survey Solutions HTML file.


{marker demo}{...}
{title:Simulated preview}

{pstd}
{cmd:surveye demo} builds a dashboard without a dataset.  Every preview
is visibly marked {it:SIMULATED -- PREVIEW ONLY}.  {opt n(#)} sets the number
of simulated records (default 240; maximum 100,000), and {opt seed(#)} makes
the simulation reproducible.  {opt maxpanels(#)}, {opt ci}, and {opt level(#)}
work as described above.  Presentation options are
{opt uilanguage()}, {opt direction()}, {opt title()}, {opt subtitle()},
{opt logo()}, {opt theme()}, {opt density()}, {opt background()},
{opt typography()}, {opt corners()}, {opt shadow()}, {opt motion()},
{opt pagewidth()}, {opt note()}, {opt source()}, {opt disclaimer()}, and
{opt diagnostics()}.


{marker data}{...}
{title:Data rules and privacy}

{pstd}
The command works with one rectangular data file at a time.  Survey Solutions
rosters are exported separately; build one dashboard per roster level or merge
a carefully defined roster summary into the parent file.  An undefined join
can change denominators.

{pstd}
The dataset in memory is preserved.  Selected columns are sent as a temporary
UTF-8 raw-code CSV so questionnaire category text and order remain authoritative.
For {opt customvars()}, the wrapper deliberately sends the Stata variable label,
type/format, and applicable observed value-label text.

{pstd}
The HTML embeds selected analysis-level values needed for filtering and charting.
Text, picture, audio, linked text-list, and questionnaire-GPS completion items
are reduced to answered/not-answered flags instead of embedding original
contents.  A map embeds valid latitude and longitude so Leaflet can draw and
filter the display: six decimal places for {cmd:points}, four for
{cmd:cluster}, and three for {cmd:heat}.  Even reduced precision can identify
respondents or establishments.  Protect the HTML like the source data, review
disclosure risk, and do not publish row-level maps without authorization.
{cmd:cluster} and {cmd:heat} reduce precision and aggregate the display, but
they are not a substitute for a formal disclosure-control method.  The command
does not upload data.


{marker readertools}{...}
{title:Reader tools inside the dashboard}

{pstd}
Every dashboard built by version 2.2.0 or later includes reader-facing tools
that require no additional options and add no runtime network dependency:

{phang2}{bf:Theme switch.}  A control in the sticky top bar switches between
the built theme and the dark theme.  Charts, the profile table, and map
point colors re-skin immediately, and the choice is remembered across
reopenings when browser storage is available.{p_end}

{phang2}{bf:Copy view link.}  The control bar copies a link that reopens the
dashboard with the same filters, weighted/unweighted setting, currency
setting, and search query — convenient when circulating a subgroup view.{p_end}

{phang2}{bf:Download data (CSV).}  Exports the currently filtered interviews.
Categorical codes are written with their questionnaire labels, multi-select
answers are joined with semicolons, and the weight column is appended for
weighted dashboards.  Only values already embedded in the file are exported,
so the button adds no new disclosure surface; the privacy guidance above
applies unchanged.{p_end}

{phang2}{bf:Chart image download.}  Each panel has a small control that
saves the chart as a PNG named after the variable.{p_end}

{phang2}{bf:Navigation aids.}  {bf:Expand all} and {bf:Collapse all} in the
section navigation open or close every section; a floating button returns to
the top; a progress bar under the top bar shows reading position; pressing
{bf:/} focuses the indicator search and {bf:Esc} clears it.{p_end}


{marker examples}{...}
{title:Examples}

{pstd}{bf:1. Inspect a questionnaire}

{phang2}{cmd:. surveye describe using "English TRG_2025.html", detail}

{pstd}{bf:2. Build a complete compact dashboard}

{phang2}{cmd:. use "TRG_2025.dta", clear}

{phang2}{cmd:. surveye using "English TRG_2025.html", saving("TRG_dashboard.html") replace open}

{pstd}{bf:3. Select indicators and observations}

{phang2}{cmd:. surveye legalstatus employment sales if consent==1 using "questionnaire.html", saving("results.html") filters(region sector) highlights(employment sales) title("Enterprise survey results") replace}

{pstd}{bf:4. Add a logical expanded multiselect}

{phang2}{cmd:. surveye sales employment using "questionnaire.html", saving("services.html") questions("services_used") filters(region) replace}

{pstd}{bf:5. Add custom data variables with their Stata labels}

{phang2}{cmd:. label variable qc_score "Enumerator quality score"}

{phang2}{cmd:. surveye using "questionnaire.html", saving("quality.html") customvars(qc_score risk_band) addtosections("Interview quality: qc_score risk_band") histograms(qc_score) bars(risk_band) replace open}

{pstd}{bf:6. Put custom variables in existing and new sections}

{phang2}{cmd:. surveye sales using "questionnaire.html", saving("focused.html") customvars(qc_score risk_band) addtosections("3: qc_score|Quality checks: risk_band") replace}

{pstd}{bf:7. Combine related suffix variables in one figure}

{phang2}{cmd:. surveye srib8a srib8b srib8c using "questionnaire.html", saving("digital.html") vargroups("Digital channels:: srib8a srib8b srib8c") replace}

{pstd}{bf:8. Compare affirmative shares across locations}

{phang2}{cmd:. surveye srib8a srib8b srib8c using "questionnaire.html", saving("digital_by_city.html") compare(srib8a srib8b srib8c) compareby(city) comparelevels("01_Colombo|02_Kandy|03_Jaffna") comparetitle("Digital access by city") replace}

{pstd}{bf:9. Show integer distributions or force a continuous histogram}

{phang2}{cmd:. surveye employees visits revenue using "questionnaire.html", saving("numeric.html") discrete(employees visits) continuous(revenue) replace}

{pstd}{bf:10. Keep figures clean or request confidence intervals}

{phang2}{cmd:. surveye sector ownership using "questionnaire.html", saving("shares_clean.html") replace}

{phang2}{cmd:. surveye sector ownership using "questionnaire.html", saving("shares_90.html") ci level(90) replace}

{pstd}{bf:11. Apply native Stata weights}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [aw=wmedian], saving("analytic.html") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [fw=frequency], saving("frequency.html") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [iw=importance], saving("importance.html") note("Descriptive importance weights.") replace}

{phang2}{cmd:. surveye sector sales using "questionnaire.html" [pw=pop], saving("weighted.html") filters(region) note("Intervals use an effective-sample-size approximation.") replace}

{pmore}
Each weighted dashboard starts with {bf:Weighted estimates} on.  Readers may
turn it off to recalculate the displayed results without weights.

{pstd}{bf:12. Add a local-currency/USD switch}

{phang2}{cmd:. surveye sales costs profit using "questionnaire.html", saving("financials.html") usdvars(sales costs profit) usdrate(300) currency(LKR) note("USD values use 300 LKR per USD.") replace open}

{pstd}{bf:13. Add a live stratum profile table}

{phang2}{cmd:. surveye women_led sales banked digital_channel using "questionnaire.html"}
{cmd:[pw=pop], saving("profile.html") filters(stratum owner_type) usdvars(sales)}
{cmd:usdrate(300) currency(LKR) tableby(stratum)}
{cmd:tablevars(women_led sales banked digital_channel)}
{cmd:tablestats("share:1|median|share:1|share:1")}
{cmd:tablelabels("Women-led|Median sales|Banked|Digital channel")}
{cmd:tabletitle("Stratum profile") tablesubtitle("Key indicators side by side")}
{cmd:tabletotal("Sri Lanka (all surveyed locations)") tableweightlabel("Est. firms")}
{cmd:replace open}

{pstd}{bf:14. Build an Arabic right-to-left dashboard}

{phang2}{cmd:. surveye using "questionnaire_ar.html", saving("dashboard_ar.html") uilanguage(ar) direction(auto) replace open}

{pstd}{bf:15. Build an Urdu right-to-left dashboard}

{phang2}{cmd:. surveye using "questionnaire_ur.html", saving("dashboard_ur.html") uilanguage(urdu) direction(rtl) replace open}

{pstd}{bf:16. Show every GPS record over Google Hybrid}

{phang2}{cmd:. surveye sector sales using "questionnaire.html", saving("mapped.html")}
{cmd:latitude(gps_latitude) longitude(gps_longitude) country(KEN)}
{cmd:boundaries("World Bank Official Boundaries - Admin 2.zip") maplevel(admin2)}
{cmd:maptype(points) basemap(google_hybrid) mapby(sector)}
{cmd:maptitle("Interview locations") replace open}

{pstd}{bf:17. Use OpenStreetMap or an aggregated point display}

{phang2}{cmd:. surveye sector using "questionnaire.html", saving("clustered.html") latitude(gps_latitude) longitude(gps_longitude) country(KEN) maptype(cluster) basemap(osm) replace}

{pstd}{bf:18. Preview a translated questionnaire}

{phang2}{cmd:. surveye demo using "siNhl Global_informal2026.html", saving("sinhala_preview.html") n(250) seed(42) theme(clean) replace open}


{marker results}{...}
{title:Stored results}

{pstd}
On success, {cmd:surveye} stores the following in {cmd:r()} when supplied
by the engine:

{synoptset 22 tabbed}{...}
{synopt:{cmd:r(success)}}1{p_end}
{synopt:{cmd:r(message)}}engine message{p_end}
{synopt:{cmd:r(title)}}dashboard or questionnaire title{p_end}
{synopt:{cmd:r(N)}}observations in the dashboard{p_end}
{synopt:{cmd:r(sample_N)}}observations exported after restrictions{p_end}
{synopt:{cmd:r(k_charted)}}charted indicators{p_end}
{synopt:{cmd:r(k_skipped)}}skipped indicators{p_end}
{synopt:{cmd:r(k_sections)}}dashboard sections{p_end}
{synopt:{cmd:r(k_filters)}}filters{p_end}
{synopt:{cmd:r(k_questions)}}parsed questions in {cmd:describe} mode{p_end}
{synopt:{cmd:r(chartvars)}}charted variable names{p_end}
{synopt:{cmd:r(skippedvars)}}skipped variable names{p_end}
{synopt:{cmd:r(filters)}}filter variable names{p_end}
{synopt:{cmd:r(sections)}}section identifiers or, in {cmd:describe}, numbered titles{p_end}
{synopt:{cmd:r(warnings)}}engine warning count{p_end}
{synopt:{cmd:r(weighted)}}1 if weighted, 0 otherwise{p_end}
{synopt:{cmd:r(has_map)}}1 if a map was created{p_end}
{synopt:{cmd:r(map_N)}}valid mapped observations{p_end}
{synopt:{cmd:r(map_missing)}}missing or out-of-range coordinate pairs{p_end}
{synopt:{cmd:r(map_outside)}}valid points outside the selected boundary{p_end}
{synopt:{cmd:r(engine_version)}}Java engine version{p_end}
{synopt:{cmd:r(output)}}dashboard filename{p_end}
{synopt:{cmd:r(filename)}}alias for {cmd:r(output)}{p_end}
{synopt:{cmd:r(questionnaire)}}questionnaire filename{p_end}
{synopt:{cmd:r(filter_candidates)}}possible filters from {cmd:describe}{p_end}
{synopt:{cmd:r(gps_candidates)}}possible GPS fields from {cmd:describe}{p_end}
{synopt:{cmd:r(package_version)}}Stata package version{p_end}


{marker troubleshooting}{...}
{title:Troubleshooting}

{pstd}
If the Java engine is missing or Stata reports {cmd:r(5100)}, verify the package:

{phang2}{cmd:. which surveye}

{phang2}{cmd:. findfile surveye_2_2_0.jar}

{phang2}{cmd:. java query}

{pstd}
Reinstall the complete package if the wrapper and release-specific JAR do not
resolve together, then type {cmd:discard} or restart Stata.  The command prints
the JAR path and preserves Stata's Java diagnostic when the engine cannot load.

{pstd}
If parsing or rendering fails, rerun with {opt diagnostics(filename)} and first
try {cmd:surveye describe ..., detail}.  A file with no recognizable
Survey Solutions sections or variables is rejected rather than producing an
empty dashboard.

{pstd}
If a map shows points and boundary lines but no background imagery, check the
internet connection, firewall, and access to the selected tile provider.  Try
{cmd:basemap(osm)} to distinguish a provider-specific problem.  The rest of the
dashboard remains usable when tiles are unavailable.


{marker author}{...}
{title:Author}

{pstd}
Attique Ur Rehman, Enterprise Analysis Unit, World Bank

{pstd}
{browse "https://github.com/arehman10/SurvEye":SurvEye repository}  {c |}
{browse "https://github.com/arehman10/SurvEye/issues":Support and bug reports}

{pstd}
Thanks to {browse "https://github.com/fahad-mirza":Fahad Mirza}
(World Bank / CERP) for his insights and guidance, and for his self-contained
Stata tooling, which helped shape the design of this package.

{pstd}
This software is provided under the MIT License.  It is an independent utility;
the views and dashboards produced with it do not necessarily represent the
views of the World Bank, its Board of Executive Directors, or the governments
they represent.  Survey Solutions is a World Bank data-collection platform.


{title:Also see}

{pstd}
Online: {browse "https://docs.mysurvey.solutions/headquarters/api/api-r-package/":Survey Solutions API documentation}{p_end}
{pstd}
Help:  {helpb suso}, {helpb javacall}, {helpb import}, {helpb shell}{p_end}
