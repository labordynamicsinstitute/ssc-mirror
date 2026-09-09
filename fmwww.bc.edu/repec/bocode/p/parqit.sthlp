{smcl}
{* *! version 0.1.37 07sep2026}{...}
{viewerdialog "parqit use" "dialog parqit_read"}{...}
{viewerdialog "parqit describe" "dialog parqit_explore"}{...}
{viewerdialog "parqit summarize" "dialog parqit_stats"}{...}
{viewerdialog "parqit keep if/in, sample" "dialog parqit_filter"}{...}
{viewerdialog "parqit keep/drop/order/sort/rename" "dialog parqit_vars"}{...}
{viewerdialog "parqit generate" "dialog parqit_gen"}{...}
{viewerdialog "parqit collapse/pivot/contract/reshape" "dialog parqit_pivot"}{...}
{viewerdialog "parqit merge/append/joinby" "dialog parqit_combine"}{...}
{viewerdialog "parqit collect/save" "dialog parqit_write"}{...}
{viewerdialog "parqit view/sql/set" "dialog parqit_views"}{...}
{vieweralsosee "[PARQIT] parqit_technical" "help parqit_technical"}{...}
{vieweralsosee "[D] use" "help use"}{...}
{vieweralsosee "[D] save" "help save"}{...}
{vieweralsosee "[D] collapse" "help collapse"}{...}
{vieweralsosee "[D] merge" "help merge"}{...}
{viewerjumpto "Syntax" "parqit##syntax"}{...}
{viewerjumpto "Menu" "parqit##menu"}{...}
{viewerjumpto "Description" "parqit##description"}{...}
{viewerjumpto "Quick start" "parqit##quickstart"}{...}
{viewerjumpto "The view at a glance" "parqit##map"}{...}
{viewerjumpto "The lazy view" "parqit##lazy"}{...}
{viewerjumpto "Verbs" "parqit##verbs"}{...}
{viewerjumpto "Materialisers" "parqit##materialisers"}{...}
{viewerjumpto "Exploring a view" "parqit##explore"}{...}
{viewerjumpto "Expressions" "parqit##expressions"}{...}
{viewerjumpto "Settings, raw SQL and diagnostics" "parqit##options"}{...}
{viewerjumpto "Examples" "parqit##examples"}{...}
{viewerjumpto "Limitations" "parqit##limitations"}{...}
{viewerjumpto "Stored results" "parqit##results"}{...}
{viewerjumpto "Authors" "parqit##author"}{...}
{viewerjumpto "Acknowledgements" "parqit##acknowledgements"}{...}
{title:Title}

{phang}
{bf:parqit} {hline 2} a grammar of data manipulation for Stata, backed by
Parquet on an embedded DuckDB engine


{marker syntax}{...}
{title:Syntax}

{pstd}Type subcommand names as shown; {cmd:generate} is also accepted for
{cmd:gen}. Other native Stata abbreviations and options are not implied by
the shared vocabulary. The syntax below defines the supported surface.

{pstd}Open a lazy view (no result rows are loaded into Stata) or read a file
into memory:

{p 8 16 2}
{cmd:parqit use} [{it:varlist-patterns}] {cmd:using} {it:filename} [{cmd:,} {opt clear} {opt n:ame(viewname)} {opt relax:ed} {opt enc:oding(name)}]

{p 8 16 2}
{cmd:parqit use} {it:filename} [{cmd:,} {opt clear} {opt n:ame(viewname)} {opt relax:ed} {opt enc:oding(name)}]

{pstd}The second form is the first without a {it:varlist}: {cmd:using} may be
omitted only when no variable list is given, and the two forms are otherwise
identical — {opt clear} reads into memory, its absence opens a lazy view.

{pstd}{it:filename} may be a Parquet file, a glob such as {it:data_*.parquet}
(wildcards are {cmd:*} and {cmd:?}; a {cmd:[} is a literal character, and a
filename that exists is always read as itself, never as a pattern),
a Hive-partitioned directory, a delimited-text file ({cmd:.csv}, {cmd:.tsv},
{cmd:.txt} or {cmd:.tab}), or a Stata {cmd:.dta} / Excel {cmd:.xls}/{cmd:.xlsx} file — see
{help parqit_technical##formats:Input formats}. Without {opt clear} a lazy view opens over
the file(s), replaces any existing view with the same name and becomes current;
the current in-memory dataset is unchanged. With {opt clear} the whole result is
read into memory atomically and every open view is left untouched; {opt name()}
is then invalid.
{opt relaxed} reads a glob whose files have {it:different} schemas by union of
column names (columns absent from a file arrive missing); without it a schema
mismatch across the matched files is a loud error. {opt encoding(name)} names
the legacy 8-bit code page for a {cmd:.dta}/Excel source that must be bridged to
Parquet (see {help parqit_technical##formats:Input formats}); it is ignored, with a note,
for a Parquet/CSV source (read as UTF-8).

{pstd}Verbs on the open view (all lazy):

{p 8 16 2}{cmd:parqit keep} {it:varlist} | {cmd:parqit keep if} {it:exp} | {cmd:parqit keep in} {it:f}[{cmd:/}{it:l}]{p_end}
{p 8 16 2}{cmd:parqit drop} {it:varlist} | {cmd:parqit drop if} {it:exp} | {cmd:parqit drop in} {it:f}[{cmd:/}{it:l}]{p_end}
{p 8 16 2}{cmd:parqit gen} [{it:type}] {it:newvar} {cmd:=} {it:exp} [{cmd:if} {it:exp}]{p_end}
{p 8 16 2}{cmd:parqit replace} {it:var} {cmd:=} {it:exp} [{cmd:if} {it:exp}]{p_end}
{p 8 16 2}{cmd:parqit egen} [{it:type}] {it:newvar} {cmd:=} {it:fcn}{cmd:(}{it:exp}{cmd:)} [{cmd:,} {opt by(varlist)}]{p_end}
{p 8 16 2}{cmd:parqit rename} {it:old} {it:new}{p_end}
{p 8 16 2}{cmd:parqit rename} {cmd:(}{it:oldlist}{cmd:)} {cmd:(}{it:newlist}{cmd:)}{p_end}
{p 8 16 2}{cmd:parqit order} {it:varlist}{p_end}
{p 8 16 2}{cmd:parqit sort} {it:varlist} | {cmd:parqit gsort} [{cmd:+}|{cmd:-}]{it:varname} ...{p_end}
{p 8 16 2}{cmd:parqit collapse} {cmd:(}{it:stat}{cmd:)} [{it:tgt}{cmd:=}]{it:src} ... [{cmd:,} {opt by(varlist)}]{p_end}
{p 8 16 2}{cmd:parqit contract} {it:varlist} [{cmd:,} {opt f:req(newvar)}]{p_end}
{p 8 16 2}{cmd:parqit duplicates drop} [{it:varlist}{cmd:,} {opt force}]{p_end}
{p 8 16 2}{cmd:parqit sample} {it:#} [{cmd:,} {opt c:ount} {opt seed(#)}]{p_end}
{p 8 16 2}{cmd:parqit reshape} {cmd:long}|{cmd:wide} {it:stubs}{cmd:,} {opt i(varlist)} {opt j(name)}{p_end}
{p 8 16 2}{cmd:parqit pivot} {cmd:(}{it:stat}{cmd:)} [{it:tgt}{cmd:=}]{it:src} ... {cmd:,} {opt r:ows(varlist)} {opt c:ols(varname)}{p_end}
{p 8 16 2}{cmd:parqit merge} {cmd:1:1}|{cmd:m:1}|{cmd:1:m} {it:keys} {cmd:using} {it:source}
[{cmd:,} {opt keep(spec)} {opt keepus:ing(varlist)} {opt gen:erate(newvar)}
{opt nogen:erate} {opt enc:oding(name)}]{p_end}
{p 8 16 2}{cmd:parqit append using} {it:source} [{it:source} ...] [{cmd:,} {opt gen:erate(newvar)} {opt enc:oding(name)}]{p_end}
{p 8 16 2}{cmd:parqit joinby} {it:keys} {cmd:using} {it:source} [{cmd:,} {opt enc:oding(name)}]{p_end}

{p 8 16 2}{cmd:parqit mergein} {cmd:1:1}|{cmd:m:1}|{cmd:1:m}|{cmd:m:m} {it:keys} {cmd:using} {it:file} [{cmd:,} {it:merge_options}]{p_end}
{p 8 16 2}{cmd:parqit appendin using} {it:file} [{cmd:,} {opt keep(varlist)} {opt force}]{space 3}({opt keep()}
names variables {it:of the file}, as in native {helpb append}){p_end}

{pstd}{cmd:mergein}/{cmd:appendin} join the data {it:already in Stata's memory}
with a disk {it:file} via a {it:native} {help merge} / {help append}: the
in-memory dataset stays put (no DuckDB round-trip), and parqit reads only the
needed columns of the disk side. This is the fast route when the disk side is a
{it:small lookup}; for big-on-big use the out-of-core
{cmd:parqit use} + {cmd:parqit merge} path instead. {it:merge_options} belong to
{cmd:mergein} alone and are the native ones ({opt keepus:ing()}, {opt keep()},
{opt gen:erate()}, {opt nogen:erate},
{opt update}, {opt replace}, {opt assert()}, {opt force}, {opt nol:abel},
{opt non:otes}, {opt norep:ort}), forwarded verbatim to native {helpb merge};
{cmd:appendin} forwards {opt keep()} and {opt force} to native {helpb append}.
Lazy {cmd:parqit merge} is not a wrapper around native {cmd:merge} and takes
only the options shown in its own syntax line; any other native
{cmd:merge} option is rejected.

{pstd}where each {it:source} is any supported disk input (Parquet file, glob or
Hive directory; delimited text; Stata; or Excel) or
{cmd:view:}{it:viewname} — another open view whose plan is embedded without
materialising either view. Non-Parquet file sources follow the adapter rules
in {help parqit_technical##formats:Input formats}.

{pstd}Materialisers and engine-side result commands (these execute against the
pipeline; only {cmd:collect}/{cmd:save} materialise its full result):

{p 8 16 2}{cmd:parqit collect} [{cmd:,} {opt clear}]{space 8}stream the result into memory (atomically){p_end}
{p 8 16 2}{cmd:parqit save} {it:filename} [{cmd:,} {opt replace} {opt d:ata}
{opt comp:ression(codec)} {opt compression_level(#)} {opt part:ition_by(varlist)}
{opt partitions(replace|append)} {opt c:hunk(#)} {opt enc:oding(name)} {opt copy:source}]{p_end}
{p 8 16 2}{cmd:parqit head} [{it:#}]{p_end}
{p 8 16 2}{cmd:parqit summarize} [{it:varlist}] [{cmd:,} {opt d:etail}]{p_end}
{p 8 16 2}{cmd:parqit tabulate} {it:varname} [{it:varname2}] [{cmd:,} {opt m:issing} {opt row} {opt col}
{opt nol:abel}]{space 2}({opt row}/{opt col} apply to the two-way form; the one-way form
ignores them; {opt nolabel} shows codes instead of value labels){p_end}
{p 8 16 2}{cmd:parqit misstable} [{cmd:summarize}|{cmd:patterns}] [{it:varlist}]{p_end}
{p 8 16 2}{cmd:parqit levelsof} {it:varname} [{cmd:,} {opt l:imit(#)}]{p_end}
{p 8 16 2}{cmd:parqit count} [{cmd:if} {it:exp}]{p_end}
{p 8 16 2}{cmd:parqit list} [{it:varlist}] [{cmd:if} {it:exp}] [{cmd:in} {it:f}[{cmd:/}{it:l}]]{p_end}
{p 8 16 2}{cmd:parqit ds} | {cmd:parqit lookfor} {it:word} [{it:word} ...]{p_end}
{p 8 16 2}{cmd:parqit codebook} [{it:varlist}]{p_end}
{p 8 16 2}{cmd:parqit distinct} [{it:varlist}] [{cmd:,} {opt j:oint}]{p_end}
{p 8 16 2}{cmd:parqit duplicates} {cmd:report}|{cmd:list} {it:varlist} [{cmd:,} {opt l:imit(#)}]{p_end}
{p 8 16 2}{cmd:parqit tabstat} {it:varlist} [{cmd:,} {opt s:tatistics(stats)} {opt by(varname)} {opt save}]{p_end}
{p 8 16 2}{cmd:parqit correlate} {it:varlist}{space 8}(listwise; takes no options){p_end}
{p 8 16 2}{cmd:parqit pwcorr} {it:varlist} [{cmd:,} {opt obs} {opt sig}]{p_end}
{p 8 16 2}{cmd:parqit histogram} {it:varname} [{cmd:,} {opt b:ins(#)} {opt nodraw}]{p_end}
{p 8 16 2}{cmd:parqit describe} [{it:parquet_source}] | {cmd:parqit glimpse} [{it:parquet_source}]{p_end}

{pstd}Escape hatches and introspection:

{p 8 16 2}{cmd:parqit sql} {cmd:"}{it:DuckDB SQL}{cmd:"} [{cmd:,} {opt clear} {opt n:ame(viewname)}]{p_end}
{p 8 16 2}{cmd:parqit query} {cmd:"}{it:SQL fragment}{cmd:"}{p_end}
{p 8 16 2}{cmd:parqit show} | {cmd:parqit explain}{p_end}
{p 8 16 2}{cmd:parqit view} [{it:viewname}[{cmd::} {it:parqit_command}]] | {cmd:parqit views}{p_end}
{p 8 16 2}{cmd:parqit open _data} [{cmd:,} {opt n:ame(viewname)} {opt enc:oding(name)}]
| {cmd:parqit close} [{it:viewname}|{cmd:_all}] | {cmd:parqit path} {it:filename}{p_end}
{p 8 16 2}{cmd:parqit set} {cmd:statamissing}|{cmd:threads}|{cmd:memory_limit}|{cmd:tempdir} {it:value}{p_end}
{p 8 16 2}{cmd:parqit version}{space 4}(plugin + engine versions){p_end}
{p 8 16 2}{cmd:parqit selftest}{space 3}(end-to-end engine and codec check, useful on new installs/HPC nodes){p_end}
{p 8 16 2}{cmd:parqit menu}{space 8}(add parqit to the {bf:User} menu — GUI Stata only){p_end}

{pstd}For {cmd:parqit sql}, trailing statement terminators ({cmd:;}) are
optional and ignored; semicolons inside the SQL text are preserved.{p_end}

{pstd}{bf:Point and click.} The dialogs cover every public subcommand listed
above (apart from {cmd:parqit menu}, which installs the menu itself); see
{help parqit##menu:Menu}.


{marker menu}{...}
{title:Menu}

{pstd}In GUI Stata, {cmd:parqit menu} adds one submenu to Stata's {bf:User}
menu for the session; add that line to your {help profile}.do to keep it
across sessions. Repeating {cmd:parqit menu} is idempotent. If another command
explicitly runs {cmd:window menu clear}, Stata removes {it:every} package's
menu additions and exposes no package-local query/removal API; restore parqit's
entry with {cmd:global PARQIT_MENU_ON} followed by {cmd:parqit menu}. parqit
never calls {cmd:window menu clear} itself. Each entry opens a dialog that
builds and runs an ordinary {cmd:parqit} command, echoed to the Results and
Review windows like a typed
command, so every click is reproducible in a do-file. The dialogs are also
listed in the Viewer's {bf:Dialog} menu of this help file, and each can be
launched directly with {cmd:db} {it:name}.

{phang2}{bf:User > parqit > Read data (lazy view or into memory)...}{p_end}
{p 12 12 2}({cmd:db parqit_read}) {cmd:use} — a lazy view, or the data into
memory with {opt clear} — {cmd:open _data}, and {cmd:path}; {bf:Populate}
lists the variables recorded in the Parquet footer of the source, and
{bf:Describe} runs {cmd:describe} on it. These two footer-inspection buttons
are disabled for recognized delimited-text, Stata and Excel inputs; those
sources can still be opened, and variable names can be typed.{p_end}

{phang2}{bf:User > parqit > Describe and explore data...}{p_end}
{p 12 12 2}({cmd:db parqit_explore}) {cmd:describe}/{cmd:glimpse} of the view
or of a file, {cmd:ds}, {cmd:lookfor}, {cmd:codebook}, {cmd:head}, {cmd:list},
{cmd:count}, {cmd:misstable} [{cmd:patterns}], {cmd:levelsof}, {cmd:distinct}
and {cmd:duplicates report}/{cmd:list}: one list of operations, every one an
engine-side query.{p_end}

{phang2}{bf:User > parqit > Summary statistics, tables, and correlations...}{p_end}
{p 12 12 2}({cmd:db parqit_stats}) {cmd:summarize} [{opt detail}],
{cmd:tabulate} one- and two-way, {cmd:tabstat} with the statistics chosen by
check boxes, {opt by()} and {opt save}, {cmd:correlate}/{cmd:pwcorr} and
{cmd:histogram}. Tabulation has separate row and optional column fields,
{opt nolabel} for numeric codes, and row/column percentages only when the
column field is filled. Calculation pickers show numeric view variables;
the tabulation and {opt by()} pickers also show strings. Tooltips explain
the group/bin limits and that {cmd:tabstat, save} returns matrices.{p_end}

{phang2}{bf:User > parqit > Keep or drop observations, or draw a sample...}{p_end}
{p 12 12 2}({cmd:db parqit_filter}) {cmd:keep if}, {cmd:drop if}, {cmd:keep in}, {cmd:drop in}
({cmd:f}, {cmd:l} and negative bounds accepted) and {cmd:sample}; the
{bf:Create...} button opens Stata's expression builder.{p_end}

{phang2}{bf:User > parqit > Keep, drop, order, sort, or rename variables...}{p_end}
{p 12 12 2}({cmd:db parqit_vars}) {cmd:keep}, {cmd:drop}, {cmd:order},
{cmd:sort}, {cmd:gsort}, {cmd:rename (oldlist) (newlist)} and
{cmd:duplicates drop}.{p_end}

{phang2}{bf:User > parqit > Create or change variables...}{p_end}
{p 12 12 2}({cmd:db parqit_gen}) {cmd:gen} (with a storage type and an
{cmd:if} qualifier), {cmd:egen} (function and {opt by()}) and
{cmd:replace}.{p_end}

{phang2}{bf:User > parqit > Collapse, contract, pivot table, or reshape...}{p_end}
{p 12 12 2}({cmd:db parqit_pivot}) {cmd:collapse} and {cmd:pivot} share two
statistic rows plus free additional specifications; {cmd:contract};
{cmd:reshape long}|{cmd:wide}.{p_end}

{phang2}{bf:User > parqit > Combine datasets (merge, append, joinby)...}{p_end}
{p 12 12 2}({cmd:db parqit_combine}) lazy {cmd:merge}, {cmd:append} (several
sources) and {cmd:joinby} over files, globs, Hive directories or
{cmd:view:}{it:name}; native {cmd:mergein}/{cmd:appendin} for data already
in memory, with the native merge options on the {bf:Options} tab. The
additional-sources field is raw Stata source-list syntax: compound-quote each
path that contains spaces or commas.{p_end}

{phang2}{bf:User > parqit > Save as Parquet or collect into memory...}{p_end}
{p 12 12 2}({cmd:db parqit_write}) three explicit choices: save the selected
view to Parquet (the initial choice), save Stata memory with {opt data}, or
{cmd:collect} [{opt clear}]. View save and collect use
{cmd:parqit view} {it:name}{cmd::} to name the view shown in the context line;
closing it cannot silently redirect a save to memory. Refresh after switching
views to select a different target. Saving offers
{opt replace} (an existing file asks first, as in Stata's save dialog),
{opt compression()}, {opt compression_level()}, {opt partition_by()},
{opt partitions()}, {opt chunk()}, {opt encoding()}, {opt data} and {opt copysource};
{bf:Populate} lists variables from the view, or from the dataset in memory
when {opt data} is selected.{p_end}

{phang2}{bf:User > parqit > Views, SQL, and engine settings...}{p_end}
{p 12 12 2}({cmd:db parqit_views}) buttons that report on the current view at
once ({cmd:views}, {cmd:show}, {cmd:explain}, {cmd:describe}, {cmd:ds},
{cmd:version}, {cmd:selftest}); the actions {cmd:view}, {cmd:close},
{cmd:view} {it:name}{cmd::} {it:command}, {cmd:sql}, {cmd:query} and the four
{cmd:set} options.{p_end}

{phang2}{bf:User > parqit > Version}, {bf:Self-test}, {bf:Help on parqit}, {bf:Technical reference}{p_end}
{p 12 12 2}run {cmd:parqit version}, {cmd:parqit selftest} and
{cmd:help parqit} and {cmd:help parqit_technical} directly.{p_end}

{pstd}Conventions shared by the dialogs, following Stata's own: a
context line identifies the view or Stata memory. {bf:Refresh} updates that
context and the relevant variable pickers after a view switch; the write dialog
uses the selected view shown there. Context updates are queued until Stata is
ready and preserve the existing {cmd:r()} results. Help buttons open the relevant
manual section. A
{bf:Populate} button fills the variable pickers on demand from the current
view, from the dataset in memory when the write dialog selects {opt data}, or
from the Parquet footer of the file named in the dialog, exactly as Stata's
{cmd:use}, {cmd:describe} and {cmd:merge} dialogs populate from a dataset on
disk (the pickers are editable, so names may also be typed); the
{bf:Create...} buttons open Stata's expression builder, whose variable list is
that of the data in memory, so type the view's variable names into the
expression; a dialog remembers the last settings submitted with {bf:OK} or
{bf:Submit} for the session ({bf:Cancel} discards changes), and the {bf:R}
button resets them.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:parqit} reads, writes, joins and manipulates columnar Parquet data with
ordinary Stata verbs that run {it:out of core} on an embedded
{browse "https://duckdb.org":DuckDB} engine. It is dbplyr's architecture
with Stata's vocabulary: verbs are lazy and build a logical plan; the plan
compiles to a SQL query; the engine scans files directly and can spill
intermediate results to a temporary directory for supported operations. The
pipeline result enters Stata's current dataset only when collected, or it can
be written straight back to Parquet without loading that result into the
current dataset.

{pstd}
The one idea to internalise: {bf:mutation verbs build a plan rather than materialising their result}.
A view is a plan — "the current dataset", except
that it lives on disk and may be far larger than memory. Opening a view probes
its schema. Verbs validate their names and stated contracts; commands such as
{cmd:keep}, {cmd:gen} and {cmd:collapse} also bind-check their candidate SQL.
Contract-sensitive verbs may run validation queries (for example merge-key uniqueness, reshape
cell uniqueness or pivot column discovery). These checks do not load the result
into Stata. {cmd:parqit collect} and {cmd:parqit save} execute the full result
plan. Projection pushdown can avoid reading unused columns; filter pushdown
can skip Parquet row groups whose statistics rule out a match. Execution may
also need validation, sizing and output-verification queries. The whole
{help parqit##explore:exploration family} ({cmd:describe}, {cmd:head},
{cmd:summarize}, {cmd:tabulate}, {cmd:codebook}, {cmd:misstable}, …) is
computed by separate engine-side queries too, so a file can be profiled without
replacing or modifying the current dataset — explore first, load last. See
{help parqit##lazy:The lazy view}.

{pstd}{bf:Why this matters for large data.} Keep the worker-level archive on
disk, build a firm-year table with filters, derived variables and aggregation,
join it to another view, and collect only the final research sample. Stata
does not need room for the source archive or each intermediate table. When even
the final table is too large, {cmd:parqit save} completes the transformation
directly to Parquet. Named views let several source plans coexist alongside
the dataset already in Stata, without loading a separate full copy of each
source. This moves the memory requirement from {it:the whole input} to
{it:the result you choose to collect}, plus execution buffers and scratch space.

{pstd}
Stata metadata survives: variable labels, value labels, notes, display
formats, characteristics and original column names are stored in standard
Parquet key-value metadata under a {cmd:parqit.*} namespace and restored on
read, while the file remains plain Parquet for pandas, polars, R and Spark.

{pstd}
StataNow (Stata 19.5) ships a native {cmd:import parquet} that reads a Parquet
file into memory ({bf:File > Import > Parquet data}). {cmd:parqit} is
complementary to it, not a replacement: its contribution is the lazy verb
grammar that filters, derives, aggregates and joins data far larger than
memory before anything is loaded, the Parquet writer ({cmd:parqit save}) and
the Stata-metadata round-trip. When reading a whole file into memory is all
that is needed, either command serves. {cmd:parqit}'s menu and dialogs live
under {bf:User > parqit} and never alter Stata's own menus.

{pstd}
This entry is the user manual. The contracts behind it — the metadata layout
in Parquet, the input adapters and code pages, the type mapping, atomicity
and locks, the expression dialect, performance tips and the complete list of
limitations — are in {help parqit_technical:the technical reference}. Consult
it when choosing resource limits, working with unusual types or assessing
reproducibility.


{marker quickstart}{...}
{title:Quick start}

{pstd}Explore first, load last. Open a file as a lazy view, look at it with
engine-side commands, build the pipeline with ordinary verbs, and materialise
only the result:

{phang2}{cmd:. parqit describe /data/big.parquet}{space 10}({it:rows, columns, types: the footer only}){p_end}
{phang2}{cmd:. parqit use using /data/big.parquet}{space 8}({it:a lazy view; no result rows loaded}){p_end}
{phang2}{cmd:. parqit summarize wage age}{space 17}({it:engine-side; the dataset in memory is unchanged}){p_end}
{phang2}{cmd:. parqit keep if year >= 2019 & !missing(wage)}{p_end}
{phang2}{cmd:. parqit gen double lwage = ln(wage)}{p_end}
{phang2}{cmd:. parqit collapse (mean) lwage (count) n=lwage, by(firm year)}{p_end}
{phang2}{cmd:. parqit show}{space 30}({it:the one query the plan compiles to}){p_end}
{phang2}{cmd:. parqit collect, clear}{space 20}({it:only the result enters memory, atomically}){p_end}

{pstd}When the result should stay on disk, replace the last line with
{cmd:parqit save result.parquet, replace}: the pipeline runs and writes Parquet
without loading the result into the current dataset. {cmd:parqit close}
discards the view. Files written by parqit keep variable and value labels,
notes, formats and characteristics, and stay plain Parquet for other tools.
Two runnable courses ship with the package, {cmd:parqit_basics.do} and
{cmd:parqit_tour.do} (see {help parqit##examples:Examples}).

{pstd}Three rules of thumb: put {cmd:keep}/{cmd:keep if} early so the engine
reads less; never expect a lazy verb to change the data in memory (only
{cmd:collect} does, and only with a complete result); and read
{help parqit##expressions:Expressions} once for the missing-value rules:
under the default SQL semantics a numeric
comparison with a nonmissing constant is unknown when the variable is missing,
so {cmd:keep if x > 5} drops a missing
{cmd:x}, where native keeps it ({cmd:parqit set statamissing on} restores
Stata's rule).


{marker map}{...}
{title:The view at a glance}

{pstd}
A parqit session has four moves: {bf:open} a view, {bf:shape} it with lazy
verbs, {bf:look} at it engine-side, and {bf:land} the result. Only the last
move materialises the full pipeline result. Opening may create an input bridge;
exploration may use scratch data. Lazy verbs change the {it:plan}, and the
current Stata dataset stays unchanged until an explicit collection.

   {c TLC}{c -} {bf:1  OPEN} {c -} start a view {c -} {help parqit##lazy:[more]}
   {c |}
   {c |}{space 4}{cmd:parqit use} {it:file}{space 11}a Parquet file, glob or Hive directory,
   {c |}{space 30}or {cmd:.csv} {cmd:.tsv} {cmd:.txt} {cmd:.tab} {cmd:.dta} {cmd:.xls} {cmd:.xlsx}
   {c |}{space 4}{cmd:parqit open _data}{space 9}the dataset already in Stata's memory
   {c |}{space 4}{cmd:parqit sql} {cmd:"}{it:SELECT ...}{cmd:"}{space 3}any DuckDB query
   {c |}
   {c LT}{c -} {bf:2  SHAPE} {c -} lazy verbs; each one extends the plan {c -} {help parqit##verbs:[more]}
   {c |}
   {c |}{space 4}rows{space 9}{cmd:keep} {cmd:drop} {cmd:sample} {cmd:duplicates drop}
   {c |}{space 4}columns{space 6}{cmd:gen} {cmd:egen} {cmd:replace} {cmd:rename} {cmd:order}
   {c |}{space 4}order{space 8}{cmd:sort} {cmd:gsort}
   {c |}{space 4}aggregate{space 4}{cmd:collapse} {cmd:contract} {cmd:pivot}
   {c |}{space 4}restructure{space 2}{cmd:reshape long} {cmd:reshape wide}
   {c |}{space 4}two tables{space 3}{cmd:merge} {cmd:append} {cmd:joinby}
   {c |}
   {c LT}{c -} {bf:3  LOOK} {c -} runs the plan, shows a summary {c -} {help parqit##explore:[more]}
   {c |}
   {c |}{space 4}shape{space 8}{cmd:describe} {cmd:glimpse} {cmd:ds} {cmd:lookfor} {cmd:codebook}
   {c |}{space 4}rows{space 9}{cmd:count} {cmd:head} {cmd:list} {cmd:levelsof} {cmd:distinct}
   {c |}{space 4}statistics{space 3}{cmd:summarize} {cmd:tabstat} {cmd:tabulate} {cmd:histogram}
   {c |}{space 17}{cmd:correlate} {cmd:pwcorr}
   {c |}{space 4}quality{space 6}{cmd:misstable} {cmd:duplicates report} {cmd:duplicates list}
   {c |}
   {c BLC}{c -} {bf:4  LAND} {c -} produce the full result {c -} {help parqit##materialisers:[more]}

   {space 5}{cmd:parqit collect}{space 12}stream the result into Stata's dataset,
   {space 31}atomically, and leave the view open
   {space 5}{cmd:parqit save} {it:file}{space 10}write Parquet; the dataset in memory is
   {space 31}untouched

{pstd}
The order is a habit, not a rule: look whenever you like, shape again after
looking, and collect or save as often as you need {c -} the view stays open and
re-executes each time.

{pstd}
Alongside the four moves, at any point in the session:

   {space 5}the plan{space 5}{cmd:parqit show} {cmd:parqit explain}
   {space 5}views{space 8}{cmd:parqit views} {cmd:parqit view} {cmd:parqit close}
   {space 5}engine{space 7}{cmd:parqit set} {cmd:parqit path}
   {space 5}install{space 6}{cmd:parqit version} {cmd:parqit selftest} {cmd:parqit menu}

{pstd}
Views are named ({cmd:default} unless {opt name()} says otherwise) and several
can be open at once, like frames. Verbs act on the {it:current} view;
{cmd:parqit view} {it:name} switches, and {cmd:parqit view} {it:name}{cmd::}
{it:command} runs one command against another view and switches back.

{pstd}
Two commands are deliberately {it:not} view verbs: {cmd:parqit mergein} and
{cmd:parqit appendin} join the dataset {it:already in Stata's memory} with a disk
file through a {it:native} {helpb merge} / {helpb append}, reading only the
columns of the file they need. Use them when the disk side is a small lookup;
use {cmd:parqit use} + {cmd:parqit merge} when both sides are big.

{marker lazy}{...}
{title:The lazy view}

{pstd}
{cmd:parqit use using} {it:files} opens a {it:view}: a description of the
data plus a pipeline of verbs, like Stata's idea of "the current dataset"
but living on disk. Opening probes source schema and metadata but does not
materialise its result into the current dataset; a delimited source may be
sampled for type inference, and adapter inputs are bridged as described below.
Views are
named (default name: {cmd:default}) and several can be open at once — the
vocabulary mirrors frames. {opt name()} opens under a name; opening a name that
already exists replaces that plan only and makes it current. {cmd:parqit view}
{it:name} switches the current view. {cmd:parqit view} {it:name}{cmd::}
{it:command} temporarily targets another view and then restores the previously
current view, even when the command fails; a lazy verb still changes the
{it:target} view, so "temporary" describes the switch, not the mutation.
{cmd:parqit views} lists them (bare {cmd:parqit view} does too) and
{cmd:parqit close}
[{it:name}|{cmd:_all}] closes a named view or every view — bare, the
current one. Verbs always act on the current view. A view holds its schema
and plan; an adapter or {cmd:open _data} may also own a temporary Parquet
snapshot. A {cmd:view:}{it:name} two-table source embeds
the source view's current compiled plan and retains any package-owned bridge it
needs; later changing or closing the source view does not invalidate the
derived plan.

{pstd}
A typical first session: open the view, explore it engine-side
({help parqit##explore:describe, head, summarize, tabulate, …} — bounded output
may be staged or displayed, but the current dataset is unchanged), then filter
and derive lazily, and {cmd:collect} only the result — explore first, load last.

{pstd}
{cmd:parqit collect} executes the pipeline once, using a direct read for a pure
source view and a spillable temporary table for a transformed result, then
loads the result atomically — your data is replaced only after the new data is
complete and valid — and the view {it:stays open}
for further exploration (collecting again re-executes). {cmd:parqit save}
executes the pipeline and writes Parquet directly, naming the view it
materialised; the current dataset is never touched. To export the {it:in-memory}
dataset while views are open, use {cmd:parqit save} {it:…}{cmd:, data}.
{cmd:parqit head} requests a small preview; a declared or restored sort order
may still require a scan to find its first rows. {cmd:parqit show} prints the generated SQL
(a readable CTE pipeline, one stage per verb); {cmd:parqit explain} prints
the engine's plan.


{marker verbs}{...}
{title:Verbs}

{pstd}Varlists expand Stata wildcards ({cmd:*} any run of characters,
{cmd:?} one Unicode character) against the exposed Stata column names, in
pattern order without duplicates. This applies to the namelist in eager or
lazy {cmd:parqit use}, the varlists of {cmd:keep}, {cmd:drop}, {cmd:order},
{cmd:contract} and {cmd:duplicates drop}, the {opt by()} of {cmd:egen} and
{cmd:collapse}, {cmd:pivot}'s {opt rows()}, {cmd:mergein}'s {opt keepusing()}
and {cmd:appendin}'s {opt keep()}. {cmd:sort}/{cmd:gsort} and
{cmd:reshape}'s {opt i()} take explicit names only.

{pstd}Lazy verbs validate names and their stated contracts before changing the
plan; a refused verb leaves the current view usable at its previous state.
Binding checks on ordinary single-table operations do not replace the
data-dependent checks performed when the result runs.
No lazy verb changes Stata's in-memory dataset. {cmd:keep}/{cmd:drop} project
columns; {cmd:order} moves the requested columns to the front and retains the
relative order of the rest. Grouped {cmd:rename (oldlist) (newlist)} is one
atomic mapping, so equal-length lists may contain swaps such as
{cmd:(a b) (b a)}; labels, notes, characteristics and declared sort keys follow
the renamed column. {cmd:sort} is ascending, while {cmd:gsort} accepts a
{cmd:+}/{cmd:-} prefix per key. Sorting records plan order and is applied when
the plan runs; it does not scan the source when typed.

{pstd}{cmd:gen} and {cmd:egen} accept {cmd:byte int long float double str# strL}.
The declared type is value semantics: numeric narrowing truncates toward zero
and makes out-of-range values missing, and {cmd:str#} enforces its byte width.
An untyped numeric result is {cmd:double}. In {cmd:gen ... if}, observations
outside the qualifier receive missing; in {cmd:replace ... if}, they retain the
old value. {cmd:replace} preserves a contractual {cmd:float}/{cmd:double} storage
type when possible and otherwise re-infers it safely. {cmd:egen} functions are
{cmd:total mean sd min max count}, optionally within {opt by()}; these functions
are numeric, so a string result type is refused.

{pstd}{cmd:collapse} statistics: {cmd:mean sum sd count min max median}
{cmd:p}{it:##} {cmd:first last firstnm lastnm}. Percentiles follow Stata's
{cmd:summarize} rule exactly and are computed out of core, by rank, so a
huge group needs no in-memory list. {cmd:first}/{cmd:last} are deterministic over
the declared {cmd:parqit sort} order and keep a missing first value missing.
Weights ({cmd:[fweight=}{it:exp}{cmd:]}, …) are not supported on
{cmd:collapse}/{cmd:pivot} and are refused loudly.

{pstd}{cmd:collapse} counts nonmissing values; parqit also permits
{cmd:(count)} on a string and excludes both {cmd:""} and SQL NULL. {cmd:(sum)}
of an all-missing group is zero. A collapse without {opt by()} over an empty
view yields zero observations rather than fabricating one aggregate row.
{cmd:first}/{cmd:last} include missing; {cmd:firstnm}/{cmd:lastnm} skip it. When
no {cmd:parqit sort} was declared, the four order-sensitive statistics use a
reproducible total order over all columns; declare the intended sort whenever
"first" means the source's substantive order.

{pstd}{cmd:contract} produces one row per distinct key tuple, calls the frequency
variable {cmd:_freq} by default, accepts another noncolliding name through
{opt freq()}, and leaves the result ordered by the contracted keys. A
{cmd:contract} that would overwrite an existing {cmd:_freq} column is refused
(name it with {opt freq()}), matching native Stata's {cmd:r(110)}.

{pstd}{cmd:sample} draws an engine-side random sample: {it:#} is a
percentage in (0,100]; with {opt count}, {it:#} is a number of rows.
The count must be a nonnegative integer below 2^63 (zero is allowed). A nonnegative
{opt seed(#)} makes the draw reproducible with unchanged input order, engine
and execution settings. The percentage form selects the nearest whole number
to N times the stored percentage divided by 100, with half ties rounded upward;
it computes that count globally. The count form uses a reservoir. If the seed is omitted
or negative, parqit chooses one when the sample step is added to the plan;
{cmd:parqit show} displays it. Re-executing the unchanged plan does not request
a fresh draw. Sampling remains lazy, and statistical commands that need
several passes use one realization of a sampled input.
Percentage sampling can require a source-sized engine temporary table and a
spillable sort; a small fixed-count sample is usually cheaper.

{pstd}{cmd:reshape long} requires {opt i()} to identify wide rows uniquely. For
each stub it discovers columns named {it:stub}{it:suffix}; if any suffix is
numeric, {opt j()} is numeric and nonnumeric prefix matches are carried as
ordinary columns, otherwise {opt j()} is string. Stubs must be balanced and
must not mix string and numeric source columns. Native Stata's leading-zero
rule is preserved: {cmd:inc01} signals that numeric {cmd:j=1} exists but is
carried as an ordinary column; {cmd:inc1}, when present, supplies the long
value, and otherwise that value is missing. Other columns are carried.
{cmd:reshape wide} requires unique ({opt i()},{opt j()}) cells, refuses missing
{opt j()} values, and requires every other column to be an {opt i()} variable,
the {opt j()} variable or a listed stub. Generated {it:stub}{it:jvalue} names
must be valid, noncolliding Stata names; a generated name that differs only by
case from a live or another generated name ({cmd:x1} beside {cmd:X1}) is
refused loudly rather than written as a duplicate column (the engine cannot
hold both). Both wide reshape and {cmd:pivot}
refuse more than 2,000 distinct {opt j()}/{opt cols()} values. Successful
reshapes leave the result ordered by {opt i()} (and then {opt j()} for long).

{pstd}{cmd:pivot} is Excel's pivot table as one lazy verb: it aggregates
the {cmd:(}{it:stat}{cmd:)} specs by ({opt rows()}, {opt cols()}) — exactly
{cmd:collapse}'s statistics and contracts — and then spreads each distinct
{opt cols()} value into its own column ({cmd:reshape wide}), so the result
has one row per {opt rows()} combination and one column per {opt cols()}
value, named {it:tgt}{it:value} (e.g. {cmd:wage2019}, {cmd:nNorth}).
{opt rows()} accepts wildcards. Both stages appear in {cmd:parqit show},
and their contracts apply: a missing {opt cols()} value is a loud error
(as in native {cmd:reshape wide} — {cmd:parqit replace} or filter it
first), generated names must be valid variable names, and more than 2,000
distinct {opt cols()} values refuse to run. A refused pivot leaves the
view exactly as it was.

{pstd}Two-table {cmd:using} sources may be {cmd:view:}{it:name}: the other
view's pipeline is embedded as a subquery, so filtered-view-to-
filtered-view joins run in one out-of-core query. All contracts below
apply to view sources too (a view may even be merged with itself).

{pstd}{cmd:merge} validates the uniqueness contract of its kind up front
({cmd:m:1} requires unique keys in using, etc.) and produces a
Stata-compatible {cmd:_merge}; missing keys match missing keys, as in
Stata. Options: {opt keep(match master using)}, {opt keepus:ing(varlist)},
{opt gen:erate(name)}, {opt nogen:erate}. Lazy {cmd:parqit merge m:m} is
refused before importing a using-side adapter or changing the current view: a
lazy plan does not retain the physical within-key row order required by native
Stata's sequential reuse rule. Use {cmd:parqit joinby} for Cartesian
many-to-many matches, or {cmd:parqit mergein m:m} when native Stata's
order-dependent sequential behaviour is deliberately required.

{pstd}The default merge marker is {cmd:_merge}, with byte values and labels
1 master only, 2 using only and 3 matched; {opt generate()} renames it and
{opt nogenerate} omits it. {opt keep()} accepts names or codes
({cmd:master}/{cmd:1}, {cmd:using}/{cmd:2}, {cmd:match}/{cmd:matched}/{cmd:3})
and repeated tokens do not change their meaning. {opt keepusing()} accepts
wildcards. A nonkey name present on both sides keeps the master column and
prints a note; missing string, NULL and NaN key encodings are folded to Stata's
single missing-key semantics before uniqueness tests and matching. The result
is ordered by the merge keys.

{pstd}{cmd:append} accepts one or more file or {cmd:view:}{it:name} sources and
performs a union by column name in the stated source order. Columns absent from
a source are missing; a same-named string/numeric conflict is a loud error.
Numeric types are reconciled before the union: float with long or double
is widened to double so values survive both {cmd:collect} and {cmd:save}.
Combining a wider integer/decimal with floating-point values is refused at
execution if the conversion would lose its original precision; make an
explicit conversion first when that loss is intended. Derived non-finite
values are normalized to missing before the appended column is used.
With {opt generate(newvar)}, master rows receive 0 and each using source receives
1, 2, ... . The marker must not collide on any side. {cmd:joinby} is an inner
Cartesian match within each key tuple; same-named nonkey using columns are not
added and produce a note. Append clears the declared sort; merge and joinby
declare their keys as the result order.

{pstd}Cross-source name matching must be unambiguous. Unaligned view inputs,
such as a master {cmd:a} and a using view exposing {cmd:A} under that spelling,
are refused by {cmd:append}. File-backed using inputs are aligned to the master
when opened; {cmd:view:} inputs retain their existing aliases. All three
two-table verbs refuse an engine alias that identifies
different Stata columns on the two sides (for example {cmd:A_1} as an alias for
{cmd:A} on one side and an original {cmd:A_1} on the other). Rename the columns
consistently in the source views first. Case-distinct datasets with already
aligned names and aliases remain supported.

{pstd}{cmd:duplicates drop} with no varlist deduplicates on every column and
needs neither ordering nor {opt force}. With a {it:varlist}, it requires both
{opt force} and a previous {cmd:parqit sort}; it keeps the first row in that
declared order. {cmd:duplicates report}/{cmd:list} are read-only diagnostics
and require an explicit key varlist.

{pstd}{cmd:keep in} {it:f}{cmd:/}{it:l} validates its range against the
real observation count when the pipeline runs; out-of-range is an error,
never a silent empty result. As in native {helpb keep}, the bounds may be the
letters {cmd:f} (first) and {cmd:l} (last) and negative counts from the end
({cmd:-1} is the last observation); {cmd:l} and negative bounds are resolved
from the view's current row count. {cmd:keep in} {it:#} keeps exactly
observation {it:#}; a reversed range is refused. {cmd:drop in} {it:f}{cmd:/}{it:l}
is the complement: it removes observations {it:f} to {it:l} of the same order
and keeps every other row in place, with the same bounds grammar and the same
validation against the real count.


{marker materialisers}{...}
{title:Materialisers}

{pstd}{cmd:parqit collect} replaces Stata's current dataset only after the
engine result has been computed, typed, filled and decorated successfully in a
staging frame. Without {opt clear}, changed nonempty data in memory trigger
Stata error 4; {opt clear} explicitly authorises replacement. The lazy view is
not closed or reset. Until the successful swap, the old dataset and the staged
result can both occupy memory. Consequently a second collect re-runs the source and every
pipeline stage. Open views are likewise untouched by eager
{cmd:parqit use ..., clear}.

{pstd}{cmd:parqit save} writes a single Parquet file (atomically: an exclusively
owned same-filesystem staging file, validated before publication) or a
Hive-partitioned tree with {opt partition_by()} (staged and validated before
publication). A partitioned target that already exists is overwritten only
with {opt replace} (the new tree is built and verified first, then the old
one is set aside until the new tree is in place); without {opt replace},
or when the path exists as a plain file, the save is refused. Codecs:
{cmd:snappy} (default) {cmd:zstd gzip lz4 lz4_raw brotli uncompressed};
unknown codecs are rejected, never silently substituted. {opt chunk(#)}
sets the target rows per Parquet row group (smaller groups = finer
pushdown granularity for later reads; larger = better compression); the
engine rounds it to its internal 2048-row vector multiples, so the
effective minimum is 2048.

{pstd}{opt compression_level(#)} is a codec-specific DuckDB setting: a
nonnegative integer is forwarded to the chosen codec; omitted (or a negative
value) keeps the engine default. {opt partition_by(varlist)} names columns in
the result and writes a directory tree rather than a single file; a partition
key is restored to its recorded Stata type on read (a float/double/{cmd:%tc}
key too), and a zero-observation partitioned save writes an empty tree that
reads back as 0 observations with every variable. A string partition key
whose value is the text {cmd:NULL} or {cmd:__HIVE_DEFAULT_PARTITION__} is
refused before the tree is published: the engine names the directory of a
{it:missing} partition that way and would read the value back as missing
(empty). A foreign tree carrying such a directory under a string key loads
those rows with the key empty, and says so in a {cmd:note:}; every other
value — the empty string, {cmd:=}, {cmd:/}, spaces, {cmd:%}, Unicode,
names differing only by case, numeric-looking text — round-trips exactly,
as does a missing numeric or date key. A save is
refused if its destination is the current view's own source file, matches one
of its source-glob paths, or lies inside (or would replace a directory
containing) a directory the view scans; collect first or choose a
nonoverlapping destination. A destination that is a symbolic link is written
through to its target (native {cmd:save, replace} semantics); a read-only
existing destination refuses {opt replace} with {cmd:r(608)}, as native does.
A valid destination name is accepted up to the filesystem limit
({cmd:NAME_MAX}, 255 bytes on the usual systems); the package lock and staging
siblings fall back to short digest-keyed names when the destination basename is
long.

{pstd}{opt partitions(replace)} and {opt partitions(append)} update an
{it:existing} partitioned tree partition by partition instead of rewriting it
(they need {opt partition_by()} and exclude {opt replace}). With
{cmd:replace}, every partition present in the result replaces its namesake in
the tree — staged, verified, then swapped directory by directory, the old
directory set aside until the new one is in place — while the partitions
absent from the result stay byte-identical and a partition the tree does not
have yet is added: the monthly "add or replace one month" update. With
{cmd:append}, the result's files are added into the partitions under unique
names and nothing is removed. The tree must be a Hive tree over the same keys
in the same order, and the result must read as one dataset with it: the same
columns and engine types, and the same {cmd:parqit.*} metadata (labels,
formats, value labels, notes, characteristics, Stata storage types including
{cmd:str#} widths, and the {cmd:sortedby} marker) — a difference is refused before anything is
published, with the tree untouched, because files that disagree lose their
labels on read. A tree written by another tool, without {cmd:parqit.*}
metadata, receives its new partitions without it, with a {cmd:note:}; a tree
whose files store the partition key inside is refused. A zero-row result
touches nothing. A note reports how many partitions were replaced and added;
handled publication errors trigger rollback of the touched partitions. Several
directory exchanges do not form one atomic snapshot for concurrent readers;
see {help parqit_technical##materialisers:atomicity and locks}.

{pstd}The current partition-update validator requires a regular Hive directory
layout: non-hidden marker files such as {cmd:_SUCCESS} at partition-directory
levels are refused. The empty tree written by a zero-row save contains a root
Parquet schema file and cannot yet be populated with {opt partitions()}; use
an initial full-tree {opt replace} when creating its first populated version.

{pstd}With a view open, {cmd:parqit save} materialises that view and leaves the
current Stata dataset untouched; {opt data} instead writes the in-memory
dataset. With no view open, save writes memory and {opt data} is redundant.
Thus selection is explicit and never guessed from which dataset was most
recently changed.
{cmd:parqit use} {it:file}{cmd:, clear} is the corresponding eager read path.

{pstd}The output format is always Parquet, irrespective of the filename
extension. To produce a Stata {cmd:.dta}, collect a result that fits in Stata
and then use native {cmd:save}. {cmd:parqit save output.dta} does not convert
Parquet to a Stata file.

{pstd}Stata's plugin observation index is signed 32-bit. Eager
{cmd:parqit use ..., clear} and {cmd:collect} therefore refuse a result above
2,147,483,647 observations with error 901 before filling memory. The lazy view
and disk-to-disk path remain valid: filter or aggregate first, or write the
large result with {cmd:parqit save}.

{pstd}The contracts behind {cmd:collect} and {cmd:save} — the {opt copysource}
opt-in, {opt encoding()} and the transcoding of legacy text, the lock file that
serializes writers, and the full string-encoding rules — are in
{help parqit_technical##materialisers:the technical reference}.


{marker explore}{...}
{title:Exploring a view (current dataset unchanged)}

{pstd}
These commands inspect the carried schema or request engine-side queries —
only summary output or the requested preview rows reach Stata, and the
current dataset is never replaced or modified:

{pstd}Results follow native Stata presentation conventions: variable labels
in headings, bordered tables, Stata numeric formats and correlation panels
that fit {cmd:linesize}. {cmd:summarize, detail} places percentiles beside the
four smallest and largest values, with moments on the right. Numeric output
for calculated statistics uses numeric formats; returned numbers retain their
precision. Long category labels and preview cells may be shortened with
{cmd:~}; braces and control characters in data are displayed as text.
{cmd:codebook} and {cmd:misstable} retain the compact information described
below, including parqit's string-missing and complete-observation counts.

{pstd}Statistics are unweighted. Their varlists take explicit view names,
including an exposed Stata name or its reported engine alias; wildcards,
variable ranges and native {cmd:if}/{cmd:in} qualifiers are not supported here.
{cmd:count if} and {cmd:list if/in} have their own syntax. For a filtered
statistical comparison, prepare a second named view and apply its extra
{cmd:keep if} before computing the summary; switching back preserves the first
view. A lazy filter changes its target plan and is not automatically undone.

{p 8 12 2}{cmd:parqit count}{space 17}rows → {cmd:r(N)}{p_end}
{p 8 12 2}{cmd:parqit summarize} [{it:vars}]{space 6}obs/mean/sd/min/max per numeric variable{p_end}
{p 8 12 2}{cmd:parqit summarize} {it:v}{cmd:, detail}{space 3}adds variance, skewness, kurtosis and the
p1 p5 p10 p25 p50 p75 p90 p95 p99 percentiles, all with Stata's exact
definitions (population central moments; the {cmd:summarize} percentile
rule); stored results are listed {help parqit##results:below}{p_end}

{pstd}{cmd:summarize} reports numeric variables. The ordinary form omits
strings and refuses a request with no numeric variables; {opt detail} refuses
an explicitly named string. Variance and standard deviation are sample
statistics (denominator N-1; missing for N below 2). Skewness and kurtosis use
population central moments; kurtosis is Pearson's coefficient, with 3 for a
normal distribution, not excess kurtosis. Sums and means accumulate exactly
before one rounding to the nearest Stata
double. Percentile endpoints retain their source precision until interpolation;
amplitudes subtract before conversion. Dispersion, shape and correlations use
exact power sums/cross-products and certified rounding, including the
same calculations inside {cmd:egen}, {cmd:collapse} and {cmd:pivot}. A finite
standard deviation can be reported even when its variance is too large to
store. Undefined or out-of-range results are ordinary missing; variance may
round to zero below double's smallest positive value. Even sd may round to
zero for a nonconstant sample at that boundary; skewness and kurtosis still use
the exact variance numerator. Corrected results can
differ from native Stata when its own arithmetic loses precision at extreme
offsets or scales. See {help parqit_technical##types:the technical reference}
for numerical and storage limits.

{pstd}For unchanged inputs, the algebraic summary results do not depend on
row order or thread count. Correlation p-values use an independently computed
complement, so a rounded correlation of 1 need not have p-value zero. Their
transcendental tail evaluation has ordinary floating-point/conditioning error
and a documented beta-function domain; see the technical reference. Exact
accumulators use bounded engine memory per group, with increased scratch and
computation possible for many groups. Raw SQL uses DuckDB's function semantics.

{pstd}Numerical correctness concerns the values actually stored. In expressions,
the double value written as .1 is slightly greater than an exact decimal tenth.
Accordingly, {cmd:round(.25,.1)} gives .2 and {cmd:mod(1,.1)} is approximately
.09999999999999995. The implementation avoids native failures such as changing
the integer in {cmd:round(4503599627370497)} or returning 0 for
{cmd:mod(1e100,3)} (the correct remainder is 1). See
{help parqit_technical##expressions:Expression dialect} for domains and tie rules.

{p 8 12 2}{cmd:parqit tabulate} {it:a}{space 14}one-way frequencies (freq/percent/cum){p_end}
{p 8 12 2}{cmd:parqit tabulate} {it:a b}{space 12}two-way cross-tabulation with row/column totals
(the column variable may have at most 30 distinct values; the table at most
10,000 occupied cells){p_end}
{p 8 12 2}{cmd:parqit misstable} [{it:vars}]{space 6}missing count and share per variable (strings
count {cmd:""}){p_end}
{p 8 12 2}{cmd:parqit levelsof} {it:v}{space 12}sorted distinct values → {cmd:r(levels)}
(strings compound-quoted, like {helpb levelsof}); refuses beyond
{opt limit(#)} (default 5,000){p_end}
{p 8 12 2}{cmd:parqit head} [{it:#}]{space 13}materialises only {it:#} rows (default 5) into a
scratch frame, lists them, discards them; {it:#} must be positive{p_end}
{p 8 12 2}{cmd:parqit describe}{space 14}the view's schema and pipeline depth
({cmd:parqit glimpse} is a synonym).
The Stata types shown are the honest display of the file's declared/saved
types {it:without} a data scan; {cmd:collect} additionally sizes integers and
strings from the observed range, so a foreign file's column can arrive
narrower than {cmd:describe} showed{p_end}
{p 8 12 2}{cmd:parqit count if} {it:exp}{space 8}filtered count {it:without touching the view's pipeline}
(any parqit expression except {cmd:_n}/{cmd:_N} — see
{help parqit##expressions:Expressions} — including {cmd:missing(a,b,c)}){p_end}
{p 8 12 2}{cmd:parqit list} [{it:vars}] [{cmd:if}] [{cmd:in}]{space 2}non-mutating preview
with projection, filter and row-range (bare {cmd:parqit list} shows rows
1-20; a bare {cmd:if} caps at 200 rows){p_end}
{p 8 12 2}{cmd:parqit ds}{space 20}variable names → {cmd:r(varlist)}{p_end}
{p 8 12 2}{cmd:parqit lookfor} {it:words}{space 8}match names and labels{p_end}
{p 8 12 2}{cmd:parqit codebook} [{it:vars}]{space 6}per variable: kind, obs, missing,
distinct, min/max, label (one scan){p_end}
{p 8 12 2}{cmd:parqit distinct} [{it:vars}]{space 6}distinct counts per variable;
{opt joint} adds the distinct count of the tuple{p_end}
{p 8 12 2}{cmd:parqit duplicates report} {it:keys}{space 1}copies/observations/surplus
table; {cmd:duplicates list} shows the first offending rows
({opt limit(#)}, default 20){p_end}
{p 8 12 2}{cmd:parqit misstable patterns}{space 3}frequencies and percentages of missing-data
patterns ({cmd:1} observed, {cmd:0} missing; up to 14 variables and the
100 most frequent patterns). Percentages use the full view; when patterns are
omitted, the displayed share and total observation count make this explicit{p_end}

{pstd}With no varlist, {cmd:misstable patterns} selects every view variable,
including fully observed variables and strings, so that form requires at most
14 variables. On a wider file, first use {cmd:misstable} and then name the
variables relevant to the missing-data check.

{p 8 12 2}{cmd:parqit tabstat} {it:vars}{cmd:, s()}{space 5}statistics × variables table
({cmd:n mean sd var sum min max range median p##}; {cmd:count} ≡ {cmd:n});
{opt by()} groups (≤200); {opt save} returns the calculated tables in {cmd:r()}{p_end}
{p 8 12 2}{cmd:parqit correlate} {it:vars}{space 7}correlation matrix, listwise like
{helpb correlate}; {cmd:parqit pwcorr} is pairwise, with {opt obs} and {opt sig}
(two-sided p from the t distribution){p_end}
{p 8 12 2}{cmd:parqit histogram} {it:v}{space 9}bins computed by the engine; only the
bin table reaches Stata, drawn with {cmd:twoway bar} ({opt bins(#)},
{opt nodraw}) → {cmd:r(bins)}, {cmd:r(width)}, {cmd:r(start)}{p_end}

{pstd}
Each data-query call re-executes the lazy pipeline; schema-only commands use
the carried schema. Filters and column selections can be pushed into a Parquet scan. Execution cost
depends on the plan and the source; an exact statistic may require a full scan
or sort. {cmd:parqit tabulate}
excludes missing values unless {opt missing} is given, like native
{helpb tabulate}; {opt row}/{opt col} add percentage panels to the two-way
form; a labelled numeric variable is displayed through its value labels, as
native does, and {opt nolabel} shows the codes instead. {cmd:codebook}'s unique count and {cmd:distinct} exclude missing values;
{cmd:tabstat, by()} omits a missing by-group, matching native Stata. SQL NULL,
empty-string and NaN encodings of the same Stata missing value are folded before
grouping. Stata transforms that have no special command translate directly:
{cmd:destring} ≡ {cmd:parqit gen y = real(x)} (with
{cmd:subinstr(x, ",", "", .)} for thousands separators), string length ≡
{cmd:parqit gen n = strlen(s)}, {cmd:bysort g: gen n = _N} ≡
{cmd:parqit egen n = count(1), by(g)}, and a duplicates tag ≡ that count
minus one. There is no {cmd:browse} over a view — preview with {cmd:parqit list}/{cmd:head} or materialise a slice with {cmd:parqit list}'s {cmd:in}
ranges; {cmd:kdensity} and {cmd:graph box} need the data and are best run
after a {cmd:collect} of the variables involved.

{pstd}
Additional display bounds are deliberate safeguards, not partial silent
results. A one-way {cmd:tabulate} refuses more than 10,000 levels. A two-way
table also caps its column dimension at 30. {cmd:tabstat, by()} permits at most
200 nonmissing groups. {cmd:histogram} defaults to ceil(sqrt(N)) bins capped at
50; an explicit request is capped at 1,000, and a constant variable uses one
bin. {cmd:bins(0)} selects the automatic rule; negative values are refused.
A constant variable returns width 0 and is drawn as a bar of width 1 at its
value. A positive width that underflows to zero, or a width outside Stata's
numeric range, is refused with a message to change {cmd:bins()} or rescale.
Bins are left-closed and right-open, with the maximum included in the last
bin. Boundaries use the exact stored endpoints and requested number of bins;
the displayed width is rounded to double. Bin centers that collapse to the
same Stata value are refused; reduce bins or center/rescale the variable.
{cmd:levelsof} excludes missing and fails if its limit would be exceeded.
{cmd:lookfor} is case-insensitive and returns variables whose name or label
contains any supplied word. These commands do not mutate the view; neither do
{cmd:count if}, {cmd:list}, {cmd:duplicates report/list}, {cmd:show},
{cmd:explain} or either form of {cmd:describe}.

{pstd}{cmd:tabstat} uses the native default orientation: variables in columns
for a multi-variable request, statistics in columns for a single variable.
With {opt by()}, parqit reports group summaries only, corresponding to native
{cmd:tabstat, nototal}; it does not add an overall aggregate query. The
{opt save} option stores those same results for reuse without another scan.
It writes no data file. Correlation commands return the full matrices as well
as the existing scalar results, subject to Stata's matrix dimension limit.

{pstd}An invalid deferred {cmd:keep in}/{cmd:drop in} is refused by these
execution commands just as by {cmd:collect}/{cmd:save}. Explicit names in
{cmd:codebook} and both {cmd:misstable} forms must all exist. Preview defaults
are small, but an explicit large {cmd:head} or {cmd:list in} request must fit
in a scratch Stata frame; a row limit does not bound the work of an upstream
join, aggregation or sort.


{marker expressions}{...}
{title:Expressions}

{pstd}
{cmd:keep if}, {cmd:drop if}, {cmd:count if}, {cmd:gen}, {cmd:replace} and
{cmd:egen} translate Stata expressions to SQL. Supported operators are
{cmd:+ - * / ^} (with Stata precedence; {cmd:^} is left-associative power and
{cmd:/} never integer-divides), {cmd:== != ~= < <= > >=}, {cmd:& |}, unary
{cmd:!}/{cmd:~} and parentheses. Relational chains are left-associative, as in
Stata: {cmd:1 < x < 10} means {cmd:(1 < x) < 10}. {cmd:+} also concatenates two
strings. Ordinary and compound string literals and the ordinary missing
literal {cmd:.} are supported. The complete function list is:

{* parqit-lint: expression-function-list begin. Every name in this block must}{...}
{* be implemented by src/engine/exprtrans.cpp, and every implemented function}{...}
{* keep this list synchronized with exprtrans.cpp.}{...}
{p 8 8 2}{cmd:abs exp ln log log10 sqrt floor ceil int trunc round mod min max}
{cmd:float cond inrange inlist missing mi}{p_end}
{p 8 8 2}{cmd:strlen length ustrlen upper strupper ustrupper lower strlower}
{cmd:ustrlower trim strtrim ltrim rtrim substr strpos subinstr string strofreal}
{cmd:real regexm}{p_end}
{p 8 8 2}{cmd:year month day quarter dow doy mdy dofm mofd yofd} and the
date literals {cmd:td tc tC tm tq th tw ty}{p_end}
{* parqit-lint: expression-function-list end}{...}

{pstd}
The date literals are constants, not functions of a variable. Seven use
Stata's own notation: {cmd:td(}{it:ddmonyyyy}{cmd:)},
{cmd:tm(}{it:yyyy}{cmd:m}{it:#}{cmd:)}, {cmd:tq(}{it:yyyy}{cmd:q}{it:#}{cmd:)},
{cmd:th(}{it:yyyy}{cmd:h}{it:#}{cmd:)}, {cmd:tw(}{it:yyyy}{cmd:w}{it:#}{cmd:)}
and {cmd:tc()}/{cmd:tC(}{it:ddmonyyyy hh:mm}[{cmd::}{it:ss}[{cmd:.}{it:fff}]]{cmd:)}
— for example {cmd:td(01jan2015)}, {cmd:tq(2015q1)} and
{cmd:tc(01jan2015 09:30:00)}. {cmd:ty(}{it:yyyy}{cmd:)} is a parqit extension
accepted for symmetry: native Stata has no {cmd:ty()} function; a yearly
{cmd:%ty} value is written as the bare year, for example {cmd:2026}. An
impossible date such as {cmd:td(31feb2020)} or a 60th second is rejected
loudly. {cmd:tC()} yields the same count as {cmd:tc()}: parqit does not add
leap seconds.

{pstd}
{cmd:_n}/{cmd:_N} are supported in {cmd:keep if}/{cmd:drop if} and in the
main expression of {cmd:parqit gen}; they are windows over the declared
{cmd:parqit sort} order (or engine scan order when no sort was declared, which
is not a reproducibility guarantee). Everywhere else they are unavailable:
{cmd:egen} refuses them in its argument, {cmd:replace} refuses them in either
half of the command, {cmd:gen} refuses
them inside its {cmd:if} qualifier (the {it:main} expression of
{cmd:gen ... if} may still use them), and the read-only
{cmd:count if}/{cmd:list if} filters do not implement them at all. Every one of
those forms fails loudly and leaves the view unchanged.

{pstd}
{it:Missing-value semantics.} By default expressions use SQL semantics:
numeric missing is NULL and comparisons with nonmissing constants are unknown
(NULL) when the variable is missing. For {cmd:keep if} this matches native Stata for the
lower-tail and equality idioms ({cmd:x < c}, {cmd:x <= c}, {cmd:x == c}),
but it differs for the upper tail and inequality ({cmd:x > c}, {cmd:x >= c},
{cmd:x != c}): native Stata treats missing as larger than every number and
so {it:keeps} those rows, whereas SQL drops them. {cmd:drop if} removes only
rows whose condition is true; an unknown comparison leaves the row in place.
Likewise
{cmd:gen y = x > c} yields system missing (not 0/1) for rows where {cmd:x}
is missing. The {cmd:if} qualifier of {cmd:gen} and {cmd:replace} is a filter
and follows the same missing-value mode: under the default SQL semantics a
missing comparison excludes the row; under {cmd:statamissing on} it reproduces
native Stata. A bare numeric condition still uses Stata truth in either mode:
zero is false and every nonzero value, including missing, is true. Numeric
operands of {cmd:&}/{cmd:|}/{cmd:!} use the same coercion; a comparison operand
retains the result implied by the selected missing-value mode. Run
{cmd:parqit set statamissing on} to emulate Stata's ordinary numeric missing
ordering ("missing is greater than every number") in filters and assignments;
the documented precision and expression-dialect limits still apply. The literal
idioms {cmd:x == .}, {cmd:x != .}, {cmd:x < .}, {cmd:x >= .} are translated
to IS NULL tests in either mode. Stata represents string missing by
{cmd:""}; SQL NULL and {cmd:""} compare alike in lazy string expressions.

{pstd}
An unsupported function is a loud, position-anchored error that names the
function — never a silent guess; syntax native Stata rejects ({cmd:||},
{cmd:&&}, uppercase extended missings like {cmd:.A}, malformed numbers) is
rejected here too, with one lenience: a unary plus ({cmd:+x}) is accepted.
Every value whose magnitude reaches Stata's missing sentinel (8.99e+307) is
missing in either sign; native Stata still stores such a {it:negative}
value. {cmd:parqit sql} and {cmd:parqit query} are the escape
hatches.

{pstd}
{cmd:parqit set statamissing} affects expressions translated {it:after} the
setting changes, including read-only {cmd:count if}/{cmd:list if} calls. Lazy
stages already appended retain the SQL semantics under which they were built;
change the setting before adding the relevant filter or assignment if the
pipeline must use Stata missing ordering throughout.

{pstd}The rest of the dialect — the numeric edge contracts, string-function
details, ties in sort keys, extended missings and double-precision evaluation
— is in {help parqit_technical##expressions:the technical reference}.


{marker options}{...}
{title:Settings, raw SQL and diagnostics}

{pstd}{bf:Engine settings.} {cmd:parqit set} takes one of four names and a value:

{p 8 12 2}{cmd:parqit set statamissing on}|{cmd:off}{space 4}expression missing-value mode{p_end}
{p 8 12 2}{cmd:parqit set threads} {it:#}{space 14}engine threads{p_end}
{p 8 12 2}{cmd:parqit set memory_limit} {it:value}{space 4}e.g. {cmd:8GB}{p_end}
{p 8 12 2}{cmd:parqit set tempdir} {it:path}{space 9}spill directory for out-of-core
execution (warns if the directory does not exist yet){p_end}

{pstd}
{cmd:statamissing} defaults to {cmd:off}. {cmd:threads} must be an integer from
1 through 2,147,483,647 and controls DuckDB query execution, not the separate
Arrow-to-Stata fill pool. {cmd:memory_limit} accepts DuckDB size strings such as
{cmd:8GB}; {cmd:tempdir} accepts a literal path (quote paths containing spaces).
The four settings apply to this loaded plugin session and survive view changes;
{cmd:discard} unloads the plugin and resets them. A nonexistent temp directory
is warned about immediately but not forbidden, because it may be created before
the first spill.

{pstd}{bf:Out-of-core execution still uses resources.} {cmd:memory_limit}
budgets DuckDB's buffer manager; it is not a ceiling for the complete Stata
process. Reserve memory for Stata, collected or preview results, and other
engine allocations, plus disk space for spill, bridges and staged output.
Not every query can spill all its state. Use {cmd:show}/{cmd:explain} to inspect
the plan, reduce unnecessary columns and rows before expensive operations
when that preserves the intended result, and collect only what fits.

{pstd}{bf:Raw SQL.} {cmd:parqit sql} accepts a DuckDB {it:query} that returns a
table; it is nested as a subquery, so DDL/DML statements are not this command's
contract. Without {opt clear}, it opens or replaces {cmd:default} (or
{opt name()}) as a lazy view and leaves the current dataset untouched. With
{opt clear}, {opt name()} is invalid: the query is staged, collected atomically, and the
{cmd:default} view is committed only after the load succeeds. Result names and
types cross the same Stata boundary as file input; unsupported columns are
dropped with a warning and a query with no loadable columns is refused.
{cmd:parqit query} instead appends a raw DuckDB clause after the current view's
{cmd:SELECT ... FROM ...}; use it for {cmd:WHERE}, {cmd:QUALIFY}, {cmd:ORDER BY}
or {cmd:LIMIT} constructs that are awkward in the Stata grammar. It does not
translate Stata expressions or change the view's declared projection, and it
bind-validates the candidate before changing the plan.

{pstd}{bf:View and installation diagnostics.} {cmd:parqit open _data} snapshots
memory to a package-owned temporary Parquet bridge, opens/replaces the named
view (default {cmd:default}), leaves memory in place, and reports any extended-
missing collapse or fractional-date rounding caused by that snapshot.
{cmd:close} releases a view and deletes a bridge only after its last dependent
view closes; {cmd:close _all} closes every view and performs the final owned-
bridge sweep. {cmd:show} prints compiled SQL; {cmd:explain} asks DuckDB for its
plan. {cmd:path} resolves a path to an absolute spelling and reports whether it
exists, without creating it. {cmd:version} reports the parqit and embedded
DuckDB versions and identifies DuckDB as the parallel execution backend.
{cmd:selftest} checks the ado/plugin codec, opens the engine, and writes/reads a
small metadata-bearing Parquet file in process. No separate OpenMP runtime or
Windows OpenMP DLL is required. {cmd:parqit set threads} controls DuckDB's workers.
{cmd:menu} adds the reproducible dialogs to {bf:User > parqit} once per GUI
session and refuses console/batch sessions.

{pstd}The environment knobs outside {cmd:parqit set} ({cmd:PARQIT_PLUGIN_PATH},
{cmd:PARQIT_NOTIPS}, {cmd:PARQIT_FILL_THREADS}) are described in
{help parqit_technical##environment:the technical reference}.

{pstd}Use matching ado and plugin files and restart Stata after an update.
The numerical protocol check refuses incompatible revisions. A
{cmd:PARQIT_PLUGIN_PATH} global is unnecessary when the matching plugin is
already found through the adopath.


{marker examples}{...}
{title:Examples}

{pstd}{bf:First contact with an unknown file.} {cmd:describe} reads only Parquet
footer metadata, not column values. The other commands below may scan relevant
data engine-side and stage bounded output, but do not replace the current
dataset:{p_end}
{phang2}{cmd:. parqit describe /data/unknown.parquet}{space 4}({it:rows, columns, types, row groups}){p_end}
{phang2}{cmd:. parqit use using /data/unknown.parquet}{space 2}({it:lazy view; schema probed, no rows loaded}){p_end}
{phang2}{cmd:. parqit head 10}{p_end}
{phang2}{cmd:. parqit codebook}{p_end}
{phang2}{cmd:. parqit misstable}{p_end}
{phang2}{cmd:. parqit summarize wage, detail}{p_end}
{phang2}{cmd:. parqit tabulate region sector, row}{p_end}
{phang2}{cmd:. parqit count if missing(wage, age)}{p_end}
{phang2}{cmd:. parqit list id year wage if wage < 0 | wage > 10000}{p_end}
{phang2}{cmd:. parqit histogram wage, bins(30)}{p_end}
{phang2}{cmd:. parqit close}{p_end}

{pstd}{bf:Compare a filtered population while keeping the full view.}
These are two plans over the same file, not two full copies in Stata:{p_end}
{phang2}{cmd:. parqit use using survey.parquet, name(full)}{p_end}
{phang2}{cmd:. parqit use using survey.parquet, name(adults)}{p_end}
{phang2}{cmd:. parqit keep if age >= 18 & !missing(age)}{p_end}
{phang2}{cmd:. parqit summarize wage, detail}{p_end}
{phang2}{cmd:. parqit view full: summarize wage, detail}{p_end}
{phang2}{cmd:. parqit view full}{p_end}

{pstd}{bf:Whole-file I/O and the metadata round-trip.} Labels, value labels,
notes, formats and storage types are carried through save → use, subject to
the documented conversion and restoration rules; the file stays
plain Parquet for Python/R/Spark (see
{help parqit_technical##metadata:Stata metadata in Parquet}):{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. parqit save auto.parquet, replace data}{p_end}
{phang2}{cmd:. parqit use using auto.parquet, clear}{p_end}
{phang2}{cmd:. describe}{space 15}({it:same types, labels and formats as before}){p_end}

{pstd}{bf:Convert an archive once, work out of core forever.} A {cmd:.dta} (or
{cmd:.xlsx}/{cmd:.csv}) source can be a {cmd:parqit use} input directly — so
conversion is two lines, metadata included:{p_end}
{phang2}{cmd:. parqit use using big_archive.dta, clear}{p_end}
{phang2}{cmd:. parqit save big_archive.parquet, replace data compression(zstd)}{p_end}

{pstd}{bf:Out-of-core panel build} — filter, derive, aggregate on disk; only
the firm-year result enters Stata:{p_end}
{phang2}{cmd:. parqit use using /data/qp_*.parquet}{p_end}
{phang2}{cmd:. parqit keep if year >= 2010 & inrange(age, 25, 64)}{p_end}
{phang2}{cmd:. parqit gen double lwage = ln(wage)}{p_end}
{phang2}{cmd:. parqit collapse (mean) lwage (sd) sd_lw=lwage (p50) med=lwage (count) n=lwage, by(firmid year)}{p_end}
{phang2}{cmd:. parqit show}{space 22}({it:print the SQL the pipeline compiled to}){p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Parquet → Parquet without loading the result into Stata} —
{cmd:save} materialises the view straight to disk; add {opt partition_by()}
for a Hive tree that later reads can prune:{p_end}
{phang2}{cmd:. parqit use using /data/qp_*.parquet}{p_end}
{phang2}{cmd:. parqit keep if wage > 0 & !missing(firmid)}{p_end}
{phang2}{cmd:. parqit save firm_panel.parquet, replace partition_by(year)}{p_end}

{pstd}{bf:Disk-to-disk joins.} The {cmd:using} side stays on disk; contracts
({cmd:m:1} unique keys, …) are validated up front and {cmd:_merge} is
Stata-compatible:{p_end}
{phang2}{cmd:. parqit use using firm_panel.parquet}{p_end}
{phang2}{cmd:. parqit merge m:1 firmid year using /data/scie.parquet, keep(match) keepusing(tfp)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Pairwise combinations} use {cmd:joinby}, as in native Stata.
Lazy {cmd:merge m:m} is refused because its order-dependent sequential pairing
cannot be reproduced from a lazy plan; native {cmd:mergein m:m} remains
available when that behaviour is intentional:{p_end}
{phang2}{cmd:. parqit use using workers.parquet}{p_end}
{phang2}{cmd:. parqit joinby firmid using patents.parquet}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Mixed formats in one pipeline} — a CSV scanned out of core and a
{cmd:.dta} lookup bridged in, joined before the result replaces the current
dataset:{p_end}
{phang2}{cmd:. parqit use using transactions_*.csv}{p_end}
{phang2}{cmd:. parqit keep if amount > 0}{p_end}
{phang2}{cmd:. parqit merge m:1 client_id using clients.dta, keepusing(region segment)}{p_end}
{phang2}{cmd:. parqit collapse (sum) amount (count) n=amount, by(region segment)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Data already in memory, lookup on disk} — keep your data put and
join natively, reading only the needed columns of the file
({cmd:mergein}/{cmd:appendin}); or promote memory to a view for big-on-big:{p_end}
{phang2}{cmd:. use master, clear}{p_end}
{phang2}{cmd:. parqit mergein m:1 firmid using firms.parquet, keepusing(tfp) nogen}{p_end}
{phang2}{cmd:. parqit appendin using late_arrivals.parquet, keep(firmid wage)}{p_end}
{phang2}{cmd:. parqit open _data}{space 18}({it:big-on-big: promote and join out of core}){p_end}
{phang2}{cmd:. parqit merge m:1 id using big_using.parquet, keepusing(x y)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Reshape on disk} — a billion-row long↔wide can be written without
loading the result into Stata's current dataset:{p_end}
{phang2}{cmd:. parqit use using wide_income.parquet}{p_end}
{phang2}{cmd:. parqit reshape long inc, i(pid) j(year)}{p_end}
{phang2}{cmd:. parqit save long_income.parquet, replace}{p_end}

{pstd}{bf:Pivot table (Excel-style)} — mean wage and a count by region × year:{p_end}
{phang2}{cmd:. parqit use using panel.parquet}{p_end}
{phang2}{cmd:. parqit pivot (mean) wage (count) n=wage, rows(region) cols(year)}{p_end}
{phang2}{cmd:. parqit collect, clear}{space 5}({it:columns wage2019 n2019 wage2020 n2020 ...}){p_end}

{pstd}{bf:Dedup, frequency tables, samples}:{p_end}
{phang2}{cmd:. parqit use using events.parquet}{p_end}
{phang2}{cmd:. parqit duplicates report id date}{space 5}({it:copies/surplus table, no materialisation}){p_end}
{phang2}{cmd:. parqit sort id date}{p_end}
{phang2}{cmd:. parqit duplicates drop id date, force}{space 2}({it:first occurrence in the declared order}){p_end}
{phang2}{cmd:. parqit contract region sector, freq(n)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}
{phang2}{cmd:. parqit use using events.parquet}{p_end}
{phang2}{cmd:. parqit sample 1, seed(42)}{space 13}({it:1% engine-side sample; count for # of rows}){p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Expressions, types and dates.} Untyped results are double (like
Stata's evaluator); type the {cmd:gen} to control storage. Dates are their
Stata numbers inside the pipeline:{p_end}
{phang2}{cmd:. parqit use using workers.parquet}{p_end}
{phang2}{cmd:. parqit gen byte prime = inrange(age, 25, 54)}{p_end}
{phang2}{cmd:. parqit gen hire_year = year(hire_date)}{p_end}
{phang2}{cmd:. parqit gen str1 ini = substr(name, 1, 1)}{p_end}
{phang2}{cmd:. parqit replace wage = . if wage <= 0}{p_end}
{phang2}{cmd:. parqit egen double fw = mean(wage), by(firmid)}{p_end}
{phang2}{cmd:. parqit keep if hire_date >= td(01jan2015)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}{bf:Missing-value semantics, explicitly.} SQL mode (the default) drops
missings on {cmd:>} filters; Stata mode keeps them:{p_end}
{phang2}{cmd:. parqit use using workers.parquet}{p_end}
{phang2}{cmd:. parqit count if wage > 5000}{space 12}({it:SQL mode: missing wage NOT counted}){p_end}
{phang2}{cmd:. parqit set statamissing on}{p_end}
{phang2}{cmd:. parqit count if wage > 5000}{space 12}({it:Stata mode: missing wage counted, as native}){p_end}
{phang2}{cmd:. parqit set statamissing off}{p_end}

{pstd}{bf:Several named views}, switched like frames and joined without
materialising either side ({cmd:view:}{it:name} as a {cmd:using} source):{p_end}
{phang2}{cmd:. parqit use using qp_*.parquet, name(panel)}{p_end}
{phang2}{cmd:. parqit keep if year >= 2018}{p_end}
{phang2}{cmd:. parqit use using qp_*.parquet, name(stats)}{p_end}
{phang2}{cmd:. parqit collapse (mean) mw=wage (count) n=wage, by(firmid)}{p_end}
{phang2}{cmd:. parqit views}{p_end}
{phang2}{cmd:. parqit view stats: count}{space 6}({it:one-off against another view}){p_end}
{phang2}{cmd:. parqit view panel}{p_end}
{phang2}{cmd:. parqit merge m:1 firmid using view:stats, keep(match)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}
{phang2}{cmd:. parqit close _all}{p_end}

{pstd}{bf:SQL escape hatches} — inject a fragment into the pipeline
({cmd:query}), or run a standalone statement ({cmd:sql}); {cmd:show} and
{cmd:explain} print what will run:{p_end}
{phang2}{cmd:. parqit use using spells.parquet}{p_end}
{phang2}{cmd:. parqit sort id start}{p_end}
{phang2}{cmd:. parqit query "qualify row_number() over (partition by id order by start) = 1"}{p_end}
{phang2}{cmd:. parqit explain}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}
{phang2}{cmd:. parqit sql "select year, count(*) n from read_parquet('spells.parquet') group by 1 order by 1", clear}{p_end}

{pstd}{bf:Housekeeping} — engine settings, environment checks:{p_end}
{phang2}{cmd:. parqit set threads 8}{p_end}
{phang2}{cmd:. parqit set memory_limit 8GB}{p_end}
{phang2}{cmd:. parqit set tempdir "/scratch/$USER"}{space 4}({it:spill directory for out-of-core runs}){p_end}
{phang2}{cmd:. parqit version}{p_end}
{phang2}{cmd:. parqit selftest}{space 17}({it:end-to-end engine/codec check on a new machine}){p_end}

{pstd}Two runnable companions, {cmd:parqit_basics.do} and
{cmd:parqit_tour.do}, ship with parqit as ancillary files
({cmd:net get parqit} from the installation source copies them into the current
directory) and live in the source repository{c 39}s {cmd:examples/} directory.
SSC submission is planned; the examples below use the GitHub distribution.
Both create small artificial NLS-style labour-panel data under Stata{c 39}s
temporary directory, so they require no data download. {bf:Start with}
{cmd:parqit_basics.do}: a gentle course in Parquet I/O and metadata, lazy
views and sampling, {cmd:collect} versus {cmd:save} (including a partitioned
directory and a multi-file glob), lazy and in-memory merge and append, and
CSV-to-Parquet conversion. {cmd:parqit_tour.do} then covers engine-side
statistics and missing-value modes, richer lazy transformations, collapse,
pivot, contract and reshape, named views, view-to-view merge, joinby, raw SQL
and engine settings. Comments identify the matching {bf:User > parqit}
dialogs; neither file is exhaustive.{p_end}

{phang2}{cmd:. net get parqit, from("https://github.com/reisportela/parqit/releases/latest/download")}{p_end}
{phang2}{cmd:. do parqit_basics.do}{p_end}
{phang2}{cmd:. do parqit_tour.do}{p_end}


{marker limitations}{...}
{title:Limitations}

{pstd}{cmd:•} A view is a plan over live files, not a snapshot: collecting
again re-executes it. Eager and direct-read paths check file identity during
the read; this is not a snapshot guarantee for every engine query. Keep
sources stable throughout a transformation or statistical command; see
{help parqit_technical##limitations:the exact read-path scope}.{p_end}
{pstd}{cmd:•} Expressions use SQL missing-value semantics unless
{cmd:parqit set statamissing on}; {cmd:_n}/{cmd:_N} work in {cmd:keep if},
{cmd:drop if} and in the main expression of {cmd:gen} only.{p_end}
{pstd}{cmd:•} Lazy {cmd:merge m:m} is refused ({cmd:joinby} or
{cmd:mergein m:m} instead); {cmd:collapse}/{cmd:pivot} take no weights;
{cmd:reshape wide}/{cmd:pivot} spread at most 2,000 values.{p_end}
{pstd}{cmd:•} Eager {cmd:use, clear} and {cmd:collect} refuse more than
2,147,483,647 observations; the lazy path and {cmd:save} are not so
bounded.{p_end}
{pstd}{cmd:•} Extended missings {cmd:.a}-{cmd:.z} become plain missing in
Parquet (their labels survive); their literals are refused in lazy
expressions.{p_end}
{pstd}{cmd:•} Stata {cmd:.dta} and Excel inputs are bridged through memory;
Parquet and delimited text are scanned out of core. {cmd:describe} with a file
argument is Parquet-only.{p_end}
{pstd}{cmd:•} Names that differ only by case are kept exact, but a lazy name
the engine could not tell apart from a live one is refused (a generated
{cmd:x1} beside {cmd:X1}, some {opt relaxed} unions, a Hive key clashing with a
column).{p_end}
{pstd}{cmd:•} {cmd:discard} forgets uncollected views; a collected result
reports {cmd:c(filename)} empty and {cmd:c(changed)} 0. The complete list, with
the contract behind each item, is in
{help parqit_technical##limitations:the technical reference}.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{it:Opening and materialising.} Eager {cmd:parqit use ..., clear} and
{cmd:collect} return scalars {cmd:r(N)} and {cmd:r(k)}. Lazy {cmd:use} returns
{cmd:r(k)} and local {cmd:r(view)}; when a {cmd:.dta} or Excel adapter was
needed it also returns the package-owned temporary path in {cmd:r(bridge)}.
{cmd:open _data} returns its snapshot path in {cmd:r(bridge)}. Lazy
{cmd:sql} returns {cmd:r(k)} and {cmd:r(view)}; {cmd:sql ..., clear} returns
{cmd:r(N)}, {cmd:r(k)} and {cmd:r(view)}. Any command that bridges a
source through a temporary snapshot ({cmd:use} lazy or eager,
{cmd:merge}/{cmd:joinby}/{cmd:append}, {cmd:open _data}) additionally returns
the snapshot's losses — {cmd:r(ext_missing)}, {cmd:r(frac_dates)},
{cmd:r(transcoded_vars)}, {cmd:r(transcoded_cells)}, {cmd:r(transcoded_meta)},
{cmd:r(encoding)} — only when the corresponding loss occurred. This bridge
reporting differs from the zero-valued counters returned by a direct memory save.

{pstd}{it:Writing.} {cmd:parqit save} always returns scalars {cmd:r(N)} and
{cmd:r(k)} and local {cmd:r(filename)}. Locals {cmd:r(ext_missing)} and
{cmd:r(frac_dates)} list the variables whose extended missings became null or
whose fractional date/period counts were rounded, and are stored
{it:only when such a loss occurred}: with nothing lost they are not set at all, so they are
absent from {helpb return list} and both references expand to nothing. A view
save also returns {cmd:r(view)}; a memory save does not. A memory save also
returns scalars {cmd:r(transcoded_cells)} and {cmd:r(transcoded_meta)} and
locals {cmd:r(transcoded_vars)} and {cmd:r(encoding)} (see
{it:String encoding}); the counts are zero, {cmd:r(transcoded_vars)} is empty,
and {cmd:r(encoding)} still names the selected code page when nothing needed
transcoding. A lazy view save does not return these transcoding counters.
{cmd:parqit save} {it:…}{cmd:, data copysource} additionally returns local
{cmd:r(copysource)}, the source file it copied.

{pstd}{it:Sources and views.} Lazy {cmd:merge}/{cmd:joinby} return
{cmd:r(bridge)} only when their using source needed an adapter. {cmd:append}
returns {cmd:r(n_bridges)} and, for each adapter-created bridge,
{cmd:r(bridge_1)}, …, {cmd:r(bridge_}{it:n}{cmd:)}. {cmd:views} and bare
{cmd:view} return {cmd:r(n_views)}; {cmd:view} {it:name} returns
{cmd:r(view)}. The prefix form {cmd:view} {it:name}{cmd::} {it:command}
returns the wrapped command's stored results after restoring the previous
current view.

{pstd}{it:Description.} {cmd:describe}/{cmd:glimpse} {it:parquet_source}
return scalars {cmd:r(n_rows)}, {cmd:r(n_cols)} (alias
{cmd:r(n_columns)}), {cmd:r(n_row_groups)}, {cmd:r(n_files)} and
{cmd:r(has_parqit_meta)}, plus locals {cmd:r(name_}{it:i}{cmd:)},
{cmd:r(type_}{it:i}{cmd:)} and {cmd:r(stata_type_}{it:i}{cmd:)} for each
column. The no-argument view form returns {cmd:r(n_cols)} (alias
{cmd:r(n_columns)}) and {cmd:r(n_steps)}.

{pstd}{it:Statistics and previews.} {cmd:count} returns {cmd:r(N)}.
{cmd:head}/{cmd:list} return {cmd:r(N)}, the number of rows shown.
{cmd:summarize} returns {cmd:r(N)}, {cmd:r(sum_w)} (equal to {cmd:r(N)} for
these unweighted summaries), {cmd:r(sum)}, {cmd:r(mean)}, {cmd:r(sd)},
{cmd:r(Var)}, {cmd:r(min)} and {cmd:r(max)} for the last displayed variable;
{opt detail} also returns {cmd:r(skewness)}, {cmd:r(kurtosis)} and
{cmd:r(p1) r(p5) r(p10) r(p25) r(p50) r(p75) r(p90) r(p95) r(p99)}.
{cmd:tabulate} returns {cmd:r(N)} and {cmd:r(r)}, plus {cmd:r(c)} for two-way
tables. {cmd:misstable} returns {cmd:r(N)} and {cmd:r(n_complete)}; its
{cmd:patterns} form returns {cmd:r(N)} for the full view and {cmd:r(r)}, the
number of displayed patterns. {cmd:levelsof} returns local {cmd:r(levels)} and scalar {cmd:r(r)}.

{pstd}{it:Other exploration.} {cmd:ds}/{cmd:lookfor} return local
{cmd:r(varlist)}. {cmd:distinct} returns {cmd:r(N)} and
{cmd:r(ndistinct)} for the last row of its displayed table (the joint tuple
when {opt joint} was requested). {cmd:duplicates report} returns
{cmd:r(N)}, {cmd:r(unique_value)} and {cmd:r(surplus)}.
{cmd:correlate}/{cmd:pwcorr} return {cmd:r(rho)}, the last off-diagonal
coefficient, and {cmd:r(N)}, the minimum diagonal nonmissing count.
These existing scalar conventions are retained for compatibility; native
{cmd:r(rho)} refers to the first two variables. Use {cmd:r(C)} and
{cmd:r(Nobs)} when a particular pair is intended. Both also
return matrix {cmd:r(C)}; {cmd:pwcorr} adds matrix {cmd:r(Nobs)} with pairwise
counts and, with {opt sig}, matrix {cmd:r(sig)} (its diagonal is missing).
If the matrix dimension exceeds Stata's limit, the table and scalars are
returned with a note instead of attempting to create an oversized matrix.
{cmd:tabstat, save} returns matrix {cmd:r(StatTotal)} without {opt by()}, or
matrices {cmd:r(Stat1)}, {cmd:r(Stat2)}, ... and group-label locals
{cmd:r(name1)}, {cmd:r(name2)}, ... with {opt by()}. Rows are statistics and
columns are the requested variables; the group-only form has no {cmd:r(StatTotal)}.
Row names follow native's stored labels:
{cmd:N Mean SD Variance Sum Min Max Range} and the requested {cmd:p##};
{cmd:median} is named {cmd:p50}.
If {opt by()} leaves no nonmissing groups, parqit prints {cmd:no observations},
returns success and creates no group matrices or group-name locals.
Native {cmd:tabstat} instead reports error 2000 for that empty-group case.
{cmd:histogram} returns {cmd:r(N)}, {cmd:r(bins)}, {cmd:r(width)} and
{cmd:r(start)}.

{pstd}{it:Diagnostics.} {cmd:path} returns local {cmd:r(path)} and scalar
{cmd:r(exists)}. {cmd:version} returns locals {cmd:r(parqit_version)},
{cmd:r(duckdb_version)} and {cmd:r(parallel_backend)} equal to {cmd:duckdb}.
For compatibility, scalars {cmd:r(openmp)}, {cmd:r(openmp_version)} and
{cmd:r(openmp_max_threads)} remain available and equal zero: the plugin has no
OpenMP dependency. These are not DuckDB worker counts. {cmd:selftest} returns
local {cmd:r(selftest)} equal to {cmd:ok} and legacy scalar
{cmd:r(openmp_threads)} equal to zero.
Commands not listed in this section do not promise parqit-specific
stored results; in particular the lazy mutation verbs normally change only the
view plan, while {cmd:codebook}, {cmd:tabstat} without {opt save}, {cmd:duplicates list},
{cmd:show} and {cmd:explain} are display commands.


{marker author}{...}
{title:Authors}

{pstd}Miguel Portela{break}
NIPE / Universidade do Minho and BPLIM / Banco de Portugal{break}
Email: {browse "mailto:miguel.portela@eeg.uminho.pt":miguel.portela@eeg.uminho.pt}{p_end}

{pstd}Rute Costa{break}
BPLIM / Banco de Portugal{break}
Email: {browse "mailto:ricosta@bportugal.pt":ricosta@bportugal.pt}{p_end}

{pstd}Paulo Guimarães{break}
BPLIM / Banco de Portugal{break}
Email: {browse "mailto:pfguimaraes@bportugal.pt":pfguimaraes@bportugal.pt}{p_end}

{pstd}Marta Silva{break}
BPLIM / Banco de Portugal{break}
Email: {browse "mailto:msilva@bportugal.pt":msilva@bportugal.pt}{p_end}

{pstd}Only the listed human authors are authors or co-authors of {cmd:parqit}. No
software tool or AI system is credited as an author or co-author.{p_end}

{pstd}Issues and source:
{browse "https://github.com/reisportela/parqit":github.com/reisportela/parqit}.{p_end}


{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
{cmd:parqit} takes {bf:pq} by Jon Rothbaum as its starting point -- the work from
which the {cmd:parqit} solution was designed -- and re-bases the manipulation
layer on an embedded engine. Full credit and thanks to:{p_end}
{phang2}{bf:pq} by Jon Rothbaum (Stata) -
{browse "https://github.com/jrothbaum/stata_parquet_io":github.com/jrothbaum/stata_parquet_io}{p_end}
{phang2}{bf:DuckDB} - {browse "https://duckdb.org":duckdb.org}{p_end}
{phang2}{bf:Apache Arrow C Data Interface} -
{browse "https://arrow.apache.org/docs/format/CDataInterface.html":arrow.apache.org}{p_end}

{pstd}
Jon Rothbaum's package, and the care he puts into its correctness, directly shaped
{cmd:parqit}'s design and its test suite; the debt is gratefully acknowledged.{p_end}

{pstd}
We warmly thank the {bf:BPLIM} team at {bf:Banco de Portugal}
({browse "https://bplim.bportugal.pt/":bplim.bportugal.pt}), whose interaction
throughout greatly benefited the development of {cmd:parqit}.{p_end}

{pstd}
{cmd:parqit} embeds {browse "https://duckdb.org":DuckDB} and uses the Apache Arrow
C Data Interface; it is not affiliated with StataCorp. All remaining errors are the
authors'.{p_end}
