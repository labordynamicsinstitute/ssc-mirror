{smcl}
{* *! version 0.1.37 07sep2026}{...}
{vieweralsosee "[PARQIT] parqit" "help parqit"}{...}
{viewerjumpto "Description" "parqit_technical##description"}{...}
{viewerjumpto "Stata metadata in Parquet" "parqit_technical##metadata"}{...}
{viewerjumpto "Input formats" "parqit_technical##formats"}{...}
{viewerjumpto "Verb contracts" "parqit_technical##verbs"}{...}
{viewerjumpto "Materialisers: atomicity, copysource, encoding, locks" "parqit_technical##materialisers"}{...}
{viewerjumpto "Performance tips" "parqit_technical##perf"}{...}
{viewerjumpto "Expression dialect" "parqit_technical##expressions"}{...}
{viewerjumpto "Type mapping" "parqit_technical##types"}{...}
{viewerjumpto "Environment" "parqit_technical##environment"}{...}
{viewerjumpto "Limitations" "parqit_technical##limitations"}{...}
{viewerjumpto "Authors" "parqit_technical##author"}{...}
{title:Title}

{phang}
{bf:parqit_technical} {hline 2} technical reference for {helpb parqit}: the
contracts behind the lazy view — metadata layout, input adapters, verb
contracts, atomicity of the materialisers, the expression dialect, the type
mapping and the complete list of limitations


{marker description}{...}
{title:Description}

{pstd}
{helpb parqit} is the user manual: syntax, the lazy-view model, the verbs, the
materialisers, the exploration commands, examples and stored results. This
entry collects what the manual leaves out on purpose — the rules parqit
follows for compatibility with native Stata and standard Parquet, together
with the supported subset and its exceptions. Use these contracts to assess a
workflow's resource needs and fidelity. The regression suites exercise them;
passing tests do not establish correctness for every possible input or platform.

{pstd}
DuckDB executes SQL using its own scheduler; {cmd:parqit set threads} controls
its worker limit. From 0.1.37, plugins do not link an OpenMP runtime or require
a companion Windows DLL. The OpenMP region in 0.1.36 was a diagnostic self-test,
not the execution mechanism for data calculations. Removing it does not change
the statistical algorithms or DuckDB's parallel execution.
{cmd:parqit version} returns {cmd:r(parallel_backend)} equal to {cmd:duckdb};
the legacy {cmd:r(openmp*)} diagnostics return zero.

{pstd}
Compiler-runtime notices remain in {cmd:parqit_openmp_license.txt}; its filename
is retained for package compatibility, although no OpenMP runtime is bundled.
The MIT license for parqit's own code does not replace third-party licenses.


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
your working dataset is left untouched — and snapshots them to a temporary Parquet
{it:bridge} the engine then scans; their variable/value labels and formats ride
along. parqit picks the path by the final file extension, case-insensitively.
On the {cmd:using} side of {cmd:merge}/{cmd:joinby}/{cmd:append}, Parquet stays
on disk, while delimited text, {cmd:.dta} and Excel are first imported to a
package-owned Parquet bridge; this keeps the engine's two-table input contract
uniform and is intended for a comparatively small using side.
The delimited using-side adapter uses Stata's {cmd:import delimited}, whose
type inference can differ from {cmd:read_csv_auto} on the main side (for
example, date text versus a parsed date). Excel uses the first worksheet and
its first row as variable names; there are no sheet/range/header options.
To retain the main-source CSV inference for a join, open that CSV as its own
named view and refer to {cmd:view:}{it:name}.
Delimited-text header names get the same treatment as Parquet column names
(see {it:Column names} under {help parqit_technical##types:Types and metadata}): a
repeated name keeps the engine's numbered form ({cmd:a_1}, with
{cmd:char a_1[src_name]} holding the original), a name that differs only by
case from another is exact in Stata (an alias inside the lazy view, with a
note), an empty header cell becomes {cmd:v}{it:#}, and a file without a header
keeps the engine's {cmd:column0}, {cmd:column1}, … names.

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
{title:Verb contracts}

{pstd}Result metadata follows native Stata where it is unambiguous. A
{cmd:collapse} target is labelled {cmd:(}{it:stat}{cmd:)} {it:source} and keeps
the source variable's display format (a {cmd:(count)} of a string source
carries {cmd:%8.0g}); a {cmd:(count)} target is stored {cmd:long}. The {cmd:merge} marker keeps native's {cmd:%23.0g} format with its
{cmd:_merge} value label. A {cmd:reshape wide} spread column is labelled
{it:jvalue} {it:stub} and keeps the stub's format. Because these travel into the
saved file's {cmd:parqit.*} metadata, third-party readers see the same
labels/formats; the data values are unchanged.

{pstd}Aggregation storage need not equal native {cmd:collapse}'s storage.
Means and standard deviations use the engine's double results, which can
retain more precision than native output stored as float. Percentile
interpolation retains the source endpoints until their exact midpoint is
rounded to double; {cmd:collapse} preserves a float
source's native value rounding, although the result may be stored wider.
{cmd:tabstat} uses the unrounded double statistic. Distinguish agreement of
statistical definitions from byte-identical storage types.

{pstd}Exploratory output uses native Stata numeric formats and table layouts;
labels come from the view's carried metadata. The smallest/largest values in
{cmd:summarize, detail} are fetched from the existing percentile sort, adding
no source scan. Printed numbers are rounded for display; returned matrices
retain the calculated precision. {cmd:tabstat, save} and correlation matrices
are built from the already computed summary response, not from another query
or a reconstruction of the raw dataset. Missing-pattern percentages use a
total computed before the 100-pattern display cap.

{pstd}Statistics cross into Stata as binary64 values before text formatting,
including extrema from a FLOAT source. Non-finite values and magnitudes outside
Stata's numeric range are returned as ordinary missing, and numeric response
text is parsed as a number rather than evaluated as an expression.
Floating sums use a fixed integer accumulator in units of the smallest
binary64 subnormal. Integer/decimal inputs use fixed 256-bit integer states.
Sums and means are rounded once to the nearest binary64 value, with ties to
even; means divide the exact total before rounding. Integer/decimal conversions
use exact midpoint comparisons, including collect, extrema and percentiles.
Dispersion and shape use exact integer power sums. Central moments are formed
before division; variance and Pearson kurtosis are exact rational values
rounded to binary64, while sd and skewness certify the rounding of their square
roots against exact midpoint squares. Correlation likewise forms exact sums
and cross-products and independently rounds the coefficient and its geometric
complement. Results for the same stored inputs are invariant to order,
partitioning and thread count. No clipping or approximate retry is used;
an internal mathematical invariant failure is an error.

{pstd}Standard deviation is rounded from the exact variance independently of
the returned variance. Thus sd can be finite when variance overflows, or nonzero when
variance underflows to zero. A constant with a very large level still has
zero sd and its finite mean. Conversely, a nonconstant sample can have sd
rounded to zero at the subnormal boundary; shape uses the exact variance
numerator and remains defined. These algorithms do not reproduce native
Stata's numerical failures. Counts, missingness and rank definitions
remain unchanged; unrelated SQL, source and resource failures remain errors.
Exact integer sums in a lazy table retain the engine's integer/decimal result
type and still refuse a true overflow of that type. For an explicitly double
total of wide values, {cmd:egen double newvar = total(x)} accumulates before
conversion. Returned {cmd:tabstat, s(sum)} statistics are double values too.

{pstd}The states are bounded and remain inside DuckDB's grouped/window/spill
execution: 288 bytes for a total, 832 for dispersion, 2,736 for detail and
2,184 per correlation pair. Many groups can require more time and scratch
than approximate accumulation. The arithmetic bound admits fewer than 2^64
values per state, finite doubles with magnitude below 2^1023, and the engine's
128-bit integer/decimal coefficients. No raw floating powers are formed.

{pstd}Correlation significance uses the independently calculated complement,
not {it:1 - rounded_rho^2}. A coefficient displayed or stored as 1 can therefore
have a small positive p-value. The two-sided Student tail uses stable analytic
or beta-function forms; a scaled series recovers subnormal probabilities that
Mata's exponential implementation would otherwise turn into zero. Unlike the
algebraic statistics, these transcendental tails are subject to floating-point
library and conditioning error; correctly rounded final bits are not promised.
The beta-function shape domain ends at 1e17: outside it, nontrivial p-values
are missing with a note, while the correlation remains available.
Raw {cmd:parqit sql}/{cmd:query} fragments retain DuckDB's own function semantics;
user-written SQL aggregates are not silently replaced by parqit's routines.

{pstd}A sampled or staged input to {cmd:summarize, detail} is materialized once
inside DuckDB before its moments and spillable rank sorts. Histogram range and
bin counts likewise share one realization. A bin boundary is compared exactly
as {it:bins*x >= (bins-k)*min+k*max}, avoiding division by an already rounded
width. Centers and width are rounded for Stata; indistinguishable centers are
refused. These temporary projections never enter
Stata's dataset and are released on completion or error. The embedded engine
includes pinned corrections for uniform reservoir inclusion and the C-API
window-aggregate state bridge. A missing/negative sample seed is chosen once
per plan and appears in {cmd:show}; it is not redrawn between statistical passes.
The count form uses a reservoir. Percentage sampling captures the source once
inside DuckDB, rounds the exact binary64 proportion {it:N*p/100} to the nearest
row count (half ties upward), and selects that many rows by a seeded hash
priority with row-index tie-breaking. Its materialization and sort can spill;
it may need substantially more time and scratch than a small fixed-count sample.
Reproducibility requires unchanged input order, engine and execution settings.

{pstd}Statistics read complete response records even when a string or label
exceeds 32 KiB. Each duplicate-preview cell has its own encoded field, and
string keys retain embedded NUL bytes during grouping and table construction.
Display escapes NUL, line breaks and unit separators as {cmd:\0}, {cmd:\n},
{cmd:\r} and {cmd:\x1f}; these escapes describe characters in the data.


{marker materialisers}{...}
{title:Materialisers: atomicity, copysource, encoding, locks}

{pstd}The default memory-to-Parquet writer assembles complete Arrow column
buffers before writing; this can require substantial memory in addition to
the dataset already in Stata. {cmd:open _data} and in-memory input adapters
use that writer too. They do not have the same memory profile as a direct
lazy Parquet-to-Parquet save. Set the operating-system environment variable
{cmd:PARQIT_SAVE_NOARROW=1} before launching Stata to use the existing batched
writer through a spillable DuckDB staging table. Any presence of this variable
(even {cmd:0}) selects that path; unset it to restore the default. This trades
additional staging work for avoiding the complete Arrow buffer assembly.

{pstd}{opt copysource} is an explicit, hardened opt-in for
{cmd:parqit save} {it:…}{cmd:, data}: instead of reading the dataset in memory,
it copies the unchanged Parquet file loaded by the last
{cmd:parqit use} {it:file}{cmd:, clear} — you assert nothing has changed. The
default memory-save path reads the dataset in memory; with a view open,
request that path with {opt data}. Stata's
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

{pstd}Atomicity has a scope. Single-file publication uses a same-filesystem
rename when replacing; creating a new file on POSIX uses a hard link followed
by removal of the staging name, so an existing destination cannot be
overwritten in a race. Filesystems without hard-link support can refuse that
new-file path. Replacing a tree and updating several partitions
involve multiple directory exchanges, with rollback on handled publication
errors; they are not one transaction visible atomically to concurrent readers,
nor a crash-recovery guarantee. The writer lock covers the resolved destination,
not every ancestor or descendant path. Coordinate readers and writers of a
partitioned tree, and do not concurrently write overlapping destinations.

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
before expensive operations when that preserves the intended result. Verb
order is semantically significant: filtering before and after {cmd:collapse},
{cmd:sample} or a row-number calculation can select different data. DuckDB
pushes work toward the scan only when its optimizer can preserve meaning.{p_end}

{phang}o {bf:Distinguish filtering from row-group pruning.} Floating-point
normalization and date conversion can leave expression filters that the pinned
engine evaluates during the scan but cannot use to prune row groups from their
statistics. Simpler predicates, including string predicates the optimizer can
simplify, may prune. {cmd:parqit explain} shows which form reaches the scan;
the presence of a filter alone does not prove that row groups were skipped.{p_end}

{phang}o {bf:Read into memory once.} If a workflow collects the same view more
than once, collect it once and work on the result; each {cmd:parqit collect}
re-executes the pipeline.{p_end}

{phang}o {bf:Set a shared-machine memory budget.} The pinned DuckDB engine's
default buffer-manager limit is 80% of the memory it detects. On a shared server
or scheduler allocation, set an explicit engine budget with
{cmd:parqit set memory_limit} (for example {cmd:8GB}) and, when useful, a spill
location with {cmd:parqit set tempdir}. This does not cap the complete process:
Stata frames, collected results and some engine allocations are outside this
budget. Sorting, joining and exact percentiles may need substantial scratch
space; complex SQL aggregate states may not spill. Smaller result output alone
does not guarantee a cheap query.{p_end}

{phang}o {bf:Force a serial fill if you need to.} Reads of 50,000+ rows fill
Stata's memory using up to {cmd:min(cores, 8)} worker threads (the per-cell
fill dominates the cost). To force the single-threaded path — for example on a
platform you have not yet verified — set the {it:operating-system} environment
variable {cmd:PARQIT_FILL_THREADS=0} {it:before launching Stata} (e.g.
{cmd:export PARQIT_FILL_THREADS=0} in your shell); {cmd:PARQIT_FILL_THREADS=}{it:n}
pins {it:n} workers for atypical very wide or string-heavy reads. It is read by
the plugin via {cmd:getenv}, so a Stata {cmd:global} does not reach it. The
parallel and serial fills are byte-identical.{p_end}


{marker expressions}{...}
{title:Expression dialect}

{pstd}
The numeric edge contracts follow Stata rather than DuckDB defaults. Division
by zero, an invalid power, overflow, {cmd:ln()}/{cmd:log10()} of a nonpositive
value and {cmd:sqrt()} of a negative value produce missing. {cmd:round(x)} and
{cmd:round(x,u)} break exact halves toward +infinity for positive units (so
{cmd:round(-2.5)=-2}); negative units reverse the tie direction and {cmd:u=0}
returns {cmd:x}. {cmd:mod(x,y)} is the
nonnegative remainder and is missing when {cmd:y<=0}. {cmd:min()}/{cmd:max()}
take 2–64 numeric arguments, ignore missing arguments and return missing only
when all are missing. {cmd:missing()}/{cmd:mi()} accept one or more arguments;
{cmd:inlist()} accepts 2–255 same-family arguments. Numeric
{cmd:inrange(x,lo,hi)} treats missing {cmd:x} as outside the range and missing
bounds as unbounded. Three-argument {cmd:cond()} treats a missing numeric
condition as true; its four-argument form selects the fourth branch instead.
Branches must be all numeric or all string.

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
{cmd:ustrupper()}/{cmd:ustrlower()} apply the engine's simple one-to-one
Unicode case mapping, not ICU's full mapping: {cmd:ustrupper("straße")} is
{cmd:STRAẞE} where native gives {cmd:STRASSE}, and {cmd:ustrlower("İ")} is
a plain {cmd:i} where native keeps a combining dot. {cmd:regexm()} has no
multiline mode: {cmd:^} and {cmd:$} anchor only at the ends of the whole
value and {cmd:.} does not match a newline, whereas native matches
{cmd:"^line1$"} and {cmd:"1.l"} inside {cmd:"line1"+char(10)+"line2"}.

{pstd}{cmd:round()} and {cmd:mod()} operate on the actual binary64 inputs,
without overflowing or rounding a quotient before finding its integer part.
This corrects native numerical failures: {cmd:round(4503599627370497)} keeps
that integer, and {cmd:mod(1e100,3)} is 1. Decimal-looking binary64 values are
not exact decimal fractions: {cmd:round(.25,.1)} is .2, and {cmd:mod(1,.1)}
is approximately .09999999999999995, not zero. The rounded exact remainder of
{cmd:mod(7,.00001)} is approximately 9.99999999942738e-06. These intentional
mathematical corrections can differ from native Stata's results.

{pstd}
Extended-missing literals {cmd:.a}-{cmd:.z} are rejected in lazy expressions.
At the Parquet boundary their category identity has already collapsed to the
single ordinary missing value, so accepting them would fabricate a distinction
the view cannot observe. Use {cmd:missing(x)} or compare with {cmd:.}.

{pstd}
Arithmetic operators evaluate in double precision, and guarded out-of-range
values become missing: an overflowing
result ({cmd:exp(800)}, {cmd:1e300*1e300}) or an out-of-range literal
({cmd:1e309}) is {cmd:.} in filters, assignments and aggregates alike —
never an IEEE infinity. Because untyped results are double, control the
storage of a generated column with a typed {cmd:parqit gen} (e.g.
{cmd:parqit gen byte flag = ...}); native Stata's untyped {cmd:gen} default
is {cmd:float}. For an explicit {cmd:float} target, a finite value outside
Stata's ±1.70e38 storage range becomes missing, as in native assignment.
A {cmd:float} operand is promoted when needed for numeric evaluation, including
comparisons with integer columns/literals above 2^24 and the alternatives of
{cmd:min()}, {cmd:max()} and {cmd:cond()}. Float-exact comparisons and
integer-only key filters retain their exact, narrow predicates. In particular:
{cmd:x == 0.1} is false for a float {cmd:x} holding 0.1, and
{cmd:x == float(0.1)} is the native idiom. {cmd:float(x)} rounds {cmd:x} to
float precision (a value beyond ±1.70e38 is missing). {cmd:round()} and
{cmd:mod()} normalize non-finite results before another expression uses them,
so {cmd:missing(round(x,u))} and {cmd:round(x,u)==.} agree.
Numeric literals first take their Stata binary64 value; fractional SQL
literals are typed directly as DOUBLE to avoid an intermediate decimal cast.
Bare integer/decimal columns retain their stored precision in comparisons,
including against a floating column. Thus DOUBLE 2^53 does not equal BIGINT
2^53+1. A DECIMAL just above .5 does not equal the literal .5, even if both
would round to .5 upon collection. Generate an explicit double copy when that
rounded representation is the intended comparison domain.
Date functions floor a fractional day count (like Stata:
{cmd:day(-0.5)} is 31) and an out-of-range argument is row-local missing.
One documented dialect difference: {cmd:regexm()} runs on DuckDB's RE2
engine, which understands {cmd:\d \w \s}, {cmd:{c -(}n,m{c )-}} and
non-greedy quantifiers that Stata's own {cmd:regexm} treats as literals —
patterns restricted to the shared syntax normally agree on single-line text.
The newline and Unicode differences above remain relevant.


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

{pstd}{it:Dates and times.} {cmd:%td} variables (and the old-style {cmd:%d}
synonyms) are {cmd:DATE} on disk,
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


{marker environment}{...}
{title:Environment}

{pstd}
The following knobs live outside {cmd:parqit set}. The Stata global
{cmd:PARQIT_PLUGIN_PATH} points the loader at a locally built plugin and
takes precedence over the adopath search for {cmd:parqit.plugin};
{cmd:global PARQIT_NOTIPS 1} mutes the one-line performance tips; and the
operating-system environment variable {cmd:PARQIT_FILL_THREADS} controls
the parallel memory fill (see {help parqit_technical##perf:Performance tips}).
The operating-system variable {cmd:PARQIT_SAVE_NOARROW} selects the batched
memory writer (see {help parqit_technical##materialisers:Materialisers}).

{pstd}No plugin-path global is needed when matching package files are on the
adopath. The ado and plugin verify their numerical protocol before operating;
incompatible files are refused. After updating a loaded package, restart Stata
so cached programs and the loaded binary belong to the same revision.


{marker limitations}{...}
{title:Limitations}

{pstd}{cmd:•} Views are plans over live sources, not snapshots: re-collecting
re-executes the pipeline and can observe a source file that changed meanwhile.
Results are not cached. A {cmd:view:}{it:name} input captures that view's plan at
the time it is embedded, but its underlying files remain live.{p_end}
{pstd}{cmd:•} Cross-source case or alias collisions must be resolved before
{cmd:append}/{cmd:merge}/{cmd:joinby}; a shared engine identifier must name the
same Stata column on both sides. Ambiguous combinations are refused before
plan mutation (see {help parqit##verbs:Verbs}).{p_end}
{pstd}{cmd:•} Eager {cmd:use, clear} and direct {cmd:collect} reads check each
matched file's identity (size, mtime, ctime, inode) before planning and before
and after the fetch. Fetched column types are compared with the plan; a change fails with
{cmd:r(920)} and the dataset in memory is untouched — retry when the file is
stable. These checks are not a cross-query snapshot protocol for transformed
collect, view save or engine-side statistics. A transformed pipeline's result
is built by an engine query over the sources at execution time; a command
may also run validation queries or several statistical passes. Its sources
must remain stable throughout the command.{p_end}
{pstd}{cmd:•} {cmd:parqit save ..., data copysource} verifies identity, names,
kinds, count, {cmd:sortedby} and the first and last 64 observations only; an
edit confined to the middle rows is not detected and the copy carries the
source file's content (see {help parqit_technical##materialisers:Materialisers}).{p_end}
{pstd}{cmd:•} {cmd:reshape wide}/{cmd:pivot} refuse a generated name that
differs only by case from a live or another generated name ({cmd:x1} beside
{cmd:X1}); a {opt relaxed} union refuses a name the engine's case-insensitive
union would split across two columns, and a Hive tree whose partition key
differs only by case from a file column is refused (see {it:Column names} under
{help parqit_technical##types:Types and metadata}).{p_end}
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
{cmd:list if} filters; {cmd:egen} also refuses them.{p_end}
{pstd}{cmd:•} {cmd:%tC} and {cmd:%tb} are stored as integer counts with
their format in metadata; third-party readers see the raw counts.{p_end}
{pstd}{cmd:•} {cmd:discard} unloads the plugin and forgets an un-collected
view (data on disk is never affected).{p_end}
{pstd}{cmd:•} A loaded result reports {cmd:c(filename)} empty and
{cmd:c(changed)} 0 — like an import, the data is not backed by a
.dta.{p_end}


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
