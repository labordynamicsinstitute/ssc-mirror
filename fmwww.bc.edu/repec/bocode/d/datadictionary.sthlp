{smcl}
{* *! version 1.0.0  2026-07-30}{...}
{viewerjumpto "Syntax" "datadictionary##syntax"}{...}
{viewerjumpto "Description" "datadictionary##description"}{...}
{viewerjumpto "Options" "datadictionary##options"}{...}
{viewerjumpto "Output" "datadictionary##output"}{...}
{viewerjumpto "Stored results" "datadictionary##results"}{...}
{viewerjumpto "Examples" "datadictionary##examples"}{...}
{viewerjumpto "Remarks" "datadictionary##remarks"}{...}
{viewerjumpto "Related work" "datadictionary##related"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:datadictionary} {hline 2}}Enhanced, over-time-ready codebook generator (a modern descsave){p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{pstd}In-memory mode (documents the dataset in memory):{p_end}

{p 8 16 2}
{cmd:datadictionary} [{varlist}] {ifin} [{cmd:,}
{cmd:wave(}{varname}{cmd:)}
{cmd:dofile(}{it:filename}{cmd:)}
{cmd:dictionary(}{it:filename}{cmd:)}
{cmd:norecast} {it:shared_options}]

{pstd}Files mode (documents a set of wave files and detects changes across
waves):{p_end}

{p 8 16 2}
{cmd:datadictionary}{cmd:,} {cmd:files(}{it:"w1.dta w2.dta ..."}{cmd:)}
[{cmd:wavenames(}{it:"name1 name2 ..."}{cmd:)} {it:shared_options}]

{p 8 16 2}
{cmd:datadictionary}{cmd:,} {cmd:folder(}{it:dirpath}{cmd:)}
[{cmd:pattern(}{it:str}{cmd:)} {cmd:wavenames(}{it:"name1 name2 ..."}{cmd:)}
{it:shared_options}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :In-memory mode}
{synopt :{opth wa:ve(varname)}}wave identifier in a stitched file; adds per-wave presence and per-wave missingness{p_end}
{synopt :{opth do:file(filename)}}write a do-file that re-applies labels, value labels, formats, types, notes, and chars after a CSV/Excel round-trip{p_end}
{synopt :{opth dict:ionary(filename)}}write a free-format {help infile} dictionary (.dct): storage type + variable label only{p_end}
{synopt :{opt norec:ast}}omit the {cmd:recast} lines from {cmd:dofile()} (keep whatever storage type the re-import produced){p_end}

{syntab :Files mode}
{synopt :{opt fil:es("f1 f2 ...")}}space-separated list of wave .dta files, in wave order{p_end}
{synopt :{opt fol:der(dirpath)}}take the wave files from a folder instead{p_end}
{synopt :{opt pat:tern(str)}}filename pattern for {cmd:folder()}; default is {cmd:*.dta}; matches are sorted by filename{p_end}
{synopt :{opt waven:ames("n1 n2 ...")}}display names for the waves, one per file; default is each file's basename{p_end}

{syntab :Shared}
{synopt :{opth ex:cel(filename)}}write a multi-sheet .xlsx codebook{p_end}
{synopt :{opth sav:ing(filename)}}save the codebook itself as a .dta, one row per variable (per variable-wave in over-time modes){p_end}
{synopt :{opt rep:lace}}overwrite existing {cmd:excel()} and {cmd:saving()} files{p_end}
{synopt :{opt exam:ples(#)}}distinct example values shown for string variables; default {cmd:examples(3)}{p_end}
{synopt :{opt top(#)}}top categories by frequency shown for value-labeled variables; default {cmd:top(5)}{p_end}
{synopt :{opt noch:ars}}skip characteristics (both the {cmd:srctag} and {cmd:chars} columns){p_end}
{synopt :{opt non:otes}}skip stored {help notes}{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
The underlined stem of each option name is its minimum abbreviation.
{cmd:excel()} and {cmd:examples()} share the stem {cmd:ex}, and the two shortest
forms do not overlap: {cmd:ex()} is {cmd:excel()}, and {cmd:examples()} must be
spelled {cmd:exam()} or longer.  {cmd:exa()} therefore matches neither option and
is rejected as {it:option exa() not allowed} (error 198); spell out
{cmd:examples()} when you mean it.{p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:datadictionary} generates a codebook: one row per variable (per variable-wave
in files mode) holding the variable's name, storage type, display format,
variable label, value-label name, N nonmissing, % missing, number of distinct
values, numeric summary statistics (mean, sd, min, median, max; blank for
strings), example values, stored {help notes}, and characteristics
({help char}), including the {cmd:srctag} characteristic written by the
author's {cmd:combineall}/{cmd:projectbuilder} tools.  Results are displayed
compactly in the Results window and can be written to a machine-readable
.dta ({cmd:saving()}) and a multi-sheet Excel workbook ({cmd:excel()}).

{pstd}
{bf:In-memory mode} documents the dataset in memory, optionally restricted by
{it:varlist}, {cmd:if}, and {cmd:in}.  With {cmd:wave(}{varname}{cmd:)} it
also reports per-wave presence and per-wave missingness for a stitched
(appended) multi-wave file.

{pstd}
{bf:Files mode} ({cmd:files()} or {cmd:folder()}) loads each wave file in
turn (the caller's data are preserved and restored untouched), harvests
per-wave metadata, and detects changes across waves: variables added or
dropped, storage type changes, variable label changes, value-label set
changes (categories added, removed, or relabeled), and display format
changes.  This is only possible in files mode, because stitching waves into
one file destroys per-wave value labels: after {help append} only one label
definition per label name survives, so wave-specific category sets can no
longer be compared.  Files mode exists for exactly this reason.


{marker options}{...}
{title:Options}

{dlgtab:In-memory mode}

{phang}{cmd:wave(}{varname}{cmd:)} names the wave identifier of a stitched
multi-wave file (numeric or string).  {cmd:datadictionary} then writes one
codebook row per variable per wave, with per-wave statistics and % missing, so
you compare a variable across waves by reading down its rows.  The wave
identifier itself is not documented: it is read to split the file into waves and
then excluded from the codebook rows, so a 12-variable stitched file with a wave
identifier among those 12 yields 11 rows per wave, none of them named for the
wave variable.  A variable
all-missing within a wave shows 100% missing that wave; in a stitched file a
variable not fielded that wave and one fielded but never answered both look
all-missing and cannot be told apart.  Label and category changes are not
detectable in a stitched file (only one label set per variable survives the
append), so the {cmd:changed} flag stays blank; use files mode over the
original wave files to detect and flag those.{p_end}

{phang}{cmd:dofile(}{it:filename}{cmd:)} writes a do-file that re-applies the
current metadata - variable labels, value labels, display formats, storage
types, {help notes}, and characteristics (including {cmd:srctag}) - to a
dataset after it has been exported to CSV/Excel and re-imported.  This is the
portability tool: export the data with {help export_delimited:export delimited},
{cmd:nolabel} (so value-labeled variables travel as their numeric codes), hand
it to a collaborator working in R, Python, or Excel, and when the edited file
comes back, {help import_delimited:import delimited} it and {cmd:do} the
generated file to restore everything Stata knew.  Each command is prefixed with
{help capture}, and the file sets {cmd:varabbrev off}, so a column the
collaborator renamed or dropped is skipped rather than fuzzily relabeled; a
{it:receipt} at the foot of the file reports which expected variables were not
found and which extra columns appeared.  {cmd:.do} is appended when no
extension is given.  In-memory mode only.{p_end}

{phang}{cmd:dictionary(}{it:filename}{cmd:)} writes a free-format
{help infile} dictionary ({cmd:.dct}) giving each variable's storage type and
variable label.  A dictionary is legacy and narrower than {cmd:dofile()}:
free-format {help infile} is {it:whitespace}- (not comma-) delimited, and a
dictionary carries storage type and variable label only (no value labels,
notes, or chars).  Prepare the data file with {cmd:export delimited},
{cmd:delimiter(tab)} {cmd:nolabel} {cmd:quote} and read it back with
{cmd:infile using} {it:filename}.  For a general comma-delimited CSV round-trip
use {cmd:dofile()} instead.  {cmd:.dct} is appended when no extension is given.
In-memory mode only.{p_end}

{phang}{cmd:norecast} drops the {cmd:recast} lines from the {cmd:dofile()}
output, leaving whatever storage type the re-import produced.  Use it when the
collaborator may legitimately change a variable's type (for example turning an
integer code into a decimal).{p_end}

{dlgtab:Files mode}

{phang}{cmd:files(}{it:"f1 f2 ..."}{cmd:)} lists the wave .dta files,
space-separated and in wave order; quote filenames that contain spaces.
Each file is one wave.{p_end}

{phang}{cmd:folder(}{it:dirpath}{cmd:)} takes the wave files from a folder.
Files matching {cmd:pattern()} are sorted by filename and treated as waves in
that order, so a sortable naming scheme ({cmd:w1_}..., {cmd:2019_}...) gives
the right wave order.{p_end}

{phang}{cmd:pattern(}{it:str}{cmd:)} is the filename pattern for
{cmd:folder()}; the default is {cmd:*.dta}.{p_end}

{phang}{cmd:wavenames(}{it:"n1 n2 ..."}{cmd:)} supplies display names for the
waves (for example {cmd:wavenames("2019 2021 2023")}), one per file, used in
the display, the {cmd:wave} column, the {cmd:Changes} wave-pairs, and the
{cmd:Missingness} column headers.  The default is each file's basename
without the extension.{p_end}

{dlgtab:Shared}

{phang}{cmd:excel(}{it:filename}{cmd:)} writes a multi-sheet .xlsx workbook;
see {help datadictionary##output:Output} below.  {cmd:.xlsx} is appended when no
extension is given.{p_end}

{phang}{cmd:saving(}{it:filename}{cmd:)} saves the codebook itself as a
Stata dataset, one row per variable (per variable-wave in over-time modes) - the
descsave-style machine-readable product.  In-memory cross-sectional runs write
these 17 columns, in this order: {cmd:name}, {cmd:type}, {cmd:format},
{cmd:varlab}, {cmd:vallab}, {cmd:n}, {cmd:pctmiss}, {cmd:distinct}, {cmd:mean},
{cmd:sd}, {cmd:min}, {cmd:p50}, {cmd:max}, {cmd:examples}, {cmd:notes},
{cmd:srctag}, {cmd:chars}.  Each carries a variable label naming what it holds.
Over-time modes ({cmd:wave()}, {cmd:files()}, {cmd:folder()}) prepend
{cmd:wave} and {cmd:wavenum} - the leading order is {cmd:wave}, {cmd:name},
{cmd:wavenum}, then {cmd:type} onward - and append {cmd:changed}, for 20 columns;
{cmd:changed} is populated in files mode only and stays blank in {cmd:wave()}
mode.  Code against these names, not against the screen table, which abbreviates
its headers: {cmd:distinct} prints as {cmd:dist} and {cmd:pctmiss} prints as
{cmd:miss%}, but the variables are named {cmd:distinct} and {cmd:pctmiss} (there
is no {cmd:ndistinct}).  {cmd:.dta} is appended when no extension is
given.{p_end}

{phang}{cmd:replace} permits overwriting; without it an existing
{cmd:excel()} or {cmd:saving()} file stops the command with error 602.{p_end}

{phang}{cmd:examples(}{it:#}{cmd:)} sets how many distinct example values are
reported for string variables (comma-separated, in sorted order); the default
is 3.{p_end}

{phang}{cmd:top(}{it:#}{cmd:)} sets how many top categories by frequency are
reported for value-labeled variables, each as {it:label (n, pct%)}; the
default is 5.{p_end}

{phang}{cmd:nochars} skips characteristics entirely: neither the
{cmd:srctag} column (harvested from {cmd:char} {it:varname}{cmd:[srctag]},
written by the author's {cmd:combineall}/{cmd:projectbuilder} tools) nor the
{cmd:chars} column (all other characteristics, concatenated as
{it:name=value} pairs) is filled.{p_end}

{phang}{cmd:nonotes} skips stored {help notes}.{p_end}


{marker output}{...}
{title:Output}

{pstd}The default output is a compact formatted display: the per-variable
codebook table (grouped by wave in over-time modes) and, in files mode, the
list of detected changes.  When any output file is written, clickable links to
open each file and its containing folder are printed at the end.
{cmd:excel(}{it:filename}{cmd:)} writes:{p_end}

{p2colset 8 26 28 2}{...}
{p2col :{cmd:Overview}}source file(s), N and variable count per wave, generation date, notes count, and, in files mode only, the count of changes detected{p_end}
{p2col :{cmd:Variables}}the codebook: one row per variable (per variable-wave
in over-time modes), with statistics, {bf:% missing}, distinct count, common
values, labels, and notes side by side.  Over-time modes add a {cmd:wave}
column and a {cmd:changed} flag (see below){p_end}
{p2col :{cmd:ValueLabels}}label name, value, label text; per wave in over-time modes{p_end}
{p2col :{cmd:Changes}}files mode only; one row per detected change: wave-pair, variable, change type, before, after{p_end}
{p2colreset}{...}

{pstd}
Missingness is not a separate sheet: the {cmd:% missing} column lives in the
{cmd:Variables} codebook beside the statistics, and in over-time modes you read
it down a variable's wave rows.  In {cmd:wave()} mode a variable that carries no
data in a wave (dropped, or not yet fielded) shows 100% missing that wave.  In
files mode a variable that is not in a wave's file has no row for that wave at
all; the {cmd:Changes} sheet reports it as {cmd:variable added} or
{cmd:variable dropped}.{p_end}

{pstd}
The {cmd:changed} column (files mode) flags a variable whose {cmd:label} was
reworded or whose value-label {cmd:categories} changed from the previous wave -
a signal that the variable may no longer mean the same thing.  A stitched panel
keeps only one label set per variable, so in-memory {cmd:wave()} mode cannot
detect this and leaves {cmd:changed} blank; use files mode over the original
wave files to populate it.{p_end}

{pstd}Header rows are written in bold via {help putexcel}.  Value-label text is
written at full length in the {cmd:ValueLabels} sheet up to 2,000 characters;
text beyond that is cut at 2,000 in the sheet and in the change-detection
signatures alike, so change detection is unaffected.{p_end}


{marker results}{...}
{title:Stored results}

{pstd}{cmd:datadictionary} stores the following in {cmd:r()}:{p_end}
{synoptset 16 tabbed}{...}
{synopt :{cmd:r(nvars)}}number of codebook rows: variables documented (variable-waves in files mode){p_end}
{synopt :{cmd:r(nchanges)}}number of changes detected across waves (0 outside files mode){p_end}
{synopt :{cmd:r(xlsx)}}path of the Excel workbook written (only with {cmd:excel()}){p_end}
{synopt :{cmd:r(dta)}}path of the codebook dataset written (only with {cmd:saving()}){p_end}
{synopt :{cmd:r(dofile)}}path of the relabel do-file written (only with {cmd:dofile()}){p_end}
{synopt :{cmd:r(dct)}}path of the dictionary written (only with {cmd:dictionary()}){p_end}
{p2colreset}{...}


{marker examples}{...}
{title:Examples}

{pstd}Cross-sectional data (the simple case): one codebook row per variable,
statistics and % missing side by side, printed and written to Excel:{p_end}

{phang2}{cmd:. sysuse auto}{p_end}
{phang2}{cmd:. datadictionary}{p_end}
{phang2}{cmd:. datadictionary, excel(auto_codebook) saving(auto_codebook) replace}{p_end}
{phang2}{cmd:. return list}{p_end}

{pstd}Document part of a dataset (a varlist and an {cmd:if} restriction work as
usual):{p_end}

{phang2}{cmd:. datadictionary price mpg rep78 foreign if foreign == 1, excel(imports) replace}{p_end}

{pstd}Over time: document three wave files and flag what changed across waves:{p_end}

{phang2}{cmd:. datadictionary, files("staff_w1.dta staff_w2.dta staff_w3.dta") wavenames("2019 2021 2023") excel(staff_codebook) saving(staff_codebook) replace}{p_end}

{pstd}The same, taking every .dta in a folder (sorted by filename):{p_end}

{phang2}{cmd:. datadictionary, folder("waves") pattern("staff_*.dta") excel(staff_codebook) replace}{p_end}

{pstd}An already-stitched panel (per-wave statistics and missingness; label
changes are not detectable once stitched - use files mode for those).  Stack the
same three waves, carry a wave identifier, and document the result:{p_end}

{phang2}{cmd:. use staff_w1, clear}{p_end}
{phang2}{cmd:. append using staff_w2 staff_w3, generate(src)}{p_end}
{phang2}{cmd:. gen int wave = 2019 + 2 * src}{p_end}
{phang2}{cmd:. drop src}{p_end}
{phang2}{cmd:. datadictionary, wave(wave) excel(stitched_codebook) replace}{p_end}

{pstd}Send data to a collaborator in another package and get it back with the
labels intact.  Generate a relabel do-file (and, optionally, a dictionary)
alongside the codebook:{p_end}

{phang2}{cmd:. use staff_w1, clear}{p_end}
{phang2}{cmd:. datadictionary, excel(staff_codebook) dofile(staff_relabel) dictionary(staff) replace}{p_end}

{pstd}Export the data as its numeric codes (so value labels reattach cleanly),
share {cmd:staff.csv} plus {cmd:staff_codebook.xlsx}, and let a collaborator
edit in R, Python, or Excel:{p_end}

{phang2}{cmd:. export delimited using staff.csv, nolabel replace}{p_end}

{pstd}When the edited file comes back, re-import it and run the relabel do-file
to restore every label, format, note, and characteristic; read its receipt to
see what did not line up:{p_end}

{phang2}{cmd:. import delimited using staff.csv, varnames(1) case(preserve) clear}{p_end}
{phang2}{cmd:. do staff_relabel}{p_end}

{pstd}The optional dictionary reads a whitespace-delimited export in one typed
{help infile} step (storage type and variable label only):{p_end}

{phang2}{cmd:. export delimited using staff.txt, delimiter(tab) nolabel quote replace}{p_end}
{phang2}{cmd:. infile using staff.dct, clear}{p_end}


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Why files mode exists.}  Change detection across waves is only possible
in files mode, because stitching waves into one file destroys per-wave value
labels.  When wave files are appended, only one definition per value-label
name survives, so a category set that was extended or relabeled between waves
is no longer recoverable from the combined file.  Run {cmd:datadictionary} over the
original wave files, before or alongside stitching, to keep that history.

{pstd}
{bf:Not fielded or never answered.}  Missingness is reported as one number per
codebook row, the {cmd:pctmiss} column ({cmd:miss%} on screen), and not as a
separate grid or sheet.  A variable that is all-missing within a wave reads
{cmd:100} there.  In a stitched file that 100 carries two meanings which cannot
be told apart: a variable that was not fielded that wave, and one that was
fielded but never answered.  In files mode the distinction does not arise,
because a variable that is not in a wave's file gets no row for that wave; it
appears in the {cmd:Changes} output as {cmd:variable added} or
{cmd:variable dropped} instead, and a {cmd:pctmiss} of 100 in files mode means
the variable was in the file and every value was missing.

{pstd}
{bf:What counts as a change.}  Consecutive waves are compared.  A variable
missing from one wave's file and present in the next is {cmd:added}; the
reverse is {cmd:dropped}.  For variables present in both waves, the storage
type, display format, variable label, and value-label set (attached label
name plus its full value/text content) are compared; each difference is one
row in the {cmd:Changes} output, with the before and after values.

{pstd}
{bf:A format change can be a side effect.}  Attaching a longer value label also
widens the display format, because Stata sizes the format of a value-labeled
variable to its longest label text.  Recoding an item from a 4-point set whose
longest text runs 17 characters to a 5-point set whose longest runs 26 moves the
format from {cmd:%17.0g} to {cmd:%26.0g}, and {cmd:datadictionary} reports
{cmd:display format changed} for that variable in the same wave-pair as
{cmd:value label set changed}.  Read the two rows together: a format change
sitting beside a value-label change is usually that side effect rather than an
independent edit to the format.

{pstd}
{bf:Sample restriction.}  In-memory mode documents the selected subsample:
rows excluded by {cmd:if}/{cmd:in} do not contribute to N, missingness,
statistics, or examples.  Selecting an empty sample stops the command with
error 2000.

{pstd}
{bf:Round-tripping through other packages.}  {cmd:dofile()} exists because a
CSV or Excel file carries values but not the metadata Stata attaches to them:
export a labeled dataset and the labels, formats, notes, and characteristics
stay behind.  The relabel do-file is that metadata written as runnable code, so
a dataset can leave Stata for R, Python, or a collaborator's spreadsheet and
return fully re-dressed.  Two rules keep the round-trip honest.  Export with
{cmd:nolabel} so value-labeled variables travel as their numeric codes, which
the {cmd:label values} lines in the do-file reattach; exporting the text labels
instead turns the column into a string the do-file cannot re-encode.  And leave
the {help capture} prefixes in place: they turn a renamed or dropped column
into a skipped line and a receipt entry rather than a failed run, which is what
lets the do-file survive a collaborator who reorganizes the file.


{marker related}{...}
{title:Related work}

{pstd}
Roger Newson's {cmd:descsave} (SSC) exports variable-level attributes to a
dataset or do-file; {cmd:datadictionary} adds over-time change detection,
missingness patterns, example values, and the notes/chars/srctag harvest.
Kishor Das's {cmd:codebookout} (SSC) writes a one-dataset codebook to
Excel; {cmd:datadictionary} adds the multi-wave file comparison and multi-sheet
workbook (value labels and changes).  Built-in {help codebook}
prints a rich per-variable report but stores no machine-readable product;
{cmd:datadictionary} writes one ({cmd:saving()}) plus the Excel workbook, and
tracks how the file changes across waves.


{title:Author}

{pstd}
Eric A. Booth, Sr Researcher, Texas 2036, 2026.
Support: eric.a.booth@gmail.com.  MIT-licensed.
