{smcl}
{* *! version 0.1.28 23aug2026}{...}
{vieweralsosee "[D] use" "help use"}{...}
{vieweralsosee "[D] save" "help save"}{...}
{vieweralsosee "[D] collapse" "help collapse"}{...}
{vieweralsosee "[D] merge" "help merge"}{...}
{viewerjumpto "Syntax" "parqit##syntax"}{...}
{viewerjumpto "Description" "parqit##description"}{...}
{viewerjumpto "Stata metadata in Parquet" "parqit##metadata"}{...}
{viewerjumpto "The lazy view" "parqit##lazy"}{...}
{viewerjumpto "Input formats" "parqit##formats"}{...}
{viewerjumpto "Verbs" "parqit##verbs"}{...}
{viewerjumpto "Materialisers" "parqit##materialisers"}{...}
{viewerjumpto "Performance tips" "parqit##perf"}{...}
{viewerjumpto "Exploring a view" "parqit##explore"}{...}
{viewerjumpto "Expressions" "parqit##expressions"}{...}
{viewerjumpto "Type mapping" "parqit##types"}{...}
{viewerjumpto "Settings, raw SQL and diagnostics" "parqit##options"}{...}
{viewerjumpto "Examples" "parqit##examples"}{...}
{viewerjumpto "Limitations" "parqit##limitations"}{...}
{viewerjumpto "Stored results" "parqit##results"}{...}
{viewerjumpto "Author" "parqit##author"}{...}
{viewerjumpto "Acknowledgements" "parqit##acknowledgements"}{...}
{title:Title}

{phang}
{bf:parqit} {hline 2} a grammar of data manipulation for Stata, backed by
Parquet on an embedded DuckDB engine


{marker syntax}{...}
{title:Syntax}

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
{help parqit##formats:Input formats}. Without {opt clear} a lazy view opens over
the file(s), replaces any existing view with the same name and becomes current;
the current in-memory dataset is unchanged. With {opt clear} the whole result is
read into memory atomically and every open view is left untouched; {opt name()}
is then invalid.
{opt relaxed} reads a glob whose files have {it:different} schemas by union of
column names (columns absent from a file arrive missing); without it a schema
mismatch across the matched files is a loud error. {opt encoding(name)} names
the legacy 8-bit code page for a {cmd:.dta}/Excel source that must be bridged to
Parquet (see {help parqit##formats:Input formats}); it is ignored, with a note,
for a Parquet/CSV source (read as UTF-8).

{pstd}Verbs on the open view (all lazy):

{p 8 16 2}{cmd:parqit keep} {it:varlist} | {cmd:parqit keep if} {it:exp} | {cmd:parqit keep in} {it:f}[{cmd:/}{it:l}]{p_end}
{p 8 16 2}{cmd:parqit drop} {it:varlist} | {cmd:parqit drop if} {it:exp}{p_end}
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
{p 8 16 2}{cmd:parqit merge} {cmd:1:1}|{cmd:m:1}|{cmd:1:m} {it:keys} {cmd:using} {it:source} [{cmd:,} {opt keep(spec)} {opt keepus:ing(varlist)} {opt gen:erate(newvar)} {opt nogen:erate} {opt enc:oding(name)}]{p_end}
{p 8 16 2}{cmd:parqit append using} {it:source} [{it:source} ...] [{cmd:,} {opt gen:erate(newvar)} {opt enc:oding(name)}]{p_end}
{p 8 16 2}{cmd:parqit joinby} {it:keys} {cmd:using} {it:source} [{cmd:,} {opt enc:oding(name)}]{p_end}

{p 8 16 2}{cmd:parqit mergein} {cmd:1:1}|{cmd:m:1}|{cmd:1:m}|{cmd:m:m} {it:keys} {cmd:using} {it:file} [{cmd:,} {it:merge_options}]{p_end}
{p 8 16 2}{cmd:parqit appendin using} {it:file} [{cmd:,} {opt keep(varlist)} {opt force}]{space 3}({opt keep()} names variables {it:of the file}, as in native {helpb append}){p_end}

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
only the four options shown in its own syntax line; any other native
{cmd:merge} option is rejected.

{pstd}where each {it:source} is any supported disk input (Parquet file, glob or
Hive directory; delimited text; Stata; or Excel) or
{cmd:view:}{it:viewname} — another open view whose plan is embedded without
materialising either view. Non-Parquet file sources follow the adapter rules
in {help parqit##formats:Input formats}.

{pstd}Materialisers and engine-side result commands (these execute against the
pipeline; only {cmd:collect}/{cmd:save} materialise its full result):

{p 8 16 2}{cmd:parqit collect} [{cmd:,} {opt clear}]{space 8}stream the result into memory (atomically){p_end}
{p 8 16 2}{cmd:parqit save} {it:filename} [{cmd:,} {opt replace} {opt d:ata} {opt comp:ression(codec)} {opt compression_level(#)} {opt part:ition_by(varlist)} {opt c:hunk(#)} {opt enc:oding(name)} {opt copy:source}]{p_end}
{p 8 16 2}{cmd:parqit head} [{it:#}]{p_end}
{p 8 16 2}{cmd:parqit summarize} [{it:varlist}] [{cmd:,} {opt d:etail}]{p_end}
{p 8 16 2}{cmd:parqit tabulate} {it:varname} [{it:varname2}] [{cmd:,} {opt m:issing} {opt row} {opt col}]{space 2}({opt row}/{opt col} apply to the two-way form; the one-way form ignores them){p_end}
{p 8 16 2}{cmd:parqit misstable} [{cmd:summarize}|{cmd:patterns}] [{it:varlist}]{p_end}
{p 8 16 2}{cmd:parqit levelsof} {it:varname} [{cmd:,} {opt l:imit(#)}]{p_end}
{p 8 16 2}{cmd:parqit count} [{cmd:if} {it:exp}]{p_end}
{p 8 16 2}{cmd:parqit list} [{it:varlist}] [{cmd:if} {it:exp}] [{cmd:in} {it:f}[{cmd:/}{it:l}]]{p_end}
{p 8 16 2}{cmd:parqit ds} | {cmd:parqit lookfor} {it:word} [{it:word} ...]{p_end}
{p 8 16 2}{cmd:parqit codebook} [{it:varlist}]{p_end}
{p 8 16 2}{cmd:parqit distinct} [{it:varlist}] [{cmd:,} {opt j:oint}]{p_end}
{p 8 16 2}{cmd:parqit duplicates} {cmd:report}|{cmd:list} {it:varlist} [{cmd:,} {opt l:imit(#)}]{p_end}
{p 8 16 2}{cmd:parqit tabstat} {it:varlist} [{cmd:,} {opt s:tatistics(stats)} {opt by(varname)}]{p_end}
{p 8 16 2}{cmd:parqit correlate} {it:varlist}{space 8}(listwise; takes no options){p_end}
{p 8 16 2}{cmd:parqit pwcorr} {it:varlist} [{cmd:,} {opt obs} {opt sig}]{p_end}
{p 8 16 2}{cmd:parqit histogram} {it:varname} [{cmd:,} {opt b:ins(#)} {opt nodraw}]{p_end}
{p 8 16 2}{cmd:parqit describe} [{it:parquet_source}] | {cmd:parqit glimpse} [{it:parquet_source}]{p_end}

{pstd}Escape hatches and introspection:

{p 8 16 2}{cmd:parqit sql} {cmd:"}{it:DuckDB SQL}{cmd:"} [{cmd:,} {opt clear} {opt n:ame(viewname)}]{p_end}
{p 8 16 2}{cmd:parqit query} {cmd:"}{it:SQL fragment}{cmd:"}{p_end}
{p 8 16 2}{cmd:parqit show} | {cmd:parqit explain}{p_end}
{p 8 16 2}{cmd:parqit view} [{it:viewname}[{cmd::} {it:parqit_command}]] | {cmd:parqit views}{p_end}
{p 8 16 2}{cmd:parqit open _data} [{cmd:,} {opt n:ame(viewname)} {opt enc:oding(name)}] | {cmd:parqit close} [{it:viewname}|{cmd:_all}] | {cmd:parqit path} {it:filename}{p_end}
{p 8 16 2}{cmd:parqit set} {cmd:statamissing}|{cmd:threads}|{cmd:memory_limit}|{cmd:tempdir} {it:value}{p_end}
{p 8 16 2}{cmd:parqit version}{space 4}(plugin + engine versions){p_end}
{p 8 16 2}{cmd:parqit selftest}{space 3}(end-to-end engine and codec check, useful on new installs/HPC nodes){p_end}
{p 8 16 2}{cmd:parqit menu}{space 8}(add parqit to the {bf:User} menu — GUI Stata only){p_end}

{pstd}{bf:Point and click.} The dialogs cover every public subcommand listed
above (apart from {cmd:parqit menu}, which installs the menu itself). Each
dialog builds and runs an ordinary {cmd:parqit} command, so every click is
reproducible from the Review window. {cmd:parqit menu} installs the complete
surface under {bf:User > parqit} (add {cmd:parqit menu} to your
{help profile}.do to keep it across sessions), or launch a dialog directly:

{p 8 12 2}{cmd:db parqit_read}{space 6}read a source into memory or open a
lazy view ({cmd:use}), promote the current dataset ({cmd:open _data}), or
resolve a source path ({cmd:path}); includes variable subset, view name,
{opt clear}, and {opt relaxed}{p_end}
{p 8 12 2}{cmd:db parqit_explore}{space 3}structure and data quality: describe
a file or the view, glimpse, head/list previews, ds/lookfor, codebook, missing
values/patterns, levelsof, distinct counts, duplicate reports/lists, and count
under a condition{p_end}
{p 8 12 2}{cmd:db parqit_stats}{space 5}descriptive statistics: summarize
(detail), tabulate one/two-way (missing, row/col %), tabstat with the
statistics chosen by checkboxes and {opt by()}, correlate/pwcorr (obs, sig),
histogram with engine-computed bins and optional {opt nodraw}{p_end}
{p 8 12 2}{cmd:db parqit_filter}{space 4}keep/drop observations by condition
(the {bf:Create...} button opens Stata's expression builder — date functions
{cmd:td()}, {cmd:tm()}, {cmd:year()}, ... included), keep a row range, or draw
an engine-side percentage/count sample with an optional seed{p_end}
{p 8 12 2}{cmd:db parqit_vars}{space 6}keep/drop/order variables, sort and
gsort, pairwise/multiple rename, or drop duplicates by keys/full rows{p_end}
{p 8 12 2}{cmd:db parqit_gen}{space 7}generate or egen (storage type, supported
egen function and optional by()), or replace; expressions and if conditions
use Stata's builder{p_end}
{p 8 12 2}{cmd:db parqit_pivot}{space 5}collapse, contract, reshape long/wide,
or build an Excel-style pivot table with rows, columns and one/two aggregated
values; every operation remains lazy{p_end}
{p 8 12 2}{cmd:db parqit_combine}{space 3}lazy merge/append/joinby over files,
globs, folders or {cmd:view:}{it:name}, including multiple append sources; or
native mergein/appendin when the master is already in Stata memory{p_end}
{p 8 12 2}{cmd:db parqit_write}{space 5}run the pipeline: collect into memory
(with an explicit replace-in-memory tick), or save to Parquet (replace,
compression/level, partition_by, chunk, encoding, data){p_end}
{p 8 12 2}{cmd:db parqit_views}{space 5}list/switch/close views, run a command
on a named view, show/explain/describe a plan, open raw SQL or add a query
fragment, change all engine settings, and run version/selftest diagnostics{p_end}

{pstd}The manipulation dialogs carry a {bf:View variables} button ({cmd:parqit ds}
of the open view, printed to Results). In the pivot dialog, {bf:Load variables}
fills the value/column pickers from the open view on demand.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:parqit} reads, writes, joins and manipulates columnar Parquet data with
ordinary Stata verbs that run {it:out of core} on an embedded
{browse "https://duckdb.org":DuckDB} engine. It is dbplyr's architecture
with Stata's vocabulary: verbs are lazy and build a logical plan; the plan
compiles to a single SQL query; the engine executes it on disk (datasets far
larger than memory; intermediate results spill to a temporary directory). The
pipeline result enters Stata's current dataset only when collected, or it can
be written straight back to Parquet without loading that result into the
current dataset.

{pstd}
The one idea to internalise: {bf:mutation verbs build a plan rather than materialising their result}.
A view is a plan — "the current dataset", except
that it lives on disk and may be far larger than memory. Opening a view probes
its schema, and every verb bind-validates the candidate plan; contract-sensitive
verbs may also run validation queries (for example merge-key uniqueness, reshape
cell uniqueness or pivot column discovery). These checks do not load the result
into Stata. {cmd:parqit collect} and {cmd:parqit save} execute the full result
plan, as one engine query that reads just the columns and rows it needs. The whole
{help parqit##explore:exploration family} ({cmd:describe}, {cmd:head},
{cmd:summarize}, {cmd:tabulate}, {cmd:codebook}, {cmd:misstable}, …) is
computed by separate engine-side queries too, so a file can be profiled without
replacing or modifying the current dataset — explore first, load last. See
{help parqit##lazy:The lazy view}.

{pstd}
Stata metadata survives: variable labels, value labels, notes, display
formats, characteristics and original column names are stored in standard
Parquet key-value metadata under a {cmd:parqit.*} namespace and restored on
read, while the file remains plain Parquet for pandas, polars, R and Spark.


{marker metadata}{...}
{title:Stata metadata in Parquet}

{pstd}
A file written by {cmd:parqit save} is an ordinary Parquet file: Python,
R, Spark, DuckDB and other readers see the data columns normally. Stata-only
metadata is stored in the Parquet footer as file-level key-value metadata.
The keys are {cmd:parqit.schema}, {cmd:parqit.vallabs}, {cmd:parqit.chars}
and {cmd:parqit.dtalabel}. {cmd:parqit.schema} carries Stata storage types,
display formats, variable labels, attached value-label names, original
source names and the dataset's sort-order marker
({cmd:sortedby}, restored on read as far as Stata accepts it);
{cmd:parqit.vallabs} carries the value-label definitions;
{cmd:parqit.chars} carries characteristics and notes; and
{cmd:parqit.dtalabel} carries the Stata data label.

{pstd}
Third-party readers usually do not apply Stata labels automatically. For
example, {cmd:pandas.read_parquet()} will read a labelled numeric variable as
its numeric codes; the label definitions remain available in the footer. In
Python, inspect them with {cmd:pyarrow}:

{phang2}{cmd:import json, pyarrow.parquet as pq}{p_end}
{phang2}{cmd:md = pq.read_metadata("file.parquet").metadata or dict()}{p_end}
{phang2}{cmd:schema = json.loads(md[b"parqit.schema"].decode())}{p_end}
{phang2}{cmd:vallabs = json.loads(md[b"parqit.vallabs"].decode())}{p_end}
{phang2}{cmd:chars = json.loads(md[b"parqit.chars"].decode())}{p_end}
{phang2}{cmd:dtalabel = json.loads(md[b"parqit.dtalabel"].decode())}{p_end}

{pstd}
When the file is read back with {cmd:parqit use} or materialised with
{cmd:parqit collect}, parqit restores the metadata to Stata. Extended missing
categories {cmd:.a}-{cmd:.z} become plain missing values in Parquet, because
Parquet has one missing concept; their value-label definitions still survive
in {cmd:parqit.vallabs}. Value labels that are defined but attached to no
variable ({cmd:label define} orphans) are written and restored too, like native
{cmd:save}.

{pstd}
Restore is best-effort and loud: a metadata item Stata cannot accept is skipped
or trimmed with a {cmd:note:} and never aborts the load — a display format Stata
rejects, a value-label name or key that is not a legal Stata name/integer,
value-label text over 32,000 bytes, a characteristic name that is not legal, a
characteristic value over Stata's 67,783-byte limit (truncated), or a note/char
whose variable is not in the result (dropped). A glob whose matched files carry
{it:different} {cmd:parqit.*} metadata, or a malformed {cmd:parqit.*} key,
restores no labels/formats and says so. In {cmd:merge}/{cmd:append}/{cmd:joinby}
a value label defined differently on both sides keeps the master definition with
a note.


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
current one. Verbs always act on the current view. A view holds only its schema
and plan, not a materialised copy. A {cmd:view:}{it:name} two-table source embeds
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
{cmd:parqit head} previews cheaply; {cmd:parqit show} prints the generated SQL
(a readable CTE pipeline, one stage per verb); {cmd:parqit explain} prints
the engine's plan.


{marker formats}{...}
{title:Input formats}

{pstd}
The engine scans {bf:Parquet} and {bf:delimited text} ({cmd:.csv}, {cmd:.tsv},
{cmd:.txt} or {cmd:.tab}) directly on disk when they are the main
{cmd:parqit use} source — both are read {it:out of core}, so a file may be
far larger than memory. Parquet can project columns and prune row groups;
delimited text must still be parsed as a stream and has no Parquet row-group
pruning. {bf:Stata} ({cmd:.dta}) and {bf:Excel} ({cmd:.xls}/{cmd:.xlsx}) inputs
are {it:not} engine-scannable, so parqit imports them into a throwaway frame —
your working dataset is left untouched — and snapshots them to a small Parquet
{it:bridge} the engine then scans; their variable/value labels and formats ride
along. parqit picks the path by the final file extension, case-insensitively.
On the {cmd:using} side of {cmd:merge}/{cmd:joinby}/{cmd:append}, Parquet stays
on disk, while delimited text, {cmd:.dta} and Excel are first imported to a
package-owned Parquet bridge; this keeps the engine's two-table input contract
uniform and is intended for a comparatively small using side.

{pstd}
Because a bridge {it:is} a {cmd:parqit save} of the imported frame, the
write-side conversions apply to it and are now reported: extended missings
{cmd:.a}-{cmd:.z} collapse to {cmd:.}, fractional date/period counts round, and
legacy 8-bit text is transcoded from {cmd:windows-1252} (see
{it:String encoding} under Materialisers). The command that created the bridge prints those losses through a
{cmd:note:} naming the bridged file and returns them in
{cmd:r(ext_missing)}/{cmd:r(frac_dates)}/{cmd:r(transcoded_vars)}/
{cmd:r(transcoded_cells)}/{cmd:r(transcoded_meta)}/{cmd:r(encoding)} —
{cmd:parqit use} (lazy and eager), {cmd:merge}/{cmd:joinby}/{cmd:append} and
{cmd:open _data} alike. Choose another code page for a {cmd:.dta}/Excel bridge
with {opt encoding(name)} on any of those commands (a Latin-9 or MacRoman
{cmd:.dta}); a CSV main source is scanned as UTF-8 and is not transcoded.

{pstd}
{bf:When does the bridge make sense?} For a {it:small} side — a lookup
{cmd:.dta}, a hand-made {cmd:.xlsx} — it is ideal: the cost is one quick import.
A {it:large} {cmd:.dta} master gains nothing from it (you would have read the
whole file into Stata either way), so for that prefer Stata's {cmd:use} followed
by {cmd:parqit open _data}. That command writes one temporary Parquet snapshot
of the in-memory dataset and opens a lazy view over it; it does not clear or
otherwise change the in-memory dataset. The plugin atomically reserves every bridge, so concurrent Stata
processes sharing a temp directory cannot choose the same path. A failed
operation removes its package-owned bridge; after success, the bridge lives
until the last view whose plan references it is closed or replaced.
{cmd:parqit close _all} remains the final package-owned cleanup sweep.

{pstd}
This is exactly the shape that keeps a large master {it:out of} Stata while a
small file joins in — only the result is collected:

{phang2}{cmd:. parqit use using big.parquet}{space 22}({it:master view; schema probed, no rows loaded}){p_end}
{phang2}{cmd:. parqit merge m:1 id using lookup.dta, keepusing(rate)}{space 3}({it:.dta bridged in}){p_end}
{phang2}{cmd:. parqit collect, clear}{space 27}({it:only the merged result replaces the current dataset}){p_end}

{pstd}
A delimited file is scanned with DuckDB's {cmd:read_csv_auto} (schema and
delimiter auto-detected); add {opt relaxed} to {cmd:parqit use} to union a glob
whose files have different schemas. (SAS/SPSS are out of scope — parqit reads
Parquet, delimited text, Stata and Excel.)

{pstd}
{cmd:parqit describe} {it:source} / {cmd:glimpse} {it:source} is deliberately a
{bf:Parquet-only} footer inspection (file, glob or Hive directory): it does not
invoke the CSV, Stata or Excel adapters. With no source argument it instead
describes the open view's carried schema and pipeline depth. A mixed-schema
Parquet glob is refused rather than displaying the first file as if it
represented the set; open it with {cmd:parqit use ..., relaxed} to inspect the
unioned view.


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

{pstd}Every lazy verb changes the plan only after its names, types and generated SQL
validate; a refused verb leaves the current view usable at its previous state.
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
{cmd:summarize} rule exactly. {cmd:first}/{cmd:last} are deterministic over
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

{pstd}Result metadata follows native Stata where it is unambiguous. A
{cmd:collapse} target is labelled {cmd:(}{it:stat}{cmd:)} {it:source} and keeps
the source variable's display format; a {cmd:(count)} target is stored
{cmd:long}. The {cmd:merge} marker keeps native's {cmd:%23.0g} format with its
{cmd:_merge} value label. A {cmd:reshape wide} spread column is labelled
{it:jvalue} {it:stub} and keeps the stub's format. Because these travel into the
saved file's {cmd:parqit.*} metadata, third-party readers see the same
labels/formats; the data values are unchanged.

{pstd}{cmd:contract} produces one row per distinct key tuple, calls the frequency
variable {cmd:_freq} by default, accepts another noncolliding name through
{opt freq()}, and leaves the result ordered by the contracted keys. A
{cmd:contract} that would overwrite an existing {cmd:_freq} column is refused
(name it with {opt freq()}), matching native Stata's {cmd:r(110)}.

{pstd}{cmd:sample} draws an engine-side random sample: {it:#} is a
percentage in (0,100]; with {opt count}, {it:#} is a number of rows.
The count must be a nonnegative integer (zero is allowed). {opt seed(#)} makes
the reservoir draw reproducible.

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
With {opt generate(newvar)}, master rows receive 0 and each using source receives
1, 2, ... . The marker must not collide on any side. {cmd:joinby} is an inner
Cartesian match within each key tuple; same-named nonkey using columns are not
added and produce a note. Append clears the declared sort; merge and joinby
declare their keys as the result order.

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
observation {it:#}; a reversed range is refused.


{marker materialisers}{...}
{title:Materialisers}

{pstd}{cmd:parqit collect} replaces Stata's current dataset only after the
engine result has been computed, typed, filled and decorated successfully in a
staging frame. Without {opt clear}, changed nonempty data in memory trigger
Stata error 4; {opt clear} explicitly authorises replacement. The lazy view is
not closed or reset. Consequently a second collect re-runs the source and every
pipeline stage. Open views are likewise untouched by eager
{cmd:parqit use ..., clear}.

{pstd}{cmd:parqit save} writes a single Parquet file (atomically: an exclusively
owned same-filesystem staging file, payload verified by a fresh scan, then
renamed into place) or a
Hive-partitioned tree with {opt partition_by()} (also staged and renamed
atomically). A partitioned target that already exists is overwritten only
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
reads back as 0 observations with every variable. A save is
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

{pstd}{opt copysource} is an explicit, hardened opt-in for
{cmd:parqit save} {it:…}{cmd:, data}: instead of reading the dataset in memory,
it copies the unchanged Parquet file loaded by the last
{cmd:parqit use} {it:file}{cmd:, clear} — you assert nothing has changed. The
default {cmd:parqit save} always reads memory, because Stata's
{cmd:c(changed)} cannot prove the dataset still equals the file: it stays 0
after {cmd:sort}/{cmd:gsort} and after Mata {cmd:st_store}/{cmd:st_sstore}/
{cmd:st_view} writes, which reorder or edit the data. {opt copysource} therefore
verifies, and refuses loudly when any check fails: the source's full identity
must still match (size, mtime, ctime, inode and a Parquet-footer digest,
re-checked immediately before and after the copy); the in-memory variable
names/kinds, observation count and {cmd:sortedby} must equal the file's; the
first and last 64 observations of every variable must equal the file's rows;
and the dataset must be reproducible by copy (case-distinct names, sanitised
names, {cmd:%tc} and binary {cmd:strL} are refused with the remedy). Those
checks catch a {cmd:sort}, a {cmd:gsort} and any edit that touches either end of
the data; they do {bf:not} compare the observations in between — an edit
confined to the middle rows (a Mata {cmd:st_store} on observation 1,000 of
2,003, say) is not detected, and the copy then carries the source file's
content, not memory: with {opt copysource} you assert that nothing has changed.
The copied file is the source file's content with the source file's own
{cmd:sortedby} claim (copied as is), and {cmd:r(copysource)} reports the file
copied. Eager {cmd:parqit use} {it:file}{cmd:, clear} records
a private characteristic {cmd:char _dta[_parqit_fast_source_nonce]} that ties the
dataset to that source so {opt copysource} can verify provenance; it is harmless,
travels with a saved {cmd:.dta}, is never written into a parqit Parquet file, and
may be removed with {cmd:char _dta[_parqit_fast_source_nonce]}.

{pstd}{opt encoding(name)} names the legacy 8-bit code page used to transcode
text that is not valid UTF-8 (see {it:String encoding} below):
{cmd:windows-1252} (the default; aliases {cmd:cp1252}, {cmd:cp-1252},
{cmd:windows1252}), {cmd:latin1} ({cmd:iso-8859-1}, {cmd:iso8859-1},
{cmd:latin-1}), {cmd:latin9} ({cmd:iso-8859-15}, {cmd:iso8859-15}) or
{cmd:macroman} ({cmd:mac-roman}, {cmd:macintosh}). {cmd:r(encoding)} reports the
canonical name ({cmd:windows-1252}, {cmd:latin1}, {cmd:latin9},
{cmd:macroman}) whatever spelling was typed. Any other name is refused before
anything is written — on {bf:both} the memory-save and the lazy view-save
paths. It has an effect only for a save of the dataset in memory; a lazy
Parquet-to-Parquet save carries UTF-8 already, so a valid name is accepted with
no effect there.

{pstd}
Writers for the same destination are serialized by
{it:filename}{cmd:.parqit_lock}. parqit removes that lock only when the current
process created it. A pre-existing or crash-stale lock therefore causes a loud,
fail-closed refusal; after confirming that no writer is alive, the user may
remove that stale lock explicitly. Historical sibling names such as
{cmd:.parqit_tmp}/{cmd:.parqit_old} are never treated as package-owned.

{pstd}With a view open, {cmd:parqit save} materialises that view and leaves the
current Stata dataset untouched; {opt data} instead writes the in-memory
dataset. With no view open, save writes memory and {opt data} is redundant.
Thus selection is explicit and never guessed from which dataset was most
recently changed.
{cmd:parqit use} {it:file}{cmd:, clear} is the corresponding eager read path.

{pstd}Stata's plugin observation index is signed 32-bit. Eager
{cmd:parqit use ..., clear} and {cmd:collect} therefore refuse a result above
2,147,483,647 observations with error 901 before filling memory. The lazy view
and disk-to-disk path remain valid: filter or aggregate first, or write the
large result with {cmd:parqit save}.

{pstd}
{it:String encoding.} Parquet/Arrow strings must be valid UTF-8. Text that is
already valid UTF-8 (ASCII, accented text, emoji, {cmd:strL}) is written
byte-exact. A string cell, variable or data label, value-label text, note or
characteristic that carries raw Latin-1/Windows-1252/MacRoman bytes (common in
administrative data saved by Stata 13 and earlier, or loaded into a Unicode
Stata without {helpb unicode:unicode translate}) is
{bf:transcoded to UTF-8 on the way out}, item by item — what
{cmd:unicode translate} would do, with no
translate step on your side and without touching the dataset in memory. The
source code page defaults to {cmd:windows-1252} (identical to Latin-1 for the
accented letters, and covering the euro sign and typographic quotes in
0x80-0x9F); {opt encoding()} selects {cmd:latin1}, {cmd:latin9} or
{cmd:macroman}. A {cmd:str#} whose transcoded values are longer is recorded
wider, exactly as {cmd:unicode translate} widens it, and past 2,045 bytes the
recorded type becomes {cmd:strL} (the {cmd:parqit.*} metadata is built after the
data pass, so the recorded type always matches the written values). Every save
that transcodes anything prints a {cmd:note:} with counts and returns
{cmd:r(transcoded_cells)}, {cmd:r(transcoded_meta)}, {cmd:r(transcoded_vars)}
and {cmd:r(encoding)}. One limitation, shared with {cmd:unicode translate}: a
legacy string that happens to be well-formed UTF-8 cannot be told apart and is
kept as is. On read, parqit never transcodes: a foreign Parquet file whose
string payload is not valid UTF-8 is refused by the engine with a loud error
naming the column — rewrite it as UTF-8 at the source. A binary {cmd:strL} containing an embedded NUL cannot be represented
through the Stata plugin's text interface, so a direct memory-to-Parquet save
refuses the offending cell before publishing any output. A lazy
Parquet-to-Parquet save does not cross that interface and preserves the bytes.


{marker perf}{...}
{title:Performance tips}

{pstd}
parqit is fastest when data stays on disk and only the final result moves into
Stata. The biggest single cost in any Stata↔columnar bridge is moving rows in
and out of Stata's memory through the plugin interface, so the patterns below
pay off most on large data. parqit prints a one-line {it:tip} when it detects one
of these (e.g. a large {cmd:mergein}); {cmd:global PARQIT_NOTIPS 1} silences them.

{dlgtab:Joining in-memory data with a disk file}

{pstd}
If your data is already in Stata's memory and you want to merge or append a
{it:small} lookup that lives on disk, keep your data put: {cmd:parqit mergein} /
{cmd:parqit appendin} run a {it:native} {help merge} / {help append}, reading only
the columns you ask for from the disk side. The engine still reads that disk
side, but your in-memory data never crosses into DuckDB and back.

{phang2}{cmd:. parqit mergein m:1 firm_id using firms.parquet, keepusing(tfp)}{p_end}
{phang2}{cmd:. parqit appendin using more_rows.parquet}{p_end}

{pstd}
When {it:both} sides are large, it is often faster to let DuckDB do the join
out of core and bring back only the result. DuckDB's hash join avoids sorting
either dataset, so on big-on-big it can beat Stata's native sort-merge even
after the cost of moving the in-memory side across. If both files are on disk:

{phang2}{cmd:. parqit use using big_master.parquet}{p_end}
{phang2}{cmd:. parqit merge m:1 id using big_using.parquet, keepusing(...)}{p_end}
{phang2}{cmd:. parqit collect, clear}{space 20}({it:only the joined result enters Stata}){p_end}

{pstd}
If the large side you want to join is in Stata's memory (not on disk), promote
it once with {cmd:parqit open _data} and join out of core, then collect:

{phang2}{cmd:. parqit open _data}{space 27}({it:snapshots the in-memory data to a view}){p_end}
{phang2}{cmd:. parqit merge m:1 id using big_using.parquet, keepusing(...)}{p_end}
{phang2}{cmd:. parqit collect, clear}{p_end}

{pstd}
The trade-off: {cmd:parqit open _data} writes a temporary bridge first (about the
cost of one {cmd:parqit save}), so for a {it:small} lookup the native
{cmd:parqit mergein} is usually faster, while for {it:big-on-big} the out-of-core
join usually wins.

{dlgtab:Other patterns}

{phang}o {bf:Write without loading.} With a view open, {cmd:parqit save} runs the
pipeline and writes Parquet directly without loading the result into the current
dataset. Use it instead of
{cmd:parqit collect} followed by a native {cmd:save}/export when you only need the
file on disk.{p_end}

{phang}o {bf:Filter and project early.} Put {cmd:parqit keep}/{cmd:parqit keep if}
before a {cmd:collect}/{cmd:save} so the engine reads fewer columns and rows —
the pipeline is lazy, so order is just a hint to push work toward the scan.{p_end}

{phang}o {bf:Read into memory once.} If a workflow collects the same view more
than once, collect it once and work on the result; each {cmd:parqit collect}
re-executes the pipeline.{p_end}

{phang}o {bf:Set a shared-machine memory budget.} The pinned DuckDB engine's
default memory limit is 80% of available system memory. On a shared server or
scheduler allocation, set an explicit per-process ceiling with
{cmd:parqit set memory_limit} (for example {cmd:8GB}) and, when useful, a spill
location with {cmd:parqit set tempdir}.{p_end}

{phang}o {bf:Force a serial fill if you need to.} Reads of 50,000+ rows fill
Stata's memory using up to {cmd:min(cores, 8)} worker threads (the per-cell
fill dominates the cost). To force the single-threaded path — for example on a
platform you have not yet verified — set the {it:operating-system} environment
variable {cmd:PARQIT_FILL_THREADS=0} {it:before launching Stata} (e.g.
{cmd:export PARQIT_FILL_THREADS=0} in your shell); {cmd:PARQIT_FILL_THREADS=}{it:n}
pins {it:n} workers for atypical very wide or string-heavy reads. It is read by
the plugin via {cmd:getenv}, so a Stata {cmd:global} does not reach it. The
parallel and serial fills are byte-identical.{p_end}


{marker explore}{...}
{title:Exploring a view (current dataset unchanged)}

{pstd}
Everything in this group is computed by the engine as a push-down query —
only the summary numbers (or a few preview rows) reach Stata, and the
current dataset is never replaced or modified:

{p 8 12 2}{cmd:parqit count}{space 17}rows → {cmd:r(N)}{p_end}
{p 8 12 2}{cmd:parqit summarize} [{it:vars}]{space 6}obs/mean/sd/min/max per numeric variable{p_end}
{p 8 12 2}{cmd:parqit summarize} {it:v}{cmd:, detail}{space 3}adds variance, skewness, kurtosis and the
p1 p5 p10 p25 p50 p75 p90 p95 p99 percentiles, all with Stata's exact
definitions (population central moments; the {cmd:summarize} percentile
rule) → the full {cmd:r()} set{p_end}
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
{p 8 12 2}{cmd:parqit misstable patterns}{space 3}frequency of missing-data patterns
({cmd:+} observed, {cmd:.} missing; up to 14 variables and the 100 most
frequent patterns){p_end}
{p 8 12 2}{cmd:parqit tabstat} {it:vars}{cmd:, s()}{space 5}statistics × variables table
({cmd:n mean sd var sum min max range median p##}; {cmd:count} ≡ {cmd:n});
{opt by()} groups (≤200){p_end}
{p 8 12 2}{cmd:parqit correlate} {it:vars}{space 7}correlation matrix, listwise like
{helpb correlate}; {cmd:parqit pwcorr} is pairwise, with {opt obs} and {opt sig}
(two-sided p from the t distribution){p_end}
{p 8 12 2}{cmd:parqit histogram} {it:v}{space 9}bins computed by the engine; only the
bin table reaches Stata, drawn with {cmd:twoway bar} ({opt bins(#)},
{opt nodraw}) → {cmd:r(bins)}, {cmd:r(width)}, {cmd:r(start)}{p_end}

{pstd}
Each call re-executes the (lazy) pipeline; on Parquet this is fast because
filters and column selections are pushed into the scan. {cmd:parqit tabulate}
excludes missing values unless {opt missing} is given, like native
{helpb tabulate}; {opt row}/{opt col} add percentage panels to the two-way
form. {cmd:codebook}'s unique count and {cmd:distinct} exclude missing values;
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
bin. {cmd:levelsof} excludes missing and fails if its limit would be exceeded.
{cmd:lookfor} is case-insensitive and returns variables whose name or label
contains any supplied word. These commands do not mutate the view; neither do
{cmd:count if}, {cmd:list}, {cmd:duplicates report/list}, {cmd:show},
{cmd:explain} or either form of {cmd:describe}.


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
{cmd:cond inrange inlist missing mi}{p_end}
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
The numeric edge contracts follow Stata rather than DuckDB defaults. Division
by zero, an invalid power, overflow, {cmd:ln()}/{cmd:log10()} of a nonpositive
value and {cmd:sqrt()} of a negative value produce missing. {cmd:round(x)} and
{cmd:round(x,u)} break exact halves toward +infinity (so
{cmd:round(-2.5)=-2}); {cmd:u=0} returns {cmd:x}. {cmd:mod(x,y)} is the
nonnegative remainder and is missing when {cmd:y<=0}. {cmd:min()}/{cmd:max()}
take 2–64 numeric arguments, ignore missing arguments and return missing only
when all are missing. {cmd:missing()}/{cmd:mi()} accept one or more arguments;
{cmd:inlist()} accepts 2–255 same-family arguments. Numeric
{cmd:inrange(x,lo,hi)} treats missing {cmd:x} as outside the range and missing
bounds as unbounded. Three-argument {cmd:cond()} treats a missing numeric
condition as true; its four-argument form selects the fourth branch instead.
Branches must be all numeric or all string.

{pstd}
{cmd:_n}/{cmd:_N} are supported in {cmd:keep if}/{cmd:drop if} and in the
main expression of {cmd:parqit gen}; they are windows over the declared
{cmd:parqit sort} order (or engine scan order when no sort was declared, which
is not a reproducibility guarantee). Everywhere else they are unavailable:
{cmd:replace} refuses them in either half of the command, {cmd:gen} refuses
them inside its {cmd:if} qualifier (the {it:main} expression of
{cmd:gen ... if} may still use them), and the read-only
{cmd:count if}/{cmd:list if} filters do not implement them at all. Every one of
those forms fails loudly and leaves the view unchanged.

{pstd}
An order with tied keys is not a total order. Because a lazy plan is
re-executed, {cmd:keep in}, {cmd:list in} and other sliced previews may select
different members of a tied group across engine plans or platforms. When the
identity of those rows matters, include an explicit unique tiebreaker in
{cmd:parqit sort}/{cmd:gsort} before slicing.

{pstd}
{cmd:string()} and {cmd:strofreal()} accept one numeric argument and use
Stata's default {cmd:%9.0g} format. {cmd:strlen()}/{cmd:length()} are string
byte lengths here, whereas {cmd:ustrlen()} counts Unicode characters; unlike
native Stata's {cmd:length()}, the numeric-display-width form is not
implemented. {cmd:real()} returns missing for invalid or nonfinite text.
{cmd:upper()}/{cmd:lower()} and their
{cmd:strupper()}/{cmd:strlower()} aliases fold ASCII only, while
{cmd:ustrupper()}/{cmd:ustrlower()} are Unicode-aware. {cmd:subinstr()} supports
the replace-all form whose fourth argument is {cmd:.}. {cmd:substr()} and
{cmd:strpos()} index bytes, like Stata; if a
{cmd:substr()} slice splits a UTF-8 codepoint, parqit returns the replacement
character because DuckDB/Arrow strings must remain valid UTF-8.
Unicode-indexed {cmd:usubstr()} and {cmd:ustrpos()} are not implemented and
fail loudly rather than silently using byte positions.

{pstd}
Extended-missing literals {cmd:.a}-{cmd:.z} are rejected in lazy expressions.
At the Parquet boundary their category identity has already collapsed to the
single ordinary missing value, so accepting them would fabricate a distinction
the view cannot observe. Use {cmd:missing(x)} or compare with {cmd:.}.

{pstd}
Expressions compute in double precision, exactly like Stata's expression
evaluator, and every value Stata cannot hold is missing: an overflowing
result ({cmd:exp(800)}, {cmd:1e300*1e300}) or an out-of-range literal
({cmd:1e309}) is {cmd:.} in filters, assignments and aggregates alike —
never an IEEE infinity. Because untyped results are double, control the
storage of a generated column with a typed {cmd:parqit gen} (e.g.
{cmd:parqit gen byte flag = ...}); native Stata's untyped {cmd:gen} default
is {cmd:float}. For an explicit {cmd:float} target, a finite value outside
Stata's ±1.70e38 storage range becomes missing, as in native assignment.
Date functions floor a fractional day count (like Stata:
{cmd:day(-0.5)} is 31) and an out-of-range argument is row-local missing.
One documented dialect difference: {cmd:regexm()} runs on DuckDB's RE2
engine, which understands {cmd:\d \w \s}, {cmd:{c -(}n,m{c )-}} and
non-greedy quantifiers that Stata's own {cmd:regexm} treats as literals —
patterns using only POSIX classes and {cmd:* + ? . [] ^ $} behave
identically.

{pstd}
{it:Missing-value semantics.} By default expressions use SQL semantics:
missing is NULL and any comparison involving a missing value is unknown
(NULL). For {cmd:keep if}/{cmd:drop if} this matches native Stata for the
lower-tail and equality idioms ({cmd:x < c}, {cmd:x <= c}, {cmd:x == c}),
but it differs for the upper tail and inequality ({cmd:x > c}, {cmd:x >= c},
{cmd:x != c}): native Stata treats missing as larger than every number and
so {it:keeps} those rows, whereas SQL drops them. Likewise
{cmd:gen y = x > c} yields system missing (not 0/1) for rows where {cmd:x}
is missing. The {cmd:if} qualifier of {cmd:gen} and {cmd:replace} is a filter
and follows the same missing-value mode: under the default SQL semantics a
missing comparison excludes the row; under {cmd:statamissing on} it reproduces
native Stata. A bare numeric condition still uses Stata truth in either mode:
zero is false and every nonzero value, including missing, is true. Numeric
operands of {cmd:&}/{cmd:|}/{cmd:!} use the same coercion; a comparison operand
retains the result implied by the selected missing-value mode. Run
{cmd:parqit set statamissing on} for full Stata ordering
("missing is greater than every number"): under it every comparison — in
filters and in assignments alike — reproduces Stata's result. The literal
idioms {cmd:x == .}, {cmd:x != .}, {cmd:x < .}, {cmd:x >= .} are translated
to IS NULL tests in either mode. Strings have no missing: NULL and
{cmd:""} are the same thing on read, write and compare.

{pstd}
An unsupported function is a loud, position-anchored error that names the
function — never a silent guess; syntax native Stata rejects ({cmd:||},
{cmd:&&}, uppercase extended missings like {cmd:.A}, malformed numbers) is
rejected here too. {cmd:parqit sql} and {cmd:parqit query} are the escape
hatches.

{pstd}
{cmd:parqit set statamissing} affects expressions translated {it:after} the
setting changes, including read-only {cmd:count if}/{cmd:list if} calls. Lazy
stages already appended retain the SQL semantics under which they were built;
change the setting before adding the relevant filter or assignment if the
pipeline must use Stata missing ordering throughout.


{marker types}{...}
{title:Type mapping}

{pstd}{it:Integers and floating point.} At the Stata-memory boundary,
{cmd:BOOLEAN} becomes {cmd:byte} 0/1. Signed and unsigned integers use the
smallest exact Stata integer storage that contains the observed range and
otherwise {cmd:double}; an all-missing integer column becomes an all-missing
{cmd:byte} with a note. {cmd:UINT32} values above Stata {cmd:long}'s ceiling
survive as {cmd:double}. {cmd:UINT64}/{cmd:HUGEINT}/{cmd:UHUGEINT} values beyond
2^53 and wide {cmd:DECIMAL} values may round in binary64, so parqit loads them
as {cmd:double} with an explicit precision note, never as silent missing.
A lazy plan keeps these source numerics in DuckDB until a Stata boundary is
actually crossed.

{pstd}{it:Round-trip storage.} When a file was written by parqit, its metadata
preserves the original storage floor (a {cmd:byte} comes back {cmd:byte}, a
{cmd:long} comes back {cmd:long}, and a {cmd:str8} keeps width 8) unless the
observed values require a wider safe type. A plain display format
({cmd:%9.2f}, {cmd:%8.0g}) never widens storage; only a genuine date/period
format keeps integer storage at {cmd:int} or wider so its count fits.
Foreign strings are sized by maximum UTF-8 byte length: up to 2,045 bytes use
{cmd:str#}, longer values use {cmd:strL}, and empty/all-null columns use
{cmd:str1}. {cmd:ENUM}, {cmd:UUID} and logical {cmd:JSON} load as text.

{pstd}{it:Dates and times.} {cmd:%td} variables are {cmd:DATE} on disk,
{cmd:%tc} variables are {cmd:TIMESTAMP}, and {cmd:%tm %tq %th %tw %ty %tb}
stay integer period counts — never mis-scaled calendar dates. A parqit-written
{cmd:%td} or {cmd:%tc} column restores its recorded storage type on both the
eager and lazy paths (an {cmd:int} {cmd:%td} comes back {cmd:int}; a {cmd:float}
{cmd:%tc} comes back {cmd:float} when a scan proves every value exactly
representable as a float — on eager, lazy and view-save reads — and
{cmd:double} otherwise) unless the observed values require wider. Foreign
{cmd:TIME} values become milliseconds since midnight with
{cmd:%tcHH:MM:SS}; nanosecond time/timestamps are truncated (toward the earlier
millisecond, including before 1970) with a note. A timezone-aware timestamp keeps its UTC instant;
a time-of-day offset is discarded with a note. Inside a pipeline dates are
their Stata day or millisecond counts, so date arithmetic is ordinary
arithmetic. Saving a fractional day, millisecond or period count rounds to the
nearest integer using native Stata's exact-half rule (toward +infinity), on
both memory and lazy paths, and names the affected column.

{pstd}{it:Special and unsupported values.} IEEE NaN loads as missing;
{cmd:±Inf}, and any finite magnitude at or above Stata's missing sentinel
(≈ 8.99e307), load as missing with a per-column note. A foreign float32 column
whose finite range exceeds Stata float's ±1.70e38 ceiling widens to
{cmd:double}. String values containing NUL are truncated at the first NUL when
loaded into Stata, with a per-column note; a lazy Parquet-to-Parquet save does
not cross that boundary. Types with no Stata representation — {cmd:NULL},
{cmd:BLOB}, {cmd:BIT}, {cmd:INTERVAL}, {cmd:LIST}/{cmd:ARRAY},
{cmd:STRUCT}/{cmd:MAP}/{cmd:UNION}, {cmd:BIGNUM}, {cmd:GEOMETRY} and
{cmd:VARIANT} — are dropped with a reason; a result containing no loadable
columns is refused.

{pstd}{it:Column names.} At the Stata boundary, invalid name characters become
underscores, a leading digit or reserved word gains an underscore (only
{cmd:strL} and the {cmd:str#} family are reserved — a plain {cmd:str} is a legal
name), names are
limited to 32 Unicode code points, empty names become {cmd:v}{it:position}
(with a note; there is no source name to keep), and collisions gain
deterministic numbered suffixes. The original file name is
retained in {cmd:char var[src_name]} and in the {cmd:parqit.*} metadata; a later
{cmd:parqit save} writes the Stata names (the original stays recoverable from
{cmd:parqit.chars}). This recovery works for a single file, a glob, a Hive tree
and a {opt relaxed} union (parqit predicts the engine's union of the files'
columns exactly and maps every engine name back to the true one), and for
DuckDB's nested dedup shapes (a file carrying {cmd:a}, {cmd:a_1} and {cmd:A} is
read back as those three names). Under {opt relaxed} the engine matches the
files' column names case-insensitively: a later file's column that differs
only by case from an earlier file's ({cmd:NUEMP} after {cmd:nuemp}) is unioned
into that column and a {cmd:note:} says so; when such a match would split one
name across two columns (one file carrying both {cmd:nuemp} and {cmd:NUEMP},
another only {cmd:NUEMP}) the read is refused — read the files separately or
rename the columns upstream. A Hive tree whose partition key differs only by
case from a column inside the files ({cmd:g=} directories over a file column
{cmd:G}) is refused on every path, because the engine would replace that
column's values with the key; a key that exactly duplicates a file column is
read with a {cmd:note:} (the directory value is used).
Names that differ only by case ({cmd:nuemp} and {cmd:NUEMP}) are distinct
variables in Stata and distinct columns in Parquet, but not in the engine, whose
identifiers are case-insensitive: parqit keeps them exact at both boundaries —
a save writes both names into the file, {cmd:parqit use ..., clear} and
{cmd:parqit collect} restore both — while inside a lazy view the second is
addressed by a numbered alias ({cmd:NUEMP_1}, reported when the view opens and
by {cmd:parqit describe}) that {cmd:collect} and {cmd:save} translate back — a
selection varlist ({cmd:parqit use} {it:varlist}, {cmd:keep}/{cmd:drop}/
{cmd:order}, {opt partition_by()}) accepts either the alias or the exact name.
Creating a lazy name that differs only by case from a live one is refused, and
{opt partition_by()} is not available for such datasets. A {cmd:parqit sql}
result with case-clashing output names ({cmd:SELECT 1 AS a, 2 AS A}) is handled
the same way and reported with a {cmd:note:}; a raw {cmd:SELECT *} over a
case-clashing file arrives with DuckDB's own dedup names (a note flags them) —
open the file with {cmd:parqit use} to keep the exact names.
A source column name containing a NUL byte is refused on every input surface;
truncating it could select the wrong column and is never allowed.


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

{pstd}
Three knobs live outside {cmd:parqit set}. The Stata global
{cmd:PARQIT_PLUGIN_PATH} points the loader at a locally built plugin and
takes precedence over the adopath search for {cmd:parqit.plugin};
{cmd:global PARQIT_NOTIPS 1} mutes the one-line performance tips; and the
operating-system environment variable {cmd:PARQIT_FILL_THREADS} controls
the parallel memory fill (see {help parqit##perf:Performance tips}).

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
DuckDB versions. {cmd:selftest} checks the ado/plugin codec, opens the engine,
and writes/reads a small metadata-bearing Parquet file in process.
{cmd:menu} adds the reproducible dialogs to {bf:User > parqit} once per GUI
session and refuses console/batch sessions.


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

{pstd}{bf:Whole-file I/O and the metadata round-trip.} Labels, value labels,
notes, formats and storage types survive save → use exactly; the file stays
plain Parquet for Python/R/Spark (see
{help parqit##metadata:Stata metadata in Parquet}):{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. parqit save auto.parquet, replace}{p_end}
{phang2}{cmd:. parqit use using auto.parquet, clear}{p_end}
{phang2}{cmd:. describe}{space 15}({it:same types, labels and formats as before}){p_end}

{pstd}{bf:Convert an archive once, work out of core forever.} A {cmd:.dta} (or
{cmd:.xlsx}/{cmd:.csv}) source can be a {cmd:parqit use} input directly — so
conversion is two lines, metadata included:{p_end}
{phang2}{cmd:. parqit use using big_archive.dta, clear}{p_end}
{phang2}{cmd:. parqit save big_archive.parquet, replace compression(zstd)}{p_end}

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

{pstd}Two runnable, {bf:self-verifying} companions ship with the source
repository. {bf:Start with} {cmd:examples/parqit_basics.do}: it walks
{cmd:use}/{cmd:save}/{cmd:merge}/{cmd:append} twice each — the eager way
(everything into memory first) and the lazy way (view + verbs +
collect/save) — asserting every lazy result against a native Stata twin.
{cmd:examples/parqit_tour.do} then tours the complete command surface the
same way. Each ends in a printed {cmd:VERDICT(...): PASS}.{p_end}


{marker limitations}{...}
{title:Limitations}

{pstd}{cmd:•} Views are plans over live sources, not snapshots: re-collecting
re-executes the pipeline and can observe a source file that changed meanwhile.
Results are not cached. A {cmd:view:}{it:name} input captures that view's plan at
the time it is embedded, but its underlying files remain live.{p_end}
{pstd}{cmd:•} A source file that changes {it:while} it is being read is refused,
never mixed: every matched file's identity (size, mtime, ctime, inode) is
captured before planning and re-checked before and after the fetch, and the
fetched column types are compared with the plan; a change fails with
{cmd:r(920)} and the dataset in memory is untouched — retry when the file is
stable. This guards eager {cmd:use, clear} and a direct {cmd:collect}; a
pipeline's whole result is built by one engine query over the files as they
are at execution time.{p_end}
{pstd}{cmd:•} {cmd:parqit save ..., data copysource} verifies identity, names,
kinds, count, {cmd:sortedby} and the first and last 64 observations only; an
edit confined to the middle rows is not detected and the copy carries the
source file's content (see {help parqit##materialisers:Materialisers}).{p_end}
{pstd}{cmd:•} {cmd:reshape wide}/{cmd:pivot} refuse a generated name that
differs only by case from a live or another generated name ({cmd:x1} beside
{cmd:X1}); a {opt relaxed} union refuses a name the engine's case-insensitive
union would split across two columns, and a Hive tree whose partition key
differs only by case from a file column is refused (see {it:Column names} under
{help parqit##types:Types and metadata}).{p_end}
{pstd}{cmd:•} Stata's plugin observation index is signed 32-bit. Eager
{cmd:use ..., clear} and {cmd:collect} refuse more than 2,147,483,647 rows with
error 901; filter, aggregate or {cmd:save} the lazy result instead.{p_end}
{pstd}{cmd:•} Main-source Parquet and delimited text are engine-scanned, but
{cmd:.dta}/{cmd:.xls}/{cmd:.xlsx} require a full temporary Parquet bridge.
Delimited text on a two-table {cmd:using} side is bridged too.
{cmd:describe} with a source argument is Parquet-only.{p_end}
{pstd}{cmd:•} Extended missings {cmd:.a}-{cmd:.z} become plain missing in
Parquet (the format has one missing concept); parqit warns when they are
written. Their literals are therefore rejected in lazy expressions; use
{cmd:missing()} or the ordinary {cmd:.} value.{p_end}
{pstd}{cmd:•} A slice over tied sort keys has no defined within-tie order.
Add a unique key to {cmd:sort}/{cmd:gsort} before {cmd:keep in} or a sliced
preview when row identity must be reproducible.{p_end}
{pstd}{cmd:•} A direct memory-to-Parquet save refuses a binary {cmd:strL}
containing NUL; a lazy Parquet-to-Parquet save preserves it, and text
{cmd:strL}s round-trip. Unsupported DuckDB types are dropped with a reason,
and an input with no representable columns is refused. A NUL in a source
column name is always refused; a NUL in a string value is truncated only when
crossing into Stata, with a note.{p_end}
{pstd}{cmd:•} Lazy {cmd:parqit merge m:m} is refused before adapter import or
view mutation because a lazy plan lacks native physical within-key order. Use
{cmd:joinby} for Cartesian matches or native {cmd:mergein m:m} for Stata's
sequential behaviour.{p_end}
{pstd}{cmd:•} {cmd:reshape wide} and {cmd:pivot} cap the spread dimension at
2,000 values. {cmd:collapse}/{cmd:pivot} do not implement weights. Lazy
expressions are the documented subset, not arbitrary Stata syntax; in
particular {cmd:_n}/{cmd:_N} are unavailable in {cmd:replace}, in the
{cmd:if} qualifier of {cmd:gen}, and in the read-only {cmd:count if} and
{cmd:list if} filters.{p_end}
{pstd}{cmd:•} {cmd:%tC} and {cmd:%tb} are stored as integer counts with
their format in metadata; third-party readers see the raw counts.{p_end}
{pstd}{cmd:•} {cmd:discard} unloads the plugin and forgets an un-collected
view (data on disk is never affected).{p_end}
{pstd}{cmd:•} A loaded result reports {cmd:c(filename)} empty and
{cmd:c(changed)} 0 — like an import, the data is not backed by a
.dta.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{it:Opening and materialising.} Eager {cmd:parqit use ..., clear} and
{cmd:collect} return scalars {cmd:r(N)} and {cmd:r(k)}. Lazy {cmd:use} returns
{cmd:r(k)} and local {cmd:r(view)}; when a {cmd:.dta} or Excel adapter was
needed it also returns the package-owned temporary path in {cmd:r(bridge)}.
{cmd:open _data} returns its snapshot path in {cmd:r(bridge)}. Lazy
{cmd:sql} returns {cmd:r(k)} and {cmd:r(view)}; {cmd:sql ..., clear} returns
{cmd:r(N)}, {cmd:r(k)} and {cmd:r(view)}. Any command that bridges a
non-UTF-8 {cmd:.dta}/Excel source ({cmd:use} lazy or eager,
{cmd:merge}/{cmd:joinby}/{cmd:append}, {cmd:open _data}) additionally returns
the snapshot's losses — {cmd:r(ext_missing)}, {cmd:r(frac_dates)},
{cmd:r(transcoded_vars)}, {cmd:r(transcoded_cells)}, {cmd:r(transcoded_meta)},
{cmd:r(encoding)} — with the same present-only-on-loss rule as {cmd:parqit save}
below.

{pstd}{it:Writing.} {cmd:parqit save} always returns scalars {cmd:r(N)} and
{cmd:r(k)} and local {cmd:r(filename)}. Locals {cmd:r(ext_missing)} and
{cmd:r(frac_dates)} list the variables whose extended missings became null or
whose fractional date/period counts were rounded, and are stored
{it:only when such a loss occurred}: with nothing lost they are not set at all, so they are
absent from {helpb return list} and both references expand to nothing. A view
save also returns {cmd:r(view)}; a memory save does not. A memory save also
returns scalars {cmd:r(transcoded_cells)} and {cmd:r(transcoded_meta)} and
locals {cmd:r(transcoded_vars)} and {cmd:r(encoding)} (see
{it:String encoding}); the counts and {cmd:r(encoding)} are absent, and
{cmd:r(transcoded_vars)} empty, when nothing needed transcoding.
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
{cmd:summarize} returns {cmd:r(N)}, {cmd:r(mean)}, {cmd:r(sd)}, {cmd:r(min)}
and {cmd:r(max)} for the last displayed variable; {opt detail} also returns
{cmd:r(Var)}, {cmd:r(skewness)}, {cmd:r(kurtosis)} and
{cmd:r(p1) r(p5) r(p10) r(p25) r(p50) r(p75) r(p90) r(p95) r(p99)}.
{cmd:tabulate} returns {cmd:r(N)} and {cmd:r(r)}, plus {cmd:r(c)} for two-way
tables. {cmd:misstable} returns {cmd:r(N)} and {cmd:r(n_complete)}; its
{cmd:patterns} form instead returns {cmd:r(r)}, the number of displayed
patterns. {cmd:levelsof} returns local {cmd:r(levels)} and scalar {cmd:r(r)}.

{pstd}{it:Other exploration.} {cmd:ds}/{cmd:lookfor} return local
{cmd:r(varlist)}. {cmd:distinct} returns {cmd:r(N)} and
{cmd:r(ndistinct)} for the last row of its displayed table (the joint tuple
when {opt joint} was requested). {cmd:duplicates report} returns
{cmd:r(N)}, {cmd:r(unique_value)} and {cmd:r(surplus)}.
{cmd:correlate}/{cmd:pwcorr} return {cmd:r(rho)}, the last off-diagonal
coefficient, and {cmd:r(N)}, the minimum diagonal nonmissing count.
{cmd:histogram} returns {cmd:r(N)}, {cmd:r(bins)}, {cmd:r(width)} and
{cmd:r(start)}.

{pstd}{it:Diagnostics.} {cmd:path} returns local {cmd:r(path)} and scalar
{cmd:r(exists)}. {cmd:version} returns locals {cmd:r(parqit_version)} and
{cmd:r(duckdb_version)}. {cmd:selftest} returns local {cmd:r(selftest)} equal
to {cmd:ok}. Commands not listed in this section do not promise parqit-specific
stored results; in particular the lazy mutation verbs normally change only the
view plan, while {cmd:codebook}, {cmd:tabstat}, {cmd:duplicates list},
{cmd:show} and {cmd:explain} are display commands.


{marker author}{...}
{title:Author}

{pstd}Miguel Portela{break}
NIPE / Universidade do Minho and BPLIM / Banco de Portugal{break}
Email: {browse "mailto:miguel.portela@eeg.uminho.pt":miguel.portela@eeg.uminho.pt}{p_end}

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
author's.{p_end}
