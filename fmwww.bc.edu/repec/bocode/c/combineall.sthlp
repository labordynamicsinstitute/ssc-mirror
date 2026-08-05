{smcl}
{* *! version 2.0.1 30jul2026 Eric A. Booth and Elizabeth Teas}{...}
{viewerjumpto "Syntax" "combineall##syntax"}{...}
{viewerjumpto "Description" "combineall##description"}{...}
{viewerjumpto "Engine options" "combineall##engine"}{...}
{viewerjumpto "Harmonization options" "combineall##harmon"}{...}
{viewerjumpto "The map file" "combineall##mapfile"}{...}
{viewerjumpto "Stored results" "combineall##results"}{...}
{viewerjumpto "Examples" "combineall##examples"}{...}
{viewerjumpto "Remarks and limits" "combineall##remarks"}{...}
{hline}
help for {hi:combineall}{right:v2.0.1}
{hline}

{title:Title}

{p2colset 5 20 22 2}{...}
{p2col :{cmd:combineall} {hline 2}}Combine (append, merge, or joinby) or convert every file in a directory, with an optional vintage-aware harmonization layer{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:combineall} [{cmd:using} {it:filename}] [{cmd:,} {it:options}]

{pstd}
{it:filename} names the combined output dataset ({cmd:.dta} may be given or
omitted).  If {cmd:using} is omitted, output goes to
{cmd:combineall_output.dta} inside {cmd:directory()}.  Every option is
optional, so a bare {cmd:combineall} is legal: it converts every
{cmd:.csv} file in the working directory to {cmd:.dta}.

{synoptset 24 tabbed}{...}
{synopthdr:engine options (2011)}
{synoptline}
{syntab:core}
{synopt :{cmdab:cmeth:od(}{it:method}{cmd:)}}combine method: {cmd:append}, {cmd:merge}, {cmd:joinby}, or {cmd:convertonly} (the default){p_end}
{synopt :{cmdab:d:irectory(}{it:path}{cmd:)}}folder containing the files to combine or convert; default is the working directory{p_end}
{synopt :{cmdab:rep:lace}}overwrite the {cmd:using} output file if it exists{p_end}
{synopt :{cmdab:keep:converted}}keep the per-file converted {cmd:.dta} copies; implied by {cmd:cmethod(convertonly)}{p_end}

{syntab:combine (append/merge/joinby)}
{synopt :{cmdab:mt:ype(}{it:type}{cmd:)}}{help merge} type: {cmd:1:1} (default), {cmd:m:m}, {cmd:1:m}, or {cmd:m:1}{p_end}
{synopt :{cmdab:mvar:s(}{it:varlist}{cmd:)}}key variables for {cmd:merge} or {cmd:joinby}; required with those methods{p_end}
{synopt :{cmd:_merge}}create one match-status variable per combined file, named {cmd:_}{it:filestem}{p_end}
{synopt :{it:other options}}options legal for {help append}, {help merge}, or {help joinby} pass through{p_end}

{syntab:file handling}
{synopt :{cmdab:file:type(}{it:ext}{cmd:)}}extension of the input files: {cmd:csv} (default), {cmd:dta}, {cmd:txt}, {cmd:xlsx}, {cmd:xls}, {cmd:xml}, or any text extension{p_end}
{synopt :{cmdab:fileid:(}{it:newvar}{cmd:)}}create {it:newvar} holding each observation's source filename{p_end}
{synopt :{cmdab:delim:iter(}{it:char}{cmd:)}}{cmd:comma} (default), {cmd:tab}, or a delimiter character such as {cmd:";"}{p_end}
{synopt :{cmdab:pre:fix(}{it:string}{cmd:)}}{it:string} added to the beginning of each converted filename{p_end}
{synopt :{cmdab:suf:fix(}{it:string}{cmd:)}}{it:string} added to the end of each converted filename{p_end}
{synopt :{cmdab:tostr:ing}}{help tostring} every variable during conversion, using each variable's display format (lossy for numerics){p_end}
{synopt :{cmdab:xml:opts(}{it:options}{cmd:)}}options passed to {help xmluse} when {cmd:filetype(xml)}{p_end}
{synoptline}

{synoptset 24 tabbed}{...}
{synopthdr:harmonization options (v2.0.0; cmethod(append) only)}
{synoptline}
{synopt :{cmd:map(}{it:filename}{cmd:)}}CSV rename map with columns {it:oldname,newname,firstyear,lastyear}; activates the layer{p_end}
{synopt :{cmdab:y:ear(}{it:spec}{cmd:)}}how to extract the year from each filename: a starting position or a regular expression; default is the first 4-digit run 19{it:xx}/20{it:xx}{p_end}
{synopt :{cmd:strict}}error (rather than report) when a mapped {it:oldname} is absent from a file its window covers{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:combineall} sweeps a directory and combines every file of one type into
a single dataset.  Text files ({cmd:csv}, {cmd:txt}, and any other delimited
extension), Excel files ({cmd:xlsx}/{cmd:xls}), and XML files are first
converted to {cmd:.dta}; native {cmd:.dta} files are used directly.  The
files are then combined by {help append}, {help merge}, or {help joinby},
or simply converted and left in place with {cmd:cmethod(convertonly)}.
The engine dates to 2011 (v1.0.0) and its option set is unchanged.

{pstd}
v2.0.0 adds a harmonization layer for stacking yearly file releases, active
under {cmd:cmethod(append)}.  Agencies publish one file per year, and
element names mutate across vintages: a column called one thing in 2015 is
renamed by 2020, so a naive append stacks unrelated variables.  With
{cmd:map()}, {cmd:combineall} extracts the 4-digit year stamped in each
filename, sorts the files by year, applies only the renames whose
{it:[firstyear,lastyear]} window covers that year, generates {cmd:int year},
and appends everything into one harmonized panel.

{pstd}
Under {cmd:map()}, every rename is written down twice.  The map CSV is the
human-readable record of the harmonization decisions, and each renamed
variable carries a {help char:characteristic},
{cmd:char} {it:varname}{cmd:[source]}, recording the original name, source
file, and year, so the panel documents its own provenance.  After stacking,
{cmd:combineall} prints a harmonization table (each final variable by the
years in which it has data) and lists any file where a mapped {it:oldname}
covered by the window was absent.  That absence is a report, not an error,
unless you add {cmd:strict}.


{marker engine}{...}
{title:Engine options}

{dlgtab:core options}

{phang}
{opt cmethod(method)} sets the combine method: {cmd:append}, {cmd:merge},
{cmd:joinby}, or {cmd:convertonly}.  The default, {cmd:convertonly},
converts each file to {cmd:.dta} in {cmd:directory()} and combines nothing.

{phang}
{opt directory(path)} names the folder containing the input files.  The
default is the current working directory.  The output {cmd:using} file is
excluded from the input list by name, so an output saved inside
{cmd:directory()} is not re-consumed on a second run.

{phang}
{opt replace} overwrites the {cmd:using} output file.  Without it,
{cmd:combineall} refuses to overwrite an existing output (error 198).

{phang}
{opt keepconverted} keeps the intermediate converted {cmd:.dta} copies
(named {it:prefix}{c 39}{it:filestem}{c 39}{it:suffix}{cmd:.dta}) after
combining.  Without it they are deleted once combined.
{cmd:cmethod(convertonly)} implies {cmd:keepconverted}; in v1.0.0 the two
had to be specified together.

{dlgtab:combine (append/merge/joinby) options}

{phang}
{opt mtype(type)} sets the {help merge} type ({cmd:1:1}, {cmd:m:m},
{cmd:1:m}, or {cmd:m:1}).  Default {cmd:1:1}.

{phang}
{opt mvars(varlist)} names the key variables for {cmd:merge} or
{cmd:joinby}; required with those methods.  The keys are created as empty
string variables in the seed master, so they must be strings in every input
file; see {help combineall##remarks:Remarks and limits}.

{phang}
{opt _merge} creates one match-status variable per combined file, named
{cmd:_}{it:filestem} (via {cmd:gen()} for {cmd:merge}, {cmd:_merge()} for
{cmd:joinby}).  File stems must therefore be valid variable-name material.

{phang}
Any other option legal for {help append}, {help merge}, or {help joinby}
passes through, for example {cmd:unmatched(both)} for {cmd:joinby}.

{dlgtab:file-handling options}

{phang}
{opt filetype(ext)} sets which files are swept up, by extension.
{cmd:csv} (default), {cmd:txt}, {cmd:raw}, {cmd:out}, {cmd:log}, and any
unrecognized extension are read with {help import delimited};
{cmd:xlsx}/{cmd:xls} with {help import excel} ({cmd:firstrow});
{cmd:xml} with {help xmluse}; {cmd:dta} with {help use}.  (v1.0.0 used
{cmd:insheet} and read {cmd:xls} as text; v2.0.0 reads Excel properly.)

{phang}
{opt fileid(newvar)} creates {it:newvar} containing each observation's
source filename, for example {cmd:enr_2019.csv}.

{phang}
{opt delimiter(char)} sets the text delimiter: {cmd:comma} (default),
{cmd:tab}, or a character such as {cmd:";"}.

{phang}
{opt prefix(string)} and {opt suffix(string)} decorate the converted
filenames, which is how you keep converted copies from colliding with
existing files.  Periods are removed from both.

{phang}
{opt tostring} converts every variable to string during conversion, for
files whose types wobble across sources.  The conversion is lossy for
numeric variables.  Each variable is passed to
{help tostring:tostring} {it:varname}{cmd:, force replace usedisplayformat},
and {cmd:usedisplayformat} is the catch: a value is written as its display
format renders it, not at full numeric precision.  A double holding 1/3
under the default {cmd:%10.0g} format becomes the string {cmd:.33333333},
and {help destring} cannot recover the digits that were dropped.
{cmd:force} allows that lossy conversion to proceed, and {cmd:combineall}
runs the conversion quietly, so {cmd:tostring}'s own loss-of-information
message is never displayed.  Reserve {cmd:tostring} for identifier-like
columns whose storage type wobbles across files, not for measured
quantities you intend to analyze at full precision.

{phang}
{opt xmlopts(options)} passes options to {help xmluse}, for example
{cmd:xmlopts(doctype(excel) firstrow)}.


{marker harmon}{...}
{title:Harmonization options (v2.0.0)}

{pstd}
These options require {cmd:cmethod(append)}; combining them with any other
method is an error (198).  {cmd:year()} and {cmd:strict} additionally
require {cmd:map()}.

{phang}
{opt map(filename)} names the rename map, a plain CSV described under
{help combineall##mapfile:The map file} below.  Specifying {cmd:map()}
activates the whole layer: year extraction, year-order sorting,
vintage-window renames, the {cmd:year} variable, {cmd:[source]} provenance
characteristics, and the harmonization table.  A map containing only the
header row stamps {cmd:year} without renaming anything.

{phang}
{opt year(spec)} controls year extraction from each filename (extension
excluded).  By default the first 4-digit run beginning 19 or 20 is used, so
{cmd:tapr_2019_campus.csv} yields 2019.  Two overrides are available:{p_end}
{phang2}{it:a number} is a 1-based starting position; {cmd:year(14)} reads 4
characters starting at position 14 of the filename.{p_end}
{phang2}{it:anything else} is treated as a regular expression
(ICU/{help ustrregexm} syntax).  If it contains a capture group, group 1 is
the year; otherwise the whole match is.  Example:
{cmd:year("run_([0-9][0-9][0-9][0-9])")}.{p_end}

{phang}
{opt strict} turns the absent-{it:oldname} report into an error (111).  Use
it when the map is a contract: every file whose year is covered by a window
must contain that {it:oldname}.


{marker mapfile}{...}
{title:The map file}

{pstd}
The map is a CSV with a header row and four columns:{p_end}

{p 8 8 2}{cmd:oldname,newname,firstyear,lastyear}{p_end}
{p 8 8 2}{cmd:enroll_cnt,enrollment,,2020}{p_end}
{p 8 8 2}{cmd:mscore,mathscore,2019,2019}{p_end}

{pstd}
A row means: in files whose year falls inside {it:[firstyear,lastyear]},
rename {it:oldname} to {it:newname}.  A blank {it:firstyear} or
{it:lastyear} leaves that end open, so the first row above reads: through
2020, {cmd:enroll_cnt} is what {cmd:enrollment} was called.  Rows apply in
file order; once an {it:oldname} is renamed in a file, later rows naming
the same {it:oldname} are skipped for that file.  A row whose {it:oldname}
equals its {it:newname} simply asserts the variable's presence (useful with
{cmd:strict}).

{pstd}
Matching is exact and case-sensitive, and text files are imported with case
preserved; write the map in the case the source files use.  Keep the map
file outside {cmd:directory()} (or use a different extension than
{cmd:filetype()}), or it will be swept up as an input file.


{marker results}{...}
{title:Stored results}

{pstd}{cmd:combineall} stores in {cmd:r()}:{p_end}
{synoptset 16 tabbed}{...}
{synopt :{cmd:r(n_files)}}number of files converted/combined{p_end}
{synopt :{cmd:r(output)}}path of the combined file (not {cmd:convertonly}){p_end}
{synopt :{cmd:r(n_vars)}}number of variables in the panel, including {cmd:year} ({cmd:map()} only){p_end}
{synopt :{cmd:r(n_missing)}}number of expected-but-absent oldname reports ({cmd:map()} only){p_end}
{synopt :{cmd:r(years)}}distinct years stacked, ascending ({cmd:map()} only){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}
Each block below is self-contained.  It builds its own input files from
{help sysuse:sysuse auto}, creates the folders it writes into, and runs as
shown in an empty working directory.  Stata does not create directories on
demand, so a {help mkdir} precedes every block that writes into a
subdirectory; {cmd:capture} is used so a block also survives a second run,
when the folder already exists.

{pstd}
Each block builds its inputs in a folder of its own on purpose.  Under
{cmd:filetype(dta)} with no {cmd:prefix()} or {cmd:suffix()} the "converted"
copy is the source file itself, so a block that adds {cmd:fileid()} writes
that column back into the files it read, and a later command pointed at the
same folder would silently inherit it; see
{help combineall##remarks:Remarks and limits}.

{pstd}{bf:Convert every CSV in a folder to .dta} (converted copies are
named {cmd:z}{it:name}{cmd:.dta}):{p_end}

{phang2}{cmd:. capture mkdir "raw"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg}{p_end}
{phang2}{cmd:. export delimited using "raw/cars_2019.csv", replace}{p_end}
{phang2}{cmd:. export delimited using "raw/cars_2020.csv", replace}{p_end}
{phang2}{cmd:. combineall, cmethod(convertonly) directory("raw/") prefix(z)}{p_end}

{pstd}{bf:Append every .dta file in a folder}, tagging each row with its
source file.  Because {cmd:filetype(dta)} rewrites the sources in place,
this block leaves {cmd:srcfile} behind in {cmd:pieces/part1.dta} and
{cmd:pieces/part2.dta}:{p_end}

{phang2}{cmd:. capture mkdir "pieces"}{p_end}
{phang2}{cmd:. capture mkdir "built"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg}{p_end}
{phang2}{cmd:. save "pieces/part1.dta", replace}{p_end}
{phang2}{cmd:. save "pieces/part2.dta", replace}{p_end}
{phang2}{cmd:. combineall using "built/all.dta", cmethod(append) directory("pieces/") filetype(dta) fileid(srcfile) replace}{p_end}

{pstd}{bf:Merge every file on a string key}, with one match-status variable
per file.  The key must be a string in every input file.  This block builds
a fresh fixture in {cmd:keys/} rather than reusing {cmd:pieces/}, which the
block above rewrote when it added {cmd:srcfile}:{p_end}

{phang2}{cmd:. capture mkdir "keys"}{p_end}
{phang2}{cmd:. capture mkdir "built"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen str3 campusid = string(_n, "%03.0f")}{p_end}
{phang2}{cmd:. keep campusid price}{p_end}
{phang2}{cmd:. save "keys/prices.dta", replace}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. gen str3 campusid = string(_n, "%03.0f")}{p_end}
{phang2}{cmd:. keep campusid mpg}{p_end}
{phang2}{cmd:. save "keys/mileage.dta", replace}{p_end}
{phang2}{cmd:. combineall using "built/wide.dta", cmethod(merge) directory("keys/") filetype(dta) mvars(campusid) _merge replace}{p_end}

{pstd}{bf:Stack yearly vintages with a rename map.}  Build two tiny yearly
files whose price column changes name, write a two-line map, and stack.
The 2019 file calls the column {cmd:price}; the 2020 vintage renamed it
{cmd:price_usd}, and the map folds it back:{p_end}

{phang2}{cmd:. capture mkdir "raw"}{p_end}
{phang2}{cmd:. capture mkdir "built"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg}{p_end}
{phang2}{cmd:. export delimited using "raw/cars_2019.csv", replace}{p_end}
{phang2}{cmd:. rename price price_usd}{p_end}
{phang2}{cmd:. export delimited using "raw/cars_2020.csv", replace}{p_end}

{phang2}{cmd:. file open m using "map.csv", write replace}{p_end}
{phang2}{cmd:. file write m "oldname,newname,firstyear,lastyear" _n}{p_end}
{phang2}{cmd:. file write m "price_usd,price,2020," _n}{p_end}
{phang2}{cmd:. file close m}{p_end}

{phang2}{cmd:. combineall using "built/cars_panel", cmethod(append) directory("raw/") map("map.csv") replace}{p_end}
{phang2}{cmd:. use "built/cars_panel.dta", clear}{p_end}
{phang2}{cmd:. char list price[source]}{p_end}
{phang2}{cmd:. tabulate year}{p_end}

{pstd}{bf:Filenames where the year is not the first 4-digit run.}  The
default extractor would read 2020 out of {cmd:batch2020run_2019.csv}, which
is the batch identifier rather than the year.  A starting position and an
explicit regular expression both pick out 2019 instead:{p_end}

{phang2}{cmd:. capture mkdir "pos"}{p_end}
{phang2}{cmd:. capture mkdir "built"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg}{p_end}
{phang2}{cmd:. export delimited using "pos/batch2020run_2019.csv", replace}{p_end}

{phang2}{cmd:. file open m using "posmap.csv", write replace}{p_end}
{phang2}{cmd:. file write m "oldname,newname,firstyear,lastyear" _n}{p_end}
{phang2}{cmd:. file write m "price,price_usd,2019,2019" _n}{p_end}
{phang2}{cmd:. file close m}{p_end}

{phang2}{cmd:. combineall using "built/p", cmethod(append) directory("pos/") map("posmap.csv") year(14) replace}{p_end}
{phang2}{cmd:. combineall using "built/p", cmethod(append) directory("pos/") map("posmap.csv") year("run_([0-9][0-9][0-9][0-9])") replace}{p_end}

{pstd}{bf:Insist the map is fully satisfied.}  A map row whose {it:oldname}
equals its {it:newname} asserts that the variable is present.  With
{cmd:strict}, a file whose year the window covers but which lacks that
variable stops the run with error 111 instead of producing a report:{p_end}

{phang2}{cmd:. capture mkdir "contract"}{p_end}
{phang2}{cmd:. capture mkdir "built"}{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}
{phang2}{cmd:. keep make price mpg}{p_end}
{phang2}{cmd:. export delimited using "contract/cars_2021.csv", replace}{p_end}

{phang2}{cmd:. file open cm using "contractmap.csv", write replace}{p_end}
{phang2}{cmd:. file write cm "oldname,newname,firstyear,lastyear" _n}{p_end}
{phang2}{cmd:. file write cm "price,price,," _n}{p_end}
{phang2}{cmd:. file close cm}{p_end}

{phang2}{cmd:. combineall using "built/contract", cmethod(append) directory("contract/") map("contractmap.csv") strict replace}{p_end}


{marker remarks}{...}
{title:Remarks and limits}

{pstd}
{bf:Output goes to the using file; memory is untouched.}  Unlike commands
that leave results in memory, {cmd:combineall} preserves and restores your
current data and writes the combined dataset to disk.  Load it with
{cmd:use} afterward.

{pstd}
{bf:Appends use force.}  The 2011 engine appends with {cmd:force}, so a
variable that is string in one file and numeric in another is coerced (the
offending values become missing) rather than stopping with an error.  This
engine behavior is kept in v2.0.0, including under {cmd:map()}.  Check the
harmonization table for unexpected gaps.  Importing everything as strings
with {cmd:tostring} and then applying {help destring} deliberately is one
way around the coercion, but that round trip is itself lossy.
{cmd:tostring} is run with {cmd:usedisplayformat}, so a numeric value is
written as its display format renders it and the digits beyond it are gone
before {cmd:destring} ever sees the column (see
{help combineall##engine:tostring} above).  Reserve that route for
identifier-like columns.

{pstd}
{bf:Merge and joinby keys must be strings.}  The engine seeds an empty
master whose key variables are created as empty strings; a numeric key in
the input files stops the first merge with a type mismatch (r(106)).
Convert keys to string in the sources, or combine with
{cmd:cmethod(append)} and reshape afterward.

{pstd}
{bf:joinby needs unmatched(both).}  Because the seed master matches
nothing, a plain {cmd:joinby} drops everything.  Pass
{cmd:unmatched(both)} (as the 2011 examples did) and drop the seed
artifacts you do not want.

{pstd}
{bf:filetype(dta) can rewrite sources in place.}  With {cmd:filetype(dta)}
and empty {cmd:prefix()}/{cmd:suffix()}, the "converted" copy is the source
file itself, so {cmd:fileid()}, {cmd:tostring}, or {cmd:map()} renames are
written back into the source files.  Specify {cmd:prefix()} or
{cmd:suffix()} to keep the originals pristine.

{pstd}
{bf:One year per file.}  The harmonization layer stamps one year per file,
taken from the filename; files containing multiple years should be split
upstream.  A file that already contains a variable named {cmd:year} stops
with an error and a hint to move it aside with a map row.

{pstd}
{bf:If strict (or any error) fires mid-run}, the partially combined
{cmd:using} file may remain on disk; rerun with {cmd:replace} after fixing
the problem.

{pstd}
{bf:Not yet handled:} recursing into subdirectories, and filenames whose
stems are not valid tokens for the {cmd:_merge} variable names.


{title:Authors}

{pstd}
Eric A. Booth, Sr Researcher, Texas 2036 {break}
eric.a.booth@gmail.com {break}

{pstd}
Elizabeth Teas, Sr Research Scientist, Far Harbor, LLC {break}
elizabeth@farharbor.com {break}

{pstd}
combineall v1.0.0 was first released in April 2011; v2.0.0 (2026) folds in
the vintage-harmonization layer developed for the authors'
applied-evaluation book.  MIT-licensed.

{title:Also see}

{p 4 8 2}On-line: help for {help append}, {help merge}, {help joinby},
{help import delimited}, {help import excel}, {help xmluse}, {help char},
{help use}
